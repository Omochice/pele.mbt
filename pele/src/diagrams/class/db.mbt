///|
/// Mermaid looks up ids that start with a digit under this prefix, so they never match a class.
const DOM_ID_PREFIX : String = "classId-"

///|
/// Mermaid's relation type of a lollipop end.
const LOLLIPOP : Int32 = 4

///|
/// The model of a class diagram, built up statement by statement as Mermaid's ClassDB is.
pub struct ClassDb {
  mut direction : String
  classes : Map[String, ClassNode]
  relations : Array[ClassRelation]
  notes : Map[String, ClassNote]
  namespaces : Map[String, NamespaceNode]
  interfaces : Array[ClassInterface]
  style_classes : Map[String, StyleClass]
  title : String?
  mut acc_title : String?
  mut acc_descr : String?
  priv namespace_stack : Array[String]
  /// The classes that carry each css class, keyed by class name in the order they were tagged.
  priv with_css_class : Map[String, Map[String, ClassNode]]
}

///|
/// An empty model that runs top to bottom, with the title front matter gave.
pub fn ClassDb::new(title? : String) -> ClassDb {
  {
    direction: "TB",
    classes: Map([]),
    relations: [],
    notes: Map([]),
    namespaces: Map([]),
    interfaces: [],
    style_classes: Map([]),
    title,
    acc_title: None,
    acc_descr: None,
    namespace_stack: [],
    with_css_class: Map([]),
  }
}

///|
/// The parts of `text` between the occurrences of `sep`, as `split` gives them.
fn split_on(text : String, sep : Int32) -> Array[String] {
  let out = []
  let mut from = 0
  for i in 0..<text.length() {
    if text.unsafe_get(i).to_int() == sep {
      out.push(@util.slice(text, from, end=i))
      from = i + 1
    }
  }
  out.push(@util.slice(text, from))
  out
}

///|
/// A name split into the class name and the generic type between its first two tildes.
fn split_name(id : String) -> (String, String) {
  let at = @util.index_of(id, "~")
  if at <= 0 {
    return (id, "")
  }
  let end = @util.index_of(id, "~", from=at + 1)
  (
    @util.slice(id, 0, end=at),
    @util.slice(id, at + 1, end=if end == -1 { id.length() } else { end }),
  )
}

///|
fn class_name_of(id : String) -> String {
  split_name(id).0
}

///|
fn lookup_id(id : String) -> String {
  class_name_of(
    if @util.is_digit(@util.code_at(id, 0)) {
      DOM_ID_PREFIX + id
    } else {
      id
    },
  )
}

///|
/// Adds the class a name with an optional generic type names, if it is new.
pub fn ClassDb::add_class(self : ClassDb, id : String) -> Unit {
  let (class_name, generic_type) = split_name(id)
  if self.classes.contains(class_name) {
    return
  }
  let node = {
    id: class_name,
    generic_type,
    label: class_name,
    css_classes: "default",
    methods: [],
    members: [],
    annotations: [],
    styles: [],
    parent: None,
    link: None,
    link_target: None,
    have_callback: false,
    tooltip: None,
  }
  self.classes.set(class_name, node)
  self.tag(node, "default")
}

///|
fn ClassDb::tag(self : ClassDb, node : ClassNode, css_class : String) -> Unit {
  match self.with_css_class.get(css_class) {
    Some(tagged) => if !tagged.contains(node.id) { tagged.set(node.id, node) }
    None => self.with_css_class.set(css_class, Map([(node.id, node)]))
  }
}

///|
/// Returns the class for a name that may carry a generic type, creating it if needed.
/// Mermaid throws a TypeError where this creates, as for an annotation on a class not yet declared.
fn ClassDb::ensure(self : ClassDb, id : String) -> ClassNode {
  self.add_class(id)
  self.classes.get(class_name_of(id)).unwrap()
}

///|
/// Sets the label a class is shown with, adding the class if it is new.
pub fn ClassDb::set_class_label(
  self : ClassDb,
  id : String,
  label : String,
) -> Unit {
  self.ensure(id).label = label
}

///|
/// Adds a relation, with an interface in place of a lone lollipop end.
pub fn ClassDb::add_relation(self : ClassDb, relation : ClassRelation) -> Unit {
  let { type1, type2, .. } = relation.relation
  if type1 == Some(LOLLIPOP) && type2 is None {
    self.add_class(relation.id2)
    relation.id1 = self.add_interface(relation.id1, relation.id2)
  } else if type2 == Some(LOLLIPOP) && type1 is None {
    self.add_class(relation.id1)
    relation.id2 = self.add_interface(relation.id2, relation.id1)
  } else {
    self.add_class(relation.id1)
    self.add_class(relation.id2)
  }
  relation.id1 = class_name_of(relation.id1)
  relation.id2 = class_name_of(relation.id2)
  relation.relation_title1 = @util.trim(relation.relation_title1)
  relation.relation_title2 = @util.trim(relation.relation_title2)
  self.relations.push(relation)
}

///|
fn ClassDb::add_interface(
  self : ClassDb,
  label : String,
  class_id : String,
) -> String {
  let id = "interface\{self.interfaces.length()}"
  self.interfaces.push({ id, label, class_id, })
  id
}

///|
/// Adds an annotation to a class, adding the class if it is new.
pub fn ClassDb::add_annotation(
  self : ClassDb,
  class_name : String,
  annotation : String,
) -> Unit {
  self.ensure(class_name).annotations.push(annotation)
}

///|
/// Adds a member to a class: an annotation in `<<` and `>>`, a method, or an attribute.
pub fn ClassDb::add_member(
  self : ClassDb,
  class_name : String,
  text : String,
) -> Unit {
  let node = self.ensure(class_name)
  let trimmed = @util.trim(text)
  if trimmed.has_prefix("<<") && trimmed.has_suffix(">>") {
    node.annotations.push(@util.slice(trimmed, 2, end=trimmed.length() - 2))
  } else if @util.index_of(trimmed, ")") > 0 {
    let parsed = ClassMember::new(trimmed, Method)
    match parsed.member_type {
      Method => node.methods.push(parsed)
      Attribute => node.members.push(parsed)
    }
  } else if trimmed != "" {
    node.members.push(ClassMember::new(trimmed, Attribute))
  }
}

///|
/// Adds the members of a class body, which the grammar collects last to first.
/// The list is turned around in place, as Mermaid's `addMembers` does.
pub fn ClassDb::add_members(
  self : ClassDb,
  class_name : String,
  list : Array[String],
) -> Unit {
  list.rev_in_place()
  for text in list {
    self.add_member(class_name, text)
  }
}

///|
/// Adds a note and returns its id.
pub fn ClassDb::add_note(
  self : ClassDb,
  text : String,
  class_id? : String,
) -> String {
  let index = self.notes.length()
  let id = "note\{index}"
  self.notes.set(id, { id, class_id, text, index, parent: None, })
  id
}

///|
/// The text of a `:` label, without the colon.
pub fn ClassDb::cleanup_label(self : ClassDb, label : String) -> String {
  ignore(self)
  @util.trim(if label.has_prefix(":") { @util.slice(label, 1) } else { label })
}

///|
/// Adds a css class to each class of a comma-separated list.
pub fn ClassDb::set_css_class(
  self : ClassDb,
  ids : String,
  class_name : String,
) -> Unit {
  for id in split_on(ids, ',') {
    guard self.classes.get(lookup_id(id)) is Some(node) else { continue }
    node.css_classes = node.css_classes + " " + class_name
    for word in split_on(class_name, ' ') {
      self.tag(node, word)
    }
  }
}

///|
/// Defines a classDef and styles the classes that already carry it.
/// Mermaid tests `cssClasses.includes(id)`, which also matches part of a longer name (a classDef named `def` styles every class, through `default`).
/// Whole names are compared here.
pub fn ClassDb::define_class(
  self : ClassDb,
  ids : Array[String],
  style : Array[String],
) -> Unit {
  for id in ids {
    let style_class = match self.style_classes.get(id) {
      Some(found) => found
      None => {
        let made = { id, styles: [], text_styles: [], }
        self.style_classes.set(id, made)
        made
      }
    }
    for s in style {
      if s.contains("color") {
        style_class.text_styles.push(replace_first(s, "fill", "bgFill"))
      }
      style_class.styles.push(s)
    }
    guard self.with_css_class.get(id) is Some(tagged) else { continue }
    let parts = []
    for s in style {
      parts.append(split_on(s, ','))
    }
    for _, node in tagged {
      for part in parts {
        node.styles.push(part)
      }
    }
  }
}

///|
/// `text.replace(old, new)` with a string pattern: only the first occurrence.
fn replace_first(text : String, old : String, new : String) -> String {
  let at = @util.index_of(text, old)
  if at == -1 {
    return text
  }
  @util.slice(text, 0, end=at) + new + @util.slice(text, at + old.length())
}

///|
/// Sets the tooltip of each class of a comma-separated list.
pub fn ClassDb::set_tooltip(
  self : ClassDb,
  ids : String,
  tooltip : String?,
) -> Unit {
  guard tooltip is Some(_) else { return }
  for id in split_on(ids, ',') {
    if self.classes.get(class_name_of(id)) is Some(node) {
      node.tooltip = tooltip
    }
  }
}

///|
/// Links each class of a comma-separated list, through a sanitized URL.
pub fn ClassDb::set_link(
  self : ClassDb,
  ids : String,
  link : String,
  target? : String,
) -> Unit {
  // Entity codes are resolved first, so that what is checked is what a browser would follow.
  let url = @util.trim(@text.decode_entities(link))
  for id in split_on(ids, ',') {
    if self.classes.get(lookup_id(id)) is Some(node) {
      node.link = if url != "" { Some(@url.sanitize_url(url)) } else { None }
      node.link_target = Some(target.unwrap_or("_blank"))
    }
  }
  self.set_css_class(ids, "clickable")
}

///|
/// Marks each class of a comma-separated list as having a callback.
/// Callbacks are never executed; the class is only marked clickable, as in Mermaid's strict mode.
pub fn ClassDb::set_click_event(self : ClassDb, ids : String) -> Unit {
  for id in split_on(ids, ',') {
    if self.classes.get(class_name_of(id)) is Some(node) {
      node.have_callback = true
    }
  }
  self.set_css_class(ids, "clickable")
}

///|
/// Sets the direction the diagram runs in.
pub fn ClassDb::set_direction(self : ClassDb, dir : String) -> Unit {
  self.direction = dir
}

///|
/// Sets the accessible title, without its leading whitespace.
pub fn ClassDb::set_acc_title(self : ClassDb, text : String) -> Unit {
  self.acc_title = Some(@util.trim_start(text))
}

///|
/// Sets the accessible description, with the indentation of its lines removed.
pub fn ClassDb::set_acc_description(self : ClassDb, text : String) -> Unit {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    let c = @util.code_at(text, i)
    if c == '\n' && @util.is_space(@util.code_at(text, i + 1)) {
      out.write_char('\n')
      i += 1
      while @util.is_space(@util.code_at(text, i)) {
        i += 1
      }
      continue
    }
    @util.write_range(out, text, i, i + 1)
    i += 1
  }
  self.acc_descr = Some(out.to_string())
}

///|
/// Opens a namespace inside the one open, with its ancestors, and returns its full name.
pub fn ClassDb::add_namespace(
  self : ClassDb,
  id : String,
  label? : String,
) -> String {
  let prefix = match self.namespace_stack.last() {
    Some(open) if open != "" => Some(open)
    _ => None
  }
  let qualified = match prefix {
    Some(open) => open + "." + id
    None => id
  }
  self.namespace_stack.push(qualified)
  let label = match label {
    Some(text) if text != "" => Some(text)
    _ => None
  }
  if self.namespaces.get(qualified) is Some(existing) {
    existing.explicit = true
    if label is Some(text) {
      existing.label = text
    }
    return qualified
  }

  // The enclosing namespace and its ancestors exist already, so only the parts of `id` are walked.
  let mut parent_id = prefix
  let mut from = match prefix {
    Some(open) => open.length() + 1
    None => 0
  }
  while true {
    let dot = @util.index_of(qualified, ".", from~)
    let leaf = dot == -1
    let current = if leaf {
      qualified
    } else {
      @util.slice(qualified, 0, end=dot)
    }
    let node = match self.namespaces.get(current) {
      Some(found) => {
        if leaf {
          found.explicit = true
        }
        found
      }
      None => {
        let part = @util.slice(
          qualified,
          from,
          end=if leaf { qualified.length() } else { dot },
        )
        let made = {
          id: current,
          label: if leaf {
            label.unwrap_or(part)
          } else {
            part
          },
          classes: Map([]),
          notes: Map([]),
          children: Map([]),
          parent: parent_id,
          explicit: leaf,
        }
        self.namespaces.set(current, made)
        made
      }
    }
    if parent_id is Some(up) && self.namespaces.get(up) is Some(parent) {
      if !parent.children.contains(current) {
        parent.children.set(current, node)
      }
      if node.parent is None {
        node.parent = parent_id
      }
    }
    if leaf {
      break
    }
    parent_id = Some(current)
    from = dot + 1
  }
  qualified
}

///|
/// Closes the namespace opened last.
pub fn ClassDb::pop_namespace(self : ClassDb) -> Unit {
  ignore(self.namespace_stack.pop())
}

///|
/// Puts classes and notes into a namespace.
pub fn ClassDb::add_classes_to_namespace(
  self : ClassDb,
  id : String,
  class_names : Array[String],
  note_names : Array[String],
) -> Unit {
  guard self.namespaces.get(id) is Some(group) else { return }
  for name in class_names {
    let class_name = class_name_of(name)
    guard self.classes.get(class_name) is Some(node) else { continue }
    node.parent = Some(id)
    group.classes.set(class_name, node)
  }
  for name in note_names {
    guard self.notes.get(name) is Some(note) else { continue }
    note.parent = Some(id)
    group.notes.set(name, note)
  }
}

///|
/// Adds the declarations of a `style` statement to a class.
pub fn ClassDb::set_css_style(
  self : ClassDb,
  id : String,
  styles : Array[String],
) -> Unit {
  guard self.classes.get(id) is Some(node) else { return }
  for s in styles {
    for part in split_on(s, ',') {
      node.styles.push(part)
    }
  }
}
