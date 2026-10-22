///|
/// The tokens of Mermaid's XY chart lexer, in the order its grammar numbers them.
priv enum Tok {
  End
  Error
  Newline
  Title
  AccTitle
  AccTitleValue
  AccDescr
  AccDescrValue
  AccDescrMultilineValue
  Xychart
  ChartOrientation
  XAxis
  YAxis
  ArrowDelimiter
  Line
  Bar
  NumberWithDecimal
  SquareBracesStart
  SquareBracesEnd
  Str
  Alpha
  Colon
  Plus
  Comma
  Equals
  Mult
  Brkt
  Underscore
  Dot
  Amp
  Minus
  Num
  Semi
  Eof
} derive(Eq)

///|
/// The name the grammar gives the token in its error messages.
fn Tok::name(self : Tok) -> String {
  match self {
    End => "$end"
    Error => "INVALID"
    Newline => "NEWLINE"
    Title => "title"
    AccTitle => "acc_title"
    AccTitleValue => "acc_title_value"
    AccDescr => "acc_descr"
    AccDescrValue => "acc_descr_value"
    AccDescrMultilineValue => "acc_descr_multiline_value"
    Xychart => "XYCHART"
    ChartOrientation => "CHART_ORIENTATION"
    XAxis => "X_AXIS"
    YAxis => "Y_AXIS"
    ArrowDelimiter => "ARROW_DELIMITER"
    Line => "LINE"
    Bar => "BAR"
    NumberWithDecimal => "NUMBER_WITH_DECIMAL"
    SquareBracesStart => "SQUARE_BRACES_START"
    SquareBracesEnd => "SQUARE_BRACES_END"
    Str => "STR"
    Alpha => "ALPHA"
    Colon => "COLON"
    Plus => "PLUS"
    Comma => "COMMA"
    Equals => "EQUALS"
    Mult => "MULT"
    Brkt => "BRKT"
    Underscore => "UNDERSCORE"
    Dot => "DOT"
    Amp => "AMP"
    Minus => "MINUS"
    Num => "NUM"
    Semi => "SEMI"
    Eof => "EOF"
  }
}

///|
/// The tokens of a source with the text and the offset each one starts at.
priv struct Tokens {
  types : Array[Tok]
  texts : Array[String]
  starts : Array[Int32]
}
