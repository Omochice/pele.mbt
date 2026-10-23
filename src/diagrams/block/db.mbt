///|
const MAX_SPACES : Double = 100000

///|
/// The shape Mermaid names for the brackets around a block's label.
pub fn type_str_to_type(type_str : String?) -> String {
  match type_str {
    Some("[]") => "square"
    Some("()") => "round"
    Some("(())") => "circle"
    Some(">]") => "rect_left_inv_arrow"
    Some("{}") => "diamond"
    Some("{{}}") => "hexagon"
    Some("([])") => "stadium"
    Some("[[]]") => "subroutine"
    Some("[()]") => "cylinder"
    Some("((()))") => "doublecircle"
    Some("[//]") => "lean_right"
    Some("[\\\\]") => "lean_left"
    Some("[/\\]") => "trapezoid"
    Some("[\\/]") => "inv_trapezoid"
    Some("<[]>") => "block_arrow"
    _ => "na"
  }
}

///|
/// The marker at the end of a link.
pub fn edge_str_to_edge_data(type_str : String) -> String {
  let trimmed = @util.trim(type_str)
  match @util.code_at(trimmed, trimmed.length() - 1) {
    120 => "arrow_cross"
    111 => "arrow_circle"
    62 => "arrow_point"
    _ => ""
  }
}

///|
/// The marker at the start of a link.
pub fn edge_str_to_edge_start_data(type_str : String) -> String {
  match @util.code_at(@util.trim(type_str), 0) {
    120 => "arrow_cross"
    111 => "arrow_circle"
    60 => "arrow_point"
    _ => "arrow_open"
  }
}

///|
pub fn edge_str_to_thickness(type_str : String) -> String {
  if type_str.contains("==") {
    "thick"
  } else {
    "normal"
  }
}

///|
pub fn edge_str_to_pattern(type_str : String) -> String {
  if type_str.contains(".-") {
    "dotted"
  } else {
    "solid"
  }
}

///|
/// The statements of one document still to place, and the children placed so far.
priv struct Frame {
  list : Array[Block]
  mut at : Int32
  parent : Block
  children : Array[Block]
  columns : Double
}

///|
fn frame(list : Array[Block], parent : Block) -> Frame {
  let mut columns = -1.0
  for block in list {
    if block.kind == "column-setting" {
      columns = block.columns
      break
    }
  }
  { list, at: 0, parent, children: [], columns, }
}

///|
/// A block diagram: its tree of blocks under `root`, its edges, and its classes.
pub struct BlockDb {
  title : String?
  root : Block
  mut blocks : Array[Block]
  edges : Array[Block]
  classes : Map[String, BlockClassDef]
  /// Every block by id, apart from the root: Mermaid keeps the root in here too, which makes a block called `root` vanish.
  by_id : Map[String, Block]
  priv warn : ((String) -> Unit)?
  /// Ids that a class or style statement named before any block had them.
  priv pending : Set[String]
  priv edge_count : Map[String, Int32]
  priv mut ids : Int32
  priv mut colors : Int32
  priv mut spaces : Double
}

///|
/// An empty diagram. `warn` hears of blocks wider than their grid, which Mermaid logs.
pub fn BlockDb::new(title? : String, warn? : (String) -> Unit) -> BlockDb {
  {
    title,
    root: Block::new("root", "composite"),
    blocks: [],
    edges: [],
    classes: {},
    by_id: {},
    warn,
    pending: Set([]),
    edge_count: {},
    ids: 0,
    colors: 0,
    spaces: 0,
  }
}

///|
/// A fresh id for a block the source does not name.
/// Mermaid's ids are random; these are counted, so the same text always gives the same output.
pub fn BlockDb::generate_id(self : BlockDb) -> String {
  self.ids += 1
  "id-\{self.ids}"
}

///|
fn replace_first(text : String, old : String, new : String) -> String {
  let at = @util.index_of(text, old)
  if at == -1 {
    return text
  }
  @util.slice(text, 0, end=at) + new + @util.slice(text, at + old.length())
}

///|
fn split_on(text : String, separator : String) -> Array[String] {
  text.split(separator).map(part => part.to_owned()).to_array()
}

///|
/// Adds the comma-separated declarations to the class, creating it when it is new.
pub fn BlockDb::add_style_class(
  self : BlockDb,
  id : String,
  style_attributes~ : String = "",
) -> Unit {
  let found = match self.classes.get(id) {
    Some(found) => found
    None => {
      let made = { id, styles: [], text_styles: [], }
      self.classes.set(id, made)
      made
    }
  }
  for attribute in split_on(style_attributes, ",") {
    let semi = @util.index_of(attribute, ";")
    let fixed = @util.trim(
      if semi == -1 {
        attribute
      } else {
        @util.slice(attribute, 0, end=semi) + @util.slice(attribute, semi + 1)
      },
    )
    if attribute.contains("color") {
      found.text_styles.push(
        replace_first(replace_first(fixed, "fill", "bgFill"), "color", "fill"),
      )
    }
    found.styles.push(fixed)
  }
}

///|
/// Replaces the inline styles of the block.
pub fn BlockDb::add_style_to_node(
  self : BlockDb,
  id : String,
  styles : String,
) -> Unit {
  self.named(id).styles = split_on(styles, ",")
}

///|
/// Gives the class to each block in a comma-separated list.
/// Mermaid looks each id up before trimming it, so `class a, b hot` misses b; here it is trimmed first.
pub fn BlockDb::set_css_class(
  self : BlockDb,
  item_ids : String,
  css_class_name : String,
) -> Unit {
  for id in split_on(item_ids, ",") {
    self.named(@util.trim(id)).classes.push(css_class_name)
  }
}

///|
/// The block of that id, or a stand-in that waits for it.
/// Mermaid throws on a style for an unknown id, and a class for one makes the block of that id disappear when it is declared later.
fn BlockDb::named(self : BlockDb, id : String) -> Block {
  match self.by_id.get(id) {
    Some(block) => block
    None => {
      let block = Block::new(id, "na")
      self.by_id.set(id, block)
      self.pending.add(id)
      block
    }
  }
}

///|
fn BlockDb::warn_wide(self : BlockDb, f : Frame, block : Block) -> Unit {
  if f.columns > 0 &&
    block.kind != "column-setting" &&
    block.width_in_columns is Some(span) &&
    span > f.columns {
    if self.warn is Some(warn) {
      warn(
        "Block \{block.id} width \{span} exceeds configured column width \{f.columns}",
      )
    }
  }
}

///|
/// Builds the tree from the statements of a document.
/// Composites nest without recursion, so deep nesting cannot exhaust the stack.
pub fn BlockDb::set_hierarchy(
  self : BlockDb,
  statements : Array[Statement],
) -> Unit raise @errors.PeleError {
  let list = []
  for statement in statements {
    match statement {
      One(block) => list.push(block)
      Chain(blocks) => list.append(blocks)
    }
  }
  let stack = [frame(list, self.root)]
  while stack.last() is Some(f) {
    if f.at == f.list.length() {
      f.parent.children = f.children
      stack.pop() |> ignore
      continue
    }
    let block = f.list[f.at]
    f.at += 1
    self.warn_wide(f, block)
    match block.kind {
      "classDef" => {
        self.add_style_class(block.id, style_attributes=block.css)
        continue
      }
      "applyClass" => {
        self.set_css_class(block.id, block.style_class)
        continue
      }
      "applyStyles" => {
        if block.styles_str != "" {
          self.add_style_to_node(block.id, block.styles_str)
        }
        continue
      }
      "column-setting" => {
        f.parent.columns = block.columns
        continue
      }
      "edge" => {
        let count = self.edge_count.get(block.id).unwrap_or(0) + 1
        self.edge_count.set(block.id, count)
        block.id = "\{count}-\{block.id}"
        self.edges.push(block)
        continue
      }
      _ => ()
    }
    if block.id == "" {
      block.id = self.generate_id()
    }
    if block.label == "" {
      block.label = if block.kind == "composite" { "" } else { block.id }
    }
    let known = self.by_id.get(block.id)
    let fresh = match known {
      None => true
      Some(_) =>
        if self.pending.contains(block.id) {
          self.pending.remove(block.id)
          true
        } else {
          false
        }
    }
    match known {
      Some(known) if !fresh => {
        if block.kind != "na" {
          known.kind = block.kind
        }
        if block.label != block.id {
          known.label = block.label
        }
      }
      _ => {
        if known is Some(known) {
          block.classes = known.classes
          block.styles = known.styles
        }
        if block.kind == "composite" {
          block.color_index = Some(self.colors)
          self.colors += 1
        }
        self.by_id.set(block.id, block)
      }
    }
    let inner = block.children
    block.children = []
    if block.kind == "space" {
      let width = block.width
      if !(width <= MAX_SPACES - self.spaces) {
        raise @errors.pele_error(
          "A block diagram can hold at most 100000 space blocks.",
          code=Limit,
          kind="block",
        )
      }
      self.spaces += @util.js_max(width, 0)
      let mut j = 0
      while j.to_double() < width {
        let copy = { ..block, id: "\{block.id}-\{j}", children: [], }
        self.by_id.set(copy.id, copy)
        f.children.push(copy)
        j += 1
      }
    } else if fresh {
      f.children.push(block)
    }
    if inner.length() > 0 {
      stack.push(frame(inner, block))
    }
  }
  self.blocks = self.root.children
}
