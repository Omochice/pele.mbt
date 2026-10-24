///|
fn model(source : String) -> String {
  let built = @cynefin.build_cynefin(
    @cynefin.parse_cynefin(source) catch {
      @errors.PeleError(failure) => return failure.message
    },
    Some("front"),
  )
  let domains = []
  for name, items in built.domains {
    domains.push("\{name}[\{items.join(",")}]")
  }
  let transitions = built.transitions.map(t => {
    "\{t.from}>\{t.to}:\{t.label.unwrap_or("-")}"
  })
  "title=\{built.title.unwrap_or("-")} accTitle=\{built.acc_title.unwrap_or("-")} accDescr=\{built.acc_descr.unwrap_or("-")} domains=\{domains.join(";")} transitions=\{transitions.join(",")}"
}

///|
test "the front matter title is used when the diagram has none" {
  inspect(
    model("cynefin-beta"),
    content="title=front accTitle=- accDescr=- domains= transitions=",
  )
  inspect(
    model("cynefin-beta\ntitle Own"),
    content="title=Own accTitle=- accDescr=- domains= transitions=",
  )
  inspect(
    model("cynefin-beta\ntitle"),
    content="title=front accTitle=- accDescr=- domains= transitions=",
  )
}

///|
test "the last block of a domain wins and keeps the first position" {
  inspect(
    model("cynefin-beta\ncomplex\n\"first\"\nclear\n\"c\"\ncomplex\n\"second\""),
    content="title=front accTitle=- accDescr=- domains=complex[second];clear[c] transitions=",
  )
}

///|
test "self loops are dropped and an empty label means none" {
  inspect(
    model(
      "cynefin-beta\ncomplex --> clear : \"x\"\nchaotic --> complex\nclear --> clear : \"ignored\"\nconfusion --> chaotic : \"\"",
    ),
    content="title=front accTitle=- accDescr=- domains= transitions=complex>clear:x,chaotic>complex:-,confusion>chaotic:-",
  )
}

///|
test "accessible texts lose their leading blanks" {
  inspect(
    model(
      "cynefin-beta\naccTitle:   at\naccDescr {\n  first\n    second\n}\ncomplex",
    ),
    content="title=front accTitle=at accDescr=first\nsecond domains=complex[] transitions=",
  )
}
