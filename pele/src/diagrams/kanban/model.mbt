///|
/// A column or a card of a board.
pub(all) struct KanbanNode {
  id : String
  level : Int32
  mut label : String
  mut icon : String?
  mut assigned : String?
  mut ticket : String?
  mut priority : String?
  mut css_classes : String?
  /// The cards of a column; always empty for a card.
  items : Array[KanbanNode]
}

///|
/// A kanban board ready to be drawn.
pub(all) struct KanbanModel {
  title : String?
  sections : Array[KanbanNode]
}

///|
priv struct KanbanDb {
  sections : Array[KanbanNode]
  mut last : KanbanNode?
  mut section_level : Int32
  mut misplaced : KanbanNode?
}

///|
fn kanban_error(
  message : String,
  code : @errors.ErrorCode,
) -> @errors.PeleError {
  @errors.pele_error(message, code~, kind="kanban")
}

///|
/// Applies the keys of a node's `@{ ... }` metadata to it.
fn apply_metadata(
  node : KanbanNode,
  shape_data : String,
) -> Unit raise @errors.PeleError {
  let yaml = if shape_data.contains("\n") {
    shape_data + "\n"
  } else {
    "{\n" + shape_data + "\n}"
  }
  let doc = @util.parse_yaml(yaml) catch {
    @util.YamlError(message) =>
      raise kanban_error(
        "Metadata of \"\{node.id}\" is not valid YAML. \{message}",
        Syntax,
      )
  }
  // Mermaid throws a TypeError on metadata that is empty or not a mapping, which pele ignores.
  guard doc is Object(map) else { return }
  let truthy = (key : String) => {
    match map.get(key) {
      Some(value) if @util.js_truthy(value) => Some(@util.js_string(value))
      _ => None
    }
  }
  let shape = truthy("shape").unwrap_or("")
  if shape != shape.to_lower() || shape.contains("_") {
    raise kanban_error(
      "No such shape: \{shape}. Shape names should be lowercase.",
      Semantic,
    )
  }
  if truthy("label") is Some(label) {
    node.label = label
  }
  if truthy("icon") is Some(value) {
    node.icon = Some(value)
  }
  if truthy("assigned") is Some(value) {
    node.assigned = Some(value)
  }
  if truthy("ticket") is Some(value) {
    node.ticket = Some(value)
  }
  if truthy("priority") is Some(value) {
    node.priority = Some(value)
  }
}

///|
impl @common.OutlineDb for KanbanDb with fn add_node(
  self,
  level,
  id,
  descr,
  _node_type,
  shape_data,
) {
  let node : KanbanNode = {
    id,
    level,
    label: descr,
    icon: None,
    assigned: None,
    ticket: None,
    priority: None,
    css_classes: None,
    items: [],
  }
  if shape_data is Some(data) {
    apply_metadata(node, data)
  }
  // A node indented less than the first column becomes a card, and Mermaid rejects whatever follows it.
  if self.misplaced is Some(misplaced) {
    raise kanban_error(
      "Items without section detected, found section (\"\{misplaced.label}\")",
      Semantic,
    )
  }
  if self.sections.is_empty() {
    self.section_level = level
  }
  self.last = Some(node)
  if level == self.section_level {
    self.sections.push(node)
  } else {
    self.sections[self.sections.length() - 1].items.push(node)
    if level < self.section_level {
      self.misplaced = Some(node)
    }
  }
}

///|
impl @common.OutlineDb for KanbanDb with fn decorate_node(self, decoration) {
  // Mermaid throws a TypeError when a decoration comes before any node, which pele ignores.
  guard self.last is Some(node) else { return }
  match decoration {
    Icon(icon) => if icon != "" { node.icon = Some(icon) }
    Class(class) => if class != "" { node.css_classes = Some(class) }
  }
}

///|
/// Reads a kanban diagram into its columns and cards.
/// `title` is the front matter title.
pub fn parse_kanban(
  source : String,
  title : String?,
) -> KanbanModel raise @errors.PeleError {
  let db : KanbanDb = {
    sections: [],
    last: None,
    section_level: 0,
    misplaced: None,
  }
  @common.parse_outline(source, db, true)
  { title, sections: db.sections, }
}
