///|
const HEAD : String = "cynefin-beta\n"

///|
fn big(source : String) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), }
  Ok(@core.render([@cynefin.cynefin], source, options)) catch {
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
test "worst-case inputs finish and either render or fail as syntax errors" {
  let n = 50000
  let names = ["complex", "clear", "chaotic", "confusion", "complicated"]
  let others = ["clear", "chaotic", "confusion", "complicated", "complex"]
  let cases = [
    HEAD + "complex\n" + repeat_lines(10000, i => "\"i\{i}\"\n"),
    HEAD + "confusion\n" + "\"x\"\n".repeat(n / 4),
    HEAD + "clear\n\"a\"\n".repeat(n / 10),
    HEAD + repeat_lines(5000, i => "complex --> clear : \"t\{i}\"\n"),
    HEAD +
    repeat_lines(5000, i => "\{names[i % 5]} --> \{others[(i + i % 3) % 5]}\n"),
    HEAD + "complex\n\"" + "word ".repeat(n / 5) + "\"",
    HEAD + "complex\n\"" + "a".repeat(n) + "\"",
    HEAD + "complex --> clear : \"" + "word ".repeat(n / 5) + "\"",
    HEAD + "title " + "x".repeat(n),
    HEAD + "complex\n\"" + "a".repeat(n),
    HEAD + "complex\n\"" + "\\".repeat(n),
    HEAD + "complex\n\"" + "\\\"".repeat(n / 2) + "\"",
    HEAD + "complex\n" + "\"a\n".repeat(n / 3),
    HEAD + "accDescr {" + " a\n".repeat(n / 3),
    HEAD + "%%{\n".repeat(n / 4),
    HEAD + "complex\n---\n".repeat(n / 12),
    HEAD + "\n".repeat(n),
    HEAD + "complex\n" + " ".repeat(n) + "\"a\"",
    HEAD + "%% c\n".repeat(n / 5),
    HEAD + "complex\n\"" + "#35;&amp;<br>".repeat(n / 13) + "\"",
    HEAD + "complex".repeat(n / 7),
  ]
  for source in cases {
    match big(source) {
      Ok(result) => inspect(result.svg.length() > 0, content="true")
      Err(failure) => inspect(failure.code is Syntax, content="true")
    }
  }
}

///|
test "options outside their range are ignored" {
  let source = "---\nconfig:\n  cynefin:\n    width: 1e999\n    height: -5\n    seed: .nan\n    boundaryAmplitude: x\n    showDomainDescriptions: 1\n---\ncynefin-beta\ncomplex\n\"a\"\nclear --> chaotic : \"b\"\n"
  let plain = "cynefin-beta\ncomplex\n\"a\"\nclear --> chaotic : \"b\"\n"
  inspect(big(source).unwrap().svg == big(plain).unwrap().svg, content="true")
}

///|
test "extreme options still draw a finite diagram" {
  for
    body in [
      "width: 1\n    height: 1", "width: 10000\n    height: 10000", "seed: 1e300",
      "seed: -7", "boundaryAmplitude: 50", "boundaryAmplitude: -1",
    ] {
    let source = "---\nconfig:\n  cynefin:\n    \{body}\n---\ncynefin-beta\ncomplex\n\"a\"\ncomplex --> clear\n"
    let svg = big(source).unwrap().svg
    inspect(svg.contains("NaN"), content="false")
    inspect(svg.contains("Infinity"), content="false")
  }
}

///|
test "hostile text is escaped in every position" {
  let payload = "<script>alert(1)</script>&"
  let sources = [
    "cynefin-beta\ncomplex\n\"\{payload}\"",
    "cynefin-beta\ncomplex\n'\{payload}'",
    "cynefin-beta\nconfusion\n\"\{payload}\"\n\"\{payload}\"\n\"\{payload}\"\n\"\{payload}\"",
    "cynefin-beta\ncomplex --> clear : \"\{payload}\"",
    "cynefin-beta\nconfusion --> chaotic : '\{payload}'",
    "cynefin-beta\ntitle \{payload}\ncomplex",
    "cynefin-beta\naccTitle: \{payload}\naccDescr: \{payload}\ncomplex",
    "cynefin-beta\naccDescr {\n \{payload}\n}\ncomplex",
    "cynefin-beta\n\{payload}",
    "cynefin-beta\ncomplex --> \{payload}",
    "---\ntitle: \"\{payload}\"\n---\ncynefin-beta\ncomplex\n\"a\"",
  ]
  for source in sources {
    match big(source) {
      Ok(result) => inspect(result.svg.contains("<script>"), content="false")
      Err(failure) => inspect(failure.code is Syntax, content="true")
    }
  }
}
