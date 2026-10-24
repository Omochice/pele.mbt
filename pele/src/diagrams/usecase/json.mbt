///|
/// The line and column of `offset` in `text`, which starts at `line` and `column`.
fn location_at(
  text : String,
  offset : Int32,
  line : Int32,
  column : Int32,
) -> (Int32, Int32) {
  let mut line = line
  let mut column = column
  let end = @cmp.minimum(@cmp.maximum(offset, 0), text.length())
  for i in 0..<end {
    let c = @util.code_at(text, i)
    if c == 13 {
      line += 1
      column = 1
    } else if c == 10 {
      if i == 0 || @util.code_at(text, i - 1) != 13 {
        line += 1
        column = 1
      }
    } else {
      column += 1
    }
  }
  (line, column)
}

///|
fn json_error(
  message : String,
  line : Int32,
  column : Int32,
) -> @errors.PeleError {
  @errors.pele_error(
    "\{message} (line \{line}, column \{column})",
    code=Syntax,
    kind="usecase",
    line~,
    column~,
  )
}

///|
/// Reads the body of a `json` node, which has to be an object.
/// pele parses with `JSON.parse` and then walks the text again for the order its keys were written in; one reader does both here.
/// `origin` gives the line and column the text starts at in the diagram, for the error.
/// Returns the members of the object in the order they were first written; raises a syntax error with V8's message, located in the diagram, for text that is not JSON.
pub fn parse_ordered_json(
  text : String,
  origin : () -> (Int32, Int32),
) -> Map[String, Json] raise @errors.PeleError {
  let value = @util.parse_json(text) catch {
    @util.JsonError(message, offset) => {
      // pele finds the place from V8's message when it names one, and otherwise where its own walk
      // of the text stops, which is where V8 stopped too.
      let (line, column) = origin()
      let (line, column) = location_at(text, offset, line, column)
      raise json_error("Invalid JSON: \{message}", line, column)
    }
  }
  guard value is Object(entries) else {
    let (line, column) = origin()
    raise json_error("JSON value must have an object root", line, column)
  }
  entries
}
