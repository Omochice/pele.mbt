///|
/// A square of side `side` at (`x`, `y`) for the icon `name`, in the form labels use, around `drawing`.
pub fn icon_svg(
  name : String,
  x : Double,
  y : Double,
  side : Double,
  drawing~ : String = "",
) -> String {
  // pele asks the host's icon resolver for the drawing inside the square.
  // The plugin has no resolver to ask, so the square holds only what the diagram draws itself, as it does in pele without one.
  "<svg class=\"pele-icon\" data-icon=\"\{@svg.esc_text(name)}\" x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y)}\" width=\"\{@svg.num(side)}\" height=\"\{@svg.num(side)}\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\">\{drawing}</svg>"
}
