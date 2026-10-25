// The expected streams were taken from pele's lexer.

///|
/// The token stream one per line, as `NAME@start "text"` with the text escaped.
fn lex(source : String) -> String {
  let tokens = @c4.tokenize(source)
  let lines = []
  for i, type_ in tokens.types {
    let text = @util.slice(source, tokens.starts[i], end=tokens.ends[i])
    lines.push("\{@c4.token_name(type_)}@\{tokens.starts[i]} \{quote(text)}")
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
test "reads shapes, boundaries and relations" {
  inspect(
    lex(
      "C4Context\ntitle System Context\nPerson(user, \"User\", \"Uses it\")\nEnterprise_Boundary(b, \"Bank\") {\n  System(app, \"App\")\n}\nRel(user, app, \"Uses\", $techn=\"HTTPS\")\n",
    ),
    content=(
      #|C4_CONTEXT@0 "C4Context"
      #|NEWLINE@9 "\n"
      #|title@10 "title System Context"
      #|NEWLINE@30 "\n"
      #|PERSON@31 "Person"
      #|STR@38 "user"
      #|STR@45 "User"
      #|STR@53 "Uses it"
      #|NEWLINE@62 "\n"
      #|ENTERPRISE_BOUNDARY@63 "Enterprise_Boundary"
      #|STR@83 "b"
      #|STR@87 "Bank"
      #|LBRACE@94 "{"
      #|NEWLINE@95 "\n"
      #|SYSTEM@98 "System"
      #|STR@105 "app"
      #|STR@111 "App"
      #|NEWLINE@116 "\n"
      #|RBRACE@117 "}"
      #|NEWLINE@118 "\n"
      #|REL@119 "Rel"
      #|STR@123 "user"
      #|STR@128 " app"
      #|STR@135 "Uses"
      #|STR_KEY@143 "techn"
      #|STR_VALUE@150 "HTTPS"
      #|NEWLINE@157 "\n"
      #|EOF@158 ""
      #|$end@158 ""
    ),
  )
}

///|
test "reads every header keyword and statement keyword" {
  inspect(
    lex(
      "C4Deployment\nDeployment_Node(n, \"N\"){\nNode_L(l, \"L\")\n{\nNode_R(r,\"R\") {\nContainerQueue_Ext(c, \"C\")\n}\n}\n}\nRel_Back(a, b, \"x\")\nRelIndex(1, a, b, \"y\")\nUpdateElementStyle(a, $bgColor=\"red\")\nUpdateRelStyle(a, b, \"red\")\nUpdateLayoutConfig(\"3\", \"1\")",
    ),
    content=(
      #|C4_DEPLOYMENT@0 "C4Deployment"
      #|NEWLINE@12 "\n"
      #|NODE@13 "Deployment_Node"
      #|STR@29 "n"
      #|STR@33 "N"
      #|LBRACE@36 "{"
      #|NEWLINE@37 "\n"
      #|NODE_L@38 "Node_L"
      #|STR@45 "l"
      #|STR@49 "L"
      #|NEWLINE@52 "\n"
      #|LBRACE@53 "{"
      #|NEWLINE@54 "\n"
      #|NODE_R@55 "Node_R"
      #|STR@62 "r"
      #|STR@65 "R"
      #|LBRACE@69 "{"
      #|NEWLINE@70 "\n"
      #|CONTAINER_EXT_QUEUE@71 "ContainerQueue_Ext"
      #|STR@90 "c"
      #|STR@94 "C"
      #|NEWLINE@97 "\n"
      #|RBRACE@98 "}"
      #|NEWLINE@99 "\n"
      #|RBRACE@100 "}"
      #|NEWLINE@101 "\n"
      #|RBRACE@102 "}"
      #|NEWLINE@103 "\n"
      #|REL_B@104 "Rel_Back"
      #|STR@113 "a"
      #|STR@115 " b"
      #|STR@120 "x"
      #|NEWLINE@123 "\n"
      #|REL_INDEX@124 "RelIndex"
      #|STR@133 "1"
      #|STR@135 " a"
      #|STR@138 " b"
      #|STR@143 "y"
      #|NEWLINE@146 "\n"
      #|UPDATE_EL_STYLE@147 "UpdateElementStyle"
      #|STR@166 "a"
      #|STR_KEY@170 "bgColor"
      #|STR_VALUE@179 "red"
      #|NEWLINE@184 "\n"
      #|UPDATE_REL_STYLE@185 "UpdateRelStyle"
      #|STR@200 "a"
      #|STR@202 " b"
      #|STR@207 "red"
      #|NEWLINE@212 "\n"
      #|UPDATE_LAYOUT_CONFIG@213 "UpdateLayoutConfig"
      #|STR@233 "3"
      #|STR@238 "1"
      #|EOF@241 ""
      #|$end@241 ""
    ),
  )
}

///|
test "takes the last direction statement on a line, through line breaks" {
  inspect(
    lex("C4Context\nx direction TB direction\n\nTB tail\nPerson(a, \"A\")"),
    content=(
      #|C4_CONTEXT@0 "C4Context"
      #|NEWLINE@9 "\n"
      #|direction_tb@10 "x direction TB direction\n\nTB tail"
      #|NEWLINE@43 "\n"
      #|PERSON@44 "Person"
      #|STR@51 "a"
      #|STR@55 "A"
      #|EOF@58 ""
      #|$end@58 ""
    ),
  )
}

///|
test "tries the directions in order" {
  inspect(
    lex("C4Context\ndirection LR\ndirection  BT\n direction RL"),
    content=(
      #|C4_CONTEXT@0 "C4Context"
      #|NEWLINE@9 "\n"
      #|direction_lr@10 "direction LR"
      #|NEWLINE@22 "\n"
      #|direction_bt@23 "direction  BT"
      #|NEWLINE@36 "\n"
      #|direction_rl@37 " direction RL"
      #|EOF@50 ""
      #|$end@50 ""
    ),
  )
}

///|
test "reads a direction word that is not a statement as an error" {
  inspect(
    lex("C4Context\ndirection XX\n"),
    content=(
      #|C4_CONTEXT@0 "C4Context"
      #|NEWLINE@9 "\n"
      #|INVALID@10 ""
    ),
  )
}

///|
test "reads accessibility statements" {
  inspect(
    lex(
      "C4Context\naccTitle : The title  \naccDescr:  one line\naccDescr  {\n  two\n  lines\n}\naccDescription described\n",
    ),
    content=(
      #|C4_CONTEXT@0 "C4Context"
      #|NEWLINE@9 "\n"
      #|acc_title@10 "accTitle : "
      #|acc_title_value@21 "The title  "
      #|NEWLINE@32 "\n"
      #|acc_descr@33 "accDescr:  "
      #|acc_descr_value@44 "one line"
      #|NEWLINE@52 "\n"
      #|acc_descr_multiline_value@67 "two\n  lines\n"
      #|NEWLINE@80 "\n"
      #|accDescription@81 "accDescription described"
      #|NEWLINE@105 "\n"
      #|EOF@106 ""
      #|$end@106 ""
    ),
  )
}

///|
test "skips a bare title with the line breaks after it" {
  inspect(
    lex("C4Context\ntitle\nThe title; and more\ntitle#x\n"),
    content=(
      #|C4_CONTEXT@0 "C4Context"
      #|NEWLINE@9 "\n"
      #|INVALID@16 ""
    ),
  )
}

///|
test "drops comments with the line breaks after them" {
  inspect(
    lex(
      "C4Context\n%% a comment\r\n\r\nPerson(a, \"A\") %% trailing\nSystem(b, \"B\")",
    ),
    content=(
      #|C4_CONTEXT@0 "C4Context"
      #|NEWLINE@9 "\n"
      #|PERSON@26 "Person"
      #|STR@33 "a"
      #|STR@37 "A"
      #|SYSTEM@53 "System"
      #|STR@60 "b"
      #|STR@64 "B"
      #|EOF@67 ""
      #|$end@67 ""
    ),
  )
}

///|
test "reads an unquoted argument through to the next comma" {
  inspect(
    lex("C4Context\nPerson(a, plain label)\nSystem(b, \"B\")"),
    content=(
      #|C4_CONTEXT@0 "C4Context"
      #|NEWLINE@9 "\n"
      #|PERSON@10 "Person"
      #|STR@17 "a"
      #|STR@19 " plain label)\nSystem(b"
      #|STR@44 "B"
      #|EOF@47 ""
      #|$end@47 ""
    ),
  )
}

///|
test "reads empty arguments" {
  inspect(
    lex("C4Context\nPerson( , a,,b, \"\", \"x\")\nPerson(,\"y\")"),
    content=(
      #|C4_CONTEXT@0 "C4Context"
      #|NEWLINE@9 "\n"
      #|PERSON@10 "Person"
      #|ATTRIBUTE_EMPTY@16 "( ,"
      #|STR@19 " a"
      #|ATTRIBUTE_EMPTY@21 ",,"
      #|STR@23 "b"
      #|ATTRIBUTE_EMPTY@25 " \"\""
      #|STR@31 "x"
      #|NEWLINE@34 "\n"
      #|PERSON@35 "Person"
      #|ATTRIBUTE_EMPTY@41 "(,"
      #|STR@44 "y"
      #|EOF@47 ""
      #|$end@47 ""
    ),
  )
}

///|
test "reads named arguments" {
  inspect(
    lex("C4Context\nSystem( $link = \"x\", $=\"\" , $k=\"v\")"),
    content=(
      #|C4_CONTEXT@0 "C4Context"
      #|NEWLINE@9 "\n"
      #|SYSTEM@10 "System"
      #|STR_KEY@19 "link "
      #|STR_VALUE@27 "x"
      #|STR_KEY@32 ""
      #|STR@35 " "
      #|STR_KEY@39 "k"
      #|STR_VALUE@42 "v"
      #|EOF@45 ""
      #|$end@45 ""
    ),
  )
}

///|
test "fails on a space before the parenthesis" {
  inspect(
    lex("C4Context\nPerson (a, \"A\")"),
    content=(
      #|C4_CONTEXT@0 "C4Context"
      #|NEWLINE@9 "\n"
      #|PERSON@10 "Person"
      #|INVALID@16 ""
    ),
  )
}

///|
test "fails on a named argument without a quoted value" {
  inspect(
    lex("C4Context\nPerson(a, $link=x)"),
    content=(
      #|C4_CONTEXT@0 "C4Context"
      #|NEWLINE@9 "\n"
      #|PERSON@10 "Person"
      #|STR@17 "a"
      #|STR_KEY@21 "link"
      #|INVALID@25 ""
    ),
  )
}

///|
test "fails on a word that is no keyword" {
  inspect(
    lex("C4Context\nPersons(a)"),
    content=(
      #|C4_CONTEXT@0 "C4Context"
      #|NEWLINE@9 "\n"
      #|INVALID@10 ""
    ),
  )
}

///|
test "ends in the middle of a statement" {
  inspect(
    lex("C4Context\nPerson"),
    content=(
      #|C4_CONTEXT@0 "C4Context"
      #|NEWLINE@9 "\n"
      #|PERSON@10 "Person"
      #|EOF_IN_STRUCT@16 ""
      #|$end@16 ""
    ),
  )
}

///|
test "ends in the middle of a string" {
  inspect(
    lex("C4Context\nPerson(a, \"open"),
    content=(
      #|C4_CONTEXT@0 "C4Context"
      #|NEWLINE@9 "\n"
      #|PERSON@10 "Person"
      #|STR@17 "a"
      #|STR@21 "open"
      #|STR@25 ""
      #|$end@25 ""
    ),
  )
}

///|
test "ends in the middle of a named argument" {
  inspect(
    lex("C4Context\nPerson(a, $k=\"v"),
    content=(
      #|C4_CONTEXT@0 "C4Context"
      #|NEWLINE@9 "\n"
      #|PERSON@10 "Person"
      #|STR@17 "a"
      #|STR_KEY@21 "k"
      #|STR_VALUE@24 "v"
      #|$end@25 ""
    ),
  )
}

///|
test "ends after a named key" {
  inspect(
    lex("C4Context\nPerson(a, $k"),
    content=(
      #|C4_CONTEXT@0 "C4Context"
      #|NEWLINE@9 "\n"
      #|PERSON@10 "Person"
      #|STR@17 "a"
      #|STR_KEY@21 "k"
      #|$end@22 ""
    ),
  )
}

///|
test "ends inside the arguments" {
  inspect(
    lex("C4Context\nPerson(a,"),
    content=(
      #|C4_CONTEXT@0 "C4Context"
      #|NEWLINE@9 "\n"
      #|PERSON@10 "Person"
      #|STR@17 "a"
      #|$end@19 ""
    ),
  )
}

///|
test "ends in an accessible title" {
  inspect(
    lex("C4Context\naccTitle:"),
    content=(
      #|C4_CONTEXT@0 "C4Context"
      #|NEWLINE@9 "\n"
      #|acc_title@10 "accTitle:"
      #|acc_title_value@19 ""
      #|$end@19 ""
    ),
  )
}

///|
test "ends in a multi-line description" {
  inspect(
    lex("C4Context\naccDescr { open"),
    content=(
      #|C4_CONTEXT@0 "C4Context"
      #|NEWLINE@9 "\n"
      #|acc_descr_multiline_value@21 "open"
      #|acc_descr_multiline_value@25 ""
      #|$end@25 ""
    ),
  )
}

///|
test "reads braces and blank lines" {
  inspect(
    lex("C4Context\n\n  \t\nBoundary(b, \"B\")\n  {\n}\n   "),
    content=(
      #|C4_CONTEXT@0 "C4Context"
      #|NEWLINE@9 "\n\n  \t\n"
      #|BOUNDARY@15 "Boundary"
      #|STR@24 "b"
      #|STR@28 "B"
      #|NEWLINE@31 "\n"
      #|LBRACE@34 "{"
      #|NEWLINE@35 "\n"
      #|RBRACE@36 "}"
      #|NEWLINE@37 "\n"
      #|EOF@41 ""
      #|$end@41 ""
    ),
  )
}
