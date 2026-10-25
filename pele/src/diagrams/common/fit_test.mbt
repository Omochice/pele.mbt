///|
test "plain_label reads only <br> as markup, and fit_label also cuts words too long for the box" {
  let m = @text.metrics_measurer
  let cases : Array[(String?, Double, Double, String, String)] = [
    (None, 100, 16, "0 0 0 0[]", "0 0 0 0[]"),
    (Some(""), 100, 16, "0 0 0 0[]", "0 0 0 0[]"),
    (
      Some("a <b>bold</b> <i>x</i>"),
      400,
      16,
      "164.576 24 16 24[a <b>bold</b> <i>x</i>/0/164.576=164.576]",
      "164.576 24 16 24[a <b>bold</b> <i>x</i>/0/164.576=164.576]",
    ),
    (
      Some("x:fa-car y"),
      400,
      16,
      "65.792 24 16 24[x:fa-car y/0/65.792=65.792]",
      "65.792 24 16 24[x:fa-car y/0/65.792=65.792]",
    ),
    (
      Some("line one<br>line two"),
      400,
      16,
      "56.032 42 16 21[line one/0/56.032=56.032;line two/0/54.24=54.24]",
      "56.032 42 16 21[line one/0/56.032=56.032;line two/0/54.24=54.24]",
    ),
    (
      Some("a<BR/>b"),
      400,
      16,
      "8.896 42 16 21[a/0/8.896=8.896;b/0/8.896=8.896]",
      "8.896 42 16 21[a/0/8.896=8.896;b/0/8.896=8.896]",
    ),
    (
      Some("Supercalifragilisticexpialidocious"),
      80,
      16,
      "229.392 24 16 24[Supercalifragilisticexpialidocious/0/229.392=229.392]",
      "78.24 63 16 21[Supercalifr/0/76.464=76.464;agilisticexp/0/78.24=78.24;ialidocious/0/74.688=74.688]",
    ),
    (
      Some("wrap these words please"),
      60,
      16,
      "47.136 84 16 21[wrap/0/34.672=34.672;these/0/39.136=39.136;words/0/42.672=42.672;please/0/47.136=47.136]",
      "47.136 84 16 21[wrap/0/34.672=34.672;these/0/39.136=39.136;words/0/42.672=42.672;please/0/47.136=47.136]",
    ),
    (
      Some("&amp;&amp;&amp;&amp;&amp;&amp;"),
      20,
      16,
      "64.032 24 16 24[&&&&&&/0/64.032=64.032]",
      "21.344 63 16 21[&&/0/21.344=21.344;&&/0/21.344=21.344;&&/0/21.344=21.344]",
    ),
    (
      Some("\u{1f408}\u{1f408}\u{1f408}\u{1f408}\u{1f408}\u{1f408}"),
      30,
      16,
      "96 24 16 24[\u{1f408}\u{1f408}\u{1f408}\u{1f408}\u{1f408}\u{1f408}/0/96=96]",
      "16 126 16 21[\u{1f408}/0/16=16;\u{1f408}/0/16=16;\u{1f408}/0/16=16;\u{1f408}/0/16=16;\u{1f408}/0/16=16;\u{1f408}/0/16=16]",
    ),
    (
      Some("ab<br>cdefghijkl"),
      30,
      12,
      "50.016 32 12 16[ab/0/13.344=13.344;cdefghijkl/0/50.016=50.016]",
      "29.352 48 12 16[ab/0/13.344=13.344;cdefg/0/29.352=29.352;hijkl/0/20.664=20.664]",
    ),
  ]
  for case in cases {
    let (raw, max, size, plain, fitted) = case
    let msg = raw.unwrap_or("undefined")
    assert_eq(dump_label(@common.plain_label(raw, m, size, max)), plain, msg~)
    assert_eq(dump_label(@common.fit_label(raw, m, size, max)), fitted, msg~)
  }
}

///|
/// Every string of up to three pieces that the tag, icon and cutting rules treat differently.
let fit_pieces : Array[String] = [
  "<br>",
  "<BR />",
  "<br/",
  "<b>",
  "\u{fb02}°",
  "°x¶ß",
  "&#35;",
  "&amp;",
  "&;",
  "\u{1f408}",
  String::from_array([(0xd800).unsafe_to_char()]),
  " ",
  "W",
  "ab",
  "\n",
  ":fa-",
  "fa:fa-car",
]

///|
fn fit_grid(
  layout : (String?, @text.TextMeasurer, Double, Double, Int32) -> @text.Label,
  length : Int32,
) -> String {
  let outputs = []
  for raw in strings_over(fit_pieces, length) {
    for max in [-1.0, 0, 5, 12, 20, 35, 60, 100] {
      for base in [0, 1, 6] {
        outputs.push(
          dump_label(layout(Some(raw), @text.metrics_measurer, 16, max, base)),
        )
      }
    }
  }
  fnv1a(outputs.join("\n"))
}

///|
test "plain_label matches pele on every string of up to three pieces" {
  let expected = ["f002259d", "724416e3", "da15f3eb", "c3f9ddac"]
  for length, hash in expected {
    let layout = (raw, m, size, max, base) => {
      @common.plain_label(raw, m, size, max, base~)
    }
    assert_eq(fit_grid(layout, length), hash, msg="length \{length}")
  }
}

///|
test "fit_label matches pele on every string of up to three pieces" {
  let expected = ["f002259d", "26a076c9", "a0f4bdf3", "50c6fa84"]
  for length, hash in expected {
    let layout = (raw, m, size, max, base) => {
      @common.fit_label(raw, m, size, max, base~)
    }
    assert_eq(fit_grid(layout, length), hash, msg="length \{length}")
  }
}
