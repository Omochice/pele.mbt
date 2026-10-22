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
  inspect(
    parsed("ishikawa-beta\n  E\n%% mid\n\n    c\n"),
    content="\"E\"(\"c\")",
  )
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
    content="Parse error on line 2:\n\n^\nExpecting 'SPACELINE', 'SPACELIST', 'TEXT', got 'EOF'",
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
  inspect(model.title, content="Some(T)")
}
