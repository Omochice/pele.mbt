///|
const FLOW : String = "\n  commit id: \"init\"\n  commit type: REVERSE tag: \"v0.1\"\n  branch develop\n  commit id: \"feat\" msg: \"A message\"\n  commit type: HIGHLIGHT\n  checkout main\n  commit tag: \"v0.2\" tag: \"stable\"\n  merge develop id: \"merged\" tag: \"v1.0\"\n  branch hotfix\n  commit id: \"fix\"\n  checkout develop\n  commit\n  cherry-pick id: \"fix\"\n  checkout main\n  merge hotfix\n"

///|
fn with_config(yaml : String, body : String) -> String {
  "---\nconfig:\n  gitGraph:\n\{yaml}\n---\n\{body}"
}

///|
fn drawn(source : String) -> Result[@types.RenderResult, @errors.Failure] {
  Ok(@core.render([@git.git], source, @types.RenderOptions::default())) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn render(source : String) -> @types.RenderResult {
  drawn(source).unwrap()
}

///|
fn svg(source : String) -> String {
  render(source).svg
}

///|
fn count(text : String, needle : String) -> Int32 {
  let mut n = 0
  let mut at = @util.index_of(text, needle)
  while at != -1 {
    n += 1
    at = @util.index_of(text, needle, from=at + needle.length())
  }
  n
}

///|
/// The text between the first `from` after `after` and the next `to`.
fn between(text : String, after : String, to : String) -> String {
  let start = @util.index_of(text, after) + after.length()
  let end = @util.index_of(text, to, from=start)
  @util.slice(text, start, end~)
}

///|
fn number_after(text : String, prefix : String) -> Double {
  @util.parse_float(between(text, prefix, "\""))
}

///|
/// Centers of the commit symbols, in drawing order, which is the order the commits were made in.
fn commit_centers(svg : String) -> Array[(Double, Double)] {
  let found = []
  let groups = svg.split("<g class=\"pele-commit ").collect()
  for i in 1..<groups.length() {
    let group = groups[i].to_owned()
    let body = @util.slice(group, @util.index_of(group, ">") + 1)
    let body = if body.has_prefix("<title>") {
      @util.slice(body, @util.index_of(body, "</title>") + 8)
    } else {
      body
    }
    if body.has_prefix("<rect x=\"") {
      let x = number_after(body, "<rect x=\"")
      let y = number_after(body, " y=\"")
      found.push((x + 8, y + 8))
    } else if group.contains("<circle cx=\"") {
      let rest = @util.slice(group, @util.index_of(group, "<circle cx=\""))
      found.push(
        (number_after(rest, "<circle cx=\""), number_after(rest, " cy=\"")),
      )
    }
  }
  found
}

///|
test "draws a lane per branch and a symbol per commit" {
  let result = render("gitGraph\n" + FLOW)
  inspect(result.kind, content="gitGraph")
  inspect(result.svg.contains("class=\"pele pele-gitGraph\""), content="true")
  inspect(count(result.svg, "class=\"pele-branch\""), content="3")
  inspect(count(result.svg, "class=\"pele-lane\""), content="3")
  inspect(count(result.svg, "<g class=\"pele-commit "), content="10")
  inspect(result.svg.contains("data-id=\"develop\""), content="true")
  inspect(result.svg.contains(">hotfix<"), content="true")
  for k in 1..<=3 {
    inspect(result.svg.contains("var(--pele-series-\{k},"), content="true")
  }
}

///|
test "gives each commit type its own symbol" {
  let out = svg("gitGraph\n" + FLOW)
  inspect(count(out, "pele-commit-normal\""), content="5")
  inspect(count(out, "pele-commit-reverse\""), content="1")
  inspect(count(out, "pele-commit-highlight\""), content="1")
  inspect(count(out, "pele-commit-merge\""), content="2")
  inspect(count(out, "pele-commit-cherry-pick\""), content="1")
  let highlight = between(out, "pele-commit-highlight\"", "</g>")
  inspect(highlight.contains("<rect"), content="true")
  let merge = between(out, "pele-commit-merge\"", "</g>")
  inspect(count(merge, "<circle"), content="2")
}

///|
test "draws a merge with a type as that type, and still marks it as a merge" {
  inspect(
    svg(
      "gitGraph\n commit\n branch b\n commit\n checkout main\n commit\n merge b type: REVERSE",
    ).contains("class=\"pele-commit pele-commit-reverse pele-commit-merge\""),
    content="true",
  )
}

///|
test "labels commits with their ids, except unnamed merges and cherry-picks" {
  let out = svg("gitGraph\n" + FLOW)
  inspect(out.contains(">init<"), content="true")
  inspect(out.contains(">merged<"), content="true")
  inspect(count(out, "class=\"pele-commit-label\""), content="8")
  inspect(count(out, "rotate(-45 "), content="8")
  let hidden = svg(
    with_config("    showCommitLabel: false", "gitGraph\n" + FLOW),
  )
  inspect(hidden.contains("pele-commit-label"), content="false")
  inspect(hidden.contains(">v0.1<"), content="true")
}

///|
test "keeps ids level when rotateCommitLabel is off, and spaces commits to fit them" {
  let source = "gitGraph\n commit id: \"a rather long commit id\"\n commit id: \"another long commit id\"\n commit"
  let rotated = render(source)
  let level = render(with_config("    rotateCommitLabel: false", source))
  inspect(level.svg.contains("rotate("), content="false")
  inspect(level.width > rotated.width, content="true")
  inspect(level.height < rotated.height, content="true")
}

///|
test "draws tags, the default cherry-pick tag, and no empty tag" {
  let out = svg("gitGraph\n" + FLOW)
  inspect(count(out, "class=\"pele-tag\""), content="5")
  inspect(out.contains(">cherry-pick:fix<"), content="true")
  let none = svg(
    "gitGraph\n commit id:\"a\" tag:\"\"\n branch b\n commit id:\"c\"\n checkout main\n commit\n cherry-pick id:\"c\" tag:\"\"",
  )
  inspect(none.contains("pele-tag"), content="false")
}

///|
test "connects commits: straight along a lane, curved between lanes, dashed for a cherry-pick" {
  let out = svg("gitGraph\n" + FLOW)
  inspect(count(out, "class=\"pele-edge\""), content="9")
  inspect(count(out, "class=\"pele-edge pele-edge-merge\""), content="2")
  inspect(count(out, "class=\"pele-edge pele-edge-cherry-pick\""), content="1")
  let cherry = between(out, "pele-edge-cherry-pick\"", "/>")
  inspect(cherry.contains("stroke-dasharray"), content="true")
  let merge = between(out, "pele-edge-merge\"", "/>")
  let path = between(merge, " d=\"", "\"")
  inspect(path.has_prefix("M") && path.contains("C"), content="true")
  inspect(merge.contains("var(--pele-series-2,"), content="true")
}

///|
test "writes ids, tags, and branch names as plain text, with entity codes decoded and <br> as a line break" {
  let out = svg(
    "gitGraph\n commit id:\"add <Button> #35;1\" tag:\"<i>t</i>\"\n branch \"one<br>two\"\n commit id:\"**a**\"",
  )
  inspect(out.contains(">add &lt;Button&gt; #1<"), content="true")
  inspect(out.contains(">&lt;i&gt;t&lt;/i&gt;<"), content="true")
  inspect(out.contains(">**a**<"), content="true")
  inspect(out.contains("data-id=\"add &lt;Button&gt; #1\""), content="true")
  let first = between(out, "<tspan", "</tspan>")
  inspect(first.has_suffix(">one"), content="true")
  inspect(out.contains("</tspan><tspan"), content="true")
  inspect(out.contains(">two</tspan>"), content="true")
}

///|
test "puts the commit message in a tooltip" {
  inspect(
    svg("gitGraph\n commit id:\"a\" msg:\"Fix <the> bug\"").contains(
      "<title>Fix &lt;the&gt; bug</title>",
    ),
    content="true",
  )
}

///|
test "lays lanes out across the page for TB and upside down for BT" {
  let body = "\n commit\n commit\n branch b\n commit\n commit\n checkout main\n commit"
  let lr = render("gitGraph" + body)
  let tb = render("gitGraph TB:" + body)
  let bt = render("gitGraph BT:" + body)
  let l = commit_centers(lr.svg)
  let t = commit_centers(tb.svg)
  let b = commit_centers(bt.svg)
  inspect(l.length(), content="5")
  inspect(l[1].0 > l[0].0, content="true")
  inspect(l[1].1 == l[0].1, content="true")
  inspect(l[2].1 > l[0].1, content="true")
  inspect(t[1].1 > t[0].1, content="true")
  inspect(t[1].0 == t[0].0, content="true")
  inspect(t[2].0 > t[0].0, content="true")
  inspect(b[1].1 < b[0].1, content="true")
  inspect(b[2].0 > b[0].0, content="true")
  inspect(tb.height > tb.width, content="true")
  inspect(bt.height == tb.height, content="true")
  inspect(bt.svg.contains("rotate(45 "), content="true")
}

///|
test "shares positions between branches with parallelCommits" {
  let source = "gitGraph\n commit\n branch develop\n commit\n commit\n checkout main\n commit\n commit"
  let serial = render(source)
  let parallel = render(with_config("    parallelCommits: true", source))
  inspect(parallel.width < serial.width, content="true")
  let centers = commit_centers(parallel.svg)
  inspect(centers[3].0 == centers[1].0, content="true")
  inspect(centers[4].0 == centers[2].0, content="true")
}

///|
test "hides branch names and lane lines when showBranches is off" {
  let out = svg(with_config("    showBranches: false", "gitGraph\n" + FLOW))
  inspect(out.contains("pele-branch"), content="false")
  inspect(out.contains(">develop<"), content="false")
  inspect(count(out, "<g class=\"pele-commit "), content="10")
}

///|
test "names and orders the main branch from config, and orders branches by `order`" {
  let source = "gitGraph\n commit\n branch b1\n commit\n branch b2 order: 3\n commit\n branch b3 order: 1\n commit"
  let yaml = "    mainBranchName: trunk\n    mainBranchOrder: 2"
  let out = svg(with_config(yaml, source))
  inspect(
    @util.index_of(out, "data-id=\"b3\"") <
    @util.index_of(out, "data-id=\"trunk\""),
    content="true",
  )
  inspect(
    @util.index_of(out, "data-id=\"b1\"") <
    @util.index_of(out, "data-id=\"b3\""),
    content="true",
  )
  inspect(
    @util.index_of(out, "data-id=\"trunk\"") <
    @util.index_of(out, "data-id=\"b2\""),
    content="true",
  )
  inspect(
    svg(
      "%%{init: {\"gitGraph\": {\"mainBranchName\": \"dev\"}}}%%\ngitGraph\n commit",
    ).contains(">dev<"),
    content="true",
  )
}

///|
test "takes the title from front matter unless the graph sets one" {
  inspect(
    svg("---\ntitle: From front matter\n---\ngitGraph\n commit").contains(
      "From front matter",
    ),
    content="true",
  )
  let own = svg(
    "---\ntitle: From front matter\n---\ngitGraph\n title Own\n commit",
  )
  inspect(own.contains(">Own<"), content="true")
  inspect(own.contains("From front matter"), content="false")
}

///|
test "writes the accessible title and description" {
  let out = svg(
    "gitGraph\n accTitle: History\n accDescr: Two branches\n commit",
  )
  inspect(
    out.contains("<title id=\"pele-title\">History</title>"),
    content="true",
  )
  inspect(
    out.contains("<desc id=\"pele-desc\">Two branches</desc>"),
    content="true",
  )
}

///|
test "draws the same graph every time" {
  let source = "gitGraph\n commit\n commit\n branch b\n commit\n checkout main\n commit\n merge b"
  inspect(svg(source) == svg(source), content="true")
}

///|
test "draws a repeated commit id once, however often it is made" {
  inspect(
    svg(
      "gitGraph\n commit id:\"a\"\n commit id:\"a\"\n branch b\n commit id:\"a\"",
    ).contains("pele-commit"),
    content="true",
  )
}

///|
test "rejects what Mermaid rejects as a semantic error" {
  match drawn("gitGraph\n commit\n branch main") {
    Ok(_) => fail("expected an error")
    Err(failure) => {
      inspect(failure.code is Semantic, content="true")
      inspect(
        failure.message,
        content="Trying to create an existing branch. (Help: Either use a new name if you want create a new branch or try using \"checkout main\")",
      )
    }
  }
}

///|
test "draws a graph with no commits, and one with only branches" {
  inspect(svg("gitGraph").contains(">main<"), content="true")
  let out = svg("gitGraph\n branch a\n branch \"b c\"")
  inspect(count(out, "class=\"pele-branch\""), content="3")
  inspect(out.contains(">b c<"), content="true")
  inspect(out.contains("NaN"), content="false")
}

///|
test "emits only finite coordinates" {
  for header in ["gitGraph", "gitGraph TB:", "gitGraph BT:"] {
    for
      config in [
        "    parallelCommits: true", "    rotateCommitLabel: false", "    showBranches: false",
      ] {
      let result = render(with_config(config, header + "\n" + FLOW))
      inspect(
        result.width.is_nan() ||
        result.height.is_nan() ||
        result.width.is_inf() ||
        result.height.is_inf(),
        content="false",
      )
      for word in ["NaN", "Infinity", "undefined"] {
        inspect(result.svg.contains(word), content="false")
      }
    }
  }
}
