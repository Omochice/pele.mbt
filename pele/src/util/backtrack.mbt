///|
/// The slots of V8's regexp backtracking stack a match may fill: 64 MiB of four-byte slots, less the 32 slots V8 keeps as slack.
/// A pattern that repeats a group with more than one way through it, such as `(?:a|bc)*`, takes a few slots for each repetition and gives none back until the match ends.
/// Once a match fills this many, V8 throws a RangeError, which pele reports as a diagram nested too deeply.
/// Each pattern's slots per repetition and the few it takes besides are measured under node 24.21, whose irregexp is what pele runs on.
pub const BACKTRACK_STACK_SLOTS : Int64 = 16777184

///|
/// Whether a match that fills `slots` of V8's backtracking stack throws, see `BACKTRACK_STACK_SLOTS`.
pub fn backtrack_stack_overflows(slots : Int64) -> Bool {
  slots >= BACKTRACK_STACK_SLOTS
}
