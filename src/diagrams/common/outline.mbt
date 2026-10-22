// The indented outline grammar that Mermaid's mindmap and kanban diagrams share.
// Kanban adds `@{ ... }` metadata after a node and keeps `@` out of node ids.

///|
/// A token type of the outline grammar.
pub(all) enum OutlineToken {
  End
  Invalid
  Spaceline
  Nl
  Eof
  Keyword
  Spacelist
  Icon
  Class
  NodeDstart
  NodeId
  NodeDescr
  NodeDend
  ShapeData
}

///|
/// The token's name as the generated parser prints it in an error, which for the end of input is its number.
pub fn OutlineToken::name(self : OutlineToken, kanban : Bool) -> String {
  ignore((self, kanban))
  ""
}

///|
/// An outline's tokens as parallel arrays: the type of each, its text, and where it starts.
pub(all) struct OutlineTokens {
  types : Array[OutlineToken]
  texts : Array[String]
  starts : Array[Int32]
}

///|
/// Splits a mindmap, or with `kanban` a kanban, into tokens as Mermaid's lexer does.
/// Text the lexer cannot read ends the list with an `Invalid` token where it stops.
pub fn tokenize_outline(src : String, kanban : Bool) -> OutlineTokens {
  ignore((src, kanban))
  { types: [], texts: [], starts: [], }
}

///|
/// A node drawn without a shape.
pub const NODE_TYPE_DEFAULT : Int32 = 0

///|
/// Mermaid's alias of the default node type.
pub const NODE_TYPE_NO_BORDER : Int32 = 0

///|
pub const NODE_TYPE_ROUNDED_RECT : Int32 = 1

///|
pub const NODE_TYPE_RECT : Int32 = 2

///|
pub const NODE_TYPE_CIRCLE : Int32 = 3

///|
pub const NODE_TYPE_CLOUD : Int32 = 4

///|
pub const NODE_TYPE_BANG : Int32 = 5

///|
pub const NODE_TYPE_HEXAGON : Int32 = 6

///|
/// The node type of a node written between `start` and `end`.
pub fn outline_node_type(start : String, end : String) -> Int32 {
  ignore((start, end))
  -1
}

///|
/// What an `::icon()` or `:::class` line adds to the node before it.
pub(all) enum Decoration {
  Icon(String)
  Class(String)
}

///|
/// The model an outline is parsed into, called as the grammar's actions call Mermaid's database.
pub(open) trait OutlineDb {
  /// Adds a node indented by `level`, with the metadata written after it, if any.
  fn add_node(
    Self,
    level : Int32,
    id : String,
    descr : String,
    node_type : Int32,
    shape_data : String?,
  ) -> Unit raise @errors.PeleError
  /// Decorates the node added last.
  fn decorate_node(Self, Decoration) -> Unit
}

///|
/// Parses a mindmap, or with `kanban` a kanban, into `db`, making the calls the grammar's actions make in the same order.
/// Raises the syntax error the generated parser would, in the same state.
pub fn[Db : OutlineDb] parse_outline(
  src : String,
  db : Db,
  kanban : Bool,
) -> Unit raise @errors.PeleError {
  ignore(src)
  if kanban {
    db.add_node(0, "", "", 0, None)
  }
}
