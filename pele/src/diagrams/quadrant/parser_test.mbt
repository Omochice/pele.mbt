///|
fn read(source : String) -> String {
  let db = @quadrant.QuadrantDb::new(None)
  // The renderer hands the parser its text with one more line break.
  @quadrant.parse_quadrant(source + "\n", db) catch {
    @errors.PeleError(failure) =>
      return "\{failure.code.to_string()}: \{failure.message}"
  }
  dump(db)
}

///|
test "the chart type has to come first" {
  inspect(
    read("quadrant-1 do"),
    content="syntax: Parse error on line 1:\nquadrant-1 do\n^\nExpecting 'QUADRANT', got 'QUADRANT_1'",
  )
  inspect(
    read("x-axis a --> b"),
    content="syntax: Parse error on line 1:\nx-axis a --> b\n^\nExpecting 'QUADRANT', got 'X-AXIS'",
  )
  inspect(
    read("title t"),
    content="syntax: Parse error on line 1:\ntitle t\n^\nExpecting 'QUADRANT', got 'title'",
  )
  inspect(
    read(""),
    content="syntax: Parse error on line 2:\n\n^\nExpecting 'QUADRANT', got '$end'",
  )
  inspect(
    read("  \n\n"),
    content="syntax: Parse error on line 4:\n\n^\nExpecting 'QUADRANT', got '$end'",
  )
  inspect(
    read("quadrantChartx"),
    content="syntax: Parse error on line 1:\nquadrantChartx\n--------------^\nExpecting 'point_start', got 'NEWLINE'",
  )
  inspect(
    read("quadrantChart2"),
    content="syntax: Parse error on line 1:\nquadrantChart2\n--------------^\nExpecting 'point_start', got 'NEWLINE'",
  )
  inspect(
    read("chart"),
    content="syntax: Parse error on line 1:\nchart\n^\nExpecting 'QUADRANT', got 'ALPHA'",
  )
}

///|
test "a bare chart has nothing in it" {
  inspect(
    read("quadrantChart"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("QuadRantChart   "),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("\n\n  quadrantChart"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart;"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read(" ;\nquadrantChart"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantCHART\n\n\n"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
}

///|
test "the x axis takes one text or two around an arrow" {
  inspect(
    read("quadrantChart\nx-axis urgent --> not urgent"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=\"urgent\"|\"not urgent\" y=-|- points= classes=",
  )
  inspect(
    read(
      "quadrantChart\n       x-AxIs         Urgent     -->        Not Urgent    \n",
    ),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=\"Urgent\"|\"Not Urgent\" y=-|- points= classes=",
  )
  inspect(
    read(
      "quadrantChart\n       x-AxIs         \"Urgent(* +=[❤\"     -->        \"Not Urgent (* +=[❤\"\n    ",
    ),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=\"Urgent(* +=[❤\"|\"Not Urgent (* +=[❤\" y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\n       x-AxIs         \"Urgent(* +=[❤\""),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=\"Urgent(* +=[❤\"|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\n       x-AxIs         \"Urgent(* +=[❤\"  --> "),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=\"Urgent(* +=[❤ ⟶\"|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nx-axis a ---> b"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=\"a\"|\"b\" y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nx-axis a -> b"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nx-axis a -> b\n----------^",
  )
  inspect(
    read("quadrantChart\nx-axis a - b"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=\"a - b\"|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nx-axis"),
    content="syntax: Parse error on line 2:\nx-axis\n------^\nExpecting 'STR', 'MD_STR', 'ALPHA', 'NUM', 'UNICODE_TEXT', 'PUNCTUATION', got 'NEWLINE'",
  )
  inspect(
    read("quadrantChart\nx-axis -->"),
    content="syntax: Parse error on line 2:\nx-axis -->\n-------^\nExpecting 'STR', 'MD_STR', 'ALPHA', 'NUM', 'UNICODE_TEXT', 'PUNCTUATION', got 'AXIS-TEXT-DELIMITER'",
  )
}

///|
test "the y axis takes one text or two around an arrow" {
  inspect(
    read("quadrantChart\ny-axis urgent --> not urgent"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=\"urgent\"|\"not urgent\" points= classes=",
  )
  inspect(
    read(
      "quadrantChart\n       y-AxIs         Urgent     -->        Not Urgent    \n",
    ),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=\"Urgent\"|\"Not Urgent\" points= classes=",
  )
  inspect(
    read(
      "quadrantChart\n       Y-AxIs         \"Urgent(* +=[❤\"     -->        \"Not Urgent (* +=[❤\"\n    ",
    ),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=\"Urgent(* +=[❤\"|\"Not Urgent (* +=[❤\" points= classes=",
  )
  inspect(
    read("quadrantChart\n       y-AxIs         \"Urgent(* +=[❤\""),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=\"Urgent(* +=[❤\"|- points= classes=",
  )
  inspect(
    read("quadrantChart\n       y-AxIs         \"Urgent(* +=[❤\"  --> "),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=\"Urgent(* +=[❤ ⟶\"|- points= classes=",
  )
}

///|
test "each quadrant takes a text" {
  inspect(
    read("quadrantChart\nquadrant-1 Plan"),
    content="title=- accTitle=- accDescr=- quadrants=\"Plan\",-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("QuadRantChart   \n     QuaDrant-1 Plan    "),
    content="title=- accTitle=- accDescr=- quadrants=\"Plan\",-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("QuadRantChart   \n     QuaDrant-1 \"Plan(* +=[❤\""),
    content="title=- accTitle=- accDescr=- quadrants=\"Plan(* +=[❤\",-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nquadrant-2 do"),
    content="title=- accTitle=- accDescr=- quadrants=-,\"do\",-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("QuadRantChart   \n     QuaDrant-2 Do    "),
    content="title=- accTitle=- accDescr=- quadrants=-,\"Do\",-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nquadrant-3 delegate"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,\"delegate\",- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nquadrant-4 delete"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,\"delete\" x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nquadrant-5 nope"),
    content="syntax: Parse error on line 2:\nquadrant-5 nope\n---------------^\nExpecting 'point_start', got 'NEWLINE'",
  )
  inspect(
    read("quadrantChart\nquadrant-0 nope"),
    content="syntax: Parse error on line 2:\nquadrant-0 nope\n---------------^\nExpecting 'point_start', got 'NEWLINE'",
  )
  inspect(
    read("quadrantChart\nquadrant-1"),
    content="syntax: Parse error on line 2:\nquadrant-1\n----------^\nExpecting 'STR', 'MD_STR', 'ALPHA', 'NUM', 'UNICODE_TEXT', 'PUNCTUATION', got 'NEWLINE'",
  )
  inspect(
    read("quadrantChart\nquadrant-1 a\nquadrant-1 b"),
    content="title=- accTitle=- accDescr=- quadrants=\"b\",-,-,- x=-|- y=-|- points= classes=",
  )
}

///|
test "a quadrant text can be a markdown string" {
  inspect(
    read("quadrantChart\nquadrant-1 \"`**Bold** text`\""),
    content="title=- accTitle=- accDescr=- quadrants=\"**Bold** text\"(md),-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nquadrant-2 \"`unclosed"),
    content="syntax: Parse error on line 3:\n\n^\nExpecting 'NEWLINE', 'SEMI', 'EOF', got '$end'",
  )
  inspect(
    read("quadrantChart\nquadrant-2 \"`a\"b`\""),
    content="syntax: Lexical error on line 2. Unrecognized text.\nquadrant-2 \"`a\"b`\"\n--------------^",
  )
  inspect(
    read("quadrantChart\nquadrant-2 \"`a`b\""),
    content="syntax: Lexical error on line 2. Unrecognized text.\nquadrant-2 \"`a`b\"\n--------------^",
  )
  inspect(
    read("quadrantChart\nx-axis \"`left`\" --> \"`right`\""),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=\"left\"(md)|\"right\"(md) y=-|- points= classes=",
  )
}

///|
test "the title is the rest of the line" {
  inspect(
    read("quadrantChart\ntitle this is title"),
    content="title=\"this is title\" accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("QuadRantChart   \n     TiTle this Is title    "),
    content="title=\"this Is title\" accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("QuadRantChart   \n     title \"this is title (* +=[❤\""),
    content="title=\"\\\"this is title (* +=[❤\\\"\" accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\ntitle"),
    content="title=\"\" accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\ntitle   \n"),
    content="title=\"\" accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\ntitle a %% not a comment? \nquadrant-1 x"),
    content="title=\"a %% not a comment?\" accTitle=- accDescr=- quadrants=\"x\",-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\ntitle a;b"),
    content="title=\"a;b\" accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\ntitles x"),
    content="syntax: Parse error on line 2:\ntitles x\n--------^\nExpecting 'point_start', got 'NEWLINE'",
  )
  inspect(
    read("quadrantChart\ntitle\tx"),
    content="title=\"x\" accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
}

///|
test "accessibility statements are read" {
  inspect(
    read("quadrantChart\naccTitle: Priorities\naccDescr: Four boxes"),
    content="title=- accTitle=\"Priorities\" accDescr=\"Four boxes\" quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\n  accTitle:   spaced out  \n  accDescr:\tdescr  "),
    content="title=- accTitle=\"spaced out\" accDescr=\"descr\" quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\naccDescr {\n  multi\n    line\n}\nquadrant-1 q"),
    content="title=- accTitle=- accDescr=\"multi\\nline\" quadrants=\"q\",-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\naccDescr{one}"),
    content="title=- accTitle=- accDescr=\"one\" quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\naccDescr {\nunclosed\n"),
    content="syntax: Parse error on line 5:\n\n^\nExpecting 'NEWLINE', 'SEMI', 'EOF', got 'acc_descr_multiline_value'",
  )
  inspect(
    read("quadrantChart\naccTitle"),
    content="syntax: Parse error on line 2:\naccTitle\n--------^\nExpecting 'point_start', got 'NEWLINE'",
  )
  inspect(
    read("quadrantChart\naccTitle Priorities"),
    content="syntax: Parse error on line 2:\naccTitle Priorities\n-------------------^\nExpecting 'point_start', got 'NEWLINE'",
  )
  inspect(
    read("quadrantChart\nACCTITLE: caps"),
    content="title=- accTitle=\"caps\" accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\naccDescr"),
    content="syntax: Parse error on line 2:\naccDescr\n--------^\nExpecting 'point_start', got 'NEWLINE'",
  )
  inspect(
    read("quadrantChart\naccDescr {}"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\naccDescr { a } b"),
    content="syntax: Parse error on line 2:\naccDescr { a } b\n--------------^\nExpecting 'NEWLINE', 'SEMI', 'EOF', got 'SPACE'",
  )
}

///|
test "a point has a name, an optional class, coordinates and styles" {
  inspect(
    read("quadrantChart\npoint1: [0.1, 0.4]"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"point1\":\"\":0.1:0.4:{} classes=",
  )
  inspect(
    read("QuadRantChart   \n     Point1      : [0.1, 0.4]   "),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"Point1\":\"\":0.1:0.4:{} classes=",
  )
  inspect(
    read("QuadRantChart   \n     \"Point1 : (* +=[❤\": [1, 0]   "),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"Point1 : (* +=[❤\":\"\":1:0:{} classes=",
  )
  inspect(
    read("quadrantChart\nA:[0,1]"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nA:[0,1]\n------^",
  )
  inspect(
    read("quadrantChart\nA :  [  0.5  ,  0.5  ]"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"A\":\"\":0.5:0.5:{} classes=",
  )
  inspect(
    read("quadrantChart\nA:\n[0.5,0.5]"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"A\":\"\":0.5:0.5:{} classes=",
  )
  inspect(
    read("quadrantChart\nA\n:[0.5,0.5]"),
    content="syntax: Parse error on line 2:\nA\n-^\nExpecting 'point_start', got 'NEWLINE'",
  )
  inspect(
    read("quadrantChart\nTwo words here: [0.5, 0.5]"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"Two words here\":\"\":0.5:0.5:{} classes=",
  )
  inspect(
    read("quadrantChart\n\"`md`\": [0.5, 0.5]"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"md\":\"\":0.5:0.5:{} classes=",
  )
  inspect(
    read("quadrantChart\nA:::class1: [0.5, 0.5]"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"A\":\"class1\":0.5:0.5:{} classes=",
  )
  inspect(
    read("quadrantChart\nA:::a-b_c: [0.5, 0.5]"),
    content="syntax: Parse error on line 2:\nA:::a-b_c: [0.5, 0.5]\n-----^\nExpecting 'point_start', got 'MINUS'",
  )
  inspect(
    read("quadrantChart\nA::: : [0.5, 0.5]"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nA::: : [0.5, 0.5]\n----^",
  )
}

///|
test "a point can be placed with odd coordinates" {
  inspect(
    read("quadrantChart\nA: [1.2, 0.4]"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nA: [1.2, 0.4]\n-----^",
  )
  inspect(
    read("quadrantChart\nA: [0.2, 0.4"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nA: [0.2, 0.4\n------------^",
  )
  inspect(
    read("quadrantChart\nA: [0.2 0.4]"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nA: [0.2 0.4]\n-------^",
  )
  inspect(
    read("quadrantChart\nA: [0x5, 0.5]"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"A\":\"\":5:0.5:{} classes=",
  )
  inspect(
    read("quadrantChart\nA: [0,5, 0.5]"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"A\":\"\":NaN:0.5:{} classes=",
  )
  inspect(
    read("quadrantChart\nA: [0 5, 0.5]"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"A\":\"\":NaN:0.5:{} classes=",
  )
  inspect(
    read("quadrantChart\nA: [055, 0e9]"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"A\":\"\":55:0:{} classes=",
  )
  inspect(
    read("quadrantChart\nA: [0.5, 0.]"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nA: [0.5, 0.]\n----------^",
  )
  inspect(
    read("quadrantChart\nA: [.5, 0.5]"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nA: [.5, 0.5]\n----^",
  )
  inspect(
    read("quadrantChart\nA: [-1, 0.5]"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nA: [-1, 0.5]\n----^",
  )
  inspect(
    read("quadrantChart\nA: [00, 01]"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nA: [00, 01]\n-----^",
  )
  inspect(
    read("quadrantChart\nA: [0\n5, 0.5]"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nA: [0\n-----^",
  )
  inspect(
    read("quadrantChart\nA: [0.5,\n0.5]"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"A\":\"\":0.5:0.5:{} classes=",
  )
  inspect(
    read("quadrantChart\nA: [0.5, 0.5"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nA: [0.5, 0.5\n------------^",
  )
  inspect(
    read("quadrantChart\nA: [0.5, 0.5]]"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nA: [0.5, 0.5]]\n-------------^",
  )
  inspect(
    read("quadrantChart\nA: [0.5, 0.5] B"),
    content="semantic: style named B is not supported.",
  )
  inspect(
    read("quadrantChart\nA: ["),
    content="syntax: Parse error on line 3:\n\n^\nExpecting 'point_x', got '$end'",
  )
  inspect(
    read("quadrantChart\nA: []"),
    content="syntax: Parse error on line 2:\nA: []\n-----^\nExpecting 'point_x', got 'NEWLINE'",
  )
  inspect(
    read("quadrantChart\nA: [ ]"),
    content="syntax: Parse error on line 2:\nA: [ ]\n------^\nExpecting 'point_x', got 'NEWLINE'",
  )
}

///|
test "a point takes styles after its coordinates" {
  inspect(
    read("quadrantChart\nMicrosoft: [0.75, 0.75] radius: 10"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"Microsoft\":\"\":0.75:0.75:{radius=10} classes=",
  )
  inspect(
    read("quadrantChart\nSalesforce: [0.55, 0.60] radius: 10, color: #ff0000"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"Salesforce\":\"\":0.55:0.6:{radius=10 color=#ff0000} classes=",
  )
  inspect(
    read(
      "quadrantChart\nIBM: [0.51, 0.40] radius: 10, color: #ff0000, stroke-color: #ff00ff",
    ),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"IBM\":\"\":0.51:0.4:{radius=10 color=#ff0000 stroke-color=#ff00ff} classes=",
  )
  inspect(
    read(
      "quadrantChart\nIncorta: [0.20, 0.30] radius: 10 ,color: #ff0000 ,stroke-color: #ff00ff ,stroke-width: 10px",
    ),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"Incorta\":\"\":0.2:0.3:{radius=10 color=#ff0000 stroke-color=#ff00ff stroke-width=10px} classes=",
  )
  inspect(
    read(
      "quadrantChart\nMicrosoft: [0.75, 0.75] stroke-color: #ff00ff ,stroke-width: 10px, color: #ff0000, radius: 10",
    ),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"Microsoft\":\"\":0.75:0.75:{radius=10 color=#ff0000 stroke-color=#ff00ff stroke-width=10px} classes=",
  )
  inspect(
    read(
      "quadrantChart\nSalesforce:::class1: [0.55, 0.60] radius: 10, color: #ff0000",
    ),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"Salesforce\":\"class1\":0.55:0.6:{radius=10 color=#ff0000} classes=",
  )
  inspect(
    read("quadrantChart\nIncorta: [0.20, 0.30] stroke-width: 10px"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"Incorta\":\"\":0.2:0.3:{stroke-width=10px} classes=",
  )
  inspect(
    read("quadrantChart\nA: [0.5, 0.5] radius: 1,"),
    content="syntax: Parse error on line 2:\nA: [0.5, 0.5] radius: 1,\n------------------------^\nExpecting 'ALPHA', 'NUM', 'COLON', 'SPACE', 'BRKT', 'MINUS', got 'NEWLINE'",
  )
  inspect(
    read("quadrantChart\nA: [0.5, 0.5] radius: 1, , color: #fff"),
    content="semantic: style named  is not supported.",
  )
  inspect(
    read("quadrantChart\nA: [0.5, 0.5] radius:1;B: [0.1,0.1]"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"A\":\"\":0.5:0.5:{radius=1},\"B\":\"\":0.1:0.1:{} classes=",
  )
  inspect(
    read("quadrantChart\nA: [0.5, 0.5]   color: #ABC   \nB: [0.1, 0.1]"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"A\":\"\":0.5:0.5:{color=#ABC},\"B\":\"\":0.1:0.1:{} classes=",
  )
  inspect(
    read("quadrantChart\nA: [0.5, 0.5] radius: 5 radius: 6"),
    content="semantic: value for radius 5 radius is invalid, please use a valid number",
  )
  inspect(
    read("quadrantChart\nA: [0.5, 0.5] \"radius\": 5"),
    content="syntax: Parse error on line 2:\nA: [0.5, 0.5] \"radius\": 5\n---------------^\nExpecting 'NEWLINE', 'SEMI', 'EOF', got 'STR'",
  )
  inspect(
    read("quadrantChart\nA: [0.5, 0.5] radius: 5 6"),
    content="semantic: value for radius 5 6 is invalid, please use a valid number",
  )
}

///|
test "a class defines styles for points" {
  inspect(
    read("quadrantChart\nclassDef c1 color: #109060"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=c1={color=#109060}",
  )
  inspect(
    read(
      "quadrantChart\nclassDef c2 color: #908342, radius : 9, stroke-color: #310085, stroke-width: 10px",
    ),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=c2={radius=9 color=#908342 stroke-color=#310085 stroke-width=10px}",
  )
  inspect(
    read(
      "quadrantChart\nclassDef constructor radius: 3\nMicrosoft:::constructor: [0.75, 0.75]\n    ",
    ),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"Microsoft\":\"constructor\":0.75:0.75:{} classes=constructor={radius=3}",
  )
  inspect(
    read("quadrantChart\nclassDef a-b,c:d&e#f*g radius: 3"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=a-b,c:d&e#f*g={radius=3}",
  )
  inspect(
    read("quadrantChart\nclassDef c"),
    content="syntax: Parse error on line 2:\nclassDef c\n----------^\nExpecting 'SPACE', got 'NEWLINE'",
  )
  inspect(
    read("quadrantChart\nclassDef c "),
    content="syntax: Parse error on line 2:\nclassDef c \n-----------^\nExpecting 'ALPHA', 'NUM', 'COLON', 'SPACE', 'BRKT', 'MINUS', got 'NEWLINE'",
  )
  inspect(
    read("quadrantChart\nclassDef"),
    content="syntax: Parse error on line 2:\nclassDef\n--------^\nExpecting 'SPACE', got 'NEWLINE'",
  )
  inspect(
    read("quadrantChart\nclassDefc radius: 3"),
    content="syntax: Parse error on line 2:\nclassDefc radius: 3\n----------------^\nExpecting 'point_start', got 'COLON'",
  )
  inspect(
    read("quadrantChart\nclassDef  c   radius: 3"),
    content="syntax: Parse error on line 2:\nclassDef  c   radius: 3\n---------^\nExpecting 'ALPHA', 'NUM', 'UNICODE_TEXT', got 'SPACE'",
  )
  inspect(
    read("quadrantChart\nclassdef c radius: 3"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=c={radius=3}",
  )
  inspect(
    read("quadrantChart\nclassDef c fill: #fff"),
    content="semantic: style named fill is not supported.",
  )
  inspect(
    read("quadrantChart\nclassDef c radius: x"),
    content="semantic: value for radius x is invalid, please use a valid number",
  )
  inspect(
    read("quadrantChart\nclassDef c radius: 1\nclassDef c color: #fff"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=c={color=#fff}",
  )
  inspect(
    read("quadrantChart\nclassDef c radius: 1,\n"),
    content="syntax: Parse error on line 2:\nclassDef c radius: 1,\n---------------------^\nExpecting 'ALPHA', 'NUM', 'COLON', 'SPACE', 'BRKT', 'MINUS', got 'NEWLINE'",
  )
}

///|
test "statements are told apart by line breaks and semicolons" {
  inspect(
    read("quadrantChart;quadrant-1 a;quadrant-2 b;"),
    content="title=- accTitle=- accDescr=- quadrants=\"a\",\"b\",-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\r\nquadrant-1 a\r\nquadrant-2 b\r\n"),
    content="title=- accTitle=- accDescr=- quadrants=\"a\",\"b\",-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\n\n\nquadrant-1 a\n\n   \nquadrant-2 b"),
    content="title=- accTitle=- accDescr=- quadrants=\"a\",\"b\",-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart quadrant-1 a"),
    content="title=- accTitle=- accDescr=- quadrants=\"a\",-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nquadrant-1 a quadrant-2 b"),
    content="syntax: Parse error on line 2:\nquadrant-1 a quadrant-2 b\n------------^\nExpecting 'NEWLINE', 'SEMI', 'EOF', got 'QUADRANT_2'",
  )
  inspect(
    read("quadrantChart\nquadrant-1 a;;quadrant-2 b"),
    content="title=- accTitle=- accDescr=- quadrants=\"a\",\"b\",-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nquadrant-1 a ; quadrant-2 b"),
    content="title=- accTitle=- accDescr=- quadrants=\"a\",\"b\",-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\n   quadrant-1 a\n\tquadrant-2 b"),
    content="title=- accTitle=- accDescr=- quadrants=\"a\",\"b\",-,- x=-|- y=-|- points= classes=",
  )
}

///|
test "comments run to the end of the line" {
  inspect(
    read("quadrantChart\n%% a comment\nquadrant-1 a"),
    content="title=- accTitle=- accDescr=- quadrants=\"a\",-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nquadrant-1 a %% trailing\nquadrant-2 b"),
    content="title=- accTitle=- accDescr=- quadrants=\"a\",\"b\",-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart %% right after the type\nquadrant-1 a"),
    content="title=- accTitle=- accDescr=- quadrants=\"a\",-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nquadrant-1 a%%x\n"),
    content=(
      #|title=- accTitle=- accDescr=- quadrants="a",-,-,- x=-|- y=-|- points= classes=
    ),
  )
  inspect(
    read("quadrantChart\n%%\n%%%%\nquadrant-1 a"),
    content="title=- accTitle=- accDescr=- quadrants=\"a\",-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nx-axis a %% c\n"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=\"a\"|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nA: [0.5, 0.5] %% c\nB: [0.1, 0.1]"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"A\":\"\":0.5:0.5:{},\"B\":\"\":0.1:0.1:{} classes=",
  )
  inspect(
    read("quadrantChart\nA: [0.5, 0.5] radius: 4 %% c\nB: [0.1, 0.1]"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"A\":\"\":0.5:0.5:{radius=4},\"B\":\"\":0.1:0.1:{} classes=",
  )
  inspect(
    read("quadrantChart\nA: [0.5, %% c\n 0.5]"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nA: [0.5, %% c\n---------^",
  )
  inspect(
    read("quadrantChart\naccTitle: x %% c\n"),
    content="title=- accTitle=\"x %% c\" accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\naccDescr {\n a %% c\n}"),
    content="title=- accTitle=- accDescr=\"a %% c\" quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
}

///|
test "text takes letters, digits, accents, CJK and emoji" {
  inspect(
    read("quadrantChart\nquadrant-1 需要扩展"),
    content="title=- accTitle=- accDescr=- quadrants=\"需要扩展\",-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read(
      "quadrantChart\nquadrant-2 需要推广\nquadrant-3 重新评估\nquadrant-4 可以改进",
    ),
    content="title=- accTitle=- accDescr=- quadrants=-,\"需要推广\",\"重新评估\",\"可以改进\" x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nx-axis 低覆盖率 --> 高覆盖率"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=\"低覆盖率\"|\"高覆盖率\" y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\ny-axis 低参与度 --> 高参与度"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=\"低参与度\"|\"高参与度\" points= classes=",
  )
  inspect(
    read("quadrantChart\n产品A: [0.3, 0.6]"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"产品A\":\"\":0.3:0.6:{} classes=",
  )
  inspect(
    read("quadrantChart\ntitle 分析象限图"),
    content="title=\"分析象限图\" accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nquadrant-1 拡張が必要\nx-axis 低い --> 高い"),
    content="title=- accTitle=- accDescr=- quadrants=\"拡張が必要\",-,-,- x=\"低い\"|\"高い\" y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nx-axis 낮음 --> 높음"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=\"낮음\"|\"높음\" y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nquadrant-2 🚀Growth"),
    content="title=- accTitle=- accDescr=- quadrants=-,\"🚀Growth\",-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nx-axis Café --> Größe"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=\"Café\"|\"Größe\" y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nquadrant-1 catégoría\nquadrant-2 naïve"),
    content="title=- accTitle=- accDescr=- quadrants=\"catégoría\",\"naïve\",-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nquadrant-1 a_b.c,d+e=f*g#h&i!j$k%l'm`n?o\\p/q"),
    content="title=- accTitle=- accDescr=- quadrants=\"a_b.c,d+e=f*g#h&i!j$k%l'm`n?o\\\\p/q\",-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nquadrant-1 a - b -- c"),
    content="title=- accTitle=- accDescr=- quadrants=\"a - b -- c\",-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nquadrant-1 a(b)"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nquadrant-1 a(b)\n------------^",
  )
  inspect(
    read("quadrantChart\nquadrant-1 a<b>"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nquadrant-1 a<b>\n------------^",
  )
  inspect(
    read("quadrantChart\nquadrant-1 a{b}"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nquadrant-1 a{b}\n------------^",
  )
  inspect(
    read("quadrantChart\nquadrant-1 a@b"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nquadrant-1 a@b\n------------^",
  )
  inspect(
    read("quadrantChart\nquadrant-1 a^b|c~d"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nquadrant-1 a^b|c~d\n------------^",
  )
  inspect(
    read("quadrantChart\nquadrant-1 [a]"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nquadrant-1 [a]\n-----------^",
  )
  inspect(
    read("quadrantChart\nquadrant-1 a:b"),
    content="syntax: Parse error on line 2:\nquadrant-1 a:b\n------------^\nExpecting 'NEWLINE', 'SEMI', 'EOF', got 'COLON'",
  )
  inspect(
    read("quadrantChart\nquadrant-1 a;b"),
    content="syntax: Parse error on line 2:\nquadrant-1 a;b\n--------------^\nExpecting 'point_start', got 'NEWLINE'",
  )
}

///|
test "a string can hold anything up to its closing quote" {
  inspect(
    read("quadrantChart\nquadrant-1 \"a: [0.5, 0.5]\""),
    content="title=- accTitle=- accDescr=- quadrants=\"a: [0.5, 0.5]\",-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nquadrant-1 \"a\nb\""),
    content="title=- accTitle=- accDescr=- quadrants=\"a\\nb\",-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nquadrant-1 \"unclosed"),
    content="syntax: Parse error on line 3:\n\n^\nExpecting 'NEWLINE', 'SEMI', 'EOF', got 'STR'",
  )
  inspect(
    read("quadrantChart\nquadrant-1 \"\""),
    content="syntax: Parse error on line 2:\nquadrant-1 \"\"\n-------------^\nExpecting 'STR', 'MD_STR', 'ALPHA', 'NUM', 'UNICODE_TEXT', 'PUNCTUATION', got 'NEWLINE'",
  )
  inspect(
    read("quadrantChart\nquadrant-1 \"a\" b"),
    content="title=- accTitle=- accDescr=- quadrants=\"a b\",-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nquadrant-1 a \"b\""),
    content="syntax: Parse error on line 2:\nquadrant-1 a \"b\"\n--------------^\nExpecting 'NEWLINE', 'SEMI', 'EOF', got 'STR'",
  )
  inspect(
    read("quadrantChart\nquadrant-1 \"a\"\"b\""),
    content="syntax: Parse error on line 2:\nquadrant-1 \"a\"\"b\"\n---------------^\nExpecting 'NEWLINE', 'SEMI', 'EOF', got 'STR'",
  )
  inspect(
    read("quadrantChart\nquadrant-1 \"%% not a comment\""),
    content=(
      #|title=- accTitle=- accDescr=- quadrants="%% not a comment",-,-,- x=-|- y=-|- points= classes=
    ),
  )
}

///|
test "text the grammar does not accept is reported where it is" {
  inspect(
    read("quadrantChart\n@"),
    content="syntax: Lexical error on line 2. Unrecognized text.\n@\n^",
  )
  inspect(
    read("quadrantChart\nquadrant-1 ok\n  ^ bad"),
    content="syntax: Lexical error on line 3. Unrecognized text.\n  ^ bad\n--^",
  )
  inspect(
    read("quadrantChart\n:"),
    content="syntax: Parse error on line 2:\n:\n^\nExpecting 'NEWLINE', 'SEMI', 'EOF', got 'COLON'",
  )
  inspect(
    read("quadrantChart\n]"),
    content="syntax: Lexical error on line 2. Unrecognized text.\n]\n^",
  )
  inspect(
    read("quadrantChart\n-->"),
    content="syntax: Parse error on line 2:\n-->\n^\nExpecting 'NEWLINE', 'SEMI', 'EOF', got 'AXIS-TEXT-DELIMITER'",
  )
  inspect(
    read("quadrantChart\n- a"),
    content="syntax: Parse error on line 2:\n- a\n^\nExpecting 'NEWLINE', 'SEMI', 'EOF', got 'MINUS'",
  )
  inspect(
    read("quadrantChart\nx-axis a --> b --> c"),
    content="syntax: Parse error on line 2:\nx-axis a --> b --> c\n--------------^\nExpecting 'NEWLINE', 'SEMI', 'EOF', got 'AXIS-TEXT-DELIMITER'",
  )
  inspect(
    read("quadrantChart\nquadrantChart"),
    content="syntax: Parse error on line 2:\nquadrantChart\n^\nExpecting 'NEWLINE', 'SEMI', 'EOF', got 'QUADRANT'",
  )
  inspect(
    read("quadrantChart\nquadrantChart\nquadrant-1 a"),
    content="syntax: Parse error on line 2:\nquadrantChart\n^\nExpecting 'NEWLINE', 'SEMI', 'EOF', got 'QUADRANT'",
  )
  inspect(
    read("quadrantChart\n\u{1}"),
    content="syntax: Lexical error on line 2. Unrecognized text.\n\u{1}\n^",
  )
  inspect(
    read("quadrantChart\nA: [0.5, 0.5]\n\u{7}"),
    content="syntax: Lexical error on line 3. Unrecognized text.\n\u{7}\n^",
  )
  inspect(
    read("quadrantChart\n:::x"),
    content="syntax: Parse error on line 2:\n:::x\n---^\nExpecting 'NEWLINE', 'SEMI', 'EOF', got 'class_name'",
  )
  inspect(
    read("quadrantChart\nA:::"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nA:::\n----^",
  )
  inspect(
    read("quadrantChart\nA:::1x: [0.5, 0.5]"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"A\":\"1x\":0.5:0.5:{} classes=",
  )
  inspect(
    read("quadrantChart\nA:::x [0.5, 0.5]"),
    content="syntax: Parse error on line 2:\nA:::x [0.5, 0.5]\n-----^\nExpecting 'point_start', got 'SPACE'",
  )
}

///|
test "the whole chart is read" {
  inspect(
    read(
      "quadrantChart\n      title Analytics and Business Intelligence Platforms\n      x-axis \"Completeness of Vision ❤\" --> \"x-axis-2\"\n      y-axis Ability to Execute --> \"y-axis-2\"\n      quadrant-1 Leaders\n      quadrant-2 Challengers\n      quadrant-3 Niche\n      quadrant-4 Visionaries\n      Microsoft: [0.75, 0.75]\n      Salesforce: [0.55, 0.60]\n      IBM: [0.51, 0.40]\n      Incorta: [0.20, 0.30]",
    ),
    content="title=\"Analytics and Business Intelligence Platforms\" accTitle=- accDescr=- quadrants=\"Leaders\",\"Challengers\",\"Niche\",\"Visionaries\" x=\"Completeness of Vision ❤\"|\"x-axis-2\" y=\"Ability to Execute\"|\"y-axis-2\" points=\"Microsoft\":\"\":0.75:0.75:{},\"Salesforce\":\"\":0.55:0.6:{},\"IBM\":\"\":0.51:0.4:{},\"Incorta\":\"\":0.2:0.3:{} classes=",
  )
  inspect(
    read(
      "quadrantChart\n      title Analytics and Business Intelligence Platforms\n      x-axis \"Completeness of Vision ❤\" --> \"x-axis-2\"\n      y-axis Ability to Execute --> \"y-axis-2\"\n      quadrant-1 Leaders\n      Microsoft: [0.75, 0.75] radius: 10\n      Salesforce: [0.55, 0.60] radius: 10, color: #ff0000\n      IBM: [0.51, 0.40] radius: 10, color: #ff0000, stroke-color: #ff00ff\n      Incorta: [0.20, 0.30] radius: 10 ,color: #ff0000 ,stroke-color: #ff00ff ,stroke-width: 10px",
    ),
    content="title=\"Analytics and Business Intelligence Platforms\" accTitle=- accDescr=- quadrants=\"Leaders\",-,-,- x=\"Completeness of Vision ❤\"|\"x-axis-2\" y=\"Ability to Execute\"|\"y-axis-2\" points=\"Microsoft\":\"\":0.75:0.75:{radius=10},\"Salesforce\":\"\":0.55:0.6:{radius=10 color=#ff0000},\"IBM\":\"\":0.51:0.4:{radius=10 color=#ff0000 stroke-color=#ff00ff},\"Incorta\":\"\":0.2:0.3:{radius=10 color=#ff0000 stroke-color=#ff00ff stroke-width=10px} classes=",
  )
  inspect(
    read(
      "quadrantChart\n        A: [0.1, 0.1] radius: 12\n        B:::c1: [0.2, 0.2] color: #ff3300, radius: 10\n        C:::c2: [0.3, 0.3]\n        D: [0.4, 0.4] color: 00f, stroke-width: 3px\n        E: [0.5, 0.5] stroke-color: #00ff00\n        classDef c1 color: #109060\n        classDef c2 color: #908342, radius : 9, stroke-color: #310085, stroke-width: 10px",
    ),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"A\":\"\":0.1:0.1:{radius=12},\"B\":\"c1\":0.2:0.2:{radius=10 color=#ff3300},\"C\":\"c2\":0.3:0.3:{},\"D\":\"\":0.4:0.4:{color=00f stroke-width=3px},\"E\":\"\":0.5:0.5:{stroke-color=#00ff00} classes=c1={color=#109060},c2={radius=9 color=#908342 stroke-color=#310085 stroke-width=10px}",
  )
}

///|
test "an error in a style is raised when its statement is read" {
  inspect(
    read("quadrantChart\nA: [0.1, 0.1] radius: big"),
    content="semantic: value for radius big is invalid, please use a valid number",
  )
  inspect(
    read("quadrantChart\nA: [0.1, 0.1] color: red"),
    content="semantic: value for color red is invalid, please use a valid hex code",
  )
  inspect(
    read("quadrantChart\nA: [0.1, 0.1] radius: big\n@"),
    content="semantic: value for radius big is invalid, please use a valid number",
  )
  inspect(
    read("quadrantChart\n@\nA: [0.1, 0.1] radius: big"),
    content="syntax: Lexical error on line 2. Unrecognized text.\n@\n^",
  )
  inspect(
    read("quadrantChart\nclassDef c fill: #fff"),
    content="semantic: style named fill is not supported.",
  )
  inspect(
    read("quadrantChart\nA: [0.1, 0.1] radius"),
    content="semantic: value for radius undefined is invalid, please use a valid number",
  )
  inspect(
    read("quadrantChart\nA: [0.1, 0.1] 5"),
    content="semantic: style named 5 is not supported.",
  )
}

///|
test "repeated statements replace earlier ones" {
  inspect(
    read("quadrantChart\ntitle a\ntitle b"),
    content="title=\"b\" accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nx-axis a --> b\nx-axis c"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=\"c\"|\"b\" y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\nx-axis a --> b\nx-axis c -->"),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=\"c ⟶\"|\"b\" y=-|- points= classes=",
  )
  inspect(
    read("quadrantChart\naccTitle: a\naccTitle: b"),
    content="title=- accTitle=\"b\" accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
}

///|
test "the character before a comment is kept" {
  inspect(
    read("quadrantChart\nquadrant-1 A%% note"),
    content=(
      #|title=- accTitle=- accDescr=- quadrants="A",-,-,- x=-|- y=-|- points= classes=
    ),
  )
  assert_true(
    read("quadrantChart\nquadrant-1 A:%% note").has_prefix("syntax: "),
  )
}
