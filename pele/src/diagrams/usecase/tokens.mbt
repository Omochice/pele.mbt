// Mermaid's token types, in an order that makes its token categories ranges:
// WORD is USECASE to IDENTIFIER, and LABEL_TEXT is USECASE to LABEL_SYMBOL.

///|
const EOF : Int32 = 0

///|
const USECASE : Int32 = 1

///|
const ACTOR : Int32 = 2

///|
const SYSTEM_BOUNDARY : Int32 = 3

///|
const END : Int32 = 4

///|
const DIRECTION : Int32 = 5

///|
const TD : Int32 = 6

///|
const TB : Int32 = 7

///|
const BT : Int32 = 8

///|
const LR : Int32 = 9

///|
const RL : Int32 = 10

///|
const NOTE : Int32 = 11

///|
const FOR : Int32 = 12

///|
const JSON : Int32 = 13

///|
const CLASS_DEF : Int32 = 14

///|
const CLASS : Int32 = 15

///|
const STYLE : Int32 = 16

///|
const INCLUDE : Int32 = 17

///|
const EXTEND : Int32 = 18

///|
const TRUE : Int32 = 19

///|
const FALSE : Int32 = 20

///|
const IDENTIFIER : Int32 = 21

///|
const NUMBER : Int32 = 22

///|
const AT : Int32 = 23

///|
const COMMA : Int32 = 24

///|
const COLON : Int32 = 25

///|
const HASH_COLOR : Int32 = 26

///|
const CSS_IDENTIFIER : Int32 = 27

///|
const CSS_ESCAPED_COMMA : Int32 = 28

///|
const DASH : Int32 = 29

///|
const DOT : Int32 = 30

///|
const PERCENT : Int32 = 31

///|
const CSS_PUNCTUATION : Int32 = 32

///|
const LABEL_PUNCTUATION : Int32 = 33

///|
const LABEL_SYMBOL : Int32 = 34

///|
const PLAIN_STRING : Int32 = 35

///|
const MARKDOWN_STRING : Int32 = 36

///|
const UNCLOSED_MARKDOWN_STRING : Int32 = 37

///|
const COMMENT : Int32 = 38

///|
const NEWLINE : Int32 = 39

///|
const ACC_DESCR_BLOCK : Int32 = 40

///|
const ACC_TITLE_LINE : Int32 = 41

///|
const ACC_DESCR_LINE : Int32 = 42

///|
const JSON_DECLARATION_START : Int32 = 43

///|
const JSON_OBJECT_LITERAL : Int32 = 44

///|
const UNCLOSED_JSON_OBJECT_LITERAL : Int32 = 45

///|
const GENERALIZATION : Int32 = 46

///|
const DEPENDENCY_ARROW : Int32 = 47

///|
const STEREOTYPE_START : Int32 = 48

///|
const STEREOTYPE_END : Int32 = 49

///|
const STEREOTYPE_TEXT : Int32 = 50

///|
const UNCLOSED_STEREOTYPE_TEXT : Int32 = 51

///|
const CLASS_SEPARATOR : Int32 = 52

///|
const FORWARD_SOLID : Int32 = 53

///|
const BACKWARD_SOLID : Int32 = 54

///|
const FORWARD_CIRCLE : Int32 = 55

///|
const BACKWARD_CIRCLE : Int32 = 56

///|
const FORWARD_CROSS : Int32 = 57

///|
const BACKWARD_CROSS : Int32 = 58

///|
const MARKERLESS_SOLID : Int32 = 59

///|
const METADATA_START : Int32 = 60

///|
const LBRACE : Int32 = 61

///|
const RBRACE : Int32 = 62

///|
const LBRACKET : Int32 = 63

///|
const RBRACKET : Int32 = 64

///|
const LPAREN : Int32 = 65

///|
const RPAREN : Int32 = 66

///|
let token_names : Array[String] = [
  "EOF", "USECASE", "ACTOR", "SYSTEM_BOUNDARY", "END", "DIRECTION", "TD", "TB", "BT",
  "LR", "RL", "NOTE", "FOR", "JSON", "CLASS_DEF", "CLASS", "STYLE", "INCLUDE", "EXTEND",
  "TRUE", "FALSE", "IDENTIFIER", "NUMBER", "AT", "COMMA", "COLON", "HASH_COLOR",
  "CSS_IDENTIFIER", "CSS_ESCAPED_COMMA", "DASH", "DOT", "PERCENT", "CSS_PUNCTUATION",
  "LABEL_PUNCTUATION", "LABEL_SYMBOL", "PLAIN_STRING", "MARKDOWN_STRING", "UNCLOSED_MARKDOWN_STRING",
  "COMMENT", "NEWLINE", "ACC_DESCR_BLOCK", "ACC_TITLE_LINE", "ACC_DESCR_LINE", "JSON_DECLARATION_START",
  "JSON_OBJECT_LITERAL", "UNCLOSED_JSON_OBJECT_LITERAL", "GENERALIZATION", "DEPENDENCY_ARROW",
  "STEREOTYPE_START", "STEREOTYPE_END", "STEREOTYPE_TEXT", "UNCLOSED_STEREOTYPE_TEXT",
  "CLASS_SEPARATOR", "FORWARD_SOLID", "BACKWARD_SOLID", "FORWARD_CIRCLE", "BACKWARD_CIRCLE",
  "FORWARD_CROSS", "BACKWARD_CROSS", "MARKERLESS_SOLID", "METADATA_START", "LBRACE",
  "RBRACE", "LBRACKET", "RBRACKET", "LPAREN", "RPAREN",
]

///|
/// Mermaid's name for a token type.
pub fn token_name(kind : Int32) -> String {
  token_names[kind]
}
