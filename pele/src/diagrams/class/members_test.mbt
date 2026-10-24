// Ported from pele v1.8.0, tests/class/members.test.ts.
// pele compares each split with Mermaid's backtracking regular expression; with no regex engine here, the splits of the same random inputs are compared through a hash of them, taken from that expression under node.

///|
/// FNV-1a over UTF-16 code units, as the expected hash was taken.
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
/// The seeded generator of pele's tests/support/corpus.ts.
fn random(seed : UInt32) -> () -> Double {
  let mut state = seed
  () => {
    state = state * 1664525U + 1013904223U
    state.to_double() / 4294967296.0
  }
}

///|
fn random_text(
  rnd : () -> Double,
  pieces : Array[String],
  max : Int32,
) -> String {
  let out = StringBuilder()
  let n = 1 + (rnd() * max.to_double()).floor().to_int()
  for _ in 0..<n {
    out.write_string(
      pieces[(rnd() * pieces.length().to_double()).floor().to_int()],
    )
  }
  out.to_string()
}

///|
test "splits methods as Mermaid does" {
  let pieces = [
    "(", ")", "()", "+", "-", "#", "~", "$", "*", " ", "  ", ":", ",", "a", "foo",
    "int", "List", "\r", "\n", "\u{2028}", "\t", "é",
  ]
  let rnd = random(11)
  let dump = StringBuilder()
  let mut matched = 0
  for _ in 0..<40000 {
    let input = random_text(rnd, pieces, 9)
    let parsed = @class.ClassMember::new(input, Method)
    if parsed.member_type is Attribute {
      dump.write_string("A\n")
      continue
    }
    matched += 1
    dump.write_string(
      "\{parsed.visibility}\t\{parsed.id}\t\{parsed.parameters}\t\{parsed.classifier}\t\{parsed.return_type}\n",
    )
  }
  inspect(matched, content="6103")
  inspect(fnv1a(dump.to_string()), content="c4613a0e")
}

///|
test "keeps a method with no opening parenthesis as an attribute" {
  // Mermaid throws a TypeError for these.
  for input in ["run)", "(a)", "+x)", ")(", "a)b"] {
    let parsed = @class.ClassMember::new(input, Method)
    assert_true(parsed.member_type is Attribute, msg=input)
    assert_eq(parsed.display_details().display_text, input)
  }
}

///|
test "reads visibility and classifiers of attributes" {
  let parsed = @class.ClassMember::new("-List~int~ items$", Attribute)
  inspect(parsed.visibility, content="-")
  inspect(parsed.classifier, content="$")
  let details = parsed.display_details()
  inspect(details.display_text, content="-List<int> items")
  inspect(details.css_style, content="text-decoration:underline;")
  inspect(
    @class.ClassMember::new("", Attribute).display_details().display_text,
    content="",
  )
}

///|
test "shows a method with its parameters and return type" {
  let parsed = @class.ClassMember::new("+get(List~T~ x)$ Map~K, V~", Method)
  inspect(parsed.visibility, content="+")
  inspect(parsed.id, content="get")
  inspect(parsed.parameters, content="List~T~ x")
  inspect(parsed.classifier, content="$")
  inspect(parsed.return_type, content="Map~K, V~")
  inspect(
    parsed.display_details().display_text,
    content="+get(List<T> x) : Map<K, V>",
  )
  let abstract_ = @class.ClassMember::new("draw() int*", Method)
  inspect(abstract_.classifier, content="*")
  inspect(abstract_.return_type, content="int")
  inspect(abstract_.display_details().css_style, content="font-style:italic;")
}
