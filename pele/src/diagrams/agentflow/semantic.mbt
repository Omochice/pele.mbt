///|
/// What a node is, from its shape: `tool`, `action`, `input`, `refdoc`, `decision` or `task`.
pub fn AgentflowDb::vertex_kind(
  _self : AgentflowDb,
  vertex : AgentNode,
) -> String {
  if is_tool_shape(vertex.kind) {
    return "tool"
  }
  match resolve_shape_alias(vertex.kind) {
    Some("hexagon" | "hex") => "action"
    Some("lean-right" | "lean_right") => "input"
    Some("lin-doc" | "lined-document") => "refdoc"
    Some("diamond") => "decision"
    _ => "task"
  }
}

///|
/// Metadata keys that only say how an element is drawn.
fn is_presentation_key(key : String) -> Bool {
  key
  is ("shape"
  | "view"
  | "icon"
  | "img"
  | "form"
  | "pos"
  | "w"
  | "h"
  | "class"
  | "style"
  | "labelType")
}

///|
fn semantic_metadata(metadata : Map[String, Json]?) -> Map[String, Json]? {
  guard metadata is Some(fields) else { return None }
  let out : Map[String, Json] = Map([])
  for key, value in fields {
    if !is_presentation_key(key) {
      out[key] = value
    }
  }
  if out.is_empty() {
    None
  } else {
    Some(out)
  }
}

///|
/// The diagram with presentation-only controls left out, for tools that read what it means.
pub fn AgentflowDb::semantic_model(self : AgentflowDb) -> SemanticModel {
  let vertices = []
  let connectors = []
  for id, v in self.nodes {
    if self.subgraph_lookup.contains(id) {
      continue
    }
    let metadata = semantic_metadata(v.metadata)
    if v.is_connector {
      let title = match v.text {
        Some(text) if text != id => Some(text)
        _ => None
      }
      connectors.push({ id, title, metadata, })
      continue
    }
    vertices.push({
      id,
      label: v.text,
      shape: resolve_shape_alias(v.kind),
      vertex_kind: self.vertex_kind(v),
      metadata,
    })
  }
  let edges = self.edges.map(e => {
    start: e.start,
    end: e.end,
    id: Some(e.id),
    label: if e.text.length() > 0 {
      Some(e.text)
    } else {
      None
    },
    kind: e.kind,
    stroke: e.stroke,
    edge_semantic: e.edge_semantic,
    length: e.length,
    metadata: match e.metadata {
      Some(fields) if !fields.is_empty() => Some(Map::from_iter(fields.iter()))
      _ => None
    },
  })
  let subgraphs = self.subgraphs.map(sg => {
    id: sg.id,
    title: sg.title,
    nodes: sg.nodes.copy(),
    direction: sg.dir,
    metadata: semantic_metadata(sg.metadata),
  })
  {
    direction: self.direction,
    vertices,
    edges,
    subgraphs,
    connectors,
    diagnostics: self.diagnostics,
  }
}
