///|
test "style_contains finds in the raw CSS what searching the escaped attribute finds" {
  let declarations = [
    ["fill:red"],
    ["stroke:red", "fill:blue"],
    ["stroke:a&fill:b"],
    ["stroke:a<fill:b"],
    ["stroke:a\"fill:b"],
    ["stroke:a\u{1}fill:b"],
    ["stroke:x;", "fill:y"],
    ["color:red"],
    [],
  ]
  for list in declarations {
    let escaped = @svg.resolve_style(list)
    let raw = @svg.resolve_raw_style(list)
    for needle in ["\"fill:", ";fill:", "fill", "&amp;", " style=\"", ""] {
      assert_eq(
        @svg.style_contains(raw.shape, needle),
        escaped.shape.contains(needle),
      )
      assert_eq(
        @svg.style_contains(raw.text, needle),
        escaped.text.contains(needle),
      )
    }
  }
}

///|
test "the styled shapes and markers write what the string ones write under the escaped style" {
  let declarations = [[], ["fill:a&b", "stroke:c"], ["stroke:x", "rx:3"]]
  for list in declarations {
    let style = @svg.resolve_style(list)
    let css = @svg.resolve_raw_style(list)
    for shape in ["rect", "rounded", "cyl", "person", "diamond", "circle"] {
      assert_eq(
        written(out => {
          @svg.write_shape_styled(
            out,
            shape,
            40,
            30,
            " fill=\"var(--_s)\"",
            css.shape,
            " stroke=\"x\"",
            css.line,
          )
        }),
        @svg.draw_shape(
          shape,
          40,
          30,
          " fill=\"var(--_s)\"" + style.shape,
          " stroke=\"x\"" + style.line,
        ),
      )
    }
    assert_eq(
      written(out => @svg.write_rounded_style(out, css.shape)),
      @svg.rounded(style.shape),
    )
    assert_eq(written(out => @svg.write_style(out, css.text)), style.text)
  }
  for kind in ["arrow_point", "arrow_circle", "arrow_cross", "none"] {
    assert_eq(
      written(out => @svg.write_marker_esc(out, kind, 1, 2, 0, 1, "a&\"b")),
      @svg.marker(kind, 1, 2, 0, 1, @svg.esc("a&\"b")),
    )
  }
}
