///|
fn show_math_label(label : @text.Label) -> String {
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
fn broken_math_label(raw : String, room : Double) -> String {
  let math = (tex : String, _ : Double) => {
    match tex {
      "tall" => Some(({ "svg": "<path/>", "width": 20, "height": 40 } : Json))
      "w" => Some({ "svg": "<g/>", "width": 30, "height": 10 })
      _ => None
    }
  }
  @text.with_math(Some(math), () => {
    let m = @text.metrics_measurer
    let label = @text.layout_label(Some(raw), true, m, 16, 40)
    show_math_label(@common.break_label(label, m, room))
  })
}

///|
test "break_label keeps math whole and recounts line heights" {
  inspect(
    broken_math_label("abcdefgh$$tall$$ij", 40),
    content=(
      #|"abcd"/0/34.688 | "efgh"/0/31.136 | [math 20x40]/0/20 "ij"/0/7.104 widths=[34.688, 31.136, 27.104] width=34.688 height=86 size=16 line=21 heights=[21, 21, 44]
    ),
  )
  inspect(
    broken_math_label("abcdefgh$$w$$ij", 40),
    content=(
      #|"abcd"/0/34.688 | "efgh"/0/31.136 | [math 30x10]/0/30 "ij"/0/7.104 widths=[34.688, 31.136, 37.104] width=37.104 height=63 size=16 line=21
    ),
  )
  inspect(
    broken_math_label("abcdefghijk<br>$$tall$$", 40),
    content=(
      #|"abcd"/0/34.688 | "efghij"/0/38.24 | "k"/0/8 | [math 20x40]/0/20 widths=[34.688, 38.24, 8, 20] width=38.24 height=107 size=16 line=21 heights=[21, 21, 21, 44]
    ),
  )
}
