// Ported from Mermaid's requirementDiagram.spec.js, as pele v1.8.0 runs it in tests/compat/requirement, and from pele's own tests of the grammar.

///|
fn parsed(src : String) -> @requirement.RequirementDb raise @errors.PeleError {
  let db = @requirement.RequirementDb::new()
  @requirement.parse_requirement(src, db)
  db
}

///|
fn parse_error(src : String) -> String {
  try {
    ignore(parsed(src))
    "no error"
  } catch {
    @errors.PeleError(failure) => failure.message
  }
}

///|
fn join_quoted(texts : Array[String]) -> String {
  "[" + texts.map(text => text.escape()).join(", ") + "]"
}

///|
fn requirement_body(kind : String, risk : String, verify : String) -> String {
  "requirementDiagram\n\n\{kind} test_req {\nid: test_id\ntext: the test text.\nrisk: \{risk}\nverifymethod: \{verify}\n}"
}

///|
test "accepts a full requirement definition" {
  let db = parsed(requirement_body("requirement", "High", "Analysis"))
  inspect(db.requirements.length(), content="1")
  let r = db.requirements.get("test_req").unwrap()
  inspect(
    "\{r.kind}|\{r.requirement_id}|\{r.text}|\{r.risk}|\{r.verify_method}",
    content="Requirement|test_id|the test text.|High|Analysis",
  )
  inspect(db.elements.length(), content="0")
  inspect(db.relations.length(), content="0")
}

///|
test "accepts a full element definition" {
  let db = parsed(
    "requirementDiagram\n\nelement test_el {\ntype: test_type\ndocref: test_ref\n}",
  )
  inspect(db.requirements.length(), content="0")
  let e = db.elements.get("test_el").unwrap()
  inspect("\{e.kind}|\{e.doc_ref}", content="test_type|test_ref")
  inspect(db.relations.length(), content="0")
}

///|
test "uses an accessible title and a description on one line or many" {
  let db = parsed(
    "requirementDiagram\n      accTitle: test title\n      accDescr: my chart description\n      element test_name {\n      type: test_type\n      docref: test_ref\n      }",
  )
  inspect(db.acc_title.unwrap(), content="test title")
  inspect(db.acc_descr.unwrap(), content="my chart description")
  let db = parsed(
    "requirementDiagram\n      accTitle: test title\n      accDescr {\n        my chart description\nline 2\n      }\n      element test_name {\n      type: test_type\n      docref: test_ref\n      }",
  )
  inspect(db.acc_title.unwrap(), content="test title")
  inspect(db.acc_descr.unwrap(), content="my chart description\nline 2")
}

///|
test "accepts a full relationship definition" {
  let db = parsed("requirementDiagram\n\na - contains -> b")
  inspect(db.requirements.length(), content="0")
  inspect(db.elements.length(), content="0")
  let r = db.relations[0]
  inspect("\{r.src} \{r.kind} \{r.dst}", content="a contains b")
}

///|
test "names each type of requirement" {
  let kinds = [
    "requirement", "functionalRequirement", "interfaceRequirement", "performanceRequirement",
    "physicalRequirement", "designConstraint",
  ]
  let names = kinds.map(kind => {
    parsed(requirement_body(kind, "High", "Analysis")).requirements
    .get("test_req")
    .unwrap().kind
  })
  inspect(
    join_quoted(names),
    content="[\"Requirement\", \"Functional Requirement\", \"Interface Requirement\", \"Performance Requirement\", \"Physical Requirement\", \"Design Constraint\"]",
  )
}

///|
test "names each risk and each verification method" {
  let risks = ["Low", "Medium", "High"].map(risk => {
    parsed(requirement_body("designConstraint", risk, "Analysis")).requirements
    .get("test_req")
    .unwrap().risk
  })
  inspect(join_quoted(risks), content="[\"Low\", \"Medium\", \"High\"]")
  let methods = ["Analysis", "Inspection", "Test", "Demonstration"].map(method => {
    parsed(requirement_body("designConstraint", "High", method)).requirements
    .get("test_req")
    .unwrap().verify_method
  })
  inspect(
    join_quoted(methods),
    content="[\"Analysis\", \"Inspection\", \"Test\", \"Demonstration\"]",
  )
}

///|
test "names each relationship" {
  let kinds = [
    "contains", "copies", "derives", "satisfies", "verifies", "refines", "traces",
  ]
  let found = kinds.map(kind => {
    parsed("requirementDiagram\n\na - \{kind} -> b").relations[0].kind
  })
  inspect(
    join_quoted(found),
    content="[\"contains\", \"copies\", \"derives\", \"satisfies\", \"verifies\", \"refines\", \"traces\"]",
  )
}

///|
test "accepts names that are object keys in JavaScript" {
  for name in ["__proto__", "constructor"] {
    let db = parsed(
      "requirementDiagram\n      requirement \{name} {\n        id: 1\n        text: the test text.\n        risk: high\n        verifymethod: test\n      }",
    )
    inspect(db.requirements.length(), content="1")
    let db = parsed(
      "requirementDiagram\n      element \{name} {\n        type: simulation\n      }",
    )
    inspect(db.elements.length(), content="1")
  }
}

///|
test "styles a requirement, an element, or several at once" {
  let db = parsed(
    "requirementDiagram\n\nrequirement test_req {\n}\nelement test_element {\n}\nstyle test_req fill:#f9f,stroke:#333,stroke-width:4px\nstyle test_req,test_element fill:#f9f\n",
  )
  inspect(
    join_quoted(db.requirements.get("test_req").unwrap().css_styles),
    content="[\"fill:#f9f\", \"stroke:#333\", \"stroke-width:4px\", \"fill:#f9f\"]",
  )
  inspect(
    join_quoted(db.elements.get("test_element").unwrap().css_styles),
    content="[\"fill:#f9f\"]",
  )
}

///|
test "defines one class or several at once" {
  let db = parsed(
    "requirementDiagram\n\nclassDef myClass fill:#f9f,stroke:#333,stroke-width:4px\nclassDef firstClass,secondClass color:blue\n",
  )
  let show = (id : String) => {
    let c = db.classes.get(id).unwrap()
    "\{c.id} \{join_quoted(c.styles)} \{join_quoted(c.text_styles)}"
  }
  inspect(
    show("myClass"),
    content="myClass [\"fill:#f9f\", \"stroke:#333\", \"stroke-width:4px\"] []",
  )
  inspect(
    show("firstClass"),
    content="firstClass [\"color:blue\"] [\"color:blue\"]",
  )
  inspect(
    show("secondClass"),
    content="secondClass [\"color:blue\"] [\"color:blue\"]",
  )
}

///|
test "assigns classes with class statements and the ::: shorthand" {
  let db = parsed(
    "requirementDiagram\n\nrequirement req {\n}\nelement elem {\n}\nclassDef class1,class2 fill:#f9f,stroke:#333,stroke-width:4px\nclass req,elem class1,class2\nreq:::class3\nelem:::class4,class5\n",
  )
  inspect(
    join_quoted(db.requirements.get("req").unwrap().classes),
    content="[\"default\", \"class1\", \"class2\", \"class3\"]",
  )
  inspect(
    join_quoted(db.elements.get("elem").unwrap().classes),
    content="[\"default\", \"class1\", \"class2\", \"class4\", \"class5\"]",
  )
}

///|
test "assigns classes where a requirement or element is defined" {
  let db = parsed(
    "requirementDiagram\n\nrequirement myReq:::class1 {\n}\nelement myElem:::class1,class2 {\n}\n\nclassDef class1 fill:#f9f,stroke:#333,stroke-width:4px\nclassDef class2 color:blue\n",
  )
  let req = db.requirements.get("myReq").unwrap()
  inspect(join_quoted(req.classes), content="[\"default\", \"class1\"]")
  inspect(
    join_quoted(req.css_styles),
    content="[\"fill:#f9f\", \"stroke:#333\", \"stroke-width:4px\"]",
  )
  inspect(
    join_quoted(db.elements.get("myElem").unwrap().classes),
    content="[\"default\", \"class1\", \"class2\"]",
  )
}

///|
test "reads direction statements" {
  let found = ["TB", "BT", "LR", "RL"].map(dir => {
    parsed("requirementDiagram\n\ndirection \{dir}\n").direction
  })
  inspect(join_quoted(found), content="[\"TB\", \"BT\", \"LR\", \"RL\"]")
}

///|
test "reads a left arrow as the relationship written the other way round" {
  let r = parsed("requirementDiagram\na <- satisfies - b\n").relations[0]
  inspect("\{r.src} \{r.kind} \{r.dst}", content="b satisfies a")
}

///|
test "keeps Mermaid quirks: the first of two repeated fields wins, and keywords ignore case" {
  let db = parsed(
    "requirementDiagram\nRequirement a {\nID: first\nid: second\nRISK: HIGH\n}\n",
  )
  let r = db.requirements.get("a").unwrap()
  inspect("\{r.requirement_id} \{r.risk}", content="first High")
}

///|
test "rejects what Mermaid rejects" {
  inspect(
    parse_error("requirementDiagram\nrequirement a {\nid: REQ-1\n}\n"),
    content="Parse error on line 3:\nid: REQ-1\n-------^\nExpecting 'NEWLINE', got 'LINE'",
  )
  inspect(
    parse_error("requirementDiagram\nrequirement a { \n}\n"),
    content="Parse error on line 3:\n}\n^\nExpecting 'NEWLINE', got 'STRUCT_STOP'",
  )
  inspect(
    parse_error(
      "requirementDiagram\nrequirement a {\ntext: test the thing\n}\n",
    ),
    content="Parse error on line 3:\ntext: test the thing\n------^\nExpecting 'qString', 'unqString', got 'VERIFY_TEST'",
  )
  inspect(
    parse_error("requirementDiagram\na - contains - b\n"),
    content="Parse error on line 2:\na - contains - b\n-------------^\nExpecting 'END_ARROW_R', got 'LINE'",
  )
  inspect(
    parse_error("requirementDiagram\nstyle a stroke-width:1.5px\n"),
    content="Lexical error on line 2. Unrecognized text.\nstyle a stroke-width:1.5px\n----------------------^",
  )
  inspect(
    parse_error("requirementDiagram\ntitle My diagram\n"),
    content="Parse error on line 2:\ntitle My diagram\n^\nExpecting 'NEWLINE', 'EOF', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'REQUIREMENT', 'FUNCTIONAL_REQUIREMENT', 'INTERFACE_REQUIREMENT', 'PERFORMANCE_REQUIREMENT', 'PHYSICAL_REQUIREMENT', 'DESIGN_CONSTRAINT', 'ELEMENT', 'CLASSDEF', 'CLASS', 'STYLE', 'unqString', 'qString', got 'title'",
  )
  inspect(
    parse_error("requirement a {\n}\n"),
    content="Parse error on line 1:\nrequirement a {\n^\nExpecting 'RD', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', got 'REQUIREMENT'",
  )
}

///|
test "names what each part of a statement expects" {
  inspect(
    parse_error("requirementDiagram\nrequirement a\n"),
    content="Parse error on line 2:\nrequirement a\n-------------^\nExpecting 'STRUCT_START', 'STYLE_SEPARATOR', got 'NEWLINE'",
  )
  inspect(
    parse_error("requirementDiagram\nelement a {\nid: 1\n}\n"),
    content="Parse error on line 3:\nid: 1\n^\nExpecting 'TYPE', 'DOCREF', 'NEWLINE', 'STRUCT_STOP', got 'ID'",
  )
  inspect(
    parse_error("requirementDiagram\nrequirement a {\ntype: 1\n}\n"),
    content="Parse error on line 3:\ntype: 1\n^\nExpecting 'ID', 'TEXT', 'RISK', 'VERIFYMTHD', 'NEWLINE', 'STRUCT_STOP', got 'TYPE'",
  )
  inspect(
    parse_error("requirementDiagram\nrequirement a {\nrisk: x\n}\n"),
    content="Parse error on line 3:\nrisk: x\n------^\nExpecting 'LOW_RISK', 'MED_RISK', 'HIGH_RISK', got 'unqString'",
  )
  inspect(
    parse_error("requirementDiagram\na b\n"),
    content="Parse error on line 2:\na b\n---^\nExpecting 'STYLE_SEPARATOR', 'END_ARROW_L', 'LINE', got 'NEWLINE'",
  )
  inspect(
    parse_error("requirementDiagram\nstyle a \"x\"\n"),
    content="Parse error on line 2:\nstyle a \"x\"\n---------^\nExpecting 'ALPHA', 'COLON', 'SEMICOLON', 'MINUS', 'BRKT', got 'qString'",
  )
  inspect(
    parse_error("requirementDiagram\nclass ,\n"),
    content="Parse error on line 2:\nclass ,\n------^\nExpecting 'qString', 'unqString', 'ALPHA', got 'COMMA'",
  )
}

///|
/// What reading a text gives, written as the generator of the hashes below writes pele's outcome.
fn dump_model(src : String) -> String {
  let db = @requirement.RequirementDb::new()
  @requirement.parse_requirement(src, db) catch {
    @errors.PeleError(failure) => return "E:" + failure.message
  }
  let out = [
    db.direction,
    db.acc_title.unwrap_or("-"),
    db.acc_descr.unwrap_or("-"),
  ]
  for _, r in db.requirements {
    out.push(
      [
        "R",
        r.name,
        r.kind,
        r.requirement_id,
        r.text,
        r.risk,
        r.verify_method,
        r.css_styles.join(";"),
        r.classes.join(" "),
      ].join("\u{3}"),
    )
  }
  for _, e in db.elements {
    out.push(
      [
        "L",
        e.name,
        e.kind,
        e.doc_ref,
        e.css_styles.join(";"),
        e.classes.join(" "),
      ].join("\u{3}"),
    )
  }
  for r in db.relations {
    out.push(["X", r.kind, r.src, r.dst].join("\u{3}"))
  }
  for _, c in db.classes {
    out.push(
      ["C", c.id, c.styles.join(";"), c.text_styles.join(";")].join("\u{3}"),
    )
  }
  out.join("\u{1}")
}

///|
fn model_hashes(pieces : Array[String]) -> Array[String] {
  Array::makei(5, length => {
    let outputs = strings_over(pieces, length).map(s => {
      dump_model("requirementDiagram\n" + s)
    })
    fnv1a(outputs.join("\u{2}"))
  })
}

///|
test "models and errors match pele for every string of up to four tokens" {
  let pieces = [
    "\n", " ", "requirement", "element", "a", "{", "}", ":", "id", "high", "-", "->",
    "contains", ":::", ",", "style", "class", "c:d", "accTitle:t",
  ]
  inspect(
    join_quoted(model_hashes(pieces)),
    content="[\"9509bb37\", \"9fbab1d6\", \"4a023b57\", \"ae482a36\", \"9e7b3438\"]",
  )
}

///|
test "models and errors match pele for every text of up to four statements" {
  let pieces = [
    "requirement a {\n", "element a {\n", "element b:::c {\n", "id: 1\n", "risk: low\n",
    "text: \"x\"\n", "type: t\n", "docRef: d\n", "}\n", "a - contains -> b\n", "b <- traces - a\n",
    "style a fill:red\n", "classDef c color:blue\n", "class a,b c\n", "a:::c\n",
    "direction LR\n", "accDescr: d\n", "\n",
  ]
  inspect(
    join_quoted(model_hashes(pieces)),
    content="[\"9509bb37\", \"765d722f\", \"2c35ab08\", \"432bbeaf\", \"6a49424f\"]",
  )
}
