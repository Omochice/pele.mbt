// Ported from pele v1.8.0, tests/render/usecase.test.ts, for what the snapshots in render_test.mbt do not show.
// The icon resolver test is not ported: a render here takes no icon resolver.

///|
fn count(text : String, needle : String) -> Int32 {
  let mut n = 0
  let mut at = @util.index_of(text, needle)
  while at != -1 {
    n += 1
    at = @util.index_of(text, needle, from=at + needle.length())
  }
  n
}

///|
fn failure_of(source : String) -> String {
  match drawn(source) {
    Ok(_) => "no error"
    Err(failure) =>
      "\{failure.code.to_string()}: \{failure.message} @\{failure.line}:\{failure.column}"
  }
}

///|
test "is detected and typed" {
  let result = drawn("usecase-beta\nactor User\nUser --> Login").unwrap()
  inspect(result.kind, content="usecase")
  inspect(result.mermaid_type, content="usecase")
  inspect(
    result.svg.has_prefix(
      "<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-usecase\"",
    ),
    content="true",
  )
  inspect(
    result.svg.contains("viewBox=\"0 0 \{result.width} \{result.height}\""),
    content="true",
  )
  inspect(result.links.length(), content="0")
}

///|
test "runs left to right unless told otherwise" {
  let chain = "actor A\nA --> B\nB --> C"
  let wide = drawn("usecase-beta\n" + chain).unwrap()
  inspect(wide.width > wide.height, content="true")
  let tall = drawn("usecase-beta\ndirection TB\n" + chain).unwrap()
  inspect(tall.height > tall.width, content="true")
  inspect(
    svg_of("usecase-beta\ndirection TD\n" + chain) == tall.svg,
    content="true",
  )
}

///|
test "breaks a markdown label where the source breaks" {
  let svg = svg_of("usecase-beta\nA(\"`first\nsecond`\")")
  inspect(count(svg, "<tspan"), content="2")
  inspect(svg.contains(">first</tspan>"), content="true")
  inspect(svg.contains(">second</tspan>"), content="true")
}

///|
test "draws nothing but the frame for a diagram with no statements" {
  let result = drawn("usecase-beta").unwrap()
  inspect(result.svg.contains("<g class=\"pele-nodes\"></g>"), content="true")
  inspect(result.width > 0, content="true")
}

///|
test "reports syntax, lexer and semantic errors as Mermaid words them" {
  inspect(
    failure_of("usecase-beta\nactor A actor B"),
    content=(
      #|syntax: Error parsing usecase diagram: Expecting: one of these possible Token sequences:
      #|  1. [NEWLINE]
      #|  2. [EOF]
      #|but found: 'actor' at line 2, column 9 [21,26) @2:9
    ),
  )
  inspect(
    failure_of("usecase-beta\nsystemBoundary S\nA --> B\nend"),
    content=(
      #|syntax: Error parsing usecase diagram: Expecting: one of these possible Token sequences:
      #|  1. [NEWLINE]
      #|  2. [EOF]
      #|but found: '-->' at line 3, column 3 [32,35) @3:3
    ),
  )
  inspect(
    failure_of("usecase-beta\nsystemBoundary S\nA"),
    content="syntax: Error parsing usecase diagram: Expecting token of type --> END <-- but found --> '' <-- at line 4, column 1 [32,32) @4:1",
  )
  inspect(
    failure_of("usecase-beta\nA \"b"),
    content="syntax: Error lexing usecase diagram: unexpected character: ->\"<- at offset: 15, skipped 1 characters. at line 2, column 3 [15,16) @2:3",
  )
  inspect(
    failure_of("usecase-beta\nnote for Ghost \"x\""),
    content="semantic: Note target 'Ghost' is unresolved at line 2, column 10 [22,27) @2:10",
  )
  inspect(
    failure_of("usecase-beta\njson P@{\"a\":}"),
    content="syntax: Invalid JSON: Unexpected token '}', \"{\"a\":}\" is not valid JSON (line 2, column 13) @2:13",
  )
  inspect(
    failure_of("usecase-beta\nactor A\nA --> B\nstyle Z fill:red"),
    content="semantic: Class/style target 'Z' is unresolved or anonymous at line 4, column 7 [35,36) @4:7",
  )
}
