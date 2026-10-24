///|
/// A node of a sankey diagram, numbered in the order its name first appears.
pub(all) struct SankeyNode {
  id : String
  index : Int32
}

///|
/// A flow between two nodes. `value` is whatever the amount's text read as, possibly NaN.
pub(all) struct SankeyLink {
  source : SankeyNode
  target : SankeyNode
  value : Double
}

///|
/// What a sankey diagram says: its nodes and the flows between them.
pub struct SankeyDb {
  nodes : Array[SankeyNode]
  links : Array[SankeyLink]
  mut title : String?
  priv lookup : Map[String, SankeyNode]
}

///|
pub fn SankeyDb::new() -> SankeyDb {
  { nodes: [], links: [], title: None, lookup: {}, }
}

///|
/// The node called `id`, created when there is none yet.
pub fn SankeyDb::find_or_create_node(
  self : SankeyDb,
  id : String,
) -> SankeyNode {
  match self.lookup.get(id) {
    Some(node) => node
    None => {
      let node = { id, index: self.nodes.length(), }
      self.lookup[id] = node
      self.nodes.push(node)
      node
    }
  }
}

///|
pub fn SankeyDb::add_link(
  self : SankeyDb,
  source : SankeyNode,
  target : SankeyNode,
  value : Double,
) -> Unit {
  self.links.push({ source, target, value, })
}
