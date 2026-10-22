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
/// Reads the statements of an event model.
pub fn read_event_model(
  source : String,
) -> EventModelAst raise @errors.PeleError {
  ignore(source)
  raise @errors.pele_error("not implemented")
}
