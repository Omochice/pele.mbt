///|
fn drawable(svg : String, theme : Map[String, String]) -> String {
  let out = StringBuilder()
  @typst.write_drawable(svg, theme, out)
  out.to_string()
}

///|
fn composed(svg : String, theme : Map[String, String]) -> String {
  @typst.hoist_radii(@typst.mix_colors(@typst.resolve_vars(svg, theme)))
}

///|
test "the drawable svg resolves, mixes and hoists in one walk as the three rewrites do in turn" {
  let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" style=\"--_a:var(--pele-accent,#123);--_r:var(--pele-radius,4);--_m:color-mix(in srgb,var(--_a) 50%,#fff)\">" +
    "<rect x=\"1\" style=\"rx:var(--_r);fill:color-mix(in srgb,var(--_a) 50%,#fff);ry:2\" stroke=\"var(--_m)\"/>" +
    "<g fill=\"var(--pele-unset)\"><text font-weight=\"var(--_w,bold)\">a &lt;b &amp; \"c\"</text></g>" +
    "<path d=\"M0 0\" stroke=\"var(--pele-line,color-mix(in srgb,red,blue))\" style=\"opacity:var(--pele-dim)\"/></svg>"
  let themes : Array[Map[String, String]] = [
    {},
    { "accent": "red", "radius": "8" },
    { "accent": "rgb(1 2 3)", "line": "#abcdef", "dim": "0.5" },
    { "accent": "a\"b", "radius": "x;y" },
  ]
  for theme in themes {
    assert_eq(drawable(svg, theme), composed(svg, theme))
  }
  inspect(
    drawable(svg, { "accent": "red", "radius": "8" }),
    content=(
      #|<svg xmlns="http://www.w3.org/2000/svg"><rect x="1" rx="8" ry="2" style="fill:#ff8080" stroke="#ff8080"/><g><text font-weight="bold">a &lt;b &amp; "c"</text></g><path d="M0 0" stroke="#800080"/></svg>
    ),
  )
}
