///|
/// A fill inside `box` styled by `declarations`, which a raw style of the same declarations must read
/// the same way.
fn styled_fill(box : Array[Double], declarations : Array[String]) -> @svg.Fill {
  let fill = @svg.Fill::new(box, @svg.resolve_style(declarations).shape)
  let raw = @svg.Fill::raw(box, @svg.resolve_raw_style(declarations).shape)
  if raw.ink != fill.ink || raw.color != fill.color {
    abort("Fill::raw differs for \{declarations.join(",")}")
  }
  fill
}

///|
/// What `over_fills` gives, with `undefined` for an edge off every fill.
fn over(
  d : String,
  tips : Array[Double],
  fills : Array[@svg.Fill],
  line~ : Array[String] = [],
) -> String {
  let picked = @svg.over_fills(
    d,
    tips,
    fills,
    line=@svg.resolve_style(line).line,
  )
  let raw = @svg.raw_over_fills(
    d,
    tips,
    fills,
    css=@svg.resolve_raw_style(line).line,
  )
  if raw != picked {
    abort("raw_over_fills differs for \{d}")
  }
  match picked {
    Some(color) => "\"\{color}\""
    None => "undefined"
  }
}

///|
test "over_fills inks an edge that one fill holds and cases one that crosses a border" {
  let nested = [
    styled_fill([-20, -20, 100, 100], ["fill:white"]),
    styled_fill([10, 0, 50, 50], ["fill:navy"]),
  ]
  let cases : Array[(String, Array[Double])] = [
    // A marker alone reaches into the nested fill.
    ("M0,10L8,10", [15, 10]),
    ("M0,10L8,10", [9, 10]),
    // A path that starts on a border and stays inside is held by that fill.
    ("M-20,10L8,10", [9, 10]),
    ("M-30,10L8,10", [9, 10]),
    ("M20,10L30,10", []),
    ("M20,10L30,10M40,10L45,10", []),
    ("M200,10L300,10", []),
    ("M200,10L300,10", [50, 50]),
    ("M-20,-20L100,-20", []),
  ]
  inspect(
    cases.map(c => "\{c.0} \{over(c.0, c.1, nested)}").join("\n"),
    content=(
      #|M0,10L8,10 ""
      #|M0,10L8,10 "var(--pele-fg-on-light,#1f1f1f)"
      #|M-20,10L8,10 "var(--pele-fg-on-light,#1f1f1f)"
      #|M-30,10L8,10 ""
      #|M20,10L30,10 "var(--pele-fg-on-dark,#fff)"
      #|M20,10L30,10M40,10L45,10 "var(--pele-fg-on-dark,#fff)"
      #|M200,10L300,10 undefined
      #|M200,10L300,10 ""
      #|M-20,-20L100,-20 undefined
    ),
  )
  inspect(over("M0,0L1,1", [], []), content="undefined")
  inspect(
    over("M10,10L20,20", [], [styled_fill([0, 0, 100, 100], ["fill:url-ish"])]),
    content="\"\"",
  )
}

///|
test "over_fills cases an edge whose line style sets its own stroke" {
  let nested = [
    styled_fill([-20, -20, 100, 100], ["fill:white"]),
    styled_fill([10, 0, 50, 50], ["fill:navy"]),
  ]
  inspect(
    [["stroke:red"], ["stroke-width:3"], ["stroke-dasharray:x&stroke:1"], []]
    .map(line => over("M0,10L8,10", [9, 10], nested, line~))
    .join("\n"),
    content=(
      #|""
      #|"var(--pele-fg-on-light,#1f1f1f)"
      #|""
      #|"var(--pele-fg-on-light,#1f1f1f)"
    ),
  )
}

///|
test "hollow_on fills hollow markers with the fill's color" {
  let marks = "<circle class=\"pele-marker\" r=\"3\" fill=\"var(--_bg)\"/><path fill=\"var(--_l)\"/><path fill=\"var(--_bg)\"/>"
  inspect(
    [["fill:black"], ["fill: #fee "], ["fill:url-ish"], ["fill:a&b"]]
    .map(decls => @svg.hollow_on(marks, styled_fill([0, 0, 1, 1], decls)))
    .join("\n"),
    content=(
      #|<circle class="pele-marker" r="3" fill="black"/><path fill="var(--_l)"/><path fill="black"/>
      #|<circle class="pele-marker" r="3" fill="#fee"/><path fill="var(--_l)"/><path fill="#fee"/>
      #|<circle class="pele-marker" r="3" fill="url-ish"/><path fill="var(--_l)"/><path fill="url-ish"/>
      #|<circle class="pele-marker" r="3" fill="a&amp"/><path fill="var(--_l)"/><path fill="a&amp"/>
    ),
  )
}
