///|
fn optional(value : String?) -> String {
  match value {
    Some(text) => text.escape()
    None => "-"
  }
}

///|
fn ast(source : String) -> String {
  let ast = @pie.parse_pie(source + "\n") catch {
    @errors.PeleError(failure) => return "\{failure.message}"
  }
  let sections = ast.sections.map(s => "\{s.label.escape()}:\{s.value}")
  "title=\{optional(ast.title)} accTitle=\{optional(ast.acc_title)} accDescr=\{optional(ast.acc_descr)} showData=\{ast.show_data} sections=\{sections.join(",")}"
}

///|
test "a bare pie has no sections" {
  inspect(
    ast("pie"),
    content="title=- accTitle=- accDescr=- showData=false sections=",
  )
  inspect(
    ast("pie title"),
    content="title=\"\" accTitle=- accDescr=- showData=false sections=",
  )
}

///|
test "showData, a title, and sections are read" {
  inspect(
    ast("pie showData title T\n\"a\":1\n\"b\":2.5"),
    content="title=\"T\" accTitle=- accDescr=- showData=true sections=\"a\":1,\"b\":2.5",
  )
  inspect(
    ast("pie\n'b' : 3\n"),
    content="title=- accTitle=- accDescr=- showData=false sections=\"b\":3",
  )
}

///|
test "accessibility statements are read" {
  inspect(
    ast("pie\n accTitle: at\n accDescr { multi\n line }\n title t\n \"a\" : 1"),
    content="title=\"t\" accTitle=\"at\" accDescr=\"multi\\nline\" showData=false sections=\"a\":1",
  )
  inspect(
    ast("pie\naccDescr: hi %% c\n\"a\":1"),
    content="title=- accTitle=- accDescr=\"hi\" showData=false sections=\"a\":1",
  )
}

///|
test "runs of blanks in a title become one space" {
  inspect(
    ast("pie title  a   b  \n\"x\": 3"),
    content="title=\"a b\" accTitle=- accDescr=- showData=false sections=\"x\":3",
  )
}

///|
test "front matter, directives, and comments are skipped" {
  inspect(
    ast("---\ntitle: x\n---\npie\n\"a\":1"),
    content="title=- accTitle=- accDescr=- showData=false sections=\"a\":1",
  )
  inspect(
    ast("%%{init: {\"theme\":\"dark\"}}%%\npie title A %% c\n\"a\":1 %% d\n"),
    content="title=\"A\" accTitle=- accDescr=- showData=false sections=\"a\":1",
  )
}

///|
test "unknown text is a lexical error" {
  inspect(
    ast("pie\n\"a\" : 1."),
    content="Lexical error on line 2. Unrecognized text.\n\"a\" : 1.\n------^",
  )
  inspect(
    ast("pie\n\"a\" : .5"),
    content="Lexical error on line 2. Unrecognized text.\n\"a\" : .5\n------^",
  )
  inspect(
    ast("pie x"),
    content="Lexical error on line 1. Unrecognized text.\npie x\n----^",
  )
  inspect(
    ast("piex"),
    content="Lexical error on line 1. Unrecognized text.\npiex\n^",
  )
  inspect(
    ast("pie\n\"a\":1.5.5"),
    content="Lexical error on line 2. Unrecognized text.\n\"a\":1.5.5\n----^",
  )
}

///|
test "misplaced tokens are parse errors" {
  inspect(
    ast("pie\n\"a\\\"b\" : 01"),
    content="Parse error on line 2:\n\"a\\\"b\" : 01\n----------^\nExpecting a line break or the end of input but found `1`.",
  )
  inspect(
    ast("pie\n\"a\" 1"),
    content="Parse error on line 2:\n\"a\" 1\n----^\nExpecting token of type ':' but found `1`.",
  )
  inspect(
    ast("pie\n\"a\": 1 \"b\": 2"),
    content="Parse error on line 2:\n\"a\": 1 \"b\": 2\n-------^\nExpecting a line break or the end of input but found `\"b\"`.",
  )
  inspect(
    ast("pie\n\"a\":-01"),
    content="Parse error on line 2:\n\"a\":-01\n------^\nExpecting a line break or the end of input but found `1`.",
  )
}
