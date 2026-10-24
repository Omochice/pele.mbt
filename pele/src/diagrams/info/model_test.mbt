///|
fn model(source : String) -> String {
  let built = @info.build_info(@info.parse_info(source), Some("front")) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "title=\{built.title.unwrap_or("-")} accTitle=\{built.acc_title.unwrap_or("-").escape()} accDescr=\{built.acc_descr.unwrap_or("-").escape()}"
}

///|
test "the front matter title is used when the diagram has none" {
  inspect(model("info"), content="title=front accTitle=\"-\" accDescr=\"-\"")
  inspect(
    model("info\ntitle"),
    content="title=front accTitle=\"-\" accDescr=\"-\"",
  )
}

///|
test "the diagram's own title wins over the front matter title" {
  inspect(
    model("info\ntitle own"),
    content="title=own accTitle=\"-\" accDescr=\"-\"",
  )
}

///|
test "accessibility text is trimmed where Mermaid trims it" {
  inspect(
    model("info\naccTitle:   a\naccDescr {\n  a\n   b\n}"),
    content="title=front accTitle=\"a\" accDescr=\"a\\nb\"",
  )
}
