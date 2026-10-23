// The expected streams were taken from pele's lexer.

///|
/// The token stream one per line, as `NAME@start "text"` with the text escaped, then the grammar's own error if lexing stopped on one.
fn lex(source : String) -> String {
  let tokens = @state.tokenize(source)
  let lines = []
  for i, kind in tokens.types {
    lines.push("\{kind.name()}@\{tokens.starts[i]} \{quote(tokens.texts[i])}")
  }
  if tokens.error is Some(error) {
    lines.push("error \{quote(error)}")
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
test "reads transitions, descriptions and start and end states" {
  inspect(
    lex("stateDiagram-v2\n[*] --> a : go\na --> [*]\nb : x::y : z;w\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|EDGE_STATE@16 "[*]"
      #|-->@20 "-->"
      #|ID@24 "a"
      #|DESCR@26 ": go"
      #|NL@30 "\n"
      #|ID@31 "a"
      #|-->@33 "-->"
      #|EDGE_STATE@37 "[*]"
      #|NL@40 "\n"
      #|ID@41 "b"
      #|DESCR@43 ": x"
      #|DESCR@46 "::y : z"
      #|ID@53 ";w"
      #|NL@55 "\n"
      #|NL@56 ""
      #|$end@56 ""
    ),
  )
}

///|
test "reads the stateDiagram keyword with and without -v2" {
  inspect(
    lex("stateDiagram\n  a\n"),
    content=(
      #|SD@0 "stateDiagram\n  "
      #|ID@15 "a"
      #|NL@16 "\n"
      #|NL@17 ""
      #|$end@17 ""
    ),
  )
}

///|
test "reads a state with a description and a composite with regions" {
  inspect(
    lex(
      "stateDiagram\n  state \"Long name\" as s1\n  state s2 {\n  a --> b\n  --\n  c\n  }\n  state s3{\n  }\n",
    ),
    content=(
      #|SD@0 "stateDiagram\n  "
      #|STATE_DESCR@22 "Long name"
      #|AS@33 "as "
      #|ID@36 "s1"
      #|COMPOSIT_STATE@47 "s2"
      #|STRUCT_START@50 "{"
      #|ID@54 "a"
      #|-->@56 "-->"
      #|ID@60 "b"
      #|CONCURRENT@64 "--"
      #|ID@69 "c"
      #|STRUCT_STOP@73 "}"
      #|NL@74 "\n"
      #|COMPOSIT_STATE@83 "s3"
      #|STRUCT_START@85 "{"
      #|STRUCT_STOP@89 "}"
      #|NL@90 "\n"
      #|NL@91 ""
      #|$end@91 ""
    ),
  )
}

///|
test "reads stereotypes in either spelling and any case" {
  inspect(
    lex(
      "stateDiagram-v2\nstate f <<fork>>\nstate j [[join]]\nstate c <<CHOICE>>\nstate k [[Choice]]\n",
    ),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|FORK@22 "f"
      #|NL@32 "\n"
      #|JOIN@39 "j"
      #|NL@49 "\n"
      #|CHOICE@56 "c"
      #|NL@68 "\n"
      #|CHOICE@75 "k"
      #|NL@87 "\n"
      #|NL@88 ""
      #|$end@88 ""
    ),
  )
}

///|
test "takes the first stereotype kind in grammar order, not the first on the line" {
  inspect(
    lex(
      "stateDiagram-v2\nstate x <<join>> y <<fork>>\nstate <<fork> [[join] z\n",
    ),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|FORK@22 "x <<join>> y"
      #|NL@43 "\n"
      #|COMPOSIT_STATE@50 "<<fork>"
      #|COMPOSIT_STATE@58 "[[join]"
      #|COMPOSIT_STATE@66 "z"
      #|NL@68 ""
      #|$end@68 ""
    ),
  )
}

///|
test "reads notes beside a state, over several lines, and floating" {
  inspect(
    lex(
      "stateDiagram-v2\nnote right of a : text\nnote left of b\n multi\n line\nend note\nnote \"floating\" as n1\nnote left of c:x\n",
    ),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|note@16 "note "
      #|right_of@21 "right of"
      #|ID@29 " a"
      #|NOTE_TEXT@31 "text"
      #|NL@38 "\n"
      #|note@39 "note "
      #|left_of@44 "left of"
      #|ID@51 " b"
      #|NOTE_TEXT@53 "multi\n line"
      #|NL@75 "\n"
      #|note@76 "note "
      #|NOTE_TEXT@82 "floating"
      #|AS@91 " as "
      #|ID@95 "n1"
      #|NL@97 "\n"
      #|note@98 "note "
      #|left_of@103 "left of"
      #|ID@110 " c"
      #|NOTE_TEXT@112 ""
      #|NL@114 "\n"
      #|NL@115 ""
      #|$end@115 ""
    ),
  )
}

///|
test "reads classDef, class, style and the class shorthand" {
  inspect(
    lex(
      "stateDiagram-v2\nclassDef hot fill:#f00,color:white\nclassDef default fill:red\nclass a,b hot\nclass a, b , c cool\nstyle a,b fill:#0f0\na:::hot --> b\n",
    ),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|classDef@16 "classDef "
      #|CLASSDEF_ID@25 "hot "
      #|CLASSDEF_STYLEOPTS@29 "fill:#f00,color:white"
      #|NL@50 "\n"
      #|classDef@51 "classDef "
      #|DEFAULT_CLASSDEF_ID@60 "default "
      #|CLASSDEF_STYLEOPTS@68 "fill:red"
      #|NL@76 "\n"
      #|class@77 "class "
      #|CLASSENTITY_IDS@83 "a,b"
      #|STYLECLASS@86 " hot"
      #|NL@90 "\n"
      #|class@91 "class "
      #|CLASSENTITY_IDS@97 "a, b"
      #|STYLECLASS@101 " , c cool"
      #|NL@110 "\n"
      #|style@111 "style "
      #|STYLE_IDS@117 "a,b "
      #|STYLEDEF_STYLEOPTS@121 "fill:#0f0"
      #|NL@130 "\n"
      #|ID@131 "a"
      #|STYLE_SEPARATOR@132 ":::"
      #|ID@135 "hot"
      #|-->@139 "-->"
      #|ID@143 "b"
      #|NL@144 "\n"
      #|NL@145 ""
      #|$end@145 ""
    ),
  )
}

///|
test "reads click statements" {
  inspect(
    lex("stateDiagram-v2\nclick a \"https://x\" \"tip\"\nclick b href \"u\"\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|CLICK@16 "click"
      #|ID@22 "a"
      #|STRING@24 "\"https://x\""
      #|STRING@36 "\"tip\""
      #|NL@41 "\n"
      #|CLICK@42 "click"
      #|ID@48 "b"
      #|HREF@50 "href"
      #|STRING@55 "\"u\""
      #|NL@58 "\n"
      #|NL@59 ""
      #|$end@59 ""
    ),
  )
}

///|
test "reads directions at the root and inside a composite" {
  inspect(
    lex(
      "stateDiagram-v2\ndirection LR\nstate A {\n direction bt\n a\n}\nx direction TB direction lr\n",
    ),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|direction_lr@16 "direction LR"
      #|NL@28 "\n"
      #|COMPOSIT_STATE@35 "A"
      #|STRUCT_START@37 "{"
      #|direction_bt@40 "direction bt"
      #|ID@54 "a"
      #|STRUCT_STOP@56 "}"
      #|NL@57 "\n"
      #|direction_tb@58 "x direction TB direction lr"
      #|NL@85 "\n"
      #|NL@86 ""
      #|$end@86 ""
    ),
  )
}

///|
test "reads a direction after a line separator" {
  inspect(
    lex("stateDiagram-v2\na\u{2028}direction LR\nb\rdirection RL\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|ID@16 "a"
      #|direction_lr@18 "direction LR"
      #|NL@30 "\n"
      #|ID@31 "b"
      #|direction_rl@33 "direction RL"
      #|NL@45 "\n"
      #|NL@46 ""
      #|$end@46 ""
    ),
  )
}

///|
test "reads accessibility statements" {
  inspect(
    lex(
      "stateDiagram-v2\naccTitle: The title\naccDescr: d\naccDescr {\n multi\n line\n}\n",
    ),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|acc_title@16 "accTitle: "
      #|acc_title_value@26 "The title"
      #|NL@35 "\n"
      #|acc_descr@36 "accDescr: "
      #|acc_descr_value@46 "d"
      #|NL@47 "\n"
      #|acc_descr_multiline_value@60 "multi\n line\n"
      #|NL@73 "\n"
      #|NL@74 ""
      #|$end@74 ""
    ),
  )
}

///|
test "skips comments and reads the statements that change nothing" {
  inspect(
    lex(
      "stateDiagram-v2\n%% comment\na --> b %% trailing\n# hash\nhide empty description\nscale 350 width\n",
    ),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|NL@26 "\n"
      #|ID@27 "a"
      #|-->@29 "-->"
      #|ID@33 "b"
      #|NL@46 "\n"
      #|NL@53 "\n"
      #|HIDE_EMPTY@54 "hide empty description"
      #|NL@76 "\n"
      #|scale@77 "scale "
      #|WIDTH@83 "350"
      #|NL@92 "\n"
      #|NL@93 ""
      #|$end@93 ""
    ),
  )
}

///|
test "ends an id at an inline comment" {
  inspect(
    lex(
      "stateDiagram-v2\na%%b --> c\n%%{x}%%\nstate \"x\" as %%y\nstate \"x\" as z%%y\n",
    ),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|ID@16 "a"
      #|NL@26 "\n"
      #|STRUCT_START@29 "{"
      #|ID@30 "x}"
      #|STATE_DESCR@42 "x"
      #|AS@45 "as "
      #|ID@51 ""
      #|STATE_DESCR@59 "x"
      #|AS@62 "as "
      #|ID@65 "z"
      #|$end@70 ""
    ),
  )
}

///|
test "reads a description given with the alias" {
  inspect(
    lex("stateDiagram-v2\nstate \"x\" as a:desc\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|STATE_DESCR@23 "x"
      #|AS@26 "as "
      #|ID@29 "a:desc"
      #|NL@36 ""
      #|$end@36 ""
    ),
  )
}

///|
test "marks text the root does not know as invalid" {
  inspect(
    lex("stateDiagram-v2\na -- b\n!x\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|ID@16 "a"
      #|INVALID@18 "-"
      #|INVALID@19 "-"
      #|ID@21 "b"
      #|NL@22 "\n"
      #|ID@23 "!x"
      #|NL@25 "\n"
      #|NL@26 ""
      #|$end@26 ""
    ),
  )
}

///|
test "reads a divider inside a composite" {
  inspect(
    lex("stateDiagram-v2\nstate A {\n a\n --\n b\n}\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|COMPOSIT_STATE@22 "A"
      #|STRUCT_START@24 "{"
      #|ID@27 "a"
      #|CONCURRENT@30 "--"
      #|ID@34 "b"
      #|STRUCT_STOP@36 "}"
      #|NL@37 "\n"
      #|NL@38 ""
      #|$end@38 ""
    ),
  )
}

///|
test "stops at text a composite does not know" {
  inspect(
    lex("stateDiagram-v2\nstate A {\n !x\n}\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|COMPOSIT_STATE@22 "A"
      #|STRUCT_START@24 "{"
      #|ID@27 "!x"
      #|STRUCT_STOP@30 "}"
      #|NL@31 "\n"
      #|NL@32 ""
      #|$end@32 ""
    ),
  )
}

///|
test "reports a state name of two words before a brace" {
  inspect(
    lex("stateDiagram-v2\nstate two words {\n a\n}\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|INVALID@22 ""
      #|error "Error: State name must be a single word. Found: \"two words {\""
    ),
  )
}

///|
test "accepts two words when the brace is on another line" {
  inspect(
    lex("stateDiagram-v2\nstate two words\n{\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|COMPOSIT_STATE@22 "two"
      #|COMPOSIT_STATE@26 "words"
      #|STRUCT_START@32 "{"
      #|$end@34 ""
    ),
  )
}

///|
test "stops at scale without width" {
  inspect(
    lex("stateDiagram-v2\nscale 350\na --> b\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|scale@16 "scale "
      #|WIDTH@22 "350"
      #|INVALID@25 ""
    ),
  )
}

///|
test "reads an unterminated state string to the end" {
  inspect(
    lex("stateDiagram-v2\nstate \"abc\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|STATE_DESCR@23 "abc\n"
      #|STATE_DESCR@27 ""
      #|$end@27 ""
    ),
  )
}

///|
test "stops at a note that never ends" {
  inspect(
    lex("stateDiagram-v2\nnote right of a\n text\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|note@16 "note "
      #|right_of@21 "right of"
      #|ID@29 " a"
      #|INVALID@31 ""
    ),
  )
}

///|
test "stops at a note with no position" {
  inspect(
    lex("stateDiagram-v2\nnote over a\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|note@16 "note "
      #|INVALID@21 ""
    ),
  )
}

///|
test "reads values that run to the end of the text" {
  inspect(
    lex("stateDiagram-v2\naccTitle:"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|acc_title@16 "accTitle:"
      #|acc_title_value@25 ""
      #|$end@25 ""
    ),
  )
}

///|
test "reads an empty accDescr value at the end" {
  inspect(
    lex("stateDiagram-v2\naccDescr:"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|acc_descr@16 "accDescr:"
      #|acc_descr_value@25 ""
      #|$end@25 ""
    ),
  )
}

///|
test "reads an unclosed accDescr block" {
  inspect(
    lex("stateDiagram-v2\naccDescr {\nabc"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|acc_descr_multiline_value@27 "abc"
      #|acc_descr_multiline_value@30 ""
      #|$end@30 ""
    ),
  )
}

///|
test "reads a classDef at the end" {
  inspect(
    lex("stateDiagram-v2\nclassDef a "),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|classDef@16 "classDef "
      #|CLASSDEF_ID@25 "a "
      #|CLASSDEF_STYLEOPTS@27 ""
      #|$end@27 ""
    ),
  )
}

///|
test "reads a class at the end" {
  inspect(
    lex("stateDiagram-v2\nclass a "),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|class@16 "class "
      #|CLASSENTITY_IDS@22 "a"
      #|STYLECLASS@23 " "
      #|NL@24 ""
      #|$end@24 ""
    ),
  )
}

///|
test "reads a style at the end" {
  inspect(
    lex("stateDiagram-v2\nstyle a "),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|style@16 "style "
      #|STYLE_IDS@22 "a "
      #|STYLEDEF_STYLEOPTS@24 ""
      #|$end@24 ""
    ),
  )
}

///|
test "reads a floating note at the end" {
  inspect(
    lex("stateDiagram-v2\nnote \"abc"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|note@16 "note "
      #|NOTE_TEXT@22 "abc"
      #|NOTE_TEXT@25 ""
      #|$end@25 ""
    ),
  )
}

///|
test "reads an alias at the end" {
  inspect(
    lex("stateDiagram-v2\nstate \"x\" as "),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|STATE_DESCR@23 "x"
      #|AS@26 "as "
      #|ID@29 ""
      #|$end@29 ""
    ),
  )
}

///|
test "reads a state statement at the end" {
  inspect(
    lex("stateDiagram-v2\nstate "),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|$end@22 ""
    ),
  )
}

///|
test "reads a floating note alias at the end" {
  inspect(
    lex("stateDiagram-v2\nnote \"abc\" as "),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|note@16 "note "
      #|NOTE_TEXT@22 "abc"
      #|AS@26 " as "
      #|ID@30 ""
      #|$end@30 ""
    ),
  )
}

///|
test "collapses blank lines at the root but not in a composite" {
  inspect(
    lex("\n\nstateDiagram-v2\n\n\na\n\n\nstate A {\n\n\nb\n\n}\n\n"),
    content=(
      #|NL@0 "\n\n"
      #|SD@2 "stateDiagram-v2\n\n\n"
      #|ID@20 "a"
      #|NL@21 "\n\n\n"
      #|COMPOSIT_STATE@30 "A"
      #|STRUCT_START@32 "{"
      #|ID@36 "b"
      #|STRUCT_STOP@39 "}"
      #|NL@40 "\n\n"
      #|NL@42 ""
      #|$end@42 ""
    ),
  )
}

///|
test "reads a composite whose name is followed by its brace" {
  inspect(
    lex("stateDiagram-v2\nstate A{\nstate B\n{\n}\n}\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|COMPOSIT_STATE@22 "A"
      #|STRUCT_START@23 "{"
      #|COMPOSIT_STATE@31 "B"
      #|INVALID@33 ""
    ),
  )
}

///|
test "reads as after a state string on the next line" {
  inspect(
    lex("stateDiagram-v2\nstate \"x\"\n  as y\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|STATE_DESCR@23 "x"
      #|AS@25 "\n  as "
      #|ID@31 "y"
      #|NL@33 ""
      #|$end@33 ""
    ),
  )
}

///|
test "reads keywords as ids where the grammar does" {
  inspect(
    lex(
      "stateDiagram-v2\nclicks --> hrefs\ndefaults\nstateful\nnotes\nclassy\nstyled\n",
    ),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|ID@16 "clicks"
      #|-->@23 "-->"
      #|ID@27 "hrefs"
      #|NL@32 "\n"
      #|ID@33 "defaults"
      #|NL@41 "\n"
      #|ID@42 "stateful"
      #|NL@50 "\n"
      #|ID@51 "notes"
      #|NL@56 "\n"
      #|ID@57 "classy"
      #|NL@63 "\n"
      #|ID@64 "styled"
      #|NL@70 "\n"
      #|NL@71 ""
      #|$end@71 ""
    ),
  )
}

///|
test "reads keywords in any case" {
  inspect(
    lex(
      "stateDiagram-v2\nSTATE A {\n}\nNOTE LEFT OF A : x\nCLASSDEF c fill:red\nCLASS A c\nSTYLE A fill:red\nCLICK A HREF \"u\"\nHIDE EMPTY DESCRIPTION\nDIRECTION LR\n",
    ),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|COMPOSIT_STATE@22 "A"
      #|STRUCT_START@24 "{"
      #|STRUCT_STOP@26 "}"
      #|NL@27 "\n"
      #|note@28 "NOTE "
      #|left_of@33 "LEFT OF"
      #|ID@40 " A"
      #|NOTE_TEXT@42 "x"
      #|NL@46 "\n"
      #|classDef@47 "CLASSDEF "
      #|CLASSDEF_ID@56 "c "
      #|CLASSDEF_STYLEOPTS@58 "fill:red"
      #|NL@66 "\n"
      #|class@67 "CLASS "
      #|CLASSENTITY_IDS@73 "A"
      #|STYLECLASS@74 " c"
      #|NL@76 "\n"
      #|style@77 "STYLE "
      #|STYLE_IDS@83 "A "
      #|STYLEDEF_STYLEOPTS@85 "fill:red"
      #|NL@93 "\n"
      #|CLICK@94 "CLICK"
      #|ID@100 "A"
      #|HREF@102 "HREF"
      #|STRING@107 "\"u\""
      #|NL@110 "\n"
      #|HIDE_EMPTY@111 "HIDE EMPTY DESCRIPTION"
      #|NL@133 "\n"
      #|direction_lr@134 "DIRECTION LR"
      #|NL@146 "\n"
      #|NL@147 ""
      #|$end@147 ""
    ),
  )
}

///|
test "reads a classDef id that is not a word" {
  inspect(
    lex(
      "stateDiagram-v2\nclassDef  fill:red\nclassDef default\nclassDef defaults x\n",
    ),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|classDef@16 "classDef  "
      #|INVALID@26 ""
    ),
  )
}

///|
test "reads a class statement that names no state" {
  inspect(
    lex("stateDiagram-v2\nclass ,a b\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|class@16 "class "
      #|INVALID@22 ""
    ),
  )
}

///|
test "reads a style statement that names no state" {
  inspect(
    lex("stateDiagram-v2\nstyle -a b\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|style@16 "style "
      #|INVALID@22 ""
    ),
  )
}

///|
test "reads a note id that is empty" {
  inspect(
    lex("stateDiagram-v2\nnote left of :x\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|note@16 "note "
      #|left_of@21 "left of"
      #|INVALID@28 ""
    ),
  )
}

///|
test "reads a note id made of a comment" {
  inspect(
    lex("stateDiagram-v2\nnote left of %%a : x\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|note@16 "note "
      #|left_of@21 "left of"
      #|ID@28 " "
      #|INVALID@29 ""
    ),
  )
}

///|
test "reads a note on a state followed by its end on the same line" {
  inspect(
    lex(
      "stateDiagram-v2\nnote right of a\n end note\nnote right of b\nend notes\nend note\n",
    ),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|note@16 "note "
      #|right_of@21 "right of"
      #|ID@29 " a"
      #|NOTE_TEXT@31 ""
      #|NL@41 "\n"
      #|note@42 "note "
      #|right_of@47 "right of"
      #|ID@55 " b"
      #|NOTE_TEXT@57 "end notes"
      #|NL@76 "\n"
      #|NL@77 ""
      #|$end@77 ""
    ),
  )
}

///|
test "reads a floating note with quotes inside" {
  inspect(
    lex("stateDiagram-v2\nnote \"a\"\"b\" as n\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|note@16 "note "
      #|NOTE_TEXT@22 "a"
      #|NOTE_TEXT@25 "b"
      #|AS@27 " as "
      #|ID@31 "n"
      #|NL@32 "\n"
      #|NL@33 ""
      #|$end@33 ""
    ),
  )
}

///|
test "reads a description that is only a colon" {
  inspect(
    lex("stateDiagram-v2\na :\nb ::\nc :::d\n:::\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|ID@16 "a"
      #|INVALID@18 ":"
      #|NL@19 "\n"
      #|ID@20 "b"
      #|INVALID@22 ":"
      #|INVALID@23 ":"
      #|NL@24 "\n"
      #|ID@25 "c"
      #|STYLE_SEPARATOR@27 ":::"
      #|ID@30 "d"
      #|NL@31 "\n"
      #|STYLE_SEPARATOR@32 ":::"
      #|NL@35 "\n"
      #|NL@36 ""
      #|$end@36 ""
    ),
  )
}

///|
test "reads an edge state with a class" {
  inspect(
    lex("stateDiagram-v2\n[*]:::c --> b:::d\n"),
    content=(
      #|SD@0 "stateDiagram-v2\n"
      #|EDGE_STATE@16 "[*]"
      #|STYLE_SEPARATOR@19 ":::"
      #|ID@22 "c"
      #|-->@24 "-->"
      #|ID@28 "b"
      #|STYLE_SEPARATOR@29 ":::"
      #|ID@32 "d"
      #|NL@33 "\n"
      #|NL@34 ""
      #|$end@34 ""
    ),
  )
}
