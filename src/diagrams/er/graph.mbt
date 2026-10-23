///|
/// An entity, or a subgraph drawn as a group, as it is laid out.
pub(all) struct ErGraphNode {
  id : String
  label : String
  alias_name : String
  attributes : Array[ErAttribute]
  is_group : Bool
  parent_id : String?
  css_styles : Array[String]
  css_compiled_styles : Array[String]
  css_classes : String
  dir : String?
}

///|
/// A relationship as it is drawn, with Mermaid's lower-cased cardinality at each end.
pub(all) struct ErGraphEdge {
  id : String
  start : String
  end : String
  label : String
  arrow_type_start : String
  arrow_type_end : String
  dashed : Bool
}

///|
/// The groups, nodes and edges an ER diagram is laid out as.
pub(all) struct ErGraph {
  nodes : Array[ErGraphNode]
  edges : Array[ErGraphEdge]
}

///|
/// Resolves a parsed ER diagram into what is drawn: subgraphs as groups, entities as nodes with their class styles, and relationships as edges.
pub fn build_er_graph(model : ErDb) -> ErGraph {
  let nodes = []
  let edges = []
  let subgraphs = model.subgraphs
  let compiled = (class_names : Array[String]) => {
    let out = []
    for name in class_names {
      guard model.classes.get(name) is Some(def) else { continue }
      for style in def.styles {
        out.push(@util.trim(style))
      }
      for style in def.text_styles {
        out.push(@util.trim(style))
      }
    }
    out
  }
  let parent_of : Map[String, String] = Map([])
  let subgraph_ids : Set[String] = Set([])
  for i = subgraphs.length() - 1; i >= 0; i = i - 1 {
    let subgraph = subgraphs[i]
    subgraph_ids.add(subgraph.id)
    for id in subgraph.nodes {
      parent_of.set(id, subgraph.id)
    }
  }
  for i = subgraphs.length() - 1; i >= 0; i = i - 1 {
    let subgraph = subgraphs[i]
    nodes.push({
      id: subgraph.id,
      label: subgraph.title,
      alias_name: "",
      attributes: [],
      is_group: true,
      parent_id: parent_of.get(subgraph.id),
      css_styles: subgraph.css_styles,
      css_compiled_styles: compiled(subgraph.classes),
      css_classes: subgraph.classes.join(" "),
      dir: subgraph.dir,
    })
  }
  // A name that is also a subgraph id stands for the subgraph.
  // Mermaid drops such an entity and leaves relationships written before the subgraph pointing at nothing; here they follow it, as in pele.
  let moved : Map[String, String] = Map([])
  for name, entity in model.entities {
    if subgraph_ids.contains(name) {
      moved.set(entity.id, name)
      continue
    }
    nodes.push({
      id: entity.id,
      label: entity.label,
      alias_name: entity.alias_name,
      attributes: entity.attributes,
      is_group: false,
      parent_id: parent_of.get(name),
      css_styles: entity.css_styles,
      css_compiled_styles: compiled(
        entity.css_classes.split(" ").map(s => s.to_owned()).to_array(),
      ),
      css_classes: entity.css_classes,
      dir: None,
    })
  }
  for index, relationship in model.relationships {
    let spec = relationship.rel_spec
    edges.push({
      id: "id_\{relationship.entity_a}_\{relationship.entity_b}_\{index}",
      start: moved.get(relationship.entity_a).unwrap_or(relationship.entity_a),
      end: moved.get(relationship.entity_b).unwrap_or(relationship.entity_b),
      label: relationship.role_a,
      arrow_type_start: marker_type(spec.card_b),
      arrow_type_end: marker_type(spec.card_a),
      dashed: spec.rel_type is NonIdentifying,
    })
  }
  { nodes, edges, }
}

///|
fn marker_type(card : Cardinality) -> String {
  match card {
    ZeroOrOne => "zero_or_one"
    ZeroOrMore => "zero_or_more"
    OneOrMore => "one_or_more"
    OnlyOne => "only_one"
    MdParent => "md_parent"
  }
}
