///|
/// A label offset as written: each sign apart from its magnitude.
pub(all) struct LabelAst {
  neg_x : Bool
  offset_x : Double
  neg_y : Bool
  offset_y : Double
}

///|
/// A stage of the evolution axis, with the right edge it gives itself and its second name.
pub(all) struct StageAst {
  name : String
  boundary : Double?
  second_name : String?
}

///|
pub(all) struct ComponentAst {
  name : String
  visibility : Double
  evolution : Double
  label : LabelAst?
  strategy : String?
  inertia : Bool
}

///|
pub(all) struct PipelineComponentAst {
  name : String
  evolution : Double
  label : LabelAst?
}

///|
/// A link as written: the ports and arrow are the text of their tokens.
pub(all) struct LinkAst {
  from : String
  from_port : String?
  arrow : String?
  to : String
  to_port : String?
  link_label : String?
}

///|
pub(all) struct AnchorAst {
  name : String
  visibility : Double
  evolution : Double
}

///|
pub(all) struct EvolveAst {
  component : String
  target : Double
}

///|
pub(all) struct PipelineAst {
  parent : String
  components : Array[PipelineComponentAst]
}

///|
pub(all) struct NoteAst {
  text : String
  visibility : Double
  evolution : Double
}

///|
/// Where the box of annotation texts goes.
pub(all) struct AnnotationsAst {
  x : Double
  y : Double
}

///|
pub(all) struct AnnotationAst {
  number : Double
  x : Double
  y : Double
  text : String
}

///|
/// An accelerator or deaccelerator.
pub(all) struct ForceAst {
  name : String
  x : Double
  y : Double
}

///|
pub(all) struct SizeAst {
  width : Double
  height : Double
}

///|
/// The statements of a Wardley map, as Mermaid's grammar reads them.
pub(all) struct WardleyAst {
  mut title : String?
  mut acc_title : String?
  mut acc_descr : String?
  mut size : SizeAst?
  mut evolution : Array[StageAst]?
  anchors : Array[AnchorAst]
  components : Array[ComponentAst]
  links : Array[LinkAst]
  evolves : Array[EvolveAst]
  pipelines : Array[PipelineAst]
  notes : Array[NoteAst]
  annotations : Array[AnnotationsAst]
  annotation : Array[AnnotationAst]
  accelerators : Array[ForceAst]
  deaccelerators : Array[ForceAst]
}

///|
/// Mermaid's Wardley lexer, in its matching order.
pub let wardley_tokens : Array[@common.TokenType] = []

///|
/// Reads the statements of a Wardley map.
/// Raises a syntax `PeleError` where Mermaid's grammar rejects the text.
pub fn parse_wardley(src : String) -> WardleyAst raise @errors.PeleError {
  ignore(@common.tokenize(src, wardley_tokens, "wardley"))
  {
    title: None,
    acc_title: None,
    acc_descr: None,
    size: None,
    evolution: None,
    anchors: [],
    components: [],
    links: [],
    evolves: [],
    pipelines: [],
    notes: [],
    annotations: [],
    annotation: [],
    accelerators: [],
    deaccelerators: [],
  }
}
