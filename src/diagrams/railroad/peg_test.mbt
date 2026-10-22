///|
test "PEG suffixes and choices are read" {
  inspect(
    peg("a? b* c+"),
    content="([<a>] {<b>}0..Infinity {<c>}1..Infinity)",
  )
  inspect(peg("a / \"b\" c"), content="(<a> | (\"b\" <c>))")
  inspect(peg("( ( a ) )"), content="<a>")
  inspect(peg("\"\\b\""), content="\"b\"")
}

///|
test "a predicate shows what it looks ahead for as special text" {
  inspect(peg("."), content="?.?")
  inspect(peg("&a"), content="?&a?")
  inspect(peg("!\"x\""), content="?!\"x\"?")
  inspect(peg("!."), content="?!.?")
  inspect(peg("!( a b )"), content="?!(...)?")
  inspect(peg("!a*"), content="?!(...)?")
  inspect(peg("&( a )"), content="?&a?")
  inspect(peg("( !a )+"), content="{?!a?}1..Infinity")
}

///|
test "comments run to the end of the line in PEG" {
  inspect(peg("a # to the end of the line\n b"), content="(<a> <b>)")
}

///|
test "PEG rejects what the grammar rejects" {
  inspect(
    failure("railroad-peg-beta\nR <- ;"),
    content="Parse error on line 2:\nR <- ;\n-----^\nExpecting a literal, a name, a dot, or an opening parenthesis but found `;`.",
  )
  inspect(
    failure("railroad-peg-beta\nR = a ;"),
    content="Lexical error on line 2. Unrecognized text.\nR = a ;\n--^",
  )
  inspect(
    failure("railroad-peg-beta\nR <- a ) ;"),
    content="Parse error on line 2:\nR <- a ) ;\n-------^\nExpecting token of type ';' but found `)`.",
  )
  inspect(
    failure("railroad-peg-beta\nR <- & ;"),
    content="Parse error on line 2:\nR <- & ;\n-------^\nExpecting a literal, a name, a dot, or an opening parenthesis but found `;`.",
  )
  inspect(
    failure("railroad-peg-beta\nR <- !&a ;"),
    content="Parse error on line 2:\nR <- !&a ;\n------^\nExpecting a literal, a name, a dot, or an opening parenthesis but found `&`.",
  )
  inspect(
    failure("railroad-peg-beta\nR <- a** ;"),
    content="Parse error on line 2:\nR <- a** ;\n-------^\nExpecting token of type ';' but found `*`.",
  )
  inspect(
    failure("railroad-peg-beta\nR <- ( a ;"),
    content="Parse error on line 2:\nR <- ( a ;\n---------^\nExpecting token of type ')' but found `;`.",
  )
  inspect(
    failure("railroad-peg-beta\nR <- a / ;"),
    content="Parse error on line 2:\nR <- a / ;\n---------^\nExpecting a literal, a name, a dot, or an opening parenthesis but found `;`.",
  )
}
