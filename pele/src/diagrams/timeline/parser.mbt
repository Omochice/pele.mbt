///|
/// The names a parse error calls the token types by, indexed by type.
let token_names : Array[String] = [
  "$end", "EOF", "INVALID", "NEWLINE", "timeline", "timeline_lr", "timeline_td",
  "title", "acc_title", "acc_title_value", "acc_descr", "acc_descr_value", "acc_descr_multiline_value",
  "section", "period", "event",
]

///|
const STATEMENT : String = "'EOF', 'SPACE', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'section', 'period', 'event'"

///|
/// Reads a timeline into `db`.
/// Raises a syntax `PeleError` with Mermaid's message on invalid text.
pub fn parse_timeline(
  src : String,
  db : TimelineDb,
) -> Unit raise @errors.PeleError {
  let tokens = tokenize(src)
  let kinds = tokens.kinds
  let text = i => @util.slice(src, tokens.starts[i], end=tokens.ends[i])
  let fail = (i : Int32, expected : String) => {
    let got = if kinds[i] == T_END { "1" } else { token_names[kinds[i]] }
    raise @errors.syntax_error(
      "timeline",
      src,
      tokens.starts[i],
      "Expecting \{expected}, got '\{got}'",
    )
  }
  let head = kinds[0]
  if head != T_TIMELINE && head != T_TIMELINE_LR && head != T_TIMELINE_TD {
    fail(0, "'timeline', 'timeline_lr', 'timeline_td'")
  }
  if head != T_TIMELINE {
    db.set_direction(if head == T_TIMELINE_LR { "LR" } else { "TD" })
  }
  let mut i = 1
  while true {
    let kind = kinds[i]
    if kind == T_NEWLINE {
      // Nothing to record: line breaks only separate statements.
    } else if kind == T_TITLE {
      db.set_diagram_title(@util.slice(text(i), 6))
    } else if kind == T_ACC_TITLE {
      i += 1
      db.set_acc_title(@util.trim(text(i)))
    } else if kind == T_ACC_DESCR {
      i += 1
      db.set_acc_description(@util.trim(text(i)))
    } else if kind == T_ACC_DESCR_MULTILINE_VALUE {
      db.set_acc_description(@util.trim(text(i)))
    } else if kind == T_SECTION {
      db.add_section(@util.slice(text(i), 8))
    } else if kind == T_PERIOD {
      db.add_task(text(i))
    } else if kind == T_EVENT {
      db.add_event(@util.slice(text(i), 2))
    } else if kind == T_EOF {
      return
    } else {
      fail(i, STATEMENT)
    }
    i += 1
  }
}
