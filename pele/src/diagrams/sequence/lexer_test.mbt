// The expected streams were taken from pele's lexer.

///|
/// The token stream one per line, as `NAME@start "text"` with the text escaped.
/// The token that ends a stream at a lexical error is written as `ERROR`, since Mermaid calls it `INVALID` too.
fn lex(source : String) -> String {
  let tokens = @sequence.tokenize(source)
  let lines = []
  for i, kind in tokens.types {
    let name = if kind is Error { "ERROR" } else { kind.name() }
    lines.push("\{name}@\{tokens.starts[i]} \{quote(tokens.texts[i])}")
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
test "reads messages and the plain arrows" {
  inspect(
    lex(
      "sequenceDiagram\nAlice->>Bob: Hello Bob\nB-->>A: x;C-)D: y\nE--xF: z\nG->H: a\nI-->J: b",
    ),
    content=(
      #|SD@0 "sequenceDiagram"
      #|NEWLINE@15 "\n"
      #|ACTOR@16 "Alice"
      #|SOLID_ARROW@21 "->>"
      #|ACTOR@24 "Bob"
      #|TXT@27 ": Hello Bob"
      #|NEWLINE@38 "\n"
      #|ACTOR@39 "B"
      #|DOTTED_ARROW@40 "-->>"
      #|ACTOR@44 "A"
      #|TXT@45 ": x"
      #|NEWLINE@48 ";"
      #|ACTOR@49 "C"
      #|SOLID_POINT@50 "-)"
      #|ACTOR@52 "D"
      #|TXT@53 ": y"
      #|NEWLINE@56 "\n"
      #|ACTOR@57 "E"
      #|DOTTED_CROSS@58 "--x"
      #|ACTOR@61 "F"
      #|TXT@62 ": z"
      #|NEWLINE@65 "\n"
      #|ACTOR@66 "G"
      #|SOLID_OPEN_ARROW@67 "->"
      #|ACTOR@69 "H"
      #|TXT@70 ": a"
      #|NEWLINE@73 "\n"
      #|ACTOR@74 "I"
      #|DOTTED_OPEN_ARROW@75 "-->"
      #|ACTOR@78 "J"
      #|TXT@79 ": b"
      #|NEWLINE@82 ""
      #|$end@82 ""
    ),
  )
}

///|
test "reads half arrows, reverse arrows, bidirectional arrows, central connections, and activation marks" {
  inspect(
    lex(
      "A-|\\B: a\nA-|/B: b\nA-\\\\B: c\nA-//B: d\nA--|\\B: e\nA--//B: f\nA/|-B: g\nA\\\\--B: h\nA<<->>B: i\nA<<-->>B: j\nA()->>()B: k\nA->>+B: l\nB-->>-A: m",
    ),
    content=(
      #|ACTOR@0 "A"
      #|SOLID_ARROW_TOP@1 "-|\\"
      #|ACTOR@4 "B"
      #|TXT@5 ": a"
      #|NEWLINE@8 "\n"
      #|ACTOR@9 "A"
      #|SOLID_ARROW_BOTTOM@10 "-|/"
      #|ACTOR@13 "B"
      #|TXT@14 ": b"
      #|NEWLINE@17 "\n"
      #|ACTOR@18 "A"
      #|STICK_ARROW_TOP@19 "-\\\\"
      #|ACTOR@22 "B"
      #|TXT@23 ": c"
      #|NEWLINE@26 "\n"
      #|ACTOR@27 "A"
      #|STICK_ARROW_BOTTOM@28 "-//"
      #|ACTOR@31 "B"
      #|TXT@32 ": d"
      #|NEWLINE@35 "\n"
      #|ACTOR@36 "A"
      #|SOLID_ARROW_TOP_DOTTED@37 "--|\\"
      #|ACTOR@41 "B"
      #|TXT@42 ": e"
      #|NEWLINE@45 "\n"
      #|ACTOR@46 "A"
      #|STICK_ARROW_BOTTOM_DOTTED@47 "--//"
      #|ACTOR@51 "B"
      #|TXT@52 ": f"
      #|NEWLINE@55 "\n"
      #|ACTOR@56 "A"
      #|SOLID_ARROW_TOP_REVERSE@57 "/|-"
      #|ACTOR@60 "B"
      #|TXT@61 ": g"
      #|NEWLINE@64 "\n"
      #|ACTOR@65 "A"
      #|STICK_ARROW_BOTTOM_REVERSE_DOTTED@66 "\\\\--"
      #|ACTOR@70 "B"
      #|TXT@71 ": h"
      #|NEWLINE@74 "\n"
      #|ACTOR@75 "A"
      #|BIDIRECTIONAL_SOLID_ARROW@76 "<<->>"
      #|ACTOR@81 "B"
      #|TXT@82 ": i"
      #|NEWLINE@85 "\n"
      #|ACTOR@86 "A"
      #|BIDIRECTIONAL_DOTTED_ARROW@87 "<<-->>"
      #|ACTOR@93 "B"
      #|TXT@94 ": j"
      #|NEWLINE@97 "\n"
      #|ACTOR@98 "A"
      #|()@99 "()"
      #|SOLID_ARROW@101 "->>"
      #|()@104 "()"
      #|ACTOR@106 "B"
      #|TXT@107 ": k"
      #|NEWLINE@110 "\n"
      #|ACTOR@111 "A"
      #|SOLID_ARROW@112 "->>"
      #|+@115 "+"
      #|ACTOR@116 "B"
      #|TXT@117 ": l"
      #|NEWLINE@120 "\n"
      #|ACTOR@121 "B"
      #|DOTTED_ARROW@122 "-->>"
      #|-@126 "-"
      #|ACTOR@127 "A"
      #|TXT@128 ": m"
      #|NEWLINE@131 ""
      #|$end@131 ""
    ),
  )
}

///|
test "reads participant declarations with aliases, config objects, and comments" {
  inspect(
    lex(
      "participant Alice as A\nactor B@{ \"type\": \"queue\" } as Q\nparticipant C #comment\nparticipant D:x\nparticipant E@{ \"alias\": \"e\" }\nACTOR  F  as  wrap: G",
    ),
    content=(
      #|participant@0 "participant"
      #|ACTOR@12 "Alice"
      #|AS@18 "as"
      #|restOfLine@21 "A"
      #|NEWLINE@22 "\n"
      #|participant_actor@23 "actor"
      #|ACTOR@29 "B"
      #|CONFIG_START@30 "@{"
      #|CONFIG_CONTENT@32 " \"type\": \"queue\" "
      #|CONFIG_END@49 "}"
      #|AS@51 "as"
      #|restOfLine@54 "Q"
      #|NEWLINE@55 "\n"
      #|participant@56 "participant"
      #|ACTOR@68 "C #comment"
      #|NEWLINE@78 "\n"
      #|participant@79 "participant"
      #|INVALID@91 "D:x"
      #|NEWLINE@94 "\n"
      #|participant@95 "participant"
      #|ACTOR@107 "E"
      #|CONFIG_START@108 "@{"
      #|CONFIG_CONTENT@110 " \"alias\": \"e\" "
      #|CONFIG_END@124 "}"
      #|NEWLINE@125 "\n"
      #|participant_actor@126 "ACTOR"
      #|ACTOR@133 "F"
      #|AS@136 "as"
      #|restOfLine@140 "wrap: G"
      #|NEWLINE@147 ""
      #|$end@147 ""
    ),
  )
}

///|
test "reads block keywords and the rest of their lines" {
  inspect(
    lex(
      "autonumber 10 5\nautonumber off\nactivate A\ndeactivate A\nloop Every minute\nend\nalt x\nelse y\nend\npar_over p\nand q\nend\ncritical c\noption o\nend\nbreak b\nend\nrect rgb(0,0,0)\nend\nbox Aqua G\nend\ncreate participant X\ndestroy X\nopt\nend",
    ),
    content=(
      #|autonumber@0 "autonumber"
      #|NUM@11 "10"
      #|NUM@14 "5"
      #|NEWLINE@15 "\n"
      #|autonumber@16 "autonumber"
      #|off@27 "off"
      #|NEWLINE@30 "\n"
      #|activate@31 "activate"
      #|ACTOR@40 "A"
      #|NEWLINE@41 "\n"
      #|deactivate@42 "deactivate"
      #|ACTOR@53 "A"
      #|NEWLINE@54 "\n"
      #|loop@55 "loop"
      #|restOfLine@60 "Every minute"
      #|NEWLINE@72 "\n"
      #|end@73 "end"
      #|NEWLINE@76 "\n"
      #|alt@77 "alt"
      #|restOfLine@81 "x"
      #|NEWLINE@82 "\n"
      #|else@83 "else"
      #|restOfLine@88 "y"
      #|NEWLINE@89 "\n"
      #|end@90 "end"
      #|NEWLINE@93 "\n"
      #|par_over@94 "par_over"
      #|restOfLine@103 "p"
      #|NEWLINE@104 "\n"
      #|and@105 "and"
      #|restOfLine@109 "q"
      #|NEWLINE@110 "\n"
      #|end@111 "end"
      #|NEWLINE@114 "\n"
      #|critical@115 "critical"
      #|restOfLine@124 "c"
      #|NEWLINE@125 "\n"
      #|option@126 "option"
      #|restOfLine@133 "o"
      #|NEWLINE@134 "\n"
      #|end@135 "end"
      #|NEWLINE@138 "\n"
      #|break@139 "break"
      #|restOfLine@145 "b"
      #|NEWLINE@146 "\n"
      #|end@147 "end"
      #|NEWLINE@150 "\n"
      #|rect@151 "rect"
      #|restOfLine@156 "rgb(0,0,0)"
      #|NEWLINE@166 "\n"
      #|end@167 "end"
      #|NEWLINE@170 "\n"
      #|box@171 "box"
      #|restOfLine@175 "Aqua G"
      #|NEWLINE@181 "\n"
      #|end@182 "end"
      #|NEWLINE@185 "\n"
      #|create@186 "create"
      #|participant@193 "participant"
      #|ACTOR@205 "X"
      #|NEWLINE@206 "\n"
      #|destroy@207 "destroy"
      #|ACTOR@215 "X"
      #|NEWLINE@216 "\n"
      #|opt@217 "opt"
      #|restOfLine@220 ""
      #|NEWLINE@220 "\n"
      #|end@221 "end"
      #|NEWLINE@224 ""
      #|$end@224 ""
    ),
  )
}

///|
test "reads notes and the participant menus" {
  inspect(
    lex(
      "Note left of A: L\nnote right of B: R\nNote over A,B: AB\nlinks A: {}\nlink A: x @ y\nproperties A: {}\ndetails A: el\nlinks\nlink-A->>B: x",
    ),
    content=(
      #|note@0 "Note"
      #|left_of@5 "left of"
      #|ACTOR@13 "A"
      #|TXT@14 ": L"
      #|NEWLINE@17 "\n"
      #|note@18 "note"
      #|right_of@23 "right of"
      #|ACTOR@32 "B"
      #|TXT@33 ": R"
      #|NEWLINE@36 "\n"
      #|note@37 "Note"
      #|over@42 "over"
      #|ACTOR@47 "A"
      #|,@48 ","
      #|ACTOR@49 "B"
      #|TXT@50 ": AB"
      #|NEWLINE@54 "\n"
      #|links@55 "links"
      #|ACTOR@61 "A"
      #|TXT@62 ": {}"
      #|NEWLINE@66 "\n"
      #|link@67 "link"
      #|ACTOR@72 "A"
      #|TXT@73 ": x @ y"
      #|NEWLINE@80 "\n"
      #|properties@81 "properties"
      #|ACTOR@92 "A"
      #|TXT@93 ": {}"
      #|NEWLINE@97 "\n"
      #|details@98 "details"
      #|ACTOR@106 "A"
      #|TXT@107 ": el"
      #|NEWLINE@111 "\n"
      #|ACTOR@112 "links"
      #|NEWLINE@117 "\n"
      #|ACTOR@118 "link-A"
      #|SOLID_ARROW@124 "->>"
      #|ACTOR@127 "B"
      #|TXT@128 ": x"
      #|NEWLINE@131 ""
      #|$end@131 ""
    ),
  )
}

///|
test "reads titles, accessible text, and comments" {
  inspect(
    lex(
      "title My title\ntitle: Legacy\naccTitle: T\naccDescr: D\naccDescr {\n multi\n}\n%% comment\n# hash\nA->>B:x #c\n %%{x}%%",
    ),
    content=(
      #|title@0 "title My title"
      #|NEWLINE@14 "\n"
      #|legacy_title@15 "title: Legacy"
      #|NEWLINE@28 "\n"
      #|acc_title@29 "accTitle: "
      #|acc_title_value@39 "T"
      #|NEWLINE@40 "\n"
      #|acc_descr@41 "accDescr: "
      #|acc_descr_value@51 "D"
      #|NEWLINE@52 "\n"
      #|acc_descr_multiline_value@65 "multi\n"
      #|NEWLINE@72 "\n"
      #|NEWLINE@83 "\n"
      #|NEWLINE@90 "\n"
      #|ACTOR@91 "A"
      #|SOLID_ARROW@92 "->>"
      #|ACTOR@95 "B"
      #|TXT@96 ":x "
      #|NEWLINE@101 "\n"
      #|NEWLINE@110 ""
      #|$end@110 ""
    ),
  )
}

///|
test "reads numbers only when a space or a line break follows" {
  inspect(
    lex("autonumber 10.01 .01\nautonumber 10.001\n1.2.3\n12x"),
    content=(
      #|autonumber@0 "autonumber"
      #|NUM@11 "10.01"
      #|NUM@17 ".01"
      #|NEWLINE@20 "\n"
      #|autonumber@21 "autonumber"
      #|ACTOR@32 "10.001"
      #|NEWLINE@38 "\n"
      #|ACTOR@39 "1.2.3"
      #|NEWLINE@44 "\n"
      #|ACTOR@45 "12x"
      #|NEWLINE@48 ""
      #|$end@48 ""
    ),
  )
}

///|
test "reads what cannot be a name as invalid" {
  inspect(
    lex("sequenceDiagram\nparticipant <x\nparticipant X asAAA:AA"),
    content=(
      #|SD@0 "sequenceDiagram"
      #|NEWLINE@15 "\n"
      #|participant@16 "participant"
      #|INVALID@28 "<x"
      #|NEWLINE@30 "\n"
      #|participant@31 "participant"
      #|INVALID@43 "X asAAA:AA"
      #|NEWLINE@53 ""
      #|$end@53 ""
    ),
  )
}

///|
test "ends the stream with a lexical error where no rule matches" {
  inspect(
    lex("sequenceDiagram\n  participant\n"),
    content=(
      #|SD@0 "sequenceDiagram"
      #|NEWLINE@15 "\n"
      #|participant@18 "participant"
      #|ERROR@29 ""
    ),
  )
}

///|
test "ends a line state with an empty rest of line" {
  inspect(
    lex("loop"),
    content=(
      #|loop@0 "loop"
      #|restOfLine@4 ""
      #|$end@4 ""
    ),
  )
}

///|
test "ends an open accessible description with an empty value" {
  inspect(
    lex("accDescr {"),
    content=(
      #|acc_descr_multiline_value@10 ""
      #|$end@10 ""
    ),
  )
}

///|
test "ends an accessible title with an empty value" {
  inspect(
    lex("accTitle:"),
    content=(
      #|acc_title@0 "accTitle:"
      #|acc_title_value@9 ""
      #|$end@9 ""
    ),
  )
}

///|
test "ends a pending alias with a newline" {
  inspect(
    lex("participant A as"),
    content=(
      #|participant@0 "participant"
      #|ACTOR@12 "A as"
      #|NEWLINE@16 ""
      #|$end@16 ""
    ),
  )
}

///|
test "reads names around spaces and non-ASCII text" {
  inspect(
    lex("A-x B: été\nA ->> B : x\nA -- B"),
    content=(
      #|ACTOR@0 "A"
      #|SOLID_CROSS@1 "-x"
      #|ACTOR@4 "B"
      #|TXT@5 ": été"
      #|NEWLINE@10 "\n"
      #|ACTOR@11 "A"
      #|SOLID_ARROW@13 "->>"
      #|ACTOR@17 "B"
      #|TXT@19 ": x"
      #|NEWLINE@22 "\n"
      #|ACTOR@23 "A"
      #|-@25 "-"
      #|-@26 "-"
      #|ACTOR@28 "B"
      #|NEWLINE@29 ""
      #|$end@29 ""
    ),
  )
}
