// Token types, numbered as pele's `const enum T`: the parser computes a direction from its offset to DIRECTION_TB.

///|
const END_OF_INPUT : Int32 = 0

///|
const ERROR : Int32 = 1

///|
const ACC_TITLE : Int32 = 2

///|
const ACC_TITLE_VALUE : Int32 = 3

///|
const ACC_DESCR : Int32 = 4

///|
const ACC_DESCR_VALUE : Int32 = 5

///|
const ACC_DESCR_MULTILINE_VALUE : Int32 = 6

///|
const SHAPE_DATA : Int32 = 7

///|
const CALLBACKNAME : Int32 = 8

///|
const CALLBACKARGS : Int32 = 9

///|
const MD_STR : Int32 = 10

///|
const STR : Int32 = 11

///|
const STYLE : Int32 = 12

///|
const DEFAULT : Int32 = 13

///|
const LINKSTYLE : Int32 = 14

///|
const INTERPOLATE : Int32 = 15

///|
const CLASSDEF : Int32 = 16

///|
const CLASS : Int32 = 17

///|
const HREF : Int32 = 18

///|
const CLICK : Int32 = 19

///|
const GRAPH : Int32 = 20

///|
const SUBGRAPH : Int32 = 21

///|
/// The `end` keyword that closes a subgraph.
const SUBGRAPH_END : Int32 = 22

///|
const LINK_TARGET : Int32 = 23

///|
const NODIR : Int32 = 24

///|
const DIR : Int32 = 25

///|
const DIRECTION_TB : Int32 = 26

///|
const DIRECTION_BT : Int32 = 27

///|
const DIRECTION_RL : Int32 = 28

///|
const DIRECTION_LR : Int32 = 29

///|
const DIRECTION_TD : Int32 = 30

///|
const LINK_ID : Int32 = 31

///|
const NUM : Int32 = 32

///|
const BRKT : Int32 = 33

///|
const STYLE_SEPARATOR : Int32 = 34

///|
const COLON : Int32 = 35

///|
const AMP : Int32 = 36

///|
const SEMI : Int32 = 37

///|
const COMMA : Int32 = 38

///|
const MULT : Int32 = 39

///|
const LINK : Int32 = 40

///|
const START_LINK : Int32 = 41

///|
const EDGE_TEXT : Int32 = 42

///|
const ELLIPSE_END : Int32 = 43

///|
const TEXT : Int32 = 44

///|
const ELLIPSE_START : Int32 = 45

///|
const STADIUMEND : Int32 = 46

///|
const STADIUMSTART : Int32 = 47

///|
const SUBROUTINEEND : Int32 = 48

///|
const SUBROUTINESTART : Int32 = 49

///|
const VERTEX_WITH_PROPS_START : Int32 = 50

///|
const TAGEND : Int32 = 51

///|
const CYLINDEREND : Int32 = 52

///|
const CYLINDERSTART : Int32 = 53

///|
const DOUBLECIRCLEEND : Int32 = 54

///|
const DOUBLECIRCLESTART : Int32 = 55

///|
const TRAPEND : Int32 = 56

///|
const INVTRAPEND : Int32 = 57

///|
const TRAPSTART : Int32 = 58

///|
const INVTRAPSTART : Int32 = 59

///|
const TAGSTART : Int32 = 60

///|
const UP : Int32 = 61

///|
const SEP : Int32 = 62

///|
const DOWN : Int32 = 63

///|
const NODE_STRING : Int32 = 64

///|
const MINUS : Int32 = 65

///|
const UNICODE_TEXT : Int32 = 66

///|
const PIPE : Int32 = 67

///|
const PE : Int32 = 68

///|
const PS : Int32 = 69

///|
const SQE : Int32 = 70

///|
const SQS : Int32 = 71

///|
const DIAMOND_STOP : Int32 = 72

///|
const DIAMOND_START : Int32 = 73

///|
const NEWLINE : Int32 = 74

///|
const SPACE : Int32 = 75

///|
const EOF : Int32 = 76

///|
/// The names Mermaid's grammar gives the token types, by number, as they appear in parse errors.
pub let token_names : Array[String] = [
  "$end", "INVALID", "acc_title", "acc_title_value", "acc_descr", "acc_descr_value",
  "acc_descr_multiline_value", "SHAPE_DATA", "CALLBACKNAME", "CALLBACKARGS", "MD_STR",
  "STR", "STYLE", "DEFAULT", "LINKSTYLE", "INTERPOLATE", "CLASSDEF", "CLASS", "HREF",
  "CLICK", "GRAPH", "subgraph", "end", "LINK_TARGET", "NODIR", "DIR", "direction_tb",
  "direction_bt", "direction_rl", "direction_lr", "direction_td", "LINK_ID", "NUM",
  "BRKT", "STYLE_SEPARATOR", "COLON", "AMP", "SEMI", "COMMA", "MULT", "LINK", "START_LINK",
  "EDGE_TEXT", "-)", "TEXT", "(-", "STADIUMEND", "STADIUMSTART", "SUBROUTINEEND",
  "SUBROUTINESTART", "VERTEX_WITH_PROPS_START", "TAGEND", "CYLINDEREND", "CYLINDERSTART",
  "DOUBLECIRCLEEND", "DOUBLECIRCLESTART", "TRAPEND", "INVTRAPEND", "TRAPSTART", "INVTRAPSTART",
  "TAGSTART", "UP", "SEP", "DOWN", "NODE_STRING", "MINUS", "UNICODE_TEXT", "PIPE",
  "PE", "PS", "SQE", "SQS", "DIAMOND_STOP", "DIAMOND_START", "NEWLINE", "SPACE",
  "EOF",
]
