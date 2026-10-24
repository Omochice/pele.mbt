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
/// The shape a node without an agentflow shape is drawn as.
const DEFAULT_SHAPE : String = "roundedRect"

///|
/// Flowchart shapes agentflow v0.8.1 removed.
fn is_removed_shape(shape : String) -> Bool {
  shape
  is ("doc"
  | "stadium"
  | "terminal"
  | "circle"
  | "trapezoid"
  | "inv_trapezoid"
  | "inv-trapezoid"
  | "doublecircle"
  | "double-circle"
  | "typeDeclaration"
  | "procs"
  | "lean_left"
  | "lean-left"
  | "in-out"
  | "cylinder"
  | "ellipse"
  | "odd"
  | "tag-rect"
  | "tagged-rectangle"
  | "delay"
  | "half-rounded-rectangle"
  | "lin-rect"
  | "lined-rectangle"
  | "win-pane"
  | "window-pane"
  | "curv-trap"
  | "curved-trapezoid")
}

///|
/// The shapes agentflow draws.
fn is_allowed_shape(shape : String) -> Bool {
  shape
  is ("roundedRect"
  | "subroutine"
  | "subprocess"
  | "subproc"
  | "framed-rectangle"
  | "lean-right"
  | "diamond"
  | "lin-doc"
  | "lined-document"
  | "hexagon"
  | "hex"
  | "connector"
  | "collapsedGroup")
}

///|
/// Reduces every node's shape to one agentflow draws, reporting the removed and unsupported ones.
fn normalise_node_shapes(nodes : Array[GraphNode], db : AgentflowDb) -> Unit {
  for node in nodes {
    if node.is_group {
      continue
    }
    if node.shape == "" || node.shape == "squareRect" || node.shape == "rect" {
      node.shape = DEFAULT_SHAPE
    }
    if is_removed_shape(node.shape) {
      db.emit(
        "SHAPE_REMOVED",
        "error",
        "shape \"\{node.shape}\" was removed in v0.8.1, using \"\{DEFAULT_SHAPE}\"",
        node_id=node.id,
      )
      node.shape = DEFAULT_SHAPE
    } else if !is_allowed_shape(node.shape) {
      db.emit(
        "SHAPE_UNSUPPORTED",
        "warning",
        "shape \"\{node.shape}\" is not supported, using \"\{DEFAULT_SHAPE}\"",
        node_id=node.id,
      )
      node.shape = DEFAULT_SHAPE
    }
  }
}

///|
/// Whether the node is drawn as a tool definition.
fn is_tool_shape(kind : String?) -> Bool {
  kind
  is Some("subroutine" | "subprocess" | "subproc" | "framed-rectangle" | "tool")
}
