///|
fn width(text : String, size : Double, style : Int32) -> Double {
  @text.metrics_measurer.width(text, size, style)
}

///|
test "ASCII text is measured from the regular Arial table" {
  inspect(width("ash", 14, 0), content="22.568")
  inspect(width("Calcium [42.96]", 14, 0), content="97.258")
  inspect(width("__proto__", 14, 0), content="63.042")
  inspect(width("40%", 14, 0), content="28.014")
  inspect(width("~", 14, 0), content="8.176")
}

///|
test "bold text is measured from the bold Arial table" {
  inspect(
    width("Key elements in Product X", 16, @text.STYLE_BOLD),
    content="201.84",
  )
  inspect(width("W", 13, @text.STYLE_BOLD), content="12.272")
}

///|
test "wide characters take an em and other non-ASCII characters an estimate" {
  inspect(width("日本語", 16, 0), content="48")
  inspect(width("\u{e9}", 16, 0), content="9.28")
  inspect(width("\u{1f600}", 16, 0), content="16")
}

///|
test "combining marks, low surrogates, and control characters take no width" {
  inspect(width("e\u{301}", 16, 0), content="8.896")
  inspect(width("a\tb", 16, 0), content="17.792")
}

///|
test "monospace text uses fixed advances" {
  inspect(width("abc", 16, @text.STYLE_MONO), content="28.8")
  inspect(width("日本", 10, @text.STYLE_MONO), content="24")
}
