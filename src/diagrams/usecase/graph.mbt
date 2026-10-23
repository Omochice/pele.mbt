///|
/// One leaf of a JSON node: `key` is blank on the second and later values of an array, and
/// `accessible_key` is the key again for every row.
pub(all) struct JsonRow {
  key : String
  accessible_key : String
  value : String
}

///|
/// What is drawn for an actor, use case, note, JSON table or boundary; `shape` is Mermaid's shape name.
pub(all) struct UsecaseGraphNode {
  id : String
  label : String
  label_type : String
  shape : String
  is_group : Bool
  padding : Double
  css_classes : String
  css_styles : Array[String]
  css_compiled_styles : Array[String]
  actor_type : String?
  business : Bool?
  icon : String?
  stereotype : String?
  parent_id : String?
  note_target : String?
  json_rows : Array[JsonRow]?
  boundary_type : String?
}

///|
/// What is drawn for a relationship or the dotted line from a note to what it is about (`internal`).
pub(all) struct UsecaseGraphEdge {
  id : String
  start : String
  end : String
  relationship_type : String
  pattern : String
  arrow_type_start : String
  arrow_type_end : String
  label : String?
  label_type : String?
  classes : String
  style : Array[String]
  css_compiled_styles : Array[String]
  animate : Bool
  animation : String?
  minlen : Int32
  explicit_id : Bool
  internal : Bool
}

///|
/// The nodes and edges of a use case diagram.
pub(all) struct UsecaseGraph {
  nodes : Array[UsecaseGraphNode]
  edges : Array[UsecaseGraphEdge]
}

///|
/// The start and end markers of each arrow type, in the order of the arrow type constants.
let association_markers : Array[(String, String)] = [
  ("none", "arrow_point"),
  ("arrow_point", "none"),
  ("none", "none"),
  ("none", "arrow_circle"),
  ("none", "arrow_cross"),
  ("arrow_circle", "none"),
  ("arrow_cross", "none"),
]

///|
fn markers(relationship : Relationship) -> (String, String) {
  if relationship.rel_type == "generalization" {
    return ("none", "extension")
  }
  if relationship.rel_type != "association" {
    return association_markers[SOLID_ARROW]
  }
  let arrow = relationship.arrow_type
  if arrow >= 0 && arrow < association_markers.length() {
    association_markers[arrow]
  } else {
    association_markers[LINE_SOLID]
  }
}

///|
/// A JSON leaf as `String(value)` writes it.
fn scalar(value : JsonValue) -> String {
  match value {
    JsonString(text) => text
    JsonNull => "null"
    JsonBool(flag) => flag.to_string()
    // `String(-0)` is "0".
    JsonNumber(number) => if number == 0 { "0" } else { number.to_string() }
    JsonArray(_) | JsonObject(_) => ""
  }
}

///|
fn is_scalar(value : JsonValue) -> Bool {
  !(value is JsonArray(_) || value is JsonObject(_))
}

///|
/// One row for each leaf of a JSON object, depth first in the order the keys were written.
/// Nesting is kept on a stack of its own, so depth is limited by memory and not by the call stack.
pub fn flatten_json_rows(value : Array[(String, JsonValue)]) -> Array[JsonRow] {
  let rows = []
  let row = (key : String, path : String, value : String) => {
    rows.push({ key, accessible_key: path, value, })
  }
  let stack : Array[(JsonValue, String)] = [(JsonObject(value), "")]
  let children : Array[(JsonValue, String)] = []
  while stack.pop() is Some((current, path)) {
    children.clear()
    match current {
      JsonArray(items) =>
        if items.length() == 0 {
          row(path, path, "[]")
        } else if items.iter().all(is_scalar) {
          for i, item in items {
            row(if i == 0 { path } else { "" }, path, scalar(item))
          }
        } else {
          for i, item in items {
            children.push((item, "\{path}[\{i}]"))
          }
        }
      JsonObject(entries) => {
        if entries.length() == 0 {
          row(path, path, "{}")
        }
        for entry in entries {
          let (key, child) = entry
          children.push(
            (child, if path == "" { key } else { "\{path}.\{key}" }),
          )
        }
      }
      _ => row(path, path, scalar(current))
    }
    for i = children.length() - 1; i >= 0; i = i - 1 {
      stack.push(children[i])
    }
  }
  rows
}

///|
fn class_list(names : Array[String]) -> String {
  names.filter(name => name != "").join(" ")
}

///|
/// Resolves a parsed use case diagram into what is drawn: every actor, use case, note, JSON table
/// and boundary as a node with its class styles, and every relationship and note connector as an
/// edge with its markers. Ports getData from Mermaid's use case DB.
pub fn build_usecase_graph(model : UsecaseModel) -> UsecaseGraph {
  let nodes = []
  let edges = []
  // A later class wins a property but keeps the place the property first took.
  let compiled = (class_names : Array[String]) => {
    let out : Map[String, String] = Map([])
    for name in ["default"] + class_names {
      guard model.class_defs.get(name) is Some(definition) else { continue }
      for raw in definition.styles {
        let style = @util.trim(raw)
        let colon = @util.index_of(style, ":")
        let property = @util.trim(
          if colon == -1 {
            style
          } else {
            @util.slice(style, 0, end=colon)
          },
        )
        if property != "" {
          out.set(property, style)
        }
      }
    }
    out.values().collect()
  }
  let business_class = (business : Bool) => {
    if business {
      "usecase-business"
    } else {
      ""
    }
  }
  for _, actor in model.actors {
    nodes.push({
      id: actor.id,
      label: actor.label,
      label_type: actor.label_type,
      shape: match actor.actor_type {
        "hollow" => "usecaseActorHollow"
        "awesome" => "usecaseActorAwesome"
        "icon" => "usecaseActorIcon"
        _ => "usecaseActor"
      },
      is_group: false,
      padding: 10,
      css_classes: class_list(
        [
          "default",
          "usecase-actor",
          "usecase-actor-\{actor.actor_type}",
          business_class(actor.business),
        ] +
        actor.classes,
      ),
      css_styles: actor.styles.copy(),
      css_compiled_styles: compiled(actor.classes),
      actor_type: Some(actor.actor_type),
      business: Some(actor.business),
      icon: non_empty(actor.icon),
      stereotype: non_empty(actor.stereotype),
      parent_id: non_empty(actor.parent_id),
      note_target: None,
      json_rows: None,
      boundary_type: None,
    })
  }
  for _, use_case in model.use_cases {
    let ellipse = use_case.shape == "ellipse"
    nodes.push({
      id: use_case.id,
      label: use_case.label,
      label_type: use_case.label_type,
      shape: if !ellipse {
        "rect"
      } else if use_case.business {
        "usecaseBusiness"
      } else {
        "usecaseEllipse"
      },
      is_group: false,
      padding: if ellipse {
        20
      } else {
        10
      },
      css_classes: class_list(
        [
          "default",
          "usecase-element",
          "usecase-\{use_case.shape}",
          business_class(use_case.business),
        ] +
        use_case.classes,
      ),
      css_styles: use_case.styles.copy(),
      css_compiled_styles: compiled(use_case.classes),
      actor_type: None,
      business: Some(use_case.business),
      icon: None,
      stereotype: non_empty(use_case.stereotype),
      parent_id: non_empty(use_case.parent_id),
      note_target: None,
      json_rows: None,
      boundary_type: None,
    })
  }
  for _, note in model.notes {
    nodes.push({
      id: note.id,
      label: note.label,
      label_type: note.label_type,
      shape: "note",
      is_group: false,
      padding: 10,
      css_classes: "default usecase-note",
      css_styles: [],
      css_compiled_styles: compiled([]),
      actor_type: None,
      business: None,
      icon: None,
      stereotype: None,
      parent_id: None,
      note_target: Some(note.target),
      json_rows: None,
      boundary_type: None,
    })
  }
  for _, json in model.json_nodes {
    nodes.push({
      id: json.id,
      label: json.id,
      label_type: "text",
      shape: "usecaseJsonTable",
      is_group: false,
      padding: 10,
      css_classes: class_list(["default", "usecase-json-table"] + json.classes),
      css_styles: json.styles.copy(),
      css_compiled_styles: compiled(json.classes),
      actor_type: None,
      business: None,
      icon: None,
      stereotype: None,
      parent_id: None,
      note_target: None,
      json_rows: Some(flatten_json_rows(json.value)),
      boundary_type: None,
    })
  }
  for _, boundary in model.system_boundaries {
    nodes.push({
      id: boundary.id,
      label: boundary.label,
      label_type: boundary.label_type,
      shape: "usecaseSystemBoundary",
      is_group: true,
      padding: 20,
      css_classes: class_list(
        [
          "default",
          "system-boundary",
          "system-boundary-\{boundary.boundary_type}",
        ] +
        boundary.classes,
      ),
      css_styles: boundary.styles.copy(),
      css_compiled_styles: compiled(boundary.classes),
      actor_type: None,
      business: None,
      icon: None,
      stereotype: None,
      parent_id: None,
      note_target: None,
      json_rows: None,
      boundary_type: Some(boundary.boundary_type),
    })
  }
  for relationship in model.relationships {
    let rel_type = relationship.rel_type
    let semantic = rel_type == "include" || rel_type == "extend"
    let (arrow_type_start, arrow_type_end) = markers(relationship)
    let animated = relationship.animate || relationship.animation is Some(_)
    // Include and extend are labelled with their kind, whatever label the relationship carries.
    let (label, label_type) = if semantic {
      (Some(rel_type), Some("text"))
    } else if rel_type == "association" {
      (non_empty(relationship.label), relationship.label_type)
    } else {
      (None, None)
    }
    edges.push({
      id: relationship.id,
      start: relationship.source,
      end: relationship.target,
      relationship_type: rel_type,
      pattern: if semantic {
        "dotted"
      } else {
        "solid"
      },
      arrow_type_start,
      arrow_type_end,
      label,
      label_type,
      classes: class_list(
        ["default", "relationship", "relationship-\{rel_type}"] +
        relationship.classes +
        [
          if animated {
            "edge-animation-\{relationship.animation.unwrap_or("fast")}"
          } else {
            ""
          },
        ],
      ),
      style: relationship.styles.copy(),
      css_compiled_styles: compiled(relationship.classes),
      animate: relationship.animate,
      animation: relationship.animation,
      minlen: relationship.minlen,
      explicit_id: relationship.explicit_id,
      internal: false,
    })
  }
  for _, note in model.notes {
    edges.push({
      id: "\{note.id}-edge",
      start: note.id,
      end: note.target,
      relationship_type: "note",
      pattern: "dotted",
      arrow_type_start: "none",
      arrow_type_end: "none",
      label: None,
      label_type: None,
      classes: "default relationship relationship-note",
      style: [],
      css_compiled_styles: compiled([]),
      animate: false,
      animation: None,
      minlen: 1,
      explicit_id: false,
      internal: true,
    })
  }
  { nodes, edges, }
}
