///|
/// The shape an author-facing name stands for, or the name itself.
fn resolve_shape_alias(shape : String?) -> String? {
  match shape {
    Some("task") => Some("roundedRect")
    Some("tool") => Some("subroutine")
    Some("input") => Some("lean-right")
    Some("decision") => Some("diamond")
    Some("refdoc") => Some("lin-doc")
    Some("action") => Some("hexagon")
    Some("round") => Some("rect")
    _ => shape
  }
}

///|
/// Whether a metadata `shape` names a shape at all.
/// Mermaid looks a shape name up with `in` on a plain object, so `constructor` passes there too.
fn is_valid_shape(name : String) -> Bool {
  @flowchart.is_valid_shape(name) || name == "constructor"
}

///|
/// Whether the node is drawn as a tool definition.
fn is_tool_shape(kind : String?) -> Bool {
  kind
  is Some("subroutine" | "subprocess" | "subproc" | "framed-rectangle" | "tool")
}
