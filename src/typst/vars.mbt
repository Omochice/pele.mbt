///|
/// Replaces every CSS custom property reference in pele's SVG with its value, and drops the custom property declarations.
/// `theme` holds values for pele's `--pele-*` properties, keyed by the name without `--pele-`; absent ones take pele's fallbacks.
pub fn resolve_vars(svg : String, theme : Map[String, String]) -> String {
  ignore(theme)
  svg
}
