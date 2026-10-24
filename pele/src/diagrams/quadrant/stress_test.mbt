///|
const HEAD : String = "quadrantChart\n"

///|
fn big(
  source : String,
  options~ : @types.RenderOptions = @types.RenderOptions::default(),
) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..options, limit: Some(1.0 / 0.0), }
  Ok(@core.render([@quadrant.quadrant], source, options)) catch {
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
/// Reads the text and lets only a `PeleError` through.
fn lexes(source : String) -> Unit {
  @quadrant.parse_quadrant(source, @quadrant.QuadrantDb::new(None)) catch {
    @errors.PeleError(_) => ()
  }
}

///|
test "inputs that make a naive lexer rescan the text are read in one pass" {
  let n = 50000
  lexes(HEAD + " ".repeat(n) + "!")
  lexes(HEAD + "A" + "\t".repeat(n) + ":x")
  lexes(HEAD + ("\t".repeat(500) + ":").repeat(100))
  lexes(HEAD + ": ".repeat(n / 2))
  lexes(HEAD + "x-axis a " + "-".repeat(n))
  lexes(HEAD + "x-axis a" + ("  " + "-".repeat(50)).repeat(1000))
  lexes("quadrantChart" + "\n%% c".repeat(n / 5))
  lexes(HEAD + "a%%".repeat(n / 3))
  lexes(HEAD + ("accTitle" + " ".repeat(40)).repeat(1000))
  lexes(HEAD + "A: [0." + "5".repeat(n) + ", 1]")
  lexes(HEAD + "A: [0" + " ".repeat(n) + "1]")
}

///|
test "styles of long runs of spaces are read in one pass" {
  for
    styles in [
      ["radius" + " ".repeat(50000) + ":" + " ".repeat(50000) + "5"],
      ["a" + " ".repeat(50000) + "b"],
    ] {
    ignore(@quadrant.parse_styles(styles)) catch {
      @errors.PeleError(_) => ()
    }
  }
}

///|
test "inputs that make a chart slow to read or to draw finish" {
  let n = 50000
  let cases = [
    HEAD + "accDescr {" + " a\n".repeat(n / 3),
    HEAD + "quadrant-1 \"" + "a".repeat(n),
    HEAD + "quadrant-1 \"`" + "a ".repeat(n / 2),
    HEAD +
    "A:::c: [0.5, 0.5]\nclassDef c " +
    "radius: 5,".repeat(8000) +
    "radius: 6",
    HEAD + "A: [0.5, 0.5] " + "color: #abc ,".repeat(6000) + "radius: 6",
    HEAD + repeat_lines(3500, i => "P\{i}: [0.\{i % 100}, 0.\{i * 7 % 100}]\n"),
    HEAD + repeat_lines(300, i => "Point \{i}: [0.5, 0.5]\n"),
    HEAD +
    repeat_lines(3000, i => "classDef c\{i} radius: \{i}\n") +
    "A:::c7: [0.5, 0.5]",
    HEAD + "word ".repeat(n / 5) + ": [0.5, 0.5]",
    HEAD + "quadrant-1 \"`" + "*a _b ".repeat(n / 6) + "`\"",
    HEAD + "x-axis \"" + "#35;&amp;<br>".repeat(n / 13) + "\"",
    HEAD + "title " + "long title ".repeat(n / 11),
    HEAD + "A:::" + "c".repeat(n) + ": [0.5, 0.5]",
    "quadrantChart;" + "quadrant-1 a;".repeat(10000),
    HEAD + repeat_lines(450, _ => " ".repeat(100) + "quadrant-2 b\n"),
    HEAD + "A: [0.5, 0.5] radius: " + "9".repeat(400),
  ]
  for source in cases {
    match big(source) {
      Ok(result) => inspect(result.svg.length() > 0, content="true")
      Err(_) => ()
    }
  }
}

///|
test "source over the default limit is refused" {
  let source = HEAD + "A: [0.5, 0.5]\n".repeat(5000)
  let message = @core.render(
      [@quadrant.quadrant],
      source,
      @types.RenderOptions::default(),
    ).svg catch {
      @errors.PeleError(failure) => failure.message
    }
  inspect(message.contains("limit of 50000"), content="true")
}
