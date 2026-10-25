///|
/// Pele's output is inserted into pages as markup, so it must be inert whatever the diagram says:
/// only drawing elements, only presentation attributes, and nothing that loads or runs anything.
/// This is a reduced form of the check pele's tests apply, with the same allowed names.
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
fn unsafe_value(name : String, value : String) -> Bool {
  match name {
    "style" =>
      value.contains("url") ||
      value.contains("expression") ||
      value.contains("@import") ||
      value.contains("javascript:") ||
      value.iter().any(c => c is ('<' | '>' | '{' | '}' | '\\'))
    "fill" | "stroke" | "font-family" | "rx" =>
      value.contains("url") || value.contains("javascript:")
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
/// Text an attacker might put anywhere a diagram accepts a string.
let payloads : Array[String] = [
  "<script>alert(1)</script>",
  "\"><script>alert(1)</script>",
  "<img src=x onerror=alert(1)>",
  "<svg onload=alert(1)>",
  "<a href=\"javascript:alert(1)\">x</a>",
  "<foreignObject><iframe src=javascript:alert(1)></iframe></foreignObject>",
  "</text></g></svg><script>alert(1)</script>",
  "javascript:alert(1)",
  "JaVaScRiPt:alert(1)",
  " javascript:alert(1)",
  "jav&#x09;ascript:alert(1)",
  "data:text/html,<script>alert(1)</script>",
  "vbscript:msgbox(1)",
  "' onload='alert(1)",
  "\" onmouseover=\"alert(1)",
  "x\" onclick=\"alert(1)\" y=\"",
  "#60;script#62;alert(1)#60;/script#62;",
  "#106;avascript:alert(1)",
  "#34; onload=#34;alert(1)",
  "url#40;javascript:alert#40;1#41;#41;",
  "red#59;background:url#40;//evil.example/x#41;",
  "&lt;script&gt;alert(1)&lt;/script&gt;",
  "&#60;script&#62;",
  "url(javascript:alert(1))",
  "expression(alert(1))",
  "red;background:url(//evil.example/x)",
  "red\" onload=\"alert(1)",
  "]]><script>alert(1)</script>",
  "--><script>alert(1)</script>",
  "\u{0}\u{1}\u{8}\u{b}\u{1f}",
  "u\u{1}rl(//evil.example/x)",
  "u￾RL(//evil.example/x)",
  "u" + String::from_array([(0xd800).unsafe_to_char()]) + "rl(//evil.example/x)",
  "java￾script:alert(1)",
  "java" + String::from_array([(0xdc00).unsafe_to_char()]) + "script:alert(1)",
  "file￿:///etc/passwd",
  "__proto__",
  "constructor",
  "toString",
  "hasOwnProperty",
  "{{7*7}}",
  "${alert(1)}",
  "%0ajavascript:alert(1)",
  "file:///etc/passwd",
  "//evil.example/share",
  "\\\\evil.example\\share",
  "smb://evil.example/share",
  "obsidian://open?vault=x",
  "\\\"><script>",
]

///|
fn quoted_payload(p : String) -> String {
  String::from_iter(p.iter().filter(c => !(c is ('"' | '\\' | '\n'))))
}

///|
fn single_payload(p : String) -> String {
  String::from_iter(p.iter().filter(c => !(c is ('\'' | '\\' | '\n'))))
}

///|
/// pele's wardley security templates: hostile text in every position a map takes a string.
let templates : Array[(String) -> String] = [
  p => "wardley-beta\ncomponent \"\{quoted_payload(p)}\" [0.5, 0.5]",
  p => {
    "wardley-beta\ncomponent '\{single_payload(p)}' [0.5, 0.5] (buy) (inertia)"
  },
  p => "wardley-beta\ncomponent \{p} [0.5, 0.5]",
  p => {
    let q = quoted_payload(p)
    "wardley-beta\nanchor \"\{q}\" [0.9, 0.5]\ncomponent B [0.5, 0.5]\n\"\{q}\" -> B"
  },
  p => {
    "wardley-beta\ncomponent A [0.9, 0.1]\ncomponent B [0.5, 0.5]\nA -> B; \{p}"
  },
  p => {
    "wardley-beta\ncomponent A [0.9, 0.1]\ncomponent B [0.5, 0.5]\nA +'\{single_payload(p)}'> B"
  },
  p => {
    let q = quoted_payload(p)
    "wardley-beta\ncomponent A [0.9, 0.1]\n\"\{q}\" -> A\nA -> \"\{q}\""
  },
  p => "wardley-beta\nnote \"\{quoted_payload(p)}\" [0.5, 0.5]",
  p => {
    "wardley-beta\nannotations [0.9, 0.1]\nannotation 1,[0.5, 0.5] \"\{quoted_payload(p)}\""
  },
  p => "wardley-beta\nannotation 7,[0.5, 0.5] \"\{quoted_payload(p)}\"",
  p => {
    let q = quoted_payload(p)
    "wardley-beta\naccelerator \"\{q}\" [0.5, 0.5]\ndeaccelerator \"\{q}\" [0.2, 0.2]"
  },
  p => {
    let q = quoted_payload(p)
    "wardley-beta\nevolution \"\{q}\" -> \"\{q}\"@0.5 / \"\{q}\" -> C\ncomponent A [0.5, 0.5]"
  },
  p => {
    let q = quoted_payload(p)
    "wardley-beta\ncomponent \"\{q}\" [0.5, 0.5]\nevolve \"\{q}\" 0.9"
  },
  p => {
    let q = quoted_payload(p)
    "wardley-beta\ncomponent \"\{q}\" [0.5, 0.5]\npipeline \"\{q}\" {\n component \"\{q}\" [0.2]\n component B [0.8]\n}"
  },
  p => "wardley-beta\ntitle \{p}\ncomponent A [0.5, 0.5]",
  p => "wardley-beta\naccTitle: \{p}\naccDescr: \{p}\ncomponent A [0.5, 0.5]",
  p => "wardley-beta\naccDescr {\n \{p}\n}\ncomponent A [0.5, 0.5]",
  p => {
    let s = single_payload(p)
    "---\ntitle: \"\{quoted_payload(p)}\"\nconfig:\n  wardley-beta:\n    width: '\{s}'\n    height: 1e999\n    showGrid: '\{s}'\n---\nwardley-beta\ncomponent A [0.5, 0.5]"
  },
]

///|
/// Whether `source` was drawn, and the first thing in the drawing that is not inert.
fn check(source : String) -> (Bool, String?) {
  let result = @core.render(
    [@wardley.wardley],
    source,
    @types.RenderOptions::default(),
  ) catch {
    @errors.PeleError(_) => return (false, None)
  }
  (true, inert_problem(result.svg))
}

///|
fn assert_inert(source : String) -> Bool raise {
  let (drawn, problem) = check(source)
  if problem is Some(problem) {
    fail("\{problem} for \{source.escape()}")
  }
  drawn
}

///|
test "the output is inert with hostile text in every position" {
  let mut rendered = 0
  for payload in payloads {
    for template in templates {
      if assert_inert(template(payload)) {
        rendered += 1
      }
    }
  }
  assert_true(rendered > payloads.length() * 12)
}

///|
test "the output is inert for extreme numbers" {
  let nines = "9".repeat(400)
  for
    source in [
      "wardley-beta\nsize [\{nines}, \{nines}]\ncomponent A [0.5, 0.5]",
      "wardley-beta\nsize [0, 0]\ncomponent A [0.5, 0.5]",
      "wardley-beta\ncomponent A [0.5, 0.5] label [-\{nines}, \{nines}]",
      "wardley-beta\nannotation \{nines},[0.5, 0.5] \"big\"\nannotations [1, 1]",
      "wardley-beta\nevolution A@\{nines}.0 -> B@0.0\ncomponent A [0.0, 1.0]",
      "wardley-beta\ncomponent A [0.5, 0.5]\ncomponent B [0.5, 0.5]\nA -> B\nA +<> B\nevolve A 0.5",
      "wardley-beta\ncomponent A [0.5, 0.5]\npipeline A {\n component B [0.5]\n component C [0.5]\n}\nevolve A 0.50",
      "---\nconfig:\n  wardley-beta:\n    width: 1\n    height: 100000\n---\nwardley-beta\ncomponent A [0.5, 0.5]",
    ] {
    assert_true(assert_inert(source), msg=source)
  }
}

///|
test "the output is inert for mutated corpus inputs" {
  let seeds = [..docs, ..valid, ..invalid]
  let pieces = [
    ..payloads, "\"", "'", "\n", " -> ", "; ", "+'", "component ", " [0.5, 0.5]",
    "note ", "(buy)",
  ]
  let next = mutator(seeds, pieces, random(17))
  let mut rendered = 0
  for source in seeds {
    if assert_inert(source) {
      rendered += 1
    }
  }
  for _ in 0..<2000 {
    if assert_inert(next()) {
      rendered += 1
    }
  }
  assert_true(rendered > 100)
}
