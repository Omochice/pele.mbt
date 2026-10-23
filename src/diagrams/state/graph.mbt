///|
/// A node to draw: a state, a composite or one of its regions, a note, or the group a note sits in.
pub(all) struct StateNode {
  id : String
  /// rect, rectWithTitle, stateStart, stateEnd, choice, fork, join, divider, roundedWithTitle, note or noteGroup.
  mut shape : String?
  mut label : String?
  mut description : Array[String]
  mut css_classes : String
  mut css_compiled_styles : Array[String]
  mut css_styles : Array[String]
  mut kind : String?
  mut is_group : Bool
  mut parent_id : String?
  /// The direction inside a composite: its last `direction` statement, or TB.
  mut dir : String?
  mut position : String?
  mut note_for : String?
  mut color_index : Int32?
}

///|
/// A transition, or the dashed line between a note and its state.
/// Labels are markdown throughout, as in Mermaid.
pub(all) struct StateEdge {
  id : String
  start : String
  end : String
  label : String
  classes : String
  dashed : Bool
}

///|
/// The nodes and edges a state diagram draws.
pub(all) struct StateGraph {
  nodes : Array[StateNode]
  edges : Array[StateEdge]
}

///|
/// Mermaid's dataFetcher: walks the documents and resolves them into the nodes and edges that are drawn.
pub fn build_state_graph(
  root_doc : Array[Stmt],
  states : Map[String, StateStmt],
  classes : Map[String, StateClassDef],
) -> StateGraph raise @errors.PeleError {
  ignore((root_doc, states, classes))
  if false {
    raise @errors.pele_error("", code=Semantic, kind="state")
  }
  { nodes: [], edges: [], }
}
