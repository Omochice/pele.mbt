///|
/// The shape Mermaid names for the brackets around a block's label.
pub fn type_str_to_type(_type_str : String?) -> String {
  ""
}

///|
/// The marker at the end of a link.
pub fn edge_str_to_edge_data(_type_str : String) -> String {
  ""
}

///|
/// The marker at the start of a link.
pub fn edge_str_to_edge_start_data(_type_str : String) -> String {
  ""
}

///|
pub fn edge_str_to_thickness(_type_str : String) -> String {
  ""
}

///|
pub fn edge_str_to_pattern(_type_str : String) -> String {
  ""
}

///|
/// A block diagram: its tree of blocks under `root`, its edges, and its classes.
pub struct BlockDb {
  title : String?
  root : Block
  mut blocks : Array[Block]
  edges : Array[Block]
  classes : Map[String, BlockClassDef]
  by_id : Map[String, Block]
}

///|
/// An empty diagram. `warn` hears of blocks wider than their grid, which Mermaid logs.
pub fn BlockDb::new(title? : String, warn? : (String) -> Unit) -> BlockDb {
  ignore(warn)
  {
    title,
    root: Block::new("root", "composite"),
    blocks: [],
    edges: [],
    classes: {},
    by_id: {},
  }
}

///|
pub fn BlockDb::generate_id(_self : BlockDb) -> String {
  ""
}

///|
/// Builds the tree from the statements of a document.
pub fn BlockDb::set_hierarchy(
  self : BlockDb,
  statements : Array[Statement],
) -> Unit raise @errors.PeleError {
  if statements.length() < 0 {
    raise @errors.pele_error("not yet built")
  }
  self.blocks = []
}
