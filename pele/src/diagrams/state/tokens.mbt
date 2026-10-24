///|
/// The tokens of Mermaid's state grammar, in the order of its symbol table.
pub(all) enum Tok {
  End
  Error
  Nl
  Sd
  Descr
  Arrow
  HideEmpty
  Scale
  Width
  CompositState
  StructStart
  StructStop
  StateDescr
  As
  Id
  Fork
  Join
  Choice
  Concurrent
  Note
  NoteText
  AccTitle
  AccTitleValue
  AccDescr
  AccDescrValue
  AccDescrMultilineValue
  Click
  Str
  Href
  ClassDef
  ClassdefId
  DefaultClassdefId
  ClassdefStyleopts
  Default
  Style
  StyleIds
  StyledefStyleopts
  Class
  ClassentityIds
  Styleclass
  DirectionTb
  DirectionBt
  DirectionRl
  DirectionLr
  EdgeState
  StyleSeparator
  LeftOf
  RightOf
  Invalid
}

///|
/// The name Mermaid's parser gives the token in its error messages.
pub fn Tok::name(self : Tok) -> String {
  match self {
    End => "$end"
    Error => "INVALID"
    Nl => "NL"
    Sd => "SD"
    Descr => "DESCR"
    Arrow => "-->"
    HideEmpty => "HIDE_EMPTY"
    Scale => "scale"
    Width => "WIDTH"
    CompositState => "COMPOSIT_STATE"
    StructStart => "STRUCT_START"
    StructStop => "STRUCT_STOP"
    StateDescr => "STATE_DESCR"
    As => "AS"
    Id => "ID"
    Fork => "FORK"
    Join => "JOIN"
    Choice => "CHOICE"
    Concurrent => "CONCURRENT"
    Note => "note"
    NoteText => "NOTE_TEXT"
    AccTitle => "acc_title"
    AccTitleValue => "acc_title_value"
    AccDescr => "acc_descr"
    AccDescrValue => "acc_descr_value"
    AccDescrMultilineValue => "acc_descr_multiline_value"
    Click => "CLICK"
    Str => "STRING"
    Href => "HREF"
    ClassDef => "classDef"
    ClassdefId => "CLASSDEF_ID"
    DefaultClassdefId => "DEFAULT_CLASSDEF_ID"
    ClassdefStyleopts => "CLASSDEF_STYLEOPTS"
    Default => "DEFAULT"
    Style => "style"
    StyleIds => "STYLE_IDS"
    StyledefStyleopts => "STYLEDEF_STYLEOPTS"
    Class => "class"
    ClassentityIds => "CLASSENTITY_IDS"
    Styleclass => "STYLECLASS"
    DirectionTb => "direction_tb"
    DirectionBt => "direction_bt"
    DirectionRl => "direction_rl"
    DirectionLr => "direction_lr"
    EdgeState => "EDGE_STATE"
    StyleSeparator => "STYLE_SEPARATOR"
    LeftOf => "left_of"
    RightOf => "right_of"
    Invalid => "INVALID"
  }
}
