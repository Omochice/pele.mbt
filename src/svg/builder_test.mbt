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
    written(out => @svg.write_label(out, label("ash", 14, 0), 311.284, 155, "")),
    content="<text x=\"311.28\" y=\"159.9\" text-anchor=\"middle\">ash</text>",
  )
}

///|
test "emphasis shared by every span is written on the text element" {
  inspect(
    written(out => {
      @svg.write_label(
        out,
        label("a neat chart", 16, @text.STYLE_BOLD),
        165.5,
        20,
        " class=\"pele-title\" font-weight=\"var(--_tw)\"",
      )
    }),
    content="<text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"165.5\" y=\"25.6\">a neat chart</tspan></text>",
  )
  inspect(
    written(out => {
      @svg.write_label(out, label("<b>x</b><br><b>y</b>", 14, 0), 50, 50, "")
    }),
    content="<text font-weight=\"var(--_w)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"50\" y=\"44.4\">x</tspan><tspan x=\"50\" y=\"65.4\">y</tspan></text>",
  )
}

///|
test "lines and spans become tspans" {
  inspect(
    written(out => {
      @svg.write_label(out, label("a<br>b", 14, 0), 303.89, 135, "")
    }),
    content="<text text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"303.89\" y=\"129.4\">a</tspan><tspan x=\"303.89\" y=\"150.4\">b</tspan></text>",
  )
  inspect(
    written(out => {
      @svg.write_label(out, label("a <b>bold</b> <i>it</i>", 14, 0), 50, 50, "")
    }),
    content="<text text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"50\" y=\"54.9\">a </tspan><tspan font-weight=\"var(--_w)\">bold</tspan><tspan> </tspan><tspan font-style=\"italic\">it</tspan></text>",
  )
  inspect(
    written(out => @svg.write_label(out, label("", 14, 0), 50, 50, "")),
    content="",
  )
}

///|
/// A host that has only `fa:fa-car`.
fn car_icons(name : String) -> String? {
  if name == "fa:fa-car" {
    Some("<path/>")
  } else {
    None
  }
}

///|
/// `text` laid out at 16px while the host's icons are known.
fn icon_label(text : String, max_width : Double) -> @text.Label {
  @text.with_icons(Some(car_icons), () => {
    @text.layout_label(Some(text), false, @text.metrics_measurer, 16, max_width)
  })
}

///|
test "an icon span is a square drawn by the resolver after the text" {
  inspect(
    written(out => {
      @svg.write_label(
        out,
        icon_label("fa:fa-car Cars", 4000),
        0,
        0,
        " class=\"x\"",
        icons=car_icons,
      )
    }),
    content="<text class=\"x\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"-9.11\" y=\"5.6\" text-anchor=\"start\"> Cars</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"-29.11\" y=\"-8.8\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path/></svg>",
  )
  inspect(
    written(out => {
      @svg.write_label(
        out,
        icon_label("fa:fa-car", 4000),
        0,
        0,
        " class=\"x\"",
        icons=car_icons,
      )
    }),
    content="<text class=\"x\" text-anchor=\"middle\" xml:space=\"preserve\"></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"-10\" y=\"-8.8\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path/></svg>",
  )
}

///|
test "only lines holding an icon place their spans one by one" {
  inspect(
    written(out => {
      @svg.write_label(
        out,
        icon_label("Go fa:fa-car fast and far away", 60),
        0,
        0,
        " class=\"x\"",
        icons=car_icons,
      )
    }),
    content="<text class=\"x\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"-22.9\" y=\"-30.4\" text-anchor=\"start\">Go </tspan><tspan x=\"0\" y=\"-6.4\">fast and</tspan><tspan x=\"0\" y=\"17.6\">far</tspan><tspan x=\"0\" y=\"41.6\">away</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"2.9\" y=\"-44.8\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path/></svg>",
  )
}

///|
test "an icon span drawn without a resolver is an empty square" {
  inspect(
    written(out => {
      @svg.write_label(out, icon_label("fa:fa-car", 4000), 0, 0, "")
    }),
    content="<text text-anchor=\"middle\" xml:space=\"preserve\"></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"-10\" y=\"-8.8\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"></svg>",
  )
}
