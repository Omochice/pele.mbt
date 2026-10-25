///|
fn math_label_svg(raw : String, size : Double, attrs : String) -> String {
  let math = (tex : String, _ : Double) => {
    match tex {
      "tall" => Some(({ "svg": "<path/>", "width": 20, "height": 40 } : Json))
      "x^2" => Some({ "svg": "<path/>", "width": 20, "height": 12 })
      "y & z" => Some({ "html": "<i>y&z</i>", "width": 31, "height": 10 })
      _ => None
    }
  }
  @text.with_math(Some(math), () => {
    let label = @text.layout_label(
      Some(raw),
      false,
      @text.metrics_measurer,
      size,
      4000,
    )
    written(out => @svg.write_label(out, label, 10, 20, attrs))
  })
}

///|
test "svg math is drawn in a nested svg box centered on its line" {
  inspect(
    math_label_svg("$$x^2$$", 16, " class=\"pele-label\""),
    content="<text class=\"pele-label\" text-anchor=\"middle\" xml:space=\"preserve\"></text><svg class=\"pele-math\" x=\"0\" y=\"14\" width=\"20\" height=\"12\" overflow=\"visible\"><path/></svg>",
  )
  inspect(
    math_label_svg("a $$x^2$$ <b>b</b>", 16, ""),
    content="<text text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"-13.78\" y=\"25.6\" text-anchor=\"start\">a </tspan><tspan x=\"19.56\" y=\"25.6\" text-anchor=\"start\"> </tspan><tspan x=\"24.01\" y=\"25.6\" text-anchor=\"start\" font-weight=\"var(--_w)\">b</tspan></text><svg class=\"pele-math\" x=\"-0.44\" y=\"14\" width=\"20\" height=\"12\" overflow=\"visible\"><path/></svg>",
  )
}

///|
test "lines are placed by their own heights" {
  inspect(
    math_label_svg("one $$tall$$<br>two", 16, ""),
    content=(
      #|<text text-anchor="middle" xml:space="preserve"><tspan x="-15.57" y="15.1" text-anchor="start">one </tspan><tspan x="10" y="47.6">two</tspan></text><svg class="pele-math" x="15.57" y="-10.5" width="20" height="40" overflow="visible"><path/></svg>
    ),
  )
}

///|
test "html math is drawn in a foreignObject at the label's font size" {
  inspect(
    math_label_svg("$$y & z$$", 14, ""),
    content="<text text-anchor=\"middle\" xml:space=\"preserve\"></text><foreignObject class=\"pele-math\" x=\"-5.5\" y=\"15\" width=\"31\" height=\"10\" overflow=\"visible\"><div xmlns=\"http://www.w3.org/1999/xhtml\" style=\"display:flex;align-items:center;justify-content:center;width:100%;height:100%;font-size:14px;line-height:normal;white-space:nowrap\"><i>y&z</i></div></foreignObject>",
  )
}

///|
test "math under an outline is covered by a patch of the stroke color" {
  inspect(
    math_label_svg("$$x^2$$ c", 16, " fill=\"none\" stroke=\"red\""),
    content="<text fill=\"none\" stroke=\"red\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"13.78\" y=\"25.6\" text-anchor=\"start\"> c</tspan></text><rect x=\"-6.22\" y=\"14\" width=\"20\" height=\"12\" rx=\"2\" fill=\"red\"/>",
  )
  inspect(
    math_label_svg("$$x^2$$ c", 16, " fill=\"none\""),
    content="<text fill=\"none\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"13.78\" y=\"25.6\" text-anchor=\"start\"> c</tspan></text><rect x=\"-6.22\" y=\"14\" width=\"20\" height=\"12\" rx=\"2\" fill=\"none\"/>",
  )
}

///|
test "math takes only the color and opacity of the text" {
  inspect(
    math_label_svg(
      "$$x^2$$ c", 16, " fill=\"#123\" style=\"opacity: 0.5 ;fill: blue \"",
    ),
    content="<text fill=\"#123\" style=\"opacity: 0.5 ;fill: blue \" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"13.78\" y=\"25.6\" text-anchor=\"start\"> c</tspan></text><svg class=\"pele-math\" x=\"-6.22\" y=\"14\" width=\"20\" height=\"12\" overflow=\"visible\" color=\"blue\" opacity=\"0.5\"><path/></svg>",
  )
  inspect(
    math_label_svg("$$x^2$$ c", 16, " fill=\"#123\" style=\"fill:;stroke:red\""),
    content="<text fill=\"#123\" style=\"fill:;stroke:red\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"13.78\" y=\"25.6\" text-anchor=\"start\"> c</tspan></text><svg class=\"pele-math\" x=\"-6.22\" y=\"14\" width=\"20\" height=\"12\" overflow=\"visible\"><path/></svg>",
  )
  inspect(
    math_label_svg(
      "$$x^2$$ c", 16, " style=\"x-fill:red;font-size:3px\" fill=\"green\"",
    ),
    content="<text style=\"x-fill:red;font-size:3px\" fill=\"green\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"13.78\" y=\"25.6\" text-anchor=\"start\"> c</tspan></text><svg class=\"pele-math\" x=\"-6.22\" y=\"14\" width=\"20\" height=\"12\" overflow=\"visible\" color=\"green\"><path/></svg>",
  )
  inspect(
    math_label_svg("<b>$$x^2$$ c</b>", 16, " fill=\"#123\""),
    content="<text fill=\"#123\" font-weight=\"var(--_w)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"13.33\" y=\"25.6\" text-anchor=\"start\"> c</tspan></text><svg class=\"pele-math\" x=\"-6.67\" y=\"14\" width=\"20\" height=\"12\" overflow=\"visible\" color=\"#123\"><path/></svg>",
  )
}
