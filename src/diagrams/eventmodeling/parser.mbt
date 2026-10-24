///|
/// A frame as written: a time frame or a reset frame.
pub(all) struct EmFrame {
  reset : Bool
  /// The frame number as written, such as "01".
  name : String
  model_entity_type : String
  entity_identifier : String
  /// The text of each `->>` source, never linked to its frame.
  source_frames : Array[String]
  data_reference : String?
  data_type : String?
  data_inline_value : String?
  /// Offset of the frame in the source, for error messages.
  offset : Int32
}

///|
pub(all) struct EmDataEntity {
  name : String
  data_type : String?
  data_block_value : String
}

///|
pub(all) struct EmNoteEntity {
  source_frame : String
  data_type : String?
  data_block_value : String
}

///|
/// A given/when/then specification: the entity names of its three statement lists.
pub(all) struct EmGwt {
  source_frame : String
  given : Array[String]
  when_ : Array[String]
  then_ : Array[String]
}

///|
/// What the grammar reads from an event model.
pub(all) struct EventModelAst {
  /// The whole token, keyword included: the grammar's own terminals get no value conversion.
  mut title : String?
  mut acc_title : String?
  mut acc_descr : String?
  model_entities : Array[String]
  frames : Array[EmFrame]
  data_entities : Array[EmDataEntity]
  note_entities : Array[EmNoteEntity]
  gwt_entities : Array[EmGwt]
  source : String
}

///|
fn one_of(
  r : @common.TokenReader,
  kinds : Array[Int32],
  expected : String,
) -> String raise @errors.PeleError {
  if kinds.contains(r.kind()) {
    r.take()
  } else {
    r.fail(expected)
  }
}

///|
fn qualified_name(r : @common.TokenReader) -> String raise @errors.PeleError {
  // Joined at its final size, because a name of hundreds of millions of characters would need a
  // doubling builder's block past what wasm allocates.
  let parts = [r.expect(t_id)]
  while r.accept(t_dot) {
    parts.push(r.expect(t_id))
  }
  if parts.length() == 1 {
    parts[0]
  } else {
    parts.join(".")
  }
}

///|
fn read_data_type(r : @common.TokenReader) -> String? raise @errors.PeleError {
  if !r.accept(t_tick) {
    return None
  }
  let type_ = one_of(r, data_types, "a data type")
  ignore(r.expect(t_tick))
  Some(type_)
}

///|
fn read_statements(
  r : @common.TokenReader,
) -> Array[String] raise @errors.PeleError {
  let names = []
  while true {
    ignore(one_of(r, entity_type, "an entity type"))
    names.push(r.expect(t_id))
    if !entity_type.contains(r.kind()) {
      break
    }
  }
  names
}

///|
fn read_frame(
  r : @common.TokenReader,
  reset : Bool,
) -> EmFrame raise @errors.PeleError {
  let offset = r.tokens.starts[r.i]
  r.i += 1
  let name = r.expect(t_frame_id)
  let model_entity_type = one_of(r, entity_type, "an entity type")
  let entity_identifier = qualified_name(r)
  let source_frames = []
  while r.accept(t_arrow) {
    source_frames.push(r.expect(t_frame_id))
  }
  let mut data_reference = None
  if r.accept(t_open) {
    data_reference = Some(r.expect(t_id))
    ignore(r.expect(t_close))
  }
  let mut data_type = None
  let mut data_inline_value = None
  if r.kind() == t_tick || r.kind() == t_inline {
    data_type = read_data_type(r)
    data_inline_value = Some(r.expect(t_inline))
  }
  {
    reset,
    name,
    model_entity_type,
    entity_identifier,
    source_frames,
    data_reference,
    data_type,
    data_inline_value,
    offset,
  }
}

///|
fn read_specification(r : @common.TokenReader) -> EmGwt raise @errors.PeleError {
  r.i += 1
  let source_frame = r.expect(t_frame_id)
  ignore(r.expect(t_given))
  let given = read_statements(r)
  let when_ = if r.accept(t_when) { read_statements(r) } else { [] }
  ignore(r.expect(t_then))
  let then_ = read_statements(r)
  { source_frame, given, when_, then_, }
}

///|
/// Reads the statements of an event model.
pub fn read_event_model(
  source : String,
) -> EventModelAst raise @errors.PeleError {
  let r = @common.TokenReader::new(
    @common.tokenize(source, tokens[:], "eventmodeling"),
    tokens[:],
    "eventmodeling",
  )
  let ast : EventModelAst = {
    title: None,
    acc_title: None,
    acc_descr: None,
    model_entities: [],
    frames: [],
    data_entities: [],
    note_entities: [],
    gwt_entities: [],
    source,
  }
  ignore(r.expect(t_keyword))
  while r.kind() != -1 {
    let kind = r.kind()
    if kind == t_acc_descr {
      ast.acc_descr = Some(r.take())
    } else if kind == t_acc_title {
      ast.acc_title = Some(r.take())
    } else if kind == t_title {
      ast.title = Some(r.take())
    } else if kind == t_entity {
      r.i += 1
      ast.model_entities.push(qualified_name(r))
    } else if time_frame.contains(kind) {
      ast.frames.push(read_frame(r, false))
    } else if reset_frame.contains(kind) {
      ast.frames.push(read_frame(r, true))
    } else if kind == t_data {
      r.i += 1
      let name = r.expect(t_id)
      let data_type = read_data_type(r)
      let data_block_value = r.expect(t_block)
      ast.data_entities.push({ name, data_type, data_block_value, })
    } else if kind == t_note {
      r.i += 1
      let source_frame = r.expect(t_frame_id)
      let data_type = read_data_type(r)
      let data_block_value = r.expect(t_block)
      ast.note_entities.push({ source_frame, data_type, data_block_value, })
    } else if kind == t_gwt {
      ast.gwt_entities.push(read_specification(r))
    } else {
      r.fail("a frame, an entity, a data block, a note, or a specification")
    }
  }
  ast
}
