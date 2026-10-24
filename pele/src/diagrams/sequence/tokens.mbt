///|
/// The tokens of Mermaid's sequence grammar.
/// `Error` ends a stream at text no lexer rule matches; `Invalid` is a token the grammar skips.
pub(all) enum Tok {
  End
  Error
  Invalid
  Newline
  Sd
  Create
  Box
  RestOfLine
  EndKw
  Autonumber
  Num
  Off
  Activate
  Deactivate
  Title
  LegacyTitle
  AccTitle
  AccTitleValue
  AccDescr
  AccDescrValue
  AccDescrMultilineValue
  Loop
  Rect
  Opt
  Alt
  Par
  ParOver
  Critical
  Break
  Option
  And
  Else
  Participant
  As
  ParticipantActor
  Destroy
  Note
  Over
  Links
  Link
  Properties
  Details
  Comma
  LeftOf
  RightOf
  Plus
  Minus
  Central
  Actor
  ConfigStart
  ConfigContent
  ConfigEnd
  Txt
  SolidOpenArrow
  DottedOpenArrow
  SolidArrow
  BidirectionalSolidArrow
  DottedArrow
  BidirectionalDottedArrow
  SolidCross
  DottedCross
  SolidPoint
  DottedPoint
  SolidArrowTop
  SolidArrowBottom
  StickArrowTop
  StickArrowBottom
  SolidArrowTopDotted
  SolidArrowBottomDotted
  StickArrowTopDotted
  StickArrowBottomDotted
  SolidArrowTopReverse
  SolidArrowBottomReverse
  StickArrowTopReverse
  StickArrowBottomReverse
  SolidArrowTopReverseDotted
  SolidArrowBottomReverseDotted
  StickArrowTopReverseDotted
  StickArrowBottomReverseDotted
}

///|
/// The name Mermaid's grammar gives the token, as its error messages quote it.
pub fn Tok::name(self : Tok) -> String {
  match self {
    End => "$end"
    Error | Invalid => "INVALID"
    Newline => "NEWLINE"
    Sd => "SD"
    Create => "create"
    Box => "box"
    RestOfLine => "restOfLine"
    EndKw => "end"
    Autonumber => "autonumber"
    Num => "NUM"
    Off => "off"
    Activate => "activate"
    Deactivate => "deactivate"
    Title => "title"
    LegacyTitle => "legacy_title"
    AccTitle => "acc_title"
    AccTitleValue => "acc_title_value"
    AccDescr => "acc_descr"
    AccDescrValue => "acc_descr_value"
    AccDescrMultilineValue => "acc_descr_multiline_value"
    Loop => "loop"
    Rect => "rect"
    Opt => "opt"
    Alt => "alt"
    Par => "par"
    ParOver => "par_over"
    Critical => "critical"
    Break => "break"
    Option => "option"
    And => "and"
    Else => "else"
    Participant => "participant"
    As => "AS"
    ParticipantActor => "participant_actor"
    Destroy => "destroy"
    Note => "note"
    Over => "over"
    Links => "links"
    Link => "link"
    Properties => "properties"
    Details => "details"
    Comma => ","
    LeftOf => "left_of"
    RightOf => "right_of"
    Plus => "+"
    Minus => "-"
    Central => "()"
    Actor => "ACTOR"
    ConfigStart => "CONFIG_START"
    ConfigContent => "CONFIG_CONTENT"
    ConfigEnd => "CONFIG_END"
    Txt => "TXT"
    SolidOpenArrow => "SOLID_OPEN_ARROW"
    DottedOpenArrow => "DOTTED_OPEN_ARROW"
    SolidArrow => "SOLID_ARROW"
    BidirectionalSolidArrow => "BIDIRECTIONAL_SOLID_ARROW"
    DottedArrow => "DOTTED_ARROW"
    BidirectionalDottedArrow => "BIDIRECTIONAL_DOTTED_ARROW"
    SolidCross => "SOLID_CROSS"
    DottedCross => "DOTTED_CROSS"
    SolidPoint => "SOLID_POINT"
    DottedPoint => "DOTTED_POINT"
    SolidArrowTop => "SOLID_ARROW_TOP"
    SolidArrowBottom => "SOLID_ARROW_BOTTOM"
    StickArrowTop => "STICK_ARROW_TOP"
    StickArrowBottom => "STICK_ARROW_BOTTOM"
    SolidArrowTopDotted => "SOLID_ARROW_TOP_DOTTED"
    SolidArrowBottomDotted => "SOLID_ARROW_BOTTOM_DOTTED"
    StickArrowTopDotted => "STICK_ARROW_TOP_DOTTED"
    StickArrowBottomDotted => "STICK_ARROW_BOTTOM_DOTTED"
    SolidArrowTopReverse => "SOLID_ARROW_TOP_REVERSE"
    SolidArrowBottomReverse => "SOLID_ARROW_BOTTOM_REVERSE"
    StickArrowTopReverse => "STICK_ARROW_TOP_REVERSE"
    StickArrowBottomReverse => "STICK_ARROW_BOTTOM_REVERSE"
    SolidArrowTopReverseDotted => "SOLID_ARROW_TOP_REVERSE_DOTTED"
    SolidArrowBottomReverseDotted => "SOLID_ARROW_BOTTOM_REVERSE_DOTTED"
    StickArrowTopReverseDotted => "STICK_ARROW_TOP_REVERSE_DOTTED"
    StickArrowBottomReverseDotted => "STICK_ARROW_BOTTOM_REVERSE_DOTTED"
  }
}
