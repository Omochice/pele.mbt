///|
fn show(node : @kanban.KanbanNode, indent : String) -> String {
  let fields = [
    ("icon", node.icon),
    ("assigned", node.assigned),
    ("ticket", node.ticket),
    ("priority", node.priority),
    ("class", node.css_classes),
  ]
  let mut line = "\{indent}\{node.id}@\{node.level} \{node.label.escape()}"
  for field in fields {
    if field.1 is Some(value) {
      line += " \{field.0}=\{value.escape()}"
    }
  }
  line
}

///|
fn model(source : String) -> String {
  let built = @kanban.parse_kanban(source + "\n", Some("front")) catch {
    @errors.PeleError(failure) =>
      return "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")}"
  }
  let lines = ["title=\{built.title.unwrap_or("-")}"]
  for section in built.sections {
    lines.push(show(section, ""))
    for item in section.items {
      lines.push(show(item, "  "))
    }
  }
  lines.join("\n")
}

///|
test "a root line is a column" {
  inspect(model("kanban\n    root"), content="title=front\nroot@4 \"root\"")
}

///|
test "a shaped root line without an id is a column" {
  inspect(model("kanban\n    (root)"), content="title=front\nroot@4 \"root\"")
}

///|
test "every deeper line is a card of the last column" {
  inspect(
    model(
      "kanban\n  root\n    child1\n      leaf1\n    child2\n  second\n      deep",
    ),
    content=(
      #|title=front
      #|root@2 "root"
      #|  child1@4 "child1"
      #|  leaf1@6 "leaf1"
      #|  child2@4 "child2"
      #|second@2 "second"
      #|  deep@6 "deep"
    ),
  )
}

///|
test "a line indented less than the first column is a card, and a line after it is rejected" {
  inspect(
    model("kanban\n    a\n  shallow"),
    content="title=front\na@4 \"a\"\n  shallow@2 \"shallow\"",
  )
  inspect(
    model("kanban\n    a\n  shallow\n    b"),
    content="semantic: Items without section detected, found section (\"shallow\") kanban",
  )
}

///|
test "metadata is read from one line" {
  inspect(
    model(
      "kanban\n  todo\n    a[Task]@{ ticket: MC-2037, assigned: 'knsv', priority: 'High', icon: star }",
    ),
    content=(
      #|title=front
      #|todo@2 "todo"
      #|  a@4 "Task" icon="star" assigned="knsv" ticket="MC-2037" priority="High"
    ),
  )
}

///|
test "metadata is read from several lines" {
  inspect(
    model(
      "kanban\n  todo\n    a@{\n      assigned: knsv\n      label: \"A new\n        label\"\n      ticket: 12\n    }",
    ),
    content=(
      #|title=front
      #|todo@2 "todo"
      #|  a@4 "A new<br/>label" assigned="knsv" ticket="12"
    ),
  )
}

///|
test "metadata that is invalid YAML is a syntax error" {
  inspect(
    model("kanban\n  todo\n    a@{ a: [ }"),
    content="syntax: Metadata of \"a\" is not valid YAML. YAML: unexpected end of the stream within a flow collection kanban",
  )
  inspect(
    model("kanban\n  todo\n    a@{ label: \"x }"),
    content="syntax: Parse error on line 3:\n    a@{ label: \"x }\n-------------------^\nExpecting 'SPACELINE', 'NL', 'EOF', 'SHAPE_DATA', got '1' kanban",
  )
}

///|
test "metadata that is not a mapping is ignored" {
  inspect(
    model("kanban\n  todo\n    a@{\n}"),
    content="title=front\ntodo@2 \"todo\"\n  a@4 \"a\"",
  )
  inspect(
    model("kanban\n  todo\n    a@{\n - x\n}"),
    content="title=front\ntodo@2 \"todo\"\n  a@4 \"a\"",
  )
  inspect(
    model("kanban\n  todo\n    a@{}"),
    content="title=front\ntodo@2 \"todo\"\n  a@4 \"a\"",
  )
}

///|
test "a shape name must be lowercase and free of underscores" {
  inspect(
    model("kanban\n  todo\n    a@{ shape: Rect }"),
    content="semantic: No such shape: Rect. Shape names should be lowercase. kanban",
  )
  inspect(
    model("kanban\n  todo\n    a@{ shape: kanban_item }"),
    content="semantic: No such shape: kanban_item. Shape names should be lowercase. kanban",
  )
  inspect(
    model("kanban\n  todo\n    a@{ shape: rect }"),
    content="title=front\ntodo@2 \"todo\"\n  a@4 \"a\"",
  )
}

///|
test "classes and icons decorate the node before them" {
  inspect(
    model(
      "kanban\n  todo[To do]\n  :::wide\n  ::icon(inbox)\n    a[Task]@{ icon: star }\n    :::urgent large",
    ),
    content=(
      #|title=front
      #|todo@2 "To do" icon="inbox" class="wide"
      #|  a@4 "Task" icon="star" class="urgent large"
    ),
  )
}

///|
test "a decoration before any node is ignored" {
  inspect(
    model("kanban\n::icon(star)\n:::big\ntodo"),
    content="title=front\ntodo@0 \"todo\"",
  )
}

///|
test "a board with no columns is empty" {
  inspect(model("kanban\n"), content="title=front")
}
