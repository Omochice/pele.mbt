///|
/// The sequence model, built as Mermaid's SequenceDB builds it.
pub struct SeqDb {
  actors : Map[String, SeqActor]
  created_actors : Map[String, Int32]
  destroyed_actors : Map[String, Int32]
  boxes : Array[SeqBox]
  messages : Array[SeqMessage]
  notes : Array[SeqNote]
  mut title : String?
  mut acc_title : String?
  mut acc_descr : String?
}

///|
/// A model with the top-level `wrap` setting, which the `%%{wrap}%%` directive also sets, and `sequence.wrap`.
pub fn SeqDb::new(wrap? : Bool, sequence_wrap~ : Bool = false) -> SeqDb {
  ignore(wrap)
  ignore(sequence_wrap)
  {
    actors: Map([]),
    created_actors: Map([]),
    destroyed_actors: Map([]),
    boxes: [],
    messages: [],
    notes: [],
    title: None,
    acc_title: None,
    acc_descr: None,
  }
}

///|
pub fn SeqDb::set_acc_title(self : SeqDb, text : String) -> Unit {
  self.acc_title = Some(text)
}

///|
pub fn SeqDb::set_acc_description(self : SeqDb, text : String) -> Unit {
  self.acc_descr = Some(text)
}

///|
pub fn SeqDb::set_diagram_title(self : SeqDb, text : String) -> Unit {
  self.title = Some(text)
}

///|
/// Reads the `wrap:` or `nowrap:` prefix of a text.
pub fn SeqDb::parse_message(self : SeqDb, text : String) -> SeqText {
  ignore(self)
  { text, wrap: None, }
}

///|
/// Splits a box line into its fill and its title.
pub fn SeqDb::parse_box_data(self : SeqDb, line : String) -> SeqBoxData {
  ignore(self)
  ignore(line)
  { text: None, color: "", wrap: None, }
}

///|
/// Applies the statements of a diagram in order.
/// Raises `PeleError` for statements the model refuses.
pub fn SeqDb::apply(
  self : SeqDb,
  statements : Array[SeqStatement],
) -> Unit raise @errors.PeleError {
  ignore(self)
  ignore(statements)
  raise @errors.pele_error("not implemented")
}
