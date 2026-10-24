///|
fn optional(value : String?) -> String {
  match value {
    Some(text) => text.escape()
    None => "-"
  }
}

///|
fn ast(source : String) -> String {
  let ast = @info.parse_info(source) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "title=\{optional(ast.title)} accTitle=\{optional(ast.acc_title)} accDescr=\{optional(ast.acc_descr)}"
}

///|
test "an empty info is accepted with any surrounding line breaks" {
  let empty = "title=- accTitle=- accDescr=-"
  inspect(ast("info"), content=empty)
  inspect(ast("\n    info"), content=empty)
  inspect(ast("info\n    "), content=empty)
  inspect(ast("\n    info\n    "), content=empty)
}

///|
test "showInfo is accepted on the same line or after line breaks" {
  let empty = "title=- accTitle=- accDescr=-"
  inspect(ast("info showInfo"), content=empty)
  inspect(ast("info showInfo\n    "), content=empty)
  inspect(ast("\n    info showInfo"), content=empty)
  inspect(ast("info\n    showInfo"), content=empty)
  inspect(ast("info\n    showInfo\n    "), content=empty)
  inspect(ast("\n    info\n    showInfo\n    "), content=empty)
  inspect(ast("\n    info showInfo\n    "), content=empty)
}

///|
test "a title and accessibility statements are read" {
  inspect(
    ast("info showInfo title x\n\n"),
    content="title=\"x\" accTitle=- accDescr=-",
  )
  inspect(
    ast("info\ntitle x\naccTitle: a\naccDescr: d"),
    content="title=\"x\" accTitle=\"a\" accDescr=\"d\"",
  )
  inspect(
    ast("info\ntitle x\n\n\ntitle y"),
    content="title=\"y\" accTitle=- accDescr=-",
  )
  inspect(
    ast("info\naccDescr { a\n b }\n"),
    content="title=- accTitle=- accDescr=\"a\\nb\"",
  )
}

///|
test "front matter, directives, and comments are skipped" {
  inspect(
    ast("---\ntitle: x\n---\ninfo"),
    content="title=- accTitle=- accDescr=-",
  )
  inspect(
    ast("%%{init: {\"theme\":\"dark\"}}%%\ninfo showInfo %% c\n"),
    content="title=- accTitle=- accDescr=-",
  )
}

///|
test "unknown text is a lexical error" {
  inspect(
    ast("info unsupported"),
    content="Lexical error on line 1. Unrecognized text.\ninfo unsupported\n-----^",
  )
  inspect(
    ast("infox"),
    content="Lexical error on line 1. Unrecognized text.\ninfox\n^",
  )
}

///|
test "misplaced tokens are parse errors" {
  inspect(
    ast("info\ntitle a\nshowInfo"),
    content="Parse error on line 3:\nshowInfo\n^\nExpecting a title or the end of input but found `showInfo`.",
  )
  inspect(
    ast("info info"),
    content="Parse error on line 1:\ninfo info\n-----^\nExpecting a title or the end of input but found `info`.",
  )
}
