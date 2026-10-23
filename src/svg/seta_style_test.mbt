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
