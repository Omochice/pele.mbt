///|
test "EBNF is read in the W3C and ISO styles" {
  inspect(ebnf("a b , c"), content="(<a> <b> <c>)")
  inspect(ebnf("a | \"b\" c"), content="(<a> | (\"b\" <c>))")
  inspect(ebnf("[ a ]"), content="[<a>]")
  inspect(ebnf("{ a | b }"), content="{(<a> | <b>)}0..Infinity")
  inspect(
    ebnf("a? b* c+"),
    content="([<a>] {<b>}0..Infinity {<c>}1..Infinity)",
  )
  inspect(ebnf("?  any character  ?"), content="?any character?")
  inspect(definition("railroad-ebnf-beta", "r ::= a ;"), content="<a>")
}

///|
test "a group of one is its only member" {
  inspect(ebnf("( ( a ) )"), content="<a>")
}

///|
test "EBNF strings decode escapes" {
  inspect(ebnf("'it\\'s'"), content="\"it's\"")
}

///|
test "postfix operators apply left to right to everything before them" {
  inspect(ebnf("a?*+"), content="{{[<a>]}0..Infinity}1..Infinity")
  inspect(ebnf("a - b"), content="(<a> \"-\" <b>)")
  inspect(ebnf("a - b - \"c\""), content="((<a> \"-\" <b>) \"-\" \"c\")")
  inspect(
    ebnf("a - ( b | c )*"),
    content="{(<a> \"-\" (<b> | <c>))}0..Infinity",
  )
  inspect(ebnf("a* - [ b ]"), content="({<a>}0..Infinity \"-\" [<b>])")
}

///|
test "a special sequence may start at any question mark that has a partner" {
  inspect(ebnf("a? b?"), content="(<a> ?b?)")
  inspect(
    rules("railroad-ebnf-beta\nr = a? ;\nq = b? ;"),
    content="r = [<a>]; q = [<b>]",
  )
}

///|
test "comments are skipped in EBNF" {
  inspect(ebnf("a (* iso *) /* w3c */ b"), content="(<a> <b>)")
}

///|
test "EBNF rejects what the grammar rejects" {
  inspect(
    failure("railroad-ebnf-beta\nr = ;"),
    content="Parse error on line 2:\nr = ;\n----^\nExpecting a terminal, a name, or an opening bracket but found `;`.",
  )
  inspect(
    failure("railroad-ebnf-beta\nr = a"),
    content="Parse error on line 3:\n\n^\nExpecting token of type ';' but found end of input.",
  )
  inspect(
    failure("railroad-ebnf-beta\nr = ( ) ;"),
    content="Parse error on line 2:\nr = ( ) ;\n------^\nExpecting a terminal, a name, or an opening bracket but found `)`.",
  )
  inspect(
    failure("railroad-ebnf-beta\nr = a | ;"),
    content="Parse error on line 2:\nr = a | ;\n--------^\nExpecting a terminal, a name, or an opening bracket but found `;`.",
  )
  inspect(
    failure("railroad-ebnf-beta\nr = a , ;"),
    content="Parse error on line 2:\nr = a , ;\n--------^\nExpecting a terminal, a name, or an opening bracket but found `;`.",
  )
  inspect(
    failure("railroad-ebnf-beta\nr = [ a ) ;"),
    content="Parse error on line 2:\nr = [ a ) ;\n--------^\nExpecting token of type ']' but found `)`.",
  )
  inspect(
    failure("railroad-ebnf-beta\nr = a - ;"),
    content="Parse error on line 2:\nr = a - ;\n--------^\nExpecting a terminal, a name, or an opening bracket but found `;`.",
  )
  inspect(
    failure("railroad-ebnf-beta\nr = ( a ;"),
    content="Parse error on line 2:\nr = ( a ;\n--------^\nExpecting token of type ')' but found `;`.",
  )
  inspect(
    failure("railroad-ebnf-beta\nr = a (*) b ;"),
    content="Parse error on line 2:\nr = a (*) b ;\n-------^\nExpecting a terminal, a name, or an opening bracket but found `*`.",
  )
  inspect(
    failure("railroad-ebnf-beta\nr = a ;\ntitle Late"),
    content="Parse error on line 3:\ntitle Late\n^\nExpecting token of type 'EBNF_ID' but found `title Late`.",
  )
  inspect(
    failure("railroad-ebnf-beta\nr = title ;"),
    content="Parse error on line 2:\nr = title ;\n----^\nExpecting a terminal, a name, or an opening bracket but found `title ;`.",
  )
  inspect(failure("railroad-ebnf-beta\nr = a ? ;"), content="accepted")
}
