// The addStyleClass and addDescription specs are ported from Mermaid's stateDb.spec.js, as pele v1.8.0 runs them in tests/compat/state.
// The other expectations were taken from pele's StateDb.

///|
test "add_style_class is added to the list of style classes" {
  let db = @state.StateDb::new()
  db.add_style_class(
    "newStyleClass",
    attributes="font-weight:bold, border:blue;",
  )
  let found = db.classes.get("newStyleClass").unwrap()
  inspect(found.id, content="newStyleClass")
  inspect(
    list(found.styles),
    content=(
      #|["font-weight:bold","border:blue"]
    ),
  )
}

///|
test "add_style_class drops one semicolon from each style and keeps the ones that color text" {
  let db = @state.StateDb::new()
  db.add_style_class(
    "newStyleClass",
    attributes="font-weight:bold, border:blue;",
  )
  db.add_style_class(
    "hot",
    attributes="fill:#f00,color:white;stroke:red;x, background-color:blue",
  )
  db.add_style_class("empty")
  db.add_style_class("hot", attributes="stroke-width:2px")
  inspect(
    model_dump(db),
    content=(
      #|dir "TB"
      #|classDef "newStyleClass" id="newStyleClass" styles=["font-weight:bold","border:blue"] textStyles=[]
      #|classDef "hot" id="hot" styles=["fill:#f00","color:whitestroke:red;x","background-color:blue","stroke-width:2px"] textStyles=["fill:whitestroke:red;x","background-fill:blue"]
      #|classDef "empty" id="empty" styles=[] textStyles=[]
    ),
  )
}

///|
test "add_description removes only the first leading colon" {
  let db = @state.StateDb::new()
  db.add_state("state1")
  db.add_description("state1", "rest of the description")
  db.add_description("state1", ":rest of the description")
  db.add_description("state1", "::rest of the description")
  inspect(
    list(db.states.get("state1").unwrap().descriptions),
    content=(
      #|["rest of the description","rest of the description",":rest of the description"]
    ),
  )
}

///|
test "add_description adds each description to the array of descriptions" {
  let db = @state.StateDb::new()
  db.add_state("state1")
  db.add_description("state1", "description 0")
  db.add_description("state1", "description 1")
  db.add_description("state1", "description 2")
  inspect(
    list(db.states.get("state1").unwrap().descriptions),
    content=(
      #|["description 0","description 1","description 2"]
    ),
  )
}

///|
test "add_description trims after a colon and ignores a state that does not exist" {
  let db = @state.StateDb::new()
  db.add_state("state1")
  db.add_description("state1", "rest")
  db.add_description("state1", ":rest")
  db.add_description("state1", "::rest")
  db.add_description("state1", ":  spaced ")
  db.add_description("missing", "x")
  inspect(
    model_dump(db),
    content=(
      #|dir "TB"
      #|state "state1" id="state1" type="default" descriptions=["rest","rest",":rest","spaced"] classes=[] styles=[] textStyles=[]
    ),
  )
}

///|
test "add_state keeps the first type and document and merges the rest" {
  let db = @state.StateDb::new()
  db.add_state(
    " a ",
    kind="fork",
    description=Lines(["  one ", ":two"]),
    note={ position: "left of", text: "n1", },
    classes=[" c1 ", "c2"],
  )
  db.add_state(
    "a",
    kind="join",
    doc=[],
    description=Text("three"),
    note={ position: "right of", text: "n2", },
    classes=["c3"],
  )
  db.add_state("b", description=Text(""))
  inspect(
    model_dump(db),
    content=(
      #|dir "TB"
      #|state "a" id="a" type="fork" descriptions=["one","two","three"] classes=["c1","c2","c3"] styles=[] textStyles=[] note="right of":"n2" doc=0
      #|state "b" id="b" type="default" descriptions=[] classes=[] styles=[] textStyles=[]
    ),
  )
}

///|
test "add_relation adds its states and the transition between them" {
  let db = @state.StateDb::new()
  db.add_relation(
    @state.StateStmt::new(" x ", kind="default", description=Text("dx"), classes=[
      "k",
    ]),
    @state.StateStmt::new("y", kind="choice", description=Text("")),
  )
  db.add_relation(
    @state.StateStmt::new("x", kind="default"),
    @state.StateStmt::new("z", kind="default"),
    title="go",
  )
  inspect(
    model_dump(db),
    content=(
      #|dir "TB"
      #|state "x" id="x" type="default" descriptions=["dx"] classes=["k"] styles=[] textStyles=[]
      #|state "y" id="y" type="choice" descriptions=[] classes=[] styles=[] textStyles=[]
      #|state "z" id="z" type="default" descriptions=[] classes=[] styles=[] textStyles=[]
      #|rel "x" "y" ""
      #|rel "x" "z" "go"
    ),
  )
}

///|
test "set_css_class names states by a comma-separated list and creates the missing ones" {
  let db = @state.StateDb::new()
  db.add_state("a")
  db.set_css_class("a, b ,,a", "hot")
  db.set_css_class("a", "cool")
  inspect(
    model_dump(db),
    content=(
      #|dir "TB"
      #|state "a" id="a" type="default" descriptions=[] classes=["hot","hot","cool"] styles=[] textStyles=[]
      #|state "b" id="b" type="default" descriptions=[] classes=["hot"] styles=[] textStyles=[]
      #|state "" id="" type="default" descriptions=[] classes=["hot"] styles=[] textStyles=[]
    ),
  )
}

///|
fn plain(id : String) -> @state.StateStmt {
  @state.StateStmt::new(id, kind="default", description=Text(""))
}

///|
fn divider(db : @state.StateDb, doc? : Array[@state.Stmt]) -> @state.Stmt {
  State(@state.StateStmt::new(db.get_divider_id(), kind="divider", doc?))
}

///|
test "set_root_doc names start and end states, splits regions and collects the root document" {
  let db = @state.StateDb::new()
  let inner : Array[@state.Stmt] = [
    Relation(plain("[*]"), plain("x"), None),
    divider(db),
    State(plain("y")),
    State(plain("[*]")),
    divider(db),
    State(
      @state.StateStmt::new("z", kind="default", description=Text(""), doc=[
        divider(db),
      ]),
    ),
  ]
  db.set_root_doc([
    Relation(plain("[*]"), plain(" A "), None),
    State(
      @state.StateStmt::new(
        "A",
        kind="default",
        description=Text(""),
        doc=inner,
      ),
    ),
    State(
      @state.StateStmt::new("B", kind="default", doc=[
        State(@state.StateStmt::new("w", kind="default")),
        divider(db),
      ]),
    ),
    Relation(plain("A"), plain("[*]"), None),
    Dir({ value: "LR", }),
    ClassDef(" hot ", "fill:red"),
    Style(" A,q ", "fill:red;;, stroke : blue ;"),
    ApplyClass(" A ", "hot"),
    Click(@state.StateStmt::new("A"), "\"u\"", "\"t\""),
    Other("hide empty description"),
    Dir({ value: "BT", }),
  ])
  inspect(
    model_dump(db),
    content=(
      #|dir "BT"
      #|relation descr=-
      #|  state "root_start" type="default" descr="" start=true
      #|  state "A" type="default" descr=""
      #|state "A" type="default" descr="" {
      #|  state "divider-id-1" type="divider" descr=- {
      #|    relation descr=-
      #|      state "divider-id-1_start" type="default" descr="" start=true
      #|      state "x" type="default" descr=""
      #|  }
      #|  state "divider-id-2" type="divider" descr=- {
      #|    state "y" type="default" descr=""
      #|    state "divider-id-2_start" type="default" descr="" start=true
      #|  }
      #|  state "divider-id-5" type="divider" descr=- {
      #|    state "z" type="default" descr="" {
      #|      state "divider-id-3" type="divider" descr=- {
      #|      }
      #|    }
      #|  }
      #|}
      #|state "B" type="default" descr=- {
      #|  state "divider-id-4" type="divider" descr=- {
      #|    state "w" type="default" descr=-
      #|  }
      #|}
      #|relation descr=-
      #|  state "A" type="default" descr=""
      #|  state "root_end" type="default" descr="" start=false
      #|dir "LR"
      #|classDef " hot " "fill:red"
      #|style " A,q " "fill:red;;, stroke : blue ;"
      #|class " A " "hot"
      #|click "A" "\"u\"" "\"t\""
      #|text "hide empty description"
      #|dir "BT"
      #|state "root_start" id="root_start" type="default" descriptions=[] classes=[] styles=[] textStyles=[]
      #|state "A" id="A" type="default" descriptions=[] classes=["hot"] styles=["fill:red","stroke : blue"] textStyles=[] doc=3
      #|state "B" id="B" type="default" descriptions=[] classes=[] styles=[] textStyles=[] doc=1
      #|state "root_end" id="root_end" type="default" descriptions=[] classes=[] styles=[] textStyles=[]
      #|state "q" id="q" type="default" descriptions=[] classes=[] styles=["fill:red","stroke : blue"] textStyles=[]
      #|rel "root_start" "A" ""
      #|rel "A" "root_end" ""
      #|classDef "hot" id="hot" styles=["fill:red"] textStyles=[]
      #|link "A" "\"u\"" "\"t\""
    ),
  )
}

///|
test "set_direction rewrites the direction statement and the accessibility setters drop indentation" {
  let db = @state.StateDb::new()
  db.set_direction("LR")
  db.set_direction("RL")
  db.set_acc_title("  \t title ")
  db.set_acc_description("a\n   b\n\n  c \n")
  inspect(
    model_dump(db),
    content=(
      #|dir "RL"
      #|accTitle "title "
      #|accDescr "a\nb\nc \n"
      #|dir "RL"
    ),
  )
  inspect(db.trim_colon(": x "), content="x")
  inspect(db.trim_colon(" :x "), content=":x")
}
