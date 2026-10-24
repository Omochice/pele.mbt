///|
/// Mermaid's Wardley database, which the syntax tree fills in Mermaid's order.
priv struct Builder {
  nodes : Map[String, WardleyNode]
  /// The first node id of each label, made again after a node is added.
  mut labels : Map[String, String]?
  links : Array[WardleyLink]
  trends : Map[String, WardleyTrend]
  pipelines : Map[String, WardleyPipeline]
  annotations : Array[WardleyAnnotation]
  notes : Array[WardleyNote]
  accelerators : Array[WardleyForce]
  deaccelerators : Array[WardleyForce]
  mut annotations_box : (Double, Double)?
  mut stages : Array[String]?
  mut stage_boundaries : Array[Double]?
  mut size : (Double, Double)?
}

///|
fn Builder::new() -> Builder {
  {
    nodes: {},
    labels: None,
    links: [],
    trends: {},
    pipelines: {},
    annotations: [],
    notes: [],
    accelerators: [],
    deaccelerators: [],
    annotations_box: None,
    stages: None,
    stage_boundaries: None,
    size: None,
  }
}

///|
/// Adds a node, or redefines one, which keeps its place and its label offsets unless new ones are given.
/// Without `traits` (inertia and sourcing strategy), as for an anchor, the node keeps its old ones.
fn Builder::add_node(
  self : Builder,
  id~ : String,
  label~ : String,
  x~ : Double,
  y~ : Double,
  class_name~ : String,
  label_offset_x? : Double,
  label_offset_y? : Double,
  traits? : (Bool, String?),
) -> Unit {
  let existing = self.nodes.get(id)
  let (inertia, source_strategy) = match (traits, existing) {
    (Some(given), _) => given
    (None, Some(old)) => (old.inertia, old.source_strategy)
    (None, None) => (false, None)
  }
  self.nodes.set(id, {
    id,
    label,
    x,
    y,
    class_name,
    label_offset_x: either(label_offset_x, existing.bind(n => n.label_offset_x)),
    label_offset_y: either(label_offset_y, existing.bind(n => n.label_offset_y)),
    in_pipeline: existing.map(n => n.in_pipeline).unwrap_or(false),
    is_pipeline_parent: existing.map(n => n.is_pipeline_parent).unwrap_or(false),
    inertia,
    source_strategy,
  })
  self.labels = None
}

///|
/// Starts a pipeline under `node_id`, emptying one it already has.
fn Builder::start_pipeline(self : Builder, node_id : String) -> Unit {
  self.pipelines.set(node_id, { node_id, component_ids: [], })
  if self.nodes.get(node_id) is Some(node) {
    node.is_pipeline_parent = true
  }
}

///|
fn Builder::add_pipeline_component(
  self : Builder,
  pipeline_id : String,
  component_id : String,
) -> Unit {
  if self.pipelines.get(pipeline_id) is Some(pipeline) {
    pipeline.component_ids.push(component_id)
  }
  if self.nodes.get(component_id) is Some(node) {
    node.in_pipeline = true
  }
}

///|
/// A name is a node id, or else the label of the first node that has it.
/// Pipeline components have ids like `Parent_Child` and are linked by label.
fn Builder::resolve_node_id(self : Builder, name : String) -> String {
  if self.nodes.contains(name) {
    return name
  }
  let labels = match self.labels {
    Some(labels) => labels
    None => {
      let labels = Map([])
      for id, node in self.nodes {
        if !labels.contains(node.label) {
          labels.set(node.label, id)
        }
      }
      self.labels = Some(labels)
      labels
    }
  }
  labels.get(name).unwrap_or(name)
}
