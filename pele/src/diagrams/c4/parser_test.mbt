// The expected models and messages were taken from pele's parser.

///|
/// The model a source builds, one line for the diagram and one per shape, boundary and relation; or the error it raises.
fn parsed(source : String) -> String {
  let db = @c4.C4Db::new()
  @c4.parse_c4(source, db) catch {
    @errors.PeleError(failure) => return "error: \{failure.message}"
  }
  let lines = [
    "c4Type=\{unset(db.c4_type)} title=\{unset(db.title)} accDescr=\{unset(db.acc_descr)} rows=\{rows(db)}",
  ]
  for shape in db.shapes {
    lines.push("shape \{show_element(shape)}")
  }
  for i in 1..<db.boundaries.length() {
    lines.push("boundary \{show_element(db.boundaries[i])}")
  }
  for rel in db.rels {
    lines.push("rel \{show_rel(rel)}")
  }
  lines.join("\n")
}

///|
test "accepts all five diagram keywords" {
  inspect(
    parsed("C4Container\nPerson(a, \"A\")"),
    content=(
      #|c4Type=C4Container title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=a label=A kind=person parent=global descr=
    ),
  )
}

///|
test "records the header keyword last" {
  inspect(
    parsed("C4Deployment\ntitle T\nNode(n, \"N\") {\nContainer(a, \"A\")\n}"),
    content=(
      #|c4Type=C4Deployment title=T accDescr=<unset> rows=4 2
      #|shape alias=a label=A kind=container parent=n descr= techn=
      #|boundary alias=n label=N parent=global type=node descr= nodeType=node
    ),
  )
}

///|
test "nests boundaries written with the brace on the next line" {
  inspect(
    parsed(
      "C4Context\nEnterprise_Boundary(e, \"E\")\n{\n  System_Boundary(s, \"S\")\n  {\n    Container_Boundary(c, \"C\") {\n      Boundary(b, \"B\") {\n        System(x, \"X\")\n      }\n    }\n  }\n}\nSystem(after, \"After\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=x label=X kind=system parent=b descr=
      #|shape alias=after label=After kind=system parent=global descr=
      #|boundary alias=e label=E parent=global type=ENTERPRISE
      #|boundary alias=s label=S parent=e type=SYSTEM
      #|boundary alias=c label=C parent=s type=CONTAINER
      #|boundary alias=b label=B parent=c type=system
    ),
  )
}

///|
test "splices the kind of a typed boundary into its third slot" {
  inspect(
    parsed(
      "C4Context\nEnterprise_Boundary(\"e\") {\nSystem(x, \"X\")\n}\nSystem_Boundary(s, \"S\", $tags=\"t\") {\nSystem(y, \"Y\")\n}",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=x label=X kind=system parent=e descr=
      #|shape alias=y label=Y kind=system parent=s descr=
      #|boundary alias=e label=ENTERPRISE parent=global type=system
      #|boundary alias=s label=S parent=global type=SYSTEM tags=t
    ),
  )
}

///|
test "reads deployment nodes of each side" {
  inspect(
    parsed(
      "C4Deployment\nDeployment_Node(outer, \"Outer\", \"Linux\", \"A machine\") {\n  Node(inner, \"Inner\") {\n    Container(app, \"App\")\n  }\n  Node_L(left, \"Left\") {\n    Container(other, \"Other\")\n  }\n  Node_R(right, \"Right\") {\n    Container(third, \"Third\")\n  }\n}",
    ),
    content=(
      #|c4Type=C4Deployment title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=app label=App kind=container parent=inner descr= techn=
      #|shape alias=other label=Other kind=container parent=left descr= techn=
      #|shape alias=third label=Third kind=container parent=right descr= techn=
      #|boundary alias=outer label=Outer parent=global type=Linux descr=A machine nodeType=node
      #|boundary alias=inner label=Inner parent=outer type=node descr= nodeType=node
      #|boundary alias=left label=Left parent=outer type=node descr= nodeType=nodeL
      #|boundary alias=right label=Right parent=outer type=node descr= nodeType=nodeR
    ),
  )
}

///|
test "reads every kind of relation" {
  inspect(
    parsed(
      "C4Context\nSystem(a, \"A\")\nSystem(b, \"B\")\nRel(a, b, \"1\")\nBiRel(b, a, \"2\")\nRel_U(a, a, \"3\")\nRel_Up(b, b, \"4\")\nRel_D(a, \"x\", \"5\")\nRel_Down(b, \"x\", \"6\")\nRel_L(a, \"y\", \"7\")\nRel_Left(b, \"y\", \"8\")\nRel_R(a, \"z\", \"9\")\nRel_Right(b, \"z\", \"10\")\nRel_Back(x, y, \"11\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=a label=A kind=system parent=global descr=
      #|shape alias=b label=B kind=system parent=global descr=
      #|rel type=rel from=a to=b label=1 techn= descr=
      #|rel type=birel from=b to=a label=2 techn= descr=
      #|rel type=rel_u from=a to=a label=3 techn= descr=
      #|rel type=rel_u from=b to=b label=4 techn= descr=
      #|rel type=rel_d from=a to=x label=5 techn= descr=
      #|rel type=rel_d from=b to=x label=6 techn= descr=
      #|rel type=rel_l from=a to=y label=7 techn= descr=
      #|rel type=rel_l from=b to=y label=8 techn= descr=
      #|rel type=rel_r from=a to=z label=9 techn= descr=
      #|rel type=rel_r from=b to=z label=10 techn= descr=
      #|rel type=rel_b from=x to=y label=11 techn= descr=
    ),
  )
}

///|
test "ignores the index of RelIndex and a relation without a label" {
  inspect(
    parsed(
      "C4Dynamic\nSystem(a, \"A\")\nSystem(b, \"B\")\nRelIndex(7, a, b, \"x\")\nRel(b, \"a\")",
    ),
    content=(
      #|c4Type=C4Dynamic title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=a label=A kind=system parent=global descr=
      #|shape alias=b label=B kind=system parent=global descr=
      #|rel type=rel from=a to=b label=x techn= descr=
    ),
  )
}

///|
test "applies style and layout updates" {
  inspect(
    parsed(
      "C4Context\nSystem(a, \"A\")\nSystem(b, \"B\")\nRel(a, b, \"x\")\nUpdateElementStyle(a, $bgColor=\"grey\")\nUpdateRelStyle(a, b, \"red\", \"blue\", \"30\", \"-10\")\nUpdateLayoutConfig($c4ShapeInRow=\"2\", $c4BoundaryInRow=\"1\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=2 1
      #|shape alias=a label=A kind=system parent=global descr= bgColor=grey
      #|shape alias=b label=B kind=system parent=global descr=
      #|rel type=rel from=a to=b label=x techn= descr= textColor=red lineColor=blue offsetX=30 offsetY=-10
    ),
  )
}

///|
test "treats accTitle as the title and reads descriptions" {
  inspect(
    parsed(
      "C4Context\naccTitle: Shown on top\naccDescr: For screen readers\nSystem(a, \"A\")",
    ),
    content=(
      #|c4Type=C4Context title=Shown on top accDescr=For screen readers rows=4 2
      #|shape alias=a label=A kind=system parent=global descr=
    ),
  )
}

///|
test "reads a multi-line description" {
  inspect(
    parsed("C4Context\naccDescr {\n  two\n  lines\n}\nSystem(a, \"A\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=two
      #|lines rows=4 2
      #|shape alias=a label=A kind=system parent=global descr=
    ),
  )
}

///|
test "reads a one-line accDescription" {
  inspect(
    parsed("C4Context\naccDescription one line\nSystem(a, \"A\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=one line rows=4 2
      #|shape alias=a label=A kind=system parent=global descr=
    ),
  )
}

///|
test "lets a title run straight into a statement" {
  inspect(
    parsed(
      "C4Context\ntitle T\nSystem(a, \"A\")\ntitle U\naccTitle: V\nSystem(b, \"B\")",
    ),
    content=(
      #|c4Type=C4Context title=V accDescr=<unset> rows=4 2
      #|shape alias=a label=A kind=system parent=global descr=
      #|shape alias=b label=B kind=system parent=global descr=
    ),
  )
}

///|
test "reads an unquoted last argument through to the next comma" {
  inspect(
    parsed("C4Context\nPerson(a, plain label)\nSystem(b, \"B\")"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=a label=plain label)
      #|System(b kind=person parent=global descr=B
    ),
  )
}

///|
test "reads a named argument wherever it is written" {
  inspect(
    parsed(
      "C4Container\nPerson(a, $sprite=\"users\")\nContainer(b, \"B\", $descr=\"described\")\nContainer($tags=\"t\", \"Anonymous\")\nNode(n, \"N\", \"t\", \"d\", $link=\"https://example.com\") {\n  Container(c, \"C\", $unknown=\"kept\", $__proto__=\"safe\")\n}\nRel(a, b, $techn=\"HTTP\")",
    ),
    content=(
      #|c4Type=C4Container title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=a label= labelAttr=sprite:users kind=person parent=global descr= sprite=users
      #|shape alias=b label=B kind=container parent=global descr=described
      #|shape alias= label=Anonymous aliasAttr=tags:t kind=container parent=global descr= techn= tags=t
      #|shape alias=c label=C kind=container parent=n extra={unknown:kept,__proto__:safe}
      #|boundary alias=n label=N parent=global type=t descr=d link=https://example.com nodeType=node
      #|rel type=rel from=a to=b label= labelAttr=techn:HTTP techn=HTTP descr=
    ),
  )
}

///|
test "merges a repeated alias" {
  inspect(
    parsed(
      "C4Context\nSystem(a, \"First\", \"d1\")\nSystem(b, \"B\")\nBoundary(x, \"X\") {\n  Person(a, \"Second\")\n}\nRel(a, b, \"one\", \"t\")\nBiRel(a, b, \"two\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=a label=Second kind=person parent=x descr=d1
      #|shape alias=b label=B kind=system parent=global descr=
      #|boundary alias=x label=X parent=global type=system
      #|rel type=birel from=a to=b label=two techn=t descr=
    ),
  )
}

///|
test "skips comments and blank lines" {
  inspect(
    parsed("C4Context\n%% a comment\n\nSystem(a, \"A\") %% trailing\n\n%% last"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=a label=A kind=system parent=global descr=
    ),
  )
}

///|
test "accepts empty arguments" {
  inspect(
    parsed(
      "C4Context\nSystem(,\"A\")\nSystem(b, , \"d\")\nSystem(c, \"\", \"\")",
    ),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias= label=A kind=system parent=global descr=
      #|shape alias=b label= kind=system parent=global descr=d
      #|shape alias=c label= kind=system parent=global descr=
    ),
  )
}

///|
test "rejects a space before the parenthesis as a lexical error" {
  inspect(
    parsed("C4Context\nPerson (a, \"A\")"),
    content=(
      #|error: Lexical error on line 2. Unrecognized text.
      #|Person (a, "A")
      #|------^
    ),
  )
}

///|
test "rejects two statements on one line" {
  inspect(
    parsed("C4Context\nPerson(a, \"A\") Person(b, \"B\")"),
    content=(
      #|error: Parse error on line 2:
      #|Person(a, "A") Person(b, "B")
      #|---------------^
      #|Expecting 'NEWLINE', 'EOF', got 'PERSON'
    ),
  )
}

///|
test "rejects a boundary without a brace" {
  inspect(
    parsed("C4Context\nBoundary(b, \"B\")\nSystem(a, \"A\")"),
    content=(
      #|error: Parse error on line 3:
      #|System(a, "A")
      #|^
      #|Expecting 'LBRACE', got 'SYSTEM'
    ),
  )
}

///|
test "rejects an unclosed boundary" {
  inspect(
    parsed("C4Context\nBoundary(b, \"B\") {\nSystem(a, \"A\")"),
    content=(
      #|error: Parse error on line 3:
      #|System(a, "A")
      #|--------------^
      #|Expecting 'NEWLINE', 'RBRACE', got 'EOF'
    ),
  )
}

///|
test "rejects a diagram with no statement" {
  inspect(
    parsed("C4Context\n"),
    content=(
      #|error: Parse error on line 2:
      #|
      #|^
      #|Expecting 'title', 'accDescription', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'PERSON', 'REL', got 'EOF'
    ),
  )
}

///|
test "rejects a header alone" {
  inspect(
    parsed("C4Context"),
    content=(
      #|error: Parse error on line 1:
      #|C4Context
      #|---------^
      #|Expecting 'NEWLINE', got 'EOF'
    ),
  )
}

///|
test "rejects an empty named value" {
  inspect(
    parsed("C4Context\nPerson(a, \"A\", $link=\"\")"),
    content=(
      #|error: Parse error on line 2:
      #|Person(a, "A", $link="")
      #|------------------------^
      #|Expecting 'STR_VALUE', got 'EOF'
    ),
  )
}

///|
test "rejects an unclosed statement" {
  inspect(
    parsed("C4Context\nPerson(a, \"A\""),
    content=(
      #|error: Parse error on line 2:
      #|Person(a, "A"
      #|-------------^
      #|Expecting 'NEWLINE', 'EOF', got '$end'
    ),
  )
}

///|
test "rejects a statement without arguments" {
  inspect(
    parsed("C4Context\nPerson()"),
    content=(
      #|error: Parse error on line 2:
      #|Person()
      #|--------^
      #|Expecting 'STR', 'STR_KEY', 'ATTRIBUTE', 'ATTRIBUTE_EMPTY', got 'EOF'
    ),
  )
}

///|
test "rejects a keyword without parentheses" {
  inspect(
    parsed("C4Context\nPerson\n"),
    content=(
      #|error: Lexical error on line 2. Unrecognized text.
      #|Person
      #|------^
    ),
  )
}

///|
test "rejects a missing header" {
  inspect(
    parsed("Person(a, \"A\")"),
    content=(
      #|error: Parse error on line 1:
      #|Person(a, "A")
      #|^
      #|Expecting 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'C4_CONTEXT', 'C4_CONTAINER', 'C4_COMPONENT', 'C4_DYNAMIC', 'C4_DEPLOYMENT', got 'PERSON'
    ),
  )
}

///|
test "rejects a title inside a boundary before any statement" {
  inspect(
    parsed("C4Context\nBoundary(b, \"B\") {\ntitle T\nSystem(a, \"A\")\n}"),
    content=(
      #|error: Parse error on line 3:
      #|title T
      #|^
      #|Expecting 'title', 'accDescription', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'PERSON', 'REL', got 'title'
    ),
  )
}

///|
test "rejects a stray closing brace" {
  inspect(
    parsed("C4Context\nSystem(a, \"A\")\n}"),
    content=(
      #|error: Parse error on line 3:
      #|}
      #|^
      #|Expecting 'NEWLINE', 'EOF', got 'RBRACE'
    ),
  )
}

///|
test "rejects a direction statement, which the grammar never uses" {
  inspect(
    parsed("C4Context\ndirection TB\nSystem(a, \"A\")"),
    content=(
      #|error: Parse error on line 2:
      #|direction TB
      #|^
      #|Expecting 'title', 'accDescription', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'PERSON', 'REL', got 'direction_tb'
    ),
  )
}

///|
test "rejects a brace on its own line inside a boundary" {
  inspect(
    parsed("C4Context\nBoundary(b, \"B\") {\n{\n}"),
    content=(
      #|error: Parse error on line 3:
      #|{
      #|^
      #|Expecting 'title', 'accDescription', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'PERSON', 'REL', got 'LBRACE'
    ),
  )
}

///|
test "rejects an accTitle without a value at the end" {
  inspect(
    parsed("C4Context\naccTitle:"),
    content=(
      #|error: Parse error on line 2:
      #|accTitle:
      #|---------^
      #|Expecting 'NEWLINE', 'EOF', got '$end'
    ),
  )
}

///|
test "accepts a header followed by spaces and a statement" {
  inspect(
    parsed("C4Context   \n  System(a, \"A\")  \n"),
    content=(
      #|c4Type=C4Context title=<unset> accDescr=<unset> rows=4 2
      #|shape alias=a label=A kind=system parent=global descr=
    ),
  )
}
