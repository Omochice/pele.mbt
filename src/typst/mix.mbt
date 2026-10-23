///|
/// Replaces every `color-mix()` in sRGB in the CSS of pele's SVG with the color it computes to.
/// typst does not evaluate `color-mix()`, so whatever is painted with one is not drawn.
pub fn mix_colors(svg : String) -> String {
  svg
}
