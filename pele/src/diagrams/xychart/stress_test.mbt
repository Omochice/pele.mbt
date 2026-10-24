///|
fn big(source : String) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), }
  Ok(@core.render([@xychart.xychart], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn read(source : String) -> Unit {
  let db = @xychart.XyChartDb::new()
  @xychart.parse_xychart(source, db) catch {
    @errors.PeleError(_) => ()
  }
}

///|
fn repeat_with(
  count : Int32,
  item : (Int32) -> String,
  join~ : String = "",
) -> String {
  Array::makei(count, item).join(join)
}

///|
const WITH_LABELS : String = "---\nconfig:\n  xyChart:\n    showDataLabel: true\n---\n"

///|
test "inputs that make a naive lexer rescan the text are read in one pass" {
  let n = 50000
  let cases = [
    "xychart\n" + " \n".repeat(n / 2) + "line [1]",
    "xychart\nx-axis a " + "-".repeat(n),
    "xychart\nline [" + "+-".repeat(n / 2) + "]",
    "xychart\nline [" + "1.".repeat(n / 2) + "]",
    "xychart" + "\n%% c".repeat(n / 5),
    "xychart\n" + "a%%".repeat(n / 3),
    "xychart\n" + ("accTitle" + " ".repeat(40)).repeat(1000),
    "xychart\n" + ("`)" + " ".repeat(36) + "{ this").repeat(1000),
    "xychart\n" + "xychart-bet x-axi linex bar_ titl ".repeat(n / 34),
    "xychart\naccDescr {" + " a\n".repeat(n / 3),
    "xychart\ntitle \"" + "a".repeat(n),
    "xychart\n" + "x-axis line bar y-axis ".repeat(n / 23),
    "xychart\n".repeat(10000) + "line [1]",
  ]
  for source in cases {
    read(source)
  }
}

///|
test "charts of many values, categories, points and series are drawn" {
  let n = 50000
  let cases = [
    "xychart\nline [" +
    repeat_with(20000, i => (i % 97).to_string(), join=",") +
    "]",
    "xychart\nbar [" +
    repeat_with(16000, i => (i % 97).to_string(), join=",") +
    "]",
    WITH_LABELS +
    "xychart\nbar [" +
    repeat_with(8000, i => i.to_string(), join=",") +
    "]",
    "xychart\nx-axis [" +
    repeat_with(8000, i => "c\{i}", join=",") +
    "]\nbar [" +
    "1,".repeat(7999) +
    "1]",
    "xychart horizontal\nx-axis [" +
    repeat_with(8000, i => "c\{i}", join=",") +
    "]\nline [" +
    "1,".repeat(7999) +
    "1]",
    "xychart\nline [" + repeat_with(5000, i => "\{i} \"p\{i}\"", join=",") + "]",
    "xychart\n" +
    repeat_with(4000, i => {
      (if i % 2 == 1 { "bar" } else { "line" }) + " [1, 2]\n"
    }),
    "xychart\n" + repeat_with(3000, i => "line \"series \{i}\" [1, 2]\n"),
    "xychart\nx-axis [\"" + "word ".repeat(n / 5) + "\"]\nbar [1]",
    "xychart\ntitle \"" + "long title ".repeat(n / 11) + "\"\nline [1, 2]",
    "xychart\ntitle " + "a ".repeat(n / 2) + "\nline [1, 2]",
    "xychart\nx-axis \"" + "#35;&amp;<br>".repeat(n / 13) + "\" [a]\nline [1]",
    "xychart\nline [" + "9".repeat(n) + ", 1]",
    "xychart\ny-axis -" +
    "9".repeat(400) +
    " --> " +
    "9".repeat(400) +
    "\nbar [1, 2]",
  ]
  for source in cases {
    match big(source) {
      Ok(result) => assert_true(result.svg.length() > 0)
      Err(failure) => inspect(failure.code is Syntax, content="true")
    }
  }
}

///|
test "source over the default limit is refused" {
  let source = "xychart\n" + "line [1, 2, 3]\n".repeat(5000)
  match drawn(source) {
    Ok(_) => fail("the source is over the limit")
    Err(failure) => assert_true(failure.message.contains("limit of 50000"))
  }
}
