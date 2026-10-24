///|
fn detected(text : String) -> String {
  match @detect.detect_diagram(text) {
    Some(found) => "\{found.kind} \{found.mermaid_type}"
    None => "none"
  }
}

///|
test "a keyword at the start of the text names the diagram" {
  inspect(detected("pie"), content="pie pie")
  inspect(detected("graph TD"), content="flowchart flowchart-v2")
  inspect(detected("flowchart-elk TD"), content="flowchart flowchart-elk")
  inspect(detected("sequenceDiagram"), content="sequence sequence")
  inspect(detected("requirementDiagram"), content="requirement requirement")
}

///|
test "leading whitespace of any kind is skipped" {
  inspect(detected("  \n\tpie title x"), content="pie pie")
  inspect(detected("\u{a0}pie"), content="pie pie")
}

///|
test "prose that mentions a keyword later names no diagram" {
  inspect(detected("should handle simple pie"), content="none")
  inspect(detected("a 60/40 pie"), content="none")
}

///|
test "the first detector in Mermaid's order wins" {
  inspect(detected("flowchart-elk"), content="flowchart flowchart-elk")
  inspect(detected("infographic"), content="info info")
}

///|
test "C4 keywords other than C4Context match anywhere, as Mermaid's regex does" {
  inspect(detected("x C4Container"), content="c4 c4")
  inspect(detected("x C4Context"), content="none")
}

///|
test "some keywords ignore case" {
  inspect(detected("ISHIKAWA"), content="ishikawa ishikawa")
  inspect(detected("railroad-EBNF-beta"), content="railroad railroadEbnf")
  inspect(detected("Wardley-beta"), content="wardley wardley")
  inspect(detected("PIE"), content="none")
}

///|
test "some keywords must end at a boundary" {
  inspect(detected("agentflow-beta-x"), content="agentflow agentflow")
  inspect(detected("agentflow-betax"), content="none")
  inspect(detected("cynefin-beta:"), content="cynefin cynefin")
  inspect(detected("cynefin-betax"), content="none")
  inspect(detected("usecase-beta"), content="usecase usecase")
  inspect(detected("usecase-betax"), content="none")
}
