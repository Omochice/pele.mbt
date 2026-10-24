///|
/// The tokens `types` makes of `src`, as type@start-end.
fn lexed(src : String, types : Array[@common.TokenType]) -> String {
  let tokens = @common.tokenize(src, types, "test") catch {
    _ => return "error"
  }
  let out = []
  for i, kind in tokens.kinds {
    out.push("\{kind}@\{tokens.starts[i]}-\{tokens.ends[i]}")
  }
  out.join(" ")
}

///|
/// A lexer where `accDescr` is also a name, so lexing goes on after an `accDescr {` that never closes.
fn lexer(acc_descr : @common.TokenType) -> Array[@common.TokenType] {
  [
    acc_descr,
    @common.literal("{", "{"),
    @common.literal("}", "}"),
    @common.pattern("NAME", (src, p) => {
      let mut i = p
      while @util.is_letter(@util.code_at(src, i)) {
        i += 1
      }
      if i > p {
        i
      } else {
        @common.NO_MATCH
      }
    }),
    @common.newline,
    @common.whitespace,
  ]
}

///|
test "resumable_acc_descr matches what acc_descr matches" {
  let sources = [
    "accDescr: one line", "accDescr {\n many\n lines\n}", "  accDescr:x %% c", "accDescr\n{x}",
    "accDescr {\naccDescr {\nx", "accDescr {\naccDescr {\n}", "accDescr\nx", "accDescr: a\naccDescr {b}\naccDescr {",
  ]
  for src in sources {
    assert_eq(
      lexed(src, lexer(@common.resumable_acc_descr)),
      lexed(src, lexer(@common.acc_descr)),
      msg=src,
    )
  }
}

///|
test "resumable_acc_descr lexes many unclosed descriptions" {
  let src = "accDescr {\n".repeat(20000)
  let tokens = @common.tokenize(src, lexer(@common.resumable_acc_descr), "test")
  inspect(tokens.kinds.length(), content="60001")
}
