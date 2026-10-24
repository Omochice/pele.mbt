///|
/// Quotes text the way the expected dumps were written: backslashes, double quotes and line breaks escaped.
fn quote(text : String) -> String {
  let out = StringBuilder()
  out.write_char('"')
  for c in text {
    match c {
      '\\' => out.write_string("\\\\")
      '"' => out.write_string("\\\"")
      '\n' => out.write_string("\\n")
      _ => out.write_char(c)
    }
  }
  out.write_char('"')
  out.to_string()
}

///|
/// Records the calls the outline parser makes, one line each.
struct Recorder {
  lines : Array[String]
}

///|
impl @common.OutlineDb for Recorder with fn add_node(
  self,
  level,
  id,
  descr,
  node_type,
  shape_data,
) {
  let data = match shape_data {
    Some(data) => quote(data)
    None => "-"
  }
  self.lines.push(
    "node \{level} \{quote(id)} \{quote(descr)} \{node_type} \{data}",
  )
}

///|
impl @common.OutlineDb for Recorder with fn decorate_node(self, decoration) {
  match decoration {
    Icon(icon) => self.lines.push("icon \{quote(icon)}")
    Class(class) => self.lines.push("class \{quote(class)}")
  }
}

///|
/// Every token as name, text and start, then every call into the model, then `ok` or the error message.
fn dump_outline(src : String, kanban : Bool) -> String {
  let tokens = @common.tokenize_outline(src, kanban)
  let lines = []
  for i, kind in tokens.types {
    lines.push(
      "\{kind.name(kanban)} \{quote(tokens.texts[i])} \{tokens.starts[i]}",
    )
  }
  let recorder = { lines, }
  try @common.parse_outline(src, recorder, kanban) catch {
    PeleError(failure) => lines.push("error " + quote(failure.message))
  } noraise {
    _ => lines.push("ok")
  }
  lines.join("\n")
}

///|
test "tokenize_outline and parse_outline read a mindmap's nodes and decorations" {
  inspect(
    dump_outline(
      "mindmap\n  root((the root))\n    child[Child]\n    ::icon(fa fa-book)\n    :::urgent large",
      false,
    ),
    content=(
      #|MINDMAP "mindmap" 0
      #|NL "\n" 7
      #|SPACELIST "  " 8
      #|NODE_ID "root" 10
      #|NODE_DSTART "((" 14
      #|NODE_DESCR "the root" 16
      #|NODE_DEND "))" 24
      #|NL "\n" 26
      #|SPACELIST "    " 27
      #|NODE_ID "child" 31
      #|NODE_DSTART "[" 36
      #|NODE_DESCR "Child" 37
      #|NODE_DEND "]" 42
      #|NL "\n" 43
      #|SPACELIST "    " 44
      #|ICON "fa fa-book" 55
      #|NL "\n" 66
      #|SPACELIST "    " 67
      #|CLASS "urgent large" 74
      #|EOF "" 86
      #|1 "" 86
      #|node 2 "root" "the root" 3 -
      #|node 4 "child" "Child" 2 -
      #|icon "fa fa-book"
      #|class "urgent large"
      #|ok
    ),
  )
}

///|
test "tokenize_outline reads kanban metadata, turning line breaks in its strings into <br/>" {
  inspect(
    dump_outline(
      "kanban\n  todo[Todo]\n    id1[Task]@{ ticket: MC-1, label: \"a\n  b\" }\n",
      true,
    ),
    content=(
      #|KANBAN "kanban" 0
      #|NL "\n" 6
      #|SPACELIST "  " 7
      #|NODE_ID "todo" 9
      #|NODE_DSTART "[" 13
      #|NODE_DESCR "Todo" 14
      #|NODE_DEND "]" 18
      #|NL "\n" 19
      #|SPACELIST "    " 20
      #|NODE_ID "id1" 24
      #|NODE_DSTART "[" 27
      #|NODE_DESCR "Task" 28
      #|NODE_DEND "]" 32
      #|SHAPE_DATA "" 33
      #|SHAPE_DATA " ticket: MC-1, label: " 35
      #|SHAPE_DATA "\"" 57
      #|SHAPE_DATA "a<br/>b" 58
      #|SHAPE_DATA "\"" 63
      #|SHAPE_DATA " " 64
      #|NL "\n" 66
      #|EOF "" 67
      #|1 "" 67
      #|node 2 "todo" "Todo" 2 -
      #|node 4 "id1" "Task" 2 " ticket: MC-1, label: \"a<br/>b\" "
      #|ok
    ),
  )
}

///|
test "parse_outline reports errors where the generated parser would" {
  inspect(
    dump_outline("mindmap\n  a\n  {", false),
    content=(
      #|MINDMAP "mindmap" 0
      #|NL "\n" 7
      #|SPACELIST "  " 8
      #|NODE_ID "a" 10
      #|NL "\n" 11
      #|SPACELIST "  " 12
      #|INVALID "" 14
      #|node 2 "a" "a" 0 -
      #|error "Lexical error on line 3. Unrecognized text.\n  {\n--^"
    ),
  )
  inspect(
    dump_outline("mindmap\nroot\n  a[b", false),
    content=(
      #|MINDMAP "mindmap" 0
      #|NL "\n" 7
      #|NODE_ID "root" 8
      #|NL "\n" 12
      #|SPACELIST "  " 13
      #|NODE_ID "a" 15
      #|NODE_DSTART "[" 16
      #|NODE_DESCR "b" 17
      #|1 "" 18
      #|node 0 "root" "root" 0 -
      #|error "Parse error on line 3:\n  a[b\n-----^\nExpecting 'NODE_DEND', got '1'"
    ),
  )
  inspect(
    dump_outline("root", false),
    content=(
      #|NODE_ID "root" 0
      #|EOF "" 4
      #|1 "" 4
      #|error "Parse error on line 1:\nroot\n^\nExpecting 'SPACELINE', 'MINDMAP', got 'NODE_ID'"
    ),
  )
}

///|
test "outline_node_type pairs any opening delimiter with any closing one" {
  let cases = [
    ("[", ")", @common.NODE_TYPE_RECT),
    ("(", ")", @common.NODE_TYPE_ROUNDED_RECT),
    ("(", "]", @common.NODE_TYPE_CLOUD),
    ("((", "]", @common.NODE_TYPE_CIRCLE),
    (")", "(", @common.NODE_TYPE_CLOUD),
    ("))", "((", @common.NODE_TYPE_BANG),
    ("{{", "}}", @common.NODE_TYPE_HEXAGON),
    ("-)", "(-", @common.NODE_TYPE_DEFAULT),
  ]
  for case in cases {
    let (start, end, expected) = case
    assert_eq(@common.outline_node_type(start, end), expected, msg=start + end)
  }
}

///|
/// pele's tests/support/corpus.ts random: a linear congruential generator returning values in [0, 1).
struct Random {
  mut state : UInt32
}

///|
fn Random::next(self : Random) -> Double {
  self.state = self.state * 1664525U + 1013904223U
  self.state.to_double() / 4294967296.0
}

///|
fn Random::below(self : Random, count : Int32) -> Int32 {
  (self.next() * count.to_double()).floor().to_int()
}

///|
/// pele's tests/support/corpus.ts mutator: a corpus source with one to three random edits.
fn mutate(
  corpus : Array[String],
  fragments : Array[String],
  rnd : Random,
) -> String {
  let mut s = corpus[rnd.below(corpus.length())]
  let edits = 1 + rnd.below(3)
  for _ in 0..<edits {
    let pos = rnd.below(s.length() + 1)
    let r = rnd.next()
    let head = @util.slice(s, 0, end=pos)
    if r < 0.35 {
      s = head + fragments[rnd.below(fragments.length())] + @util.slice(s, pos)
    } else if r < 0.6 {
      s = head + @util.slice(s, pos + 1 + rnd.below(3))
    } else if r < 0.75 {
      let other = corpus[rnd.below(corpus.length())]
      let from = rnd.below(other.length())
      let piece = @util.slice(other, from, end=from + rnd.below(20))
      s = head + piece + @util.slice(s, pos)
    } else if r < 0.9 {
      s = head +
        @util.slice(s, pos, end=pos + rnd.below(6)) +
        @util.slice(s, pos)
    } else {
      s = head +
        fragments[rnd.below(fragments.length())] +
        @util.slice(s, pos + 1)
    }
  }
  s
}

///|
/// Checks the corpus and the same 5000 mutations as pele's oracle test, seed 7, against pele's dumps in hundreds.
fn check_outline_corpus(
  corpus : Array[String],
  fragments : Array[String],
  kanban : Bool,
  expected : (Int32, Array[String]),
) -> Unit raise Error {
  let inputs = corpus.copy()
  let rnd = { state: 7, }
  for _ in 0..<5000 {
    let src = mutate(corpus, fragments, rnd)
    if src.length() <= 4000 {
      inputs.push(src)
    }
  }
  let (count, hashes) = expected
  assert_eq(inputs.length(), count)
  for k, hash in hashes {
    let end = if k * 100 + 100 < count { k * 100 + 100 } else { count }
    let dumps = inputs[k * 100:end].map(src => dump_outline(src, kanban))
    assert_eq(fnv1a(dumps.join("\n\n")), hash, msg="inputs from \{k * 100}")
  }
}

///|
test "the outline tokenizer and parser match pele on the mindmap corpus and its mutations" {
  check_outline_corpus(
    mindmap_corpus, mindmap_fragments, false, mindmap_expected,
  )
}

///|
test "the outline tokenizer and parser match pele on the kanban corpus and its mutations" {
  check_outline_corpus(kanban_corpus, kanban_fragments, true, kanban_expected)
}
