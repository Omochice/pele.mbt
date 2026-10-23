// The message kinds, numbered as in Mermaid.

///|
pub const SOLID : Int32 = 0

///|
pub const DOTTED : Int32 = 1

///|
pub const NOTE : Int32 = 2

///|
pub const SOLID_CROSS : Int32 = 3

///|
pub const DOTTED_CROSS : Int32 = 4

///|
pub const SOLID_OPEN : Int32 = 5

///|
pub const DOTTED_OPEN : Int32 = 6

///|
pub const LOOP_START : Int32 = 10

///|
pub const LOOP_END : Int32 = 11

///|
pub const ALT_START : Int32 = 12

///|
pub const ALT_ELSE : Int32 = 13

///|
pub const ALT_END : Int32 = 14

///|
pub const OPT_START : Int32 = 15

///|
pub const OPT_END : Int32 = 16

///|
pub const ACTIVE_START : Int32 = 17

///|
pub const ACTIVE_END : Int32 = 18

///|
pub const PAR_START : Int32 = 19

///|
pub const PAR_AND : Int32 = 20

///|
pub const PAR_END : Int32 = 21

///|
pub const RECT_START : Int32 = 22

///|
pub const RECT_END : Int32 = 23

///|
pub const SOLID_POINT : Int32 = 24

///|
pub const DOTTED_POINT : Int32 = 25

///|
pub const AUTONUMBER : Int32 = 26

///|
pub const CRITICAL_START : Int32 = 27

///|
pub const CRITICAL_OPTION : Int32 = 28

///|
pub const CRITICAL_END : Int32 = 29

///|
pub const BREAK_START : Int32 = 30

///|
pub const BREAK_END : Int32 = 31

///|
pub const PAR_OVER_START : Int32 = 32

///|
pub const BIDIRECTIONAL_SOLID : Int32 = 33

///|
pub const BIDIRECTIONAL_DOTTED : Int32 = 34

///|
pub const SOLID_TOP : Int32 = 41

///|
pub const SOLID_BOTTOM : Int32 = 42

///|
pub const STICK_TOP : Int32 = 43

///|
pub const STICK_BOTTOM : Int32 = 44

///|
pub const SOLID_ARROW_TOP_REVERSE : Int32 = 45

///|
pub const SOLID_ARROW_BOTTOM_REVERSE : Int32 = 46

///|
pub const STICK_ARROW_TOP_REVERSE : Int32 = 47

///|
pub const STICK_ARROW_BOTTOM_REVERSE : Int32 = 48

///|
pub const SOLID_TOP_DOTTED : Int32 = 51

///|
pub const SOLID_BOTTOM_DOTTED : Int32 = 52

///|
pub const STICK_TOP_DOTTED : Int32 = 53

///|
pub const STICK_BOTTOM_DOTTED : Int32 = 54

///|
pub const SOLID_ARROW_TOP_REVERSE_DOTTED : Int32 = 55

///|
pub const SOLID_ARROW_BOTTOM_REVERSE_DOTTED : Int32 = 56

///|
pub const STICK_ARROW_TOP_REVERSE_DOTTED : Int32 = 57

///|
pub const STICK_ARROW_BOTTOM_REVERSE_DOTTED : Int32 = 58

///|
pub const CENTRAL_CONNECTION : Int32 = 59

///|
pub const CENTRAL_CONNECTION_REVERSE : Int32 = 60

///|
pub const CENTRAL_CONNECTION_DUAL : Int32 = 61

///|
/// A note to the left of its participant.
pub const LEFTOF : Int32 = 0

///|
/// A note to the right of its participant.
pub const RIGHTOF : Int32 = 1

///|
/// A note over one participant or across two.
pub const OVER : Int32 = 2

///|
/// Text with the wrap its `wrap:` or `nowrap:` prefix asks for, if any.
pub(all) struct SeqText {
  text : String
  wrap : Bool?
}

///|
/// A box line split into its fill and its title.
pub(all) struct SeqBoxData {
  text : String?
  color : String
  wrap : Bool?
}

///|
/// A group of participants drawn inside one box.
pub(all) struct SeqBox {
  name : String?
  wrap : Bool
  fill : String
  actor_keys : Array[String]
}

///|
/// A participant.
/// `details` holds the id of the page element a `details` statement names, which pele has no page to read from.
pub(all) struct SeqActor {
  mut box : SeqBox?
  name : String
  description : String
  wrap : Bool
  prev_actor : String?
  mut next_actor : String?
  links : Map[String, Json]
  properties : Map[String, Json]
  mut details : String?
  kind : String
}

///|
/// What an `autonumber` statement sets.
pub(all) struct SeqNumbering {
  start : Double?
  step : Double?
  visible : Bool
}

///|
/// One entry of the message list: a message, a note, an activation, a block boundary, or a numbering switch.
/// The numbering switch carries `numbering` and an empty `message`.
pub(all) struct SeqMessage {
  id : String
  from : String?
  to : String?
  message : String
  numbering : SeqNumbering?
  wrap : Bool
  kind : Int32
  activate : Bool
  placement : Int32?
  central_connection : Int32
}

///|
/// A note, over one or two participants.
/// `actors` holds one id for a note beside its participant, and two for a note over, which repeat the id for one participant.
pub(all) struct SeqNote {
  actors : Array[String]
  placement : Int32
  message : String
  wrap : Bool
}

///|
/// One statement as Mermaid's grammar hands it to the model.
pub(all) enum SeqStatement {
  SequenceIndex(start~ : Double?, step~ : Double?, visible~ : Bool)
  AddParticipant(
    actor~ : String,
    draw~ : String?,
    description~ : SeqText?,
    config~ : String?
  )
  CreateParticipant(
    actor~ : String,
    draw~ : String?,
    description~ : SeqText?,
    config~ : String?
  )
  DestroyParticipant(String)
  ActiveStart(String)
  ActiveEnd(String)
  CentralConnectionStart(String)
  CentralConnectionReverseStart(String)
  AddNote(actors~ : Array[String], placement~ : Int32, text~ : SeqText)
  AddLinks(String, SeqText)
  AddALink(String, SeqText)
  AddProperties(String, SeqText)
  AddDetails(String, SeqText)
  AddMessage(
    from~ : String,
    to~ : String,
    signal_type~ : Int32,
    msg~ : SeqText,
    activate~ : Bool,
    central_connection~ : Int32?
  )
  BoxStart(SeqBoxData)
  BoxEnd
  BlockStart(Int32, SeqText)
  BlockEnd(Int32)
}
