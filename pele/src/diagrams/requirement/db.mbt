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
/// Applying a class copies its declarations onto each node, so a short text can ask for
/// hundreds of millions of copies. Past this many the diagram is refused.
const MAX_STYLE_COPIES : Int32 = 1_000_000

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
  // The grammar reports a body's fields before the requirement or element they belong to.
  priv mut new_id : String
  priv mut new_text : String
  priv mut new_risk : String
  priv mut new_verify_method : String
  priv mut new_element_type : String
  priv mut new_doc_ref : String
  priv mut style_copies : Int32
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
    new_id: "",
    new_text: "",
    new_risk: "",
    new_verify_method: "",
    new_element_type: "",
    new_doc_ref: "",
    style_copies: 0,
  }
}

///|
fn RequirementDb::copy(
  self : RequirementDb,
  target : Array[String],
  styles : Array[String],
) -> Unit raise @errors.PeleError {
  self.style_copies += styles.length()
  if self.style_copies > MAX_STYLE_COPIES {
    raise @errors.pele_error(
      "Requirement diagram applies too many style declarations.",
      code=Limit,
      kind="requirement",
    )
  }
  target.append(styles)
}

///|
pub fn RequirementDb::set_direction(self : RequirementDb, dir : String) -> Unit {
  self.direction = dir
}

///|
/// Adds a requirement with the fields read since the last one, unless one of that name exists.
pub fn RequirementDb::add_requirement(
  self : RequirementDb,
  name : String,
  kind : String,
) -> Unit {
  if !self.requirements.contains(name) {
    self.requirements.set(name, {
      name,
      kind,
      requirement_id: self.new_id,
      text: self.new_text,
      risk: self.new_risk,
      verify_method: self.new_verify_method,
      css_styles: [],
      classes: ["default"],
    })
  }
  self.new_id = ""
  self.new_text = ""
  self.new_risk = ""
  self.new_verify_method = ""
}

///|
pub fn RequirementDb::set_new_req_id(self : RequirementDb, id : String) -> Unit {
  self.new_id = id
}

///|
pub fn RequirementDb::set_new_req_text(
  self : RequirementDb,
  text : String,
) -> Unit {
  self.new_text = text
}

///|
pub fn RequirementDb::set_new_req_risk(
  self : RequirementDb,
  risk : String,
) -> Unit {
  self.new_risk = risk
}

///|
pub fn RequirementDb::set_new_req_verify_method(
  self : RequirementDb,
  verify_method : String,
) -> Unit {
  self.new_verify_method = verify_method
}

///|
/// Adds an element with the fields read since the last one, unless one of that name exists.
pub fn RequirementDb::add_element(self : RequirementDb, name : String) -> Unit {
  if !self.elements.contains(name) {
    self.elements.set(name, {
      name,
      kind: self.new_element_type,
      doc_ref: self.new_doc_ref,
      css_styles: [],
      classes: ["default"],
    })
  }
  self.new_element_type = ""
  self.new_doc_ref = ""
}

///|
pub fn RequirementDb::set_new_element_type(
  self : RequirementDb,
  kind : String,
) -> Unit {
  self.new_element_type = kind
}

///|
pub fn RequirementDb::set_new_element_doc_ref(
  self : RequirementDb,
  doc_ref : String,
) -> Unit {
  self.new_doc_ref = doc_ref
}

///|
pub fn RequirementDb::add_relationship(
  self : RequirementDb,
  kind : String,
  src : String,
  dst : String,
) -> Unit {
  self.relations.push({ kind, src, dst, })
}

///|
/// The declarations and classes of the requirement of this name, or else of the element.
fn RequirementDb::node(
  self : RequirementDb,
  id : String,
) -> (Array[String], Array[String])? {
  match self.requirements.get(id) {
    Some(requirement) => Some((requirement.css_styles, requirement.classes))
    None =>
      match self.elements.get(id) {
        Some(element) => Some((element.css_styles, element.classes))
        None => None
      }
  }
}

///|
fn split_commas(text : String) -> Array[String] {
  let parts = []
  let mut from = 0
  while true {
    let at = @util.index_of(text, ",", from~)
    if at == -1 {
      parts.push(@util.slice(text, from))
      break
    }
    parts.push(@util.slice(text, from, end=at))
    from = at + 1
  }
  parts
}

///|
/// Gives the named requirements and elements these declarations.
/// Raises a limit error when the diagram copies too many declarations in all.
pub fn RequirementDb::set_css_style(
  self : RequirementDb,
  ids : Array[String],
  styles : Array[String],
) -> Unit raise @errors.PeleError {
  for id in ids {
    // Mermaid stops at the first unknown id, leaving the rest of the list unstyled.
    guard self.node(id) is Some((css_styles, _)) else { return }
    for style in styles {
      self.copy(css_styles, split_commas(style))
    }
  }
}

///|
/// Gives the named requirements and elements these classes and the declarations defined for them.
/// Raises a limit error when the diagram copies too many declarations in all.
pub fn RequirementDb::set_class(
  self : RequirementDb,
  ids : Array[String],
  class_names : Array[String],
) -> Unit raise @errors.PeleError {
  for id in ids {
    guard self.node(id) is Some((css_styles, classes)) else { continue }
    for name in class_names {
      classes.push(name)
      if self.classes.get(name) is Some(defined) {
        self.copy(css_styles, defined.styles)
      }
    }
  }
}

///|
/// Defines classes, or adds to them, and styles the nodes that already have them.
/// Raises a limit error when the diagram copies too many declarations in all.
pub fn RequirementDb::define_class(
  self : RequirementDb,
  ids : Array[String],
  style : Array[String],
) -> Unit raise @errors.PeleError {
  for id in ids {
    let style_class = match self.classes.get(id) {
      Some(style_class) => style_class
      None => {
        let style_class = { id, styles: [], text_styles: [], }
        self.classes.set(id, style_class)
        style_class
      }
    }
    for s in style {
      if s.contains("color") {
        style_class.text_styles.push(replace_first(s, "fill", "bgFill"))
      }
      style_class.styles.push(s)
    }
    let split = []
    for s in style {
      split.append(split_commas(s))
    }
    for _, requirement in self.requirements {
      if requirement.classes.contains(id) {
        self.copy(requirement.css_styles, split)
      }
    }
    for _, element in self.elements {
      if element.classes.contains(id) {
        self.copy(element.css_styles, split)
      }
    }
  }
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
pub fn RequirementDb::set_acc_title(
  self : RequirementDb,
  text : String,
) -> Unit {
  self.acc_title = Some(@util.trim_start(text))
}

///|
/// Does what `text.replace(/\n\s+/g, '\n')` does.
fn join_indented_lines(text : String) -> String {
  let out = StringBuilder()
  let mut i = 0
  let mut last = 0
  while i < text.length() {
    if @util.code_at(text, i) != '\n'.to_int() {
      i += 1
      continue
    }
    let start = i
    i += 1
    while @util.is_space(@util.code_at(text, i)) {
      i += 1
    }
    if i > start + 1 {
      @util.write_range(out, text, last, start + 1)
      last = i
    }
  }
  @util.write_range(out, text, last, text.length())
  out.to_string()
}

///|
pub fn RequirementDb::set_acc_description(
  self : RequirementDb,
  text : String,
) -> Unit {
  self.acc_descr = Some(join_indented_lines(text))
}
