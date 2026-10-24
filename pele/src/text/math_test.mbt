///|
/// A typesetter that answers every request with `markup`.
fn answering(markup : Json) -> ((String, Double) -> Json?)? {
  Some((_, _) => Some(markup))
}

///|
fn shown(markup : @text.MathMarkup?) -> String {
  match markup {
    None => "none"
    Some({ body: Svg(svg), width, height, }) => "svg \{svg} \{width}x\{height}"
    Some({ body: Html(html), width, height, }) =>
      "html \{html} \{width}x\{height}"
  }
}

///|
test "nothing is typeset without a typesetter" {
  inspect(@text.math_active(), content="false")
  inspect(@text.typeset("x", 16) is None, content="true")
}

///|
test "svg and html markup are typeset in a box of their size" {
  let svg : Json = { "svg": "<path/>", "width": 20, "height": 24 }
  @text.with_math(answering(svg), () => {
    inspect(@text.math_active(), content="true")
    inspect(shown(@text.typeset("x", 16)), content="svg <path/> 20x24")
  })
  let html : Json = { "html": "<i>x</i>", "width": 17.5, "height": 21 }
  @text.with_math(answering(html), () => {
    inspect(shown(@text.typeset("x", 14)), content="html <i>x</i> 17.5x21")
  })
}

///|
test "markup without a finite positive size or a string body is not typeset" {
  let rejected : Array[Json] = [
    { "svg": "<path/>", "width": 0, "height": 24 },
    { "svg": "<path/>", "width": 20, "height": -1 },
    { "svg": "<path/>", "width": "20", "height": 24 },
    { "svg": "<path/>", "height": 24 },
    { "svg": null, "html": "<i>x</i>", "width": 20, "height": 24 },
    { "html": 1, "width": 20, "height": 24 },
    { "width": 20, "height": 24 },
    "<path/>",
  ]
  for markup in rejected {
    @text.with_math(answering(markup), () => {
      inspect(@text.typeset("x", 16) is None, content="true")
    })
  }
  @text.with_math(Some((_, _) => None), () => {
    inspect(@text.typeset("x", 16) is None, content="true")
  })
}

///|
test "each TeX and size is asked for once per render" {
  let asked = []
  let math = Some((tex : String, size : Double) => {
    asked.push("\{tex}@\{size}")
    Some(({ "svg": "", "width": 1, "height": 1 } : Json))
  })
  @text.with_math(math, () => {
    ignore(@text.typeset("x", 16))
    ignore(@text.typeset("x", 16))
    ignore(@text.typeset("x", 14))
    ignore(@text.typeset("y", 16))
  })
  @text.with_math(math, () => ignore(@text.typeset("x", 16)))
  debug_inspect(asked, content="[\"x@16\", \"x@14\", \"y@16\", \"x@16\"]")
}

///|
test "a rejected markup is remembered as rejected" {
  let mut calls = 0
  let math = Some((_ : String, _ : Double) => {
    calls += 1
    Some(({ "svg": "", "width": 0, "height": 1 } : Json))
  })
  @text.with_math(math, () => {
    ignore(@text.typeset("x", 16))
    ignore(@text.typeset("x", 16))
  })
  inspect(calls, content="1")
}

///|
test "the typesetter is restored after a render and around a title" {
  let svg : Json = { "svg": "", "width": 1, "height": 1 }
  @text.with_math(answering(svg), () => {
    @text.without_math(() => {
      inspect(@text.math_active(), content="false")
      inspect(@text.typeset("x", 16) is None, content="true")
    })
    inspect(@text.math_active(), content="true")
    @text.with_math(None, () => inspect(@text.math_active(), content="false"))
    inspect(@text.math_active(), content="true")
  })
  inspect(@text.math_active(), content="false")
}

///|
suberror Stop

///|
test "the typesetter is restored when a render fails" {
  let svg : Json = { "svg": "", "width": 1, "height": 1 }
  @text.with_math(answering(svg), () => raise Stop) catch {
    _ => ()
  }
  inspect(@text.math_active(), content="false")
  @text.with_math(answering(svg), () => {
    @text.without_math(() => raise Stop) catch {
      _ => ()
    }
    inspect(@text.math_active(), content="true")
  })
}
