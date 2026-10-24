///|
let statement : String = "'EOF', 'SPACE', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'section', 'taskName'"

///|
fn text_of(tokens : @common.Tokens, i : Int32) -> String {
  @util.slice(tokens.src, tokens.starts[i], end=tokens.ends[i])
}

///|
fn fail(
  tokens : @common.Tokens,
  i : Int32,
  expected : String,
) -> Unit raise @errors.PeleError {
  let got = if tokens.kinds[i] == END {
    "1"
  } else {
    token_names[tokens.kinds[i]]
  }
  raise @errors.syntax_error(
    "journey",
    tokens.src,
    tokens.starts[i],
    "Expecting \{expected}, got '\{got}'",
  )
}

///|
/// Reads a journey into `db`. Raises a syntax `PeleError` with Mermaid's message on invalid text.
pub fn parse_journey(
  source : String,
  db : JourneyDb,
) -> Unit raise @errors.PeleError {
  let tokens = tokenize(source)
  if tokens.kinds[0] != JOURNEY {
    fail(tokens, 0, "'journey'")
  }
  let mut i = 1
  while true {
    let text = text_of(tokens, i)
    match tokens.kinds[i] {
      NEWLINE => ()
      TITLE => db.set_diagram_title(@util.slice(text, 6))
      ACC_TITLE => {
        i += 1
        db.set_acc_title(@util.trim(text_of(tokens, i)))
      }
      ACC_DESCR => {
        i += 1
        db.set_acc_description(@util.trim(text_of(tokens, i)))
      }
      ACC_DESCR_MULTILINE_VALUE => db.set_acc_description(@util.trim(text))
      SECTION => db.add_section(@util.slice(text, 8))
      TASK_NAME => {
        i += 1
        if tokens.kinds[i] != TASK_DATA {
          fail(tokens, i, "'taskData'")
        }
        db.add_task(text, text_of(tokens, i))
      }
      EOF => return
      _ => fail(tokens, i, statement)
    }
    i += 1
  }
}
