///|
pub(all) enum NodeKind {
  Service
  Junction
}

///|
/// A service or a junction; only a service has an icon, an icon text, or a title.
pub(all) struct ArchNode {
  id : String
  kind : NodeKind
  icon : String?
  icon_text : String?
  title : String?
  parent : String?
}

///|
pub(all) struct ArchGroup {
  id : String
  icon : String?
  title : String?
  parent : String?
}

///|
/// An edge between two nodes; `into` is an arrowhead at that end, and `group` says the edge
/// meets the border of the node's group instead of the node.
pub(all) struct ArchEdge {
  lhs_id : String
  lhs_dir : Side
  lhs_into : Bool
  lhs_group : Bool
  rhs_id : String
  rhs_dir : Side
  rhs_into : Bool
  rhs_group : Bool
  title : String?
}

///|
/// An `align` statement; `direction` is `row` or `column`.
pub(all) struct ArchLayoutHint {
  direction : String
  members : Array[String]
}

///|
/// An architecture diagram ready to be laid out, built as Mermaid's database builds it.
pub struct ArchitectureDb {
  mut title : String?
  mut acc_title : String?
  mut acc_descr : String?
  nodes : Map[String, ArchNode]
  groups : Map[String, ArchGroup]
  edges : Array[ArchEdge]
  layout_hints : Array[ArchLayoutHint]
  /// Every id in use, and whether it is a group's.
  priv registered : Map[String, Bool]
}

///|
pub fn ArchitectureDb::new() -> ArchitectureDb {
  {
    title: None,
    acc_title: None,
    acc_descr: None,
    nodes: {},
    groups: {},
    edges: [],
    layout_hints: [],
    registered: {},
  }
}

///|
fn fail(message : String) -> @errors.PeleError {
  @errors.pele_error(message, code=Semantic, kind="architecture")
}

///|
fn owner(is_group : Bool) -> String {
  if is_group {
    "group"
  } else {
    "node"
  }
}

///|
fn ArchitectureDb::register(
  self : ArchitectureDb,
  kind : String,
  id : String,
  parent : String?,
) -> Unit raise @errors.PeleError {
  if self.registered.get(id) is Some(is_group) {
    raise fail(
      "The \{kind} id [\{id}] is already in use by another \{owner(is_group)}",
    )
  }
  if parent is Some(parent) {
    if id == parent {
      raise fail("The \{kind} [\{id}] cannot be placed within itself")
    }
    match self.registered.get(parent) {
      None =>
        raise fail(
          "The \{kind} [\{id}]'s parent does not exist. Please make sure the parent is created before this \{kind}",
        )
      Some(false) => raise fail("The \{kind} [\{id}]'s parent is not a group")
      Some(true) => ()
    }
  }
  self.registered.set(id, kind == "group")
}

///|
/// Adds a service.
/// Raises a semantic `PeleError` for an id in use or a parent that is not a declared group.
pub fn ArchitectureDb::add_service(
  self : ArchitectureDb,
  id : String,
  icon? : String,
  icon_text? : String,
  title? : String,
  parent? : String,
) -> Unit raise @errors.PeleError {
  self.register("service", id, parent)
  self.nodes.set(id, { id, kind: Service, icon, icon_text, title, parent, })
}

///|
/// Adds a junction.
/// Raises a semantic `PeleError` for an id in use or a parent that is not a declared group.
pub fn ArchitectureDb::add_junction(
  self : ArchitectureDb,
  id : String,
  parent? : String,
) -> Unit raise @errors.PeleError {
  self.register("junction", id, parent)
  self.nodes.set(id, {
    id,
    kind: Junction,
    icon: None,
    icon_text: None,
    title: None,
    parent,
  })
}

///|
/// Adds a group.
/// Raises a semantic `PeleError` for an id in use or a parent that is not a declared group.
pub fn ArchitectureDb::add_group(
  self : ArchitectureDb,
  id : String,
  icon? : String,
  title? : String,
  parent? : String,
) -> Unit raise @errors.PeleError {
  self.register("group", id, parent)
  self.groups.set(id, { id, icon, title, parent, })
}

///|
/// Adds an edge.
/// Raises a semantic `PeleError` for an end that is not a declared node, or a `{group}` end of
/// an edge that stays within one group.
pub fn ArchitectureDb::add_edge(
  self : ArchitectureDb,
  edge : ArchEdge,
) -> Unit raise @errors.PeleError {
  let ends = [
    ("left", edge.lhs_id, edge.lhs_group),
    ("right", edge.rhs_id, edge.rhs_group),
  ]
  for end in ends {
    let (side, id, _) = end
    if !self.registered.contains(id) {
      raise fail(
        "The \{side}-hand id [\{id}] does not yet exist. Please create the service/group before declaring an edge to it.",
      )
    }
  }
  // Mermaid lets a group id through the check above and then fails with a TypeError.
  for end in ends {
    let (side, id, _) = end
    if !self.nodes.contains(id) {
      raise fail(
        "The \{side}-hand id [\{id}] is a group. Add {group} to a service inside it instead.",
      )
    }
  }
  let parent = self.nodes.get(edge.lhs_id).unwrap().parent
  if parent is Some(_) && parent == self.nodes.get(edge.rhs_id).unwrap().parent {
    for end in ends {
      let (side, id, crosses) = end
      if crosses {
        raise fail(
          "The \{side}-hand id [\{id}] is modified to traverse the group boundary, but the edge does not pass through two groups.",
        )
      }
    }
  }
  self.edges.push(edge)
}

///|
/// Adds an alignment.
/// Raises a semantic `PeleError` unless it names at least two distinct nodes.
pub fn ArchitectureDb::add_layout_hint(
  self : ArchitectureDb,
  hint : ArchLayoutHint,
) -> Unit raise @errors.PeleError {
  if hint.members.length() < 2 {
    raise fail(
      "An align directive requires at least two members; got \{hint.members.length()}",
    )
  }
  let seen : Set[String] = Set([])
  for id in hint.members {
    if !(self.registered.get(id) is Some(false)) {
      raise fail(
        "align \{hint.direction} references [\{id}], which is not a service or junction",
      )
    }
    if seen.contains(id) {
      raise fail("align \{hint.direction} lists [\{id}] more than once")
    }
    seen.add(id)
  }
  self.layout_hints.push(hint)
}

///|
/// Does what `text.replace(/\n\s+/g, '\n')` does.
fn join_indented_lines(text : String) -> String {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    @util.write_range(out, text, i, i + 1)
    if @util.code_at(text, i) == '\n'.to_int() &&
      @util.is_space(@util.code_at(text, i + 1)) {
      i += 1
      while @util.is_space(@util.code_at(text, i)) {
        i += 1
      }
    } else {
      i += 1
    }
  }
  out.to_string()
}

///|
fn non_empty(value : String?) -> String? {
  match value {
    Some("") => None
    _ => value
  }
}

///|
/// Fills `db` from the statements of a diagram, as Mermaid's `populateDb` does: every group,
/// then services, junctions, edges, and alignments.
/// Raises a semantic `PeleError` where a statement contradicts an earlier one.
pub fn populate(
  ast : ArchitectureAst,
  db : ArchitectureDb,
) -> Unit raise @errors.PeleError {
  if non_empty(ast.acc_descr) is Some(descr) {
    db.acc_descr = Some(join_indented_lines(descr))
  }
  if non_empty(ast.acc_title) is Some(title) {
    db.acc_title = Some(@util.trim_start(title))
  }
  if non_empty(ast.title) is Some(text) {
    db.title = Some(text)
  }
  for group in ast.groups {
    db.add_group(
      group.id,
      icon?=group.icon,
      title?=group.title,
      parent?=group.parent,
    )
  }
  for service in ast.services {
    db.add_service(
      service.id,
      icon?=service.icon,
      icon_text?=service.icon_text,
      title?=service.title,
      parent?=service.parent,
    )
  }
  for junction in ast.junctions {
    db.add_junction(junction.id, parent?=junction.parent)
  }
  for edge in ast.edges {
    db.add_edge({
      lhs_id: edge.lhs_id,
      lhs_dir: edge.lhs_dir,
      lhs_into: edge.lhs_into,
      lhs_group: edge.lhs_group,
      rhs_id: edge.rhs_id,
      rhs_dir: edge.rhs_dir,
      rhs_into: edge.rhs_into,
      rhs_group: edge.rhs_group,
      title: edge.title,
    })
  }
  for alignment in ast.alignments {
    db.add_layout_hint({
      direction: alignment.direction,
      members: alignment.members.copy(),
    })
  }
}
