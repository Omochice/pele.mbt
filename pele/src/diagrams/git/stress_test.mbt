///|
fn big(source : String) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), }
  Ok(@core.render([@git.git], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn repeat_lines(count : Int32, line : (Int32) -> String) -> String {
  let out = StringBuilder()
  for i in 0..<count {
    out.write_string(line(i))
  }
  out.to_string()
}

///|
fn config_block(yaml : String) -> String {
  "---\nconfig:\n  gitGraph:\n\{yaml}\n---\n"
}

///|
fn parse_only(source : String) -> Bool {
  ignore(@git.parse_git(source)) catch {
    @errors.PeleError(_) => return false
  }
  true
}

///|
fn zigzag() -> String {
  repeat_lines(1200, i => {
    let (from, to) = if i % 2 == 1 { ("main", "b") } else { ("b", "main") }
    "checkout \{from}\ncommit\nmerge \{to}\n"
  })
}

///|
fn picks() -> String {
  "gitGraph\ncommit id:\"s\"\nbranch b\ncommit\n" +
  repeat_lines(1500, i => {
    "checkout main\ncommit id:\"m\{i}\"\ncheckout b\ncommit\ncherry-pick id:\"s\"\n"
  })
}

///|
fn finishes(source : String) -> Unit raise {
  match big(source) {
    Ok(result) => inspect(result.svg.length() > 0, content="true")
    Err(failure) => inspect(failure.code is (Syntax | Semantic), content="true")
  }
}

///|
test "large graphs are laid out in near linear time" {
  let n = 50000
  finishes("gitGraph\n" + "commit\n".repeat(7000))
  finishes(
    config_block("    rotateCommitLabel: false") +
    "gitGraph TB:\n" +
    "commit\n".repeat(7000),
  )
  finishes(
    "gitGraph\ncommit\n" + repeat_lines(3000, i => "branch b\{i}\ncommit\n"),
  )
  finishes(
    config_block("    parallelCommits: true") +
    "gitGraph BT:\ncommit\n" +
    repeat_lines(3000, i => "branch b\{i}\ncommit\n"),
  )
  finishes(
    "gitGraph\ncommit\n" +
    repeat_lines(1500, i => "branch b\{i}\ncommit\ncheckout main\nmerge b\{i}\n"),
  )
  finishes("gitGraph\ncommit\nbranch b\ncommit\n" + zigzag())
  finishes(
    config_block("    parallelCommits: true") +
    "gitGraph\ncommit\nbranch b\ncommit\n" +
    zigzag(),
  )
  finishes(picks())
  finishes(
    config_block("    parallelCommits: true") +
    picks().replace(old="gitGraph", new="gitGraph TB:"),
  )
  finishes(
    "gitGraph\ncommit" +
    " tag:\"t\"".repeat(4000) +
    "\nbranch b\ncommit" +
    " tag:\"u\"".repeat(2000),
  )
  finishes("gitGraph\n" + "commit id:\"same\"\n".repeat(3000))
  finishes("gitGraph\ncommit id:\"" + "word ".repeat(n / 5) + "\"")
  finishes("gitGraph\ncommit\nbranch " + "x".repeat(n) + "\ncommit")
  finishes("gitGraph\ntitle " + "x".repeat(n) + "\ncommit")
  finishes("gitGraph\ncommit\nbranch b order: " + "9".repeat(n) + "\ncommit")
}

///|
test "commits that already have the ids that would be generated next are skipped over" {
  let model = @git.build_git(
    @git.parse_git("gitGraph\n" + "commit\n".repeat(3000)),
    {},
    None,
  )
  let later = model.commits.keys().collect()[1500:]
  let source = "gitGraph\n" +
    later.iter().map(id => "commit id:\"\{id}\"\n").collect().join("") +
    "commit\n".repeat(1500)
  finishes(source)
}

///|
test "inputs that make a naive lexer rescan the text are read in one pass" {
  let n = 50000
  let cases = [
    "gitGraph\nbranch a" + ".".repeat(n),
    "gitGraph\n" + ("branch a" + ".".repeat(20) + "b\n").repeat(2000),
    "gitGraph\nbranch b order: " + "9".repeat(n) + ".",
    "gitGraph\ncommit id:" + "\"a".repeat(n / 2),
    "gitGraph\ncommit id:\"" + "\\\"".repeat(n / 2),
    "gitGraph\n" + "accDescr {\n".repeat(n / 11),
    "gitGraph\n" + ("accDescr" + "\n".repeat(50)).repeat(800),
    "gitGraph\n" + "%%{\n".repeat(n / 4),
    "gitGraph\n" + "---\n".repeat(n / 4),
    "---\n" + "--- x\n".repeat(n / 6) + "gitGraph",
    "gitGraph\n" + ("title " + "a%".repeat(40) + "\n").repeat(550),
    "gitGraph\n" + " ".repeat(n) + "commit",
    "gitGraph\n" +
    ("commit" + " ".repeat(40) + "id:" + " ".repeat(40) + "\"a\"\n").repeat(500),
    "gitGraph\n" + "commit".repeat(n / 6),
    "gitGraph:".repeat(n / 9),
  ]
  for source in cases {
    ignore(parse_only(source))
  }
}
