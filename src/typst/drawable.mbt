///|
/// Writes pele's SVG to `out` as typst can draw it under `theme`, as
/// `hoist_radii(mix_colors(resolve_vars(svg, theme)))` makes it.
/// Every rewrite leaves a tag one tag whose values hold no `"`, so the three rewrite each tag in
/// turn during a single walk, and the SVG is never held a second or third time.
pub fn write_drawable(
  svg : String,
  theme : Map[String, String],
  out : &Logger,
) -> Unit {
  let resolver = Resolver::new(svg, theme)
  map_tags(
    svg,
    attributes => {
      hoist_attributes(mix_attributes(resolver.attributes(attributes)))
    },
    out,
  )
}
