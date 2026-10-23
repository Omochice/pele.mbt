///|
/// The tokens of Mermaid's class diagram grammar.
pub(all) enum Tok {
  End
  Error
  ClassDiagram
  Newline
  Eof
  Sqs
  Str
  Sqe
  Dot
  GenericType
  Label
  AccTitle
  AccTitleValue
  AccDescr
  AccDescrValue
  AccDescrMultilineValue
  StructStart
  StructStop
  Namespace
  StyleSeparator
  AnnotationStart
  AnnotationEnd
  Class
  Member
  NoteFor
  Note
  ClassDef
  Alpha
  Comma
  DirectionTb
  DirectionBt
  DirectionRl
  DirectionLr
  Aggregation
  Extension
  Composition
  Dependency
  Lollipop
  Line
  DottedLine
  Callback
  Link
  LinkTarget
  Click
  CallbackName
  CallbackArgs
  Href
  Style
  CssClass
  Colon
  Brkt
  Pct
  Minus
  UnicodeText
  BquoteStr
  EdgeState
  EofInStruct
  OpenInStruct
  Plus
  Equals
  Punctuation
}

///|
/// The name Mermaid's grammar gives the token, as its error messages quote it.
pub fn Tok::name(self : Tok) -> String {
  match self {
    End => "$end"
    Error => "INVALID"
    ClassDiagram => "CLASS_DIAGRAM"
    Newline => "NEWLINE"
    Eof => "EOF"
    Sqs => "SQS"
    Str => "STR"
    Sqe => "SQE"
    Dot => "DOT"
    GenericType => "GENERICTYPE"
    Label => "LABEL"
    AccTitle => "acc_title"
    AccTitleValue => "acc_title_value"
    AccDescr => "acc_descr"
    AccDescrValue => "acc_descr_value"
    AccDescrMultilineValue => "acc_descr_multiline_value"
    StructStart => "STRUCT_START"
    StructStop => "STRUCT_STOP"
    Namespace => "NAMESPACE"
    StyleSeparator => "STYLE_SEPARATOR"
    AnnotationStart => "ANNOTATION_START"
    AnnotationEnd => "ANNOTATION_END"
    Class => "CLASS"
    Member => "MEMBER"
    NoteFor => "NOTE_FOR"
    Note => "NOTE"
    ClassDef => "CLASSDEF"
    Alpha => "ALPHA"
    Comma => "COMMA"
    DirectionTb => "direction_tb"
    DirectionBt => "direction_bt"
    DirectionRl => "direction_rl"
    DirectionLr => "direction_lr"
    Aggregation => "AGGREGATION"
    Extension => "EXTENSION"
    Composition => "COMPOSITION"
    Dependency => "DEPENDENCY"
    Lollipop => "LOLLIPOP"
    Line => "LINE"
    DottedLine => "DOTTED_LINE"
    Callback => "CALLBACK"
    Link => "LINK"
    LinkTarget => "LINK_TARGET"
    Click => "CLICK"
    CallbackName => "CALLBACK_NAME"
    CallbackArgs => "CALLBACK_ARGS"
    Href => "HREF"
    Style => "STYLE"
    CssClass => "CSSCLASS"
    Colon => "COLON"
    Brkt => "BRKT"
    Pct => "PCT"
    Minus => "MINUS"
    UnicodeText => "UNICODE_TEXT"
    BquoteStr => "BQUOTE_STR"
    EdgeState => "EDGE_STATE"
    EofInStruct => "EOF_IN_STRUCT"
    OpenInStruct => "OPEN_IN_STRUCT"
    Plus => "PLUS"
    Equals => "EQUALS"
    Punctuation => "PUNCTUATION"
  }
}
