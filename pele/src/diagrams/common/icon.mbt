///|
/// A square of side `side` at (`x`, `y`) for the icon `name`, in the form labels use.
/// It holds what `icons` draws for the name, or `drawing` when the host has nothing for it.
pub fn icon_svg(
  name : String,
  x : Double,
  y : Double,
  side : Double,
  icons? : @types.IconResolver,
  drawing~ : String = "",
) -> String {
  let drawing = match icons {
    Some(resolve) => resolve(name).unwrap_or(drawing)
    None => drawing
  }
  "<svg class=\"pele-icon\" data-icon=\"\{@svg.esc_text(name)}\" x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y)}\" width=\"\{@svg.num(side)}\" height=\"\{@svg.num(side)}\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\">\{drawing}</svg>"
}

///|
/// Writes the square `icon_svg` draws for the icon `name` to `out`, with the name escaped a piece
/// at a time and the drawing written as a piece of its own.
/// A name of tens of millions of `&` escapes to more than a doubling StringBuilder holds.
pub fn write_icon(
  out : @svg.Markup,
  name : String,
  x : Double,
  y : Double,
  side : Double,
  icons? : @types.IconResolver,
  drawing~ : String = "",
) -> Unit {
  let drawing = match icons {
    Some(resolve) => resolve(name).unwrap_or(drawing)
    None => drawing
  }
  out.write("<svg class=\"pele-icon\" data-icon=\"")
  out.write_esc_text(name)
  out.write(
    "\" x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y)}\" width=\"\{@svg.num(side)}\" height=\"\{@svg.num(side)}\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\">",
  )
  out.write(drawing)
  out.write("</svg>")
}
