///|
/// The model an ER diagram is parsed into, as pele's ErDb.
pub struct ErDb {
  mut direction : String
  entities : Map[String, ErEntity]
  relationships : Array[ErRelationship]
  classes : Map[String, ErClassDef]
  subgraphs : Array[ErSubgraph]
  title : String?
  mut acc_title : String?
  mut acc_descr : String?
  priv subgraph_lookup : Map[String, ErSubgraph]
  priv claimed : Set[String]
}

///|
/// An empty model that runs top to bottom, with the title front matter gave.
pub fn ErDb::new(title? : String) -> ErDb {
  {
    direction: "TB",
    entities: Map([]),
    relationships: [],
    classes: Map([]),
    subgraphs: [],
    title,
    acc_title: None,
    acc_descr: None,
    subgraph_lookup: Map([]),
    claimed: Set([]),
  }
}

///|
/// The entity of that name, added if it is new; an alias is kept only if it has none yet.
pub fn ErDb::add_entity(
  self : ErDb,
  name : String,
  alias_name~ : String = "",
) -> ErEntity {
  match self.entities.get(name) {
    Some(entity) => {
      if entity.alias_name == "" && alias_name != "" {
        entity.alias_name = alias_name
      }
      entity
    }
    None => {
      let entity = {
        // Joined at its final size, because interpolating a name of hundreds of millions of
        // characters would need a doubling builder's block past what wasm allocates.
        id: ["entity-", name, "-", self.entities.length().to_string()].join(""),
        label: name,
        alias_name,
        attributes: [],
        css_classes: "default",
        css_styles: [],
      }
      self.entities.set(name, entity)
      entity
    }
  }
}

///|
/// Adds attributes to the entity, which the grammar hands over last to first.
pub fn ErDb::add_attributes(
  self : ErDb,
  name : String,
  attributes : Array[ErAttribute],
) -> Unit {
  let entity = self.add_entity(name)
  for i = attributes.length() - 1; i >= 0; i = i - 1 {
    entity.attributes.push(attributes[i])
  }
}

///|
/// Relates two names, each an entity or a subgraph that already exists.
pub fn ErDb::add_relationship(
  self : ErDb,
  entity_a : String,
  role_a : String,
  entity_b : String,
  spec : RelSpec,
) -> Unit {
  let entity_a = if self.subgraph_lookup.contains(entity_a) {
    entity_a
  } else {
    self.add_entity(entity_a).id
  }
  let entity_b = if self.subgraph_lookup.contains(entity_b) {
    entity_b
  } else {
    self.add_entity(entity_b).id
  }
  self.relationships.push({ entity_a, role_a, entity_b, rel_spec: spec, })
}

///|
/// Sets the direction the diagram runs in, as a `direction` statement outside any subgraph does.
pub fn ErDb::set_direction(self : ErDb, dir : String) -> Unit {
  self.direction = dir
}

///|
/// Gives the entities and subgraphs of those ids the styles of a `style` statement.
pub fn ErDb::add_css_styles(
  self : ErDb,
  ids : Array[String],
  styles : Array[String],
) -> Unit {
  for id in ids {
    if self.entities.get(id) is Some(entity) {
      entity.css_styles.push_iter(styles.iter())
    }
    if self.subgraph_lookup.get(id) is Some(subgraph) {
      subgraph.css_styles.push_iter(styles.iter())
    }
  }
}

///|
/// Defines classes with styles, as a `classDef` statement does.
pub fn ErDb::add_class(
  self : ErDb,
  ids : Array[String],
  styles : Array[String],
) -> Unit {
  for id in ids {
    let def = match self.classes.get(id) {
      Some(def) => def
      None => {
        let def = { id, styles: [], text_styles: [], }
        self.classes.set(id, def)
        def
      }
    }
    for style in styles {
      if style.contains("color") {
        def.text_styles.push(replace_first(style, "fill", "bgFill"))
      }
      def.styles.push(style)
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
/// Gives the entities and subgraphs of those ids the classes.
pub fn ErDb::set_class(
  self : ErDb,
  ids : Array[String],
  class_names : Array[String],
) -> Unit {
  for id in ids {
    if self.entities.get(id) is Some(entity) {
      for name in class_names {
        entity.css_classes = entity.css_classes + " " + name
      }
    }
    if self.subgraph_lookup.get(id) is Some(subgraph) {
      subgraph.classes.push_iter(class_names.iter())
    }
  }
}

///|
/// Adds a subgraph holding the names listed in it that no earlier subgraph holds, and returns its id.
pub fn ErDb::add_sub_graph(
  self : ErDb,
  id : String,
  list : Array[DocItem],
  title : String,
) -> String {
  let id = @util.trim(id)
  let seen = Set([])
  let nodes = []
  let mut dir = None
  for item in list {
    match item {
      Dir(value) => dir = Some(value)
      Name(name) => {
        let trimmed = @util.trim(name)
        if trimmed == "" || seen.contains(trimmed) {
          continue
        }
        seen.add(trimmed)
        // A name is claimed as written, while repeats are spotted trimmed, as in Mermaid.
        if !self.claimed.contains(name) {
          nodes.push(name)
        }
      }
    }
  }
  for node in nodes {
    self.claimed.add(node)
  }
  let subgraph = {
    id,
    nodes,
    title: @util.trim(title),
    classes: [],
    css_styles: [],
    dir,
  }
  self.subgraphs.push(subgraph)
  self.subgraph_lookup.set(id, subgraph)
  id
}

///|
/// Sets the accessible title, without its leading whitespace.
pub fn ErDb::set_acc_title(self : ErDb, text : String) -> Unit {
  self.acc_title = Some(@util.trim_start(text))
}

///|
/// Sets the accessible description, with the indentation of its lines removed.
pub fn ErDb::set_acc_description(self : ErDb, text : String) -> Unit {
  let out = StringBuilder()
  let mut from = 0
  let mut i = 0
  while i < text.length() {
    let c = @util.code_at(text, i)
    i += 1
    if c == '\n'.to_int() &&
      i < text.length() &&
      @util.is_space(@util.code_at(text, i)) {
      @util.write_range(out, text, from, i)
      while i < text.length() && @util.is_space(@util.code_at(text, i)) {
        i += 1
      }
      from = i
    }
  }
  @util.write_range(out, text, from, text.length())
  self.acc_descr = Some(out.to_string())
}
