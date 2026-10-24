// Mermaid's wardleyBuilder.spec.ts.

///|
fn place(builder : Builder, id : String, label : String, x : Double) -> Unit {
  builder.add_node(id~, label~, x~, y=x, class_name="component")
}

///|
test "returns the id when a node exists with that exact id" {
  let builder = Builder::new()
  place(builder, "API", "API", 60)
  assert_eq(builder.resolve_node_id("API"), "API")
}

///|
test "falls back to label match for pipeline-style synthetic ids" {
  let builder = Builder::new()
  builder.add_node(
    id="Kettle_Campfire Kettle",
    label="Campfire Kettle",
    x=35,
    y=45,
    class_name="pipeline-component",
  )
  assert_eq(
    builder.resolve_node_id("Campfire Kettle"),
    "Kettle_Campfire Kettle",
  )
}

///|
test "returns the input unchanged when no id or label matches" {
  let builder = Builder::new()
  place(builder, "API", "API", 60)
  assert_eq(builder.resolve_node_id("Unknown"), "Unknown")
}

///|
test "prefers exact id over label match when both exist" {
  let builder = Builder::new()
  place(builder, "Alpha", "Beta", 0)
  place(builder, "Beta", "Gamma", 1)
  assert_eq(builder.resolve_node_id("Beta"), "Beta")
}

///|
test "a label resolves to the first node that has it, also after more nodes are added" {
  let builder = Builder::new()
  place(builder, "a", "L", 0)
  assert_eq(builder.resolve_node_id("M"), "M")
  place(builder, "b", "M", 0)
  place(builder, "c", "M", 0)
  assert_eq(builder.resolve_node_id("M"), "b")
  assert_eq(builder.resolve_node_id("L"), "a")
}
