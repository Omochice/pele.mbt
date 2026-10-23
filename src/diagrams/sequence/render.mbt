///|
/// The numbers of the message lines.
/// `index` holds the number each message line carries, whether or not it is shown, and NaN for every other entry.
/// `visible` says whether numbers are on after the last statement.
pub(all) struct Numbering {
  index : Array[Double]
  shown : Array[Bool]
  visible : Bool
}

///|
/// Counts message lines the way Mermaid's renderer does while it draws.
/// `always` numbers every line, as the `showSequenceNumbers` setting does.
pub fn number_messages(
  messages : Array[SeqMessage],
  always : Bool,
) -> Numbering {
  ignore(messages)
  ignore(always)
  { index: [], shown: [], visible: false, }
}
