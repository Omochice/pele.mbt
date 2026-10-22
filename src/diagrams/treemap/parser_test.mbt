///|
fn indent_prefix(indent : Int32?) -> String {
  match indent {
    Some(width) => "@\{width} "
    None => ""
  }
}

///|
fn selector_suffix(selector : String?) -> String {
  match selector {
    Some(name) => " :::\{name}"
    None => ""
  }
}

///|
fn describe_row(row : @treemap.RowAst) -> String {
  match row {
    Item(indent, Section(name, selector)) =>
      "\{indent_prefix(indent)}S \{name.escape()}\{selector_suffix(selector)}"
    Item(indent, Leaf(name, value, selector)) =>
      "\{indent_prefix(indent)}L \{name.escape()} \{value}\{selector_suffix(selector)}"
    ClassDef(indent, name, Some(text)) =>
      "\{indent_prefix(indent)}D \{name} \{text.escape()}"
    ClassDef(indent, name, None) => "\{indent_prefix(indent)}D \{name}"
  }
}

///|
/// The rows of a source joined by semicolons, then the title and accessibility statements it has.
fn parse(source : String) -> String {
  let ast = @treemap.parse_treemap(source + "\n") catch {
    @errors.PeleError(failure) => return "error: \{failure.message}"
  }
  let out = StringBuilder()
  out.write_string(ast.rows.map(describe_row).join("; "))
  if ast.title is Some(title) {
    out.write_string(" / title=\{title.escape()}")
  }
  if ast.acc_title is Some(title) {
    out.write_string(" / accTitle=\{title.escape()}")
  }
  if ast.acc_descr is Some(text) {
    out.write_string(" / accDescr=\{text.escape()}")
  }
  out.to_string()
}

///|
test "a treemap with no rows" {
  inspect(parse("treemap"), content="")
  inspect(parse("treemap-beta"), content="")
}

///|
test "a name alone is a section" {
  inspect(parse("treemap\n\"Root\""), content="S \"Root\"")
  inspect(parse("treemap\n'Single'"), content="S \"Single\"")
}

///|
test "a name followed by a colon or a comma and a number is a leaf" {
  inspect(
    parse("treemap\n\"Root\"\n  \"Child1\" , 100\n  \"Child2\" : 200"),
    content="S \"Root\"; @2 L \"Child1\" 100; @2 L \"Child2\" 200",
  )
  inspect(parse("treemap\n\"Item\" : 123.45"), content="L \"Item\" 123.45")
  inspect(parse("treemap\n\"a\", 5"), content="L \"a\" 5")
  inspect(parse("treemap\n\"a\"\t:\t5"), content="L \"a\" 5")
}

///|
test "the whitespace before a row is its indentation" {
  inspect(parse("treemap\n\t\"a\": 5"), content="@1 L \"a\" 5")
  inspect(
    parse("treemap\n\"a\"\n \"b\"\n  \"c\": 1\n \"d\": 2"),
    content="S \"a\"; @1 S \"b\"; @2 L \"c\" 1; @1 L \"d\" 2",
  )
  inspect(
    parse("treemap\n\"a\": 1\r\n  \"b\": 2"),
    content="L \"a\" 1; @2 L \"b\" 2",
  )
}

///|
test "a row may follow another on the same line" {
  inspect(
    parse("treemap\n\"a\": 1 \"b\": 2"),
    content="L \"a\" 1; @1 L \"b\" 2",
  )
}

///|
test "a value is read as parseFloat reads it once its commas are gone" {
  inspect(parse("treemap\n\"a\": 1,000"), content="L \"a\" 1000")
  inspect(parse("treemap\n\"a\": 1_0"), content="L \"a\" 1")
  inspect(parse("treemap\n\"a\": ."), content="L \"a\" NaN")
  inspect(
    parse("treemap\n\"a\": " + "9".repeat(400)),
    content="L \"a\" Infinity",
  )
}

///|
test "comment lines are skipped, and one after a row is not" {
  inspect(parse("treemap\n%% note\n\"a\": 1"), content="L \"a\" 1")
  inspect(parse("treemap\n  %% note\n\"a\": 1"), content="@2 L \"a\" 1")
}

///|
test "title and accessibility statements are kept apart from the rows" {
  inspect(
    parse(
      "treemap\ntitle My Treemap Diagram\naccTitle: Accessible Title\naccDescr: This is an accessible description\n\"Root\"\n  \"Child\": 100",
    ),
    content="S \"Root\"; @2 L \"Child\" 100 / title=\"My Treemap Diagram\" / accTitle=\"Accessible Title\" / accDescr=\"This is an accessible description\"",
  )
  inspect(parse("treemap title Own"), content=" / title=\"Own\"")
  inspect(parse("treemap\n\"a\": 1\ntitle\n"), content="L \"a\" 1 / title=\"\"")
  inspect(
    parse("treemap\naccDescr {\n  line one\n  line two\n}\n\"a\": 1"),
    content="L \"a\" 1 / accDescr=\"line one\\nline two\"",
  )
}
