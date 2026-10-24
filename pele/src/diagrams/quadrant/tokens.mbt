///|
const END : Int32 = 0

///|
const ERROR : Int32 = 1

///|
const NEWLINE : Int32 = 2

///|
const TITLE : Int32 = 3

///|
const TITLE_VALUE : Int32 = 4

///|
const ACC_TITLE : Int32 = 5

///|
const ACC_TITLE_VALUE : Int32 = 6

///|
const ACC_DESCR : Int32 = 7

///|
const ACC_DESCR_VALUE : Int32 = 8

///|
const ACC_DESCR_MULTILINE_VALUE : Int32 = 9

///|
const X_AXIS : Int32 = 10

///|
const Y_AXIS : Int32 = 11

///|
const DELIMITER : Int32 = 12

///|
const QUADRANT_1 : Int32 = 13

///|
const QUADRANT_2 : Int32 = 14

///|
const QUADRANT_3 : Int32 = 15

///|
const QUADRANT_4 : Int32 = 16

///|
const CLASSDEF : Int32 = 17

///|
const MD_STR : Int32 = 18

///|
const STR : Int32 = 19

///|
const CLASS_NAME : Int32 = 20

///|
const POINT_START : Int32 = 21

///|
const POINT_X : Int32 = 22

///|
const POINT_Y : Int32 = 23

///|
const QUADRANT : Int32 = 24

///|
const ALPHA : Int32 = 25

///|
const UNICODE_TEXT : Int32 = 26

///|
const COLON : Int32 = 27

///|
const PLUS : Int32 = 28

///|
const COMMA : Int32 = 29

///|
const EQUALS : Int32 = 30

///|
const MULT : Int32 = 31

///|
const BRKT : Int32 = 32

///|
const UNDERSCORE : Int32 = 33

///|
const DOT : Int32 = 34

///|
const AMP : Int32 = 35

///|
const MINUS : Int32 = 36

///|
const NUM : Int32 = 37

///|
const SPACE : Int32 = 38

///|
const SEMI : Int32 = 39

///|
const PUNCTUATION : Int32 = 40

///|
const EOF : Int32 = 41

///|
/// The names Mermaid's parser gives the tokens in its messages, indexed by token.
let token_names : Array[String] = [
  "$end", "INVALID", "NEWLINE", "title", "title_value", "acc_title", "acc_title_value",
  "acc_descr", "acc_descr_value", "acc_descr_multiline_value", "X-AXIS", "Y-AXIS",
  "AXIS-TEXT-DELIMITER", "QUADRANT_1", "QUADRANT_2", "QUADRANT_3", "QUADRANT_4",
  "CLASSDEF", "MD_STR", "STR", "class_name", "point_start", "point_x", "point_y",
  "QUADRANT", "ALPHA", "UNICODE_TEXT", "COLON", "PLUS", "COMMA", "EQUALS", "MULT",
  "BRKT", "UNDERSCORE", "DOT", "AMP", "MINUS", "NUM", "SPACE", "SEMI", "PUNCTUATION",
  "EOF",
]
