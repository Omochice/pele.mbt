///|
fn AgentflowDb::position(self : AgentflowDb, loc : Loc) -> ElementPosition {
  {
    start_line: loc.first_line + self.line_offset,
    start_column: loc.first_column,
    end_line: loc.last_line + self.line_offset,
    end_column: loc.last_column,
    start_index: 0,
    end_index: 0,
  }
}

///|
fn AgentflowDb::push_mapping(
  self : AgentflowDb,
  id : String,
  kind : String,
  position : ElementPosition,
) -> ElementMapping {
  let mapping : ElementMapping = { id, kind, position, }
  self.mappings.push(mapping)
  if !self.first_mapping.contains(id) {
    self.first_mapping[id] = mapping
  }
  mapping
}

///|
/// Records where a node is written.
/// A bare reference, written without a shape, becomes an attachment if a metadata block follows it.
pub fn AgentflowDb::add_vertex_mapping(
  self : AgentflowDb,
  id : String,
  shape : String?,
  loc : Loc,
) -> Unit {
  if id == "" {
    return
  }
  ignore(self.push_mapping(id, "vertex", self.position(loc)))
  if shape is None {
    self.bare_mappings[self.mappings.length() - 1] = ()
  }
}

///|
/// Widens a node's span over the metadata block that follows it, or records the block alone.
pub fn AgentflowDb::extend_vertex_mapping(
  self : AgentflowDb,
  id : String,
  loc : Loc,
) -> Unit {
  if id == "" {
    return
  }
  let end = self.position(loc)
  for i = self.mappings.length() - 1; i >= 0; i = i - 1 {
    let m = self.mappings[i]
    if m.kind != "vertex" || m.id != id {
      continue
    }
    if self.bare_mappings.contains(i) {
      self.bare_mappings.remove(i)
      m.kind = "attachment"
    }
    let p = m.position
    if end.end_line > p.end_line ||
      (end.end_line == p.end_line && end.end_column > p.end_column) {
      p.end_line = end.end_line
      p.end_column = end.end_column
    }
    return
  }
  ignore(self.push_mapping(id, "attachment", end))
}

///|
/// Records where an edge statement is written, named after the nodes it leads to.
pub fn AgentflowDb::add_edge_mapping(
  self : AgentflowDb,
  to_nodes : Array[String],
  loc : Loc,
) -> Unit {
  let ids = to_nodes.filter(id => id != "")
  let id = if ids.is_empty() { "edge" } else { ids.join(">") }
  ignore(self.push_mapping(id, "edge", self.position(loc)))
}

///|
fn AgentflowDb::block_mapping(
  self : AgentflowDb,
  id : String,
  kind : String,
  start : Loc,
  end : Loc,
) -> Unit {
  if id == "" {
    return
  }
  let start = self.position(start)
  let end = self.position(end)
  ignore(
    self.push_mapping(id, kind, {
      start_line: start.start_line,
      start_column: start.start_column,
      end_line: end.end_line,
      end_column: end.end_column,
      start_index: 0,
      end_index: 0,
    }),
  )
}

///|
/// Records a flow from its keyword to its `end`.
pub fn AgentflowDb::add_subgraph_mapping(
  self : AgentflowDb,
  id : @flowchart.FlowText?,
  start : Loc,
  end : Loc,
) -> Unit {
  let text = match id {
    Some(t) => t.text
    None => ""
  }
  self.block_mapping(text, "subgraph", start, end)
}

///|
/// Records a connector from its keyword to the end of its line.
pub fn AgentflowDb::add_connector_mapping(
  self : AgentflowDb,
  id : @flowchart.FlowText?,
  start : Loc,
  end : Loc,
) -> Unit {
  let text = match id {
    Some(t) => @util.trim(t.text)
    None => ""
  }
  self.block_mapping(text, "connector", start, end)
}
