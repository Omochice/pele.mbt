///|
/// Draws a diagram with room to spare, and tightly instead when that does not fit the width the
/// host has and the tight drawing is narrower.
pub fn tighten(
  options : @types.RenderOptions,
  draw : (Bool) -> @types.Rendered,
) -> @types.Rendered {
  let loose = draw(false)
  guard options.max_width is Some(available) &&
    available > 0 &&
    loose.width > available else {
    return loose
  }
  let tight = draw(true)
  if tight.width < loose.width {
    tight
  } else {
    loose
  }
}
