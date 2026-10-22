///|
test "literal_label keeps every character but the spaces a line breaks at" {
  let m = @text.metrics_measurer
  let cases : Array[(String, Double, Double, Int32, String)] = [
    (
      "hello world", 40, 16, 0, "38.224 48 16 24[hello/0/33.792=33.792;world/0/38.224=38.224]",
    ),
    ("a  b", 10, 16, 0, "8.896 48 16 24[a/0/8.896=8.896;b/0/8.896=8.896]"),
    ("", 100, 16, 0, "0 0 16 24[]"),
    ("\n", 100, 16, 0, "0 48 16 24[/0/0=0;/0/0=0]"),
    (
      "one\n\ntwo", 100, 16, 0, "26.688 72 16 24[one/0/26.688=26.688;/0/0=0;two/0/24.896=24.896]",
    ),
    (
      "abc def", 0, 16, 0, "8.896 144 16 24[a/0/8.896=8.896;b/0/8.896=8.896;c/0/8=8;d/0/8.896=8.896;e/0/8.896=8.896;f/0/4.448=4.448]",
    ),
    (
      "  lead", 20, 16, 0, "17.792 72 16 24[  /0/8.896=8.896;le/0/12.448=12.448;ad/0/17.792=17.792]",
    ),
    (
      "x \u{1f408}\u{1f408}\u{1f408}", 20, 12, 1, "12 72 12 18[x/1/6.672=6.672;\u{1f408}/1/12=12;\u{1f408}/1/12=12;\u{1f408}/1/12=12]",
    ),
    (
      "path/to/file.txt", 50, 16, 4, "48 96 16 24[path//4/48=48;to/fi/4/48=48;le.tx/4/48=48;t/4/9.6=9.6]",
    ),
  ]
  for case in cases {
    let (raw, room, size, style, expected) = case
    assert_eq(
      dump_label(@common.literal_label(raw, m, size, room, style~)),
      expected,
      msg=raw,
    )
  }
}

///|
test "literal_label preserves literal text and Unicode through long-word wrapping" {
  let raw = "<literal>& emoji \u{1f408} 中文 " + "filename_".repeat(40)
  let label = @common.literal_label(raw, @text.metrics_measurer, 16, 100)
  let texts = []
  for line in label.lines {
    for span in line {
      texts.push(span.text)
    }
  }
  let without_spaces = (text : String) => {
    let out = StringBuilder()
    for c in text {
      if !@util.is_space(c.to_int()) {
        out.write_char(c)
      }
    }
    out.to_string()
  }
  assert_eq(without_spaces(texts.join("")), without_spaces(raw))
  for text in texts {
    assert_eq(text, @util.trim(text))
  }
  assert_eq(texts[0], "<literal>&")
  assert_true(label.width <= 100)
  assert_eq(label.lines.length(), 32)
  assert_eq(fnv1a(dump_label(label)), "0554b4ae")
}

///|
test "break_label cuts lines too wide between characters and keeps their emphasis" {
  let m = @text.metrics_measurer
  let styled = @text.layout_label(
    Some("<b>Supercalifragilisticexpialidocious</b>"),
    false,
    m,
    16,
    400,
  )
  let wrapped = @common.break_label(styled, m, 80)
  inspect(
    dump_label(wrapped),
    content="77.36 96 16 24[Supercalif/1/77.36=77.36;ragilistice/1/74.704=74.704;xpialidoci/1/73.808=73.808;ous/1/28.448=28.448]",
  )
  inspect(
    dump_label(
      @common.break_label(
        @text.layout_label(
          Some("plain <i>it</i> and **bold**"),
          true,
          m,
          16,
          400,
        ),
        m,
        30,
      ),
    ),
    content="28.448 120 16 24[plai/0/24.896=24.896;n /0/13.344|it/2/8| /0/4.448=25.792;and/0/26.688=26.688; /0/4.448|bol/1/24=28.448;d/1/9.776=9.776]",
  )
  inspect(
    dump_label(
      @common.break_label(
        @text.layout_label(Some("a<br><br>b"), false, m, 16, 400),
        m,
        3,
      ),
    ),
    content="8.896 72 16 24[a/0/8.896=8.896;=0;b/0/8.896=8.896]",
  )
}

///|
test "break_label matches pele on labels of every string of up to four pieces" {
  let pieces = [
    "<b>",
    "</b>",
    "ab",
    "Wide",
    " ",
    "<br>",
    "\u{1f408}",
    "*",
    String::from_array([(0xd800).unsafe_to_char()]),
  ]
  let expected = ["f002259d", "331af199", "e1e78ce5", "d6d4957d", "f8870691"]
  let m = @text.metrics_measurer
  for length, hash in expected {
    let outputs = []
    for raw in strings_over(pieces, length) {
      for markdown in [false, true] {
        for max in [400.0, 30] {
          let label = @text.layout_label(Some(raw), markdown, m, 16, max)
          for room in [-1.0, 0, 6, 20, 45, 1000] {
            outputs.push(dump_label(@common.break_label(label, m, room)))
          }
        }
      }
    }
    assert_eq(fnv1a(outputs.join("\n")), hash, msg="length \{length}")
  }
}

///|
test "left_label_svg anchors every line at its start and keeps its spaces" {
  let m = @text.metrics_measurer
  inspect(
    @common.left_label_svg(
      @text.layout_label(
        Some("<b>bold</b> and <i>it</i><br>line 2 & <more>"),
        false,
        m,
        16,
        400,
      ),
      4,
      10,
      " class=\"lbl\"",
    ),
    content="<text class=\"lbl\" x=\"4\" y=\"27.6\" text-anchor=\"start\" xml:space=\"preserve\"><tspan font-weight=\"var(--_w)\">bold</tspan> and <tspan font-style=\"italic\">it</tspan></text><text class=\"lbl\" x=\"4\" y=\"51.6\" text-anchor=\"start\" xml:space=\"preserve\">line 2 &amp; </text>",
  )
  inspect(
    @common.left_label_svg(
      @text.layout_label(Some("<b>all bold</b>"), false, m, 16, 400),
      0,
      0,
      "",
    ),
    content="<text font-weight=\"var(--_w)\" x=\"0\" y=\"17.6\" text-anchor=\"start\" xml:space=\"preserve\">all bold</text>",
  )
  inspect(
    @common.left_label_svg(
      @text.layout_label(Some("a<br><br>b"), false, m, 12, 400),
      1.25,
      0.5,
      "",
    ),
    content="<text x=\"1.25\" y=\"13.7\" text-anchor=\"start\" xml:space=\"preserve\">a</text><text x=\"1.25\" y=\"49.7\" text-anchor=\"start\" xml:space=\"preserve\">b</text>",
  )
  inspect(
    @common.left_label_svg(
      @common.literal_label("  keep  spaces", m, 16, 1000),
      0,
      0,
      "",
    ),
    content="<text x=\"0\" y=\"17.6\" text-anchor=\"start\" xml:space=\"preserve\">  keep  spaces</text>",
  )
}

///|
test "left_label_svg matches pele on labels of every string of up to four pieces" {
  let pieces = ["<b>", "</b>", "<i>", "a&b", " ", "<br>", "\u{1}", "x"]
  let expected = ["6a00f6a5", "c0addd87", "12e724b4", "ae235f44", "f411a7e3"]
  let m = @text.metrics_measurer
  for length, hash in expected {
    let outputs = []
    for raw in strings_over(pieces, length) {
      let label = @text.layout_label(Some(raw), false, m, 16, 400)
      for
        attrs in [
          "", " class=\"t\"", " font-weight=\"bold\"", " font-style=\"italic\"",
        ] {
        outputs.push(@common.left_label_svg(label, 10.5, 3, attrs))
      }
      outputs.push(
        @common.left_label_svg(
          @common.literal_label(raw, m, 14, 30, style=2),
          0,
          0,
          "",
        ),
      )
    }
    assert_eq(fnv1a(outputs.join("\n")), hash, msg="length \{length}")
  }
}

///|
test "literal_label matches pele on every string of up to four pieces" {
  let pieces = [
    " ",
    "a",
    "W",
    "file_",
    "\n",
    "\u{1f408}",
    String::from_array([(0xd800).unsafe_to_char()]),
    "中",
    "\u{a0}",
  ]
  let expected = ["387fe23d", "253a3d86", "90469435", "37a287cd", "54356152"]
  for length, hash in expected {
    let outputs = []
    for raw in strings_over(pieces, length) {
      for room in [-1.0, 0, 8, 20, 40, 1000] {
        for style in [0, 5] {
          outputs.push(
            dump_label(
              @common.literal_label(
                raw,
                @text.metrics_measurer,
                16,
                room,
                style~,
              ),
            ),
          )
        }
      }
    }
    assert_eq(fnv1a(outputs.join("\n")), hash, msg="length \{length}")
  }
}
