///|
test "ABNF repeats are read" {
  inspect(abnf("*a"), content="{<a>}0..Infinity")
  inspect(abnf("1*a"), content="{<a>}1..Infinity")
  inspect(abnf("2*4a"), content="{<a>}2..4")
  inspect(abnf("*4a"), content="{<a>}0..4")
  inspect(abnf("3a"), content="{<a>}3..3")
  inspect(abnf("1a"), content="{<a>}1..1")
  inspect(abnf("007a"), content="{<a>}7..7")
  inspect(abnf("2*( a / b )"), content="{(<a> | <b>)}2..Infinity")
  inspect(abnf("3[ a ]"), content="{[<a>]}3..3")
}

///|
test "a repeat of nothing to one is an optional element" {
  inspect(abnf("0*1a"), content="[<a>]")
  inspect(abnf("*1\"a\""), content="[\"a\"]")
}

///|
test "a repeat count too large for a number is infinite" {
  inspect(abnf("9".repeat(400) + "a"), content="{<a>}Infinity..Infinity")
}

///|
test "ABNF values, groups, and alternation are read" {
  inspect(
    abnf("%x41 %d65.66 %b1000001 %x30-39"),
    content="(\"%x41\" \"%d65.66\" \"%b1000001\" \"%x30-39\")",
  )
  inspect(abnf("a / \"b\" c / [ d ]"), content="(<a> | (\"b\" <c>) | [<d>])")
  inspect(abnf("rule-name DIGIT"), content="(<rule-name> <DIGIT>)")
  inspect(abnf("( ( a ) )"), content="<a>")
}

///|
test "ABNF strings have no escapes" {
  inspect(abnf("\"a\\\" b"), content="(\"a\\\\\" <b>)")
}

///|
test "a rule ends only with a semicolon that ends its line" {
  inspect(
    rules(
      "railroad-abnf-beta\nr = a ; a comment, so the rule goes on\n  b ;\ns = c ;",
    ),
    content="r = (<a> <b>); s = <c>",
  )
}

///|
test "ABNF rejects what the grammar rejects" {
  inspect(
    failure("railroad-abnf-beta\nr = a /\n ;"),
    content="Parse error on line 3:\n ;\n-^\nExpecting a string, a number, a name, or an opening bracket but found `;`.",
  )
  inspect(
    failure("railroad-abnf-beta\nr = 2* ;"),
    content="Parse error on line 2:\nr = 2* ;\n-------^\nExpecting a string, a number, a name, or an opening bracket but found `;`.",
  )
  inspect(
    failure("railroad-abnf-beta\nr = a ; \n"),
    content="Parse error on line 2:\nr = a ; \n-------^\nExpecting token of type ';' but found end of input.",
  )
  inspect(
    failure("railroad-abnf-beta\nr = ( a ;"),
    content="Parse error on line 2:\nr = ( a ;\n--------^\nExpecting token of type ')' but found `;`.",
  )
  inspect(
    failure("railroad-abnf-beta\nr = [ a ) ;"),
    content="Parse error on line 2:\nr = [ a ) ;\n--------^\nExpecting token of type ']' but found `)`.",
  )
  inspect(
    failure("railroad-abnf-beta\nr = ;"),
    content="Parse error on line 2:\nr = ;\n----^\nExpecting a string, a number, a name, or an opening bracket but found `;`.",
  )
  inspect(
    failure("railroad-abnf-beta\nr = %x ;"),
    content="Lexical error on line 2. Unrecognized text.\nr = %x ;\n----^",
  )
  inspect(
    failure("railroad-abnf-beta\nr = \"a ;"),
    content="Lexical error on line 2. Unrecognized text.\nr = \"a ;\n----^",
  )
  inspect(
    failure("railroad-abnf-beta\nr = 3 ;"),
    content="Parse error on line 2:\nr = 3 ;\n------^\nExpecting a string, a number, a name, or an opening bracket but found `;`.",
  )
}
