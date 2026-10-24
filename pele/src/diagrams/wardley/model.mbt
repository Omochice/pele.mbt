///|
/// Which way value flows along a link.
pub(all) enum Flow {
  Forward
  Backward
  Bidirectional
}

///|
/// A component, anchor, or pipeline component, with coordinates in percent: `x` is evolution and
/// `y` is visibility.
pub(all) struct WardleyNode {
  id : String
  label : String
  x : Double
  y : Double
  /// `anchor`, `component`, or `pipeline-component`.
  class_name : String
  label_offset_x : Double?
  label_offset_y : Double?
  mut in_pipeline : Bool
  mut is_pipeline_parent : Bool
  inertia : Bool
  source_strategy : String?
}

///|
pub(all) struct WardleyLink {
  source : String
  target : String
  dashed : Bool
  label : String?
  flow : Flow?
}

///|
/// Where a component is evolving to.
pub(all) struct WardleyTrend {
  node_id : String
  target_x : Double
  target_y : Double
}

///|
pub(all) struct WardleyPipeline {
  node_id : String
  component_ids : Array[String]
}

///|
/// A numbered mark on the map, whose text is listed in the annotations box.
pub(all) struct WardleyAnnotation {
  number : Double
  x : Double
  y : Double
  text : String
}

///|
pub(all) struct WardleyNote {
  text : String
  x : Double
  y : Double
}

///|
/// An accelerator or deaccelerator.
pub(all) struct WardleyForce {
  name : String
  x : Double
  y : Double
}

///|
/// A Wardley map ready to be drawn, with every position in percent.
pub(all) struct WardleyModel {
  title : String?
  acc_title : String?
  acc_descr : String?
  /// In the order their ids were first defined.
  nodes : Array[WardleyNode]
  links : Array[WardleyLink]
  trends : Array[WardleyTrend]
  pipelines : Array[WardleyPipeline]
  annotations : Array[WardleyAnnotation]
  notes : Array[WardleyNote]
  accelerators : Array[WardleyForce]
  deaccelerators : Array[WardleyForce]
  annotations_box : (Double, Double)?
  stages : Array[String]?
  /// The right edge of each stage that gives one, from 0 to 1.
  stage_boundaries : Array[Double]?
  size : (Double, Double)?
}

///|
/// Values up to 1 are fractions; larger ones are already percentages.
fn to_percent(
  value : Double,
  context : String,
) -> Double raise @errors.PeleError {
  let normalized = if value <= 1 { value * 100 } else { value }
  if normalized < 0 || normalized > 100 {
    raise @errors.pele_error(
      "\{context} must be between 0-1 (decimal) or 0-100 (percentage). Received: \{value}",
      code=Semantic,
      kind="wardley",
    )
  }
  normalized
}

///|
/// Evolution across and visibility up, in percent.
fn to_coordinates(
  visibility : Double,
  evolution : Double,
  context : String,
) -> (Double, Double) raise @errors.PeleError {
  (
    to_percent(evolution, "\{context} evolution"),
    to_percent(visibility, "\{context} visibility"),
  )
}

///|
fn flow_from_port(port : String?) -> Flow? {
  match port {
    Some("+<>") => Some(Bidirectional)
    Some("+<") => Some(Backward)
    Some("+>") => Some(Forward)
    _ => None
  }
}

///|
/// The flow and the label of an arrow like `+'label'>`.
fn flow_from_arrow(arrow : String?) -> (Flow?, String?) {
  guard arrow is Some(text) && text.has_prefix("+") else { (None, None) }
  let end = @util.index_of(text, "'", from=2)
  let label = if @util.code_at(text, 1) == '\''.to_int() && end != -1 {
    Some(@util.slice(text, 2, end~))
  } else {
    None
  }
  let flow = if text.contains("<>") {
    Some(Bidirectional)
  } else if text.contains("<") {
    Some(Backward)
  } else if text.contains(">") {
    Some(Forward)
  } else {
    None
  }
  (flow, label)
}

///|
fn signed(label : LabelAst?) -> (Double?, Double?) {
  match label {
    Some(l) =>
      (
        Some(if l.neg_x { -l.offset_x } else { l.offset_x }),
        Some(if l.neg_y { -l.offset_y } else { l.offset_y }),
      )
    None => (None, None)
  }
}

///|
/// `first ?? second`.
fn[T] either(first : T?, second : T?) -> T? {
  match first {
    Some(_) => first
    None => second
  }
}

///|
fn non_empty(value : String?) -> String? {
  match value {
    Some("") => None
    _ => value
  }
}

///|
/// Does what `text.replace(/\n\s+/g, '\n')` does.
fn join_indented_lines(text : String) -> String {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    @util.write_range(out, text, i, i + 1)
    if @util.code_at(text, i) == '\n'.to_int() &&
      @util.is_space(@util.code_at(text, i + 1)) {
      i += 1
      while @util.is_space(@util.code_at(text, i)) {
        i += 1
      }
    } else {
      i += 1
    }
  }
  out.to_string()
}

///|
/// Mermaid's populateDb: fills the builder from the syntax tree, in Mermaid's order.
fn populate(ast : WardleyAst, db : Builder) -> Unit raise @errors.PeleError {
  if ast.size is Some(size) {
    db.size = Some((size.width, size.height))
  }
  if ast.evolution is Some(stages) {
    db.stages = Some(
      stages.map(stage => {
        match stage.second_name {
          Some(second) if second != "" =>
            "\{@util.trim(stage.name)} / \{@util.trim(second)}"
          _ => @util.trim(stage.name)
        }
      }),
    )
    db.stage_boundaries = Some(stages.filter_map(stage => stage.boundary))
  }
  for anchor in ast.anchors {
    let (x, y) = to_coordinates(
      anchor.visibility,
      anchor.evolution,
      "Anchor \"\{anchor.name}\"",
    )
    db.add_node(id=anchor.name, label=anchor.name, x~, y~, class_name="anchor")
  }
  for component in ast.components {
    let (x, y) = to_coordinates(
      component.visibility,
      component.evolution,
      "Component \"\{component.name}\"",
    )
    let (label_offset_x, label_offset_y) = signed(component.label)
    db.add_node(
      id=component.name,
      label=component.name,
      x~,
      y~,
      class_name="component",
      label_offset_x?,
      label_offset_y?,
      traits=(component.inertia, component.strategy),
    )
  }
  for note in ast.notes {
    let (x, y) = to_coordinates(
      note.visibility,
      note.evolution,
      "Note \"\{note.text}\"",
    )
    db.notes.push({ text: note.text, x, y, })
  }
  for pipeline in ast.pipelines {
    guard db.nodes.get(pipeline.parent) is Some(parent) else {
      raise @errors.pele_error(
        "Pipeline \"\{pipeline.parent}\" must reference an existing component with coordinates.",
        code=Semantic,
        kind="wardley",
      )
    }
    let y = parent.y
    db.start_pipeline(pipeline.parent)
    for component in pipeline.components {
      let id = "\{pipeline.parent}_\{component.name}"
      let (label_offset_x, label_offset_y) = signed(component.label)
      let x = to_percent(
        component.evolution,
        "Pipeline component \"\{component.name}\" evolution",
      )
      db.add_node(
        id~,
        label=component.name,
        x~,
        y~,
        class_name="pipeline-component",
        label_offset_x?,
        label_offset_y?,
        traits=(false, None),
      )
      db.add_pipeline_component(pipeline.parent, id)
    }
  }
  for link in ast.links {
    let dashed = match link.arrow {
      Some(arrow) => arrow.contains("-.->") || arrow.contains(".-.")
      None => false
    }
    let (arrow_flow, arrow_label) = flow_from_arrow(link.arrow)
    let flow = either(
      either(flow_from_port(link.from_port), flow_from_port(link.to_port)),
      arrow_flow,
    )
    db.links.push({
      source: db.resolve_node_id(link.from),
      target: db.resolve_node_id(link.to),
      dashed,
      label: either(arrow_label, link.link_label),
      flow,
    })
  }
  for evolve in ast.evolves {
    if db.nodes.get(evolve.component) is Some(node) {
      db.trends.set(evolve.component, {
        node_id: evolve.component,
        target_x: to_percent(
          evolve.target,
          "Evolve target for \"\{evolve.component}\"",
        ),
        target_y: node.y,
      })
    }
  }
  if ast.annotations.get(0) is Some(box) {
    db.annotations_box = Some(to_coordinates(box.x, box.y, "Annotations box"))
  }
  for annotation in ast.annotation {
    let (x, y) = to_coordinates(
      annotation.x,
      annotation.y,
      "Annotation \{annotation.number}",
    )
    db.annotations.push({
      number: annotation.number,
      x,
      y,
      text: annotation.text,
    })
  }
  for force in ast.accelerators {
    let (x, y) = to_coordinates(
      force.x,
      force.y,
      "Accelerator \"\{force.name}\"",
    )
    db.accelerators.push({ name: force.name, x, y, })
  }
  for force in ast.deaccelerators {
    let (x, y) = to_coordinates(
      force.x,
      force.y,
      "Deaccelerator \"\{force.name}\"",
    )
    db.deaccelerators.push({ name: force.name, x, y, })
  }
}

///|
/// Builds the model of a Wardley map as Mermaid's database fills it.
/// `title` is the front matter title, used when the map has none.
/// Raises a semantic `PeleError` for a coordinate outside both ranges or a pipeline without its component.
pub fn build_wardley(
  ast : WardleyAst,
  title : String?,
) -> WardleyModel raise @errors.PeleError {
  let db = Builder::new()
  populate(ast, db)
  {
    title: either(non_empty(ast.title), title),
    acc_title: non_empty(ast.acc_title).map(@util.trim_start),
    acc_descr: non_empty(ast.acc_descr).map(join_indented_lines),
    nodes: db.nodes.values().collect(),
    links: db.links,
    trends: db.trends.values().collect(),
    pipelines: db.pipelines.values().collect(),
    annotations: db.annotations,
    notes: db.notes,
    accelerators: db.accelerators,
    deaccelerators: db.deaccelerators,
    annotations_box: db.annotations_box,
    stages: db.stages,
    stage_boundaries: db.stage_boundaries,
    size: db.size,
  }
}
