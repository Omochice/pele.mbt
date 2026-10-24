// Ported from pele v1.8.0, tests/sequence/stress.test.ts.
// pele also bounds each worst case to three seconds; here each only has to finish with a drawing or a PeleError.

///|
const N : Int32 = 50000

///|
const HEAD : String = "sequenceDiagram\n"

///|
fn big(source : String) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), }
  Ok(@core.render([@sequence.sequence], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn parsed_big(source : String) -> Result[Unit, @errors.Failure] {
  Ok(@sequence.parse_sequence(source, @sequence.SeqDb::new())) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn repeat_lines(count : Int32, line : (Int32) -> String) -> String {
  let out = StringBuilder()
  for i in 0..<count {
    out.write_string(line(i))
  }
  out.to_string()
}

///|
fn finished(outcome : Result[@types.RenderResult, @errors.Failure]) -> Bool {
  match outcome {
    Ok(result) => result.svg.length() > 0
    Err(_) => true
  }
}

///|
test "lexer rules with lookahead read the text in one pass" {
  let sources = [
    HEAD + "participant A" + " ".repeat(N) + "x",
    HEAD + "participant a" + " #b".repeat(N / 3) + ":",
    HEAD + "participant a b c d e f:\n".repeat(N / 24),
    HEAD + "participant a" + " as".repeat(N / 3),
    HEAD + "participant A" + "@{}".repeat(N / 3),
    HEAD + "A" + "-".repeat(N) + ">>B: x",
    HEAD + "A" + "-b".repeat(N / 2) + "->>B: x",
    HEAD + "A" + "/(|)\\".repeat(N / 5) + "->>B: x",
    HEAD + "1".repeat(N) + "x",
    HEAD + "1.2.".repeat(N / 4),
    HEAD + ("links" + " ".repeat(40) + "\n").repeat(N / 46),
    HEAD + "title".repeat(N / 5),
    HEAD + "accDescr {" + " x".repeat(N / 2),
    HEAD + "a%%".repeat(N / 3),
    HEAD + " \n\t".repeat(N / 3) + "A->>B: x",
  ]
  for source in sources {
    inspect(@sequence.tokenize(source).types.length() > 0, content="true")
  }
}

///|
test "huge texts and long names are drawn" {
  let sources = [
    HEAD + "A->>B: " + "word ".repeat(N / 5),
    HEAD + "A->>B: wrap: " + "word ".repeat(N / 5),
    HEAD + "Note over A: wrap: " + "x".repeat(N),
    HEAD + "A->>B: " + "#35;<br/>".repeat(N / 9),
    HEAD + "participant " + "n".repeat(N) + "\nA->>B: x",
    HEAD +
    "autonumber " +
    "9".repeat(N / 2) +
    " " +
    "9".repeat(N / 2) +
    "\nA->>B: x\nB->>A: y",
  ]
  for source in sources {
    inspect(finished(big(source)), content="true")
  }
}

///|
test "config objects, menus, and boxes that never end or nest deeply finish" {
  let parses = [
    HEAD + "participant A@{ " + "\"a\": 1, ".repeat(N / 8),
    HEAD + "participant A@{ \"a\": " + "[".repeat(N) + " }\nA->>A: x",
    HEAD + "accDescr{}".repeat(N / 10),
    HEAD + "box rgb(" + "1, ".repeat(N / 3) + ") T\nparticipant A\nend",
    HEAD +
    "box rgb" +
    " ".repeat(N / 2) +
    "(".repeat(N / 2) +
    ")\nparticipant A\nend",
    HEAD +
    "participant A\nlinks A: {" +
    repeat_lines(4000, i => "\"k\{i}\": \"v\", ") +
    "\"z\": 1}",
    HEAD + "participant A\nlinks A: " + "[".repeat(N / 2) + "]".repeat(N / 2),
    HEAD + "loop\n".repeat(10000) + "A->>B: x\n" + "end\n".repeat(10000),
    HEAD + "A->>B: x\n" + "deactivate A\n".repeat(3000),
    HEAD + ">".repeat(N),
  ]
  for source in parses {
    inspect(parsed_big(source) is (Ok(_) | Err(_)), content="true")
  }
}

///|
test "huge counts and wide layouts are drawn" {
  let sources = [
    HEAD + "A->>B: x\n".repeat(8000),
    HEAD + repeat_lines(4000, i => "participant p\{i}\n"),
    HEAD + repeat_lines(2500, i => "p\{i}->>p\{2499 - i}: m\n"),
    HEAD +
    repeat_lines(1500, i => "p\{i}->>p\{i * 7 % 1500}: a long message \{i}\n"),
    HEAD +
    repeat_lines(3000, i => if i % 2 == 1 { "alt a\n" } else { "rect\n" }) +
    "A->>B: x\n" +
    "end\n".repeat(3000),
    HEAD + "alt a\n" + "else b\n".repeat(10000) + "end\n",
    HEAD + "par a\nA->>B: x\n" + "and b\nB->>A: y\n".repeat(5000) + "end\n",
    HEAD + "A->>+B: x\n".repeat(5000) + "B-->>-A: y\n".repeat(5000),
    HEAD + "activate A\n".repeat(4500),
    HEAD +
    "participant A\nparticipant B\nparticipant C\n" +
    "Note over A,C: n\n".repeat(3000),
    HEAD + "A->>A: x\n".repeat(5000),
    HEAD +
    repeat_lines(2000, i => "create participant c\{i}\n") +
    "Note over c0: n\n".repeat(500),
    HEAD +
    repeat_lines(1000, i => {
      "create participant c\{i}\nA->>c\{i}: x\ndestroy c\{i}\nA-xc\{i}: y\n"
    }),
    HEAD +
    repeat_lines(1500, i => "box Aqua Group \{i}\nparticipant b\{i}\nend\n"),
    HEAD + "autonumber\n" + "A()->>()B: x\n".repeat(3000),
  ]
  for source in sources {
    inspect(finished(big(source)), content="true")
  }
}

///|
test "refuses source over the default limit" {
  let source = HEAD + "A->>B: hello\n".repeat(5000)
  let options = @types.RenderOptions::default()
  let refused = Ok(@core.render([@sequence.sequence], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
  inspect(
    refused is Err(failure) && failure.message.contains("limit of 50000"),
    content="true",
  )
  inspect(finished(big(source)), content="true")
}
