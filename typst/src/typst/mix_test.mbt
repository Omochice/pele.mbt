///|
/// What `mix_colors` makes of `value` as the stroke of a text.
/// The expected colors are what Chrome 156 computes each value to, as `color(srgb r g b / a)`, scaled to bytes and rounded half up, as Chrome rounds `rgb()` channels.
fn stroke(value : String) -> String {
  let out = @typst.mix_colors("<text stroke=\"\{value}\">t</text>")
  let start = out.find("stroke=\"").unwrap() + 8
  let end = start + out.view(start_offset=start).find("\"").unwrap()
  out.view(start_offset=start, end_offset=end).to_owned()
}

///|
test "the halo behind a nested cluster title mixes pele's default surface and background" {
  inspect(stroke("color-mix(in srgb,#e6e6e6 50%,#fff)"), content="#f3f3f3")
  inspect(stroke("color-mix(in srgb,#e6e6e6 75%,#fff)"), content="#ececec")
  inspect(stroke("color-mix(in srgb,#e6e6e6 87.5%,#fff)"), content="#e9e9e9")
  inspect(stroke("color-mix(in srgb,#e6e6e6 99.61%,#fff)"), content="#e6e6e6")
}

///|
test "the halo mixes the colors a typst theme writes as six digit hex codes" {
  inspect(stroke("color-mix(in srgb,#45475a 50%,#1e1e2e)"), content="#323344")
}

///|
test "an omitted percentage takes what the other one leaves" {
  inspect(stroke("color-mix(in srgb, red, blue)"), content="#800080")
  inspect(stroke("color-mix(in srgb, red 30%, blue)"), content="#4d00b3")
  inspect(stroke("color-mix(in srgb, red, blue 30%)"), content="#b3004d")
  inspect(stroke("color-mix(in srgb, red 100%, blue)"), content="#ff0000")
}

///|
test "a percentage may come before its color" {
  inspect(stroke("color-mix(in srgb, 30% red, blue)"), content="#4d00b3")
}

///|
test "percentages that sum past 100% are scaled down to it" {
  inspect(stroke("color-mix(in srgb, red 80%, blue 80%)"), content="#800080")
}

///|
test "percentages that sum short of 100% make the mix that much transparent" {
  inspect(stroke("color-mix(in srgb, red 30%, blue 30%)"), content="#80008099")
}

///|
test "percentages that sum to zero mix evenly into a transparent color" {
  inspect(stroke("color-mix(in srgb, red 0%, blue 0%)"), content="#80008000")
}

///|
test "translucent colors are mixed premultiplied by their alpha" {
  inspect(stroke("color-mix(in srgb, #ff000080, blue)"), content="#5500aac0")
  inspect(stroke("color-mix(in srgb, #f008 40%, #0f0c)"), content="#4eb100b1")
  inspect(stroke("color-mix(in srgb, transparent, teal)"), content="#00808080")
}

///|
test "rgb() and rgba() are read in their comma and space forms" {
  inspect(
    stroke("color-mix(in srgb, rgba(255, 0, 0, 0.2) 25%, rgb(0 0 255 / 60%))"),
    content="#1a00e680",
  )
  // Chrome stores the alpha of the comma form as a byte, 128/255, and computes #5500aac0, while CSS Color 4 keeps it 0.5.
  inspect(
    stroke("color-mix(in srgb, rgb(255,0,0,50%), rgba(0 0 255))"),
    content="#5500aabf",
  )
  inspect(stroke("color-mix(in srgb, rgb(1e2 0 0), blue)"), content="#320080")
}

///|
test "a missing rgb() component takes the other color's" {
  inspect(stroke("color-mix(in srgb, rgb(none 0 0), blue)"), content="#000080")
  inspect(
    stroke("color-mix(in srgb, rgb(255 0 0 / none), #0000ff80)"),
    content="#80008080",
  )
  inspect(
    stroke(
      "color-mix(in srgb, rgb(255 0 0 / 0.5) 20%, rgb(none 100 none / 0.25))",
    ),
    content="#ff43004d",
  )
}

///|
test "a component missing from both colors is drawn as zero" {
  inspect(
    stroke("color-mix(in srgb, rgb(none 0 0), rgb(none 0 255))"),
    content="#000080",
  )
  inspect(
    stroke("color-mix(in srgb, rgb(255 0 0 / none), rgb(0 0 255 / none))"),
    content="#80008000",
  )
  inspect(
    stroke(
      "color-mix(in srgb, color-mix(in srgb, rgb(none 0 0), rgb(none 0 0)), rgb(200 0 0))",
    ),
    content="#c80000",
  )
}

///|
test "a percentage may follow a function without a space" {
  inspect(
    stroke("color-mix(in srgb, rgb(255,0,0)50%, blue)"),
    content="#800080",
  )
}

///|
test "rgb() channels out of range are clamped" {
  inspect(
    stroke("color-mix(in srgb, rgb(10%, 20%, 30%), rgb(300 -5 128))"),
    content="#8c1a66",
  )
}

///|
test "names and keywords are read regardless of case" {
  inspect(stroke("color-mix(IN SRGB, TEAL, White)"), content="#80c0c0")
  inspect(stroke("COLOR-MIX(in srgb, red, blue)"), content="#800080")
}

///|
test "a mix of a mix is evaluated" {
  inspect(
    stroke("color-mix(in srgb, color-mix(in srgb, red, blue) 25%, white)"),
    content="#dfbfdf",
  )
}

///|
test "a mix that CSS rejects or that is not in sRGB is left as written" {
  for
    value in [
      "color-mix(in srgb, red)", "color-mix(in srgb, red, blue, lime)", "color-mix(in srgb, red 101%, blue)",
      "color-mix(in srgb, red -1%, blue)", "color-mix(in srgb, red 10% 20%, blue)",
      "color-mix(red, blue)", "color-mix(in oklab, red, blue)", "color-mix(in srgb red, blue)",
      "color-mix(in srgb, rgb(255,0%,0), blue)", "color-mix(in srgb, rgb(255 0 0 0), blue)",
      "color-mix(in srgb, #ff00000, blue)", "color-mix(in srgb, #12345, blue)", "color-mix(in srgb, rgb(255,none,0), blue)",
      "color-mix(in srgb, rgba(255 0 0 , 1), blue)", "color-mix(in srgb, rgb(255 .5 5.), blue)",
      "color-mix(in srgb, rgb(255, 0, 0,), blue)",
    ] {
    assert_eq(stroke(value), value)
  }
}

///|
test "a mix of colors it cannot evaluate is left as written" {
  for
    value in [
      "color-mix(in srgb, hsl(0 100% 50%), blue)", "color-mix(in srgb, currentcolor, blue)",
      "color-mix(in srgb, rgb(calc(1) 0 0), blue)", "color-mix(in srgb, var(--x), blue)",
      "color-mix(in srgb, notacolor, blue)",
    ] {
    assert_eq(stroke(value), value)
  }
}

///|
test "a mix is evaluated in place within a declaration" {
  inspect(
    @typst.mix_colors(
      (
        #|<rect style="fill:red;stroke:color-mix(in srgb,red,blue)" fill="url(#g) color-mix(in srgb,red,blue)"/>
      ),
    ),
    content=(
      #|<rect style="fill:red;stroke:#800080" fill="url(#g) #800080"/>
    ),
  )
}

///|
test "text and attributes that are not CSS are left alone" {
  let svg =
    #|<g data-id="color-mix(in srgb,red,blue)"><title>color-mix(in srgb,red,blue)</title><text class="x">color-mix(in srgb,red,blue)</text></g>
  inspect(@typst.mix_colors(svg), content=svg)
}
