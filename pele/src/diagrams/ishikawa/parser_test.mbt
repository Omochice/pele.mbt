///|
fn outline(node : @ishikawa.IshikawaNode) -> String {
  if node.children.length() == 0 {
    return node.text.escape()
  }
  "\{node.text.escape()}(\{node.children.map(outline).join(" ")})"
}

///|
fn parsed(src : String) -> String {
  let model = @ishikawa.parse_ishikawa(src + "\n") catch {
    @errors.PeleError(failure) => return failure.message
  }
  match model.root {
    Some(root) => outline(root)
    None => "no effect"
  }
}

///|
test "causes nest by their indentation" {
  inspect(
    parsed("ishikawa-beta\n  Effect\n    Cause\n      Sub\n"),
    content="\"Effect\"(\"Cause\"(\"Sub\"))",
  )
  inspect(
    parsed(
      "ishikawa-beta\n    Blurry Photo\n        Process\n            Out of focus\n        User\n            Shaky hands\n",
    ),
    content="\"Blurry Photo\"(\"Process\"(\"Out of focus\") \"User\"(\"Shaky hands\"))",
  )
}

///|
test "nesting is relative to the first cause, so the effect may be indented more" {
  inspect(
    parsed("ishikawa-beta\n        Problem\n  A\n      A1\n    A2\n  B\n C\n"),
    content="\"Problem\"(\"A\"(\"A1\" \"A2\") \"B\" \"C\")",
  )
  inspect(
    parsed("ishikawa-beta\nProblem\nCause A\n  Subcause A1\nCause B\n"),
    content="\"Problem\"(\"Cause A\"(\"Subcause A1\") \"Cause B\")",
  )
  inspect(
    parsed("ishikawa-beta\n    Problem\nCause A\n  Subcause A1\nCause B\n"),
    content="\"Problem\"(\"Cause A\"(\"Subcause A1\") \"Cause B\")",
  )
}

///|
test "a cause indented less than the first cause is still a category" {
  inspect(
    parsed("ishikawa-beta\n  E\n      a\n    b\n  c\n"),
    content="\"E\"(\"a\" \"b\" \"c\")",
  )
}

///|
test "text is trimmed and a comment is part of its line" {
  inspect(
    parsed("ishikawa-beta\n  E\n    c %% x\n"),
    content="\"E\"(\"c %% x\")",
  )
  inspect(
    parsed("ishikawa-beta\n  E\n  \t\n x %% c"),
    content="\"E\"(\"x %% c\")",
  )
  inspect(parsed("ishikawa-beta\n  E\r\n    c\r\n"), content="\"E\"(\"c\")")
}

///|
test "comment lines and blank lines are skipped" {
  inspect(parsed("ishikawa-beta\n  E\n\n    c\n"), content="\"E\"(\"c\")")
  inspect(parsed("%% x\nishikawa-beta x"), content="\"x\"")
  inspect(parsed("\n\nishikawa-beta\n E\n"), content="\"E\"")
}

///|
test "the keyword may end the text or be followed by text on its line" {
  inspect(parsed("ishikawa-beta\n"), content="no effect")
  inspect(parsed("ishikawa-beta E"), content="\"E\"")
  inspect(parsed("ishikawa extra\n E"), content="\"extra\"(\"E\")")
}

///|
test "the keyword takes the longest form that ends at a word boundary" {
  inspect(parsed("ishikawa-betax\n E"), content="\"-betax\"(\"E\")")
  inspect(parsed("ishikawa-bet\n E"), content="\"-bet\"(\"E\")")
}

///|
test "what Mermaid rejects is rejected with its message" {
  inspect(
    parsed("ishikawa-beta"),
    content="Parse error on line 1:\nishikawa-beta\n-------------^\nExpecting 'SPACELINE', 'SPACELIST', 'TEXT', got 'EOF'",
  )
  inspect(
    parsed("ishikawa-beta\n\n  Effect\n"),
    content="Parse error on line 3:\n  Effect\n^\nExpecting 'SPACELINE', 'NL', 'EOF', got 'SPACELIST'",
  )
  inspect(
    parsed("ishikawa-beta\n  Effect\n  ishikawa again\n"),
    content="Parse error on line 3:\n  ishikawa again\n--^\nExpecting 'SPACELINE', 'NL', 'EOF', 'TEXT', got 'ISHIKAWA'",
  )
}

///|
test "the front matter title is kept" {
  let model = @ishikawa.parse_ishikawa("ishikawa-beta\n E\n", title="T")
  inspect(model.title.unwrap_or("-"), content="T")
}

///|
test "an outline 3000 levels deep is read without recursion" {
  let src = StringBuilder()
  src.write_string("ishikawa-beta\n")
  for i in 0..<3000 {
    src.write_string("\{" ".repeat(i + 1)}n\n")
  }
  let model = @ishikawa.parse_ishikawa(src.to_string() + "\n")
  let mut depth = 0
  let mut node = model.root
  while node is Some(n) {
    depth += 1
    node = n.children.get(0)
  }
  inspect(depth, content="3000")
}

///|
test "long runs of white space and line breaks are read" {
  let head = "ishikawa-beta\n"
  for
    body in [
      " ".repeat(50000),
      "\n".repeat(50000),
      " \n".repeat(25000),
      (" ".repeat(999) + "x\n").repeat(50),
      "x\n" + " ".repeat(50000),
      " \t\r  \n".repeat(8000) + "%",
    ] {
    ignore(
      @ishikawa.parse_ishikawa(head + body) catch {
        _ => @ishikawa.IshikawaModel::{ title: None, root: None, }
      },
    )
  }
}
