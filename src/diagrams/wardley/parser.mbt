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
fn is_name(r : @common.TokenReader) -> Bool {
  r.kind() is (STRING | ID | NAME)
}

///|
fn name(r : @common.TokenReader) -> String raise @errors.PeleError {
  match r.kind() {
    STRING => @common.string_value(r.take())
    ID | NAME => r.take()
    _ => r.fail("a name")
  }
}

///|
fn number(r : @common.TokenReader) -> Double raise @errors.PeleError {
  @util.to_number(r.expect(NUMBER))
}

///|
fn int(r : @common.TokenReader) -> Double raise @errors.PeleError {
  @util.to_number(r.expect(INT))
}

///|
/// A coordinate of an annotation, which may be written as a whole number.
fn coordinate(r : @common.TokenReader) -> Double raise @errors.PeleError {
  if r.kind() == NUMBER {
    @util.to_number(r.take())
  } else {
    int(r)
  }
}

///|
fn end_of_line(r : @common.TokenReader) -> Unit raise @errors.PeleError {
  if r.kind() == -1 {
    return
  }
  if r.kind() != NEWLINE {
    r.fail("a line break or the end of input")
  }
  while r.kind() == NEWLINE {
    r.i += 1
  }
}

///|
fn pair(
  r : @common.TokenReader,
  read : (@common.TokenReader) -> Double raise @errors.PeleError,
) -> (Double, Double) raise @errors.PeleError {
  r.expect(LBRACKET) |> ignore
  let first = read(r)
  r.expect(COMMA) |> ignore
  let second = read(r)
  r.expect(RBRACKET) |> ignore
  (first, second)
}

///|
fn label(r : @common.TokenReader) -> LabelAst raise @errors.PeleError {
  r.expect(LABEL) |> ignore
  r.expect(LBRACKET) |> ignore
  let neg_x = r.accept(MINUS)
  let offset_x = int(r)
  r.expect(COMMA) |> ignore
  let neg_y = r.accept(MINUS)
  let offset_y = int(r)
  r.expect(RBRACKET) |> ignore
  { neg_x, offset_x, neg_y, offset_y, }
}

///|
fn optional_label(r : @common.TokenReader) -> LabelAst? raise @errors.PeleError {
  if r.kind() == LABEL {
    Some(label(r))
  } else {
    None
  }
}

///|
fn stage(r : @common.TokenReader) -> StageAst raise @errors.PeleError {
  let stage_name = name(r)
  let boundary = if r.accept(AT) { Some(number(r)) } else { None }
  let second_name = if r.accept(SLASH) { Some(name(r)) } else { None }
  { name: stage_name, boundary, second_name, }
}

///|
fn component(r : @common.TokenReader) -> ComponentAst raise @errors.PeleError {
  let component_name = name(r)
  let (visibility, evolution) = pair(r, number)
  let offsets = optional_label(r)
  let mut strategy = None
  if r.kind() == LPAREN && r.tokens.kinds[r.i + 1] == STRATEGY {
    r.i += 1
    strategy = Some(r.take())
    r.expect(RPAREN) |> ignore
  }
  let mut inertia = false
  if r.accept(INERTIA) {
    inertia = true
  } else if r.accept(LPAREN) {
    r.expect(INERTIA) |> ignore
    r.expect(RPAREN) |> ignore
    inertia = true
  }
  end_of_line(r)
  {
    name: component_name,
    visibility,
    evolution,
    label: offsets,
    strategy,
    inertia,
  }
}

///|
fn pipeline(r : @common.TokenReader) -> PipelineAst raise @errors.PeleError {
  let parent = name(r)
  r.expect(LBRACE) |> ignore
  r.expect(NEWLINE) |> ignore
  while r.kind() == NEWLINE {
    r.i += 1
  }
  let components = []
  while true {
    r.expect(COMPONENT) |> ignore
    let component_name = name(r)
    r.expect(LBRACKET) |> ignore
    let evolution = number(r)
    r.expect(RBRACKET) |> ignore
    let offsets = optional_label(r)
    end_of_line(r)
    components.push({ name: component_name, evolution, label: offsets, })
    if r.kind() != COMPONENT {
      break
    }
  }
  r.expect(RBRACE) |> ignore
  end_of_line(r)
  { parent, components, }
}

///|
fn link(r : @common.TokenReader) -> LinkAst raise @errors.PeleError {
  if !is_name(r) {
    r.fail("a statement")
  }
  let from = name(r)
  let from_port = if r.kind() == LINK_PORT { Some(r.take()) } else { None }
  let arrow = if r.kind() == LINK_ARROW || r.kind() == ARROW {
    Some(r.take())
  } else {
    None
  }
  let to = name(r)
  let to_port = if r.kind() == LINK_PORT { Some(r.take()) } else { None }
  let link_label = if r.kind() == LINK_LABEL {
    Some(@util.trim(@util.slice(r.take(), 1)))
  } else {
    None
  }
  end_of_line(r)
  { from, from_port, arrow, to, to_port, link_label, }
}

///|
/// Reads the statements of a Wardley map.
/// Raises a syntax `PeleError` where Mermaid's grammar rejects the text.
pub fn parse_wardley(src : String) -> WardleyAst raise @errors.PeleError {
  let r = @common.TokenReader::new(
    @common.tokenize(src, wardley_tokens, "wardley"),
    wardley_tokens,
    "wardley",
  )
  let ast : WardleyAst = {
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
  while r.kind() == NEWLINE {
    r.i += 1
  }
  r.expect(WARDLEY) |> ignore
  while r.kind() != -1 {
    match r.kind() {
      NEWLINE => r.i += 1
      ACC_DESCR => {
        ast.acc_descr = Some(@common.acc_descr_value(r.take()))
        end_of_line(r)
      }
      ACC_TITLE => {
        ast.acc_title = Some(@common.acc_title_value(r.take()))
        end_of_line(r)
      }
      TITLE => {
        ast.title = Some(@common.title_value(r.take()))
        end_of_line(r)
      }
      SIZE => {
        r.i += 1
        let (width, height) = pair(r, int)
        end_of_line(r)
        ast.size = Some({ width, height, })
      }
      EVOLUTION => {
        r.i += 1
        let stages = [stage(r)]
        r.expect(ARROW) |> ignore
        stages.push(stage(r))
        while r.accept(ARROW) {
          stages.push(stage(r))
        }
        end_of_line(r)
        ast.evolution = Some(stages)
      }
      ANCHOR => {
        r.i += 1
        let anchor = name(r)
        let (visibility, evolution) = pair(r, number)
        end_of_line(r)
        ast.anchors.push({ name: anchor, visibility, evolution, })
      }
      COMPONENT => {
        r.i += 1
        ast.components.push(component(r))
      }
      EVOLVE => {
        r.i += 1
        let evolved = name(r)
        let target = number(r)
        end_of_line(r)
        ast.evolves.push({ component: evolved, target, })
      }
      PIPELINE => {
        r.i += 1
        ast.pipelines.push(pipeline(r))
      }
      NOTE => {
        r.i += 1
        let text = @common.string_value(r.expect(STRING))
        let (visibility, evolution) = pair(r, number)
        end_of_line(r)
        ast.notes.push({ text, visibility, evolution, })
      }
      ANNOTATIONS => {
        r.i += 1
        let (x, y) = pair(r, coordinate)
        end_of_line(r)
        ast.annotations.push({ x, y, })
      }
      ANNOTATION => {
        r.i += 1
        let n = int(r)
        r.expect(COMMA) |> ignore
        let (x, y) = pair(r, coordinate)
        let text = @common.string_value(r.expect(STRING))
        end_of_line(r)
        ast.annotation.push({ number: n, x, y, text, })
      }
      ACCELERATOR | DEACCELERATOR => {
        let slow = r.kind() == DEACCELERATOR
        r.i += 1
        let force = name(r)
        let (x, y) = pair(r, number)
        end_of_line(r)
        if slow {
          ast.deaccelerators.push({ name: force, x, y, })
        } else {
          ast.accelerators.push({ name: force, x, y, })
        }
      }
      _ => ast.links.push(link(r))
    }
  }
  ast
}
