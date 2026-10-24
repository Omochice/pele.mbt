///|
fn dump_fitted(fitted : @common.Fitted?) -> String {
  match fitted {
    Some(f) => "\{f.text}|\{f.size}|\{f.width}"
    None => "-"
  }
}

///|
test "fit_text shrinks the font before cutting the text" {
  let m = @text.metrics_measurer
  let cases : Array[(String, Double, Double, Double, String)] = [
    ("hello world", 30, 16, 8, "hello w…|8|29.536"),
    ("hello world", 60, 16, 8, "hello world|12|57.348"),
    ("hello world", 200, 16, 8, "hello world|16|76.464"),
    ("hello world", 10, 16, 8, "h…|8|9.088"),
    ("a b c", 14, 16, 8, "a…|8|9.088"),
    (
      "\u{1f408}\u{1f408}\u{1f408} cats", 25, 16, 8, "\u{1f408}\u{1f408}…|8|20.64",
    ),
    ("x", 0, 16, 8, "-"),
    ("", 50, 16, 8, "-"),
  ]
  for case in cases {
    let (text, max, size, min, expected) = case
    assert_eq(
      dump_fitted(@common.fit_text(text, max, size, min, m)),
      expected,
      msg=text,
    )
  }
}

///|
test "fit_text matches pele over widths, sizes, minimums and styles" {
  let maxes : Array[Double] = [-1, 0, 0.5]
  for m in 1..<=160 {
    maxes.push(m.to_double())
  }
  maxes.push(7.25)
  maxes.push(200)
  maxes.push(1000)
  maxes.push(0.0 / 0.0)
  let sizes : Array[Double] = [16, 12, 14.5]
  let mins : Array[Double] = [8, 6, 10.5, 16, 20]
  let styles = [0, 1, 2, 4, 7]
  let expected = [
    ("", "9e66ecd0"),
    ("a", "eab3cf71"),
    ("hello world", "a4027488"),
    ("Hello   ", "7afeaab2"),
    ("\u{1f408}\u{1f408}\u{1f408} cats", "b88a5de8"),
    ("中文テキスト", "9365c69b"),
    ("WWWWWWWWWWWWWWWWWWWW", "9c1d4d50"),
    ("a b c d e f g", "a9bed894"),
    ("x\u{a0}y   z\t", "f822bbf7"),
    (
      String::from_array([
        (0xd800).unsafe_to_char(),
        'a',
        'b',
        'c',
        (0xdc00).unsafe_to_char(),
      ]),
      "9de08f59",
    ),
    ("Mi", "79d05353"),
  ]
  for case in expected {
    let (text, hash) = case
    let outputs = []
    for max in maxes {
      for size in sizes {
        for min in mins {
          for style in styles {
            outputs.push(
              dump_fitted(
                @common.fit_text(
                  text,
                  max,
                  size,
                  min,
                  @text.metrics_measurer,
                  style~,
                ),
              ),
            )
          }
        }
      }
    }
    assert_eq(outputs.length(), 12525)
    assert_eq(fnv1a(outputs.join("\n")), hash, msg=text)
  }
}
