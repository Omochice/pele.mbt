///|
test "the constructor notation builds one node per call" {
  inspect(ir("terminal(\"a\")"), content="\"a\"")
  inspect(ir("nonterminal('b')"), content="<b>")
  inspect(ir("special(\"any character\")"), content="?any character?")
  inspect(
    ir("sequence(terminal(\"a\"), nonterminal(\"b\"))"),
    content="(\"a\" <b>)",
  )
  inspect(
    ir("choice(terminal(\"a\"), nonterminal(\"b\"), special(\"c\"))"),
    content="(\"a\" | <b> | ?c?)",
  )
  inspect(ir("optional(terminal(\"a\"))"), content="[\"a\"]")
  inspect(ir("oneOrMore(terminal(\"a\"))"), content="{\"a\"}1..Infinity")
  inspect(ir("zeroOrMore(terminal(\"a\"))"), content="{\"a\"}0..Infinity")
}

///|
test "a sequence or choice of one is its only member" {
  inspect(ir("sequence(choice(sequence(terminal(\"a\"))))"), content="\"a\"")
  inspect(ir("optional(choice(terminal(\"a\")))"), content="[\"a\"]")
}

///|
test "three escapes are decoded and any other escaped character stands for itself" {
  inspect(
    ir("terminal(\"a\\nb\\tc\\rd\")"),
    content="\"a\\nb\\tc\\rd\"",
  )
  inspect(ir("terminal(\"\\\"\\\\\\x\\0\")"), content="\"\\\"\\\\x0\"")
}

///|
test "comments are skipped" {
  inspect(ir("/* c */ terminal(\"a\") /* d */"), content="\"a\"")
}

///|
test "a keyword is a keyword only when it stands alone" {
  inspect(
    rules("railroad-beta\nterminals = nonterminal(\"choice\") ;"),
    content="terminals = <choice>",
  )
  inspect(
    failure("railroad-beta\nterminal = terminal(\"a\") ;"),
    content="Parse error on line 2:\nterminal = terminal(\"a\") ;\n^\nExpecting token of type 'RR_ID' but found `terminal`.",
  )
  inspect(
    failure("railroad-beta-x\nr = terminal(\"a\") ;"),
    content="Parse error on line 1:\nrailroad-beta-x\n^\nExpecting token of type 'railroad-beta' but found `railroad-beta-x`.",
  )
}

///|
test "the constructor notation rejects what Mermaid's grammar rejects" {
  inspect(
    failure("railroad-beta\nr = sequence() ;"),
    content="Parse error on line 2:\nr = sequence() ;\n-------------^\nExpecting an expression but found `)`.",
  )
  inspect(
    failure("railroad-beta\nr = optional(terminal(\"a\"), terminal(\"b\")) ;"),
    content="Parse error on line 2:\nr = optional(terminal(\"a\"), terminal(\"b\")) ;\n--------------------------^\nExpecting token of type ')' but found `,`.",
  )
  inspect(
    failure("railroad-beta\nr = terminal(a) ;"),
    content="Parse error on line 2:\nr = terminal(a) ;\n-------------^\nExpecting token of type 'RR_STRING' but found `a`.",
  )
  inspect(
    failure("railroad-beta\nr = terminal(\"unclosed) ;"),
    content="Lexical error on line 2. Unrecognized text.\nr = terminal(\"unclosed) ;\n-------------^",
  )
}

///|
test "rules keep their order and a name defined twice appears twice" {
  inspect(
    rules("railroad-beta\nr = terminal(\"a\") ;\nr = terminal(\"b\") ;"),
    content="r = \"a\"; r = \"b\"",
  )
  inspect(rules("railroad-beta"), content="")
}
