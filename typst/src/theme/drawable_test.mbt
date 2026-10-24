///|
fn drawable(svg : String, theme : Map[String, String]) -> String {
  let out = StringBuilder()
  @theme.write_drawable(svg, theme, out)
  out.to_string()
}

///|
fn composed(svg : String, theme : Map[String, String]) -> String {
  @theme.hoist_radii(@theme.mix_colors(@theme.resolve_vars(svg, theme)))
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

///|
/// What is written to it: its length, and the code units at its start and end.
priv struct Tally {
  mut length : Int32
  head : StringBuilder
  mut tail : String
}

///|
impl Logger for Tally with fn write_view(self, view) {
  let text = view.to_owned()
  if self.length < 64 {
    self.head.write_string(@util.slice(text, 0, end=64 - self.length))
  }
  self.length += text.length()
  self.tail = @util.slice(self.tail + @util.slice(text, -64), -64)
}

///|
impl Logger for Tally with fn write_string(self, text) {
  Logger::write_view(self, text.view())
}

///|
impl Logger for Tally with fn write_char(self, c) {
  Logger::write_string(self, c.to_string())
}

///|
#skip("slow: rewrites a style of 270 million code units")
test "a style of tens of millions of entities is rewritten as the three rewrites would rewrite it" {
  let fill = "&amp;".repeat(54000000)
  let svg = "<svg style=\"--_r:var(--pele-radius,4)\"><rect style=\"rx:var(--_r);fill:\{fill}\"/></svg>"
  let out : Tally = { length: 0, head: StringBuilder(), tail: "", }
  @theme.write_drawable(svg, {}, out)
  inspect(
    "\{out.length} \{out.head.to_string()} … \{out.tail}",
    content=(
      #|270000039 <svg><rect rx="4" style="fill:&amp;&amp;&amp;&amp;&amp;&amp;&amp … &amp;&amp;&amp;&amp;&amp;&amp;&amp;&amp;&amp;&amp;&amp;"/></svg>
    ),
  )
}
