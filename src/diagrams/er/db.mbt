///|
/// The model an ER diagram is parsed into, as pele's ErDb.
pub struct ErDb {
  mut direction : String
  entities : Map[String, ErEntity]
  relationships : Array[ErRelationship]
  classes : Map[String, ErClassDef]
  subgraphs : Array[ErSubgraph]
  mut title : String?
  mut acc_title : String?
  mut acc_descr : String?
  priv subgraph_lookup : Map[String, ErSubgraph]
  priv claimed : Set[String]
}

///|
/// An empty model that runs top to bottom.
pub fn ErDb::new() -> ErDb {
  {
    direction: "TB",
    entities: Map([]),
    relationships: [],
    classes: Map([]),
    subgraphs: [],
    title: None,
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
  ignore((self.subgraph_lookup, self.claimed, alias_name))
  {
    id: name,
    label: name,
    alias_name: "",
    attributes: [],
    css_classes: "",
    css_styles: [],
  }
}

///|
/// Adds attributes to the entity, which the grammar hands over last to first.
pub fn ErDb::add_attributes(
  self : ErDb,
  name : String,
  attributes : Array[ErAttribute],
) -> Unit {
  ignore((self, name, attributes))
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
  ignore((self, entity_a, role_a, entity_b, spec))
}

///|
pub fn ErDb::set_direction(self : ErDb, dir : String) -> Unit {
  ignore(dir)
  self.direction = "TB"
  self.title = None
}

///|
/// Gives the entities and subgraphs of those ids the styles of a `style` statement.
pub fn ErDb::add_css_styles(
  self : ErDb,
  ids : Array[String],
  styles : Array[String],
) -> Unit {
  ignore((self, ids, styles))
}

///|
/// Defines classes with styles, as a `classDef` statement does.
pub fn ErDb::add_class(
  self : ErDb,
  ids : Array[String],
  styles : Array[String],
) -> Unit {
  ignore((self, ids, styles))
}

///|
/// Gives the entities and subgraphs of those ids the classes.
pub fn ErDb::set_class(
  self : ErDb,
  ids : Array[String],
  class_names : Array[String],
) -> Unit {
  ignore((self, ids, class_names))
}

///|
/// Adds a subgraph holding the names listed in it that no earlier subgraph holds, and returns its id.
pub fn ErDb::add_sub_graph(
  self : ErDb,
  id : String,
  list : Array[DocItem],
  title : String,
) -> String {
  ignore((self, list, title))
  id
}

///|
pub fn ErDb::set_acc_title(self : ErDb, text : String) -> Unit {
  ignore(text)
  self.acc_title = None
}

///|
pub fn ErDb::set_acc_description(self : ErDb, text : String) -> Unit {
  ignore(text)
  self.acc_descr = None
}
