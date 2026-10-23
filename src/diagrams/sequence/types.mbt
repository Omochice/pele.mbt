// The message kinds, numbered as in Mermaid.

///|
/// A solid line with an arrowhead, `->>`.
pub const SOLID : Int32 = 0

///|
/// A dotted line with an arrowhead, `-->>`.
pub const DOTTED : Int32 = 1

///|
/// A note.
pub const NOTE : Int32 = 2

///|
/// A solid line that ends in a cross, `-x`.
pub const SOLID_CROSS : Int32 = 3

///|
/// A dotted line that ends in a cross, `--x`.
pub const DOTTED_CROSS : Int32 = 4

///|
/// A solid line without a head, `->`.
pub const SOLID_OPEN : Int32 = 5

///|
/// A dotted line without a head, `-->`.
pub const DOTTED_OPEN : Int32 = 6

///|
/// The start of a `loop` block.
pub const LOOP_START : Int32 = 10

///|
/// The end of a `loop` block.
pub const LOOP_END : Int32 = 11

///|
/// The start of an `alt` block.
pub const ALT_START : Int32 = 12

///|
/// An `else` section of an `alt` block.
pub const ALT_ELSE : Int32 = 13

///|
/// The end of an `alt` block.
pub const ALT_END : Int32 = 14

///|
/// The start of an `opt` block.
pub const OPT_START : Int32 = 15

///|
/// The end of an `opt` block.
pub const OPT_END : Int32 = 16

///|
/// The activation of a participant.
pub const ACTIVE_START : Int32 = 17

///|
/// The end of the latest activation of a participant.
pub const ACTIVE_END : Int32 = 18

///|
/// The start of a `par` block.
pub const PAR_START : Int32 = 19

///|
/// An `and` section of a `par` block.
pub const PAR_AND : Int32 = 20

///|
/// The end of a `par` or `par_over` block.
pub const PAR_END : Int32 = 21

///|
/// The start of a shaded `rect` block.
pub const RECT_START : Int32 = 22

///|
/// The end of a shaded `rect` block.
pub const RECT_END : Int32 = 23

///|
/// A solid line with an open arrowhead, `-)`.
pub const SOLID_POINT : Int32 = 24

///|
/// A dotted line with an open arrowhead, `--)`.
pub const DOTTED_POINT : Int32 = 25

///|
/// An `autonumber` statement.
pub const AUTONUMBER : Int32 = 26

///|
/// The start of a `critical` block.
pub const CRITICAL_START : Int32 = 27

///|
/// An `option` section of a `critical` block.
pub const CRITICAL_OPTION : Int32 = 28

///|
/// The end of a `critical` block.
pub const CRITICAL_END : Int32 = 29

///|
/// The start of a `break` block.
pub const BREAK_START : Int32 = 30

///|
/// The end of a `break` block.
pub const BREAK_END : Int32 = 31

///|
/// The start of a `par_over` block.
pub const PAR_OVER_START : Int32 = 32

///|
/// A solid line with an arrowhead at each end, `<<->>`.
pub const BIDIRECTIONAL_SOLID : Int32 = 33

///|
/// A dotted line with an arrowhead at each end, `<<-->>`.
pub const BIDIRECTIONAL_DOTTED : Int32 = 34

///|
/// A solid line with a solid half head above it, `-|\`.
pub const SOLID_TOP : Int32 = 41

///|
/// A solid line with a solid half head below it, `-|/`.
pub const SOLID_BOTTOM : Int32 = 42

///|
/// A solid line with a stick half head above it, `-\\`.
pub const STICK_TOP : Int32 = 43

///|
/// A solid line with a stick half head below it, `-//`.
pub const STICK_BOTTOM : Int32 = 44

///|
/// A solid line with a solid half head above it at the sender, `/|-`.
pub const SOLID_ARROW_TOP_REVERSE : Int32 = 45

///|
/// A solid line with a solid half head below it at the sender, `\|-`.
pub const SOLID_ARROW_BOTTOM_REVERSE : Int32 = 46

///|
/// A solid line with a stick half head above it at the sender, `//-`.
pub const STICK_ARROW_TOP_REVERSE : Int32 = 47

///|
/// A solid line with a stick half head below it at the sender, `\\-`.
pub const STICK_ARROW_BOTTOM_REVERSE : Int32 = 48

///|
/// A dotted line with a solid half head above it, `--|\`.
pub const SOLID_TOP_DOTTED : Int32 = 51

///|
/// A dotted line with a solid half head below it, `--|/`.
pub const SOLID_BOTTOM_DOTTED : Int32 = 52

///|
/// A dotted line with a stick half head above it, `--\\`.
pub const STICK_TOP_DOTTED : Int32 = 53

///|
/// A dotted line with a stick half head below it, `--//`.
pub const STICK_BOTTOM_DOTTED : Int32 = 54

///|
/// A dotted line with a solid half head above it at the sender, `/|--`.
pub const SOLID_ARROW_TOP_REVERSE_DOTTED : Int32 = 55

///|
/// A dotted line with a solid half head below it at the sender, `\|--`.
pub const SOLID_ARROW_BOTTOM_REVERSE_DOTTED : Int32 = 56

///|
/// A dotted line with a stick half head above it at the sender, `//--`.
pub const STICK_ARROW_TOP_REVERSE_DOTTED : Int32 = 57

///|
/// A dotted line with a stick half head below it at the sender, `\\--`.
pub const STICK_ARROW_BOTTOM_REVERSE_DOTTED : Int32 = 58

///|
/// A circle on the lifeline of the receiver, `->>()`.
pub const CENTRAL_CONNECTION : Int32 = 59

///|
/// A circle on the lifeline of the sender, `()->>`.
pub const CENTRAL_CONNECTION_REVERSE : Int32 = 60

///|
/// A circle on the lifelines of both participants, `()->>()`.
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
