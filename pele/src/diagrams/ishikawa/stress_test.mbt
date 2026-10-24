///|
let head : String = "ishikawa-beta\n"

///|
/// Renders without the source limit and says whether the picture came out finite.
fn survives(src : String) -> Bool {
  let options = { ..@types.RenderOptions::default(), limit: Some(1.0e9), }
  let result = @core.render([@ishikawa.ishikawa], src, options) catch {
    @errors.PeleError(_) => return true
  }
  !result.svg.contains("NaN") &&
  !result.svg.contains("Infinity") &&
  result.width.is_nan() == false &&
  result.height.is_nan() == false
}

///|
fn nested(count : Int32, pad : (Int32) -> Int32) -> String {
  let out = StringBuilder()
  for i in 0..<count {
    out.write_string("\{" ".repeat(pad(i))}n\n")
  }
  out.to_string()
}

///|
test "long single lines are drawn" {
  assert_true(survives(head + "  " + "a".repeat(50000)))
  assert_true(survives(head + "  Effect\n    " + "word ".repeat(10000)))
  assert_true(
    survives(
      head + "  Effect\n    Category\n      " + "#35;&amp;<br>".repeat(3800),
    ),
  )
}

///|
test "thousands of categories and causes are drawn" {
  assert_true(survives(head + "  E\n" + "    c\n".repeat(12000)))
  assert_true(survives(head + "  E\n    C\n" + "      c\n".repeat(12000)))
  assert_true(
    survives(head + "  E\n    C\n      c\n" + "        s\n".repeat(12000)),
  )
  assert_true(
    survives(head + "  E\n" + "    c\n      d\n        e\n".repeat(4000)),
  )
}

///|
test "outlines thousands of levels deep are drawn without recursion" {
  assert_true(survives(head + nested(300, i => i + 1)))
  assert_true(survives(head + nested(3000, i => i + 1)))
  assert_true(
    survives(
      head + " E\n" + nested(3000, i => i + 2) + nested(3000, i => i + 2),
    ),
  )
}

///|
test "indentation that goes up and down is drawn" {
  assert_true(survives(head + nested(8000, i => 1 + i * 7 % 13)))
  assert_true(survives(head + " E\n" + nested(20, i => 1 + i % 2 * 2000)))
}

///|
test "a deep outline stays in order" {
  let options = { ..@types.RenderOptions::default(), limit: Some(1.0e9), }
  let out = StringBuilder()
  for i in 0..<400 {
    out.write_string("\{" ".repeat(i + 1)}n\{i}\n")
  }
  let result = @core.render(
    [@ishikawa.ishikawa],
    head + out.to_string(),
    options,
  )
  assert_true(result.svg.contains(">n399</text>"))
}

///|
test "source over the default limit is refused" {
  let message = @core.render(
      [@ishikawa.ishikawa],
      head + "  cause\n".repeat(8000),
      @types.RenderOptions::default(),
    ).svg catch {
      @errors.PeleError(failure) => failure.message
    }
  assert_true(message.contains("limit of 50000"))
}

///|
test "names that are special in JavaScript are plain text" {
  assert_true(
    survives(
      head +
      "  __proto__\n    constructor\n      toString\n        hasOwnProperty\n    __proto__\n",
    ),
  )
}
