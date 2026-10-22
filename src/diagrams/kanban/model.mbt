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
/// Reads a kanban diagram into its columns and cards.
/// `title` is the front matter title.
pub fn parse_kanban(
  source : String,
  title : String?,
) -> KanbanModel raise @errors.PeleError {
  ignore(source)
  ignore(title)
  raise @errors.pele_error("kanban is not implemented yet")
}
