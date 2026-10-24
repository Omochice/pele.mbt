///|
/// FNV-1a over UTF-16 code units, the hash under which the expected outputs in this package's tests were taken from pele.
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
/// The tokens of `src` as type@start+length, or the lexical error.
fn lex(src : String) -> String {
  let tokens = @common.tokenize(src, @wardley.wardley_tokens, "wardley") catch {
    @errors.PeleError(failure) => return failure.message
  }
  let out = []
  for i, kind in tokens.kinds {
    out.push("\{kind}@\{tokens.starts[i]}+\{tokens.ends[i] - tokens.starts[i]}")
  }
  out.join(" ")
}

///|
fn check_lexing(cases : Array[(String, String)]) -> Unit raise {
  for case in cases {
    let (src, expected) = case
    assert_eq(lex(src), expected, msg=src)
  }
}

///|
test "names take hyphens and blanks between words, but not an arrow or a title" {
  check_lexing([
    ("wardley-beta", "16@0+12 -1@12+0"),
    ("Cup of Tea", "30@0+10 -1@10+0"),
    ("real-time processing  x", "30@0+23 -1@23+0"),
    ("A->B", "30@0+1 11@1+2 30@3+1 -1@4+0"),
    ("foo-bar->baz", "30@0+7 11@7+2 30@9+3 -1@12+0"),
    ("foo--bar", "30@0+8 -1@8+0"),
    ("foo-", "30@0+4 -1@4+0"),
    ("title x", "34@0+7 -1@7+0"),
    ("title", "30@0+5 -1@5+0"),
    ("titles", "30@0+6 -1@6+0"),
    ("accTitle: x", "33@0+11 -1@11+0"),
    ("accDescription", "37@0+14 -1@14+0"),
    (
      "a (b) & c", "Lexical error on line 1. Unrecognized text.\na (b) & c\n------^",
    ),
  ])
}

///|
test "keywords and strategies match without a boundary" {
  check_lexing([
    ("components", "20@0+9 30@9+1 -1@10+0"),
    ("buyer", "15@0+3 30@3+2 -1@5+0"),
    ("labelled thing", "21@0+5 30@5+9 -1@14+0"),
  ])
}

///|
test "a number needs a fraction, and an integer is not followed by a dot" {
  check_lexing([
    ("0.5", "10@0+3 -1@3+0"),
    ("05", "35@0+1 35@1+1 -1@2+0"),
    ("12.", "Lexical error on line 1. Unrecognized text.\n12.\n--^"),
    ("1.5.", "Lexical error on line 1. Unrecognized text.\n1.5.\n---^"),
    ("100", "35@0+3 -1@3+0"),
  ])
}

///|
test "arrows, ports, flow labels, and a hyphen that loses to a longer token" {
  check_lexing([
    ("->", "11@0+2 -1@2+0"),
    ("-->", "13@0+3 -1@3+0"),
    ("-.->", "13@0+4 -1@4+0"),
    ("+>", "12@0+2 -1@2+0"),
    ("+<>", "12@0+3 -1@3+0"),
    ("+'x'>", "13@0+5 -1@5+0"),
    ("+'z'<>", "13@0+6 -1@6+0"),
    ("+'", "Lexical error on line 1. Unrecognized text.\n+'\n^"),
    ("+'' B", "Lexical error on line 1. Unrecognized text.\n+'' B\n^"),
    ("-", "7@0+1 -1@1+0"),
    ("--", "7@0+1 7@1+1 -1@2+0"),
    ("---", "7@0+1 7@1+1 7@2+1 -1@3+0"),
    ("---\nx\n---\ny", "30@10+1 -1@11+0"),
    ("---\nx", "7@0+1 7@1+1 7@2+1 38@3+1 30@4+1 -1@5+0"),
    ("; note", "14@0+6 -1@6+0"),
  ])
}

///|
test "strings, comments, and directives" {
  check_lexing([
    ("\"a b\" 'c'", "36@0+5 36@6+3 -1@9+0"),
    ("%% c\n%%{init}%%\nx", "38@4+1 30@16+1 -1@17+0"),
  ])
}

///|
test "lexing matches pele on every string of up to five punctuation pieces" {
  let expected = ["dd53a4ac", "2c4d6845", "f4914ccc", "5c1c96ef", "bd2e05e7"]
  for i, hash in expected {
    let pieces = ["-", ">", ".", "+", "'", "<", "1", "a", " ", "\n"]
    assert_eq(
      fnv1a(strings_over(pieces, i + 1).map(lex).join("\n")),
      hash,
      msg="length \{i + 1}",
    )
  }
}

///|
test "lexing matches pele on every string of up to four name pieces" {
  let expected = ["b44aa0c2", "94f27868", "0802cc84", "217b231e"]
  for i, hash in expected {
    let pieces = [
      "title", "accTitle", "accDescr", "a", " ", "-", ">", "\t", "(", "1", ":", "{",
      "}",
    ]
    assert_eq(
      fnv1a(strings_over(pieces, i + 1).map(lex).join("\n")),
      hash,
      msg="length \{i + 1}",
    )
  }
}

///|
test "lexing matches pele on every string of up to three word pieces" {
  let expected = ["46f97c73", "74332904", "70faed8b"]
  for i, hash in expected {
    let pieces = [
      "component", "s", "buy", "build", "note", "evolve", "evolution", "anchor",
      " ", "0", ".", "5", "_",
    ]
    assert_eq(
      fnv1a(strings_over(pieces, i + 1).map(lex).join("\n")),
      hash,
      msg="length \{i + 1}",
    )
  }
}
