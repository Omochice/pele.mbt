// Ported from pele v1.8.0, tests/render/c4-security.test.ts; the inertness check is the one the other ports use.

///|
/// Pele's output is inserted into pages as markup, so it must be inert whatever the diagram says:
/// only drawing elements, only presentation attributes, and nothing that loads or runs anything.
/// This is the reduced form of pele's check that the mind map tests use, with the same allowed names.
let allowed_elements : Array[String] = [
  "svg", "g", "rect", "circle", "ellipse", "polygon", "path", "text", "tspan", "a",
  "title", "desc", "image",
]

///|
let allowed_attributes : Array[String] = [
  "xmlns", "class", "viewBox", "width", "height", "style", "font-family", "font-size",
  "font-weight", "font-style", "fill", "fill-opacity", "opacity", "stroke", "stroke-width",
  "stroke-dasharray", "stroke-linecap", "stroke-linejoin", "role", "aria-roledescription",
  "aria-labelledby", "aria-describedby", "id", "data-id", "data-icon", "data-href",
  "transform", "x", "y", "rx", "ry", "r", "cx", "cy", "d", "points", "text-anchor",
  "xml:space", "href", "target", "rel", "preserveAspectRatio",
]

///|
let numeric_attributes : Array[String] = [
  "x", "y", "width", "height", "r", "cx", "cy", "rx", "ry",
]

///|
fn is_name_char(c : Int32) -> Bool {
  (c >= 'a'.to_int() && c <= 'z'.to_int()) ||
  (c >= 'A'.to_int() && c <= 'Z'.to_int()) ||
  (c >= '0'.to_int() && c <= '9'.to_int()) ||
  c == '-'.to_int() ||
  c == ':'.to_int() ||
  c == '_'.to_int()
}

///|
fn is_number(value : String) -> Bool {
  value == "100%" ||
  (
    value != "" &&
    value.iter().all(c => c.is_ascii_digit() || c is ('-' | '.' | 'e' | '+'))
  )
}

///|
/// Whether `value` holds `url(` as /url\s*\(/i finds it.
/// pele's check asks for the call, so C4's placeholders for entities, which leave `url` without a parenthesis, are inert.
fn has_url_call(value : String) -> Bool {
  let lower = value.to_lower()
  let mut at = @util.index_of(lower, "url")
  while at != -1 {
    let mut i = at + 3
    while @util.is_space(@util.code_at(lower, i)) {
      i += 1
    }
    if @util.code_at(lower, i) == 40 {
      return true
    }
    at = @util.index_of(lower, "url", from=at + 1)
  }
  false
}

///|
fn unsafe_value(name : String, value : String) -> Bool {
  let lower = value.to_lower()
  match name {
    "style" =>
      has_url_call(value) ||
      lower.contains("expression") ||
      lower.contains("@import") ||
      lower.contains("javascript:") ||
      value.iter().any(c => c is ('<' | '>' | '{' | '}' | '\\'))
    "fill" | "stroke" | "font-family" | "rx" =>
      has_url_call(value) || lower.contains("javascript:")
    _ => false
  }
}

///|
/// The first thing about the markup that is not inert, or `None` when there is none.
fn inert_problem(svg : String) -> String? {
  let n = svg.length()
  let mut i = 0
  while i < n {
    if @util.code_at(svg, i) != '<'.to_int() {
      i += 1
      continue
    }
    i += 1
    if @util.code_at(svg, i) == '/'.to_int() {
      i += 1
    }
    let start = i
    while i < n && is_name_char(@util.code_at(svg, i)) {
      i += 1
    }
    let element = @util.slice(svg, start, end=i)
    if !allowed_elements.contains(element) {
      return Some("element <\{element}>")
    }
    while true {
      while @util.is_space(@util.code_at(svg, i)) {
        i += 1
      }
      let c = @util.code_at(svg, i)
      if c == '>'.to_int() {
        i += 1
        break
      }
      if c == '/'.to_int() && @util.code_at(svg, i + 1) == '>'.to_int() {
        i += 2
        break
      }
      let name_start = i
      while i < n && is_name_char(@util.code_at(svg, i)) {
        i += 1
      }
      let name = @util.slice(svg, name_start, end=i)
      if !allowed_attributes.contains(name) {
        return Some("attribute \{name} on <\{element}>")
      }
      if @util.code_at(svg, i) != '='.to_int() ||
        @util.code_at(svg, i + 1) != '"'.to_int() {
        return Some("attribute \{name} has no quoted value")
      }
      let close = @util.index_of(svg, "\"", from=i + 2)
      if close == -1 {
        return Some("attribute \{name} is not closed")
      }
      let value = @util.slice(svg, i + 2, end=close)
      if value.contains("<") {
        return Some("\{name}=\"\{value}\" holds a tag")
      }
      if numeric_attributes.contains(name) && !is_number(value) {
        return Some("\{name}=\"\{value}\" is not a number")
      }
      if unsafe_value(name, value) {
        return Some("\{name}=\"\{value}\"")
      }
      i = close + 1
    }
  }
  None
}

///|
/// FNV-1a over UTF-16 code units, the hash under which `hostile_outcomes` were taken from pele.
fn fnv1a(text : String) -> String {
  let mut h : UInt32 = 0x811c9dc5U
  for i in 0..<text.length() {
    h = (h ^ text.unsafe_get(i).to_int().reinterpret_as_uint()) * 0x01000193U
  }
  let digits = "0123456789abcdef"
  let out = StringBuilder()
  for shift in [28, 24, 20, 16, 12, 8, 4, 0] {
    let d = ((h >> shift) & 0xfU).reinterpret_as_int()
    out.write_char(digits.get_char(d).unwrap())
  }
  out.to_string()
}

///|
/// What rendering gives, written as the generator of `hostile_outcomes` writes pele's.
fn render_outcome(source : String) -> String {
  match drawn(source) {
    Ok(r) => {
      let links = r.links.map(l => "\{l.id}|\{l.href}|\{l.internal}").join(";")
      "ok \{r.width} \{r.height} \{links}\n\{r.svg}"
    }
    Err(failure) => "error \{failure.code.to_string()}\n\{failure.message}"
  }
}

///|
test "hostile text in every position is drawn as pele draws it, and inert" {
  let wrong = []
  let mut k = 0
  let mut rendered = 0
  for t, pieces in hostile_templates {
    for p, payload in hostile_payloads {
      let source = pieces.join(payload)
      let outcome = render_outcome(source)
      if fnv1a(outcome) != hostile_outcomes[k] {
        wrong.push("template \{t} payload \{p}")
      }
      if drawn(source) is Ok(result) {
        rendered += 1
        if inert_problem(result.svg) is Some(problem) {
          fail("\{problem} for \{source.escape()}")
        }
      }
      k += 1
    }
  }
  assert_eq(k, hostile_outcomes.length())
  inspect(wrong.join("\n"), content="")
  assert_true(rendered > 700)
}

///|
test "the output is inert for every documentation example" {
  for source in docs {
    let svg = drawn(source).unwrap().svg
    assert_eq(inert_problem(svg), None)
  }
}

///|
test "holds for hostile option values" {
  for payload in hostile_payloads {
    let options = {
      ..@types.RenderOptions::default(),
      id_prefix: Some(payload),
      font_family: Some(payload),
    }
    let result = @core.render(
      [@c4.c4],
      "C4Context\naccDescr: d\nSystem(a, \"A\")\nSystem(b, \"B\")\nRel(a, b, \"x\")",
      options,
    )
    assert_eq(inert_problem(result.svg), None, msg=payload.escape())
  }
}

///|
test "never emits an unsafe link" {
  for
    url in [
      "javascript:alert(1)", " JaVaScRiPt:alert(1)", "data:text/html,x", "vbscript:x",
      "jav&#x09;ascript:alert(1)",
    ] {
    let result = drawn(
      "C4Context\nSystem(a, \"A\", $link=\"\{url}\")\nBoundary(b, \"B\", $link=\"\{url}\") {\nSystem(c, \"C\")\n}\nRel(a, c, \"x\", $link=\"\{url}\")",
    ).unwrap()
    assert_false(result.svg.contains("<a "))
    assert_eq(result.links.length(), 0)
  }
}

///|
test "drops colours that are more than a colour" {
  let svg = svg_of(
    "C4Context\nSystem(a, \"A\")\nSystem(b, \"B\")\nRel(a, b, \"x\")\nUpdateElementStyle(a, \"red;background:url(//evil.example/x)\", \"expression(alert(1))\", \"url(#x)\")\nUpdateRelStyle(a, b, \"red}\", \"blue<\")",
  )
  for word in ["url(", "expression", "evil", "red", "blue"] {
    assert_false(svg.contains(word), msg=word)
  }
}

///|
test "names that are object keys in pele are plain names" {
  let svg = svg_of(
    "C4Context\nSystem(__proto__, \"A\", $__proto__=\"polluted\", $constructor=\"x\")\nSystem(constructor, \"B\", $tags=\"__proto__,constructor\", $shape=\"toString\")\nRel(__proto__, constructor, \"x\")\nUpdateElementStyle(__proto__, $prototype=\"x\")\nUpdateRelStyle(__proto__, constructor, $__proto__=\"1\")",
  )
  assert_true(svg.has_prefix("<svg"))
  assert_true(svg.contains("data-id=\"__proto__-constructor\""))
  assert_false(svg.contains("[object"))
}

///|
/// pele's seeded generator for its randomised tests.
priv struct Random {
  mut state : UInt32
}

///|
fn Random::next(self : Random) -> Double {
  self.state = self.state * 1664525U + 1013904223U
  self.state.to_double() / 4294967296.0
}

///|
fn Random::pick(self : Random, n : Int32) -> Int32 {
  (self.next() * n.to_double()).floor().to_int()
}

///|
/// pele mutates every source in its corpus; this corpus is the documentation examples alone.
fn mutator(
  corpus : Array[String],
  fragments : Array[String],
  rnd : Random,
) -> () -> String {
  fn pick(list : Array[String]) -> String {
    list[rnd.pick(list.length())]
  }

  () => {
    let mut s = pick(corpus)
    let edits = 1 + rnd.pick(3)
    for _ in 0..<edits {
      let pos = rnd.pick(s.length() + 1)
      let r = rnd.next()
      s = if r < 0.35 {
        @util.slice(s, 0, end=pos) + pick(fragments) + @util.slice(s, pos)
      } else if r < 0.6 {
        @util.slice(s, 0, end=pos) + @util.slice(s, pos + 1 + rnd.pick(3))
      } else if r < 0.75 {
        let other = pick(corpus)
        let from = rnd.pick(other.length())
        @util.slice(s, 0, end=pos) +
        @util.slice(other, from, end=from + rnd.pick(20)) +
        @util.slice(s, pos)
      } else if r < 0.9 {
        @util.slice(s, 0, end=pos) +
        @util.slice(s, pos, end=pos + rnd.pick(6)) +
        @util.slice(s, pos)
      } else {
        @util.slice(s, 0, end=pos) + pick(fragments) + @util.slice(s, pos + 1)
      }
    }
    s
  }
}

///|
test "holds for mutated inputs" {
  let fragments = hostile_payloads.copy()
  fragments.append([
    "\"", "(", ")", ",", "\n", "{", "}", "$link=\"", "$bgColor=\"", "$offsetX=\"",
    "Rel(a, b, \"", "UpdateElementStyle(a, \"",
  ])
  let next = mutator(docs, fragments, Random::{ state: 3, })
  for _ in 0..<4000 {
    let source = next()
    if source.length() <= 4000 && drawn(source) is Ok(result) {
      if inert_problem(result.svg) is Some(problem) {
        fail("\{problem} for \{source.escape()}")
      }
    }
  }
}
