///|
/// The tokens of Mermaid's ER grammar, plus `Char` for a character no rule names.
pub(all) enum Tok {
  End
  Error
  ErDiagram
  Eof
  Newline
  Colon
  StyleSeparator
  BlockStart
  BlockStop
  Sqs
  Sqe
  AccTitle
  AccTitleValue
  AccDescr
  AccDescrValue
  AccDescrMultilineValue
  EndKw
  Subgraph
  DirectionTb
  DirectionBt
  DirectionRl
  DirectionLr
  ClassDef
  UnicodeText
  StyleText
  Comma
  Class
  Style
  Semi
  Num
  Brkt
  EntityName
  DecimalNum
  EntityOne
  AttributeWord
  AttributeKey
  Comment
  ZeroOrOne
  ZeroOrMore
  OneOrMore
  OnlyOne
  MdParent
  NonIdentifying
  Identifying
  Word
  Char
}

///|
/// The name Mermaid's grammar gives the token, as its error messages quote it.
pub fn Tok::name(self : Tok) -> String {
  match self {
    End => "$end"
    Error => "INVALID"
    ErDiagram => "ER_DIAGRAM"
    Eof => "EOF"
    Newline => "NEWLINE"
    Colon => "COLON"
    StyleSeparator => "STYLE_SEPARATOR"
    BlockStart => "BLOCK_START"
    BlockStop => "BLOCK_STOP"
    Sqs => "SQS"
    Sqe => "SQE"
    AccTitle => "acc_title"
    AccTitleValue => "acc_title_value"
    AccDescr => "acc_descr"
    AccDescrValue => "acc_descr_value"
    AccDescrMultilineValue => "acc_descr_multiline_value"
    EndKw => "END"
    Subgraph => "SUBGRAPH"
    DirectionTb => "direction_tb"
    DirectionBt => "direction_bt"
    DirectionRl => "direction_rl"
    DirectionLr => "direction_lr"
    ClassDef => "CLASSDEF"
    UnicodeText => "UNICODE_TEXT"
    StyleText => "STYLE_TEXT"
    Comma => "COMMA"
    Class => "CLASS"
    Style => "STYLE"
    Semi => "SEMI"
    Num => "NUM"
    Brkt => "BRKT"
    EntityName => "ENTITY_NAME"
    DecimalNum => "DECIMAL_NUM"
    EntityOne => "ENTITY_ONE"
    AttributeWord => "ATTRIBUTE_WORD"
    AttributeKey => "ATTRIBUTE_KEY"
    Comment => "COMMENT"
    ZeroOrOne => "ZERO_OR_ONE"
    ZeroOrMore => "ZERO_OR_MORE"
    OneOrMore => "ONE_OR_MORE"
    OnlyOne => "ONLY_ONE"
    MdParent => "MD_PARENT"
    NonIdentifying => "NON_IDENTIFYING"
    Identifying => "IDENTIFYING"
    Word => "WORD"
    Char => "CHAR"
  }
}
