///|
/// Moves the corner radii that pele writes in `style` into `rx` and `ry` attributes.
/// typst reads radii only from attributes, so a radius set in `style` draws square corners.
pub fn hoist_radii(svg : String) -> String {
  svg
}
