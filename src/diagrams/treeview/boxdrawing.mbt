///|
/// The text of a tree view with box-drawing prefixes turned into indentation.
pub(all) struct BoxDrawing {
  text : String
  /// Output line number to original line number, both from 1.
  /// Empty when the text is unchanged.
  line_map : Map[Int32, Int32]
}

///|
/// Whether any of `lines` has a box-drawing character.
pub fn is_box_drawing_format(_lines : Array[String]) -> Bool {
  false
}

///|
/// Rewrites the line numbers in an error message through `line_map`.
pub fn remap_error_lines(
  message : String,
  _line_map : Map[Int32, Int32],
) -> String {
  message
}

///|
/// Turns the `├──`, `└──`, `│` prefixes `tree` prints, and their heavy variants, into the indentation the grammar reads.
/// Text that is not a tree view in box-drawing format is returned as it is.
/// Raises a syntax `PeleError` naming the line of the original text for an empty node or for indentation without box-drawing characters.
pub fn preprocess_box_drawing(
  input : String,
) -> BoxDrawing raise @errors.PeleError {
  raise @errors.pele_error("not implemented \{input.length()}")
}
