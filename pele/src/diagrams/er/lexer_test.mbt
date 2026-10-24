// The expected streams were taken from pele's lexer.

///|
/// The token stream one per line, as `NAME@start "text"` with the text escaped.
fn lex(source : String) -> String {
  let tokens = @er.tokenize(source)
  let lines = []
  for i, kind in tokens.types {
    lines.push("\{kind.name()}@\{tokens.starts[i]} \{quote(tokens.texts[i])}")
  }
  lines.join("\n")
}

///|
fn quote(text : String) -> String {
  let out = StringBuilder()
  out.write_char('"')
  for c in text {
    match c {
      '\\' => out.write_string("\\\\")
      '"' => out.write_string("\\\"")
      '\n' => out.write_string("\\n")
      '\r' => out.write_string("\\r")
      '\t' => out.write_string("\\t")
      _ => out.write_char(c)
    }
  }
  out.write_char('"')
  out.to_string()
}

///|
test "reads a relationship and an attribute block" {
  inspect(
    lex("erDiagram\n  A ||--o{ B : has\n  A { int id PK \"c\" }"),
    content=(
      #|ER_DIAGRAM@0 "erDiagram"
      #|NEWLINE@9 "\n"
      #|UNICODE_TEXT@12 "A"
      #|ONLY_ONE@14 "||"
      #|IDENTIFYING@16 "--"
      #|ZERO_OR_MORE@18 "o{"
      #|UNICODE_TEXT@21 "B"
      #|COLON@23 ":"
      #|UNICODE_TEXT@25 "has"
      #|NEWLINE@28 "\n"
      #|UNICODE_TEXT@31 "A"
      #|BLOCK_START@33 "{"
      #|ATTRIBUTE_WORD@35 "int"
      #|ATTRIBUTE_WORD@39 "id"
      #|ATTRIBUTE_KEY@42 "PK"
      #|COMMENT@45 "\"c\""
      #|BLOCK_STOP@49 "}"
      #|EOF@50 ""
      #|$end@50 ""
    ),
  )
}

///|
test "reads the word forms of cardinalities and identification" {
  inspect(
    lex(
      "erDiagram\n A one or zero to one or more B : x\n C only one optionally to zero or many D : y\n E many(0) to many(1) F : z\n G 0+ to 1+ H : w\n I one to many J : v\n K one or many to zero or one L : u",
    ),
    content=(
      #|ER_DIAGRAM@0 "erDiagram"
      #|NEWLINE@9 "\n"
      #|UNICODE_TEXT@11 "A"
      #|ZERO_OR_ONE@13 "one or zero"
      #|IDENTIFYING@25 "to"
      #|ONE_OR_MORE@28 "one or more"
      #|UNICODE_TEXT@40 "B"
      #|COLON@42 ":"
      #|UNICODE_TEXT@44 "x"
      #|NEWLINE@45 "\n"
      #|UNICODE_TEXT@47 "C"
      #|ONLY_ONE@49 "only one"
      #|NON_IDENTIFYING@58 "optionally to"
      #|ZERO_OR_MORE@72 "zero or many"
      #|UNICODE_TEXT@85 "D"
      #|COLON@87 ":"
      #|UNICODE_TEXT@89 "y"
      #|NEWLINE@90 "\n"
      #|UNICODE_TEXT@92 "E"
      #|ZERO_OR_MORE@94 "many(0)"
      #|IDENTIFYING@102 "to"
      #|ONE_OR_MORE@105 "many(1)"
      #|UNICODE_TEXT@113 "F"
      #|COLON@115 ":"
      #|UNICODE_TEXT@117 "z"
      #|NEWLINE@118 "\n"
      #|UNICODE_TEXT@120 "G"
      #|ZERO_OR_MORE@122 "0+"
      #|IDENTIFYING@125 "to"
      #|ONE_OR_MORE@128 "1+"
      #|UNICODE_TEXT@131 "H"
      #|COLON@133 ":"
      #|UNICODE_TEXT@135 "w"
      #|NEWLINE@136 "\n"
      #|UNICODE_TEXT@138 "I"
      #|ONLY_ONE@140 "one"
      #|IDENTIFYING@144 "to"
      #|ZERO_OR_MORE@147 "many"
      #|UNICODE_TEXT@152 "J"
      #|COLON@154 ":"
      #|UNICODE_TEXT@156 "v"
      #|NEWLINE@157 "\n"
      #|UNICODE_TEXT@159 "K"
      #|ONE_OR_MORE@161 "one or many"
      #|IDENTIFYING@173 "to"
      #|ZERO_OR_ONE@176 "zero or one"
      #|UNICODE_TEXT@188 "L"
      #|COLON@190 ":"
      #|UNICODE_TEXT@192 "u"
      #|EOF@193 ""
      #|$end@193 ""
    ),
  )
}

///|
test "tells a 1 cardinality from a 1 entity and other numbers" {
  inspect(
    lex(
      "erDiagram\nCUSTOMER ||--|| 1 : has\n1 ||--o{ 12 : x\n1.5 { int a }\n1--1 : y\n1 \"q\" 1x 10 2.x",
    ),
    content=(
      #|ER_DIAGRAM@0 "erDiagram"
      #|NEWLINE@9 "\n"
      #|UNICODE_TEXT@10 "CUSTOMER"
      #|ONLY_ONE@19 "||"
      #|IDENTIFYING@21 "--"
      #|ONLY_ONE@23 "||"
      #|ENTITY_ONE@26 "1"
      #|COLON@28 ":"
      #|UNICODE_TEXT@30 "has"
      #|NEWLINE@33 "\n"
      #|ENTITY_ONE@34 "1"
      #|ONLY_ONE@36 "||"
      #|IDENTIFYING@38 "--"
      #|ZERO_OR_MORE@40 "o{"
      #|NUM@43 "12"
      #|COLON@46 ":"
      #|UNICODE_TEXT@48 "x"
      #|NEWLINE@49 "\n"
      #|DECIMAL_NUM@50 "1.5"
      #|BLOCK_START@54 "{"
      #|ATTRIBUTE_WORD@56 "int"
      #|ATTRIBUTE_WORD@60 "a"
      #|BLOCK_STOP@62 "}"
      #|NEWLINE@63 "\n"
      #|ONLY_ONE@64 "1"
      #|IDENTIFYING@65 "--"
      #|ENTITY_ONE@67 "1"
      #|COLON@69 ":"
      #|UNICODE_TEXT@71 "y"
      #|NEWLINE@72 "\n"
      #|ONLY_ONE@73 "1"
      #|ENTITY_NAME@75 "\"q\""
      #|NUM@79 "1"
      #|UNICODE_TEXT@80 "x"
      #|NUM@82 "10"
      #|NUM@85 "2"
      #|UNICODE_TEXT@86 ".x"
      #|EOF@88 ""
      #|$end@88 ""
    ),
  )
}

///|
test "reads the symbol forms of cardinalities and identification" {
  inspect(
    lex(
      "erDiagram\n A |o..o| B : x\n C }o--o{ D : y\n E }|..|{ F : z\n G u--|| H : w\n I ||.-|| J : v\n K ||-.|| L : t\n M |O--O| N : s\n uu u.",
    ),
    content=(
      #|ER_DIAGRAM@0 "erDiagram"
      #|NEWLINE@9 "\n"
      #|UNICODE_TEXT@11 "A"
      #|ZERO_OR_ONE@13 "|o"
      #|NON_IDENTIFYING@15 ".."
      #|ZERO_OR_ONE@17 "o|"
      #|UNICODE_TEXT@20 "B"
      #|COLON@22 ":"
      #|UNICODE_TEXT@24 "x"
      #|NEWLINE@25 "\n"
      #|UNICODE_TEXT@27 "C"
      #|ZERO_OR_MORE@29 "}o"
      #|IDENTIFYING@31 "--"
      #|ZERO_OR_MORE@33 "o{"
      #|UNICODE_TEXT@36 "D"
      #|COLON@38 ":"
      #|UNICODE_TEXT@40 "y"
      #|NEWLINE@41 "\n"
      #|UNICODE_TEXT@43 "E"
      #|ONE_OR_MORE@45 "}|"
      #|NON_IDENTIFYING@47 ".."
      #|ONE_OR_MORE@49 "|{"
      #|UNICODE_TEXT@52 "F"
      #|COLON@54 ":"
      #|UNICODE_TEXT@56 "z"
      #|NEWLINE@57 "\n"
      #|UNICODE_TEXT@59 "G"
      #|MD_PARENT@61 "u"
      #|IDENTIFYING@62 "--"
      #|ONLY_ONE@64 "||"
      #|UNICODE_TEXT@67 "H"
      #|COLON@69 ":"
      #|UNICODE_TEXT@71 "w"
      #|NEWLINE@72 "\n"
      #|UNICODE_TEXT@74 "I"
      #|ONLY_ONE@76 "||"
      #|NON_IDENTIFYING@78 ".-"
      #|ONLY_ONE@80 "||"
      #|UNICODE_TEXT@83 "J"
      #|COLON@85 ":"
      #|UNICODE_TEXT@87 "v"
      #|NEWLINE@88 "\n"
      #|UNICODE_TEXT@90 "K"
      #|ONLY_ONE@92 "||"
      #|NON_IDENTIFYING@94 "-."
      #|ONLY_ONE@96 "||"
      #|UNICODE_TEXT@99 "L"
      #|COLON@101 ":"
      #|UNICODE_TEXT@103 "t"
      #|NEWLINE@104 "\n"
      #|UNICODE_TEXT@106 "M"
      #|ZERO_OR_ONE@108 "|O"
      #|IDENTIFYING@110 "--"
      #|ZERO_OR_ONE@112 "O|"
      #|UNICODE_TEXT@115 "N"
      #|COLON@117 ":"
      #|UNICODE_TEXT@119 "s"
      #|NEWLINE@120 "\n"
      #|UNICODE_TEXT@122 "uu"
      #|MD_PARENT@125 "u"
      #|UNICODE_TEXT@126 "."
      #|EOF@127 ""
      #|$end@127 ""
    ),
  )
}

///|
test "reads quoted names, words and an unclosed quote" {
  inspect(
    lex("erDiagram\n \"a b\" ||--|| \"\" : \"role\"\n \"x%y\"\n \"unterminated"),
    content=(
      #|ER_DIAGRAM@0 "erDiagram"
      #|NEWLINE@9 "\n"
      #|ENTITY_NAME@11 "\"a b\""
      #|ONLY_ONE@17 "||"
      #|IDENTIFYING@19 "--"
      #|ONLY_ONE@21 "||"
      #|WORD@24 "\"\""
      #|COLON@27 ":"
      #|ENTITY_NAME@29 "\"role\""
      #|NEWLINE@35 "\n"
      #|WORD@37 "\"x%y\""
      #|NEWLINE@42 "\n"
      #|CHAR@44 "\""
      #|UNICODE_TEXT@45 "unterminated"
      #|EOF@57 ""
      #|$end@57 ""
    ),
  )
}

///|
test "lets a direction statement swallow its whole line" {
  inspect(
    lex(
      "erDiagram\n  direction LR\n  A direction TB B\n subgraph s\n direction\n\n rl\n end\n direction XX\n",
    ),
    content=(
      #|ER_DIAGRAM@0 "erDiagram"
      #|NEWLINE@9 "\n"
      #|direction_lr@10 "  direction LR"
      #|NEWLINE@24 "\n"
      #|direction_tb@25 "  A direction TB B"
      #|NEWLINE@43 "\n"
      #|SUBGRAPH@45 "subgraph"
      #|UNICODE_TEXT@54 "s"
      #|NEWLINE@55 "\n"
      #|direction_rl@56 " direction\n\n rl"
      #|NEWLINE@71 "\n"
      #|END@73 "end\n "
      #|UNICODE_TEXT@78 "direction"
      #|UNICODE_TEXT@88 "XX"
      #|NEWLINE@90 "\n"
      #|EOF@91 ""
      #|$end@91 ""
    ),
  )
}

///|
test "reads accessible titles and descriptions" {
  inspect(
    lex(
      "erDiagram\n accTitle : My title\n accDescr: d\n accDescr {\n multi\n line\n }\n A\n acctitle:",
    ),
    content=(
      #|ER_DIAGRAM@0 "erDiagram"
      #|NEWLINE@9 "\n"
      #|acc_title@11 "accTitle : "
      #|acc_title_value@22 "My title"
      #|NEWLINE@30 "\n"
      #|acc_descr@32 "accDescr: "
      #|acc_descr_value@42 "d"
      #|NEWLINE@43 "\n"
      #|acc_descr_multiline_value@57 "multi\n line\n "
      #|NEWLINE@71 "\n"
      #|UNICODE_TEXT@73 "A"
      #|NEWLINE@74 "\n"
      #|acc_title@76 "acctitle:"
      #|acc_title_value@85 ""
      #|$end@85 ""
    ),
  )
}

///|
test "reads style statements up to a character they do not allow" {
  inspect(
    lex(
      "erDiagram\n A:::hot,cold\n classDef hot fill:#f96,stroke:#333;\n style A fill:rgb(1,2,3)\n",
    ),
    content=(
      #|ER_DIAGRAM@0 "erDiagram"
      #|NEWLINE@9 "\n"
      #|UNICODE_TEXT@11 "A"
      #|STYLE_SEPARATOR@12 ":::"
      #|UNICODE_TEXT@15 "hot"
      #|COMMA@18 ","
      #|UNICODE_TEXT@19 "cold"
      #|NEWLINE@23 "\n"
      #|CLASSDEF@25 "classDef"
      #|STYLE_TEXT@34 "hot"
      #|STYLE_TEXT@38 "fill"
      #|COLON@42 ":"
      #|BRKT@43 "#"
      #|STYLE_TEXT@44 "f96"
      #|COMMA@47 ","
      #|STYLE_TEXT@48 "stroke"
      #|COLON@54 ":"
      #|BRKT@55 "#"
      #|STYLE_TEXT@56 "333"
      #|SEMI@59 ";"
      #|NEWLINE@60 "\n"
      #|STYLE@62 "style"
      #|STYLE_TEXT@68 "A"
      #|STYLE_TEXT@70 "fill"
      #|COLON@74 ":"
      #|STYLE_TEXT@75 "rgb"
      #|INVALID@78 ""
    ),
  )
}

///|
test "reads attribute words, keys, comments and backtick names" {
  inspect(
    lex(
      "erDiagram\n A {\n string(99) name PK, FK \"c\"\n List~int~ items\n `weird name` *id uk\n float? price\n µx Àb\n }",
    ),
    content=(
      #|ER_DIAGRAM@0 "erDiagram"
      #|NEWLINE@9 "\n"
      #|UNICODE_TEXT@11 "A"
      #|BLOCK_START@13 "{"
      #|ATTRIBUTE_WORD@16 "string(99)"
      #|ATTRIBUTE_WORD@27 "name"
      #|ATTRIBUTE_KEY@32 "PK"
      #|CHAR@34 ","
      #|ATTRIBUTE_KEY@36 "FK"
      #|COMMENT@39 "\"c\""
      #|ATTRIBUTE_WORD@44 "List~int~"
      #|ATTRIBUTE_WORD@54 "items"
      #|ATTRIBUTE_WORD@62 "weird name"
      #|ATTRIBUTE_WORD@74 "*id"
      #|ATTRIBUTE_KEY@78 "uk"
      #|ATTRIBUTE_WORD@82 "float"
      #|CHAR@87 "?"
      #|ATTRIBUTE_WORD@89 "price"
      #|ATTRIBUTE_WORD@96 "µx"
      #|ATTRIBUTE_WORD@99 "Àb"
      #|BLOCK_STOP@103 "}"
      #|EOF@104 ""
      #|$end@104 ""
    ),
  )
}

///|
test "reads a generic type through the last tilde of its line" {
  inspect(
    lex("erDiagram\nA {\n a~ b\n ~a~ c\n x~y z~w~\n}"),
    content=(
      #|ER_DIAGRAM@0 "erDiagram"
      #|NEWLINE@9 "\n"
      #|UNICODE_TEXT@10 "A"
      #|BLOCK_START@12 "{"
      #|ATTRIBUTE_WORD@15 "a"
      #|CHAR@16 "~"
      #|ATTRIBUTE_WORD@18 "b"
      #|ATTRIBUTE_WORD@21 "~a~"
      #|ATTRIBUTE_WORD@25 "c"
      #|ATTRIBUTE_WORD@28 "x~y z~w~"
      #|BLOCK_STOP@37 "}"
      #|EOF@38 ""
      #|$end@38 ""
    ),
  )
}

///|
test "reads subgraph and class keywords" {
  inspect(
    lex(
      "erDiagram\n subgraph g [Title words]\n A\n end   \n class A b\nEND end endx\nsubgraphs Subgraph",
    ),
    content=(
      #|ER_DIAGRAM@0 "erDiagram"
      #|NEWLINE@9 "\n"
      #|SUBGRAPH@11 "subgraph"
      #|UNICODE_TEXT@20 "g"
      #|SQS@22 "["
      #|UNICODE_TEXT@23 "Title"
      #|UNICODE_TEXT@29 "words"
      #|SQE@34 "]"
      #|NEWLINE@35 "\n"
      #|UNICODE_TEXT@37 "A"
      #|NEWLINE@38 "\n"
      #|END@40 "end   \n "
      #|CLASS@48 "class"
      #|UNICODE_TEXT@54 "A"
      #|UNICODE_TEXT@56 "b"
      #|NEWLINE@57 "\n"
      #|END@58 "END "
      #|END@62 "end "
      #|UNICODE_TEXT@66 "endx"
      #|NEWLINE@70 "\n"
      #|UNICODE_TEXT@71 "subgraphs"
      #|SUBGRAPH@81 "Subgraph"
      #|EOF@89 ""
      #|$end@89 ""
    ),
  )
}

///|
test "reads punctuation" {
  inspect(
    lex("erDiagram\n A # , ; ! @ [ ] :: :::\n"),
    content=(
      #|ER_DIAGRAM@0 "erDiagram"
      #|NEWLINE@9 "\n"
      #|UNICODE_TEXT@11 "A"
      #|BRKT@13 "#"
      #|COMMA@15 ","
      #|CHAR@17 ";"
      #|CHAR@19 "!"
      #|CHAR@21 "@"
      #|SQS@23 "["
      #|SQE@25 "]"
      #|COLON@27 ":"
      #|COLON@28 ":"
      #|STYLE_SEPARATOR@30 ":::"
      #|NEWLINE@33 "\n"
      #|EOF@34 ""
      #|$end@34 ""
    ),
  )
}

///|
test "skips blanks and joins newlines" {
  inspect(
    lex("erDiagram\r\n\n\nA\t B\n\n"),
    content=(
      #|ER_DIAGRAM@0 "erDiagram"
      #|NEWLINE@10 "\n\n\n"
      #|UNICODE_TEXT@13 "A"
      #|UNICODE_TEXT@16 "B"
      #|NEWLINE@17 "\n\n"
      #|EOF@19 ""
      #|$end@19 ""
    ),
  )
}

///|
test "ends an unclosed backtick name at the end of the text" {
  inspect(
    lex("erDiagram\n A {\n `open"),
    content=(
      #|ER_DIAGRAM@0 "erDiagram"
      #|NEWLINE@9 "\n"
      #|UNICODE_TEXT@11 "A"
      #|BLOCK_START@13 "{"
      #|ATTRIBUTE_WORD@17 "open"
      #|$end@21 ""
    ),
  )
}

///|
test "ends an unclosed multi-line description at the end of the text" {
  inspect(
    lex("erDiagram\n accDescr {\n never closed"),
    content=(
      #|ER_DIAGRAM@0 "erDiagram"
      #|NEWLINE@9 "\n"
      #|acc_descr_multiline_value@23 "never closed"
      #|acc_descr_multiline_value@35 ""
      #|$end@35 ""
    ),
  )
}

///|
test "ends an accessible title at the end of the text" {
  inspect(
    lex("erDiagram\n accTitle: ends at input"),
    content=(
      #|ER_DIAGRAM@0 "erDiagram"
      #|NEWLINE@9 "\n"
      #|acc_title@11 "accTitle: "
      #|acc_title_value@21 "ends at input"
      #|EOF@34 ""
      #|$end@34 ""
    ),
  )
}
