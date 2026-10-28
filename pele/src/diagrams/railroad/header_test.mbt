///|
fn optional(value : String?) -> String {
  match value {
    Some(text) => text.escape()
    None => "-"
  }
}

///|
fn header(source : String, title? : String) -> String {
  let model = parse(source, title?) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "title=\{optional(model.title)} accTitle=\{optional(model.acc_title)} accDescr=\{optional(model.acc_descr)}"
}

///|
test "the title and accessibility statements are read" {
  inspect(
    header(
      "railroad-ebnf-beta\ntitle   \"A \\\"quoted\\\"\\ttitle\"   \naccTitle:   Acc   title\naccDescr: One   line\nr = a ;",
    ),
    content="title=\"A \\\"quoted\\\"\\ttitle\" accTitle=\"Acc title\" accDescr=\"One line\"",
  )
  inspect(
    header(
      "railroad-peg-beta\ntitle 'single'\naccDescr {\n   Two\n   lines\n}\nR <- a ;",
    ),
    content="title=\"single\" accTitle=- accDescr=\"Two\\nlines\"",
  )
  inspect(
    header("railroad-beta title Plain  title %% comment\nr = terminal(\"a\") ;"),
    content="title=\"Plain title\" accTitle=- accDescr=-",
  )
}

///|
test "an ABNF title loses its quotes but keeps its backslashes" {
  inspect(
    header("railroad-abnf-beta\ntitle \"a\\tb\"\nr = a ;"),
    content="title=\"a\\\\tb\" accTitle=- accDescr=-",
  )
}

///|
test "the last title wins and no title leaves none" {
  inspect(
    header("railroad-ebnf-beta\ntitle first\ntitle second\nr = a ;"),
    content="title=\"second\" accTitle=- accDescr=-",
  )
  inspect(
    header("railroad-ebnf-beta\nr = a ;"),
    content="title=- accTitle=- accDescr=-",
  )
}

///|
test "the diagram's own title wins over the front matter title" {
  inspect(
    header("railroad-ebnf-beta\nr = a ;", title="Front"),
    content="title=\"Front\" accTitle=- accDescr=-",
  )
  inspect(
    header("railroad-ebnf-beta\ntitle Own\nr = a ;", title="Front"),
    content="title=\"Own\" accTitle=- accDescr=-",
  )
  inspect(
    header("railroad-ebnf-beta\ntitle\nr = a ;", title="Front"),
    content="title=\"Front\" accTitle=- accDescr=-",
  )
}

///|
test "a rule name may start with title in each notation" {
  inspect(
    header("railroad-ebnf-beta\ntitles = a ;"),
    content="title=- accTitle=- accDescr=-",
  )
  inspect(rules("railroad-ebnf-beta\ntitles = a ;"), content="titles = <a>")
  inspect(
    rules(
      "railroad-beta\ntitles = nonterminal(\"title-x\") ;\ntitle-x = terminal(\"a\") ;",
    ),
    content="titles = <title-x>; title-x = \"a\"",
  )
  inspect(
    rules("railroad-ebnf-beta\ntitles = title-x ;\ntitle-x = \"a\" ;"),
    content="titles = <title-x>; title-x = \"a\"",
  )
  inspect(
    rules("railroad-abnf-beta\ntitles = title-x ;\ntitle-x = \"a\" ;"),
    content="titles = <title-x>; title-x = \"a\"",
  )
  inspect(
    rules("railroad-peg-beta\ntitles <- title-x ;\ntitle-x <- \"a\" ;"),
    content="titles = <title-x>; title-x = \"a\"",
  )
}

///|
test "each keyword selects its notation, in any case for detection" {
  let notation = fn(source : String) -> String {
    let model = parse(source) catch {
      @errors.PeleError(failure) => return failure.message
    }
    match model.notation {
      Railroad => "railroad"
      Ebnf => "ebnf"
      Abnf => "abnf"
      Peg => "peg"
    }
  }
  inspect(notation("railroad-beta"), content="railroad")
  inspect(notation("railroad-ebnf-beta"), content="ebnf")
  inspect(notation("railroad-abnf-beta"), content="abnf")
  inspect(notation("railroad-peg-beta"), content="peg")
  inspect(
    notation("RAILROAD-BETA\nr = terminal(\"a\") ;"),
    content="Parse error on line 1:\nRAILROAD-BETA\n^\nExpecting token of type 'railroad-beta' but found `RAILROAD-BETA`.",
  )
  inspect(
    notation("Railroad-EBNF-Beta\nr = \"a\" ;"),
    content="Parse error on line 1:\nRailroad-EBNF-Beta\n^\nExpecting token of type 'railroad-ebnf-beta' but found `Railroad-EBNF-Beta`.",
  )
  inspect(notation("pie"), content="No railroad diagram keyword found.")
}
