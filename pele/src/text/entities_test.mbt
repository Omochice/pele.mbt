///|
test "HTML entities become characters" {
  inspect(@text.decode_entities("a &amp; b"), content="a & b")
  inspect(@text.decode_entities("&#35;"), content="#")
  inspect(@text.decode_entities("&#x41;&#X42;"), content="AB")
  inspect(
    @text.decode_entities("&lt;&gt;&quot;&nbsp;&euro;"),
    content="<>\"\u{a0}\u{20ac}",
  )
  inspect(@text.decode_entities("x &#38;amp; y"), content="x &amp; y")
}

///|
test "unknown or invalid entities are kept" {
  inspect(@text.decode_entities("&unknown;"), content="&unknown;")
  inspect(@text.decode_entities("&#0;"), content="&#0;")
  inspect(@text.decode_entities("&#xD800;"), content="&#xD800;")
  inspect(@text.decode_entities("&#1114112;"), content="&#1114112;")
  inspect(@text.decode_entities("&amp"), content="&amp")
}

///|
test "Mermaid's entity placeholders are decoded" {
  inspect(
    @text.decode_entities("\u{fb02}\u{b0}\u{b0}35\u{b6}\u{df}"),
    content="#",
  )
  inspect(@text.decode_entities("\u{fb02}\u{b0}quot\u{b6}\u{df}"), content="\"")
}
