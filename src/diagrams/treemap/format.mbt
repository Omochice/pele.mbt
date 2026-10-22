///|
/// Makes the function that writes a treemap's values for a d3-format style specifier.
/// Only `$`, `,`, a precision, and the types `f`, `%`, `d`, `e`, or none are understood.
/// A specifier that is not understood formats like `,`.
pub fn formatter(spec : String) -> (Double) -> String {
  ignore(spec)
  _ => ""
}
