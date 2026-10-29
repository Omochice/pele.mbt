///|
test "a classDef statement keeps its declarations as written" {
  inspect(
    parse("treemap\nclassDef myClass fill:red;"),
    content="D myClass \"fill:red\"",
  )
  inspect(
    parse("treemap\nclassDef myClass fill:red"),
    content="D myClass \"fill:red\"",
  )
  inspect(
    parse(
      "treemap\nclassDef complexClass fill:blue stroke:#ff0000 stroke-width:2px",
    ),
    content="D complexClass \"fill:blue stroke:#ff0000 stroke-width:2px\"",
  )
  inspect(parse("treemap\nclassDef myClass"), content="D myClass")
}

///|
test "a classDef statement may be indented and followed by blank lines" {
  inspect(
    parse("treemap\n  classDef myClass fill:red\n\"a\": 1"),
    content="@2 D myClass \"fill:red\"; L \"a\" 1",
  )
  inspect(
    parse("treemap\nclassDef myClass fill:red;\n\n\"a\": 1"),
    content="D myClass \"fill:red\"; L \"a\" 1",
  )
}

///|
test "a classDef name with no declarations takes the next line as its declarations" {
  inspect(
    parse("treemap\n\"a\": 1\nclassDef myClass\n\n   \"b\": 2"),
    content="L \"a\" 1; D myClass \"\\\"b\\\": 2\"",
  )
}

///|
test "a class name needs two characters" {
  inspect(
    parse("treemap\nclassDef a fill:red"),
    content="error: Parse error on line 2:\nclassDef a fill:red\n^\nExpecting a node, a class definition, or a title but found `classDef`.",
  )
}

///|
test "a class statement is not part of the treemap grammar" {
  inspect(
    parse("treemap\nclass myNode myClass"),
    content="error: Parse error on line 2:\nclass myNode myClass\n^\nExpecting a node, a class definition, or a title but found `class`.",
  )
}

///|
test "a section or a leaf takes a class with three colons" {
  inspect(
    parse("treemap\n\"My Section\":::sectionClass"),
    content="S \"My Section\" :::sectionClass",
  )
  inspect(
    parse("treemap\n\"My Leaf\" : 100:::leafClass"),
    content="L \"My Leaf\" 100 :::leafClass",
  )
  inspect(
    parse("treemap\n\"s\":::c1\n  \"a\": 1:::c1"),
    content="S \"s\" :::c1; @2 L \"a\" 1 :::c1",
  )
}

///|
test "a class name may start with title" {
  inspect(
    parse(
      "treemap\nclassDef titles fill:red\nclassDef title_2 fill:blue\n\"A\":::titles\n  \"B\": 1:::title_2",
    ),
    content="D titles \"fill:red\"; D title_2 \"fill:blue\"; S \"A\" :::titles; @2 L \"B\" 1 :::title_2",
  )
  inspect(
    parse("treemap\n\"A\":::title"),
    content="error: Parse error on line 2:\n\"A\":::title\n------^\nExpecting token of type 'ID2' but found `title`.",
  )
}

///|
test "text that is not a row is reported with the token that was expected" {
  inspect(
    parse("\"a\": 1"),
    content="error: Parse error on line 1:\n\"a\": 1\n^\nExpecting token of type 'TREEMAP_KEYWORD' but found `\"a\"`.",
  )
  inspect(
    parse("  treemap"),
    content="error: Parse error on line 1:\n  treemap\n^\nExpecting token of type 'TREEMAP_KEYWORD' but found `  `.",
  )
  inspect(
    parse("treemap\n\"a\": "),
    content="error: Parse error on line 2:\n\"a\": \n----^\nExpecting token of type 'NUMBER2' but found end of input.",
  )
  inspect(
    parse("treemap\n\"a\": x"),
    content="error: Parse error on line 2:\n\"a\": x\n-----^\nExpecting token of type 'NUMBER2' but found `x`.",
  )
  inspect(
    parse("treemap\n\"a\" 5"),
    content="error: Parse error on line 2:\n\"a\" 5\n----^\nExpecting token of type 'STRING2' but found `5`.",
  )
  inspect(
    parse("treemap\n\"a\":::"),
    content="error: Parse error on line 2:\n\"a\":::\n------^\nExpecting token of type 'ID2' but found end of input.",
  )
  inspect(
    parse("treemap\n\"a\": 1:::1x"),
    content="error: Parse error on line 2:\n\"a\": 1:::1x\n---------^\nExpecting token of type 'ID2' but found `1`.",
  )
}

///|
test "a comment after a row leaves blanks that no row follows" {
  inspect(
    parse("treemap\n\"a\": 1 %% note"),
    content="error: Parse error on line 2:\n\"a\": 1 %% note\n------^\nExpecting token of type 'STRING2' but found end of input.",
  )
}

///|
test "text no token matches is a lexical error" {
  inspect(
    parse("treemap\n\"unterminated"),
    content="error: Lexical error on line 2. Unrecognized text.\n\"unterminated\n^",
  )
  inspect(
    parse("treemap\n@"),
    content="error: Lexical error on line 2. Unrecognized text.\n@\n^",
  )
  inspect(
    parse("treemap\n\"a\": 1\rb"),
    content="error: Lexical error on line 2. Unrecognized text.\n\"a\": 1\rb\n------^",
  )
  inspect(
    parse("treemap\n\"tab\\\"x\": 1"),
    content="error: Lexical error on line 2. Unrecognized text.\n\"tab\\\"x\": 1\n-------^",
  )
}
