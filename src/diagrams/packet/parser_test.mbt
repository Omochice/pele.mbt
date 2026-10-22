///|
fn optional(value : String?) -> String {
  match value {
    Some(text) => text.escape()
    None => "-"
  }
}

///|
fn number(value : Double?) -> String {
  match value {
    Some(n) => n.to_string()
    None => "-"
  }
}

///|
fn ast(source : String) -> String {
  let ast = @packet.parse_packet(source + "\n") catch {
    @errors.PeleError(failure) => return failure.message
  }
  let blocks = ast.blocks.map(b => {
    "\{number(b.start)}..\{number(b.end)}+\{number(b.bits)}=\{b.label.escape()}"
  })
  "title=\{optional(ast.title)} accTitle=\{optional(ast.acc_title)} accDescr=\{optional(ast.acc_descr)} blocks=\{blocks.join(",")}"
}

///|
test "a bare packet or packet-beta has no blocks" {
  inspect(ast("packet"), content="title=- accTitle=- accDescr=- blocks=")
  inspect(ast("packet-beta"), content="title=- accTitle=- accDescr=- blocks=")
  inspect(ast("\n\npacket"), content="title=- accTitle=- accDescr=- blocks=")
}

///|
test "ranges, single bits, and bit counts are read" {
  inspect(
    ast("packet\n0-10: \"test\"\n11: 'single'\n+8: \"byte\""),
    content="title=- accTitle=- accDescr=- blocks=0..10+-=\"test\",11..-+-=\"single\",-..-+8=\"byte\"",
  )
}

///|
test "a title and accessibility statements are read" {
  inspect(
    ast(
      "packet\n    title Packet diagram\n    accTitle: Packet accTitle\n    accDescr: Packet accDescription\n    0-10: \"test\"\n    ",
    ),
    content="title=\"Packet diagram\" accTitle=\"Packet accTitle\" accDescr=\"Packet accDescription\" blocks=0..10+-=\"test\"",
  )
  inspect(
    ast("packet title T\n0: \"a\" %% c"),
    content="title=\"T\" accTitle=- accDescr=- blocks=0..-+-=\"a\"",
  )
}

///|
test "front matter, directives, and comments are skipped" {
  inspect(
    ast("%%{init: {}}%%\npacket\n%% note\n0-3: \"a\""),
    content="title=- accTitle=- accDescr=- blocks=0..3+-=\"a\"",
  )
}

///|
test "a number is read as Number reads it" {
  inspect(
    ast("packet\n0-0: \"a\"\n+" + "9".repeat(400) + ": \"b\""),
    content="title=- accTitle=- accDescr=- blocks=0..0+-=\"a\",-..-+Infinity=\"b\"",
  )
}

///|
test "a digit run before a dot gives up its last digit" {
  inspect(
    ast("packet\n12.5: \"a\""),
    content="Lexical error on line 2. Unrecognized text.\n12.5: \"a\"\n-^",
  )
}

///|
test "a leading zero ends its number" {
  inspect(
    ast("packet\n05: \"a\""),
    content="Parse error on line 2:\n05: \"a\"\n-^\nExpecting token of type ':' but found `5`.",
  )
}

///|
test "malformed fields are rejected" {
  inspect(
    ast("packet\n0-: \"a\""),
    content="Parse error on line 2:\n0-: \"a\"\n--^\nExpecting token of type 'INT' but found `:`.",
  )
  inspect(
    ast("packet\nfoo"),
    content="Lexical error on line 2. Unrecognized text.\nfoo\n^",
  )
  inspect(
    ast("packet\n0: a"),
    content="Lexical error on line 2. Unrecognized text.\n0: a\n---^",
  )
  inspect(
    ast("packet\n---\n0: \"a\""),
    content="Parse error on line 2:\n---\n^\nExpecting a field, a title, or a line break but found `-`.",
  )
}

///|
test "spaces may surround the dash of a range" {
  inspect(
    ast("packet\n0 - 3: \"a\""),
    content="title=- accTitle=- accDescr=- blocks=0..3+-=\"a\"",
  )
}

///|
test "dashes that open front matter are skipped as front matter" {
  inspect(
    ast("packet\n0-1: \"a\"\n---\nx: 1\n---\n2: \"b\""),
    content="title=- accTitle=- accDescr=- blocks=0..1+-=\"a\",2..-+-=\"b\"",
  )
}
