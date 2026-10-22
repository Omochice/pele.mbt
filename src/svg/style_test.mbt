///|
fn show(declarations : Array[String]) -> String {
  let style = @svg.resolve_style(declarations)
  "shape=[\{style.shape}] line=[\{style.line}] text=[\{style.text}] stroke=\{style.stroke.unwrap_or("-")} bold=\{style.bold} italic=\{style.italic} size=\{style.font_size.map(size => size.to_string()).unwrap_or("-")}"
}

///|
test "no declarations resolve to nothing" {
  inspect(
    show([]),
    content="shape=[] line=[] text=[] stroke=- bold=false italic=false size=-",
  )
  inspect(
    show(["nonsense", ":x", "color:", "x:y"]),
    content="shape=[] line=[] text=[] stroke=- bold=false italic=false size=-",
  )
}

///|
test "a fill applies to the shape only" {
  inspect(
    show(["fill:#a1a1a1"]),
    content="shape=[ style=\"fill:#a1a1a1;\"] line=[] text=[] stroke=- bold=false italic=false size=-",
  )
}

///|
test "strokes also style lines and !important is dropped" {
  inspect(
    show(["stroke:#f00", "stroke-width: 2px !IMPORTANT"]),
    content="shape=[ style=\"stroke:#f00;stroke-width:2px;\"] line=[ style=\"stroke:#f00;stroke-width:2px;\"] text=[] stroke=#f00 bold=false italic=false size=-",
  )
}

///|
test "text properties are kept apart and color becomes fill" {
  inspect(
    show([
      "color:red", "font-weight:bold", "font-style:italic", "font-size:12px",
    ]),
    content="shape=[] line=[] text=[ style=\"fill:red;font-weight:bold;font-style:italic;font-size:12px;\"] stroke=- bold=true italic=true size=12",
  )
}

///|
test "opacity applies to both and a repeated property keeps its first place" {
  inspect(
    show(["FILL:red", "opacity:0.5", "stroke:blue", "fill:green"]),
    content="shape=[ style=\"fill:green;opacity:0.5;stroke:blue;\"] line=[ style=\"opacity:0.5;stroke:blue;\"] text=[ style=\"opacity:0.5;\"] stroke=blue bold=false italic=false size=-",
  )
}

///|
test "values that could break out or load something are dropped" {
  for
    value in [
      "url(#x)", "URL (x)", "expression(1)", "javascript:1", "a<b", "a>b", "a{b",
      "a}b", "a;b", "a\\b", "@import x", "image-set(x)", "a/*b",
    ] {
    inspect(
      show(["fill:" + value]),
      content="shape=[] line=[] text=[] stroke=- bold=false italic=false size=-",
    )
  }
}

///|
test "quotes in a value are escaped" {
  inspect(
    show(["fill:a\"b&c"]),
    content="shape=[ style=\"fill:a&quot;b&amp;c;\"] line=[] text=[] stroke=- bold=false italic=false size=-",
  )
}

///|
test "font weight and size are read from the text style" {
  inspect(
    show(["font-weight:700"]),
    content="shape=[] line=[] text=[ style=\"font-weight:700;\"] stroke=- bold=true italic=false size=-",
  )
  inspect(
    show(["font-weight:0x258"]),
    content="shape=[] line=[] text=[ style=\"font-weight:0x258;\"] stroke=- bold=true italic=false size=-",
  )
  inspect(
    show(["font-weight:500", "font-size:300px"]),
    content="shape=[] line=[] text=[ style=\"font-weight:500;font-size:300px;\"] stroke=- bold=false italic=false size=-",
  )
  inspect(
    show(["font-size:1.5.2px"]),
    content="shape=[] line=[] text=[ style=\"font-size:1.5.2px;\"] stroke=- bold=false italic=false size=1.5",
  )
  inspect(
    show(["font-size:2em"]),
    content="shape=[] line=[] text=[ style=\"font-size:2em;\"] stroke=- bold=false italic=false size=-",
  )
}
