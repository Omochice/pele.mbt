///|
test "the chart keyword and its orientation" {
  inspect(
    tokens("xychart"),
    content="XYCHART@0\"xychart\" EOF@7\"\" $end@7\"\"",
  )
  inspect(
    tokens("xychart-beta"),
    content="XYCHART@0\"xychart-beta\" EOF@12\"\" $end@12\"\"",
  )
  inspect(
    tokens("XYCHART-BETA Horizontal"),
    content="XYCHART@0\"XYCHART-BETA\" CHART_ORIENTATION@13\"Horizontal\" EOF@23\"\" $end@23\"\"",
  )
  inspect(
    tokens("xychart vertical\n"),
    content="XYCHART@0\"xychart\" CHART_ORIENTATION@8\"vertical\" NEWLINE@16\"\\n\" EOF@17\"\" $end@17\"\"",
  )
  inspect(
    tokens("xychart horizontal  \n  line [1]"),
    content="XYCHART@0\"xychart\" CHART_ORIENTATION@8\"horizontal\" LINE@23\"line\" SQUARE_BRACES_START@28\"[\" NUMBER_WITH_DECIMAL@29\"1\" SQUARE_BRACES_END@30\"]\" EOF@31\"\" $end@31\"\"",
  )
}

///|
test "keywords must end at a word boundary" {
  inspect(
    tokens("xychart-bet"),
    content="XYCHART@0\"xychart\" MINUS@7\"-\" ALPHA@8\"bet\" EOF@11\"\" $end@11\"\"",
  )
  inspect(
    tokens("xycharts"),
    content="ALPHA@0\"xycharts\" EOF@8\"\" $end@8\"\"",
  )
  inspect(
    tokens("x-axisy"),
    content="ALPHA@0\"x\" MINUS@1\"-\" ALPHA@2\"axisy\" EOF@7\"\" $end@7\"\"",
  )
  inspect(
    tokens("linex [1]"),
    content="ALPHA@0\"linex\" SQUARE_BRACES_START@6\"[\" NUM@7\"1\" SQUARE_BRACES_END@8\"]\" EOF@9\"\" $end@9\"\"",
  )
  inspect(
    tokens("bar_ [1]"),
    content="ALPHA@0\"bar\" UNDERSCORE@3\"_\" SQUARE_BRACES_START@5\"[\" NUM@6\"1\" SQUARE_BRACES_END@7\"]\" EOF@8\"\" $end@8\"\"",
  )
  inspect(
    tokens("titl x"),
    content="ALPHA@0\"titl\" ALPHA@5\"x\" EOF@6\"\" $end@6\"\"",
  )
  inspect(
    tokens("title_x"),
    content="ALPHA@0\"title\" UNDERSCORE@5\"_\" ALPHA@6\"x\" EOF@7\"\" $end@7\"\"",
  )
  inspect(
    tokens("verticalx"),
    content="CHART_ORIENTATION@0\"vertical\" ALPHA@8\"x\" EOF@9\"\" $end@9\"\"",
  )
  inspect(
    tokens("horizontal1"),
    content="CHART_ORIENTATION@0\"horizontal\" NUM@10\"1\" EOF@11\"\" $end@11\"\"",
  )
}

///|
test "keywords are read in any case" {
  inspect(
    tokens("XYCHART\nTITLE t\nX-AXIS a\nY-AXIS b\nLINE [1]\nBAR [2]"),
    content="XYCHART@0\"XYCHART\" NEWLINE@7\"\\n\" title@8\"TITLE\" ALPHA@14\"t\" NEWLINE@15\"\\n\" X_AXIS@16\"X-AXIS\" ALPHA@23\"a\" NEWLINE@24\"\\n\" Y_AXIS@25\"Y-AXIS\" ALPHA@32\"b\" NEWLINE@33\"\\n\" LINE@34\"LINE\" SQUARE_BRACES_START@39\"[\" NUMBER_WITH_DECIMAL@40\"1\" SQUARE_BRACES_END@41\"]\" NEWLINE@42\"\\n\" BAR@43\"BAR\" SQUARE_BRACES_START@47\"[\" NUMBER_WITH_DECIMAL@48\"2\" SQUARE_BRACES_END@49\"]\" EOF@50\"\" $end@50\"\"",
  )
}

///|
test "a title is read word by word" {
  inspect(
    tokens("xychart\ntitle Sales 2024-Q1 & more"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" title@8\"title\" ALPHA@14\"Sales\" NUM@20\"2024\" MINUS@24\"-\" ALPHA@25\"Q\" NUM@26\"1\" AMP@28\"&\" ALPHA@30\"more\" EOF@34\"\" $end@34\"\"",
  )
  inspect(
    tokens("xychart\ntitle \"A quoted title\""),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" title@8\"title\" STR@15\"A quoted title\" EOF@30\"\" $end@30\"\"",
  )
  inspect(
    tokens("xychart\ntitle _a.b+c=d*e#f"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" title@8\"title\" UNDERSCORE@14\"_\" ALPHA@15\"a\" DOT@16\".\" ALPHA@17\"b\" PLUS@18\"+\" ALPHA@19\"c\" EQUALS@20\"=\" ALPHA@21\"d\" MULT@22\"*\" ALPHA@23\"e\" BRKT@24\"#\" ALPHA@25\"f\" EOF@26\"\" $end@26\"\"",
  )
}

///|
test "quoted strings take everything up to the closing quote" {
  inspect(
    tokens("xychart\ntitle \"two\nlines\""),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" title@8\"title\" STR@15\"two\\nlines\" EOF@25\"\" $end@25\"\"",
  )
  inspect(
    tokens("xychart\ntitle \"unclosed"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" title@8\"title\" STR@15\"unclosed\" STR@23\"\" $end@23\"\"",
  )
  inspect(
    tokens("xychart\ntitle \"\""),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" title@8\"title\" EOF@16\"\" $end@16\"\"",
  )
  inspect(
    tokens("xychart\ntitle \"a %% b\""),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" title@8\"title\" STR@15\"a %% b\" EOF@22\"\" $end@22\"\"",
  )
}

///|
test "an axis with categories" {
  inspect(
    tokens("xychart\nx-axis \"Month\" [jan, \"feb mar\", apr]\n"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" X_AXIS@8\"x-axis\" STR@16\"Month\" SQUARE_BRACES_START@23\"[\" ALPHA@24\"jan\" COMMA@27\",\" STR@30\"feb mar\" COMMA@38\",\" ALPHA@40\"apr\" SQUARE_BRACES_END@43\"]\" NEWLINE@44\"\\n\" EOF@45\"\" $end@45\"\"",
  )
  inspect(
    tokens("xychart\nx-axis [a,b,c]\nline [1]"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" X_AXIS@8\"x-axis\" SQUARE_BRACES_START@15\"[\" ALPHA@16\"a\" COMMA@17\",\" ALPHA@18\"b\" COMMA@19\",\" ALPHA@20\"c\" SQUARE_BRACES_END@21\"]\" NEWLINE@22\"\\n\" LINE@23\"line\" SQUARE_BRACES_START@28\"[\" NUMBER_WITH_DECIMAL@29\"1\" SQUARE_BRACES_END@30\"]\" EOF@31\"\" $end@31\"\"",
  )
  inspect(
    tokens("xychart\nx-axis [a b, c-d, 1]"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" X_AXIS@8\"x-axis\" SQUARE_BRACES_START@15\"[\" ALPHA@16\"a\" ALPHA@18\"b\" COMMA@19\",\" ALPHA@21\"c\" MINUS@22\"-\" ALPHA@23\"d\" COMMA@24\",\" NUM@26\"1\" SQUARE_BRACES_END@27\"]\" EOF@28\"\" $end@28\"\"",
  )
}

///|
test "numbers inside an axis or a series" {
  inspect(
    tokens("xychart\nx-axis 45.5 --> 33"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" X_AXIS@8\"x-axis\" NUMBER_WITH_DECIMAL@15\"45.5\" ARROW_DELIMITER@20\"-->\" NUMBER_WITH_DECIMAL@24\"33\" EOF@26\"\" $end@26\"\"",
  )
  inspect(
    tokens("xychart\nx-axis -1 --> +2.5"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" X_AXIS@8\"x-axis\" NUMBER_WITH_DECIMAL@15\"-1\" ARROW_DELIMITER@18\"-->\" NUMBER_WITH_DECIMAL@22\"+2.5\" EOF@26\"\" $end@26\"\"",
  )
  inspect(
    tokens("xychart\nx-axis .5 --> 1."),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" X_AXIS@8\"x-axis\" NUMBER_WITH_DECIMAL@15\".5\" ARROW_DELIMITER@18\"-->\" NUMBER_WITH_DECIMAL@22\"1\" DOT@23\".\" EOF@24\"\" $end@24\"\"",
  )
  inspect(
    tokens("xychart\ny-axis t 0 --> 10\n"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" Y_AXIS@8\"y-axis\" ALPHA@15\"t\" NUMBER_WITH_DECIMAL@17\"0\" ARROW_DELIMITER@19\"-->\" NUMBER_WITH_DECIMAL@23\"10\" NEWLINE@25\"\\n\" EOF@26\"\" $end@26\"\"",
  )
  inspect(
    tokens("xychart\nline [1, -2, +3.5, .25, 1.5.5, 12abc]"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" LINE@8\"line\" SQUARE_BRACES_START@13\"[\" NUMBER_WITH_DECIMAL@14\"1\" COMMA@15\",\" NUMBER_WITH_DECIMAL@17\"-2\" COMMA@19\",\" NUMBER_WITH_DECIMAL@21\"+3.5\" COMMA@25\",\" NUMBER_WITH_DECIMAL@27\".25\" COMMA@30\",\" NUMBER_WITH_DECIMAL@32\"1.5\" NUMBER_WITH_DECIMAL@35\".5\" COMMA@37\",\" NUMBER_WITH_DECIMAL@39\"12\" ALPHA@41\"abc\" SQUARE_BRACES_END@44\"]\" EOF@45\"\" $end@45\"\"",
  )
}

///|
test "an arrow is only an arrow inside an axis" {
  inspect(
    tokens("xychart\nline [1 --> 2]"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" LINE@8\"line\" SQUARE_BRACES_START@13\"[\" NUMBER_WITH_DECIMAL@14\"1\" MINUS@16\"-\" MINUS@17\"-\" INVALID@18\"\"",
  )
  inspect(
    tokens("xychart\ntitle a --> b"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" title@8\"title\" ALPHA@14\"a\" MINUS@16\"-\" MINUS@17\"-\" INVALID@18\"\"",
  )
  inspect(
    tokens("xychart\nx-axis a-->b"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" X_AXIS@8\"x-axis\" ALPHA@15\"a\" ARROW_DELIMITER@16\"-->\" ALPHA@19\"b\" EOF@20\"\" $end@20\"\"",
  )
}

///|
test "a series with labelled points" {
  inspect(
    tokens("xychart\nline \"s\" [10 \"First\", 20, 30 \"Third\"]\nbar [1]"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" LINE@8\"line\" STR@14\"s\" SQUARE_BRACES_START@17\"[\" NUMBER_WITH_DECIMAL@18\"10\" STR@22\"First\" COMMA@28\",\" NUMBER_WITH_DECIMAL@30\"20\" COMMA@32\",\" NUMBER_WITH_DECIMAL@34\"30\" STR@38\"Third\" SQUARE_BRACES_END@44\"]\" NEWLINE@45\"\\n\" BAR@46\"bar\" SQUARE_BRACES_START@50\"[\" NUMBER_WITH_DECIMAL@51\"1\" SQUARE_BRACES_END@52\"]\" EOF@53\"\" $end@53\"\"",
  )
}

///|
test "a line break after an axis or a series leaves its state" {
  inspect(
    tokens("xychart\nx-axis [a]\nline [1]\nbar [2]\n"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" X_AXIS@8\"x-axis\" SQUARE_BRACES_START@15\"[\" ALPHA@16\"a\" SQUARE_BRACES_END@17\"]\" NEWLINE@18\"\\n\" LINE@19\"line\" SQUARE_BRACES_START@24\"[\" NUMBER_WITH_DECIMAL@25\"1\" SQUARE_BRACES_END@26\"]\" NEWLINE@27\"\\n\" BAR@28\"bar\" SQUARE_BRACES_START@32\"[\" NUMBER_WITH_DECIMAL@33\"2\" SQUARE_BRACES_END@34\"]\" NEWLINE@35\"\\n\" EOF@36\"\" $end@36\"\"",
  )
  inspect(
    tokens("xychart\nx-axis a\n\n\ny-axis b\r\nline [1]\r\n\r\n"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" X_AXIS@8\"x-axis\" ALPHA@15\"a\" NEWLINE@16\"\\n\" NEWLINE@17\"\\n\\n\" Y_AXIS@19\"y-axis\" ALPHA@26\"b\" NEWLINE@27\"\\r\\n\" LINE@29\"line\" SQUARE_BRACES_START@34\"[\" NUMBER_WITH_DECIMAL@35\"1\" SQUARE_BRACES_END@36\"]\" NEWLINE@37\"\\r\\n\" NEWLINE@39\"\\r\\n\" EOF@41\"\" $end@41\"\"",
  )
  inspect(
    tokens("xychart\nline [1\n,2]\nbar [3]"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" LINE@8\"line\" SQUARE_BRACES_START@13\"[\" NUMBER_WITH_DECIMAL@14\"1\" NEWLINE@15\"\\n\" COMMA@16\",\" NUMBER_WITH_DECIMAL@17\"2\" SQUARE_BRACES_END@18\"]\" NEWLINE@19\"\\n\" BAR@20\"bar\" SQUARE_BRACES_START@24\"[\" NUMBER_WITH_DECIMAL@25\"3\" SQUARE_BRACES_END@26\"]\" EOF@27\"\" $end@27\"\"",
  )
}

///|
test "a line break after spaces keeps the state of the line" {
  inspect(
    tokens("xychart\nx-axis a \n--> b"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" X_AXIS@8\"x-axis\" ALPHA@15\"a\" ARROW_DELIMITER@18\"-->\" ALPHA@22\"b\" EOF@23\"\" $end@23\"\"",
  )
  inspect(
    tokens("xychart\nline [1]  \n[2]"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" LINE@8\"line\" SQUARE_BRACES_START@13\"[\" NUMBER_WITH_DECIMAL@14\"1\" SQUARE_BRACES_END@15\"]\" SQUARE_BRACES_START@19\"[\" NUMBER_WITH_DECIMAL@20\"2\" SQUARE_BRACES_END@21\"]\" EOF@22\"\" $end@22\"\"",
  )
  inspect(
    tokens("xychart\nline \r[1]"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" LINE@8\"line\" SQUARE_BRACES_START@14\"[\" NUMBER_WITH_DECIMAL@15\"1\" SQUARE_BRACES_END@16\"]\" EOF@17\"\" $end@17\"\"",
  )
}

///|
test "comments run to the end of the line" {
  inspect(
    tokens("%% first\nxychart %% second\n%% third\nline [1] %% fourth"),
    content="NEWLINE@8\"\\n\" XYCHART@9\"xychart\" NEWLINE@35\"\\n\" LINE@36\"line\" SQUARE_BRACES_START@41\"[\" NUMBER_WITH_DECIMAL@42\"1\" SQUARE_BRACES_END@43\"]\" EOF@54\"\" $end@54\"\"",
  )
  inspect(
    tokens("xychart\n%%\nline [1]"),
    content="XYCHART@0\"xychart\" NEWLINE@10\"\\n\" LINE@11\"line\" SQUARE_BRACES_START@16\"[\" NUMBER_WITH_DECIMAL@17\"1\" SQUARE_BRACES_END@18\"]\" EOF@19\"\" $end@19\"\"",
  )
  inspect(
    tokens("xychart\nline [1]%%x\nbar [2]"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" LINE@8\"line\" SQUARE_BRACES_START@13\"[\" NUMBER_WITH_DECIMAL@14\"1\" NEWLINE@19\"\\n\" BAR@20\"bar\" SQUARE_BRACES_START@24\"[\" NUMBER_WITH_DECIMAL@25\"2\" SQUARE_BRACES_END@26\"]\" EOF@27\"\" $end@27\"\"",
  )
  inspect(
    tokens("xychart\ntitle a%%b\nbar [1]"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" title@8\"title\" NEWLINE@18\"\\n\" BAR@19\"bar\" SQUARE_BRACES_START@23\"[\" NUMBER_WITH_DECIMAL@24\"1\" SQUARE_BRACES_END@25\"]\" EOF@26\"\" $end@26\"\"",
  )
}

///|
test "a comment marker takes the character before it" {
  inspect(
    tokens("xychart\ntitle a%% c\ntitle b"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" title@8\"title\" NEWLINE@19\"\\n\" title@20\"title\" ALPHA@26\"b\" EOF@27\"\" $end@27\"\"",
  )
  inspect(
    tokens("xychart\nline [1,%%\n2]"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" LINE@8\"line\" SQUARE_BRACES_START@13\"[\" NUMBER_WITH_DECIMAL@14\"1\" NEWLINE@18\"\\n\" NUMBER_WITH_DECIMAL@19\"2\" SQUARE_BRACES_END@20\"]\" EOF@21\"\" $end@21\"\"",
  )
  inspect(
    tokens("xychart\n}%%x"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" INVALID@8\"\"",
  )
}

///|
test "accessibility statements" {
  inspect(
    tokens("xychart\naccTitle: A title\naccDescr: A description\nline [1]"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" acc_title@8\"accTitle: \" acc_title_value@18\"A title\" NEWLINE@25\"\\n\" acc_descr@26\"accDescr: \" acc_descr_value@36\"A description\" NEWLINE@49\"\\n\" LINE@50\"line\" SQUARE_BRACES_START@55\"[\" NUMBER_WITH_DECIMAL@56\"1\" SQUARE_BRACES_END@57\"]\" EOF@58\"\" $end@58\"\"",
  )
  inspect(
    tokens("xychart\nACCTITLE:  padded  \n"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" acc_title@8\"ACCTITLE:  \" acc_title_value@19\"padded  \" NEWLINE@27\"\\n\" EOF@28\"\" $end@28\"\"",
  )
  inspect(
    tokens("xychart\naccDescr {\n  multi\n  line\n}\nline [1]"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" acc_descr_multiline_value@21\"multi\\n  line\\n\" NEWLINE@35\"\\n\" LINE@36\"line\" SQUARE_BRACES_START@41\"[\" NUMBER_WITH_DECIMAL@42\"1\" SQUARE_BRACES_END@43\"]\" EOF@44\"\" $end@44\"\"",
  )
  inspect(
    tokens("xychart\naccTitle:\nline [1]"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" acc_title@8\"accTitle:\\n\" acc_title_value@18\"line [1]\" EOF@26\"\" $end@26\"\"",
  )
  inspect(
    tokens("xychart\naccDescr{ x }\n"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" acc_descr_multiline_value@18\"x \" NEWLINE@21\"\\n\" EOF@22\"\" $end@22\"\"",
  )
  inspect(
    tokens("xychart\naccDescr: a %% b\nbar [1]"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" acc_descr@8\"accDescr: \" acc_descr_value@18\"a %% b\" NEWLINE@24\"\\n\" BAR@25\"bar\" SQUARE_BRACES_START@29\"[\" NUMBER_WITH_DECIMAL@30\"1\" SQUARE_BRACES_END@31\"]\" EOF@32\"\" $end@32\"\"",
  )
  inspect(
    tokens("xychart\naccDescr {\nunclosed"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" acc_descr_multiline_value@19\"unclosed\" acc_descr_multiline_value@27\"\" $end@27\"\"",
  )
  inspect(
    tokens("xychart\naccTitle: unclosed"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" acc_title@8\"accTitle: \" acc_title_value@18\"unclosed\" EOF@26\"\" $end@26\"\"",
  )
}

///|
test "accessibility keywords that are not statements" {
  inspect(
    tokens("xychart\naccTitle"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" ALPHA@8\"accTitle\" EOF@16\"\" $end@16\"\"",
  )
  inspect(
    tokens("xychart\naccTitle x"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" ALPHA@8\"accTitle\" ALPHA@17\"x\" EOF@18\"\" $end@18\"\"",
  )
  inspect(
    tokens("xychart\naccDescr {"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" acc_descr_multiline_value@18\"\" $end@18\"\"",
  )
  inspect(
    tokens("xychart\nacc"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" ALPHA@8\"acc\" EOF@11\"\" $end@11\"\"",
  )
  inspect(
    tokens("xychart\naccTitlex: a"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" ALPHA@8\"accTitlex\" COLON@17\":\" ALPHA@19\"a\" EOF@20\"\" $end@20\"\"",
  )
}

///|
test "punctuation outside axes and series" {
  inspect(
    tokens("xychart\n: + , = * # _ . & - ;"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" COLON@8\":\" PLUS@10\"+\" COMMA@12\",\" EQUALS@14\"=\" MULT@16\"*\" BRKT@18\"#\" UNDERSCORE@20\"_\" DOT@22\".\" AMP@24\"&\" MINUS@26\"-\" SEMI@28\";\" EOF@29\"\" $end@29\"\"",
  )
  inspect(
    tokens("xychart\n[ ]"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" SQUARE_BRACES_START@8\"[\" SQUARE_BRACES_END@10\"]\" EOF@11\"\" $end@11\"\"",
  )
  inspect(
    tokens("xychart\ntitle a;title b"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" title@8\"title\" ALPHA@14\"a\" SEMI@15\";\" title@16\"title\" ALPHA@22\"b\" EOF@23\"\" $end@23\"\"",
  )
}

///|
test "text that is not a token ends the input with an error" {
  inspect(
    tokens("xychart\n@"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" INVALID@8\"\"",
  )
  inspect(
    tokens("xychart\ntitle caf\u{e9}"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" title@8\"title\" ALPHA@14\"caf\" INVALID@17\"\"",
  )
  inspect(
    tokens("xychart\nline [1] ?"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" LINE@8\"line\" SQUARE_BRACES_START@13\"[\" NUMBER_WITH_DECIMAL@14\"1\" SQUARE_BRACES_END@15\"]\" INVALID@17\"\"",
  )
  inspect(
    tokens("xychart\ntitle \"ok\" \u{e9}\nline [1]"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" title@8\"title\" STR@15\"ok\" INVALID@19\"\"",
  )
}

///|
test "the markdown string rule that Mermaid breaks" {
  inspect(
    tokens("xychart\ntitle `) {}"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" title@8\"title\" INVALID@14\"\"",
  )
  inspect(
    tokens("xychart\n`)"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" INVALID@8\"\"",
  )
  inspect(
    tokens("xychart\n`"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" INVALID@8\"\"",
  )
  inspect(
    tokens("xychart\ntitle \"`a`\""),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" title@8\"title\" STR@15\"`a`\" EOF@19\"\" $end@19\"\"",
  )
}

///|
test "whitespace of every kind between tokens" {
  inspect(
    tokens("xychart\t \u{000b}\f\ntitle\u{a0}x"),
    content="XYCHART@0\"xychart\" title@12\"title\" ALPHA@18\"x\" EOF@19\"\" $end@19\"\"",
  )
  inspect(
    tokens("xychart\n\ttitle\ta"),
    content="XYCHART@0\"xychart\" NEWLINE@7\"\\n\" title@9\"title\" ALPHA@15\"a\" EOF@16\"\" $end@16\"\"",
  )
  inspect(
    tokens("xychart  \n  \n  \n title x"),
    content="XYCHART@0\"xychart\" title@17\"title\" ALPHA@23\"x\" EOF@24\"\" $end@24\"\"",
  )
}

///|
test "empty and blank sources" {
  inspect(tokens(""), content="EOF@0\"\" $end@0\"\"")
  inspect(tokens(" "), content="EOF@1\"\" $end@1\"\"")
  inspect(tokens("\n"), content="NEWLINE@0\"\\n\" EOF@1\"\" $end@1\"\"")
  inspect(
    tokens("\n\n  \n"),
    content="NEWLINE@0\"\\n\\n\" EOF@5\"\" $end@5\"\"",
  )
  inspect(tokens("%%"), content="EOF@2\"\" $end@2\"\"")
}
