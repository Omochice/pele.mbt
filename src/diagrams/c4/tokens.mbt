// Token types are plain numbers because the parser reads meaning from their order, as pele's does:
// shape keywords map to kinds by offset, and ranges select statements.

///|
const END : Int32 = 0

///|
const ERROR : Int32 = 1

///|
const DIRECTION_TB : Int32 = 2

///|
const TITLE : Int32 = 6

///|
const ACC_DESCRIPTION : Int32 = 7

///|
const ACC_TITLE : Int32 = 8

///|
const ACC_TITLE_VALUE : Int32 = 9

///|
const ACC_DESCR : Int32 = 10

///|
const ACC_DESCR_VALUE : Int32 = 11

///|
const ACC_DESCR_MULTILINE_VALUE : Int32 = 12

///|
const NEWLINE : Int32 = 13

///|
const C4_CONTEXT : Int32 = 14

///|
const C4_CONTAINER : Int32 = 15

///|
const C4_COMPONENT : Int32 = 16

///|
const C4_DYNAMIC : Int32 = 17

///|
const C4_DEPLOYMENT : Int32 = 18

///|
const PERSON : Int32 = 19

///|
const PERSON_EXT : Int32 = 20

///|
const SYSTEM : Int32 = 21

///|
const SYSTEM_DB : Int32 = 22

///|
const SYSTEM_QUEUE : Int32 = 23

///|
const SYSTEM_EXT : Int32 = 24

///|
const SYSTEM_EXT_DB : Int32 = 25

///|
const SYSTEM_EXT_QUEUE : Int32 = 26

///|
const CONTAINER : Int32 = 27

///|
const CONTAINER_DB : Int32 = 28

///|
const CONTAINER_QUEUE : Int32 = 29

///|
const CONTAINER_EXT : Int32 = 30

///|
const CONTAINER_EXT_DB : Int32 = 31

///|
const CONTAINER_EXT_QUEUE : Int32 = 32

///|
const COMPONENT : Int32 = 33

///|
const COMPONENT_DB : Int32 = 34

///|
const COMPONENT_QUEUE : Int32 = 35

///|
const COMPONENT_EXT : Int32 = 36

///|
const COMPONENT_EXT_DB : Int32 = 37

///|
const COMPONENT_EXT_QUEUE : Int32 = 38

///|
const ENTERPRISE_BOUNDARY : Int32 = 39

///|
const SYSTEM_BOUNDARY : Int32 = 40

///|
const BOUNDARY : Int32 = 41

///|
const CONTAINER_BOUNDARY : Int32 = 42

///|
const NODE : Int32 = 43

///|
const NODE_L : Int32 = 44

///|
const NODE_R : Int32 = 45

///|
const REL : Int32 = 46

///|
const BIREL : Int32 = 47

///|
const REL_U : Int32 = 48

///|
const REL_D : Int32 = 49

///|
const REL_L : Int32 = 50

///|
const REL_R : Int32 = 51

///|
const REL_B : Int32 = 52

///|
const REL_INDEX : Int32 = 53

///|
const UPDATE_EL_STYLE : Int32 = 54

///|
const UPDATE_REL_STYLE : Int32 = 55

///|
const UPDATE_LAYOUT_CONFIG : Int32 = 56

///|
const EOF_IN_STRUCT : Int32 = 57

///|
const ATTRIBUTE_EMPTY : Int32 = 58

///|
const STR : Int32 = 59

///|
const STR_KEY : Int32 = 60

///|
const STR_VALUE : Int32 = 61

///|
const LBRACE : Int32 = 62

///|
const RBRACE : Int32 = 63

///|
const EOF : Int32 = 64

///|
let token_names : Array[String] = [
  "$end", "INVALID", "direction_tb", "direction_bt", "direction_rl", "direction_lr",
  "title", "accDescription", "acc_title", "acc_title_value", "acc_descr", "acc_descr_value",
  "acc_descr_multiline_value", "NEWLINE", "C4_CONTEXT", "C4_CONTAINER", "C4_COMPONENT",
  "C4_DYNAMIC", "C4_DEPLOYMENT", "PERSON", "PERSON_EXT", "SYSTEM", "SYSTEM_DB", "SYSTEM_QUEUE",
  "SYSTEM_EXT", "SYSTEM_EXT_DB", "SYSTEM_EXT_QUEUE", "CONTAINER", "CONTAINER_DB",
  "CONTAINER_QUEUE", "CONTAINER_EXT", "CONTAINER_EXT_DB", "CONTAINER_EXT_QUEUE",
  "COMPONENT", "COMPONENT_DB", "COMPONENT_QUEUE", "COMPONENT_EXT", "COMPONENT_EXT_DB",
  "COMPONENT_EXT_QUEUE", "ENTERPRISE_BOUNDARY", "SYSTEM_BOUNDARY", "BOUNDARY", "CONTAINER_BOUNDARY",
  "NODE", "NODE_L", "NODE_R", "REL", "BIREL", "REL_U", "REL_D", "REL_L", "REL_R",
  "REL_B", "REL_INDEX", "UPDATE_EL_STYLE", "UPDATE_REL_STYLE", "UPDATE_LAYOUT_CONFIG",
  "EOF_IN_STRUCT", "ATTRIBUTE_EMPTY", "STR", "STR_KEY", "STR_VALUE", "LBRACE", "RBRACE",
  "EOF",
]

///|
let keywords : Map[String, Int32] = {
  "C4Context": C4_CONTEXT,
  "C4Container": C4_CONTAINER,
  "C4Component": C4_COMPONENT,
  "C4Dynamic": C4_DYNAMIC,
  "C4Deployment": C4_DEPLOYMENT,
  "Person": PERSON,
  "Person_Ext": PERSON_EXT,
  "System": SYSTEM,
  "SystemDb": SYSTEM_DB,
  "SystemQueue": SYSTEM_QUEUE,
  "System_Ext": SYSTEM_EXT,
  "SystemDb_Ext": SYSTEM_EXT_DB,
  "SystemQueue_Ext": SYSTEM_EXT_QUEUE,
  "Container": CONTAINER,
  "ContainerDb": CONTAINER_DB,
  "ContainerQueue": CONTAINER_QUEUE,
  "Container_Ext": CONTAINER_EXT,
  "ContainerDb_Ext": CONTAINER_EXT_DB,
  "ContainerQueue_Ext": CONTAINER_EXT_QUEUE,
  "Component": COMPONENT,
  "ComponentDb": COMPONENT_DB,
  "ComponentQueue": COMPONENT_QUEUE,
  "Component_Ext": COMPONENT_EXT,
  "ComponentDb_Ext": COMPONENT_EXT_DB,
  "ComponentQueue_Ext": COMPONENT_EXT_QUEUE,
  "Enterprise_Boundary": ENTERPRISE_BOUNDARY,
  "System_Boundary": SYSTEM_BOUNDARY,
  "Boundary": BOUNDARY,
  "Container_Boundary": CONTAINER_BOUNDARY,
  "Deployment_Node": NODE,
  "Node": NODE,
  "Node_L": NODE_L,
  "Node_R": NODE_R,
  "Rel": REL,
  "BiRel": BIREL,
  "Rel_Up": REL_U,
  "Rel_U": REL_U,
  "Rel_Down": REL_D,
  "Rel_D": REL_D,
  "Rel_Left": REL_L,
  "Rel_L": REL_L,
  "Rel_Right": REL_R,
  "Rel_R": REL_R,
  "Rel_Back": REL_B,
  "RelIndex": REL_INDEX,
  "UpdateElementStyle": UPDATE_EL_STYLE,
  "UpdateRelStyle": UPDATE_REL_STYLE,
  "UpdateLayoutConfig": UPDATE_LAYOUT_CONFIG,
}
