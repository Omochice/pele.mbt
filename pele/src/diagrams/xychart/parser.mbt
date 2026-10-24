///|
priv struct Parser {
  src : String
  tokens : Tokens
  db : XyChartDb
  mut i : Int32
}

///|
/// A token past the end of the stream reads as `End`, which stops every loop.
fn Parser::kind(self : Parser) -> Tok {
  if self.i < self.tokens.types.length() {
    self.tokens.types[self.i]
  } else {
    End
  }
}

///|
fn Parser::start(self : Parser) -> Int32 {
  if self.i < self.tokens.starts.length() {
    self.tokens.starts[self.i]
  } else {
    self.src.length()
  }
}

///|
fn Parser::take(self : Parser) -> String {
  let text = self.tokens.texts[self.i]
  self.i += 1
  text
}

///|
fn[T] Parser::fail(
  self : Parser,
  expected : String,
) -> T raise @errors.PeleError {
  let kind = self.kind()
  if kind == Error {
    raise @errors.syntax_error(
      "xychart",
      self.src,
      self.start(),
      "",
      lexical=true,
    )
  }
  raise @errors.syntax_error(
    "xychart",
    self.src,
    self.start(),
    "Expecting \{expected}, got '\{kind.name()}'",
  )
}

///|
fn Parser::expect(self : Parser, kind : Tok) -> String raise @errors.PeleError {
  if self.kind() != kind {
    self.fail("'\{kind.name()}'")
  }
  self.take()
}

///|
fn is_word(kind : Tok) -> Bool {
  match kind {
    Amp
    | Num
    | Alpha
    | Plus
    | Equals
    | Mult
    | Dot
    | Brkt
    | Minus
    | Underscore => true
    _ => false
  }
}

///|
fn is_end_of_line(kind : Tok) -> Bool {
  kind is (Newline | Semi | Eof)
}

///|
fn Parser::at_text(self : Parser) -> Bool {
  let kind = self.kind()
  kind == Str || is_word(kind)
}

///|
/// A quoted string stands alone, and anything else runs on over the words that follow it.
fn Parser::text(self : Parser) -> String raise @errors.PeleError {
  if !self.at_text() {
    self.fail("'STR', 'ALPHA', 'NUM'")
  }
  let quoted = self.kind() == Str
  let first = self.take()
  if quoted || !is_word(self.kind()) {
    return first
  }
  // The run is gathered before it is copied, because a label of hundreds of millions of
  // characters copied into a doubling builder would need a block past what wasm allocates.
  let parts = [first]
  while is_word(self.kind()) {
    parts.push(self.take())
  }
  parts.join("")
}

///|
fn Parser::number(self : Parser) -> Double raise @errors.PeleError {
  @util.to_number(self.expect(NumberWithDecimal))
}

///|
fn Parser::range(self : Parser) -> (Double, Double) raise @errors.PeleError {
  let min = self.number()
  ignore(self.expect(ArrowDelimiter))
  (min, self.number())
}

///|
fn Parser::points(self : Parser) -> Array[DataPoint] raise @errors.PeleError {
  let out = []
  ignore(self.expect(SquareBracesStart))
  while true {
    let value = self.number()
    let label = if self.kind() == Str { self.take() } else { "" }
    out.push({ value, label, })
    if self.kind() != Comma {
      break
    }
    self.i += 1
  }
  ignore(self.expect(SquareBracesEnd))
  out
}

///|
fn Parser::skip_line_ends(self : Parser) -> Unit {
  while is_end_of_line(self.kind()) {
    self.i += 1
  }
}

///|
/// Reads what follows `x-axis` or `y-axis`: an optional title, then a range, or categories on the x axis.
fn Parser::axis(self : Parser, x : Bool) -> Unit raise @errors.PeleError {
  let title = if self.at_text() { Some(self.text()) } else { None }
  if x && self.kind() == SquareBracesStart {
    let categories = []
    while true {
      self.i += 1
      categories.push(self.text())
      if self.kind() != Comma {
        break
      }
    }
    ignore(self.expect(SquareBracesEnd))
    self.db.set_x_axis_band(categories)
  } else if self.kind() == NumberWithDecimal || title is None {
    let (min, max) = self.range()
    if x {
      self.db.set_x_axis_range_data(min, max)
    } else {
      self.db.set_y_axis_range_data(min, max)
    }
  }
  let title = title.unwrap_or("")
  if x {
    self.db.set_x_axis_title(title)
  } else {
    self.db.set_y_axis_title(title)
  }
}

///|
fn Parser::series(self : Parser, kind : Tok) -> Unit raise @errors.PeleError {
  let title = if self.kind() == SquareBracesStart { "" } else { self.text() }
  let data = self.points()
  if kind == Line {
    self.db.set_line_data(title, data)
  } else {
    self.db.set_bar_data(title, data)
  }
}

///|
fn Parser::chart_header(self : Parser) -> Unit {
  while true {
    if is_end_of_line(self.kind()) {
      self.i += 1
    } else if self.kind() != Xychart {
      break
    } else {
      self.i += 1
      if self.kind() == ChartOrientation {
        self.db.set_orientation(self.take())
      }
    }
  }
}

///|
fn Parser::statements(self : Parser) -> Unit raise @errors.PeleError {
  while self.kind() != End {
    let kind = self.kind()
    self.i += 1
    match kind {
      Title => self.db.set_diagram_title(@util.trim(self.text()))
      XAxis => self.axis(true)
      YAxis => self.axis(false)
      Line | Bar => self.series(kind)
      AccTitle => self.db.set_acc_title(@util.trim(self.expect(AccTitleValue)))
      AccDescr =>
        self.db.set_acc_description(@util.trim(self.expect(AccDescrValue)))
      AccDescrMultilineValue =>
        self.db.set_acc_description(@util.trim(self.tokens.texts[self.i - 1]))
      _ => {
        self.i -= 1
        self.fail(
          "'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value'",
        )
      }
    }
    self.skip_line_ends()
  }
}

///|
/// Reads the statements of an XY chart source into `db`.
/// Raises a syntax `PeleError` where the source does not follow Mermaid's grammar.
pub fn parse_xychart(
  source : String,
  db : XyChartDb,
) -> Unit raise @errors.PeleError {
  let parser = { src: source, tokens: tokenize(source), db, i: 0, }
  parser.chart_header()
  parser.statements()
}
