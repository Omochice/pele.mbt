///|
fn layout(
  raw : String,
  size : Double,
  max_width : Double,
  markdown~ : Bool = false,
  base~ : Int32 = 0,
) -> String {
  let label = @text.layout_label(
    Some(raw),
    markdown,
    @text.metrics_measurer,
    size,
    max_width,
    base~,
  )
  let lines = label.lines.map(line => {
    line
    .map(span => {
      let icon = match span.icon {
        Some(name) => "@" + name
        None => ""
      }
      "\{span.text.escape()}\{icon}/\{span.style}/\{span.width}"
    })
    .join(" ")
  })
  "\{lines.join(" | ")} widths=[\{label.widths.map(w => w.to_string()).join(", ")}] width=\{label.width} height=\{label.height} size=\{label.size} line=\{label.line_height}"
}

///|
test "plain text is one measured line, trimmed" {
  inspect(
    layout("ash", 14, 4000),
    content="\"ash\"/0/22.568 widths=[22.568] width=22.568 height=21 size=14 line=21",
  )
  inspect(
    layout("  Key elements  ", 16, 4000, base=@text.STYLE_BOLD),
    content="\"Key elements\"/1/103.152 widths=[103.152] width=103.152 height=24 size=16 line=24",
  )
}

///|
test "an empty label has no lines" {
  inspect(
    layout("", 16, 4000),
    content=" widths=[] width=0 height=0 size=0 line=0",
  )
}

///|
test "inline HTML sets emphasis and entities are decoded" {
  inspect(
    layout("a <b>bold</b> &amp; x", 16, 4000, base=@text.STYLE_BOLD),
    content="\"a bold & x\"/1/76.464 widths=[76.464] width=76.464 height=24 size=16 line=24",
  )
  inspect(
    layout("a <i>it</i> <B>b</B>", 16, 4000),
    content="\"a \"/0/13.344 \"it\"/2/8 \" \"/0/4.448 \"b\"/1/9.776 widths=[35.568] width=35.568 height=24 size=16 line=24",
  )
  inspect(
    layout("__proto__", 14, 4000),
    content="\"__proto__\"/0/63.042 widths=[63.042] width=63.042 height=21 size=14 line=21",
  )
  inspect(
    layout("x \u{fb02}\u{b0}\u{b0}35\u{b6}\u{df} y", 14, 4000),
    content="\"x # y\"/0/29.568 widths=[29.568] width=29.568 height=21 size=14 line=21",
  )
}

///|
test "sub and sup shift text by the innermost tag open, across line breaks" {
  inspect(
    layout("H<sub>2</sub>O x<SUP>2</SUP>", 16, 4000),
    content=(
      #|"H"/0/11.552 "2"/8/7.413333333333334 "O x"/0/24.896 "2"/16/7.413333333333334 widths=[51.27466666666667] width=51.27466666666667 height=24 size=16 line=24
    ),
  )
  inspect(
    layout("<b>a<sup>b<sub>c</sub>d</sup></b>", 16, 4000),
    content=(
      #|"a"/1/8.896 "b"/17/8.146666666666667 "c"/9/7.413333333333334 "d"/17/8.146666666666667 widths=[32.60266666666667] width=32.60266666666667 height=24 size=16 line=24
    ),
  )
  inspect(
    layout("<sup>a<sub>b<sup>c</sup>d</sub>e</sup>", 16, 4000),
    content=(
      #|"a"/16/7.413333333333334 "b"/8/7.413333333333334 "c"/16/6.666666666666667 "d"/8/7.413333333333334 "e"/16/7.413333333333334 widths=[36.32000000000001] width=36.32000000000001 height=24 size=16 line=24
    ),
  )
  inspect(
    layout("<sup>a<sub>b<br/>c</sub>d</sup>", 16, 4000),
    content=(
      #|"a"/16/7.413333333333334 "b"/8/7.413333333333334 | "c"/8/6.666666666666667 "d"/16/7.413333333333334 widths=[14.826666666666668, 14.080000000000002] width=14.826666666666668 height=42 size=16 line=21
    ),
  )
  inspect(
    layout("a</sub>b<sub>c", 16, 4000),
    content=(
      #|"ab"/0/17.792 "c"/8/6.666666666666667 widths=[24.45866666666667] width=24.45866666666667 height=24 size=16 line=24
    ),
  )
}

///|
test "icons the host does not have leave no gap" {
  inspect(
    layout("fa:fa-car Cars", 16, 4000),
    content="\"Cars\"/0/33.776 widths=[33.776] width=33.776 height=24 size=16 line=24",
  )
  inspect(
    layout("Cars fa:fa-car", 16, 4000),
    content="\"Cars\"/0/33.776 widths=[33.776] width=33.776 height=24 size=16 line=24",
  )
}

///|
/// A host that has `fa:fa-car`, and an empty drawing for `fa:fa-empty`.
fn car_icons(name : String) -> String? {
  match name {
    "fa:fa-car" => Some("<path/>")
    "fa:fa-empty" => Some("")
    _ => None
  }
}

///|
test "an icon the host has is a span a size and a quarter wide" {
  @text.with_icons(Some(car_icons), () => {
    inspect(
      layout("fa:fa-car Cars", 16, 4000),
      content="\"\"@fa:fa-car/0/20 \" Cars\"/0/38.224 widths=[58.224] width=58.224 height=24 size=16 line=24",
    )
    inspect(
      layout("Cars fa:fa-car", 16, 4000),
      content="\"Cars \"/0/38.224 \"\"@fa:fa-car/0/20 widths=[58.224] width=58.224 height=24 size=16 line=24",
    )
    inspect(
      layout("<b>Bold</b> fa:fa-car", 14, 4000),
      content="\"Bold\"/1/31.108 \" \"/0/3.892 \"\"@fa:fa-car/0/17.5 widths=[52.5] width=52.5 height=21 size=14 line=21",
    )
  })
}

///|
test "an icon whose drawing is empty counts as missing in a label" {
  @text.with_icons(Some(car_icons), () => {
    inspect(
      layout("fa:fa-empty Cars", 16, 4000),
      content="\"Cars\"/0/33.776 widths=[33.776] width=33.776 height=24 size=16 line=24",
    )
  })
}

///|
test "wrapping keeps an icon whole and the space before it" {
  @text.with_icons(Some(car_icons), () => {
    inspect(
      layout("Go fa:fa-car fast and far away", 16, 60),
      content=(
        #|"Go "/0/25.792 ""@fa:fa-car/0/20 | "fast and"/0/56.928 | "far"/0/18.672 | "away"/0/37.344 widths=[45.792, 56.928, 18.672, 37.344] width=56.928 height=84 size=16 line=21
      ),
    )
  })
}

///|
test "icons are looked up only while a resolver is installed" {
  @text.with_icons(Some(car_icons), () => ())
  inspect(
    layout("fa:fa-car Cars", 16, 4000),
    content="\"Cars\"/0/33.776 widths=[33.776] width=33.776 height=24 size=16 line=24",
  )
}

///|
test "line breaks split a label into lines" {
  inspect(
    layout("a<br>b<BR/>c\\nd\ne", 14, 4000),
    content=(
      #|"a"/0/7.784 | "b"/0/7.784 | "c"/0/7 | "d"/0/7.784 | "e"/0/7.784 widths=[7.784, 7.784, 7, 7.784, 7.784] width=7.784 height=90 size=14 line=18
    ),
  )
}

///|
test "a label wider than the room wraps at spaces" {
  inspect(
    layout("alpha beta gamma", 16, 50),
    content=(
      #|"alpha"/0/39.136 | "beta"/0/31.136 | "gamma"/0/53.344 widths=[39.136, 31.136, 53.344] width=53.344 height=63 size=16 line=21
    ),
  )
  inspect(
    layout("<b>alpha beta</b> gamma delta", 16, 60),
    content=(
      #|"alpha"/1/41.792 | "beta"/1/32.896 | "gamma"/0/53.344 | "delta"/0/34.688 widths=[41.792, 32.896, 53.344, 34.688] width=53.344 height=84 size=16 line=21
    ),
  )
}

///|
test "Chinese and Japanese wrap between characters, keeping punctuation attached" {
  inspect(
    layout("日本語のテキスト、です。", 16, 40),
    content=(
      #|"日本"/0/32 | "語の"/0/32 | "テキ"/0/32 | "ス"/0/16 | "ト、"/0/32 | "で"/0/16 | "す。"/0/32 widths=[32, 32, 32, 16, 32, 16, 32] width=32 height=147 size=16 line=21
    ),
  )
  inspect(
    layout("（括弧）テスト", 16, 20),
    content=(
      #|"（括"/0/32 | "弧）"/0/32 | "テ"/0/16 | "ス"/0/16 | "ト"/0/16 widths=[32, 32, 16, 16, 16] width=32 height=105 size=16 line=21
    ),
  )
}

///|
test "markdown labels read emphasis markers" {
  inspect(
    layout("*em* and **strong** a_b_c", 16, 4000, markdown=true),
    content="\"em\"/2/22.224 \" and \"/0/35.584 \"strong\"/1/49.776 \" a_b_c\"/0/48.032 widths=[155.61599999999999] width=155.61599999999999 height=24 size=16 line=24",
  )
}
