// Mermaid's er parser specs are run through `spec_cases`; the other expectations were taken from pele's parseEr.

///|
fn q(text : String) -> String {
  let escaped = text
    .replace_all(old="\\", new="\\\\")
    .replace_all(old="\"", new="\\\"")
    .replace_all(old="\n", new="\\n")
    .replace_all(old="\r", new="\\r")
  "\"\{escaped}\""
}

///|
fn quoted(items : Array[String]) -> String {
  "[" + items.map(q).join(",") + "]"
}

///|
/// The model as text, written as the dump of pele's model that `spec_cases` holds.
fn dump(db : @er.ErDb) -> String {
  let lines = ["dir \{q(db.direction)}"]
  if db.title is Some(title) {
    lines.push("title \{q(title)}")
  }
  if db.acc_title is Some(text) {
    lines.push("accTitle \{q(text)}")
  }
  if db.acc_descr is Some(text) {
    lines.push("accDescr \{q(text)}")
  }
  for name, e in db.entities {
    lines.push(
      "entity \{q(name)} id=\{q(e.id)} label=\{q(e.label)} alias=\{q(e.alias_name)} classes=\{q(e.css_classes)} styles=\{quoted(e.css_styles)}",
    )
    for a in e.attributes {
      lines.push(
        "  attr \{q(a.data_type)} \{q(a.name)} keys=\{quoted(a.keys)} comment=\{q(a.comment)}",
      )
    }
  }
  for r in db.relationships {
    let rel_type = match r.rel_spec.rel_type {
      Identifying => "IDENTIFYING"
      NonIdentifying => "NON_IDENTIFYING"
    }
    lines.push(
      "rel \{q(r.entity_a)} \{q(r.role_a)} \{q(r.entity_b)} \{r.rel_spec.card_a.name()} \{rel_type} \{r.rel_spec.card_b.name()}",
    )
  }
  for _, c in db.classes {
    lines.push(
      "class \{q(c.id)} styles=\{quoted(c.styles)} text=\{quoted(c.text_styles)}",
    )
  }
  for s in db.subgraphs {
    let dir = match s.dir {
      Some(dir) => q(dir)
      None => "-"
    }
    lines.push(
      "subgraph \{q(s.id)} title=\{q(s.title)} dir=\{dir} nodes=\{quoted(s.nodes)} classes=\{quoted(s.classes)} styles=\{quoted(s.css_styles)}",
    )
  }
  lines.join("\n")
}

///|
/// What parsing `source` into a fresh model gives: its dump, or the error with its position.
fn outcome(source : String) -> String {
  let db = @er.ErDb::new()
  @er.parse_er(source, db) catch {
    @errors.PeleError(failure) =>
      return "error \{failure.code.to_string()} \{failure.line}:\{failure.column}\n\{failure.message}"
  }
  "ok\n" + dump(db)
}

///|
test "every source of Mermaid's er parser specs reads as pele reads it" {
  let wrong = []
  for case in spec_cases {
    let (source, expected) = case
    let actual = outcome(source)
    if actual != expected {
      wrong.push(
        "\{source.escape()}: \{actual.escape()} instead of \{expected.escape()}",
      )
    }
  }
  inspect(wrong.length(), content="0")
}

///|
test "statements need no separator after a relationship" {
  inspect(
    outcome("erDiagram\nA:::x,y ||--o{ B:::z : \"r\" C[\"c\"]:::k { int x PK }"),
    content=(
      #|ok
      #|dir "TB"
      #|entity "A" id="entity-A-0" label="A" alias="" classes="default x y" styles=[]
      #|entity "B" id="entity-B-1" label="B" alias="" classes="default z" styles=[]
      #|entity "C" id="entity-C-2" label="C" alias="c" classes="default k" styles=[]
      #|  attr "int" "x" keys=["PK"] comment=""
      #|rel "entity-A-0" "r" "entity-B-1" ZERO_OR_MORE IDENTIFYING ONLY_ONE
    ),
  )
}

///|
test "a subgraph lists every statement inside it, keywords and accessible text included" {
  inspect(
    outcome(
      "erDiagram\nsubgraph s [\"a\" b 1]\ndirection LR\naccTitle: t\nclassDef k fill:#f00\nA\nend",
    ),
    content=(
      #|ok
      #|dir "TB"
      #|accTitle "t"
      #|entity "A" id="entity-A-0" label="A" alias="" classes="default" styles=[]
      #|class "k" styles=["fill:#f00"] text=[]
      #|subgraph "s" title="a b 1" dir="LR" nodes=["t","classDef","A"] classes=[] styles=[]
    ),
  )
}

///|
test "an unclosed subgraph expects its end" {
  inspect(
    outcome("erDiagram\nsubgraph s\nA\n"),
    content=(
      #|error syntax 3:2
      #|Parse error on line 3:
      #|A
      #|-^
      #|Expecting 'END', 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got '$end'
    ),
  )
}

///|
test "an unnamed character is quoted as itself and a bad style character is a lexical error" {
  inspect(
    outcome("erDiagram\nA \"x"),
    content=(
      #|error syntax 2:3
      #|Parse error on line 2:
      #|A "x
      #|--^
      #|Expecting 'EOF', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'SUBGRAPH', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'CLASSDEF', 'CLASS', 'STYLE', 'UNICODE_TEXT', 'NUM', 'ENTITY_NAME', 'DECIMAL_NUM', 'ENTITY_ONE', got '"'
    ),
  )
  inspect(
    outcome("erDiagram\nstyle A fill:red!"),
    content=(
      #|error syntax 2:17
      #|Lexical error on line 2. Unrecognized text.
      #|style A fill:red!
      #|----------------^
    ),
  )
}

///|
test "an attribute block names what it expects" {
  let last_line = (source : String) => {
    let lines = outcome(source).split("\n").to_array()
    lines[lines.length() - 1].to_owned()
  }
  inspect(
    last_line("erDiagram\nA { int x\n"),
    content="Expecting 'ATTRIBUTE_WORD', got '$end'",
  )
  inspect(
    last_line("erDiagram\nA { int? }"),
    content="Expecting 'ATTRIBUTE_WORD', got 'BLOCK_STOP'",
  )
  inspect(
    last_line("erDiagram\nA { int x PK, }"),
    content="Expecting 'ATTRIBUTE_KEY', got 'BLOCK_STOP'",
  )
  inspect(
    last_line("erDiagram\nA ||--|| B"),
    content="Expecting 'COLON', got 'EOF'",
  )
}
