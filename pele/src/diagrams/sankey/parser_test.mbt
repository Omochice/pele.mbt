///|
fn tokens(src : String) -> String {
  let found = @sankey.tokenize(src)
  let parts = []
  for i, kind in found.types {
    parts.push("\{kind.name()}:\{found.texts[i].escape()}@\{found.starts[i]}")
  }
  parts.join(" ")
}

///|
test "the keyword, rows, and quoted fields are split into tokens" {
  inspect(
    tokens("sankey\na,\"b \"\"c\"\"\",1"),
    content="SANKEY:\"sankey\"@0 NEWLINE:\"\\n\"@6 NON_ESCAPED_TEXT:\"a\"@7 COMMA:\",\"@8 DQUOTE:\"\\\"\"@9 ESCAPED_TEXT:\"b \\\"\\\"c\\\"\\\"\"@10 DQUOTE:\"\\\"\"@17 COMMA:\",\"@18 NON_ESCAPED_TEXT:\"1\"@19 EOF:\"\"@20 $end:\"\"@20",
  )
}

///|
test "the keyword is case-insensitive, may carry -beta, and must end at a non-word character" {
  inspect(
    tokens("SANKEY-beta\n"),
    content="SANKEY:\"SANKEY-beta\"@0 NEWLINE:\"\\n\"@11 EOF:\"\"@12 $end:\"\"@12",
  )
  inspect(
    tokens("sankeyx"),
    content="NON_ESCAPED_TEXT:\"sankeyx\"@0 EOF:\"\"@7 $end:\"\"@7",
  )
  inspect(
    tokens("sankey-"),
    content="SANKEY:\"sankey\"@0 NON_ESCAPED_TEXT:\"-\"@6 EOF:\"\"@7 $end:\"\"@7",
  )
  inspect(
    tokens("san\u{212A}ey"),
    content="SANKEY:\"san\u{212A}ey\"@0 EOF:\"\"@6 $end:\"\"@6",
  )
}

///|
test "the keyword is recognised once, wherever it first appears" {
  inspect(
    tokens("a\nsankey"),
    content="NON_ESCAPED_TEXT:\"a\"@0 NEWLINE:\"\\n\"@1 SANKEY:\"sankey\"@2 EOF:\"\"@8 $end:\"\"@8",
  )
  inspect(
    tokens("sankey\nsankey"),
    content="SANKEY:\"sankey\"@0 NEWLINE:\"\\n\"@6 NON_ESCAPED_TEXT:\"sankey\"@7 EOF:\"\"@13 $end:\"\"@13",
  )
}

///|
test "a character outside the CSV alphabet stops the lexer" {
  inspect(
    tokens("sankey\n\u{80}"),
    content="SANKEY:\"sankey\"@0 NEWLINE:\"\\n\"@6 NON_ESCAPED_TEXT:\"\"@7 STUCK:\"\"@7",
  )
  inspect(
    tokens("a\rb"),
    content="NON_ESCAPED_TEXT:\"a\"@0 NON_ESCAPED_TEXT:\"\"@1 STUCK:\"\"@1",
  )
  inspect(
    tokens("\"a\tb\""),
    content="DQUOTE:\"\\\"\"@0 ESCAPED_TEXT:\"a\"@1 ESCAPED_TEXT:\"\"@2 STUCK:\"\"@2",
  )
}

///|
test "quoted text may hold commas and line breaks, and an unclosed quote ends in escaped text" {
  inspect(
    tokens("\"a,b\nc\""),
    content="DQUOTE:\"\\\"\"@0 ESCAPED_TEXT:\"a,b\\nc\"@1 DQUOTE:\"\\\"\"@6 EOF:\"\"@7 $end:\"\"@7",
  )
  inspect(
    tokens("\"ab"),
    content="DQUOTE:\"\\\"\"@0 ESCAPED_TEXT:\"ab\"@1 ESCAPED_TEXT:\"\"@3 $end:\"\"@3",
  )
}

///|
fn rows(source : String) -> String {
  let db = @sankey.SankeyDb::new()
  @sankey.parse_sankey(@sankey.prepare_text_for_parsing(source + "\n"), db) catch {
    @errors.PeleError(failure) => return failure.message
  }
  let nodes = db.nodes.map(node => node.id.escape())
  let links = db.links.map(link => {
    "\{link.source.id.escape()}>\{link.target.id.escape()}=\{link.value}"
  })
  "nodes=\{nodes.join(",")} links=\{links.join(",")}"
}

///|
test "rows become nodes in order of appearance and links" {
  inspect(
    rows("sankey\na,b,1"),
    content="nodes=\"a\",\"b\" links=\"a\">\"b\"=1",
  )
  inspect(
    rows("sankey-beta\n\n  a , b , 10  \n\n\"x\",y,\"7\""),
    content="nodes=\"a\",\"b\",\"x\",\"y\" links=\"a\">\"b\"=10,\"x\">\"y\"=7",
  )
}

///|
test "quoted fields keep commas and unescape doubled quotes" {
  inspect(
    rows(
      "sankey\n\"Heating, \"\"homes\"\"\",Agricultural 'waste',1\n  Lighting & appliances - commercial  , Over generation / exports ,2",
    ),
    content="nodes=\"Heating, \\\"homes\\\"\",\"Agricultural 'waste'\",\"Lighting & appliances - commercial\",\"Over generation / exports\" links=\"Heating, \\\"homes\\\"\">\"Agricultural 'waste'\"=1,\"Lighting & appliances - commercial\">\"Over generation / exports\"=2",
  )
}

///|
test "amounts are read as far as they are numbers, and a non-finite one is refused" {
  let shown = []
  for
    value in [
      "1e3", "-2.5", "+.5", "7.", "-2.5x", "abc", "", "\"1\n2\"", "Infinity", "1e400",
      "-", "0x10", "1e", " 3 ",
    ] {
    shown.push(value.escape() + " " + rows("sankey\na,b,\{value}"))
  }
  inspect(
    shown.join("\n"),
    content=(
      #|"1e3" nodes="a","b" links="a">"b"=1000
      #|"-2.5" nodes="a","b" links="a">"b"=-2.5
      #|"+.5" nodes="a","b" links="a">"b"=0.5
      #|"7." nodes="a","b" links="a">"b"=7
      #|"-2.5x" nodes="a","b" links="a">"b"=-2.5
      #|"abc" Parse error on line 2:
      #|a,b,abc
      #|----^
      #|Expecting a number
      #|"" Parse error on line 2:
      #|a,b,
      #|----^
      #|Expecting 'DQUOTE', 'NON_ESCAPED_TEXT', got 'EOF'
      #|"\"1\n2\"" nodes="a","b" links="a">"b"=1
      #|"Infinity" Parse error on line 2:
      #|a,b,Infinity
      #|----^
      #|Expecting a number
      #|"1e400" Parse error on line 2:
      #|a,b,1e400
      #|----^
      #|Expecting a number
      #|"-" Parse error on line 2:
      #|a,b,-
      #|----^
      #|Expecting a number
      #|"0x10" nodes="a","b" links="a">"b"=0
      #|"1e" nodes="a","b" links="a">"b"=1
      #|" 3 " nodes="a","b" links="a">"b"=3
    ),
  )
}

///|
test "a name that is a property of Object is an ordinary node" {
  inspect(
    rows("sankey\n__proto__,A,0.597\nA,__proto__,0.403"),
    content="nodes=\"__proto__\",\"A\" links=\"__proto__\">\"A\"=0.597,\"A\">\"__proto__\"=0.403",
  )
}

///|
test "a text without rows is rejected where Mermaid rejects it" {
  inspect(
    rows("sankey"),
    content="Parse error on line 1:\nsankey\n------^\nExpecting 'NEWLINE', got 'EOF'",
  )
  inspect(
    rows("sankey x\na,b,1"),
    content="Parse error on line 1:\nsankey x\n------^\nExpecting 'NEWLINE', got 'NON_ESCAPED_TEXT'",
  )
  inspect(
    rows("sankey-betax\na,b,1"),
    content="Parse error on line 1:\nsankey-betax\n------^\nExpecting 'NEWLINE', got 'NON_ESCAPED_TEXT'",
  )
  inspect(
    rows("sankey-beta,a,b,1"),
    content="Parse error on line 1:\nsankey-beta,a,b,1\n-----------^\nExpecting 'NEWLINE', got 'COMMA'",
  )
}

///|
test "a row must have three fields" {
  inspect(
    rows("sankey\na,b"),
    content="Parse error on line 2:\na,b\n---^\nExpecting 'COMMA', 'NEWLINE', 'EOF', got 'EOF'",
  )
  inspect(
    rows("sankey\na,b,1,2"),
    content="Parse error on line 2:\na,b,1,2\n-----^\nExpecting 'NEWLINE', 'EOF', got 'COMMA'",
  )
  inspect(
    rows("sankey\na,,1"),
    content="Parse error on line 2:\na,,1\n--^\nExpecting 'DQUOTE', 'NON_ESCAPED_TEXT', got 'COMMA'",
  )
  inspect(
    rows("sankey\n,b,1"),
    content="Parse error on line 2:\n,b,1\n^\nExpecting 'DQUOTE', 'NON_ESCAPED_TEXT', got 'COMMA'",
  )
}

///|
test "quoted fields must be well formed" {
  inspect(
    rows("sankey\n\"\",b,1"),
    content="Parse error on line 2:\n\"\",b,1\n-^\nExpecting 'ESCAPED_TEXT', got 'DQUOTE'",
  )
  inspect(
    rows("sankey\na,\"b,1"),
    content="Parse error on line 2:\na,\"b,1\n------^\nExpecting 'DQUOTE', got 'ESCAPED_TEXT'",
  )
  inspect(
    rows("sankey\na,\"b\"x,1"),
    content="Parse error on line 2:\na,\"b\"x,1\n-----^\nExpecting 'COMMA', 'NEWLINE', 'EOF', got 'NON_ESCAPED_TEXT'",
  )
}

///|
test "characters outside the CSV alphabet are reported as the token before them" {
  inspect(
    rows("sankey\nCaf\u{7f},Bar,1"),
    content=(
      #|Parse error on line 2:
      #|Caf,Bar,1
      #|---^
      #|Expecting 'COMMA', 'NEWLINE', 'EOF', got 'NON_ESCAPED_TEXT'
    ),
  )
}

///|
test "a blank row inside the text is rejected" {
  inspect(
    rows("sankey\na,b,1\n   \nc,d,2"),
    content="Parse error on line 3:\n   \n---^\nExpecting 'COMMA', 'NEWLINE', 'EOF', got 'NEWLINE'",
  )
}

///|
test "preparing the text trims its ends and collapses line breaks" {
  inspect(
    @sankey.prepare_text_for_parsing(" \t\n\r\nsankey\r\n\r\n\na,b,1 \t\n\n"),
    content="sankey\na,b,1",
  )
  inspect(
    @sankey.prepare_text_for_parsing("\u{3000}sankey\u{a0}\na\u{a0}\n\u{feff}"),
    content="sankey\u{a0}\na",
  )
}

///|
test "names may hold any Unicode text, quoted or not" {
  let shown = []
  for keyword in ["sankey", "sankey-beta"] {
    for
      pair in [
        ("Доход", "Расходы"),
        ("Café", "München"),
        ("収入", "支出"),
        ("☀️", "🏠"),
        ("Cafe\u{301}", "Cafe\u{300}"),
      ] {
      let (from, to) = pair
      shown.push(rows("\{keyword}\n\{from},\{to},100"))
      shown.push(rows("\{keyword}\n\"\{from}\",\"\{to}\",100"))
    }
    shown.push(
      rows(
        "\{keyword}\n\"Доход, \"\"чистый\"\"\",Café,2\nCafé,収入,1",
      ),
    )
  }
  inspect(
    shown.join("\n"),
    content=(
      #|nodes="Доход","Расходы" links="Доход">"Расходы"=100
      #|nodes="Доход","Расходы" links="Доход">"Расходы"=100
      #|nodes="Café","München" links="Café">"München"=100
      #|nodes="Café","München" links="Café">"München"=100
      #|nodes="収入","支出" links="収入">"支出"=100
      #|nodes="収入","支出" links="収入">"支出"=100
      #|nodes="☀️","🏠" links="☀️">"🏠"=100
      #|nodes="☀️","🏠" links="☀️">"🏠"=100
      #|nodes="Café","Cafè" links="Café">"Cafè"=100
      #|nodes="Café","Cafè" links="Café">"Cafè"=100
      #|nodes="Доход, \"чистый\"","Café","収入" links="Доход, \"чистый\"">"Café"=2,"Café">"収入"=1
      #|nodes="Доход","Расходы" links="Доход">"Расходы"=100
      #|nodes="Доход","Расходы" links="Доход">"Расходы"=100
      #|nodes="Café","München" links="Café">"München"=100
      #|nodes="Café","München" links="Café">"München"=100
      #|nodes="収入","支出" links="収入">"支出"=100
      #|nodes="収入","支出" links="収入">"支出"=100
      #|nodes="☀️","🏠" links="☀️">"🏠"=100
      #|nodes="☀️","🏠" links="☀️">"🏠"=100
      #|nodes="Café","Cafè" links="Café">"Cafè"=100
      #|nodes="Café","Cafè" links="Café">"Cafè"=100
      #|nodes="Доход, \"чистый\"","Café","収入" links="Доход, \"чистый\"">"Café"=2,"Café">"収入"=1
    ),
  )
}

///|
test "malformed rows with Unicode names are rejected" {
  let shown = []
  for
    row in [
      "Доход,Расходы", "Доход,Расходы,1,2", "\"Доход,Расходы,1",
      "\"Доход\"x,Расходы,1", "Доход,,1",
    ] {
    shown.push(rows("sankey\n\{row}"))
  }
  inspect(
    shown.join("\n"),
    content=(
      #|Parse error on line 2:
      #|Доход,Расходы
      #|-------------^
      #|Expecting 'COMMA', 'NEWLINE', 'EOF', got 'EOF'
      #|Parse error on line 2:
      #|Доход,Расходы,1,2
      #|---------------^
      #|Expecting 'NEWLINE', 'EOF', got 'COMMA'
      #|Parse error on line 2:
      #|"Доход,Расходы,1
      #|----------------^
      #|Expecting 'DQUOTE', got 'ESCAPED_TEXT'
      #|Parse error on line 2:
      #|"Доход"x,Расходы,1
      #|-------^
      #|Expecting 'COMMA', 'NEWLINE', 'EOF', got 'NON_ESCAPED_TEXT'
      #|Parse error on line 2:
      #|Доход,,1
      #|------^
      #|Expecting 'DQUOTE', 'NON_ESCAPED_TEXT', got 'COMMA'
    ),
  )
}

///|
test "control characters, lone surrogates and noncharacters end a name" {
  let shown = []
  for
    c in [
      "\u{0}",
      "\u{1}",
      "\t",
      "\u{1f}",
      "\u{7f}",
      "\u{80}",
      "\u{9f}",
      @util.slice("\u{10000}", 0, end=1),
      @util.slice("\u{10ffff}", 1),
      "\u{fffe}",
      "\u{ffff}",
    ] {
    // The message ends with what was expected, after a snippet of the source holding the character.
    for source in ["sankey\na\{c}b,c,1", "sankey\n\"a\{c}b\",c,1"] {
      let message = rows(source)
      shown.push(@util.slice(message, message.rev_find("\n").unwrap_or(-1) + 1))
    }
  }
  inspect(
    shown.join("\n"),
    content=(
      #|Expecting 'COMMA', 'NEWLINE', 'EOF', got 'NON_ESCAPED_TEXT'
      #|Expecting 'DQUOTE', got 'ESCAPED_TEXT'
      #|Expecting 'COMMA', 'NEWLINE', 'EOF', got 'NON_ESCAPED_TEXT'
      #|Expecting 'DQUOTE', got 'ESCAPED_TEXT'
      #|Expecting 'COMMA', 'NEWLINE', 'EOF', got 'NON_ESCAPED_TEXT'
      #|Expecting 'DQUOTE', got 'ESCAPED_TEXT'
      #|Expecting 'COMMA', 'NEWLINE', 'EOF', got 'NON_ESCAPED_TEXT'
      #|Expecting 'DQUOTE', got 'ESCAPED_TEXT'
      #|Expecting 'COMMA', 'NEWLINE', 'EOF', got 'NON_ESCAPED_TEXT'
      #|Expecting 'DQUOTE', got 'ESCAPED_TEXT'
      #|Expecting 'COMMA', 'NEWLINE', 'EOF', got 'NON_ESCAPED_TEXT'
      #|Expecting 'DQUOTE', got 'ESCAPED_TEXT'
      #|Expecting 'COMMA', 'NEWLINE', 'EOF', got 'NON_ESCAPED_TEXT'
      #|Expecting 'DQUOTE', got 'ESCAPED_TEXT'
      #|Expecting 'COMMA', 'NEWLINE', 'EOF', got 'NON_ESCAPED_TEXT'
      #|Expecting 'DQUOTE', got 'ESCAPED_TEXT'
      #|Expecting 'COMMA', 'NEWLINE', 'EOF', got 'NON_ESCAPED_TEXT'
      #|Expecting 'DQUOTE', got 'ESCAPED_TEXT'
      #|Expecting 'COMMA', 'NEWLINE', 'EOF', got 'NON_ESCAPED_TEXT'
      #|Expecting 'DQUOTE', got 'ESCAPED_TEXT'
      #|Expecting 'COMMA', 'NEWLINE', 'EOF', got 'NON_ESCAPED_TEXT'
      #|Expecting 'DQUOTE', got 'ESCAPED_TEXT'
    ),
  )
}

///|
test "entity codes for characters XML forbids are rejected in a name" {
  let shown = []
  for entity in ["&#65534;", "&#65535;", "&#1;", "&#xFFFE;"] {
    shown.push(rows("sankey\na\{entity},b,1"))
    shown.push(rows("sankey\nb,\"a\{entity}\",1"))
  }
  inspect(
    shown.join("\n"),
    content=(
      #|Parse error on line 2:
      #|a&#65534;,b,1
      #|^
      #|Invalid XML character in node name
      #|Parse error on line 2:
      #|b,"a&#65534;",1
      #|--^
      #|Invalid XML character in node name
      #|Parse error on line 2:
      #|a&#65535;,b,1
      #|^
      #|Invalid XML character in node name
      #|Parse error on line 2:
      #|b,"a&#65535;",1
      #|--^
      #|Invalid XML character in node name
      #|Parse error on line 2:
      #|a&#1;,b,1
      #|^
      #|Invalid XML character in node name
      #|Parse error on line 2:
      #|b,"a&#1;",1
      #|--^
      #|Invalid XML character in node name
      #|Parse error on line 2:
      #|a&#xFFFE;,b,1
      #|^
      #|Invalid XML character in node name
      #|Parse error on line 2:
      #|b,"a&#xFFFE;",1
      #|--^
      #|Invalid XML character in node name
    ),
  )
}
