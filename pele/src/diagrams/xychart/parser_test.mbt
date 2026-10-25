///|
fn parsed(source : String) -> String {
  let db = @xychart.XyChartDb::new()
  @xychart.parse_xychart(source, db) catch {
    @errors.PeleError(failure) => return "error: \{failure.message}"
  }
  dump(db)
}

///|
test "the chart keyword is required and may stand alone" {
  inspect(
    parsed("xychart-1"),
    content=(
      #|error: Parse error on line 1:
      #|xychart-1
      #|-------^
      #|Expecting 'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'MINUS'
    ),
  )
  inspect(
    parsed("xychart"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("" []) set=false
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart-beta"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("" []) set=false
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed(""),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("" []) set=false
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("line [1]"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("" 1..1) set=true
      #|y="" 1..1 set=false
      #|line "" ["1"=1] labels=-
    ),
  )
  inspect(
    parsed("xychart xychart horizontal"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=horizontal
      #|x=band("" []) set=false
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("\n\n xychart\n\n xychart vertical\nline [1]"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=vertical
      #|x=linear("" 1..1) set=true
      #|y="" 1..1 set=false
      #|line "" ["1"=1] labels=-
    ),
  )
  inspect(
    parsed("xychart;;\n;line [1]"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("" 1..1) set=true
      #|y="" 1..1 set=false
      #|line "" ["1"=1] labels=-
    ),
  )
}

///|
test "the title of the chart" {
  inspect(
    parsed("xychart \n title \"This is a title\""),
    content=(
      #|title="This is a title" accTitle=- accDescr=-
      #|orientation=-
      #|x=band("" []) set=false
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart \n title oneLinertitle"),
    content=(
      #|title="oneLinertitle" accTitle=- accDescr=-
      #|orientation=-
      #|x=band("" []) set=false
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart\ntitle My title with spaces & symbols_1.0-2"),
    content=(
      #|title="withspaces&symbols_1.0-2" accTitle=- accDescr=-
      #|orientation=-
      #|x=band("" []) set=false
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart\ntitle\nline [1]"),
    content=(
      #|error: Parse error on line 2:
      #|title
      #|-----^
      #|Expecting 'STR', 'ALPHA', 'NUM', got 'NEWLINE'
    ),
  )
  inspect(
    parsed("xychart\ntitle \"  padded  \"\nline [1]"),
    content=(
      #|title="padded" accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("" 1..1) set=true
      #|y="" 1..1 set=false
      #|line "" ["1"=1] labels=-
    ),
  )
  inspect(
    parsed("xychart\ntitle a\ntitle b\nline [1]"),
    content=(
      #|title="b" accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("" 1..1) set=true
      #|y="" 1..1 set=false
      #|line "" ["1"=1] labels=-
    ),
  )
  inspect(
    parsed("xychart\ntitle \"\"\nline [1]"),
    content=(
      #|error: Parse error on line 2:
      #|title ""
      #|--------^
      #|Expecting 'STR', 'ALPHA', 'NUM', got 'NEWLINE'
    ),
  )
}

///|
test "the orientation of the chart" {
  inspect(
    parsed("xychart vertical"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=vertical
      #|x=band("" []) set=false
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart        horizontal        "),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=horizontal
      #|x=band("" []) set=false
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart abc"),
    content=(
      #|error: Parse error on line 1:
      #|xychart abc
      #|--------^
      #|Expecting 'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'ALPHA'
    ),
  )
  inspect(
    parsed("xychart HORIZONTAL\nline [1]"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=vertical
      #|x=linear("" 1..1) set=true
      #|y="" 1..1 set=false
      #|line "" ["1"=1] labels=-
    ),
  )
  inspect(
    parsed("xychart horizontalx"),
    content=(
      #|error: Parse error on line 1:
      #|xychart horizontalx
      #|------------------^
      #|Expecting 'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'ALPHA'
    ),
  )
  inspect(
    parsed("xychart\nhorizontal"),
    content=(
      #|error: Parse error on line 2:
      #|horizontal
      #|^
      #|Expecting 'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'CHART_ORIENTATION'
    ),
  )
}

///|
test "a title for the x axis" {
  inspect(
    parsed("xychart \nx-axis xAxisName\n"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("xAxisName" []) set=false
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart \nx-axis        xAxisName     \n"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("xAxisName" []) set=false
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart \n    x-axis \"xAxisName has space\"\n"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("xAxisName has space" []) set=false
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart \n   x-axis    \"  xAxisName has space   \"         \n"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("xAxisName has space" []) set=false
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart\nx-axis two words here\n"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("twowordshere" []) set=false
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart\nx-axis\nline [1]"),
    content=(
      #|error: Parse error on line 2:
      #|x-axis
      #|------^
      #|Expecting 'NUMBER_WITH_DECIMAL', got 'NEWLINE'
    ),
  )
}

///|
test "a range for the x axis" {
  inspect(
    parsed("xychart \nx-axis xAxisName    45.5   -->   33   \n"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("xAxisName" 45.5..33) set=true
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart \nx-axis xAxisName    aaa   -->   33   \n"),
    content=(
      #|error: Parse error on line 2:
      #|x-axis xAxisName    aaa   -->   33   
      #|--------------------------^
      #|Expecting 'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'ARROW_DELIMITER'
    ),
  )
  inspect(
    parsed("xychart \nx-axis xAxisName    45.5   -->   .34   \n"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("xAxisName" 45.5..0.34) set=true
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart \nx-axis   45.5   -->   1.34   \n"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("" 45.5..1.34) set=true
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart\nx-axis 1 -->\nline [1]"),
    content=(
      #|error: Parse error on line 2:
      #|x-axis 1 -->
      #|------------^
      #|Expecting 'NUMBER_WITH_DECIMAL', got 'NEWLINE'
    ),
  )
  inspect(
    parsed("xychart\nx-axis 1 --> 2 --> 3"),
    content=(
      #|error: Parse error on line 2:
      #|x-axis 1 --> 2 --> 3
      #|---------------^
      #|Expecting 'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'ARROW_DELIMITER'
    ),
  )
  inspect(
    parsed("xychart\nx-axis -5 --> +7"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("" -5..7) set=true
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart\nx-axis 5\nline [1]"),
    content=(
      #|error: Parse error on line 2:
      #|x-axis 5
      #|--------^
      #|Expecting 'ARROW_DELIMITER', got 'NEWLINE'
    ),
  )
  inspect(
    parsed("xychart\nx-axis a 5\nline [1]"),
    content=(
      #|error: Parse error on line 2:
      #|x-axis a 5
      #|----------^
      #|Expecting 'ARROW_DELIMITER', got 'NEWLINE'
    ),
  )
}

///|
test "categories for the x axis" {
  inspect(
    parsed("xychart \nx-axis xAxisName    [  \"cat1\"  ,   cat2a  ]   \n   "),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("xAxisName" ["cat1","cat2a"]) set=true
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart \nx-axis    [  \"cat1\"  ,   cat2a  ]   \n   "),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("" ["cat1","cat2a"]) set=true
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed(
      "xychart \nx-axis \"this is x axis\" [category1, \"category 2\", category3]\n",
    ),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("this is x axis" ["category1","category 2","category3"]) set=true
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed(
      "xychart \nx-axis xAxisName    [  \"cat1  with space\"  ,   cat2 , cat3]   \n   ",
    ),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("xAxisName" ["cat1  with space","cat2","cat3"]) set=true
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed(
      "xychart \nx-axis xAxisName    [  \"cat1  with space\"  ,   cat2 asdf , cat3]   \n   ",
    ),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("xAxisName" ["cat1  with space","cat2asdf","cat3"]) set=true
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed(
      "xychart\nx-axis [1, 2.5, 3-4, a_b, c.d, e&f, g+h, i=j, k*l, m#n]\nline [1]",
    ),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("" ["1","2.5","3-4","a_b","c.d","e&f","g+h","i=j","k*l","m#n"]) set=true
      #|y="" 1..1 set=false
      #|line "" ["1"=1,"2.5"=-,"3-4"=-,"a_b"=-,"c.d"=-,"e&f"=-,"g+h"=-,"i=j"=-,"k*l"=-,"m#n"=-] labels=-
    ),
  )
  inspect(
    parsed("xychart\nx-axis []\nline [1]"),
    content=(
      #|error: Parse error on line 2:
      #|x-axis []
      #|--------^
      #|Expecting 'STR', 'ALPHA', 'NUM', got 'SQUARE_BRACES_END'
    ),
  )
  inspect(
    parsed("xychart\nx-axis [a,]\nline [1]"),
    content=(
      #|error: Parse error on line 2:
      #|x-axis [a,]
      #|----------^
      #|Expecting 'STR', 'ALPHA', 'NUM', got 'SQUARE_BRACES_END'
    ),
  )
  inspect(
    parsed("xychart\nx-axis [,a]\nline [1]"),
    content=(
      #|error: Parse error on line 2:
      #|x-axis [,a]
      #|--------^
      #|Expecting 'STR', 'ALPHA', 'NUM', got 'COMMA'
    ),
  )
  inspect(
    parsed("xychart\nx-axis [a b\nc]\nline [1]"),
    content=(
      #|error: Parse error on line 2:
      #|x-axis [a b
      #|-----------^
      #|Expecting 'SQUARE_BRACES_END', got 'NEWLINE'
    ),
  )
  inspect(
    parsed("xychart\nx-axis [\"\", b]\nline [1, 2]"),
    content=(
      #|error: Parse error on line 2:
      #|x-axis ["", b]
      #|----------^
      #|Expecting 'STR', 'ALPHA', 'NUM', got 'COMMA'
    ),
  )
}

///|
test "unbalanced brackets in an axis" {
  inspect(
    parsed("xychart \nx-axis xAxisName    [  \"cat1\"  [   cat2a  ]   \n   "),
    content=(
      #|error: Parse error on line 2:
      #|x-axis xAxisName    [  "cat1"  [   cat2a  ]   
      #|-------------------------------^
      #|Expecting 'SQUARE_BRACES_END', got 'SQUARE_BRACES_START'
    ),
  )
  inspect(
    parsed("xychart \nx-axis xAxisName    [  \"cat1\"  ,   cat2a ] ]   \n   "),
    content=(
      #|error: Parse error on line 2:
      #|x-axis xAxisName    [  "cat1"  ,   cat2a ] ]   
      #|-------------------------------------------^
      #|Expecting 'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'SQUARE_BRACES_END'
    ),
  )
  inspect(
    parsed("xychart\nx-axis [a, b"),
    content=(
      #|error: Parse error on line 2:
      #|x-axis [a, b
      #|------------^
      #|Expecting 'SQUARE_BRACES_END', got 'EOF'
    ),
  )
}

///|
test "a title and a range for the y axis" {
  inspect(
    parsed("xychart \ny-axis yAxisName\n"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("" []) set=false
      #|y="yAxisName" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart \ny-axis        yAxisName     \n"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("" []) set=false
      #|y="yAxisName" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart \n    y-axis \"yAxisName has space\"\n"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("" []) set=false
      #|y="yAxisName has space" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart \n   y-axis    \"  yAxisName has space   \"         \n"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("" []) set=false
      #|y="yAxisName has space" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart \ny-axis yAxisName    45.5   -->   33   \n"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("" []) set=false
      #|y="yAxisName" 45.5..33 set=true
    ),
  )
  inspect(
    parsed("xychart \ny-axis    45.5   -->   33   \n"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("" []) set=false
      #|y="" 45.5..33 set=true
    ),
  )
  inspect(
    parsed("xychart \ny-axis yAxisName    45.5   -->   .33   \n"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("" []) set=false
      #|y="yAxisName" 45.5..0.33 set=true
    ),
  )
  inspect(
    parsed("xychart \ny-axis yAxisName    45.5   -->   abc   \n"),
    content=(
      #|error: Parse error on line 2:
      #|y-axis yAxisName    45.5   -->   abc   
      #|---------------------------------^
      #|Expecting 'NUMBER_WITH_DECIMAL', got 'ALPHA'
    ),
  )
  inspect(
    parsed("xychart \ny-axis yAxisName    [ 45.3,   33 ]   \n"),
    content=(
      #|error: Parse error on line 2:
      #|y-axis yAxisName    [ 45.3,   33 ]   
      #|--------------------^
      #|Expecting 'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'SQUARE_BRACES_START'
    ),
  )
  inspect(
    parsed("xychart\nx-axis xAxisName\ny-axis yAxisName\n"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("xAxisName" []) set=false
      #|y="yAxisName" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart\ny-axis 10 --> 150\nline [1, 2]"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("" 1..2) set=true
      #|y="" 10..150 set=true
      #|line "" ["1"=1,"2"=2] labels=-
    ),
  )
}

///|
test "a line series" {
  inspect(
    parsed(
      "xychart\nx-axis xAxisName\ny-axis yAxisName\n line lineTitle [23, 45, 56.6]",
    ),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("xAxisName" 1..3) set=true
      #|y="yAxisName" 23..56.6 set=false
      #|line "lineTitle" ["1"=23,"2"=45,"3"=56.6] labels=-
    ),
  )
  inspect(
    parsed(
      "xychart\nx-axis xAxisName\ny-axis yAxisName\n line \"lineTitle with space\"   [  +23 , -45  , 56.6 ]   ",
    ),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("xAxisName" 1..3) set=true
      #|y="yAxisName" -45..56.6 set=false
      #|line "lineTitle with space" ["1"=23,"2"=-45,"3"=56.6] labels=-
    ),
  )
  inspect(
    parsed(
      "xychart\nx-axis xAxisName\ny-axis yAxisName\n line [  +23 , -45  , 56.6 , .33]   ",
    ),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("xAxisName" 1..4) set=true
      #|y="yAxisName" -45..56.6 set=false
      #|line "" ["1"=23,"2"=-45,"3"=56.6,"4"=0.33] labels=-
    ),
  )
  inspect(
    parsed("xychart\nline [1.5e3]"),
    content=(
      #|error: Parse error on line 2:
      #|line [1.5e3]
      #|---------^
      #|Expecting 'SQUARE_BRACES_END', got 'ALPHA'
    ),
  )
  inspect(
    parsed("xychart\nline [1, 012, 1.50, +.5, -.5, 007.25]"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("" 1..6) set=true
      #|y="" -0.5..12 set=false
      #|line "" ["1"=1,"2"=12,"3"=1.5,"4"=0.5,"5"=-0.5,"6"=7.25] labels=-
    ),
  )
  inspect(
    parsed("xychart\nline [1.]"),
    content=(
      #|error: Parse error on line 2:
      #|line [1.]
      #|-------^
      #|Expecting 'SQUARE_BRACES_END', got 'DOT'
    ),
  )
  inspect(
    parsed("xychart\nline [1 2]"),
    content=(
      #|error: Parse error on line 2:
      #|line [1 2]
      #|--------^
      #|Expecting 'SQUARE_BRACES_END', got 'NUMBER_WITH_DECIMAL'
    ),
  )
}

///|
test "a bar series" {
  inspect(
    parsed(
      "xychart\nx-axis xAxisName\ny-axis yAxisName\n bar barTitle [23, 45, 56.6, .22]",
    ),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("xAxisName" 1..4) set=true
      #|y="yAxisName" 0.22..56.6 set=false
      #|bar "barTitle" ["1"=23,"2"=45,"3"=56.6,"4"=0.22] labels=-
    ),
  )
  inspect(
    parsed(
      "xychart\nx-axis xAxisName\ny-axis yAxisName\n bar \"barTitle with space\"   [  +23 , -45  , 56.6 ]   ",
    ),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("xAxisName" 1..3) set=true
      #|y="yAxisName" -45..56.6 set=false
      #|bar "barTitle with space" ["1"=23,"2"=-45,"3"=56.6] labels=-
    ),
  )
  inspect(
    parsed(
      "xychart\nx-axis xAxisName\ny-axis yAxisName\n bar   [  +23 , -45  , 56.6 ]   ",
    ),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("xAxisName" 1..3) set=true
      #|y="yAxisName" -45..56.6 set=false
      #|bar "" ["1"=23,"2"=-45,"3"=56.6] labels=-
    ),
  )
  inspect(
    parsed("xychart\nbar a b c [1]"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("" 1..1) set=true
      #|y="" 1..1 set=false
      #|bar "abc" ["1"=1] labels=-
    ),
  )
  inspect(
    parsed("xychart\nbar \"a\" \"b\" [1]"),
    content=(
      #|error: Parse error on line 2:
      #|bar "a" "b" [1]
      #|---------^
      #|Expecting 'SQUARE_BRACES_START', got 'STR'
    ),
  )
}

///|
test "a series that is not well formed" {
  inspect(
    parsed(
      "xychart\nx-axis xAxisName\ny-axis yAxisName\n line \"lineTitle with space\"   [  +23 [ -45  , 56.6 ]   ",
    ),
    content=(
      #|error: Parse error on line 4:
      #| line "lineTitle with space"   [  +23 [ -45  , 56.6 ]   
      #|--------------------------------------^
      #|Expecting 'SQUARE_BRACES_END', got 'SQUARE_BRACES_START'
    ),
  )
  inspect(
    parsed(
      "xychart\nx-axis xAxisName\ny-axis yAxisName\n line \"lineTitle with space\"   [  +23 , -45  ] 56.6 ]   ",
    ),
    content=(
      #|error: Parse error on line 4:
      #| line "lineTitle with space"   [  +23 , -45  ] 56.6 ]   
      #|-----------------------------------------------^
      #|Expecting 'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'NUM'
    ),
  )
  inspect(
    parsed(
      "xychart\nx-axis xAxisName\ny-axis yAxisName\n line \"lineTitle with space\"   ",
    ),
    content=(
      #|error: Parse error on line 4:
      #| line "lineTitle with space"   
      #|-------------------------------^
      #|Expecting 'SQUARE_BRACES_START', got 'EOF'
    ),
  )
  inspect(
    parsed(
      "xychart\nx-axis xAxisName\ny-axis yAxisName\n line \"lineTitle with space\"  [ ] ",
    ),
    content=(
      #|error: Parse error on line 4:
      #| line "lineTitle with space"  [ ] 
      #|--------------------------------^
      #|Expecting 'NUMBER_WITH_DECIMAL', got 'SQUARE_BRACES_END'
    ),
  )
  inspect(
    parsed(
      "xychart\nx-axis xAxisName\ny-axis yAxisName\n line \"lineTitle with space\"   [  +23 ,  , -45  , 56.6 ]   ",
    ),
    content=(
      #|error: Parse error on line 4:
      #| line "lineTitle with space"   [  +23 ,  , -45  , 56.6 ]   
      #|-----------------------------------------^
      #|Expecting 'NUMBER_WITH_DECIMAL', got 'COMMA'
    ),
  )
  inspect(
    parsed(
      "xychart\nx-axis xAxisName\ny-axis yAxisName\n line \"lineTitle with space\"   [  +23 , -4aa5  , 56.6 ]   ",
    ),
    content=(
      #|error: Parse error on line 4:
      #| line "lineTitle with space"   [  +23 , -4aa5  , 56.6 ]   
      #|------------------------------------------^
      #|Expecting 'SQUARE_BRACES_END', got 'ALPHA'
    ),
  )
  inspect(
    parsed("xychart\nbar [1,"),
    content=(
      #|error: Parse error on line 2:
      #|bar [1,
      #|-------^
      #|Expecting 'NUMBER_WITH_DECIMAL', got 'EOF'
    ),
  )
  inspect(
    parsed("xychart\nbar [1, 2"),
    content=(
      #|error: Parse error on line 2:
      #|bar [1, 2
      #|---------^
      #|Expecting 'SQUARE_BRACES_END', got 'EOF'
    ),
  )
  inspect(
    parsed("xychart\nbar [1, 2]]"),
    content=(
      #|error: Parse error on line 2:
      #|bar [1, 2]]
      #|----------^
      #|Expecting 'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'SQUARE_BRACES_END'
    ),
  )
  inspect(
    parsed("xychart\nbar\n[1]"),
    content=(
      #|error: Parse error on line 2:
      #|bar
      #|---^
      #|Expecting 'STR', 'ALPHA', 'NUM', got 'NEWLINE'
    ),
  )
  inspect(
    parsed("xychart\nline [1] [2]"),
    content=(
      #|error: Parse error on line 2:
      #|line [1] [2]
      #|---------^
      #|Expecting 'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'SQUARE_BRACES_START'
    ),
  )
}

///|
test "several series" {
  inspect(
    parsed(
      "xychart\nx-axis xAxisName\ny-axis yAxisName\n bar barTitle1 [23, 45, 56.6] \n line lineTitle1 [11, 45.5, 67, 23] \n bar barTitle2 [13, 42, 56.89] \n line lineTitle2 [45, 99, 012]",
    ),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("xAxisName" 1..3) set=true
      #|y="yAxisName" 11..99 set=false
      #|bar "barTitle1" ["1"=23,"2"=45,"3"=56.6] labels=-
      #|line "lineTitle1" ["1"=11,"1.6666666666666665"=45.5,"2.333333333333333"=67,"3"=23] labels=-
      #|bar "barTitle2" ["1"=13,"2"=42,"3"=56.89] labels=-
      #|line "lineTitle2" ["1"=45,"2"=99,"3"=12] labels=-
    ),
  )
  inspect(
    parsed(
      "\n    xychart horizontal\n    title \"Basic xychart\"\n    x-axis \"this is x axis\" [category1, \"category 2\", category3]\n    y-axis yaxisText 10 --> 150\n bar barTitle1 [23, 45, 56.6]\n line lineTitle1 [11, 45.5, 67, 23]\n bar barTitle2 [13, 42, 56.89]\n    line lineTitle2 [45, 99, 012]",
    ),
    content=(
      #|title="Basic xychart" accTitle=- accDescr=-
      #|orientation=horizontal
      #|x=band("this is x axis" ["category1","category 2","category3"]) set=true
      #|y="yaxisText" 10..150 set=true
      #|bar "barTitle1" ["category1"=23,"category 2"=45,"category3"=56.6] labels=-
      #|line "lineTitle1" ["category1"=11,"category 2"=45.5,"category3"=67] labels=-
      #|bar "barTitle2" ["category1"=13,"category 2"=42,"category3"=56.89] labels=-
      #|line "lineTitle2" ["category1"=45,"category 2"=99,"category3"=12] labels=-
    ),
  )
  inspect(
    parsed("xychart\nline [1]; bar [2]; line [3]"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("" 1..1) set=true
      #|y="" 1..3 set=false
      #|line "" ["1"=1] labels=-
      #|bar "" ["1"=2] labels=-
      #|line "" ["1"=3] labels=-
    ),
  )
}

///|
test "labels on the points of a series" {
  inspect(
    parsed(
      "xychart\nx-axis xAxisName\ny-axis yAxisName\n line [10 \"First\", 20 \"Second\", 30 \"Third\"]",
    ),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("xAxisName" 1..3) set=true
      #|y="yAxisName" 10..30 set=false
      #|line "" ["1"=10,"2"=20,"3"=30] labels=["First","Second","Third"]
    ),
  )
  inspect(
    parsed(
      "xychart\nx-axis xAxisName\ny-axis yAxisName\n line [10 \"Start\", 20, 30 \"End\"]",
    ),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("xAxisName" 1..3) set=true
      #|y="yAxisName" 10..30 set=false
      #|line "" ["1"=10,"2"=20,"3"=30] labels=["Start","","End"]
    ),
  )
  inspect(
    parsed(
      "xychart\nx-axis xAxisName\ny-axis yAxisName\n line [10 \"Hello World\", 20 \"Another Label\"]",
    ),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("xAxisName" 1..2) set=true
      #|y="yAxisName" 10..20 set=false
      #|line "" ["1"=10,"2"=20] labels=["Hello World","Another Label"]
    ),
  )
  inspect(
    parsed(
      "xychart\nx-axis xAxisName\ny-axis yAxisName\n line \"My Line\" [10 \"A\", 20 \"B\"]",
    ),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("xAxisName" 1..2) set=true
      #|y="yAxisName" 10..20 set=false
      #|line "My Line" ["1"=10,"2"=20] labels=["A","B"]
    ),
  )
  inspect(
    parsed(
      "xychart\nx-axis xAxisName\ny-axis yAxisName\n bar [10 \"A\", 20 \"B\", 30 \"C\"]",
    ),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("xAxisName" 1..3) set=true
      #|y="yAxisName" 10..30 set=false
      #|bar "" ["1"=10,"2"=20,"3"=30] labels=-
    ),
  )
  inspect(
    parsed(
      "xychart\nx-axis xAxisName\ny-axis yAxisName\n line [3.8 \"Phi-3\", 7 \"Mistral\", 540 \"PaLM\"]",
    ),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("xAxisName" 1..3) set=true
      #|y="yAxisName" 3.8..540 set=false
      #|line "" ["1"=3.8,"2"=7,"3"=540] labels=["Phi-3","Mistral","PaLM"]
    ),
  )
  inspect(
    parsed("xychart\nline [1 \"a\" \"b\"]"),
    content=(
      #|error: Parse error on line 2:
      #|line [1 "a" "b"]
      #|-------------^
      #|Expecting 'SQUARE_BRACES_END', got 'STR'
    ),
  )
  inspect(
    parsed("xychart\nline [1 \"  padded \", 2 \"\"]"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("" 1..2) set=true
      #|y="" 1..2 set=false
      #|line "" ["1"=1,"2"=2] labels=["padded",""]
    ),
  )
  inspect(
    parsed("xychart\nline [1 label]"),
    content=(
      #|error: Parse error on line 2:
      #|line [1 label]
      #|--------^
      #|Expecting 'SQUARE_BRACES_END', got 'ALPHA'
    ),
  )
}

///|
test "accessibility statements" {
  inspect(
    parsed("xychart\naccTitle: Accessible Title\nx-axis [Q1, Q2]\nline [1, 2]"),
    content=(
      #|title=- accTitle="Accessible Title" accDescr=-
      #|orientation=-
      #|x=band("" ["Q1","Q2"]) set=true
      #|y="" 1..2 set=false
      #|line "" ["Q1"=1,"Q2"=2] labels=-
    ),
  )
  inspect(
    parsed(
      "xychart\naccDescr: This is a description\nx-axis [Q1, Q2]\nline [1, 2]",
    ),
    content=(
      #|title=- accTitle=- accDescr="This is a description"
      #|orientation=-
      #|x=band("" ["Q1","Q2"]) set=true
      #|y="" 1..2 set=false
      #|line "" ["Q1"=1,"Q2"=2] labels=-
    ),
  )
  inspect(
    parsed(
      "xychart\naccDescr {\n  This is a multiline\n  description\n}\nx-axis [Q1, Q2]\nline [1, 2]",
    ),
    content=(
      #|title=- accTitle=- accDescr="This is a multiline\ndescription"
      #|orientation=-
      #|x=band("" ["Q1","Q2"]) set=true
      #|y="" 1..2 set=false
      #|line "" ["Q1"=1,"Q2"=2] labels=-
    ),
  )
  inspect(
    parsed(
      "xychart\naccTitle: Sales Overview\naccDescr: Revenue report for Q1-Q4\ntitle \"Revenue Report\"\nx-axis [Q1, Q2, Q3, Q4]\nline [45, 67, 89, 55]",
    ),
    content=(
      #|title="Revenue Report" accTitle="Sales Overview" accDescr="Revenue report for Q1-Q4"
      #|orientation=-
      #|x=band("" ["Q1","Q2","Q3","Q4"]) set=true
      #|y="" 45..89 set=false
      #|line "" ["Q1"=45,"Q2"=67,"Q3"=89,"Q4"=55] labels=-
    ),
  )
  inspect(
    parsed("xychart\naccTitle:\nline [1]"),
    content=(
      #|title=- accTitle="line [1]" accDescr=-
      #|orientation=-
      #|x=band("" []) set=false
      #|y="" Infinity..-Infinity set=false
    ),
  )
  inspect(
    parsed("xychart\naccDescr {\n}\nline [1]"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=linear("" 1..1) set=true
      #|y="" 1..1 set=false
      #|line "" ["1"=1] labels=-
    ),
  )
  inspect(
    parsed("xychart\naccTitle: one\naccTitle: two\nline [1]"),
    content=(
      #|title=- accTitle="two" accDescr=-
      #|orientation=-
      #|x=linear("" 1..1) set=true
      #|y="" 1..1 set=false
      #|line "" ["1"=1] labels=-
    ),
  )
  inspect(
    parsed("xychart\naccDescr {\nunclosed"),
    content=(
      #|title=- accTitle=- accDescr=""
      #|orientation=-
      #|x=band("" []) set=false
      #|y="" Infinity..-Infinity set=false
    ),
  )
}

///|
test "text that is not valid ends the parse with a lexical error" {
  inspect(
    parsed("xychart\n@"),
    content=(
      #|error: Lexical error on line 2. Unrecognized text.
      #|@
      #|^
    ),
  )
  inspect(
    parsed("xychart\ntitle caf\u{e9}\nline [1]"),
    content=(
      #|error: Lexical error on line 2. Unrecognized text.
      #|title café
      #|---------^
    ),
  )
  inspect(
    parsed("xychart\nline [1] ?"),
    content=(
      #|error: Lexical error on line 2. Unrecognized text.
      #|line [1] ?
      #|---------^
    ),
  )
  inspect(
    parsed("xychart\nline [1,\n2] \u{e9}"),
    content=(
      #|error: Parse error on line 2:
      #|line [1,
      #|--------^
      #|Expecting 'NUMBER_WITH_DECIMAL', got 'NEWLINE'
    ),
  )
  inspect(
    parsed("xychart\n\n\ntitle a\nline [1]\n\u{e9}"),
    content=(
      #|error: Lexical error on line 6. Unrecognized text.
      #|é
      #|^
    ),
  )
}

///|
test "a statement that is out of place" {
  inspect(
    parsed("xychart\n[1]"),
    content=(
      #|error: Parse error on line 2:
      #|[1]
      #|^
      #|Expecting 'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'SQUARE_BRACES_START'
    ),
  )
  inspect(
    parsed("xychart\n,"),
    content=(
      #|error: Parse error on line 2:
      #|,
      #|^
      #|Expecting 'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'COMMA'
    ),
  )
  inspect(
    parsed("xychart\n--> 1"),
    content=(
      #|error: Parse error on line 2:
      #|--> 1
      #|^
      #|Expecting 'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'MINUS'
    ),
  )
  inspect(
    parsed("xychart\n1"),
    content=(
      #|error: Parse error on line 2:
      #|1
      #|^
      #|Expecting 'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'NUM'
    ),
  )
  inspect(
    parsed("xychart\nxychart\ntitle t\nxychart"),
    content=(
      #|error: Parse error on line 4:
      #|xychart
      #|^
      #|Expecting 'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'XYCHART'
    ),
  )
  inspect(
    parsed("xychart\ntitle t\nxychart horizontal\nline [1]"),
    content=(
      #|error: Parse error on line 3:
      #|xychart horizontal
      #|^
      #|Expecting 'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'XYCHART'
    ),
  )
  inspect(
    parsed("xychart\nvertical"),
    content=(
      #|error: Parse error on line 2:
      #|vertical
      #|^
      #|Expecting 'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'CHART_ORIENTATION'
    ),
  )
  inspect(
    parsed("xychart\n\"string\""),
    content=(
      #|error: Parse error on line 2:
      #|"string"
      #|-^
      #|Expecting 'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'STR'
    ),
  )
  inspect(
    parsed("xychart\naccTitle"),
    content=(
      #|error: Parse error on line 2:
      #|accTitle
      #|^
      #|Expecting 'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'ALPHA'
    ),
  )
  inspect(
    parsed("xychart\naccDescr"),
    content=(
      #|error: Parse error on line 2:
      #|accDescr
      #|^
      #|Expecting 'title', 'X_AXIS', 'Y_AXIS', 'LINE', 'BAR', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'ALPHA'
    ),
  )
}

///|
test "the position an error is reported at" {
  inspect(
    parsed("xychart\n\n\nline [1, ]"),
    content=(
      #|error: Parse error on line 4:
      #|line [1, ]
      #|---------^
      #|Expecting 'NUMBER_WITH_DECIMAL', got 'SQUARE_BRACES_END'
    ),
  )
  inspect(
    parsed("xychart\n   title t\n   line [1, x]"),
    content=(
      #|error: Parse error on line 3:
      #|   line [1, x]
      #|------------^
      #|Expecting 'NUMBER_WITH_DECIMAL', got 'ALPHA'
    ),
  )
  inspect(
    parsed("xychart\ntitle a\nx-axis [1, 2\nline [1]"),
    content=(
      #|error: Parse error on line 3:
      #|x-axis [1, 2
      #|------------^
      #|Expecting 'SQUARE_BRACES_END', got 'NEWLINE'
    ),
  )
}

///|
test "the character before a comment is kept" {
  inspect(
    parsed("xychart-beta\nx-axis [a, b]\nbar [1,2]%% note"),
    content=(
      #|title=- accTitle=- accDescr=-
      #|orientation=-
      #|x=band("" ["a","b"]) set=true
      #|y="" 1..2 set=false
      #|bar "" ["a"=1,"b"=2] labels=-
    ),
  )
  assert_true(
    parsed("xychart-beta\ntitle Sales:%% note\nbar [1,2]").has_prefix("error: "),
  )
}
