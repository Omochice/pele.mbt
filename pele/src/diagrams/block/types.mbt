///|
/// One shape for blocks, edges, and the statements that set columns, classes, and styles, as in Mermaid.
/// `kind` is Mermaid's `type`, and an empty `id` stands for a block that has none yet.
pub(all) struct Block {
  mut id : String
  mut kind : String
  mut label : String
  mut children : Array[Block]
  /// The grid width of a composite: a positive count, or -1 to put every child on one row.
  mut columns : Double
  width_in_columns : Double?
  /// The number of cells a `space` statement asked for.
  width : Double
  directions : Array[String]
  mut classes : Array[String]
  mut styles : Array[String]
  mut color_index : Int32?
  start : String
  end : String
  arrow_type_start : String
  arrow_type_end : String
  thickness : String
  pattern : String
  css : String
  style_class : String
  styles_str : String
}

///|
/// A block with every field it does not name left empty.
pub fn Block::new(
  id : String,
  kind : String,
  label~ : String = "",
  children~ : Array[Block] = [],
  columns~ : Double = -1,
  width_in_columns? : Double,
  width~ : Double = 1,
  directions~ : Array[String] = [],
  start~ : String = "",
  end~ : String = "",
  arrow_type_start~ : String = "",
  arrow_type_end~ : String = "",
  thickness~ : String = "",
  pattern~ : String = "",
  css~ : String = "",
  style_class~ : String = "",
  styles_str~ : String = "",
) -> Block {
  {
    id,
    kind,
    label,
    children,
    columns,
    width_in_columns,
    width,
    directions,
    classes: [],
    styles: [],
    color_index: None,
    start,
    end,
    arrow_type_start,
    arrow_type_end,
    thickness,
    pattern,
    css,
    style_class,
    styles_str,
  }
}

///|
/// A statement of the grammar: one block, or a block linked to others, as block, edge, block, and so on.
pub(all) enum Statement {
  One(Block)
  Chain(Array[Block])
}

///|
/// A class: the declarations of its `classDef` statements, and those of them that apply to text.
pub(all) struct BlockClassDef {
  id : String
  styles : Array[String]
  text_styles : Array[String]
}
