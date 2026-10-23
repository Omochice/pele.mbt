///|
/// Whether a message kind is drawn as a line between lifelines.
fn is_line_message(kind : Int32) -> Bool {
  match kind {
    0 | 1 | 3 | 4 | 5 | 6 | 24 | 25 | 33 | 34 => true
    _ => (kind >= 41 && kind <= 48) || (kind >= 51 && kind <= 58)
  }
}

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
/// A number as `||` takes it: zero and NaN fall back to `fallback`.
fn or_else(value : Double?, fallback : Double) -> Double {
  match value {
    Some(value) if !(value == 0 || value.is_nan()) => value
    _ => fallback
  }
}

///|
/// Counts message lines the way Mermaid's renderer does while it draws.
/// `always` numbers every line, as the `showSequenceNumbers` setting does.
pub fn number_messages(
  messages : Array[SeqMessage],
  always : Bool,
) -> Numbering {
  let index = []
  let shown = []
  let mut current = 1.0
  let mut step = 1.0
  let mut visible = false
  for m in messages {
    let mut number = @double.not_a_number
    let mut show = false
    if m.kind == AUTONUMBER {
      if m.numbering is Some(spec) {
        current = or_else(spec.start, current)
        step = or_else(spec.step, step)
        visible = spec.visible
      }
    } else if is_line_message(m.kind) {
      number = current
      show = visible || always
      current = ((current + step) * 100).round() / 100
    }
    index.push(number)
    shown.push(show)
  }
  { index, shown, visible, }
}

///|
/// Draws a sequence diagram.
pub fn render_sequence(
  db : SeqDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered {
  ignore(db)
  ignore(config)
  ignore(options)
  { svg: "", width: 0, height: 0, links: [], }
}
