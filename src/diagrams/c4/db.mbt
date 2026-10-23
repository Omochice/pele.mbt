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
  }
}

///|
pub fn C4Db::set_c4_type(self : C4Db, type_ : String) -> Unit {
  self.c4_type = None
  ignore(type_)
}

///|
pub fn C4Db::set_title(self : C4Db, title : String) -> Unit {
  self.title = None
  ignore(title)
}

///|
/// Sets the description, with the indentation after each line break removed.
pub fn C4Db::set_acc_description(self : C4Db, descr : String) -> Unit {
  self.acc_descr = None
  ignore(descr)
}

///|
/// Adds or updates a person or system from: alias, label, ?descr, ?sprite, ?tags, $link.
pub fn C4Db::add_person_or_system(
  self : C4Db,
  kind : String,
  attrs : Array[C4Attr],
) -> Unit {
  ignore(self)
  ignore(kind)
  ignore(attrs)
}

///|
/// Adds or updates a container from: alias, label, ?techn, ?descr, ?sprite, ?tags, $link.
pub fn C4Db::add_container(
  self : C4Db,
  kind : String,
  attrs : Array[C4Attr],
) -> Unit {
  ignore(self)
  ignore(kind)
  ignore(attrs)
}

///|
/// Adds or updates a component, which takes the arguments of a container.
pub fn C4Db::add_component(
  self : C4Db,
  kind : String,
  attrs : Array[C4Attr],
) -> Unit {
  ignore(self)
  ignore(kind)
  ignore(attrs)
}

///|
/// Opens a boundary from: alias, label, ?type, ?tags, $link.
pub fn C4Db::add_person_or_system_boundary(
  self : C4Db,
  attrs : Array[C4Attr],
  fallback~ : String = "system",
) -> Unit {
  ignore(self)
  ignore(attrs)
  ignore(fallback)
}

///|
/// Opens a container boundary, which takes the arguments of a system boundary.
pub fn C4Db::add_container_boundary(self : C4Db, attrs : Array[C4Attr]) -> Unit {
  ignore(self)
  ignore(attrs)
}

///|
/// Opens a deployment node from: alias, label, ?type, ?descr, ?sprite, ?tags, $link.
pub fn C4Db::add_deployment_node(
  self : C4Db,
  node_type : String,
  attrs : Array[C4Attr],
) -> Unit {
  ignore(self)
  ignore(node_type)
  ignore(attrs)
}

///|
/// Closes the innermost open boundary.
pub fn C4Db::pop_boundary_parse_stack(self : C4Db) -> Unit {
  ignore(self)
}

///|
/// Adds or updates a relation from: from, to, label, ?techn, ?descr, ?sprite, ?tags, $link.
/// A relation without a label is ignored.
pub fn C4Db::add_rel(
  self : C4Db,
  type_ : String,
  attrs : Array[C4Attr],
) -> Unit {
  ignore(self)
  ignore(type_)
  ignore(attrs)
}

///|
/// The shape with this alias, else the boundary with it.
pub fn C4Db::get_c4_shape(self : C4Db, alias_ : String) -> C4Element? {
  ignore(self)
  ignore(alias_)
  None
}

///|
/// Styles a shape or boundary from: elementName, ?bgColor, ?fontColor, ?borderColor, ?shadowing, ?shape, ?sprite, ?techn, ?legendText, ?legendSprite.
pub fn C4Db::update_el_style(self : C4Db, attrs : Array[C4Attr]) -> Unit {
  ignore(self)
  ignore(attrs)
}

///|
/// Styles a relation from: from, to, ?textColor, ?lineColor, ?offsetX, ?offsetY.
pub fn C4Db::update_rel_style(self : C4Db, attrs : Array[C4Attr]) -> Unit {
  ignore(self)
  ignore(attrs)
}

///|
/// Sets the layout from: ?c4ShapeInRow, ?c4BoundaryInRow.
/// As in Mermaid, the slot decides which one a value sets, not its name.
pub fn C4Db::update_layout_config(self : C4Db, attrs : Array[C4Attr]) -> Unit {
  self.shape_in_row = 4
  self.boundary_in_row = 2
  ignore(attrs)
}
