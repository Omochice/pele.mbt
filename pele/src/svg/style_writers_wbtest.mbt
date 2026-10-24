///|
let declaration_samples : Array[Array[String]] = [
  [],
  ["fill:red"],
  ["fill:a&b\"c", "stroke:x&y", "stroke-width:2"],
  ["color:a&b", "font-weight:bold", "font-style:italic", "opacity:0.5"],
  ["stroke:&", "fill:var(--_w)", "rx:3"],
  ["color:x font-weight=", "fill:\u{1}fill:"],
]

///|
test "shapes and markers drawn with style stand-ins are written as they are drawn with the styles" {
  for declarations in declaration_samples {
    let resolved = resolve_style(declarations)
    let css = resolve_raw_style(declarations)
    let slots = css.slots()
    for name, _ in shapes {
      let want = draw_shape(
        name,
        100,
        50,
        " fill=\"var(--_s)\"" + resolved.shape,
        " fill=\"none\"" + resolved.line,
      )
      let out = Markup::new()
      write_styled(
        out,
        draw_shape(
          name,
          100,
          50,
          " fill=\"var(--_s)\"" + slots.shape,
          " fill=\"none\"" + slots.line,
        ),
        css,
      )
      assert_eq(out.to_string(), want)
    }
    let stroke = match resolved.stroke {
      Some(stroke) if stroke != "" => (esc(stroke), STROKE_CSS)
      _ => ("var(--_l)", "var(--_l)")
    }
    for kind in ["arrow_point", "arrow_circle", "arrow_cross", "none"] {
      let out = Markup::new()
      write_styled(out, marker(kind, 1, 2, 0, 1, stroke.1), css)
      assert_eq(out.to_string(), marker(kind, 1, 2, 0, 1, stroke.0))
    }
  }
}

///|
test "text drawn with a style stand-in is written as it is drawn with the style" {
  for declarations in declaration_samples {
    let resolved = resolve_style(declarations)
    let css = resolve_raw_style(declarations)
    let out = Markup::new()
    write_styled(out, "<text class=\"a\"\{css.slots().text}>t</text>", css)
    assert_eq(out.to_string(), "<text class=\"a\"\{resolved.text}>t</text>")
  }
}
