///|
/// Renders `source` without a size limit and reports whether it drew or was refused.
/// What matters is that every input finishes and fails only with a `PeleError`.
fn outcome(source : String) -> String {
  let options = {
    ..@types.RenderOptions::default(),
    limit: Some(@double.infinity),
  }
  let _ = @core.render([@packet.packet], source, options) catch {
    @errors.PeleError(_) => return "refused"
  }
  "drawn"
}

///|
fn config(packet : String, body : String) -> String {
  "---\nconfig:\n  packet:\n\{packet}\n---\n\{body}"
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
test "four thousand single-bit fields" {
  inspect(
    outcome("packet\n" + repeat_lines(4000, i => "\{i}: \"f\{i}\"\n")),
    content="drawn",
  )
}

///|
test "five thousand counted fields" {
  inspect(
    outcome("packet\n" + repeat_lines(5000, i => "+\{i % 40 + 1}: \"f\"\n")),
    content="drawn",
  )
}

///|
test "one field of a billion bits" {
  inspect(
    outcome("packet\n+1000000000: \"wide\"\n+1: \"after\""),
    content="drawn",
  )
}

///|
test "a field of more bits than a number holds" {
  inspect(
    outcome("packet\n+" + "9".repeat(400) + ": \"x\"\n+1: \"y\""),
    content="drawn",
  )
}

///|
test "ten thousand rows of one bit" {
  inspect(
    outcome(config("    bitsPerRow: 1", "packet\n+20000: \"a\"")),
    content="drawn",
  )
}

///|
test "a long label on one field" {
  inspect(
    outcome("packet\n0-31: \"" + "word ".repeat(10000) + "\""),
    content="drawn",
  )
}

///|
test "a long label of entities" {
  inspect(
    outcome("packet\n0-31: \"" + "#35;&amp;".repeat(5000) + "\""),
    content="drawn",
  )
}

///|
test "long runs that the lexer could rescan" {
  inspect(
    outcome("packet\n" + "1".repeat(50000) + ": \"a\""),
    content="refused",
  )
  inspect(outcome("packet\n" + "0".repeat(50000)), content="refused")
  inspect(outcome("packet\n0" + "-".repeat(50000)), content="refused")
  inspect(outcome("packet\n" + "---\n".repeat(12000)), content="drawn")
  inspect(outcome("packet\n" + "---\n".repeat(12001)), content="refused")
  inspect(outcome("packet\n0: \"" + "a".repeat(50000)), content="refused")
  inspect(outcome("packet\n0: \"" + "\\".repeat(50000)), content="refused")
  inspect(outcome("packet\n" + "%%{\n".repeat(12000)), content="drawn")
  inspect(
    outcome("packet\naccDescr {" + " a\n".repeat(16000)),
    content="refused",
  )
}

///|
test "a long title and many blank lines and comments" {
  inspect(outcome("packet title " + "x".repeat(50000)), content="drawn")
  inspect(outcome("packet\n" + " ".repeat(50000) + "0: \"a\""), content="drawn")
  inspect(
    outcome("packet\n" + "\n \t".repeat(16000) + "0: \"a\""),
    content="drawn",
  )
  inspect(
    outcome("packet\n" + "%% c\n".repeat(10000) + "0: \"a\""),
    content="drawn",
  )
  inspect(outcome("packet\n" + "title t\n".repeat(6000)), content="drawn")
}
