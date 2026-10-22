///|
test "num rounds to hundredths and drops trailing zeros" {
  inspect(@svg.num(1.5), content="1.5")
  inspect(@svg.num(1.25), content="1.25")
  inspect(@svg.num(1.1), content="1.1")
  inspect(@svg.num(100), content="100")
  inspect(@svg.num(71.9345), content="71.93")
  inspect(@svg.num(25.6), content="25.6")
  inspect(@svg.num(404.6250000001), content="404.63")
  inspect(@svg.num(0.1 + 0.2), content="0.3")
}

///|
test "num rounds the scaled value half up like Math.round" {
  inspect(@svg.num(0.005), content="0.01")
  inspect(@svg.num(2.675), content="2.68")
  inspect(@svg.num(1.005), content="1")
  inspect(@svg.num(0.49999999999999994), content="0.5")
}

///|
test "num writes negatives with a sign" {
  inspect(@svg.num(-71.9345), content="-71.93")
  inspect(@svg.num(-77.1), content="-77.1")
  inspect(@svg.num(-0.015), content="-0.01")
}

///|
test "num writes zero and values that round to zero as 0" {
  inspect(@svg.num(0), content="0")
  inspect(@svg.num(-0.0), content="0")
  inspect(@svg.num(0.004), content="0")
  inspect(@svg.num(-0.004), content="0")
  inspect(@svg.num(-0.005), content="0")
}

///|
test "num falls back to number formatting from 1e9" {
  inspect(@svg.num(999999999.99), content="999999999.99")
  inspect(@svg.num(1.0e9), content="1000000000")
  inspect(@svg.num(-1.0e9), content="-1000000000")
  inspect(@svg.num(1234567890.123), content="1234567890.12")
  inspect(@svg.num(-1234567890.123), content="-1234567890.12")
  inspect(@svg.num(2.0e20), content="200000000000000000000")
  inspect(@svg.num(@double.infinity), content="Infinity")
  inspect(@svg.num(@double.neg_infinity), content="-Infinity")
  inspect(@svg.num(@double.not_a_number), content="NaN")
}

///|
test "esc escapes markup and drops control characters" {
  inspect(
    @svg.esc("<a & \"b\">\u{1}\u{2}x\u{7f}"),
    content="&lt;a &amp; &quot;b&quot;&gt;x",
  )
  inspect(@svg.esc("plain"), content="plain")
  inspect(@svg.esc_text("a &amp; <b>"), content="a &amp; &lt;b&gt;")
}

///|
fn label(text : String, size : Double, base : Int32) -> @text.Label {
  @text.layout_label(
    Some(text),
    false,
    @text.metrics_measurer,
    size,
    4000,
    base~,
  )
}

///|
test "a plain single-span label is one text element" {
  inspect(
    @svg.label_svg(label("ash", 14, 0), 311.284, 155, ""),
    content="<text x=\"311.28\" y=\"159.9\" text-anchor=\"middle\">ash</text>",
  )
}

///|
test "emphasis shared by every span is written on the text element" {
  inspect(
    @svg.label_svg(
      label("a neat chart", 16, @text.STYLE_BOLD),
      165.5,
      20,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
    ),
    content="<text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"165.5\" y=\"25.6\">a neat chart</tspan></text>",
  )
  inspect(
    @svg.label_svg(label("<b>x</b><br><b>y</b>", 14, 0), 50, 50, ""),
    content="<text font-weight=\"var(--_w)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"50\" y=\"44.4\">x</tspan><tspan x=\"50\" y=\"65.4\">y</tspan></text>",
  )
}

///|
test "lines and spans become tspans" {
  inspect(
    @svg.label_svg(label("a<br>b", 14, 0), 303.89, 135, ""),
    content="<text text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"303.89\" y=\"129.4\">a</tspan><tspan x=\"303.89\" y=\"150.4\">b</tspan></text>",
  )
  inspect(
    @svg.label_svg(label("a <b>bold</b> <i>it</i>", 14, 0), 50, 50, ""),
    content="<text text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"50\" y=\"54.9\">a </tspan><tspan font-weight=\"var(--_w)\">bold</tspan><tspan> </tspan><tspan font-style=\"italic\">it</tspan></text>",
  )
  inspect(@svg.label_svg(label("", 14, 0), 50, 50, ""), content="")
}
