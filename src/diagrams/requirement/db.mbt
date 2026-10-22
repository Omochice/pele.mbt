///|
/// A requirement as declared, with the fields its body gave.
pub(all) struct Requirement {
  name : String
  /// What kind of requirement it is, such as `Functional Requirement`.
  kind : String
  requirement_id : String
  text : String
  risk : String
  verify_method : String
  css_styles : Array[String]
  classes : Array[String]
}

///|
/// An element as declared, with the fields its body gave.
pub(all) struct RequirementElement {
  name : String
  kind : String
  doc_ref : String
  css_styles : Array[String]
  classes : Array[String]
}

///|
/// A relationship from `src` to `dst`, such as `satisfies`.
pub(all) struct Relation {
  kind : String
  src : String
  dst : String
}

///|
/// A class defined by `classDef`.
pub(all) struct RequirementClass {
  id : String
  styles : Array[String]
  text_styles : Array[String]
}

///|
/// The statements of a requirement diagram, collected as the parser reads them.
pub(all) struct RequirementDb {
  mut direction : String
  requirements : Map[String, Requirement]
  elements : Map[String, RequirementElement]
  relations : Array[Relation]
  classes : Map[String, RequirementClass]
  mut title : String?
  mut acc_title : String?
  mut acc_descr : String?
}

///|
/// An empty model running top to bottom.
pub fn RequirementDb::new() -> RequirementDb {
  {
    direction: "TB",
    requirements: Map([]),
    elements: Map([]),
    relations: [],
    classes: Map([]),
    title: None,
    acc_title: None,
    acc_descr: None,
  }
}

///|
pub fn RequirementDb::set_direction(self : RequirementDb, dir : String) -> Unit {
  ignore(self)
  ignore(dir)
}

///|
/// Adds a requirement with the fields read since the last one, unless one of that name exists.
pub fn RequirementDb::add_requirement(
  self : RequirementDb,
  name : String,
  kind : String,
) -> Unit {
  ignore(self)
  ignore(name)
  ignore(kind)
}

///|
pub fn RequirementDb::set_new_req_id(self : RequirementDb, id : String) -> Unit {
  ignore(self)
  ignore(id)
}

///|
pub fn RequirementDb::set_new_req_text(
  self : RequirementDb,
  text : String,
) -> Unit {
  ignore(self)
  ignore(text)
}

///|
pub fn RequirementDb::set_new_req_risk(
  self : RequirementDb,
  risk : String,
) -> Unit {
  ignore(self)
  ignore(risk)
}

///|
pub fn RequirementDb::set_new_req_verify_method(
  self : RequirementDb,
  verify_method : String,
) -> Unit {
  ignore(self)
  ignore(verify_method)
}

///|
/// Adds an element with the fields read since the last one, unless one of that name exists.
pub fn RequirementDb::add_element(self : RequirementDb, name : String) -> Unit {
  ignore(self)
  ignore(name)
}

///|
pub fn RequirementDb::set_new_element_type(
  self : RequirementDb,
  kind : String,
) -> Unit {
  ignore(self)
  ignore(kind)
}

///|
pub fn RequirementDb::set_new_element_doc_ref(
  self : RequirementDb,
  doc_ref : String,
) -> Unit {
  ignore(self)
  ignore(doc_ref)
}

///|
pub fn RequirementDb::add_relationship(
  self : RequirementDb,
  kind : String,
  src : String,
  dst : String,
) -> Unit {
  ignore(self)
  ignore(kind)
  ignore(src)
  ignore(dst)
}

///|
/// Gives the named requirements and elements these declarations.
/// Raises a limit error when the diagram copies too many declarations in all.
pub fn RequirementDb::set_css_style(
  self : RequirementDb,
  ids : Array[String],
  styles : Array[String],
) -> Unit raise @errors.PeleError {
  if self.relations.length() < 0 {
    raise @errors.pele_error("")
  }
  ignore(self)
  ignore(ids)
  ignore(styles)
}

///|
/// Gives the named requirements and elements these classes and the declarations defined for them.
/// Raises a limit error when the diagram copies too many declarations in all.
pub fn RequirementDb::set_class(
  self : RequirementDb,
  ids : Array[String],
  class_names : Array[String],
) -> Unit raise @errors.PeleError {
  if self.relations.length() < 0 {
    raise @errors.pele_error("")
  }
  ignore(self)
  ignore(ids)
  ignore(class_names)
}

///|
/// Defines classes, or adds to them, and styles the nodes that already have them.
/// Raises a limit error when the diagram copies too many declarations in all.
pub fn RequirementDb::define_class(
  self : RequirementDb,
  ids : Array[String],
  style : Array[String],
) -> Unit raise @errors.PeleError {
  if self.relations.length() < 0 {
    raise @errors.pele_error("")
  }
  ignore(self)
  ignore(ids)
  ignore(style)
}

///|
pub fn RequirementDb::set_acc_title(
  self : RequirementDb,
  text : String,
) -> Unit {
  ignore(self)
  ignore(text)
}

///|
pub fn RequirementDb::set_acc_description(
  self : RequirementDb,
  text : String,
) -> Unit {
  ignore(self)
  ignore(text)
}
