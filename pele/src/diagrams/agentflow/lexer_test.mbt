// The expected streams were taken from pele's agentflow lexer.

///|
/// The token stream one per line, as `NAME@start "text" line:column-line:column` with the text escaped.
fn lex(source : String) -> String {
  let tokens = @agentflow.tokenize(source)
  let lines = []
  for i, kind in tokens.types {
    lines.push(
      "\{@agentflow.token_names[kind]}@\{tokens.starts[i]} \{quote(tokens.texts[i])} \{tokens.first_lines[i]}:\{tokens.first_columns[i]}-\{tokens.last_lines[i]}:\{tokens.last_columns[i]}",
    )
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
      '\u{2028}' => out.write_string("\\u2028")
      '\u{2029}' => out.write_string("\\u2029")
      _ => out.write_char(c)
    }
  }
  out.write_char('"')
  out.to_string()
}

///|
test "reads the header, a labelled node and an arrow" {
  inspect(
    lex("agentflow-beta TB\n  a[\"A\"] --> b"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|SPACE@18 " " 2:0-2:1
      #|SPACE@19 " " 2:1-2:2
      #|NODE_STRING@20 "a" 2:2-2:3
      #|SQS@21 "[" 2:3-2:4
      #|STR@23 "A" 2:5-2:6
      #|SQE@25 "]" 2:7-2:8
      #|LINK@26 " --> " 2:8-2:13
      #|NODE_STRING@31 "b" 2:13-2:14
      #|EOF@32 "" 2:14-2:14
      #|$end@32 "" 2:14-2:14
    ),
  )
}

///|
test "reads a header without a direction" {
  inspect(
    lex("agentflow-beta\na"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|NODIR@14 "\n" 1:14-2:0
      #|NODE_STRING@15 "a" 2:0-2:1
      #|EOF@16 "" 2:1-2:1
      #|$end@16 "" 2:1-2:1
    ),
  )
}

///|
test "reads arrow symbols as directions" {
  inspect(
    lex("agentflow-beta >\na"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " >" 1:14-1:16
      #|NEWLINE@16 "\n" 1:16-2:0
      #|NODE_STRING@17 "a" 2:0-2:1
      #|EOF@18 "" 2:1-2:1
      #|$end@18 "" 2:1-2:1
    ),
  )
}

///|
test "counts CRLF as one line break" {
  inspect(
    lex("agentflow-beta LR\r\na --> b\r\nflow f@{ x: 1 }\r\nend"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " LR" 1:14-1:17
      #|NEWLINE@17 "\r\n" 1:17-2:0
      #|NODE_STRING@19 "a" 2:0-2:1
      #|LINK@20 " --> " 2:1-2:6
      #|NODE_STRING@25 "b" 2:6-2:7
      #|NEWLINE@26 "\r\n" 2:7-3:0
      #|flow@28 "flow" 3:0-3:4
      #|SPACE@32 " " 3:4-3:5
      #|NODE_STRING@33 "f" 3:5-3:6
      #|SHAPE_DATA@34 "" 3:6-3:8
      #|SHAPE_DATA@36 " x: 1 " 3:8-3:14
      #|NEWLINE@43 "\r\n" 3:15-4:0
      #|end@45 "end" 4:0-4:3
      #|EOF@48 "" 4:3-4:3
      #|$end@48 "" 4:3-4:3
    ),
  )
}

///|
test "stops a column after a break at U+2028" {
  inspect(
    lex("agentflow-beta\n  a[\"x\n y\u{2028}z\"]"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|NODIR@14 "\n" 1:14-2:0
      #|SPACE@15 " " 2:0-2:1
      #|SPACE@16 " " 2:1-2:2
      #|NODE_STRING@17 "a" 2:2-2:3
      #|SQS@18 "[" 2:3-2:4
      #|STR@20 "x\n y\u2028z" 2:5-3:2
      #|SQE@27 "]" 3:3-3:4
      #|EOF@28 "" 3:4-3:4
      #|$end@28 "" 3:4-3:4
    ),
  )
}

///|
test "counts each CRLF in an ellipse label as two breaks" {
  inspect(
    lex("agentflow-beta TB\na(-x\r\ny-)"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|NODE_STRING@18 "a" 2:0-2:1
      #|(-@19 "(-" 2:1-2:3
      #|TEXT@21 "x\r\ny" 2:3-4:1
      #|-)@25 "-)" 4:1-4:3
      #|EOF@27 "" 4:3-4:3
      #|$end@27 "" 4:3-4:3
    ),
  )
}

///|
test "counts each CRLF in edge text as two breaks" {
  inspect(
    lex("agentflow-beta TB\na -- x\r\ny --> b"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|NODE_STRING@18 "a" 2:0-2:1
      #|START_LINK@19 " -- " 2:1-2:5
      #|EDGE_TEXT@23 "x\r\ny" 2:5-4:1
      #|LINK@27 " --> " 4:1-4:6
      #|NODE_STRING@32 "b" 4:6-4:7
      #|EOF@33 "" 4:7-4:7
      #|$end@33 "" 4:7-4:7
    ),
  )
}

///|
test "reads every shape opener" {
  inspect(
    lex(
      "agentflow-beta TB\na(x) & b([x]) & c[[x]] & d[(x)] & e((x)) & f{x} & g{{x}} & h>x] & i[/x/] & j[\\x\\] & k[/x\\] & l[\\x/] & m(-x-)",
    ),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|NODE_STRING@18 "a" 2:0-2:1
      #|PS@19 "(" 2:1-2:2
      #|TEXT@20 "x" 2:2-2:3
      #|PE@21 ")" 2:3-2:4
      #|SPACE@22 " " 2:4-2:5
      #|AMP@23 "&" 2:5-2:6
      #|SPACE@24 " " 2:6-2:7
      #|NODE_STRING@25 "b" 2:7-2:8
      #|STADIUMSTART@26 "([" 2:8-2:10
      #|TEXT@28 "x" 2:10-2:11
      #|STADIUMEND@29 "])" 2:11-2:13
      #|SPACE@31 " " 2:13-2:14
      #|AMP@32 "&" 2:14-2:15
      #|SPACE@33 " " 2:15-2:16
      #|NODE_STRING@34 "c" 2:16-2:17
      #|SUBROUTINESTART@35 "[[" 2:17-2:19
      #|TEXT@37 "x" 2:19-2:20
      #|SUBROUTINEEND@38 "]]" 2:20-2:22
      #|SPACE@40 " " 2:22-2:23
      #|AMP@41 "&" 2:23-2:24
      #|SPACE@42 " " 2:24-2:25
      #|NODE_STRING@43 "d" 2:25-2:26
      #|CYLINDERSTART@44 "[(" 2:26-2:28
      #|TEXT@46 "x" 2:28-2:29
      #|CYLINDEREND@47 ")]" 2:29-2:31
      #|SPACE@49 " " 2:31-2:32
      #|AMP@50 "&" 2:32-2:33
      #|SPACE@51 " " 2:33-2:34
      #|NODE_STRING@52 "e" 2:34-2:35
      #|PS@53 "(" 2:35-2:36
      #|PS@54 "(" 2:36-2:37
      #|TEXT@55 "x" 2:37-2:38
      #|PE@56 ")" 2:38-2:39
      #|PE@57 ")" 2:39-2:40
      #|SPACE@58 " " 2:40-2:41
      #|AMP@59 "&" 2:41-2:42
      #|SPACE@60 " " 2:42-2:43
      #|NODE_STRING@61 "f" 2:43-2:44
      #|DIAMOND_START@62 "{" 2:44-2:45
      #|TEXT@63 "x" 2:45-2:46
      #|DIAMOND_STOP@64 "}" 2:46-2:47
      #|SPACE@65 " " 2:47-2:48
      #|AMP@66 "&" 2:48-2:49
      #|SPACE@67 " " 2:49-2:50
      #|NODE_STRING@68 "g" 2:50-2:51
      #|DIAMOND_START@69 "{" 2:51-2:52
      #|DIAMOND_START@70 "{" 2:52-2:53
      #|TEXT@71 "x" 2:53-2:54
      #|DIAMOND_STOP@72 "}" 2:54-2:55
      #|DIAMOND_STOP@73 "}" 2:55-2:56
      #|SPACE@74 " " 2:56-2:57
      #|AMP@75 "&" 2:57-2:58
      #|SPACE@76 " " 2:58-2:59
      #|NODE_STRING@77 "h" 2:59-2:60
      #|TAGEND@78 ">" 2:60-2:61
      #|TEXT@79 "x" 2:61-2:62
      #|SQE@80 "]" 2:62-2:63
      #|SPACE@81 " " 2:63-2:64
      #|AMP@82 "&" 2:64-2:65
      #|SPACE@83 " " 2:65-2:66
      #|NODE_STRING@84 "i" 2:66-2:67
      #|TRAPSTART@85 "[/" 2:67-2:69
      #|TEXT@87 "x" 2:69-2:70
      #|INVTRAPEND@88 "/]" 2:70-2:72
      #|SPACE@90 " " 2:72-2:73
      #|AMP@91 "&" 2:73-2:74
      #|SPACE@92 " " 2:74-2:75
      #|NODE_STRING@93 "j" 2:75-2:76
      #|INVTRAPSTART@94 "[\\" 2:76-2:78
      #|TEXT@96 "x" 2:78-2:79
      #|TRAPEND@97 "\\]" 2:79-2:81
      #|SPACE@99 " " 2:81-2:82
      #|AMP@100 "&" 2:82-2:83
      #|SPACE@101 " " 2:83-2:84
      #|NODE_STRING@102 "k" 2:84-2:85
      #|TRAPSTART@103 "[/" 2:85-2:87
      #|TEXT@105 "x" 2:87-2:88
      #|TRAPEND@106 "\\]" 2:88-2:90
      #|SPACE@108 " " 2:90-2:91
      #|AMP@109 "&" 2:91-2:92
      #|SPACE@110 " " 2:92-2:93
      #|NODE_STRING@111 "l" 2:93-2:94
      #|INVTRAPSTART@112 "[\\" 2:94-2:96
      #|TEXT@114 "x" 2:96-2:97
      #|INVTRAPEND@115 "/]" 2:97-2:99
      #|SPACE@117 " " 2:99-2:100
      #|AMP@118 "&" 2:100-2:101
      #|SPACE@119 " " 2:101-2:102
      #|NODE_STRING@120 "m" 2:102-2:103
      #|(-@121 "(-" 2:103-2:105
      #|TEXT@123 "x" 2:105-2:106
      #|-)@124 "-)" 2:106-2:108
      #|EOF@126 "" 2:108-2:108
      #|$end@126 "" 2:108-2:108
    ),
  )
}

///|
test "reads a vertex with props" {
  inspect(
    lex("agentflow-beta TB\na[|borderStyle:dotted|x]"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|NODE_STRING@18 "a" 2:0-2:1
      #|VERTEX_WITH_PROPS_START@19 "[|" 2:1-2:3
      #|NODE_STRING@21 "borderStyle" 2:3-2:14
      #|COLON@32 ":" 2:14-2:15
      #|NODE_STRING@33 "dotted" 2:15-2:21
      #|PIPE@39 "|" 2:21-2:22
      #|TEXT@40 "x" 2:22-2:23
      #|SQE@41 "]" 2:23-2:24
      #|EOF@42 "" 2:24-2:24
      #|$end@42 "" 2:24-2:24
    ),
  )
}

///|
test "reads the three arrows and a split one" {
  inspect(
    lex(
      "agentflow-beta TB\na --> b\na --x c\na -.- d\na -- text --> e\na ---> f",
    ),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|NODE_STRING@18 "a" 2:0-2:1
      #|LINK@19 " --> " 2:1-2:6
      #|NODE_STRING@24 "b" 2:6-2:7
      #|NEWLINE@25 "\n" 2:7-3:0
      #|NODE_STRING@26 "a" 3:0-3:1
      #|LINK@27 " --x " 3:1-3:6
      #|NODE_STRING@32 "c" 3:6-3:7
      #|NEWLINE@33 "\n" 3:7-4:0
      #|NODE_STRING@34 "a" 4:0-4:1
      #|LINK@35 " -.- " 4:1-4:6
      #|NODE_STRING@40 "d" 4:6-4:7
      #|NEWLINE@41 "\n" 4:7-5:0
      #|NODE_STRING@42 "a" 5:0-5:1
      #|START_LINK@43 " -- " 5:1-5:5
      #|EDGE_TEXT@47 "text" 5:5-5:9
      #|LINK@51 " --> " 5:9-5:14
      #|NODE_STRING@56 "e" 5:14-5:15
      #|NEWLINE@57 "\n" 5:15-6:0
      #|NODE_STRING@58 "a" 6:0-6:1
      #|LINK@59 " ---> " 6:1-6:7
      #|NODE_STRING@65 "f" 6:7-6:8
      #|EOF@66 "" 6:8-6:8
      #|$end@66 "" 6:8-6:8
    ),
  )
}

///|
test "reads an edge id" {
  inspect(
    lex("agentflow-beta TB\na e1@--> b\na e2@-.- c"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|NODE_STRING@18 "a" 2:0-2:1
      #|SPACE@19 " " 2:1-2:2
      #|LINK_ID@20 "e1@" 2:2-2:5
      #|LINK@23 "--> " 2:5-2:9
      #|NODE_STRING@27 "b" 2:9-2:10
      #|NEWLINE@28 "\n" 2:10-3:0
      #|NODE_STRING@29 "a" 3:0-3:1
      #|SPACE@30 " " 3:1-3:2
      #|LINK_ID@31 "e2@" 3:2-3:5
      #|LINK@34 "-.- " 3:5-3:9
      #|NODE_STRING@38 "c" 3:9-3:10
      #|EOF@39 "" 3:10-3:10
      #|$end@39 "" 3:10-3:10
    ),
  )
}

///|
test "reads metadata with quoted strings and line breaks" {
  inspect(
    lex("agentflow-beta TB\na@{ label: \"one\n   two\", shape: tool }"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|NODE_STRING@18 "a" 2:0-2:1
      #|SHAPE_DATA@19 "" 2:1-2:3
      #|SHAPE_DATA@21 " label: " 2:3-2:11
      #|SHAPE_DATA@29 "\"" 2:11-2:12
      #|SHAPE_DATA@30 "one<br/>two" 2:12-3:6
      #|SHAPE_DATA@40 "\"" 3:6-3:7
      #|SHAPE_DATA@41 ", shape: tool " 3:7-3:21
      #|EOF@56 "" 3:22-3:22
      #|$end@56 "" 3:22-3:22
    ),
  )
}

///|
test "reads flow, connector, global and end" {
  inspect(
    lex(
      "agentflow-beta TB\nflow f[\"Title\"]@{ view: collapsed }\n  a\nend\nconnector c[\"C\"]\nglobal\n  b\nend   \n",
    ),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|flow@18 "flow" 2:0-2:4
      #|SPACE@22 " " 2:4-2:5
      #|NODE_STRING@23 "f" 2:5-2:6
      #|SQS@24 "[" 2:6-2:7
      #|STR@26 "Title" 2:8-2:13
      #|SQE@32 "]" 2:14-2:15
      #|SHAPE_DATA@33 "" 2:15-2:17
      #|SHAPE_DATA@35 " view: collapsed " 2:17-2:34
      #|NEWLINE@53 "\n" 2:35-3:0
      #|SPACE@54 " " 3:0-3:1
      #|SPACE@55 " " 3:1-3:2
      #|NODE_STRING@56 "a" 3:2-3:3
      #|NEWLINE@57 "\n" 3:3-4:0
      #|end@58 "end" 4:0-4:3
      #|NEWLINE@61 "\n" 4:3-5:0
      #|connector@62 "connector" 5:0-5:9
      #|SPACE@71 " " 5:9-5:10
      #|NODE_STRING@72 "c" 5:10-5:11
      #|SQS@73 "[" 5:11-5:12
      #|STR@75 "C" 5:13-5:14
      #|SQE@77 "]" 5:15-5:16
      #|NEWLINE@78 "\n" 5:16-6:0
      #|global@79 "global" 6:0-6:6
      #|NEWLINE@85 "\n" 6:6-7:0
      #|SPACE@86 " " 7:0-7:1
      #|SPACE@87 " " 7:1-7:2
      #|NODE_STRING@88 "b" 7:2-7:3
      #|NEWLINE@89 "\n" 7:3-8:0
      #|end@90 "end   " 8:0-8:6
      #|NEWLINE@96 "\n" 8:6-9:0
      #|EOF@97 "" 9:0-9:0
      #|$end@97 "" 9:0-9:0
    ),
  )
}

///|
test "reads accessibility statements" {
  inspect(
    lex(
      "agentflow-beta TB\naccTitle: The title\naccDescr: one line\naccDescr {\n  many\n  lines\n}\na",
    ),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|acc_title@18 "accTitle: " 2:0-2:10
      #|acc_title_value@28 "The title" 2:10-2:19
      #|NEWLINE@37 "\n" 2:19-3:0
      #|acc_descr@38 "accDescr: " 3:0-3:10
      #|acc_descr_value@48 "one line" 3:10-3:18
      #|NEWLINE@56 "\n" 3:18-4:0
      #|acc_descr_multiline_value@70 "many\n  lines\n" 5:2-7:0
      #|NEWLINE@84 "\n" 7:1-8:0
      #|NODE_STRING@85 "a" 8:0-8:1
      #|EOF@86 "" 8:1-8:1
      #|$end@86 "" 8:1-8:1
    ),
  )
}

///|
test "reads click and call statements" {
  inspect(
    lex(
      "agentflow-beta TB\nclick a call fn(x, y) \"tip\"\nclick b href \"http://x\" _blank\nclick c call go()\nclick d \"u\"",
    ),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|CLICK@24 "a" 2:6-2:7
      #|CALLBACKNAME@31 "fn" 2:13-2:15
      #|CALLBACKARGS@34 "x, y" 2:16-2:20
      #|SPACE@39 " " 2:21-2:22
      #|STR@41 "tip" 2:23-2:26
      #|NEWLINE@45 "\n" 2:27-3:0
      #|CLICK@52 "b" 3:6-3:7
      #|HREF@54 "href " 3:8-3:13
      #|STR@60 "http://x" 3:14-3:22
      #|SPACE@69 " " 3:23-3:24
      #|LINK_TARGET@70 "_blank" 3:24-3:30
      #|NEWLINE@76 "\n" 3:30-4:0
      #|CLICK@83 "c" 4:6-4:7
      #|CALLBACKNAME@90 "go" 4:13-4:15
      #|NEWLINE@94 "\n" 4:17-5:0
      #|CLICK@101 "d" 5:6-5:7
      #|STR@104 "u" 5:9-5:10
      #|EOF@106 "" 5:11-5:11
      #|$end@106 "" 5:11-5:11
    ),
  )
}

///|
test "reads style, classDef, class and linkStyle" {
  inspect(
    lex(
      "agentflow-beta TB\nstyle a fill:#f9f,stroke:#333\nclassDef big font-size:20px\nclass a,b big\nlinkStyle 0,1 interpolate basis stroke:red\nlinkStyle default stroke:blue\na:::big",
    ),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|STYLE@18 "style" 2:0-2:5
      #|SPACE@23 " " 2:5-2:6
      #|NODE_STRING@24 "a" 2:6-2:7
      #|SPACE@25 " " 2:7-2:8
      #|NODE_STRING@26 "fill" 2:8-2:12
      #|COLON@30 ":" 2:12-2:13
      #|BRKT@31 "#" 2:13-2:14
      #|NODE_STRING@32 "f9f" 2:14-2:17
      #|COMMA@35 "," 2:17-2:18
      #|NODE_STRING@36 "stroke" 2:18-2:24
      #|COLON@42 ":" 2:24-2:25
      #|BRKT@43 "#" 2:25-2:26
      #|NUM@44 "333" 2:26-2:29
      #|NEWLINE@47 "\n" 2:29-3:0
      #|CLASSDEF@48 "classDef" 3:0-3:8
      #|SPACE@56 " " 3:8-3:9
      #|NODE_STRING@57 "big" 3:9-3:12
      #|SPACE@60 " " 3:12-3:13
      #|NODE_STRING@61 "font-size" 3:13-3:22
      #|COLON@70 ":" 3:22-3:23
      #|NUM@71 "20" 3:23-3:25
      #|NODE_STRING@73 "px" 3:25-3:27
      #|NEWLINE@75 "\n" 3:27-4:0
      #|CLASS@76 "class" 4:0-4:5
      #|SPACE@81 " " 4:5-4:6
      #|NODE_STRING@82 "a" 4:6-4:7
      #|COMMA@83 "," 4:7-4:8
      #|NODE_STRING@84 "b" 4:8-4:9
      #|SPACE@85 " " 4:9-4:10
      #|NODE_STRING@86 "big" 4:10-4:13
      #|NEWLINE@89 "\n" 4:13-5:0
      #|LINKSTYLE@90 "linkStyle" 5:0-5:9
      #|SPACE@99 " " 5:9-5:10
      #|NUM@100 "0" 5:10-5:11
      #|COMMA@101 "," 5:11-5:12
      #|NUM@102 "1" 5:12-5:13
      #|SPACE@103 " " 5:13-5:14
      #|INTERPOLATE@104 "interpolate" 5:14-5:25
      #|SPACE@115 " " 5:25-5:26
      #|NODE_STRING@116 "basis" 5:26-5:31
      #|SPACE@121 " " 5:31-5:32
      #|NODE_STRING@122 "stroke" 5:32-5:38
      #|COLON@128 ":" 5:38-5:39
      #|NODE_STRING@129 "red" 5:39-5:42
      #|NEWLINE@132 "\n" 5:42-6:0
      #|LINKSTYLE@133 "linkStyle" 6:0-6:9
      #|SPACE@142 " " 6:9-6:10
      #|DEFAULT@143 "default" 6:10-6:17
      #|SPACE@150 " " 6:17-6:18
      #|NODE_STRING@151 "stroke" 6:18-6:24
      #|COLON@157 ":" 6:24-6:25
      #|NODE_STRING@158 "blue" 6:25-6:29
      #|NEWLINE@162 "\n" 6:29-7:0
      #|NODE_STRING@163 "a" 7:0-7:1
      #|STYLE_SEPARATOR@164 ":::" 7:1-7:4
      #|NODE_STRING@167 "big" 7:4-7:7
      #|EOF@170 "" 7:7-7:7
      #|$end@170 "" 7:7-7:7
    ),
  )
}

///|
test "reads direction statements" {
  inspect(
    lex("agentflow-beta TB\nflow f\n  direction LR\n  x direction RL\nend"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|flow@18 "flow" 2:0-2:4
      #|SPACE@22 " " 2:4-2:5
      #|NODE_STRING@23 "f" 2:5-2:6
      #|NEWLINE@24 "\n" 2:6-3:0
      #|direction_lr@25 "  direction LR" 3:0-3:14
      #|NEWLINE@39 "\n" 3:14-4:0
      #|direction_rl@40 "  x direction RL" 4:0-4:16
      #|NEWLINE@56 "\n" 4:16-5:0
      #|end@57 "end" 5:0-5:3
      #|EOF@60 "" 5:3-5:3
      #|$end@60 "" 5:3-5:3
    ),
  )
}

///|
test "reads comments" {
  inspect(
    lex(
      "agentflow-beta TB\n%% a comment\n  %% indented\na[\"x %% y\"] %% trailing\n%%{init: {}}%%",
    ),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|COMMENT@18 "%% a comment" 2:0-2:12
      #|NEWLINE@30 "\n" 2:12-3:0
      #|COMMENT@31 "  %% indented" 3:0-3:13
      #|NEWLINE@44 "\n" 3:13-4:0
      #|NODE_STRING@45 "a" 4:0-4:1
      #|SQS@46 "[" 4:1-4:2
      #|STR@48 "x %% y" 4:3-4:9
      #|SQE@55 "]" 4:10-4:11
      #|COMMENT@56 " %% trailing" 4:11-4:23
      #|NEWLINE@68 "\n" 4:23-5:0
      #|NODE_STRING@69 "%%" 5:0-5:2
      #|DIAMOND_START@71 "{" 5:2-5:3
      #|TEXT@72 "init: " 5:3-5:9
      #|DIAMOND_START@78 "{" 5:9-5:10
      #|DIAMOND_STOP@79 "}" 5:10-5:11
      #|DIAMOND_STOP@80 "}" 5:11-5:12
      #|COMMENT@81 "%%" 5:12-5:14
      #|EOF@83 "" 5:14-5:14
      #|$end@83 "" 5:14-5:14
    ),
  )
}

///|
test "reads markdown strings" {
  inspect(
    lex("agentflow-beta TB\na[\"`**bold** _it_`\"]"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|NODE_STRING@18 "a" 2:0-2:1
      #|SQS@19 "[" 2:1-2:2
      #|MD_STR@22 "**bold** _it_" 2:4-2:17
      #|SQE@37 "]" 2:19-2:20
      #|EOF@38 "" 2:20-2:20
      #|$end@38 "" 2:20-2:20
    ),
  )
}

///|
test "reads link targets and numbers" {
  inspect(
    lex("agentflow-beta TB\nclick a \"u\" _self\na1 --> 23"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|CLICK@24 "a" 2:6-2:7
      #|STR@27 "u" 2:9-2:10
      #|SPACE@29 " " 2:11-2:12
      #|LINK_TARGET@30 "_self" 2:12-2:17
      #|NEWLINE@35 "\n" 2:17-3:0
      #|NODE_STRING@36 "a1" 3:0-3:2
      #|LINK@38 " --> " 3:2-3:7
      #|NUM@43 "23" 3:7-3:9
      #|EOF@45 "" 3:9-3:9
      #|$end@45 "" 3:9-3:9
    ),
  )
}

///|
test "reads unicode letters" {
  inspect(
    lex("agentflow-beta TB\nä --> 日本"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|UNICODE_TEXT@18 "ä" 2:0-2:1
      #|LINK@19 " --> " 2:1-2:6
      #|UNICODE_TEXT@24 "日" 2:6-2:7
      #|UNICODE_TEXT@25 "本" 2:7-2:8
      #|EOF@26 "" 2:8-2:8
      #|$end@26 "" 2:8-2:8
    ),
  )
}

///|
test "stops at an unrecognized character in a label" {
  inspect(
    lex("agentflow-beta TB\na[x}"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|NODE_STRING@18 "a" 2:0-2:1
      #|SQS@19 "[" 2:1-2:2
      #|TEXT@20 "x" 2:2-2:3
      #|DIAMOND_STOP@21 "}" 2:3-2:4
      #|EOF@22 "" 2:4-2:4
      #|$end@22 "" 2:4-2:4
    ),
  )
}

///|
test "stops at a lone percent sign in a label" {
  inspect(
    lex("agentflow-beta TB\na[x % y]"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|NODE_STRING@18 "a" 2:0-2:1
      #|SQS@19 "[" 2:1-2:2
      #|TEXT@20 "x " 2:2-2:4
      #|INVALID@22 "" 2:4-2:4
    ),
  )
}

///|
test "reads trapezoid ends" {
  inspect(
    lex("agentflow-beta TB\na[/x?] & b[/x=] & c[/x)] "),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|NODE_STRING@18 "a" 2:0-2:1
      #|TRAPSTART@19 "[/" 2:1-2:3
      #|TEXT@21 "x?" 2:3-2:5
      #|INVALID@23 "" 2:5-2:5
    ),
  )
}

///|
test "reads a link id run with an at sign before braces" {
  inspect(
    lex("agentflow-beta TB\na@b@{ x: 1 }"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|LINK_ID@18 "a@" 2:0-2:2
      #|NODE_STRING@20 "b" 2:2-2:3
      #|SHAPE_DATA@21 "" 2:3-2:5
      #|SHAPE_DATA@23 " x: 1 " 2:5-2:11
      #|EOF@30 "" 2:12-2:12
      #|$end@30 "" 2:12-2:12
    ),
  )
}

///|
test "reads minus and lone dashes" {
  inspect(
    lex("agentflow-beta TB\na - b\na-b\n-"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|NODE_STRING@18 "a" 2:0-2:1
      #|SPACE@19 " " 2:1-2:2
      #|NODE_STRING@20 "-" 2:2-2:3
      #|SPACE@21 " " 2:3-2:4
      #|NODE_STRING@22 "b" 2:4-2:5
      #|NEWLINE@23 "\n" 2:5-3:0
      #|NODE_STRING@24 "a-b" 3:0-3:3
      #|NEWLINE@27 "\n" 3:3-4:0
      #|MINUS@28 "-" 4:0-4:1
      #|EOF@29 "" 4:1-4:1
      #|$end@29 "" 4:1-4:1
    ),
  )
}

///|
test "reads ellipse text with a comment" {
  inspect(
    lex("agentflow-beta TB\na(-x %% c\n y-)"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|NODE_STRING@18 "a" 2:0-2:1
      #|(-@19 "(-" 2:1-2:3
      #|TEXT@21 "x " 2:3-2:5
      #|TEXT@27 "\n y" 2:9-3:2
      #|-)@30 "-)" 3:2-3:4
      #|EOF@32 "" 3:4-3:4
      #|$end@32 "" 3:4-3:4
    ),
  )
}

///|
test "reads an unterminated string to the end" {
  inspect(
    lex("agentflow-beta TB\na[\"x"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|NODE_STRING@18 "a" 2:0-2:1
      #|SQS@19 "[" 2:1-2:2
      #|STR@21 "x" 2:3-2:4
      #|$end@22 "" 2:4-2:4
    ),
  )
}

///|
test "reads shape data quotes left open" {
  inspect(
    lex("agentflow-beta TB\na@{ k: \"v"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|NODE_STRING@18 "a" 2:0-2:1
      #|SHAPE_DATA@19 "" 2:1-2:3
      #|SHAPE_DATA@21 " k: " 2:3-2:7
      #|SHAPE_DATA@25 "\"" 2:7-2:8
      #|SHAPE_DATA@26 "v" 2:8-2:9
      #|$end@27 "" 2:9-2:9
    ),
  )
}

///|
test "reads an empty source" {
  inspect(
    lex(""),
    content=(
      #|EOF@0 "" 1:0-1:0
      #|$end@0 "" 1:0-1:0
    ),
  )
}

///|
test "reads a blank-line fold before a brace" {
  inspect(
    lex("agentflow-beta TB\na@{ k: 1 }   \n\nb"),
    content=(
      #|GRAPH@0 "agentflow-beta" 1:0-1:14
      #|DIR@14 " TB" 1:14-1:17
      #|NEWLINE@17 "\n" 1:17-2:0
      #|NODE_STRING@18 "a" 2:0-2:1
      #|SHAPE_DATA@19 "" 2:1-2:3
      #|SHAPE_DATA@21 " k: 1 " 2:3-2:9
      #|SPACE@28 " " 2:10-2:11
      #|SPACE@29 " " 2:11-2:12
      #|SPACE@30 " " 2:12-2:13
      #|NEWLINE@31 "\n\n" 2:13-4:0
      #|NODE_STRING@33 "b" 4:0-4:1
      #|EOF@34 "" 4:1-4:1
      #|$end@34 "" 4:1-4:1
    ),
  )
}
