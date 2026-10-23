///|
/// The tokens of Mermaid's block grammar.
pub(all) enum Tok {
  End
  Error
  Key
  IdBlock
  Columns
  MdStr
  Str
  SpaceBlock
  Default
  LinkStyle
  Interpolate
  ClassDef
  DefaultClassDefId
  ClassDefId
  ClassDefStyleOpts
  Class
  ClassEntityIds
  StyleClass
  Style
  StyleEntityIds
  StyleDefinitionData
  AccTitle
  AccTitleValue
  AccDescr
  AccDescrValue
  AccDescrMultilineValue
  EndKw
  NodeDStart
  NodeDEnd
  BlockArrowStart
  BlockArrowEnd
  Dir
  NodeId
  Link
  StartLink
  LinkLabel
  Size
  Eof
}

///|
/// The name Mermaid's grammar gives the token, as its error messages quote it.
pub fn Tok::name(self : Tok) -> String {
  match self {
    End => "$end"
    Error => "INVALID"
    Key => "BLOCK_DIAGRAM_KEY"
    IdBlock => "id-block"
    Columns => "COLUMNS"
    MdStr => "MD_STR"
    Str => "STR"
    SpaceBlock => "SPACE_BLOCK"
    Default => "DEFAULT"
    LinkStyle => "LINKSTYLE"
    Interpolate => "INTERPOLATE"
    ClassDef => "classDef"
    DefaultClassDefId => "DEFAULT_CLASSDEF_ID"
    ClassDefId => "CLASSDEF_ID"
    ClassDefStyleOpts => "CLASSDEF_STYLEOPTS"
    Class => "class"
    ClassEntityIds => "CLASSENTITY_IDS"
    StyleClass => "STYLECLASS"
    Style => "style"
    StyleEntityIds => "STYLE_ENTITY_IDS"
    StyleDefinitionData => "STYLE_DEFINITION_DATA"
    AccTitle => "acc_title"
    AccTitleValue => "acc_title_value"
    AccDescr => "acc_descr"
    AccDescrValue => "acc_descr_value"
    AccDescrMultilineValue => "acc_descr_multiline_value"
    EndKw => "end"
    NodeDStart => "NODE_DSTART"
    NodeDEnd => "NODE_DEND"
    BlockArrowStart => "BLOCK_ARROW_START"
    BlockArrowEnd => "BLOCK_ARROW_END"
    Dir => "DIR"
    NodeId => "NODE_ID"
    Link => "LINK"
    StartLink => "START_LINK"
    LinkLabel => "LINK_LABEL"
    Size => "SIZE"
    Eof => "EOF"
  }
}
