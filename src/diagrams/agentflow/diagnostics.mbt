///|
fn same_finding(a : Diagnostic, b : Diagnostic) -> Bool {
  a.id == b.id &&
  a.severity == b.severity &&
  a.message == b.message &&
  a.node_id == b.node_id &&
  a.edge_id == b.edge_id
}

///|
/// Records a finding on a node or an edge, positioned where that element is first written.
/// The graph may be built more than once, so each finding is recorded once.
fn AgentflowDb::emit(
  self : AgentflowDb,
  id : String,
  severity : String,
  message : String,
  node_id? : String,
  edge_id? : String,
) -> Unit {
  let anchor = match node_id {
    Some(_) => node_id
    None => edge_id
  }
  let (node_id, edge_id) = match (node_id, edge_id) {
    (Some(node), _) if node != "" => (Some(node), None)
    (_, Some(edge)) if edge != "" => (None, Some(edge))
    _ => (None, None)
  }
  let position = match anchor {
    Some(anchor) if anchor != "" =>
      self.first_mapping.get(anchor).map(m => m.position)
    _ => None
  }
  let diagnostic : Diagnostic = {
    id,
    severity,
    message,
    node_id,
    edge_id,
    position,
  }
  let key = anchor.unwrap_or("")
  match self.reported.get(key) {
    None => self.reported[key] = [diagnostic]
    Some(same) => {
      if same.iter().any(d => same_finding(d, diagnostic)) {
        return
      }
      same.push(diagnostic)
    }
  }
  self.diagnostics.push(diagnostic)
}
