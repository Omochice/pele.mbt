///|
/// The model a C4 diagram builds, through the calls Mermaid's grammar makes into c4Db.
pub struct C4Db {
  /// The header keyword: C4Context, C4Container, C4Component, C4Dynamic or C4Deployment.
  mut c4_type : String?
  mut title : String?
  mut acc_descr : String?
  shapes : Array[C4Element]
  /// The first boundary is the unnamed one that holds everything at the top level.
  boundaries : Array[C4Element]
  rels : Array[C4Rel]
  mut shape_in_row : Double
  mut boundary_in_row : Double
  priv shape_index : Map[String, C4Element]
  // The top-level boundary is not listed, so a boundary a diagram names `global` is its own box.
  // In Mermaid it replaces the top level and nothing is drawn.
  priv boundary_index : Map[String, C4Element]
  priv rel_index : Map[String, Map[String, C4Rel]]
  priv mut current : C4Element
  priv stack : Array[C4Element]
}

///|
fn element_new() -> C4Element {
  {
    alias_: "",
    label: "",
    alias_attr: None,
    label_attr: None,
    parent: None,
    type_: None,
    descr: None,
    techn: None,
    sprite: None,
    tags: None,
    link: None,
    bg_color: None,
    font_color: None,
    border_color: None,
    shadowing: None,
    shape: None,
    legend_text: None,
    legend_sprite: None,
    extra: None,
    kind: "",
    node_type: None,
  }
}

///|
/// An empty model, titled from front matter when `title` is given.
pub fn C4Db::new(title? : String) -> C4Db {
  let root = element_new()
  root.alias_ = "global"
  root.label = "global"
  root.type_ = Some("global")
  {
    c4_type: None,
    title: match title {
      Some("") => None
      other => other
    },
    acc_descr: None,
    shapes: [],
    boundaries: [root],
    rels: [],
    shape_in_row: 4,
    boundary_in_row: 2,
    shape_index: {},
    boundary_index: {},
    rel_index: {},
    current: root,
    stack: [],
  }
}

///|
fn keep_extra(
  extra : Map[String, String]?,
  key : String,
  value : String,
) -> Map[String, String] {
  let map = match extra {
    Some(map) => map
    None => {}
  }
  map[key] = value
  map
}

///|
/// Sets the element field a name or a slot stands for; false when no field has that name.
fn set_element_field(el : C4Element, field : String, value : String) -> Bool {
  match field {
    "label" => el.label = value
    "type" => el.type_ = Some(value)
    "descr" => el.descr = Some(value)
    "techn" => el.techn = Some(value)
    "sprite" => el.sprite = Some(value)
    "tags" => el.tags = Some(value)
    "link" => el.link = Some(value)
    "bgColor" => el.bg_color = Some(value)
    "fontColor" => el.font_color = Some(value)
    "borderColor" => el.border_color = Some(value)
    "shadowing" => el.shadowing = Some(value)
    "shape" => el.shape = Some(value)
    "legendText" => el.legend_text = Some(value)
    "legendSprite" => el.legend_sprite = Some(value)
    _ => return false
  }
  true
}

///|
fn set_rel_field(rel : C4Rel, field : String, value : String) -> Bool {
  match field {
    "label" => rel.label = value
    "descr" => rel.descr = Some(value)
    "techn" => rel.techn = Some(value)
    "sprite" => rel.sprite = Some(value)
    "tags" => rel.tags = Some(value)
    "link" => rel.link = Some(value)
    "textColor" => rel.text_color = Some(value)
    "lineColor" => rel.line_color = Some(value)
    _ => return false
  }
  true
}

///|
/// Mermaid assigns a named argument to whatever property it names, structural ones included.
/// Here it reaches only the known fields; any other name is kept aside in `extra`.
fn named_element(el : C4Element, attr : C4Named) -> Unit {
  if !set_element_field(el, attr.key, attr.value) {
    el.extra = Some(keep_extra(el.extra, attr.key, attr.value))
  }
}

///|
fn named_rel(rel : C4Rel, attr : C4Named) -> Unit {
  match attr.key {
    "offsetX" => rel.offset_x = Some(parse_int(attr.value))
    "offsetY" => rel.offset_y = Some(parse_int(attr.value))
    key =>
      if !set_rel_field(rel, key, attr.value) {
        rel.extra = Some(keep_extra(rel.extra, key, attr.value))
      }
  }
}

///|
/// A positional argument fills the field of its slot; a named one fills the field it names, whichever slot it is in.
fn put_element(el : C4Element, field : String, attr : C4Attr?) -> Unit {
  match attr {
    None => ()
    Some(Text(value)) => ignore(set_element_field(el, field, value))
    Some(Named(named)) => named_element(el, named)
  }
}

///|
fn put_rel(rel : C4Rel, field : String, attr : C4Attr?) -> Unit {
  match attr {
    None => ()
    Some(Text(value)) => ignore(set_rel_field(rel, field, value))
    Some(Named(named)) => named_rel(rel, named)
  }
}

///|
fn text_element(el : C4Element, field : String, attr : C4Attr?) -> Unit {
  match attr {
    None => {
      let current = if field == "descr" { el.descr } else { el.techn }
      if current is None {
        ignore(set_element_field(el, field, ""))
      }
    }
    _ => put_element(el, field, attr)
  }
}

///|
fn text_rel(rel : C4Rel, field : String, attr : C4Attr?) -> Unit {
  match attr {
    None => {
      let current = if field == "descr" { rel.descr } else { rel.techn }
      if current is None {
        ignore(set_rel_field(rel, field, ""))
      }
    }
    _ => put_rel(rel, field, attr)
  }
}

///|
fn label_element(el : C4Element, attr : C4Attr?) -> Unit {
  el.label_attr = None
  match attr {
    Some(Named(named)) => {
      el.label = ""
      el.label_attr = Some(named)
      named_element(el, named)
    }
    Some(Text(value)) => el.label = value
    None => el.label = ""
  }
}

///|
fn label_rel(rel : C4Rel, attr : C4Attr?) -> Unit {
  rel.label_attr = None
  match attr {
    Some(Named(named)) => {
      rel.label = ""
      rel.label_attr = Some(named)
      named_rel(rel, named)
    }
    Some(Text(value)) => rel.label = value
    None => rel.label = ""
  }
}

///|
fn arg(attrs : Array[C4Attr], at : Int32) -> C4Attr? {
  attrs.get(at)
}

///|
pub fn C4Db::set_c4_type(self : C4Db, type_ : String) -> Unit {
  self.c4_type = Some(type_)
}

///|
pub fn C4Db::set_title(self : C4Db, title : String) -> Unit {
  self.title = Some(title)
}

///|
/// Sets the description, with the indentation after each line break removed.
pub fn C4Db::set_acc_description(self : C4Db, descr : String) -> Unit {
  // descr.replace(/\n\s+/g, '\n')
  let out = StringBuilder()
  let n = descr.length()
  let mut from = 0
  let mut i = 0
  while i < n {
    if @util.code_at(descr, i) == 10 &&
      @util.is_space(@util.code_at(descr, i + 1)) {
      @util.write_range(out, descr, from, i + 1)
      i += 1
      while i < n && @util.is_space(@util.code_at(descr, i)) {
        i += 1
      }
      from = i
      continue
    }
    i += 1
  }
  @util.write_range(out, descr, from, n)
  self.acc_descr = Some(out.to_string())
}

///|
fn find_or_add(
  list : Array[C4Element],
  index : Map[String, C4Element],
  alias_ : C4Attr,
  title : C4Attr?,
) -> C4Element {
  let found = match alias_ {
    Text(name) => index.get(name)
    Named(_) => None
  }
  let el = match found {
    Some(el) => el
    None => {
      let el = element_new()
      list.push(el)
      match alias_ {
        Text(name) => {
          el.alias_ = name
          index[name] = el
        }
        Named(named) => {
          el.alias_attr = Some(named)
          named_element(el, named)
        }
      }
      el
    }
  }
  label_element(el, title)
  el
}

///|
/// Adds or updates a person or system from: alias, label, ?descr, ?sprite, ?tags, $link.
pub fn C4Db::add_person_or_system(
  self : C4Db,
  kind : String,
  attrs : Array[C4Attr],
) -> Unit {
  let shape = find_or_add(
    self.shapes,
    self.shape_index,
    attrs[0],
    arg(attrs, 1),
  )
  text_element(shape, "descr", arg(attrs, 2))
  self.finish_shape(shape, kind, attrs, 3)
}

///|
/// Adds or updates a container from: alias, label, ?techn, ?descr, ?sprite, ?tags, $link.
pub fn C4Db::add_container(
  self : C4Db,
  kind : String,
  attrs : Array[C4Attr],
) -> Unit {
  let shape = find_or_add(
    self.shapes,
    self.shape_index,
    attrs[0],
    arg(attrs, 1),
  )
  text_element(shape, "techn", arg(attrs, 2))
  text_element(shape, "descr", arg(attrs, 3))
  self.finish_shape(shape, kind, attrs, 4)
}

///|
/// Adds or updates a component, which takes the arguments of a container.
pub fn C4Db::add_component(
  self : C4Db,
  kind : String,
  attrs : Array[C4Attr],
) -> Unit {
  self.add_container(kind, attrs)
}

///|
fn C4Db::finish_shape(
  self : C4Db,
  shape : C4Element,
  kind : String,
  attrs : Array[C4Attr],
  at : Int32,
) -> Unit {
  put_element(shape, "sprite", arg(attrs, at))
  put_element(shape, "tags", arg(attrs, at + 1))
  put_element(shape, "link", arg(attrs, at + 2))
  shape.kind = kind
  shape.parent = Some(self.current)
}

///|
fn C4Db::boundary(
  self : C4Db,
  attrs : Array[C4Attr],
  fallback : String,
) -> C4Element {
  let boundary = find_or_add(
    self.boundaries,
    self.boundary_index,
    attrs[0],
    arg(attrs, 1),
  )
  match arg(attrs, 2) {
    None => boundary.type_ = Some(fallback)
    attr => put_element(boundary, "type", attr)
  }
  boundary
}

///|
fn C4Db::open(self : C4Db, boundary : C4Element) -> Unit {
  boundary.parent = Some(self.current)
  self.stack.push(self.current)
  self.current = boundary
}

///|
/// Opens a boundary from: alias, label, ?type, ?tags, $link.
pub fn C4Db::add_person_or_system_boundary(
  self : C4Db,
  attrs : Array[C4Attr],
  fallback~ : String = "system",
) -> Unit {
  let boundary = self.boundary(attrs, fallback)
  put_element(boundary, "tags", arg(attrs, 3))
  put_element(boundary, "link", arg(attrs, 4))
  self.open(boundary)
}

///|
/// Opens a container boundary, which takes the arguments of a system boundary.
pub fn C4Db::add_container_boundary(self : C4Db, attrs : Array[C4Attr]) -> Unit {
  self.add_person_or_system_boundary(attrs, fallback="container")
}

///|
/// Opens a deployment node from: alias, label, ?type, ?descr, ?sprite, ?tags, $link.
pub fn C4Db::add_deployment_node(
  self : C4Db,
  node_type : String,
  attrs : Array[C4Attr],
) -> Unit {
  let boundary = self.boundary(attrs, "node")
  text_element(boundary, "descr", arg(attrs, 3))
  // Mermaid drops whatever is in the sprite slot, a named argument included; pele keeps it, and so does this port.
  put_element(boundary, "sprite", arg(attrs, 4))
  put_element(boundary, "tags", arg(attrs, 5))
  put_element(boundary, "link", arg(attrs, 6))
  boundary.node_type = Some(node_type)
  self.open(boundary)
}

///|
/// Closes the innermost open boundary.
pub fn C4Db::pop_boundary_parse_stack(self : C4Db) -> Unit {
  self.current = match self.stack.pop() {
    Some(boundary) => boundary
    None => self.boundaries[0]
  }
}

///|
/// Adds or updates a relation from: from, to, label, ?techn, ?descr, ?sprite, ?tags, $link.
/// A relation without a label is ignored.
pub fn C4Db::add_rel(
  self : C4Db,
  type_ : String,
  attrs : Array[C4Attr],
) -> Unit {
  guard attrs.length() >= 3 else { return }
  let from = attrs[0]
  let to = attrs[1]
  let known = match (from, to) {
    (Text(a), Text(b)) => Some((a, b))
    _ => None
  }
  let existing = match known {
    Some((a, b)) =>
      match self.rel_index.get(a) {
        Some(targets) => targets.get(b)
        None => None
      }
    None => None
  }
  let rel = match existing {
    Some(rel) => rel
    None => {
      let rel : C4Rel = {
        type_,
        from: "",
        to: "",
        label: "",
        from_attr: None,
        to_attr: None,
        label_attr: None,
        techn: None,
        descr: None,
        sprite: None,
        tags: None,
        link: None,
        text_color: None,
        line_color: None,
        offset_x: None,
        offset_y: None,
        extra: None,
      }
      self.rels.push(rel)
      if known is Some((a, b)) {
        let targets = match self.rel_index.get(a) {
          Some(targets) => targets
          None => {
            let targets = Map([])
            self.rel_index[a] = targets
            targets
          }
        }
        targets[b] = rel
      }
      match from {
        Text(name) => rel.from = name
        Named(named) => rel.from_attr = Some(named)
      }
      match to {
        Text(name) => rel.to = name
        Named(named) => rel.to_attr = Some(named)
      }
      rel
    }
  }
  rel.type_ = type_
  label_rel(rel, arg(attrs, 2))
  text_rel(rel, "techn", arg(attrs, 3))
  text_rel(rel, "descr", arg(attrs, 4))
  put_rel(rel, "sprite", arg(attrs, 5))
  put_rel(rel, "tags", arg(attrs, 6))
  put_rel(rel, "link", arg(attrs, 7))
}

///|
/// The shape with this alias, else the boundary with it.
pub fn C4Db::get_c4_shape(self : C4Db, alias_ : String) -> C4Element? {
  match self.shape_index.get(alias_) {
    Some(shape) => Some(shape)
    None => self.boundary_index.get(alias_)
  }
}

///|
/// Styles a shape or boundary from: elementName, ?bgColor, ?fontColor, ?borderColor, ?shadowing, ?shape, ?sprite, ?techn, ?legendText, ?legendSprite.
pub fn C4Db::update_el_style(self : C4Db, attrs : Array[C4Attr]) -> Unit {
  guard arg(attrs, 0) is Some(Text(name)) && self.get_c4_shape(name) is Some(el) else {
    return
  }
  put_element(el, "bgColor", arg(attrs, 1))
  put_element(el, "fontColor", arg(attrs, 2))
  put_element(el, "borderColor", arg(attrs, 3))
  put_element(el, "shadowing", arg(attrs, 4))
  put_element(el, "shape", arg(attrs, 5))
  put_element(el, "sprite", arg(attrs, 6))
  put_element(el, "techn", arg(attrs, 7))
  put_element(el, "legendText", arg(attrs, 8))
  put_element(el, "legendSprite", arg(attrs, 9))
}

///|
/// Styles a relation from: from, to, ?textColor, ?lineColor, ?offsetX, ?offsetY.
pub fn C4Db::update_rel_style(self : C4Db, attrs : Array[C4Attr]) -> Unit {
  guard arg(attrs, 0) is Some(Text(from)) &&
    arg(attrs, 1) is Some(Text(to)) &&
    self.rel_index.get(from) is Some(targets) &&
    targets.get(to) is Some(rel) else {
    return
  }
  put_rel(rel, "textColor", arg(attrs, 2))
  put_rel(rel, "lineColor", arg(attrs, 3))
  match arg(attrs, 4) {
    Some(Text(x)) => rel.offset_x = Some(parse_int(x))
    Some(Named(named)) => named_rel(rel, named)
    None => ()
  }
  match arg(attrs, 5) {
    Some(Text(y)) => rel.offset_y = Some(parse_int(y))
    Some(Named(named)) => named_rel(rel, named)
    None => ()
  }
}

///|
/// Sets the layout from: ?c4ShapeInRow, ?c4BoundaryInRow.
/// As in Mermaid, the slot decides which one a value sets, not its name.
pub fn C4Db::update_layout_config(self : C4Db, attrs : Array[C4Attr]) -> Unit {
  let count = (attr : C4Attr?) => {
    match attr {
      None => @double.not_a_number
      Some(Text(value)) => parse_int(value)
      Some(Named(named)) => parse_int(named.value)
    }
  }
  let shapes = count(arg(attrs, 0))
  let boundaries = count(arg(attrs, 1))
  if shapes >= 1 {
    self.shape_in_row = shapes
  }
  if boundaries >= 1 {
    self.boundary_in_row = boundaries
  }
}
