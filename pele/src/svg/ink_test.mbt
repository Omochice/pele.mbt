///|
const ON_LIGHT : String = "var(--pele-fg-on-light,#1f1f1f)"

///|
const ON_DARK : String = "var(--pele-fg-on-dark,#fff)"

///|
/// The label color `ink` picks for the declarations, which `raw_ink` must pick from the same declarations kept raw.
fn ink_for(declarations : Array[String]) -> String? {
  let style = @svg.resolve_style(declarations)
  let raw = @svg.resolve_raw_style(declarations)
  let picked = @svg.ink(style.shape, text=style.text)
  assert_eq(@svg.raw_ink(raw.shape, text=raw.text), picked) catch {
    _ => abort("raw_ink differs for \{declarations.join(",")}")
  }
  picked
}

///|
fn ink_of(fill : String) -> String {
  ink_for(["fill:" + fill]).unwrap_or("none")
}

///|
let named : Array[(String, String)] = [
  ("aliceblue", "f0f8ff"),
  ("antiquewhite", "faebd7"),
  ("aqua", "00ffff"),
  ("aquamarine", "7fffd4"),
  ("azure", "f0ffff"),
  ("beige", "f5f5dc"),
  ("bisque", "ffe4c4"),
  ("black", "000000"),
  ("blanchedalmond", "ffebcd"),
  ("blue", "0000ff"),
  ("blueviolet", "8a2be2"),
  ("brown", "a52a2a"),
  ("burlywood", "deb887"),
  ("cadetblue", "5f9ea0"),
  ("chartreuse", "7fff00"),
  ("chocolate", "d2691e"),
  ("coral", "ff7f50"),
  ("cornflowerblue", "6495ed"),
  ("cornsilk", "fff8dc"),
  ("crimson", "dc143c"),
  ("cyan", "00ffff"),
  ("darkblue", "00008b"),
  ("darkcyan", "008b8b"),
  ("darkgoldenrod", "b8860b"),
  ("darkgray", "a9a9a9"),
  ("darkgreen", "006400"),
  ("darkgrey", "a9a9a9"),
  ("darkkhaki", "bdb76b"),
  ("darkmagenta", "8b008b"),
  ("darkolivegreen", "556b2f"),
  ("darkorange", "ff8c00"),
  ("darkorchid", "9932cc"),
  ("darkred", "8b0000"),
  ("darksalmon", "e9967a"),
  ("darkseagreen", "8fbc8f"),
  ("darkslateblue", "483d8b"),
  ("darkslategray", "2f4f4f"),
  ("darkslategrey", "2f4f4f"),
  ("darkturquoise", "00ced1"),
  ("darkviolet", "9400d3"),
  ("deeppink", "ff1493"),
  ("deepskyblue", "00bfff"),
  ("dimgray", "696969"),
  ("dimgrey", "696969"),
  ("dodgerblue", "1e90ff"),
  ("firebrick", "b22222"),
  ("floralwhite", "fffaf0"),
  ("forestgreen", "228b22"),
  ("fuchsia", "ff00ff"),
  ("gainsboro", "dcdcdc"),
  ("ghostwhite", "f8f8ff"),
  ("gold", "ffd700"),
  ("goldenrod", "daa520"),
  ("gray", "808080"),
  ("green", "008000"),
  ("greenyellow", "adff2f"),
  ("grey", "808080"),
  ("honeydew", "f0fff0"),
  ("hotpink", "ff69b4"),
  ("indianred", "cd5c5c"),
  ("indigo", "4b0082"),
  ("ivory", "fffff0"),
  ("khaki", "f0e68c"),
  ("lavender", "e6e6fa"),
  ("lavenderblush", "fff0f5"),
  ("lawngreen", "7cfc00"),
  ("lemonchiffon", "fffacd"),
  ("lightblue", "add8e6"),
  ("lightcoral", "f08080"),
  ("lightcyan", "e0ffff"),
  ("lightgoldenrodyellow", "fafad2"),
  ("lightgray", "d3d3d3"),
  ("lightgreen", "90ee90"),
  ("lightgrey", "d3d3d3"),
  ("lightpink", "ffb6c1"),
  ("lightsalmon", "ffa07a"),
  ("lightseagreen", "20b2aa"),
  ("lightskyblue", "87cefa"),
  ("lightslategray", "778899"),
  ("lightslategrey", "778899"),
  ("lightsteelblue", "b0c4de"),
  ("lightyellow", "ffffe0"),
  ("lime", "00ff00"),
  ("limegreen", "32cd32"),
  ("linen", "faf0e6"),
  ("magenta", "ff00ff"),
  ("maroon", "800000"),
  ("mediumaquamarine", "66cdaa"),
  ("mediumblue", "0000cd"),
  ("mediumorchid", "ba55d3"),
  ("mediumpurple", "9370db"),
  ("mediumseagreen", "3cb371"),
  ("mediumslateblue", "7b68ee"),
  ("mediumspringgreen", "00fa9a"),
  ("mediumturquoise", "48d1cc"),
  ("mediumvioletred", "c71585"),
  ("midnightblue", "191970"),
  ("mintcream", "f5fffa"),
  ("mistyrose", "ffe4e1"),
  ("moccasin", "ffe4b5"),
  ("navajowhite", "ffdead"),
  ("navy", "000080"),
  ("oldlace", "fdf5e6"),
  ("olive", "808000"),
  ("olivedrab", "6b8e23"),
  ("orange", "ffa500"),
  ("orangered", "ff4500"),
  ("orchid", "da70d6"),
  ("palegoldenrod", "eee8aa"),
  ("palegreen", "98fb98"),
  ("paleturquoise", "afeeee"),
  ("palevioletred", "db7093"),
  ("papayawhip", "ffefd5"),
  ("peachpuff", "ffdab9"),
  ("peru", "cd853f"),
  ("pink", "ffc0cb"),
  ("plum", "dda0dd"),
  ("powderblue", "b0e0e6"),
  ("purple", "800080"),
  ("rebeccapurple", "663399"),
  ("red", "ff0000"),
  ("rosybrown", "bc8f8f"),
  ("royalblue", "4169e1"),
  ("saddlebrown", "8b4513"),
  ("salmon", "fa8072"),
  ("sandybrown", "f4a460"),
  ("seagreen", "2e8b57"),
  ("seashell", "fff5ee"),
  ("sienna", "a0522d"),
  ("silver", "c0c0c0"),
  ("skyblue", "87ceeb"),
  ("slateblue", "6a5acd"),
  ("slategray", "708090"),
  ("slategrey", "708090"),
  ("snow", "fffafa"),
  ("springgreen", "00ff7f"),
  ("steelblue", "4682b4"),
  ("tan", "d2b48c"),
  ("teal", "008080"),
  ("thistle", "d8bfd8"),
  ("tomato", "ff6347"),
  ("turquoise", "40e0d0"),
  ("violet", "ee82ee"),
  ("wheat", "f5deb3"),
  ("white", "ffffff"),
  ("whitesmoke", "f5f5f5"),
  ("yellow", "ffff00"),
  ("yellowgreen", "9acd32"),
]

///|
test "reads hex fills" {
  assert_eq(ink_of("#fff"), ON_LIGHT)
  assert_eq(ink_of("#BBDEFB"), ON_LIGHT)
  assert_eq(ink_of("#000"), ON_DARK)
  assert_eq(ink_of("#1F3A5F"), ON_DARK)
  assert_eq(ink_of("#000c"), ON_DARK)
  assert_eq(ink_of("#ffffff80"), ON_LIGHT)
}

///|
test "picks the ink with the higher contrast near the middle" {
  assert_eq(ink_of("#f00"), ON_LIGHT)
  assert_eq(ink_of("#808000"), ON_DARK)
}

///|
test "reads rgb() in comma and space syntax" {
  assert_eq(ink_of("rgb(191, 223, 255)"), ON_LIGHT)
  assert_eq(ink_of("rgba(0,0,0,0.6)"), ON_DARK)
  assert_eq(ink_of("RGB(100%, 100%, 100%)"), ON_LIGHT)
  assert_eq(ink_of("rgb(0% 0% 0% / .9)"), ON_DARK)
  assert_eq(ink_of("rgba(255 255 255 / 75%)"), ON_LIGHT)
  assert_eq(ink_of("rgb(none 0 0)"), ON_DARK)
}

///|
test "reads hsl()" {
  assert_eq(ink_of("hsl(210, 100%, 87%)"), ON_LIGHT)
  assert_eq(ink_of("hsl(0 0% 10%)"), ON_DARK)
  assert_eq(ink_of("hsla(120deg, 50%, 20%, 0.8)"), ON_DARK)
  assert_eq(ink_of("hsl(0.5turn 100% 90%)"), ON_LIGHT)
  assert_eq(ink_of("hsl(-120, 100%, 30%)"), ON_DARK)
  assert_eq(ink_of("hsl(0 0 95)"), ON_LIGHT)
  assert_eq(ink_of("hsl(none 0% 0%)"), ON_DARK)
}

///|
test "reads all 148 named colors, in any case" {
  assert_eq(named.length(), 148)
  for entry in named {
    let (name, hex) = entry
    let expected = ink_of("#" + hex)
    assert_eq(ink_of(name), expected, msg=name)
    assert_eq(ink_of(name.to_upper()), expected, msg=name)
  }
}

///|
test "leaves labels alone on fills it cannot read" {
  for
    fill in [
      "var(--x)", "currentColor", "none", "transparent", "blu", "#ggg", "#12345",
      "rgb(1,2)", "rgb(1, 2 3)", "rgb(1 2 3 / 4 / 5)", "rgb(1, 2, 3 / 1)", "rgb(1 2 3 4)",
      "hsl(10%, 50%, 50%)", "rgb(10deg, 2, 3)", "rgb(0%,0,0)", "hsl(0,0,0)", "rgb(0. 0 0)",
      "rgb(none,0,0)",
    ] {
    assert_eq(ink_for(["fill:" + fill]), None, msg=fill)
  }
  assert_eq(ink_for(["stroke:#000"]), None)
}

///|
test "leaves labels alone on fills under half opaque" {
  assert_eq(ink_for(["fill:#0007"]), None)
  assert_eq(ink_for(["fill:#0000007f"]), None)
  assert_eq(ink_for(["fill:rgb(191 223 255 / 40%)"]), None)
  assert_eq(ink_for(["fill:#000", "fill-opacity:0.4"]), None)
  assert_eq(ink_for(["fill:#000", "fill-opacity:60%"]), Some(ON_DARK))
  assert_eq(ink_for(["fill:#0009", "fill-opacity:0.8"]), None)
  assert_eq(ink_for(["fill:#000", "fill-opacity:calc(0.1)"]), None)
  assert_eq(ink_for(["fill:#000", "fill-opacity:var(--fade)"]), None)
  assert_eq(ink_for(["fill:#000", "opacity:0.4"]), None)
  assert_eq(ink_for(["fill:#000", "opacity:0.8", "fill-opacity:0.6"]), None)
  assert_eq(ink_for(["fill:#000", "opacity:0.8"]), Some(ON_DARK))
}

///|
test "leaves a color the style sets" {
  assert_eq(ink_for(["fill:#fff", "color:#fff"]), None)
  assert_eq(ink_for(["fill:white"]), Some(ON_LIGHT))
}

///|
test "reads raw CSS as the attribute it is escaped into" {
  // Escaping ends an `&` with a `;`, which reads as the start of a declaration.
  assert_eq(ink_for(["stroke:x&fill:black"]), Some(ON_DARK))
  assert_eq(ink_for(["fill:#fff&", "stroke:red"]), None)
  assert_eq(ink_for(["fill:#000", "stroke:\"&fill-opacity:0.1"]), None)
  assert_eq(ink_for(["fill:#000", "stroke:\"&opacity:0.1"]), None)
  assert_eq(ink_for(["fill:#000", "stroke:a&opacity:0.9", "opacity:0.5"]), None)
  assert_eq(ink_for(["fill:#000", "stroke-opacity:0.1"]), Some(ON_DARK))
  assert_eq(ink_for(["fill:#000", "color:a&b"]), None)
}

///|
test "reads numbers and units in any case, as pele's pattern does" {
  assert_eq(ink_of("BLAC\u{212a}"), ON_DARK)
  assert_eq(ink_of("greygrey"), "none")
  assert_eq(ink_of("hsl(1e400, 50%, 50%)"), "none")
  assert_eq(ink_of("rgb(1e2 1e2 1e2)"), ON_DARK)
  assert_eq(ink_of("hsl(3.14159rad 50% 50%)"), ON_LIGHT)
  assert_eq(ink_of("hsl(200GRAD 50% 60%)"), ON_LIGHT)
  assert_eq(ink_of("rgb( 1 , 2 , 3 )"), ON_DARK)
  assert_eq(ink_of("rgb(255,255,255,)"), "none")
  assert_eq(ink_of("rgb(255 255 255/)"), "none")
  assert_eq(ink_for(["fill:#000", "fill-opacity:1E0"]), Some(ON_DARK))
  assert_eq(ink_for(["fill:#000", "fill-opacity:+.6e0"]), Some(ON_DARK))
  assert_eq(ink_of("#808080"), ON_LIGHT)
  assert_eq(ink_of("#777"), ON_DARK)
}

///|
test "a label's fill attribute falls back when no fill is read" {
  let dark = @svg.resolve_style(["fill:navy"])
  let plain = @svg.resolve_style(["stroke:red"])
  inspect(
    @svg.ink_fill(dark, fallback="var(--_m)"),
    content=" fill=\"var(--pele-fg-on-dark,#fff)\"",
  )
  inspect(
    @svg.ink_fill(plain, fallback="var(--_m)"),
    content=" fill=\"var(--_m)\"",
  )
  inspect(@svg.ink_fill(plain), content="")
  inspect(
    @svg.raw_ink_fill(@svg.resolve_raw_style(["fill:#BBDEFB"])),
    content=" fill=\"var(--pele-fg-on-light,#1f1f1f)\"",
  )
}

///|
test "picks the same color for a style asked again, after others push it out" {
  let dark = @svg.resolve_style(["fill:black"])
  assert_eq(@svg.ink(dark.shape), Some(ON_DARK))
  for i in 0..<1100 {
    ignore(@svg.ink(@svg.resolve_style(["fill:#\{100000 + i}"]).shape))
  }
  assert_eq(@svg.ink(dark.shape), Some(ON_DARK))
  assert_eq(@svg.ink(dark.shape, text=" style=\"fill:red;\""), None)
}

///|
test "keeps the colors picked for raw CSS apart from those for attributes" {
  // Raw CSS escapes its `&` into `&amp;`, whose `;` starts a declaration that the same text read as an attribute lacks.
  let shape = "stroke:x&fill:black"
  assert_eq(@svg.raw_ink(shape), Some(ON_DARK))
  assert_eq(@svg.ink(shape), None)
}
