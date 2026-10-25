///|
/// The tokens of a text as type@start+length, with the types numbered as in pele: END is 0, EOF 1, INVALID 2, NEWLINE 3, timeline 4,
/// timeline_lr 5, timeline_td 6, title 7, acc_title 8 to acc_descr_multiline_value 12, section 13, period 14 and event 15.
fn dump_tokens(src : String) -> String {
  let tokens = @timeline.tokenize(src)
  let out = []
  for i, kind in tokens.kinds {
    out.push("\{kind}@\{tokens.starts[i]}+\{tokens.ends[i] - tokens.starts[i]}")
  }
  out.join(" ")
}

///|
/// FNV-1a over UTF-16 code units, the hash under which the expected outputs below were taken from pele.
fn fnv1a(text : String) -> String {
  let mut h : UInt32 = 0x811c9dc5U
  for i in 0..<text.length() {
    h = (h ^ text.unsafe_get(i).to_int().reinterpret_as_uint()) * 0x01000193U
  }
  let digits = "0123456789abcdef"
  let out = StringBuilder()
  for shift in [28, 24, 20, 16, 12, 8, 4, 0] {
    let d = ((h >> shift) & 0xfU).reinterpret_as_int()
    out.write_char(digits.get_char(d).unwrap())
  }
  out.to_string()
}

///|
/// Every string of exactly `length` pieces drawn from `pieces`, in lexicographic order of piece indices.
fn strings_over(pieces : Array[String], length : Int32) -> Array[String] {
  let mut out = [""]
  for _ in 0..<length {
    let next = []
    for prefix in out {
      for piece in pieces {
        next.push(prefix + piece)
      }
    }
    out = next
  }
  out
}

///|
test "the timeline keyword takes an optional direction" {
  let cases = [
    ("timeline TD", "6@0+11 1@11+0 0@11+0"),
    ("Timeline TD", "6@0+11 1@11+0 0@11+0"),
    ("timeline  LR\n", "5@0+12 3@12+1 1@13+0 0@13+0"),
    ("timeline\ttd x", "6@0+11 14@12+1 1@13+0 0@13+0"),
    ("timeline LRx", "4@0+8 14@9+3 1@12+0 0@12+0"),
    ("timelineLR", "14@0+10 1@10+0 0@10+0"),
    ("\n\ntimeline", "3@0+2 4@2+8 1@10+0 0@10+0"),
  ]
  for case in cases {
    let (src, expected) = case
    assert_eq(dump_tokens(src), expected, msg=src)
  }
}

///|
test "a title takes the rest of its line, and the next line when nothing follows the keyword" {
  let cases = [
    ("title x", "7@0+7 1@7+0 0@7+0"),
    ("title\nx", "7@0+7 1@7+0 0@7+0"),
    ("title ", "14@0+6 1@6+0 0@6+0"),
    ("title  y\n", "7@0+8 3@8+1 1@9+0 0@9+0"),
    ("title x\ntimeline", "7@0+7 3@7+1 4@8+8 1@16+0 0@16+0"),
  ]
  for case in cases {
    let (src, expected) = case
    assert_eq(dump_tokens(src), expected, msg=src)
  }
}

///|
test "a section takes its name up to a colon or a line break" {
  let cases = [
    ("section S\n", "13@0+9 3@9+1 1@10+0 0@10+0"),
    ("section\nx", "13@0+9 1@9+0 0@9+0"),
    ("section  :x", "13@0+9 2@9+1 14@10+1 1@11+0 0@11+0"),
    ("section a:b", "13@0+9 2@9+1 14@10+1 1@11+0 0@11+0"),
  ]
  for case in cases {
    let (src, expected) = case
    assert_eq(dump_tokens(src), expected, msg=src)
  }
}

///|
test "a period runs to a colon, and an event starts at a colon followed by whitespace" {
  let cases = [
    (
      "timeline\n  2001 : a : b\n", "4@0+8 3@8+1 14@11+5 15@16+4 15@20+3 3@23+1 1@24+0 0@24+0",
    ),
    ("a : b", "14@0+2 15@2+3 1@5+0 0@5+0"),
    ("a: b", "14@0+1 15@1+3 1@4+0 0@4+0"),
    ("a :b", "14@0+2 2@2+1 14@3+1 1@4+0 0@4+0"),
    ("a:b:c", "14@0+1 2@1+1 14@2+1 2@3+1 14@4+1 1@5+0 0@5+0"),
    ("  : e", "15@2+3 1@5+0 0@5+0"),
    ("  :\n", "2@2+1 3@3+1 1@4+0 0@4+0"),
    ("  : a:b : c", "15@2+6 15@8+3 1@11+0 0@11+0"),
    ("a\u{a0}: b\u{2028}c : d", "14@0+2 15@2+6 15@8+3 1@11+0 0@11+0"),
  ]
  for case in cases {
    let (src, expected) = case
    assert_eq(dump_tokens(src), expected, msg=src)
  }
}

///|
test "comments and blank space are skipped, and a hash ends a period" {
  let cases = [
    ("x # y", "14@0+2 1@5+0 0@5+0"),
    ("x %% y\nz", "14@0+6 3@6+1 14@7+1 1@8+0 0@8+0"),
    ("%{ x\n", "14@0+4 3@4+1 1@5+0 0@5+0"),
    ("timeline\n\n\n x", "4@0+8 3@8+3 14@12+1 1@13+0 0@13+0"),
    ("a\r\nb", "14@0+2 3@2+1 14@3+1 1@4+0 0@4+0"),
  ]
  for case in cases {
    let (src, expected) = case
    assert_eq(dump_tokens(src), expected, msg=src)
  }
}

///|
test "accessibility statements become tokens, and an unclosed block ends the text without an EOF" {
  let cases = [
    (
      "accTitle: t\naccDescr: d", "8@0+10 9@10+1 3@11+1 10@12+10 11@22+1 1@23+0 0@23+0",
    ),
    ("accDescr {\n a\n}\n", "12@12+2 3@15+1 1@16+0 0@16+0"),
    ("accDescr {", "12@10+0 0@10+0"),
    ("accTitle", "14@0+8 1@8+0 0@8+0"),
  ]
  for case in cases {
    let (src, expected) = case
    assert_eq(dump_tokens(src), expected, msg=src)
  }
}

///|
test "tokens match pele for every string of up to four lexical pieces" {
  let pieces = [
    "timeline", " ", "\n", ":", "a", "title", "section", "LR", "td", "#", "%%", "acc",
    "\t",
  ]
  let expected = ["bd92d544", "7f9c63be", "38df550f", "cef6bd89", "7b2f1ee0"]
  for length in 0..<=4 {
    let outputs = strings_over(pieces, length).map(dump_tokens)
    assert_eq(
      fnv1a(outputs.join("\n")),
      expected[length],
      msg="length \{length}",
    )
  }
}
