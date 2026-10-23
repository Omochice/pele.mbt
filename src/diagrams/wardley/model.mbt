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
/// Builds the model of a Wardley map as Mermaid's database fills it.
/// `title` is the front matter title, used when the map has none.
/// Raises a semantic `PeleError` for a coordinate outside both ranges or a pipeline without its component.
pub fn build_wardley(
  ast : WardleyAst,
  title : String?,
) -> WardleyModel raise @errors.PeleError {
  ignore((ast, title))
  raise @errors.pele_error("not built yet", code=Semantic, kind="wardley")
}
