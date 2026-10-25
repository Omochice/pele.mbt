///|
/// Whether every tag in the drawing is one the renderer writes, which holds when no payload reached the markup unescaped.
fn is_inert(svg : String) -> Bool {
  if @svg.has_invalid_xml(svg) {
    return false
  }
  let known = [
    "svg", "g", "path", "rect", "circle", "text", "tspan", "title", "desc", "style",
    "defs",
  ]
  let mut at = @util.index_of(svg, "<")
  while at != -1 {
    let mut end = at + 1
    if @util.code_at(svg, end) == '/' {
      end += 1
    }
    let start = end
    while @util.is_word(@util.code_at(svg, end)) {
      end += 1
    }
    if !known.contains(@util.slice(svg, start, end~)) {
      return false
    }
    at = @util.index_of(svg, "<", from=at + 1)
  }
  !svg.contains("<?")
}

///|
fn quote_forms(payload : String) -> Array[String] {
  [
    "\"\{payload}\"",
    "'\{payload}'",
    "\"\{payload.replace_all(old="\\", new="\\\\").replace_all(old="\"", new="\\\"")}\"",
  ]
}

///|
fn templates(q : String, p : String) -> Array[String] {
  [
    "gitGraph\n commit id: \{q}",
    "gitGraph\n commit id: \{q} msg: \{q} tag: \{q} tag: \{q} type: HIGHLIGHT",
    "gitGraph\n commit \{q}",
    "gitGraph\n commit\n branch \{q}\n commit\n checkout \{q}\n commit",
    "gitGraph\n commit\n branch \{q} order: 2\n commit\n switch main\n commit\n merge \{q} id: \{q} tag: \{q} type: REVERSE",
    "gitGraph\n commit id: \{q}\n branch b\n commit\n cherry-pick id: \{q}",
    "gitGraph\n commit id: \"a\"\n branch b\n commit id: \"c\"\n checkout main\n commit\n cherry-pick id: \"c\" tag: \{q}",
    "gitGraph\n commit id:\"z\"\n branch b\n commit id:\"a\"\n checkout main\n commit\n merge b id:\"m\"\n checkout b\n cherry-pick id:\"m\" parent:\"a\" tag: \{q}",
    "gitGraph TB:\n commit id: \{q} tag: \{q}\n branch \{q}\n commit",
    "gitGraph BT:\n commit id: \{q} tag: \{q}\n branch \{q}\n commit",
    "gitGraph\n commit\n branch \{p}\n commit",
    "gitGraph\n title \{p}\n commit",
    "gitGraph\n accTitle: \{p}\n accDescr: \{p}\n commit",
    "gitGraph\n accDescr {\n \{p}\n }\n commit",
    "gitGraph \{p}:\n commit",
    "gitGraph\n commit type: \{p}",
    "---\ntitle: \{q}\nconfig:\n  gitGraph:\n    mainBranchName: \{q}\n    mainBranchOrder: \{q}\n    showBranches: \{q}\n    rotateCommitLabel: \{q}\n---\ngitGraph\n commit id: \"x\"",
    "%%{init: {\"gitGraph\": {\"mainBranchName\": \{q}, \"showCommitLabel\": \{q}, \"parallelCommits\": \{q}}}}%%\ngitGraph\n commit\n branch b\n commit",
  ]
}

///|
test "hostile text is escaped in every position" {
  let payloads = [
    "<script>alert(1)</script>", "\"><script>alert(1)</script>", "<img src=x onerror=alert(1)>",
    "<svg onload=alert(1)>", "<a href=\"javascript:alert(1)\">x</a>", "<foreignObject><iframe src=javascript:alert(1)></iframe></foreignObject>",
    "</text></g></svg><script>alert(1)</script>", "javascript:alert(1)", "' onload='alert(1)",
    "x\" onclick=\"alert(1)\" y=\"", "#60;script#62;alert(1)#60;/script#62;", "]]><script>alert(1)</script>",
    "--><script>alert(1)</script>", "&lt;script&gt;alert(1)&lt;/script&gt;",
  ]
  let mut rendered = 0
  let mut turn = 0
  for payload in payloads {
    let forms = quote_forms(payload)
    for source in templates(forms[turn % forms.length()], payload) {
      turn += 1
      match drawn(source) {
        Ok(result) => {
          rendered += 1
          inspect(is_inert(result.svg), content="true")
        }
        Err(failure) =>
          inspect(failure.code is (Syntax | Semantic), content="true")
      }
    }
  }
  inspect(rendered > 20, content="true")
}

///|
test "keeps payload text out of markup" {
  let out = svg(
    "gitGraph\n commit id: \"<script>alert(1)</script>\" tag: \"\\\"><img src=x onerror=alert(1)>\"\n branch \"</text><script>\"\n commit",
  )
  inspect(out.contains("<script"), content="false")
  inspect(out.contains("<img"), content="false")
  inspect(out.contains("&lt;script&gt;alert(1)&lt;/script&gt;"), content="true")
}
