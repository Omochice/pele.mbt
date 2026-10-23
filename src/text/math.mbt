///|
/// Markup the host typeset, drawn in a nested `<svg>` or in a `<foreignObject>`.
pub(all) enum MathBody {
  Svg(String)
  Html(String)
}

///|
/// Typeset math that passed pele's check, with the size of the box it is drawn in.
pub(all) struct MathMarkup {
  body : MathBody
  width : Double
  height : Double
}

///|
/// Runs `run` with `math` as the typesetter that labels ask, and with nothing typeset yet.
pub fn[T] with_math(
  math : ((String, Double) -> Json?)?,
  run : () -> T raise?,
) -> T raise? {
  ignore(math)
  run()
}

///|
/// Whether labels are laid out with a typesetter.
pub fn math_active() -> Bool {
  false
}

///|
/// The host's markup for `tex` at font size `size`, or `None` when there is no typesetter or the
/// markup fails pele's check.
pub fn typeset(tex : String, size : Double) -> MathMarkup? {
  ignore(tex)
  ignore(size)
  None
}

///|
/// Runs `run` with no typesetter, as Mermaid draws diagram titles as text.
pub fn[T] without_math(run : () -> T raise?) -> T raise? {
  run()
}
