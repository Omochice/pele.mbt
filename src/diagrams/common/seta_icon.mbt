///|
/// Writes the square `icon_svg` draws for the icon `name` to `out`, with the name escaped a piece
/// at a time and the drawing written as a piece of its own.
/// A name of tens of millions of `&` escapes to more than a doubling StringBuilder holds.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_icon(
  out : @svg.Markup,
  name : String,
  x : Double,
  y : Double,
  side : Double,
  icons? : @types.IconResolver,
  drawing~ : String = "",
) -> Unit raise @errors.PeleError {
  let drawing = match icons {
    Some(resolve) => resolve(name).unwrap_or(drawing)
    None => drawing
  }
  out.write("<svg class=\"pele-icon\" data-icon=\"")
  @svg.write_esc_text(out, name)
  out.write(
    "\" x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y)}\" width=\"\{@svg.num(side)}\" height=\"\{@svg.num(side)}\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\">",
  )
  out.write(drawing)
  out.write("</svg>")
}
