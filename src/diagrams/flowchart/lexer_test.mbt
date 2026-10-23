///|
fn tokens(source : String) -> String raise {
  let tokens = @flowchart.tokenize(source)
  let lines = []
  for i, kind in tokens.types {
    lines.push(
      "\{@flowchart.token_names[kind]}@\{tokens.starts[i]} \{tokens.texts[i].escape()}",
    )
  }
  lines.join("\n")
}

///|
test "a header and a link are tokenized as pele does" {
  inspect(
    tokens("graph TD\nA-->B\n"),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " TD"
      #|NEWLINE@8 "\n"
      #|NODE_STRING@9 "A"
      #|LINK@10 "-->"
      #|NODE_STRING@13 "B"
      #|NEWLINE@14 "\n"
      #|EOF@15 ""
      #|$end@15 ""
    ),
  )
  inspect(
    tokens("graph TD;A-->B;B-->C;\n"),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " TD"
      #|SEMI@8 ";"
      #|NODE_STRING@9 "A"
      #|LINK@10 "-->"
      #|NODE_STRING@13 "B"
      #|SEMI@14 ";"
      #|NODE_STRING@15 "B"
      #|LINK@16 "-->"
      #|NODE_STRING@19 "C"
      #|SEMI@20 ";"
      #|NEWLINE@21 "\n"
      #|EOF@22 ""
      #|$end@22 ""
    ),
  )
  inspect(
    tokens("flowchart-elk TD\nA\n"),
    content=(
      #|GRAPH@0 "flowchart-elk"
      #|DIR@13 " TD"
      #|NEWLINE@16 "\n"
      #|NODE_STRING@17 "A"
      #|NEWLINE@18 "\n"
      #|EOF@19 ""
      #|$end@19 ""
    ),
  )
  inspect(
    tokens("swimlane-beta\nA\n"),
    content=(
      #|GRAPH@0 "swimlane-beta"
      #|NODIR@13 "\n"
      #|NODE_STRING@14 "A"
      #|NEWLINE@15 "\n"
      #|EOF@16 ""
      #|$end@16 ""
    ),
  )
}

///|
test "node shapes are tokenized as pele does" {
  inspect(
    tokens(
      "flowchart LR\n  A[Square] --> B(Round)\n  B --> C{Diamond}\n  C -->|Yes| D((Circle))\n  C -.->|No| E>Odd]\n",
    ),
    content=(
      #|GRAPH@0 "flowchart"
      #|DIR@9 " LR"
      #|NEWLINE@12 "\n"
      #|SPACE@13 "  "
      #|NODE_STRING@15 "A"
      #|SQS@16 "["
      #|TEXT@17 "Square"
      #|SQE@23 "]"
      #|LINK@24 " --> "
      #|NODE_STRING@29 "B"
      #|PS@30 "("
      #|TEXT@31 "Round"
      #|PE@36 ")"
      #|NEWLINE@37 "\n"
      #|SPACE@38 "  "
      #|NODE_STRING@40 "B"
      #|LINK@41 " --> "
      #|NODE_STRING@46 "C"
      #|DIAMOND_START@47 "{"
      #|TEXT@48 "Diamond"
      #|DIAMOND_STOP@55 "}"
      #|NEWLINE@56 "\n"
      #|SPACE@57 "  "
      #|NODE_STRING@59 "C"
      #|LINK@60 " -->"
      #|PIPE@64 "|"
      #|TEXT@65 "Yes"
      #|PIPE@68 "|"
      #|SPACE@69 " "
      #|NODE_STRING@70 "D"
      #|PS@71 "("
      #|PS@72 "("
      #|TEXT@73 "Circle"
      #|PE@79 ")"
      #|PE@80 ")"
      #|NEWLINE@81 "\n"
      #|SPACE@82 "  "
      #|NODE_STRING@84 "C"
      #|LINK@85 " -.->"
      #|PIPE@90 "|"
      #|TEXT@91 "No"
      #|PIPE@93 "|"
      #|SPACE@94 " "
      #|NODE_STRING@95 "E"
      #|TAGEND@96 ">"
      #|TEXT@97 "Odd"
      #|SQE@100 "]"
      #|NEWLINE@101 "\n"
      #|EOF@102 ""
      #|$end@102 ""
    ),
  )
  inspect(
    tokens(
      "graph\nA[/trap\\]\nB[\\inv/]\nC[/lean/]\nD[\\lean\\]\nE[(cyl)]\nF[[sub]]\nG([stad])\nH(((dbl)))\nI{{hex}}\nJ(-ell-)\nK[|f:v|t]\n",
    ),
    content=(
      #|GRAPH@0 "graph"
      #|NODIR@5 "\n"
      #|NODE_STRING@6 "A"
      #|TRAPSTART@7 "[/"
      #|TEXT@9 "trap"
      #|TRAPEND@13 "\\]"
      #|NEWLINE@15 "\n"
      #|NODE_STRING@16 "B"
      #|INVTRAPSTART@17 "[\\"
      #|TEXT@19 "inv"
      #|INVTRAPEND@22 "/]"
      #|NEWLINE@24 "\n"
      #|NODE_STRING@25 "C"
      #|TRAPSTART@26 "[/"
      #|TEXT@28 "lean"
      #|INVTRAPEND@32 "/]"
      #|NEWLINE@34 "\n"
      #|NODE_STRING@35 "D"
      #|INVTRAPSTART@36 "[\\"
      #|TEXT@38 "lean"
      #|TRAPEND@42 "\\]"
      #|NEWLINE@44 "\n"
      #|NODE_STRING@45 "E"
      #|CYLINDERSTART@46 "[("
      #|TEXT@48 "cyl"
      #|CYLINDEREND@51 ")]"
      #|NEWLINE@53 "\n"
      #|NODE_STRING@54 "F"
      #|SUBROUTINESTART@55 "[["
      #|TEXT@57 "sub"
      #|SUBROUTINEEND@60 "]]"
      #|NEWLINE@62 "\n"
      #|NODE_STRING@63 "G"
      #|STADIUMSTART@64 "(["
      #|TEXT@66 "stad"
      #|STADIUMEND@70 "])"
      #|NEWLINE@72 "\n"
      #|NODE_STRING@73 "H"
      #|DOUBLECIRCLESTART@74 "((("
      #|TEXT@77 "dbl"
      #|DOUBLECIRCLEEND@80 ")))"
      #|NEWLINE@83 "\n"
      #|NODE_STRING@84 "I"
      #|DIAMOND_START@85 "{"
      #|DIAMOND_START@86 "{"
      #|TEXT@87 "hex"
      #|DIAMOND_STOP@90 "}"
      #|DIAMOND_STOP@91 "}"
      #|NEWLINE@92 "\n"
      #|NODE_STRING@93 "J"
      #|(-@94 "(-"
      #|TEXT@96 "ell"
      #|-)@99 "-)"
      #|NEWLINE@101 "\n"
      #|NODE_STRING@102 "K"
      #|VERTEX_WITH_PROPS_START@103 "[|"
      #|NODE_STRING@105 "f"
      #|COLON@106 ":"
      #|DOWN@107 "v"
      #|PIPE@108 "|"
      #|TEXT@109 "t"
      #|SQE@110 "]"
      #|NEWLINE@111 "\n"
      #|EOF@112 ""
      #|$end@112 ""
    ),
  )
  inspect(
    tokens(
      "graph TD\nA[a(b)c]\nB(a[b]c)\nC{a{b}c}\nD[/a?]\nE[/a=]\nF(-a(b)-)\n",
    ),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " TD"
      #|NEWLINE@8 "\n"
      #|NODE_STRING@9 "A"
      #|SQS@10 "["
      #|TEXT@11 "a"
      #|PS@12 "("
      #|TEXT@13 "b"
      #|PE@14 ")"
      #|TEXT@15 "c"
      #|SQE@16 "]"
      #|NEWLINE@17 "\n"
      #|NODE_STRING@18 "B"
      #|PS@19 "("
      #|TEXT@20 "a"
      #|SQS@21 "["
      #|TEXT@22 "b"
      #|SQE@23 "]"
      #|TEXT@24 "c"
      #|PE@25 ")"
      #|NEWLINE@26 "\n"
      #|NODE_STRING@27 "C"
      #|DIAMOND_START@28 "{"
      #|TEXT@29 "a"
      #|DIAMOND_START@30 "{"
      #|TEXT@31 "b"
      #|DIAMOND_STOP@32 "}"
      #|TEXT@33 "c"
      #|DIAMOND_STOP@34 "}"
      #|NEWLINE@35 "\n"
      #|NODE_STRING@36 "D"
      #|TRAPSTART@37 "[/"
      #|TEXT@39 "a?"
      #|INVALID@41 ""
    ),
  )
}

///|
test "link kinds are tokenized as pele does" {
  inspect(
    tokens(
      "graph TB\nA-- text --> B\nA== thick ==>B\nA-. dotted .->B\nA ~~~ B\nA<-->B\nAx--xB\nAo--oB\n",
    ),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " TB"
      #|NEWLINE@8 "\n"
      #|NODE_STRING@9 "A"
      #|START_LINK@10 "-- "
      #|EDGE_TEXT@13 "text"
      #|LINK@17 " --> "
      #|NODE_STRING@22 "B"
      #|NEWLINE@23 "\n"
      #|NODE_STRING@24 "A"
      #|START_LINK@25 "== "
      #|EDGE_TEXT@28 "thick"
      #|LINK@33 " ==>"
      #|NODE_STRING@37 "B"
      #|NEWLINE@38 "\n"
      #|NODE_STRING@39 "A"
      #|START_LINK@40 "-. "
      #|EDGE_TEXT@43 "dotted"
      #|LINK@49 " .->"
      #|NODE_STRING@53 "B"
      #|NEWLINE@54 "\n"
      #|NODE_STRING@55 "A"
      #|LINK@56 " ~~~ "
      #|NODE_STRING@61 "B"
      #|NEWLINE@62 "\n"
      #|NODE_STRING@63 "A"
      #|LINK@64 "<-->"
      #|NODE_STRING@68 "B"
      #|NEWLINE@69 "\n"
      #|NODE_STRING@70 "Ax"
      #|LINK@72 "--x"
      #|NODE_STRING@75 "B"
      #|NEWLINE@76 "\n"
      #|NODE_STRING@77 "Ao"
      #|LINK@79 "--o"
      #|NODE_STRING@82 "B"
      #|NEWLINE@83 "\n"
      #|EOF@84 ""
      #|$end@84 ""
    ),
  )
  inspect(
    tokens(
      "graph TD\nA---B\nA----B\nA-.-B\nA-..-B\nA===B\nA~~~~B\nA-->|text with spaces|B\nA--text--->B\nA-->|\"str\"|B\n",
    ),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " TD"
      #|NEWLINE@8 "\n"
      #|NODE_STRING@9 "A"
      #|LINK@10 "---"
      #|NODE_STRING@13 "B"
      #|NEWLINE@14 "\n"
      #|NODE_STRING@15 "A"
      #|LINK@16 "----"
      #|NODE_STRING@20 "B"
      #|NEWLINE@21 "\n"
      #|NODE_STRING@22 "A"
      #|LINK@23 "-.-"
      #|NODE_STRING@26 "B"
      #|NEWLINE@27 "\n"
      #|NODE_STRING@28 "A"
      #|LINK@29 "-..-"
      #|NODE_STRING@33 "B"
      #|NEWLINE@34 "\n"
      #|NODE_STRING@35 "A"
      #|LINK@36 "==="
      #|NODE_STRING@39 "B"
      #|NEWLINE@40 "\n"
      #|NODE_STRING@41 "A"
      #|LINK@42 "~~~~"
      #|NODE_STRING@46 "B"
      #|NEWLINE@47 "\n"
      #|NODE_STRING@48 "A"
      #|LINK@49 "-->"
      #|PIPE@52 "|"
      #|TEXT@53 "text with spaces"
      #|PIPE@69 "|"
      #|NODE_STRING@70 "B"
      #|NEWLINE@71 "\n"
      #|NODE_STRING@72 "A"
      #|START_LINK@73 "--"
      #|EDGE_TEXT@75 "text"
      #|LINK@79 "--->"
      #|NODE_STRING@83 "B"
      #|NEWLINE@84 "\n"
      #|NODE_STRING@85 "A"
      #|LINK@86 "-->"
      #|PIPE@89 "|"
      #|STR@91 "str"
      #|PIPE@95 "|"
      #|NODE_STRING@96 "B"
      #|NEWLINE@97 "\n"
      #|EOF@98 ""
      #|$end@98 ""
    ),
  )
  inspect(
    tokens(
      "graph TD\nA-- x -- y --> B\nA-- a - b -->B\nA== a = b ==>B\nA-. a . b .->B\nA-- \"q\" -->B\n",
    ),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " TD"
      #|NEWLINE@8 "\n"
      #|NODE_STRING@9 "A"
      #|START_LINK@10 "-- "
      #|EDGE_TEXT@13 "x "
      #|INVALID@15 ""
    ),
  )
}

///|
test "subgraphs and directions are tokenized as pele does" {
  inspect(
    tokens("graph LR\nsubgraph one [Title]\ndirection LR\na1-->a2\nend\n"),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " LR"
      #|NEWLINE@8 "\n"
      #|subgraph@9 "subgraph"
      #|SPACE@17 " "
      #|NODE_STRING@18 "one"
      #|SPACE@21 " "
      #|SQS@22 "["
      #|TEXT@23 "Title"
      #|SQE@28 "]"
      #|NEWLINE@29 "\n"
      #|direction_lr@30 "direction LR"
      #|NEWLINE@42 "\n"
      #|NODE_STRING@43 "a1"
      #|LINK@45 "-->"
      #|NODE_STRING@48 "a2"
      #|NEWLINE@50 "\n"
      #|end@51 "end\n"
      #|EOF@55 ""
      #|$end@55 ""
    ),
  )
  inspect(
    tokens("graph TD\n  direction BT\n  A\nsubgraph\nend\nend   \n"),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " TD"
      #|NEWLINE@8 "\n"
      #|direction_bt@9 "  direction BT"
      #|NEWLINE@23 "\n"
      #|SPACE@24 "  "
      #|NODE_STRING@26 "A"
      #|NEWLINE@27 "\n"
      #|subgraph@28 "subgraph"
      #|NEWLINE@36 "\n"
      #|end@37 "end\n"
      #|end@41 "end   \n"
      #|EOF@48 ""
      #|$end@48 ""
    ),
  )
  inspect(
    tokens("graph >\nA\n"),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " >"
      #|NEWLINE@7 "\n"
      #|NODE_STRING@8 "A"
      #|NEWLINE@9 "\n"
      #|EOF@10 ""
      #|$end@10 ""
    ),
  )
  inspect(
    tokens("graph v\nA\n"),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " v"
      #|NEWLINE@7 "\n"
      #|NODE_STRING@8 "A"
      #|NEWLINE@9 "\n"
      #|EOF@10 ""
      #|$end@10 ""
    ),
  )
  inspect(
    tokens("graph <\nA\n"),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " <"
      #|NEWLINE@7 "\n"
      #|NODE_STRING@8 "A"
      #|NEWLINE@9 "\n"
      #|EOF@10 ""
      #|$end@10 ""
    ),
  )
  inspect(
    tokens("graph ^\nA\n"),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " ^"
      #|NEWLINE@7 "\n"
      #|NODE_STRING@8 "A"
      #|NEWLINE@9 "\n"
      #|EOF@10 ""
      #|$end@10 ""
    ),
  )
  inspect(
    tokens("graph\n\n  \nA\n"),
    content=(
      #|GRAPH@0 "graph"
      #|NODIR@5 "\n\n  \n"
      #|NODE_STRING@10 "A"
      #|NEWLINE@11 "\n"
      #|EOF@12 ""
      #|$end@12 ""
    ),
  )
  inspect(
    tokens("graph \"TD\"\n"),
    content=(
      #|GRAPH@0 "graph"
      #|INVALID@5 ""
    ),
  )
}

///|
test "styles and classes are tokenized as pele does" {
  inspect(
    tokens(
      "flowchart TD\nclassDef green fill:#9f6,stroke:#333,stroke-width:2px;\nclass A green\nstyle B fill:#f9f\nlinkStyle 0,1 interpolate basis stroke:#ff3\nlinkStyle default stroke:red\nA:::green-->B\n",
    ),
    content=(
      #|GRAPH@0 "flowchart"
      #|DIR@9 " TD"
      #|NEWLINE@12 "\n"
      #|CLASSDEF@13 "classDef"
      #|SPACE@21 " "
      #|NODE_STRING@22 "green"
      #|SPACE@27 " "
      #|NODE_STRING@28 "fill"
      #|COLON@32 ":"
      #|BRKT@33 "#"
      #|NUM@34 "9"
      #|NODE_STRING@35 "f6"
      #|COMMA@37 ","
      #|NODE_STRING@38 "stroke"
      #|COLON@44 ":"
      #|BRKT@45 "#"
      #|NUM@46 "333"
      #|COMMA@49 ","
      #|NODE_STRING@50 "stroke-width"
      #|COLON@62 ":"
      #|NUM@63 "2"
      #|NODE_STRING@64 "px"
      #|SEMI@66 ";"
      #|NEWLINE@67 "\n"
      #|CLASS@68 "class"
      #|SPACE@73 " "
      #|NODE_STRING@74 "A"
      #|SPACE@75 " "
      #|NODE_STRING@76 "green"
      #|NEWLINE@81 "\n"
      #|STYLE@82 "style"
      #|SPACE@87 " "
      #|NODE_STRING@88 "B"
      #|SPACE@89 " "
      #|NODE_STRING@90 "fill"
      #|COLON@94 ":"
      #|BRKT@95 "#"
      #|NODE_STRING@96 "f9f"
      #|NEWLINE@99 "\n"
      #|LINKSTYLE@100 "linkStyle"
      #|SPACE@109 " "
      #|NUM@110 "0"
      #|COMMA@111 ","
      #|NUM@112 "1"
      #|SPACE@113 " "
      #|INTERPOLATE@114 "interpolate"
      #|SPACE@125 " "
      #|NODE_STRING@126 "basis"
      #|SPACE@131 " "
      #|NODE_STRING@132 "stroke"
      #|COLON@138 ":"
      #|BRKT@139 "#"
      #|NODE_STRING@140 "ff3"
      #|NEWLINE@143 "\n"
      #|LINKSTYLE@144 "linkStyle"
      #|SPACE@153 " "
      #|DEFAULT@154 "default"
      #|SPACE@161 " "
      #|NODE_STRING@162 "stroke"
      #|COLON@168 ":"
      #|NODE_STRING@169 "red"
      #|NEWLINE@172 "\n"
      #|NODE_STRING@173 "A"
      #|STYLE_SEPARATOR@174 ":::"
      #|NODE_STRING@177 "green"
      #|LINK@182 "-->"
      #|NODE_STRING@185 "B"
      #|NEWLINE@186 "\n"
      #|EOF@187 ""
      #|$end@187 ""
    ),
  )
}

///|
test "click statements are tokenized as pele does" {
  inspect(
    tokens(
      "graph TD\nclick A callback \"Tooltip\"\nclick B call cb(\"x\", 1) \"tip\"\nclick C href \"http://x\" _blank\nclick D \"u\" \"t\" _self\nclick E call cb()\n",
    ),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " TD"
      #|NEWLINE@8 "\n"
      #|CLICK@15 "A"
      #|NODE_STRING@17 "callback"
      #|SPACE@25 " "
      #|STR@27 "Tooltip"
      #|NEWLINE@35 "\n"
      #|CLICK@42 "B"
      #|CALLBACKNAME@49 "cb"
      #|CALLBACKARGS@52 "\"x\", 1"
      #|SPACE@59 " "
      #|STR@61 "tip"
      #|NEWLINE@65 "\n"
      #|CLICK@72 "C"
      #|HREF@74 "href "
      #|STR@80 "http://x"
      #|SPACE@89 " "
      #|LINK_TARGET@90 "_blank"
      #|NEWLINE@96 "\n"
      #|CLICK@103 "D"
      #|STR@106 "u"
      #|SPACE@108 " "
      #|STR@110 "t"
      #|SPACE@112 " "
      #|LINK_TARGET@113 "_self"
      #|NEWLINE@118 "\n"
      #|CLICK@125 "E"
      #|CALLBACKNAME@132 "cb"
      #|NEWLINE@136 "\n"
      #|EOF@137 ""
      #|$end@137 ""
    ),
  )
}

///|
test "accessibility statements are tokenized as pele does" {
  inspect(
    tokens(
      "graph TD\naccTitle: The title\naccDescr: A desc\naccDescr {\nmulti\nline\n}\nA\n",
    ),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " TD"
      #|NEWLINE@8 "\n"
      #|acc_title@9 "accTitle: "
      #|acc_title_value@19 "The title"
      #|NEWLINE@28 "\n"
      #|acc_descr@29 "accDescr: "
      #|acc_descr_value@39 "A desc"
      #|NEWLINE@45 "\n"
      #|acc_descr_multiline_value@57 "multi\nline\n"
      #|NEWLINE@69 "\n"
      #|NODE_STRING@70 "A"
      #|NEWLINE@71 "\n"
      #|EOF@72 ""
      #|$end@72 ""
    ),
  )
}

///|
test "node data and link ids are tokenized as pele does" {
  inspect(
    tokens(
      "flowchart TD\nA@{ shape: rounded, label: \"x\n  y\" }\ne1@-->B\ne1@{ animate: true }\n",
    ),
    content=(
      #|GRAPH@0 "flowchart"
      #|DIR@9 " TD"
      #|NEWLINE@12 "\n"
      #|NODE_STRING@13 "A"
      #|SHAPE_DATA@14 ""
      #|SHAPE_DATA@16 " shape: rounded, label: "
      #|SHAPE_DATA@40 "\""
      #|SHAPE_DATA@41 "x<br/>y"
      #|SHAPE_DATA@46 "\""
      #|SHAPE_DATA@47 " "
      #|NEWLINE@49 "\n"
      #|LINK_ID@50 "e1@"
      #|LINK@53 "-->"
      #|NODE_STRING@56 "B"
      #|NEWLINE@57 "\n"
      #|NODE_STRING@58 "e1"
      #|SHAPE_DATA@60 ""
      #|SHAPE_DATA@62 " animate: true "
      #|NEWLINE@78 "\n"
      #|EOF@79 ""
      #|$end@79 ""
    ),
  )
  inspect(
    tokens("graph TD\nA e1@--> B\nA x@y@--> C\nA@{a: \"b\"}@--> D\n"),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " TD"
      #|NEWLINE@8 "\n"
      #|NODE_STRING@9 "A"
      #|SPACE@10 " "
      #|LINK_ID@11 "e1@"
      #|LINK@14 "--> "
      #|NODE_STRING@18 "B"
      #|NEWLINE@19 "\n"
      #|NODE_STRING@20 "A"
      #|SPACE@21 " "
      #|LINK_ID@22 "x@y@"
      #|LINK@26 "--> "
      #|NODE_STRING@30 "C"
      #|NEWLINE@31 "\n"
      #|NODE_STRING@32 "A"
      #|SHAPE_DATA@33 ""
      #|SHAPE_DATA@35 "a: "
      #|SHAPE_DATA@38 "\""
      #|SHAPE_DATA@39 "b"
      #|SHAPE_DATA@40 "\""
      #|INVALID@42 ""
    ),
  )
}

///|
test "strings and Unicode text are tokenized as pele does" {
  inspect(
    tokens("graph TD\nA[\"quoted\"]-->B[\"`md **bold**`\"]\nC & D --> E\n"),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " TD"
      #|NEWLINE@8 "\n"
      #|NODE_STRING@9 "A"
      #|SQS@10 "["
      #|STR@12 "quoted"
      #|SQE@19 "]"
      #|LINK@20 "-->"
      #|NODE_STRING@23 "B"
      #|SQS@24 "["
      #|MD_STR@27 "md **bold**"
      #|SQE@40 "]"
      #|NEWLINE@41 "\n"
      #|NODE_STRING@42 "C"
      #|SPACE@43 " "
      #|AMP@44 "&"
      #|SPACE@45 " "
      #|NODE_STRING@46 "D"
      #|LINK@47 " --> "
      #|NODE_STRING@52 "E"
      #|NEWLINE@53 "\n"
      #|EOF@54 ""
      #|$end@54 ""
    ),
  )
  inspect(
    tokens("graph TD\n\u{e4}-->\u{f6}\n\u{65e5}\u{672c}-->\u{8a9e}\nA\"x\"B\n"),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " TD"
      #|NEWLINE@8 "\n"
      #|UNICODE_TEXT@9 "ä"
      #|LINK@10 "-->"
      #|UNICODE_TEXT@13 "ö"
      #|NEWLINE@14 "\n"
      #|UNICODE_TEXT@15 "日"
      #|UNICODE_TEXT@16 "本"
      #|LINK@17 "-->"
      #|UNICODE_TEXT@20 "語"
      #|NEWLINE@21 "\n"
      #|NODE_STRING@22 "A\"x\"B"
      #|NEWLINE@27 "\n"
      #|EOF@28 ""
      #|$end@28 ""
    ),
  )
  inspect(
    tokens(
      "graph TD\n  A --> B\n  v --> ^\n  1 --> 2\n  a.b --> c-d\n  #x --> *y\n",
    ),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " TD"
      #|NEWLINE@8 "\n"
      #|SPACE@9 "  "
      #|NODE_STRING@11 "A"
      #|LINK@12 " --> "
      #|NODE_STRING@17 "B"
      #|NEWLINE@18 "\n"
      #|SPACE@19 "  "
      #|DOWN@21 "v"
      #|LINK@22 " --> "
      #|UP@27 "^"
      #|NEWLINE@28 "\n"
      #|SPACE@29 "  "
      #|NUM@31 "1"
      #|LINK@32 " --> "
      #|NUM@37 "2"
      #|NEWLINE@38 "\n"
      #|SPACE@39 "  "
      #|NODE_STRING@41 "a.b"
      #|LINK@44 " --> "
      #|NODE_STRING@49 "c-d"
      #|NEWLINE@52 "\n"
      #|SPACE@53 "  "
      #|BRKT@55 "#"
      #|NODE_STRING@56 "x"
      #|LINK@57 " --> "
      #|MULT@62 "*"
      #|NODE_STRING@63 "y"
      #|NEWLINE@64 "\n"
      #|EOF@65 ""
      #|$end@65 ""
    ),
  )
}

///|
test "lexical errors are tokenized as pele does" {
  inspect(
    tokens("graph TD\nA(-x)]\n"),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " TD"
      #|NEWLINE@8 "\n"
      #|NODE_STRING@9 "A"
      #|(-@10 "(-"
      #|TEXT@12 "x"
      #|INVALID@13 ""
    ),
  )
  inspect(
    tokens("graph TD\nA{x]\n"),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " TD"
      #|NEWLINE@8 "\n"
      #|NODE_STRING@9 "A"
      #|DIAMOND_START@10 "{"
      #|TEXT@11 "x"
      #|SQE@12 "]"
      #|NEWLINE@13 "\n"
      #|EOF@14 ""
      #|$end@14 ""
    ),
  )
  inspect(
    tokens("graph TD\nA[/x}\n"),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " TD"
      #|NEWLINE@8 "\n"
      #|NODE_STRING@9 "A"
      #|TRAPSTART@10 "[/"
      #|TEXT@12 "x"
      #|INVALID@13 ""
    ),
  )
  inspect(
    tokens("graph TD\n\u{a7}\n"),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " TD"
      #|NEWLINE@8 "\n"
      #|INVALID@9 ""
    ),
  )
  inspect(
    tokens("graph TD\nA@{ ^ }\n"),
    content=(
      #|GRAPH@0 "graph"
      #|DIR@5 " TD"
      #|NEWLINE@8 "\n"
      #|NODE_STRING@9 "A"
      #|SHAPE_DATA@10 ""
      #|SHAPE_DATA@12 " "
      #|INVALID@13 ""
    ),
  )
}
