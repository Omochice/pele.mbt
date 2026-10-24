///|
pub const T_END : Int32 = 0

///|
pub const T_ERROR : Int32 = 1

///|
pub const T_TITLE : Int32 = 2

///|
pub const T_ACC_TITLE : Int32 = 3

///|
pub const T_ACC_TITLE_VALUE : Int32 = 4

///|
pub const T_ACC_DESCR : Int32 = 5

///|
pub const T_ACC_DESCR_VALUE : Int32 = 6

///|
pub const T_ACC_DESCR_MULTILINE_VALUE : Int32 = 7

///|
pub const T_DIRECTION_TB : Int32 = 8

///|
pub const T_DIRECTION_BT : Int32 = 9

///|
pub const T_DIRECTION_RL : Int32 = 10

///|
pub const T_DIRECTION_LR : Int32 = 11

///|
pub const T_NEWLINE : Int32 = 12

///|
pub const T_EOF : Int32 = 13

///|
pub const T_RD : Int32 = 14

///|
pub const T_STRUCT_START : Int32 = 15

///|
pub const T_STRUCT_STOP : Int32 = 16

///|
pub const T_STYLE_SEPARATOR : Int32 = 17

///|
pub const T_COLONSEP : Int32 = 18

///|
pub const T_ID : Int32 = 19

///|
pub const T_TEXT : Int32 = 20

///|
pub const T_RISK : Int32 = 21

///|
pub const T_VERIFYMTHD : Int32 = 22

///|
pub const T_REQUIREMENT : Int32 = 23

///|
pub const T_FUNCTIONAL_REQUIREMENT : Int32 = 24

///|
pub const T_INTERFACE_REQUIREMENT : Int32 = 25

///|
pub const T_PERFORMANCE_REQUIREMENT : Int32 = 26

///|
pub const T_PHYSICAL_REQUIREMENT : Int32 = 27

///|
pub const T_DESIGN_CONSTRAINT : Int32 = 28

///|
pub const T_LOW_RISK : Int32 = 29

///|
pub const T_MED_RISK : Int32 = 30

///|
pub const T_HIGH_RISK : Int32 = 31

///|
pub const T_VERIFY_ANALYSIS : Int32 = 32

///|
pub const T_VERIFY_DEMONSTRATION : Int32 = 33

///|
pub const T_VERIFY_INSPECTION : Int32 = 34

///|
pub const T_VERIFY_TEST : Int32 = 35

///|
pub const T_ELEMENT : Int32 = 36

///|
pub const T_CONTAINS : Int32 = 37

///|
pub const T_COPIES : Int32 = 38

///|
pub const T_DERIVES : Int32 = 39

///|
pub const T_SATISFIES : Int32 = 40

///|
pub const T_VERIFIES : Int32 = 41

///|
pub const T_REFINES : Int32 = 42

///|
pub const T_TRACES : Int32 = 43

///|
pub const T_TYPE : Int32 = 44

///|
pub const T_DOCREF : Int32 = 45

///|
pub const T_STYLE : Int32 = 46

///|
pub const T_CLASSDEF : Int32 = 47

///|
pub const T_CLASS : Int32 = 48

///|
pub const T_ALPHA : Int32 = 49

///|
pub const T_COLON : Int32 = 50

///|
pub const T_SEMICOLON : Int32 = 51

///|
pub const T_PERCENT : Int32 = 52

///|
pub const T_MINUS : Int32 = 53

///|
pub const T_BRKT : Int32 = 54

///|
pub const T_END_ARROW_L : Int32 = 55

///|
pub const T_END_ARROW_R : Int32 = 56

///|
pub const T_LINE : Int32 = 57

///|
pub const T_QSTRING : Int32 = 58

///|
pub const T_UNQSTRING : Int32 = 59

///|
pub const T_COMMA : Int32 = 60

///|
/// The names Jison gives the token types, indexed by type.
pub let token_names : Array[String] = [
  "$end", "INVALID", "title", "acc_title", "acc_title_value", "acc_descr", "acc_descr_value",
  "acc_descr_multiline_value", "direction_tb", "direction_bt", "direction_rl", "direction_lr",
  "NEWLINE", "EOF", "RD", "STRUCT_START", "STRUCT_STOP", "STYLE_SEPARATOR", "COLONSEP",
  "ID", "TEXT", "RISK", "VERIFYMTHD", "REQUIREMENT", "FUNCTIONAL_REQUIREMENT", "INTERFACE_REQUIREMENT",
  "PERFORMANCE_REQUIREMENT", "PHYSICAL_REQUIREMENT", "DESIGN_CONSTRAINT", "LOW_RISK",
  "MED_RISK", "HIGH_RISK", "VERIFY_ANALYSIS", "VERIFY_DEMONSTRATION", "VERIFY_INSPECTION",
  "VERIFY_TEST", "ELEMENT", "CONTAINS", "COPIES", "DERIVES", "SATISFIES", "VERIFIES",
  "REFINES", "TRACES", "TYPE", "DOCREF", "STYLE", "CLASSDEF", "CLASS", "ALPHA", "COLON",
  "SEMICOLON", "PERCENT", "MINUS", "BRKT", "END_ARROW_L", "END_ARROW_R", "LINE",
  "qString", "unqString", "COMMA",
]
