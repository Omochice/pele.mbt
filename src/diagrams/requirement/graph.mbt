///|
priv struct GraphNode {
  id : String
  requirement : Requirement?
  element : RequirementElement?
  css_styles : Array[String]
  css_classes : String
}

///|
priv struct GraphEdge {
  id : String
  start : String?
  end : String?
  kind : String
  contains : Bool
}

///|
priv struct RequirementGraph {
  nodes : Array[GraphNode]
  edges : Array[GraphEdge]
  direction : String
}

///|
/// The nodes and edges to lay out: requirements first, then elements, as Mermaid orders them.
fn build_requirement_graph(db : RequirementDb) -> RequirementGraph {
  let nodes = []
  for _, requirement in db.requirements {
    nodes.push({
      id: requirement.name,
      requirement: Some(requirement),
      element: None,
      css_styles: requirement.css_styles,
      css_classes: requirement.classes.join(" "),
    })
  }
  for _, element in db.elements {
    nodes.push({
      id: element.name,
      requirement: None,
      element: Some(element),
      css_styles: element.css_styles,
      css_classes: element.classes.join(" "),
    })
  }
  let known = (id : String) => {
    if db.requirements.contains(id) || db.elements.contains(id) {
      Some(id)
    } else {
      None
    }
  }
  let edges = db.relations.mapi((index, relation) => {
    id: "\{relation.src}-\{relation.dst}-\{index}",
    start: known(relation.src),
    end: known(relation.dst),
    kind: relation.kind,
    contains: relation.kind == "contains",
  })
  { nodes, edges, direction: db.direction, }
}
