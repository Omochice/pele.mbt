///|
/// FNV-1a over UTF-16 code units, as scripts/gen-flowchart-golden-test.mjs hashes pele's dumps.
fn fnv1a(text : String) -> String {
  let mut h : UInt32 = 0x811c9dc5U
  for i in 0..<text.length() {
    h = (h ^ text.unsafe_get(i).to_int().reinterpret_as_uint()) * 0x01000193U
  }
  let digits = "0123456789abcdef"
  let out = StringBuilder()
  for shift in [28, 24, 20, 16, 12, 8, 4, 0] {
    let d = ((h >> shift) & 0xfU).reinterpret_as_int()
    out.write_char(digits.get_char(d).unwrap())
  }
  out.to_string()
}

///|
/// What reading the golden source gives through the same steps as `@core.render` up to parsing,
/// written as the generator writes pele's outcome.
fn golden_outcome(source : String) -> String {
  let model : Ref[@flowchart.FlowDb?] = { val: None, }
  let diagram : @types.Diagram = {
    kind: "flowchart",
    section: None,
    keep_comments: false,
    parse: (text, config, title, _, limits) => {
      model.val = Some(@flowchart.parse_model(text, config, title, limits))
      { render: (_, _) => { svg: "", width: 0, height: 0, links: [], }, }
    },
  }
  let options = {
    ..@types.RenderOptions::default(),
    limit: Some(50000),
    max_edges: Some(5000),
  }
  ignore(@core.render([diagram], source, options)) catch {
    @errors.PeleError(failure) => {
      let kind = failure.kind.unwrap_or("null")
      let mermaid_type = failure.mermaid_type.unwrap_or("null")
      return "error \{failure.code.to_string()} \{kind} \{mermaid_type}\n\{failure.message}"
    }
  }
  match model.val {
    Some(db) => "ok \{fnv1a(dump(db))}"
    None => "no model"
  }
}

///|
test "every flowchart golden reads as pele reads it, failing with the same error" {
  let wrong = []
  for case in golden_cases {
    let (id, source, expected) = case
    let actual = golden_outcome(source)
    if actual != expected {
      wrong.push("\{id}: \{actual.escape()} instead of \{expected.escape()}")
    }
  }
  inspect(wrong.join("\n"), content="")
}
