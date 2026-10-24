// Ported from Mermaid's requirementDb.spec.ts, as pele v1.8.0 runs it in tests/compat/requirement, and from the model's own rules.

///|
fn quoted(texts : Array[String]) -> String {
  "[" + texts.map(text => text.escape()).join(", ") + "]"
}

///|
fn optional(text : String?) -> String {
  match text {
    Some(text) => text.escape()
    None => "-"
  }
}

///|
fn styles_of(db : @requirement.RequirementDb, id : String) -> String {
  match db.requirements.get(id) {
    Some(requirement) => requirement.css_styles.join("|")
    None =>
      match db.elements.get(id) {
        Some(element) => element.css_styles.join("|")
        None => "missing"
      }
  }
}

///|
fn classes_of(db : @requirement.RequirementDb, id : String) -> String {
  match db.requirements.get(id) {
    Some(requirement) => requirement.classes.join(" ")
    None =>
      match db.elements.get(id) {
        Some(element) => element.classes.join(" ")
        None => "missing"
      }
  }
}

///|
test "adds a requirement with the fields read before it" {
  let db = @requirement.RequirementDb::new()
  db.set_new_req_id("1")
  db.set_new_req_text("the text")
  db.set_new_req_risk("High")
  db.set_new_req_verify_method("Test")
  db.add_requirement("r", "Requirement")
  db.add_requirement("plain", "Design Constraint")
  let r = db.requirements.get("r").unwrap()
  inspect(
    "\{r.name} \{r.kind} \{r.requirement_id} \{r.text} \{r.risk} \{r.verify_method} \{quoted(r.classes)}",
    content="r Requirement 1 the text High Test [\"default\"]",
  )
  let plain = db.requirements.get("plain").unwrap()
  inspect(
    quoted([plain.requirement_id, plain.text, plain.risk, plain.verify_method]),
    content="[\"\", \"\", \"\", \"\"]",
  )
}

///|
test "adds an element with the fields read before it" {
  let db = @requirement.RequirementDb::new()
  db.set_new_element_type("simulation")
  db.set_new_element_doc_ref("reqs/e")
  db.add_element("e")
  db.add_element("bare")
  let e = db.elements.get("e").unwrap()
  inspect(
    "\{e.name} \{e.kind} \{e.doc_ref} \{quoted(e.classes)}",
    content="e simulation reqs/e [\"default\"]",
  )
  let bare = db.elements.get("bare").unwrap()
  inspect(quoted([bare.kind, bare.doc_ref]), content="[\"\", \"\"]")
}

///|
test "keeps the first of two requirements or elements of one name" {
  let db = @requirement.RequirementDb::new()
  db.set_new_req_id("first")
  db.add_requirement("r", "Requirement")
  db.set_new_req_id("second")
  db.add_requirement("r", "Design Constraint")
  db.set_new_element_type("first")
  db.add_element("e")
  db.set_new_element_type("second")
  db.add_element("e")
  db.add_requirement("plain", "Requirement")
  let r = db.requirements.get("r").unwrap()
  inspect("\{r.kind} \{r.requirement_id}", content="Requirement first")
  inspect(db.elements.get("e").unwrap().kind, content="first")
  inspect(db.requirements.get("plain").unwrap().requirement_id, content="")
}

///|
test "adds a relationship" {
  let db = @requirement.RequirementDb::new()
  db.add_relationship("contains", "src", "dst")
  inspect(
    quoted(db.relations.map(r => "\{r.src} \{r.kind} \{r.dst}")),
    content="[\"src contains dst\"]",
  )
}

///|
test "defines one class or many" {
  let db = @requirement.RequirementDb::new()
  db.define_class(["a"], ["stroke-width: 8px"])
  db.define_class(["b", "c"], ["stroke-width: 8px"])
  inspect(quoted(db.classes.keys().collect()), content="[\"a\", \"b\", \"c\"]")
  let c = db.classes.get("c").unwrap()
  inspect(
    "\{c.id} \{quoted(c.styles)} \{quoted(c.text_styles)}",
    content="c [\"stroke-width: 8px\"] []",
  )
}

///|
test "keeps text declarations of a class apart with fill read as the background" {
  let db = @requirement.RequirementDb::new()
  db.define_class(["c"], ["color:red", "fill:blue", "fill-color:fill"])
  inspect(
    quoted(db.classes.get("c").unwrap().text_styles),
    content="[\"color:red\", \"bgFill-color:fill\"]",
  )
}

///|
test "sets the direction" {
  let db = @requirement.RequirementDb::new()
  inspect(db.direction, content="TB")
  db.set_direction("LR")
  inspect(db.direction, content="LR")
}

///|
test "styles requirements and elements" {
  let db = @requirement.RequirementDb::new()
  db.add_requirement("requirement", "Requirement")
  db.set_css_style(["requirement"], ["color:red"])
  db.add_element("element")
  db.set_css_style(["element"], ["stroke-width:4px", "stroke: yellow"])
  inspect(styles_of(db, "requirement"), content="color:red")
  inspect(styles_of(db, "element"), content="stroke-width:4px|stroke: yellow")
}

///|
test "splits a declaration that holds commas" {
  let db = @requirement.RequirementDb::new()
  db.add_element("e")
  db.set_css_style(["e"], ["fill:red,stroke:blue", "color:x"])
  inspect(styles_of(db, "e"), content="fill:red|stroke:blue|color:x")
}

///|
test "stops styling at the first name that is not defined" {
  let db = @requirement.RequirementDb::new()
  db.add_element("a")
  db.add_element("b")
  db.set_css_style(["a", "missing", "b"], ["fill:red"])
  inspect(styles_of(db, "a"), content="fill:red")
  inspect(styles_of(db, "b"), content="")
}

///|
test "gives requirements and elements classes" {
  let db = @requirement.RequirementDb::new()
  db.add_requirement("requirement", "Requirement")
  db.add_element("element")
  db.set_class(["requirement", "missing", "element"], ["myClass"])
  inspect(classes_of(db, "requirement"), content="default myClass")
  inspect(classes_of(db, "element"), content="default myClass")
}

///|
test "styles requirements and elements with the declarations of their classes" {
  let db = @requirement.RequirementDb::new()
  db.add_requirement("requirement", "Requirement")
  db.add_element("element")
  db.define_class(["myClass"], ["color:red"])
  db.define_class(["myClass2"], ["stroke-width:4px", "stroke: yellow"])
  db.set_class(["requirement"], ["myClass"])
  db.set_class(["element"], ["myClass2"])
  inspect(styles_of(db, "requirement"), content="color:red")
  inspect(styles_of(db, "element"), content="stroke-width:4px|stroke: yellow")
}

///|
test "styles the nodes that already have a class when it is defined" {
  let db = @requirement.RequirementDb::new()
  db.add_requirement("r", "Requirement")
  db.add_element("e")
  db.set_class(["r", "e"], ["late"])
  db.define_class(["late"], ["fill:red,stroke:blue"])
  inspect(styles_of(db, "r"), content="fill:red|stroke:blue")
  inspect(styles_of(db, "e"), content="fill:red|stroke:blue")
}

///|
test "a requirement takes the styles of a name shared with an element" {
  let db = @requirement.RequirementDb::new()
  db.add_requirement("x", "Requirement")
  db.add_element("x")
  db.set_css_style(["x"], ["fill:red"])
  inspect(
    quoted(db.requirements.get("x").unwrap().css_styles),
    content="[\"fill:red\"]",
  )
  inspect(quoted(db.elements.get("x").unwrap().css_styles), content="[]")
}

///|
test "refuses to copy class declarations without bound" {
  let db = @requirement.RequirementDb::new()
  db.add_requirement("a", "Requirement")
  db.define_class(["c"], Array::make(2001, "a:b"))
  let result = try {
    for _ in 0..<600 {
      db.set_class(["a"], ["c"])
    }
    "no error"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()} \{optional(failure.kind)}: \{failure.message}"
  }
  inspect(
    result,
    content="limit \"requirement\": Requirement diagram applies too many style declarations.",
  )
}

///|
test "accessible title and description lose leading whitespace" {
  let db = @requirement.RequirementDb::new()
  db.set_acc_title(" \t title ")
  db.set_acc_description("one\n   two\n\n  three\nfour")
  inspect(optional(db.acc_title), content="\"title \"")
  inspect(optional(db.acc_descr), content="\"one\\ntwo\\nthree\\nfour\"")
}
