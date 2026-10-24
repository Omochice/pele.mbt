///|
/// What a node is drawn as.
pub(all) enum NodeShape {
  Rect
  ClassBox
  NoteBox
  InterfaceRing
}

///|
/// The name pele gives the shape.
pub fn NodeShape::name(self : NodeShape) -> String {
  match self {
    Rect => "rect"
    ClassBox => "classBox"
    NoteBox => "note"
    InterfaceRing => "interface"
  }
}

///|
/// A namespace, class, note or interface as it is drawn.
pub(all) struct GraphNode {
  id : String
  label : String
  is_group : Bool
  shape : NodeShape
  parent_id : String?
  /// Index of the namespace node this one is drawn in, or -1.
  mut parent : Int32
  class_node : ClassNode?
  /// Position among the classes, in declaration order.
  /// Namespaces and notes have none.
  color_index : Int32?
}

///|
/// A relation, or the line from a note to its class, as it is drawn.
pub(all) struct GraphEdge {
  id : String
  start : String
  end : String
  /// Indexes into the node list.
  /// Ids alone are ambiguous: a class may be named `note0` or `interface0`.
  source : Int32
  target : Int32
  label : String?
  arrow_type_start : String
  arrow_type_end : String
  start_label_right : String
  end_label_left : String
  pattern : String
  classes : String
}

///|
/// The nodes and edges of a class diagram.
pub(all) struct ClassGraph {
  nodes : Array[GraphNode]
  edges : Array[GraphEdge]
}

///|
/// Resolves a parsed class diagram into the nodes and edges that are drawn.
/// With `hierarchical` off, only namespaces the source declares are kept and each is labeled with its full name.
pub fn build_class_graph(
  model : ClassDb,
  hierarchical~ : Bool = true,
) -> ClassGraph {
  let nodes : Array[GraphNode] = []
  let edges : Array[GraphEdge] = []
  let namespace_at : Map[String, Int32] = Map([])
  let class_at : Map[String, Int32] = Map([])
  let interface_at : Map[String, Int32] = Map([])
  let declared : Map[String, String?] = Map([])
  let declared_ancestor = (id : String?) => {
    if hierarchical {
      return id
    }
    guard id is Some(start) else { return None }
    let chain = []
    let mut current = Some(start)
    let mut found = None
    while current is Some(at) && at != "" {
      if declared.get(at) is Some(known) {
        found = known
        break
      }
      guard model.namespaces.get(at) is Some(ns) else { break }
      if ns.explicit {
        found = Some(at)
        break
      }
      chain.push(at)
      current = ns.parent
    }
    for visited in chain {
      declared.set(visited, found)
    }
    found
  }
  let group = (id : String?) => {
    match id {
      Some(at) => namespace_at.get(at).unwrap_or(-1)
      None => -1
    }
  }
  for _, ns in model.namespaces {
    if !hierarchical && !ns.explicit {
      continue
    }
    namespace_at.set(ns.id, nodes.length())
    nodes.push({
      id: ns.id,
      label: if hierarchical {
        ns.label
      } else {
        ns.id
      },
      is_group: true,
      shape: Rect,
      parent_id: if hierarchical {
        ns.parent
      } else {
        None
      },
      parent: -1,
      class_node: None,
      color_index: None,
    })
  }
  for node in nodes {
    node.parent = group(node.parent_id)
  }
  let mut color_index = 0
  for _, class_node in model.classes {
    let parent_id = declared_ancestor(class_node.parent)
    class_at.set(class_node.id, nodes.length())
    nodes.push({
      id: class_node.id,
      label: class_node.label,
      is_group: false,
      shape: ClassBox,
      parent_id,
      parent: group(parent_id),
      class_node: Some(class_node),
      color_index: Some(color_index),
    })
    color_index += 1
  }
  for _, note in model.notes {
    let parent_id = declared_ancestor(note.parent)
    let target = match note.class_id {
      Some(id) => class_at.get(id)
      None => None
    }
    if target is Some(at) {
      edges.push({
        id: "edgeNote\{note.index}",
        start: note.id,
        end: nodes[at].id,
        source: nodes.length(),
        target: at,
        label: None,
        arrow_type_start: "none",
        arrow_type_end: "none",
        start_label_right: "",
        end_label_left: "",
        pattern: "dotted",
        classes: "relation",
      })
    }
    nodes.push({
      id: note.id,
      label: note.text,
      is_group: false,
      shape: NoteBox,
      parent_id,
      parent: group(parent_id),
      class_node: None,
      color_index: None,
    })
  }

  // Mermaid leaves every lollipop interface outside the namespaces.
  // Here it stays beside its class.
  for item in model.interfaces {
    interface_at.set(item.id, nodes.length())
    nodes.push({
      id: item.id,
      label: item.label,
      is_group: false,
      shape: InterfaceRing,
      parent_id: None,
      parent: match class_at.get(item.class_id) {
        Some(owner) => nodes[owner].parent
        None => -1
      },
      class_node: None,
      color_index: None,
    })
  }
  let mut count = 0
  for relation in model.relations {
    count += 1
    let { type1, type2, line_type, } = relation.relation
    // add_relation swaps in an interface for the lollipop end of a relation with no other marker.
    let start_is_interface = type1 == Some(LOLLIPOP) && type2 is None
    let end_is_interface = !start_is_interface &&
      type2 == Some(LOLLIPOP) &&
      type1 is None
    edges.push({
      id: "id_\{relation.id1}_\{relation.id2}_\{count}",
      start: relation.id1,
      end: relation.id2,
      source: (if start_is_interface { interface_at } else { class_at })
      .get(relation.id1)
      .unwrap_or(-1),
      target: (if end_is_interface { interface_at } else { class_at })
      .get(relation.id2)
      .unwrap_or(-1),
      label: relation.title,
      arrow_type_start: marker_name(type1),
      arrow_type_end: marker_name(type2),
      start_label_right: if relation.relation_title1 == "none" {
        ""
      } else {
        relation.relation_title1
      },
      end_label_left: if relation.relation_title2 == "none" {
        ""
      } else {
        relation.relation_title2
      },
      pattern: if line_type == 1 {
        "dashed"
      } else {
        "solid"
      },
      classes: "relation",
    })
  }
  { nodes, edges, }
}

///|
/// The end marker a relation type draws.
fn marker_name(kind : Int32?) -> String {
  match kind {
    Some(0) => "aggregation"
    Some(1) => "extension"
    Some(2) => "composition"
    Some(3) => "dependency"
    Some(4) => "lollipop"
    _ => "none"
  }
}
