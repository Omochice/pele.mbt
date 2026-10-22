///|
test "line_end finds the next line break or the end of the text" {
  inspect(@common.line_end("ab\ncd", 0), content="2")
  inspect(@common.line_end("ab\ncd", 3), content="5")
  inspect(@common.line_end("ab\ncd", 9), content="5")
  inspect(@common.line_end("", 0), content="0")
}

///|
test "skip_trivia skips comments and whitespace up to a line break" {
  let cases : Array[(String, Int32, Int32)] = [
    ("%%{init}%%\n", 0, 10),
    ("%{x}\n", 0, 0),
    ("}%%x\ny", 0, 0),
    ("a%%b\nc", 0, 4),
    (" \t # c\n x", 0, 6),
    ("%", 0, 1),
    ("  ", 0, 2),
    ("x", 5, 5),
  ]
  for case in cases {
    let (src, from, expected) = case
    assert_eq(@common.skip_trivia(src, from), expected, msg=src)
  }
}

///|
test "skip_trivia matches pele from every position of every string of up to six trivia characters" {
  let expected = [
    "350ca8af", "6e33e0d3", "3ce5f7da", "289bf99d", "a2fceccb", "3a5738d7", "fc146edc",
  ]
  for length, hash in expected {
    let outputs = strings_over(["%", "{", "}", "\n", " ", "#", "a"], length).map(src => {
        let ends = []
        for p in 0..<=src.length() {
          ends.push(@common.skip_trivia(src, p).to_string())
        }
        ends.join(",")
      },
    )
    assert_eq(fnv1a(outputs.join("\n")), hash, msg="length \{length}")
  }
}

///|
/// Where `accessibility` ends and the tokens it emits, as type@start+length, with the first type 10.
fn dump_accessibility(src : String, p : Int32) -> String {
  let out : @common.Tokens = { kinds: [], starts: [], ends: [], src, }
  let end = @common.accessibility(out, p, 10)
  let tokens = []
  for i, kind in out.kinds {
    tokens.push("\{kind}@\{out.starts[i]}+\{out.ends[i] - out.starts[i]}")
  }
  "\{end}:" + tokens.join(" ")
}

///|
test "accessibility lexes accTitle and accDescr statements" {
  let cases : Array[(String, Int32, String)] = [
    ("accTitle: hello world\nnext", 0, "21:10@0+10 11@10+11"),
    ("x accDescr { a\nb }", 2, "18:14@13+4"),
    ("accDescr {", 0, "10:14@10+0"),
    ("accDescr {}", 0, "11:"),
    ("accDescr", 0, "0:"),
    ("accTitle", 0, "0:"),
    ("accTitle :", 0, "10:10@0+10 11@10+0"),
    ("accDescr  {  multi\n line  ", 0, "26:14@13+13 14@26+0"),
    ("accTitle\u{a0}:\u{3000}x", 0, "12:10@0+11 11@11+1"),
    ("accDescr:x", 0, "10:12@0+9 13@9+1"),
    ("acctitle x", 0, "0:"),
  ]
  for case in cases {
    let (src, p, expected) = case
    assert_eq(dump_accessibility(src, p), expected, msg=src)
  }
}

///|
test "accessibility matches pele after each keyword on every suffix of up to five characters" {
  let expected = [
    ("accTitle", "9ec992ed"),
    ("accDescr", "4ea7812c"),
    ("ACCDESCR", "4ea7812c"),
    ("acctitl", "cbddc4d7"),
    ("x", "cbddc4d7"),
  ]
  for case in expected {
    let (keyword, hash) = case
    let outputs = []
    for length in 0..<=5 {
      for suffix in strings_over([" ", ":", "{", "}", "\n", "a"], length) {
        outputs.push(dump_accessibility(keyword + suffix, 0))
      }
    }
    assert_eq(outputs.length(), 9331)
    assert_eq(fnv1a(outputs.join("\n")), hash, msg=keyword)
  }
}
