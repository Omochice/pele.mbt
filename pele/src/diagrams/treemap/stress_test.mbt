///|
/// Draws a treemap with no limit on its size, and says whether that worked and stayed finite.
fn outcome(source : String) -> String {
  let options = {
    ..@types.RenderOptions::default(),
    limit: Some(@double.infinity),
  }
  let result = @core.render([@treemap.treemap], source, options) catch {
    @errors.PeleError(_) => return "error"
  }
  if result.svg.contains("NaN") || result.svg.contains("Infinity") {
    return "not finite"
  }
  "ok"
}

///|
fn lines(count : Int32, line : (Int32) -> String) -> String {
  let out = StringBuilder()
  for i in 0..<count {
    out.write_string(line(i))
  }
  out.to_string()
}

///|
test "thousands of leaves" {
  inspect(
    outcome("treemap\n" + lines(5000, i => "\"l\{i}\": \{i + 1}\n")),
    content="ok",
  )
  inspect(
    outcome("treemap\n\"s\"\n" + lines(5000, _ => " \"l\": 1\n")),
    content="ok",
  )
  inspect(
    outcome(
      "treemap\n" +
      lines(5000, i => {
        "\"l\": \{if i % 2 == 1 { "0.0001" } else { "99999999" }}\n"
      }),
    ),
    content="ok",
  )
}

///|
test "thousands of sections" {
  inspect(
    outcome("treemap\n" + lines(3000, i => "\"s\{i}\"\n  \"l\": \{i + 1}\n")),
    content="ok",
  )
  inspect(outcome("treemap\n" + lines(5000, i => "\"s\{i}\"\n")), content="ok")
}

///|
test "deep nesting" {
  inspect(
    outcome(
      "treemap\n" +
      lines(300, i => " ".repeat(i) + "\"s\{i}\"\n") +
      " ".repeat(300) +
      "\"leaf\": 1\n",
    ),
    content="ok",
  )
}

///|
test "many classes and declarations" {
  inspect(
    outcome(
      "treemap\n\"a\": 1:::c1\n" + lines(3000, i => "classDef c\{i} fill:red\n"),
    ),
    content="ok",
  )
  inspect(
    outcome(
      "treemap\n\"a\": 1:::c1\nclassDef c1 " +
      "fill:red,".repeat(5000) +
      "stroke:blue;\n",
    ),
    content="ok",
  )
  inspect(
    outcome(
      "treemap\nclassDef c1 fill:red,stroke:blue,color:white\n" +
      lines(3000, i => "\"l\{i}\": 5:::c1\n"),
    ),
    content="ok",
  )
}

///|
test "very long names, values and styles" {
  inspect(
    outcome("treemap\n\"" + "word ".repeat(10000) + "\": 1"),
    content="ok",
  )
  inspect(
    outcome("treemap\n\"" + "x".repeat(50000) + "\"\n \"a\": 1"),
    content="ok",
  )
  inspect(
    outcome("treemap\n\"" + "#35;&amp;".repeat(5555) + "\": 1"),
    content="ok",
  )
  inspect(outcome("treemap\n\"a\": " + "9".repeat(50000)), content="ok")
  inspect(outcome("treemap\n\"a\": " + ".,_".repeat(16666)), content="ok")
  inspect(
    outcome("treemap\n\"a\": 1:::cc\nclassDef cc " + "x".repeat(50000)),
    content="ok",
  )
  inspect(outcome("treemap\ntitle " + "x".repeat(50000)), content="ok")
  inspect(
    outcome(
      "---\nconfig:\n  treemap:\n    valueFormat: \"" +
      "0".repeat(50000) +
      "x\"\n---\ntreemap\n\"a\": 1",
    ),
    content="ok",
  )
}

///|
test "text that the lexer rejects only after scanning far" {
  inspect(
    outcome("treemap\nclassDef" + " ".repeat(50000) + "1"),
    content="error",
  )
  inspect(outcome("treemap\n" + "classDef a\n".repeat(6250)), content="error")
  inspect(
    outcome("treemap\nclassDef" + "\n ".repeat(25000) + "ab"),
    content="ok",
  )
  inspect(
    outcome("treemap\n" + "accDescr\n".repeat(5000) + "{"),
    content="error",
  )
  inspect(
    outcome("treemap\naccDescr {" + " a\n".repeat(16666)),
    content="error",
  )
  inspect(outcome("treemap\n\"" + "a".repeat(50000)), content="error")
  inspect(outcome("treemap\n" + "\"".repeat(25000)), content="ok")
  inspect(outcome("treemap\n\"a\"" + ":".repeat(50000)), content="error")
  inspect(outcome("treemap\n" + " ".repeat(50000) + "\"a\": 1"), content="ok")
  inspect(
    outcome("treemap\n" + "%% c\n".repeat(10000) + "\"a\": 1"),
    content="ok",
  )
}
