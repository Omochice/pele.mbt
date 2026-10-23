///|
/// A typesetter that knows a few TeX strings, at any size.
fn tex_markup(tex : String, _ : Double) -> Json? {
  match tex {
    "tall" => Some({ "svg": "<path/>", "width": 20, "height": 40 })
    "x^2" => Some({ "svg": "<path/>", "width": 20, "height": 12 })
    "y &amp; z" => Some({ "html": "<i>y</i>", "width": 30, "height": 10 })
    "y & z" => Some({ "html": "<i>y&z</i>", "width": 31, "height": 10 })
    "w" => Some({ "svg": "<g/>", "width": 50, "height": 30 })
    _ => None
  }
}

///|
fn show_label(label : @text.Label) -> String {
  let lines = label.lines.map(line => {
    line
    .map(span => {
      let text = match span.math {
        Some(math) => "[math \{math.width}x\{math.height}]"
        None => span.text.escape()
      }
      "\{text}/\{span.style}/\{span.width}"
    })
    .join(" ")
  })
  let heights = match label.heights {
    Some(heights) => " heights=[\{heights.map(h => h.to_string()).join(", ")}]"
    None => ""
  }
  "\{lines.join(" | ")} widths=[\{label.widths.map(w => w.to_string()).join(", ")}] width=\{label.width} height=\{label.height} size=\{label.size} line=\{label.line_height}\{heights}"
}

///|
fn math_layout(
  raw : String,
  size : Double,
  max_width : Double,
  markdown~ : Bool = false,
) -> @text.Label {
  @text.with_math(Some(tex_markup), () => {
    @text.layout_label(
      Some(raw),
      markdown,
      @text.metrics_measurer,
      size,
      max_width,
    )
  })
}

///|
test "typeset math is a span as wide as its markup" {
  inspect(
    show_label(math_layout("$$x^2$$", 16, 4000)),
    content="[math 20x12]/0/20 widths=[20] width=20 height=24 size=16 line=24",
  )
  inspect(
    show_label(math_layout("a $$x^2$$ b", 16, 4000)),
    content="\"a \"/0/13.344 [math 20x12]/0/20 \" b\"/0/13.344 widths=[46.688] width=46.688 height=24 size=16 line=24",
  )
  inspect(
    show_label(math_layout("$$x^2$$$$tall$$", 16, 4000)),
    content="[math 20x12]/0/20 [math 20x40]/0/20 widths=[40] width=40 height=44 size=16 line=24 heights=[44]",
  )
}

///|
test "TeX is decoded before it is typeset" {
  inspect(
    show_label(math_layout("$$y &amp; z$$", 16, 4000)),
    content="[math 31x10]/0/31 widths=[31] width=31 height=24 size=16 line=24",
  )
}

///|
test "math the host does not typeset stays text" {
  inspect(
    show_label(math_layout("$$nope$$ x", 16, 4000)),
    content="\"$$nope$$ x\"/0/83.616 widths=[83.616] width=83.616 height=24 size=16 line=24",
  )
  inspect(
    show_label(math_layout("$$$x^2$$", 16, 4000)),
    content="\"$$$x^2$$\"/0/68.88 widths=[68.88] width=68.88 height=24 size=16 line=24",
  )
  inspect(
    show_label(math_layout("p $$ $$ q", 16, 4000)),
    content="\"p $$ $$ q\"/0/66.72 widths=[66.72] width=66.72 height=24 size=16 line=24",
  )
}

///|
test "a label holding a placeholder character is not typeset" {
  inspect(
    show_label(math_layout("\u{e000} $$x^2$$", 16, 4000)),
    content="\"\u{e000} $$x^2$$\"/0/73.712 widths=[73.712] width=73.712 height=24 size=16 line=24",
  )
}

///|
test "math takes the emphasis around it" {
  inspect(
    show_label(math_layout("<b>$$x^2$$</b> c", 14, 4000)),
    content="[math 20x12]/1/20 \" c\"/0/10.892 widths=[30.892] width=30.892 height=21 size=14 line=21",
  )
  inspect(
    show_label(math_layout("**$$x^2$$** _a_", 16, 4000, markdown=true)),
    content="[math 20x12]/1/20 \" \"/0/4.448 \"a\"/2/8.896 widths=[33.344] width=33.344 height=24 size=16 line=24",
  )
}

///|
test "tall math makes its line taller" {
  let label = math_layout("one $$tall$$<br>two", 16, 4000)
  inspect(
    show_label(label),
    content="\"one \"/0/31.136 [math 20x40]/0/20 | \"two\"/0/24.896 widths=[51.135999999999996, 24.896] width=51.135999999999996 height=68 size=16 line=24 heights=[44, 24]",
  )
  inspect(
    "\{@text.line_middle(label, 0)}, \{@text.line_middle(label, 1)}",
    content="22, 56",
  )
  inspect(
    label.lines.map(line => @text.has_math(line).to_string()).join(","),
    content="true,false",
  )
  inspect(
    show_label(@text.label_line(label, 0)),
    content="\"one \"/0/31.136 [math 20x40]/0/20 widths=[51.135999999999996] width=51.135999999999996 height=44 size=16 line=24 heights=[44]",
  )
  inspect(
    show_label(@text.label_line(label, 1)),
    content="\"two\"/0/24.896 widths=[24.896] width=24.896 height=24 size=16 line=24",
  )
}

///|
test "math is kept whole when a line wraps" {
  let label = math_layout("aaa bbb $$w$$ ccc ddd", 16, 60)
  inspect(
    show_label(label),
    content="\"aaa bbb\"/0/57.824 | [math 50x30]/0/50 | \"ccc ddd\"/0/55.136 widths=[57.824, 50, 55.136] width=57.824 height=82 size=16 line=24 heights=[24, 34, 24]",
  )
  inspect(
    "\{@text.line_middle(label, 0)}, \{@text.line_middle(label, 1)}, \{@text.line_middle(label, 2)}",
    content="12, 41, 70",
  )
}

///|
test "a label without math has no line heights" {
  let label = @text.layout_label(
    Some("one<br>two"),
    false,
    @text.metrics_measurer,
    16,
    4000,
  )
  inspect(
    "\{@text.line_middle(label, 0)}, \{@text.line_middle(label, 1)}",
    content="12, 36",
  )
  inspect(@text.with_heights(label).heights is None, content="true")
}

///|
test "line heights are dropped once no line needs them" {
  let label = math_layout("one $$tall$$<br>two", 16, 4000)
  let rest = { ..label, lines: [label.lines[1]], widths: [label.widths[1]], }
  inspect(
    show_label(@text.with_heights(rest)),
    content="\"two\"/0/24.896 widths=[24.896] width=51.135999999999996 height=24 size=16 line=24",
  )
}
