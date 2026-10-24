///|
test "indented sources, as Mermaid's parser specs write them, are read" {
  inspect(
    rules(
      "\n        railroad-beta\n        rule = terminal(\"hello\") ;\n      ",
    ),
    content="rule = \"hello\"",
  )
  inspect(
    rules(
      "\n        railroad-ebnf-beta\n        a = b | c ;\n        d = { a } ;\n      ",
    ),
    content="a = (<b> | <c>); d = {<a>}0..Infinity",
  )
}

///|
test "a collapsed single element keeps the node type of its member" {
  inspect(
    rules("railroad-beta\nrule = sequence(terminal(\"a\")) ;"),
    content="rule = \"a\"",
  )
  inspect(
    rules("railroad-beta\nrule = choice(terminal(\"a\")) ;"),
    content="rule = \"a\"",
  )
}

///|
test "carriage returns end lines like line feeds" {
  inspect(
    rules("railroad-ebnf-beta\r\ntitle T\r\na = b ;\r\nc = d ;"),
    content="a = <b>; c = <d>",
  )
}

///|
test "a name defined twice is kept twice in order" {
  inspect(
    rules("railroad-peg-beta\nA <- a ;\nA <- b ;"),
    content="A = <a>; A = <b>",
  )
}

///|
test "a diagram with only a keyword has no rules" {
  inspect(rules("railroad-peg-beta"), content="")
}
