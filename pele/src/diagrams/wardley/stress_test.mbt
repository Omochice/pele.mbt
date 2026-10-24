///|
const HEAD : String = "wardley-beta\n"

///|
fn big(source : String) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), }
  Ok(@core.render([@wardley.wardley], source, options)) catch {
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
/// `(0.001 * (i % 1000)).toFixed(3)`
fn frac(i : Int32) -> String {
  let n = i % 1000
  let digits = n.to_string()
  "0." + "0".repeat(3 - digits.length()) + digits
}

///|
test "worst-case inputs are drawn or rejected without rescanning the text" {
  let n = 50000
  let cases = [
    HEAD + "component A [0.5, 0.5]\n" + "0".repeat(n - 100),
    HEAD + "component A [0.5, 0.5]\n" + "1.".repeat(n / 2 - 100),
    HEAD +
    repeat_lines(2000, i => "component c\{i} [\{frac(i)}, \{frac(i * 7)}]\n"),
    HEAD +
    repeat_lines(1500, i => "component c\{i} [\{frac(i)}, \{frac(i * 7)}]\n") +
    repeat_lines(1500, i => "c\{i} -> c\{i + 1}\n"),
    HEAD +
    repeat_lines(500, i => "component c\{i} [0.5, \{frac(i)}]\n") +
    repeat_lines(3000, i => "u\{i} -> v\{i}\n"),
    HEAD +
    "component A [0.9, 0.1]\ncomponent B [0.1, 0.9]\n" +
    repeat_lines(3000, i => "A +<> B; label \{i}\n"),
    HEAD + "component A [0.5, 0.5]\n".repeat(3000),
    HEAD +
    "component P [0.5, 0.5]\npipeline P {\n" +
    repeat_lines(2000, i => " component p\{i} [\{frac(i)}]\n") +
    "}\n",
    HEAD +
    repeat_lines(1000, i => {
      "component P\{i} [\{frac(i)}, 0.5]\npipeline P\{i} {\n component x [0.2]\n}\n"
    }),
    HEAD +
    "annotations [0.9, 0.1]\n" +
    repeat_lines(2000, i => "annotation \{i},[\{frac(i)}, 0.5] \"text \{i}\"\n"),
    HEAD +
    repeat_lines(700, i => {
      "note \"n\{i}\" [0.5, \{frac(i)}]\naccelerator a\{i} [0.2, \{frac(i)}]\ndeaccelerator d\{i} [0.8, \{frac(i)}]\n"
    }),
    HEAD +
    repeat_lines(1000, i => "component c\{i} [0.5, 0.1]\n") +
    repeat_lines(1000, i => "evolve c\{i} 0.9\n"),
    HEAD + "evolution " + repeat_lines(5000, i => "s\{i}@0.5 -> ") + "end\n",
    HEAD + "component " + "a".repeat(n) + " [0.5, 0.5]",
    HEAD + "component " + "ab ".repeat(n / 4) + "[0.5, 0.5]",
    HEAD + "component \"" + "word ".repeat(n / 5) + "\" [0.5, 0.5]",
    HEAD + "note \"" + "word ".repeat(n / 5) + "\" [0.5, 0.5]",
    HEAD +
    "component A [0.1, 0.1]\ncomponent B [0.9, 0.9]\nA -> B; " +
    "x".repeat(n),
    HEAD + ("a" + " ".repeat(99)).repeat(n / 100) + "1",
    HEAD + ("a" + " ".repeat(49) + "1" + " ".repeat(49)).repeat(n / 100),
    HEAD + "1" + "-".repeat(n) + "!",
    HEAD + ("1" + "-".repeat(99) + " ").repeat(n / 101),
    HEAD + "-".repeat(n),
    HEAD + "---\n".repeat(n / 4),
    HEAD + "A +'x\n".repeat(n / 6),
    HEAD + "A +'" + "x".repeat(n),
    HEAD + "component \"a\n".repeat(n / 13),
    HEAD + "accDescr {\n".repeat(n / 11),
    HEAD + ("accTitle" + " ".repeat(40)).repeat(n / 48),
    HEAD + "%%{\n".repeat(n / 4),
    HEAD + "size [" + "9".repeat(n) + ", 1]",
    HEAD + "component A [0." + "5".repeat(n) + ", 0.5]",
    HEAD + ("1".repeat(98) + ". ").repeat(n / 100),
    HEAD + "\n".repeat(n),
    HEAD + "component A [0.5, 0.5] %% c\n".repeat(n / 28),
    HEAD + "componentannotationsevolve".repeat(n / 26),
  ]
  for source in cases {
    match big(source) {
      Ok(result) => assert_true(result.svg.length() > 0)
      Err(failure) =>
        assert_true(failure.code is (Syntax | Semantic), msg=failure.message)
    }
  }
}

///|
test "refuses source over the default limit" {
  let source = HEAD + "component A [0.5, 0.5]\n".repeat(3000)
  match drawn_with_defaults(source) {
    Ok(_) => fail("rendered")
    Err(failure) => assert_true(failure.message.contains("limit of 50000"))
  }
}

///|
fn drawn_with_defaults(
  source : String,
) -> Result[@types.RenderResult, @errors.Failure] {
  Ok(@core.render([@wardley.wardley], source, @types.RenderOptions::default())) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}
