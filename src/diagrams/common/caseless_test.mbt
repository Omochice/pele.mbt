///|
test "word_at folds only ASCII letters, as a regex's i flag without u" {
  let cases : Array[(String, Int32, String, Bool)] = [
    ("MindMap", 0, "mindmap", true),
    ("xMINDMAP", 1, "mindmap", true),
    ("mind", 0, "mindmap", false),
    ("", 0, "", true),
    ("abc", 3, "", true),
    ("ABC", 0, "abd", false),
    ("@", 0, "`", false),
    ("`", 0, "@", false),
    ("[", 0, "{", false),
    ("K", 0, "k", true),
    ("\u{212a}", 0, "k", false),
    ("a", -1, "a", false),
  ]
  for case in cases {
    let (src, at, word, expected) = case
    assert_eq(
      @common.word_at(src, at, word),
      expected,
      msg="\{src} \{at} \{word}",
    )
  }
}

///|
test "word_at matches pele for every code unit against every ASCII word character" {
  let bits = StringBuilder()
  let mut matched = 0
  for w in 0..<128 {
    let word = String::from_array([w.unsafe_to_char()])
    for c in 0..<65536 {
      let src = String::from_array([c.unsafe_to_char()])
      let hit = @common.word_at(src, 0, word)
      bits.write_char(if hit { '1' } else { '0' })
      if hit {
        matched += 1
      }
    }
    let hit = @common.word_at("", 0, word)
    bits.write_char(if hit { '1' } else { '0' })
    if hit {
      matched += 1
    }
  }
  assert_eq(matched, 154)
  assert_eq(fnv1a(bits.to_string()), "bedc34dd")
}
