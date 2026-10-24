///|
fn optional(value : String?) -> String {
  match value {
    Some(text) => text.escape()
    None => "-"
  }
}

///|
fn label_text(label : @wardley.LabelAst?) -> String {
  match label {
    Some(l) => {
      let x = if l.neg_x { "-" } else { "" }
      let y = if l.neg_y { "-" } else { "" }
      " label \{x}\{l.offset_x},\{y}\{l.offset_y}"
    }
    None => ""
  }
}

///|
fn stage_text(stage : @wardley.StageAst) -> String {
  let boundary = match stage.boundary {
    Some(b) => "@\{b}"
    None => ""
  }
  let second = match stage.second_name {
    Some(name) => "/" + name.escape()
    None => ""
  }
  stage.name.escape() + boundary + second
}

///|
/// The syntax tree of `src` in the form the expected outputs were taken from pele in, or the parse error.
fn ast(src : String) -> String {
  let a = @wardley.parse_wardley(src) catch {
    @errors.PeleError(failure) => return failure.message
  }
  let lines = [
    "title=\{optional(a.title)} accTitle=\{optional(a.acc_title)} accDescr=\{optional(a.acc_descr)}",
  ]
  if a.size is Some(size) {
    lines.push("size \{size.width} \{size.height}")
  }
  if a.evolution is Some(stages) {
    lines.push("evolution " + stages.map(stage_text).join(" -> "))
  }
  for x in a.anchors {
    lines.push("anchor \{x.name.escape()} \{x.visibility} \{x.evolution}")
  }
  for c in a.components {
    let strategy = match c.strategy {
      Some(s) => " (\{s})"
      None => ""
    }
    let inertia = if c.inertia { " inertia" } else { "" }
    lines.push(
      "component \{c.name.escape()} \{c.visibility} \{c.evolution}\{label_text(c.label)}\{strategy}\{inertia}",
    )
  }
  for l in a.links {
    let from_port = l.from_port.map(p => " " + p).unwrap_or("")
    let arrow = l.arrow.map(p => " " + p.escape()).unwrap_or("")
    let to_port = l.to_port.map(p => " " + p).unwrap_or("")
    let link_label = l.link_label.map(p => " ;" + p.escape()).unwrap_or("")
    lines.push(
      "link \{l.from.escape()}\{from_port}\{arrow} \{l.to.escape()}\{to_port}\{link_label}",
    )
  }
  for e in a.evolves {
    lines.push("evolve \{e.component.escape()} \{e.target}")
  }
  for p in a.pipelines {
    let parts = p.components.map(c => {
      "\{c.name.escape()} \{c.evolution}\{label_text(c.label)}"
    })
    lines.push("pipeline \{p.parent.escape()} {\{parts.join("; ")}}")
  }
  for n in a.notes {
    lines.push("note \{n.text.escape()} \{n.visibility} \{n.evolution}")
  }
  for n in a.annotations {
    lines.push("annotations \{n.x} \{n.y}")
  }
  for n in a.annotation {
    lines.push("annotation \{n.number} \{n.x} \{n.y} \{n.text.escape()}")
  }
  for n in a.accelerators {
    lines.push("accelerator \{n.name.escape()} \{n.x} \{n.y}")
  }
  for n in a.deaccelerators {
    lines.push("deaccelerator \{n.name.escape()} \{n.x} \{n.y}")
  }
  lines.join("\n")
}

///|
fn check_parsing(cases : Array[(String, String)]) -> Unit raise {
  for case in cases {
    let (src, expected) = case
    assert_eq(ast(src), expected, msg=src)
  }
}

///|
test "the header, title, and accessibility statements" {
  check_parsing([
    ("wardley-beta", "title=- accTitle=- accDescr=-"),
    ("wardley-beta title T\n", "title=\"T\" accTitle=- accDescr=-"),
    (
      "\n\nwardley-beta\naccTitle: A\naccDescr {\n multi\n line\n}\ntitle T\n", "title=\"T\" accTitle=\"A\" accDescr=\"multi\\nline\"",
    ),
    (
      "---\ntitle: x\n---\nwardley-beta\ncomponent A [0.5, 0.5] %% trailing\n", "title=- accTitle=- accDescr=-\ncomponent \"A\" 0.5 0.5",
    ),
    (
      "wardley-beta\r\ncomponent A [0.5, 0.5]\r\nA->B\r\n", "title=- accTitle=- accDescr=-\ncomponent \"A\" 0.5 0.5\nlink \"A\" \"->\" \"B\"",
    ),
  ])
}

///|
test "size and evolution stages with boundaries and second names" {
  check_parsing([
    (
      "wardley-beta\nsize [800, 600]\nevolution \"A b\"@0.25 / c -> B@0.5 -> C_1@0.75 / \"d e\" -> D@1.0\n",
      "title=- accTitle=- accDescr=-\nsize 800 600\nevolution \"A b\"@0.25/\"c\" -> \"B\"@0.5 -> \"C_1\"@0.75/\"d e\" -> \"D\"@1",
    ),
  ])
}

///|
test "components with label offsets, strategies, and inertia" {
  check_parsing([
    (
      "wardley-beta\ncomponent A [0.5, 0.5] label [-10, 5] (build) (inertia)\ncomponent B [0.1, 0.9] inertia\ncomponent \"C d\" [0.3, 0.3] (market)\n",
      "title=- accTitle=- accDescr=-\ncomponent \"A\" 0.5 0.5 label -10,5 (build) inertia\ncomponent \"B\" 0.1 0.9 inertia\ncomponent \"C d\" 0.3 0.3 (market)",
    ),
    (
      "wardley-beta\ncomponent A [0.5, 0.5] label [10, -5] (inertia)\ncomponent _b [0.1, 0.9] (buy) inertia\ncomponent _9 [0.3, 0.3] (outsource)\n",
      "title=- accTitle=- accDescr=-\ncomponent \"A\" 0.5 0.5 label 10,-5 inertia\ncomponent \"_b\" 0.1 0.9 (buy) inertia\ncomponent \"_9\" 0.3 0.3 (outsource)",
    ),
  ])
}

///|
test "pipelines hold components with one coordinate" {
  check_parsing([
    (
      "wardley-beta\ncomponent A [0.5, 0.5]\npipeline A {\n\n  component X [0.2] label [1, -2]\n\n  component \"Y z\" [0.8]\n}\n",
      "title=- accTitle=- accDescr=-\ncomponent \"A\" 0.5 0.5\npipeline \"A\" {\"X\" 0.2 label 1,-2; \"Y z\" 0.8}",
    ),
  ])
}

///|
test "links with arrows, ports, flow labels, and link labels" {
  check_parsing([
    (
      "wardley-beta\nA -> B\nA --> B\nA -.-> B; dashed\n", "title=- accTitle=- accDescr=-\nlink \"A\" \"->\" \"B\"\nlink \"A\" \"-->\" \"B\"\nlink \"A\" \"-.->\" \"B\" ;\"dashed\"",
    ),
    (
      "wardley-beta\nA +> B\nA +< B\nA +<> B\n", "title=- accTitle=- accDescr=-\nlink \"A\" +> \"B\"\nlink \"A\" +< \"B\"\nlink \"A\" +<> \"B\"",
    ),
    (
      "wardley-beta\nA +'text'> B\nA +'t'< B\nA +''<> B; label\n", "title=- accTitle=- accDescr=-\nlink \"A\" \"+'text'>\" \"B\"\nlink \"A\" \"+'t'<\" \"B\"\nlink \"A\" \"+''<>\" \"B\" ;\"label\"",
    ),
    (
      "wardley-beta\n\"A\" \"B\"\n_1 _2\nA > B\nA->B\nfoo-bar->baz\n", "title=- accTitle=- accDescr=-\nlink \"A\" \"B\"\nlink \"_1\" \"_2\"\nlink \"A\" \">\" \"B\"\nlink \"A\" \"->\" \"B\"\nlink \"foo-bar\" \"->\" \"baz\"",
    ),
    (
      "wardley-beta\nA +> B +<; both\nA +< -> B +>\n\"x y\" -.-> 'z'\n", "title=- accTitle=- accDescr=-\nlink \"A\" +> \"B\" +< ;\"both\"\nlink \"A\" +< \"->\" \"B\" +>\nlink \"x y\" \"-.->\" \"z\"",
    ),
    (
      "wardley-beta\n---\nx\n---\nA->B\n", "title=- accTitle=- accDescr=-\nlink \"A\" \"->\" \"B\"",
    ),
  ])
}

///|
test "notes, annotations, evolves, and forces" {
  check_parsing([
    (
      "wardley-beta\nannotations [0.1, 90]\nannotation 1,[0.5, 50] \"one\"\nannotation 0,[1, 0] 'two'\nnote \"n\" [0.2, 0.3]\n",
      "title=- accTitle=- accDescr=-\nnote \"n\" 0.2 0.3\nannotations 0.1 90\nannotation 1 0.5 50 \"one\"\nannotation 0 1 0 \"two\"",
    ),
    (
      "wardley-beta\naccelerator \"Go\" [0.5, 0.5]\ndeaccelerator Slow down [0.1, 0.2]\nevolve A 0.9\nevolve \"B c\" 0.10\n",
      "title=- accTitle=- accDescr=-\nevolve \"A\" 0.9\nevolve \"B c\" 0.1\naccelerator \"Go\" 0.5 0.5\ndeaccelerator \"Slow down\" 0.1 0.2",
    ),
  ])
}

///|
test "statements Mermaid's grammar rejects" {
  check_parsing([
    (
      "wardley-beta\ncomponent market [0.1, 0.2]\n", "Parse error on line 2:\ncomponent market [0.1, 0.2]\n----------^\nExpecting a name but found `market`.",
    ),
    (
      "wardley-beta\ncomponent labelled thing [0.1, 0.2]\n", "Parse error on line 2:\ncomponent labelled thing [0.1, 0.2]\n----------^\nExpecting a name but found `label`.",
    ),
    (
      "wardley-beta\n1 2\n", "Parse error on line 2:\n1 2\n^\nExpecting a statement but found `1`.",
    ),
    (
      "wardley-beta\nA B\n", "Parse error on line 2:\nA B\n---^\nExpecting a name but found `\n`.",
    ),
    (
      "wardley-beta\ncomponent A [1, 2]\n", "Parse error on line 2:\ncomponent A [1, 2]\n-------------^\nExpecting token of type 'WARDLEY_NUMBER' but found `1`.",
    ),
    (
      "wardley-beta\nevolution A / b@0.5 -> B\n", "Parse error on line 2:\nevolution A / b@0.5 -> B\n---------------^\nExpecting token of type 'ARROW' but found `@`.",
    ),
    (
      "wardley-beta\ncomponent A [0.5, 0.5] (inertia) (buy)\n", "Parse error on line 2:\ncomponent A [0.5, 0.5] (inertia) (buy)\n---------------------------------^\nExpecting a line break or the end of input but found `(`.",
    ),
  ])
}
