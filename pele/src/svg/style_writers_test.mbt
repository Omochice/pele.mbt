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
test "a style split as raw CSS sets a fill where its escaped attribute does" {
  let declarations = [
    ["fill:red"],
    ["stroke:red", "fill:blue"],
    ["stroke:a&fill:b"],
    ["fill-opacity:0.2"],
    ["stroke:red"],
    [],
  ]
  for list in declarations {
    assert_eq(
      @svg.sets_raw_fill(@svg.resolve_raw_style(list).shape),
      @svg.sets_fill(@svg.resolve_style(list).shape),
    )
  }
}

///|
test "the style attributes write what the string ones write under the escaped style" {
  let declarations = [[], ["fill:a&b", "stroke:c"], ["stroke:x", "rx:3"]]
  for list in declarations {
    let style = @svg.resolve_style(list)
    let css = @svg.resolve_raw_style(list)
    assert_eq(
      written(out => @svg.write_rounded_style(out, css.shape)),
      @svg.rounded(style.shape),
    )
    assert_eq(written(out => @svg.write_style(out, css.text)), style.text)
  }
}

///|
test "styles split as raw CSS write the attributes resolve_style makes" {
  let samples : Array[Array[String]] = [
    [],
    ["fill:red", "stroke:blue !important", "color:green"],
    ["fill:a&b\"c", "stroke-width:2", "font-weight:bold", "font-style:italic"],
    ["font-size:12px", "url(x)", "fill:<x>", "opacity:0.5"],
    ["FILL : red", "stroke:"],
  ]
  for declarations in samples {
    let want = @svg.resolve_style(declarations)
    let got = @svg.resolve_raw_style(declarations)
    assert_eq(written(out => @svg.write_style(out, got.shape)), want.shape)
    assert_eq(written(out => @svg.write_style(out, got.line)), want.line)
    assert_eq(written(out => @svg.write_style(out, got.text)), want.text)
    assert_eq(got.stroke, want.stroke)
    assert_eq(got.bold, want.bold)
    assert_eq(got.italic, want.italic)
    assert_eq(got.font_size, want.font_size)
  }
}
