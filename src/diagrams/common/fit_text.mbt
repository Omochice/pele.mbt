///|
/// One line of text fitted into a width, with the font size it is drawn at.
pub(all) struct Fitted {
  text : String
  size : Double
  width : Double
}

///|
/// Fits one line of text into `max`: first by shrinking the font down to `min`, then by cutting the text and adding an ellipsis.
/// Returns `None` when not even one character fits.
pub fn fit_text(
  text : String,
  max : Double,
  size : Double,
  min : Double,
  measurer : @text.TextMeasurer,
  style~ : Int32 = 0,
) -> Fitted? {
  ignore((text, max, size, min, measurer, style))
  None
}
