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
  if @svg.has_invalid_xml(svg) {
    return Some("a character XML does not allow")
  }
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
  "a￾b￿c" +
  String::from_array([(0xd800).unsafe_to_char()]) +
  "d" +
  String::from_array([(0xdc00).unsafe_to_char()]) +
  "e#65534;f",
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
  "#92;#92;nevil.example/share",
  "\u{9}/#92;nevil.example/share",
  "smb://evil.example/share",
  "obsidian://open?vault=x",
  "\\\"><script>",
]

///|
let templates : Array[(String) -> String] = [
  p => "\{HEAD}service a(server)[\{p}]",
  p => "\{HEAD}service a(server)[\"\{p}\"]",
  p => "\{HEAD}service a(server)['\{p}']",
  p => "\{HEAD}service a \"\{p}\"[A]",
  p => "\{HEAD}service a '\{p}'",
  p => "\{HEAD}service a(\{p})[A]",
  p => "\{HEAD}service \{p}",
  p => "\{HEAD}group g(cloud)[\{p}]\nservice a in g",
  p => "\{HEAD}group g(cloud)[\"\{p}\"]\nservice a[\{p}] in g",
  p => "\{HEAD}group g(\{p})[G]",
  p => "\{HEAD}group \{p}",
  p => "\{HEAD}group g\nservice a in \{p}",
  p => "\{HEAD}junction \{p}",
  p => "\{HEAD}service a\nservice b\na:R -[\{p}]-> L:b",
  p => "\{HEAD}service a\nservice b\na:R -[\"\{p}\"]- L:b",
  p => "\{HEAD}service a\nservice b\na:B <-['\{p}']-> T:b",
  p => "\{HEAD}service a\nservice b\na:\{p} -- L:b",
  p => "\{HEAD}service a\nservice b\n\{p}:R -- L:b",
  p => "\{HEAD}service a\nservice b\na\{p}:R -- L:b{group}",
  p => "\{HEAD}service a\nservice b\nalign row a \{p}",
  p => "\{HEAD}service a\nservice b\nalign \{p} a b",
  p => "\{HEAD}title \{p}\nservice a",
  p => "\{HEAD}accTitle: \{p}\naccDescr: \{p}\nservice a",
  p => "\{HEAD}accDescr {\n \{p}\n }\nservice a",
  p => "architecture-beta \{p}\nservice a",
  p => "\{HEAD}%% \{p}\nservice a",
  p => {
    "---\ntitle: \"\{p}\"\nconfig:\n  architecture:\n    iconSize: \"\{p}\"\n    fontSize: \"\{p}\"\n    padding: \"\{p}\"\n---\n\{HEAD}group g[G]\nservice a[A] in g"
  },
  p => {
    "%%{init: {\"architecture\": {\"iconSize\": \"\{p}\"}, \"themeVariables\": {\"fontFamily\": \"\{p}\"}}}%%\n\{HEAD}service a[A]"
  },
  p => "---\nconfig:\n  architecture: \"\{p}\"\n---\n\{HEAD}service a[A]",
]

///|
/// Renders `source` and tells whether it was drawn and the first thing that is not inert.
/// Text pele rejects has no output to check.
fn check(source : String, options : @types.RenderOptions) -> (Bool, String?) {
  let result = @core.render([@architecture.architecture], source, options) catch {
    @errors.PeleError(_) => return (false, None)
  }
  (true, inert_problem(result.svg))
}

///|
test "the output is inert with hostile text in every position" {
  let mut rendered = 0
  for template in templates {
    for payload in payloads {
      let source = template(payload)
      let (drawn, problem) = check(source, @types.RenderOptions::default())
      if drawn {
        rendered += 1
      }
      if problem is Some(problem) {
        fail("\{problem} for \{source.escape()}")
      }
    }
  }
  assert_true(rendered > 300)
}

///|
test "the output is inert for every documentation example" {
  for source in docs {
    let (drawn, problem) = check(source, @types.RenderOptions::default())
    assert_true(drawn)
    assert_eq(problem, None)
  }
}

///|
test "hostile option values stay inert" {
  let source = "\{HEAD}accTitle: t\ngroup g(cloud)[G]\nservice a(server)[A] in g\nservice b \"x\"[B]\na:R -[l]-> L:b"
  for payload in payloads {
    let options = {
      ..@types.RenderOptions::default(),
      id_prefix: Some(payload),
      font_family: Some(payload),
    }
    let (drawn, problem) = check(source, options)
    assert_true(drawn)
    assert_eq(problem, None, msg=payload.escape())
  }
}

///|
test "extreme numeric settings stay inert" {
  for
    value in [
      "0", "-1", "1e308", ".inf", ".nan", "1e-9", "99999999", "[1]", "{a: 1}", "null",
      "true",
    ] {
    let source = "---\nconfig:\n  architecture:\n    iconSize: \{value}\n    fontSize: \{value}\n    padding: \{value}\n---\n\{HEAD}group g[G]\nservice a \"t\"[A] in g\nservice b[B]\na:R -[l]-> L:b"
    let (drawn, problem) = check(source, @types.RenderOptions::default())
    assert_true(drawn, msg=value)
    assert_eq(problem, None, msg=value)
  }
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
test "the output is inert for mutated inputs" {
  let fragments = payloads.copy()
  fragments.append([
    "\"", "[", "]", "(", ")", "\n", " in ", "{group}", ":R --> L:", "service ", "group ",
    "junction ", "title ", "-[", "]-",
  ])
  let next = mutator(docs, fragments, Random::{ state: 3, })
  for _ in 0..<4000 {
    let source = next()
    if source.length() <= 4000 {
      let (_, problem) = check(source, @types.RenderOptions::default())
      if problem is Some(problem) {
        fail("\{problem} for \{source.escape()}")
      }
    }
  }
}

///|
test "ids that name object internals are plain ids" {
  let out = drawing(
    "\{HEAD}group __proto__(cloud)[P]\ngroup constructor[C] in __proto__\nservice toString(server)[A] in __proto__\nservice hasOwnProperty[B] in constructor\njunction valueOf\ntoString:R -- L:hasOwnProperty\nhasOwnProperty:B -- T:valueOf\nalign row toString hasOwnProperty",
  )
  inspect(count(out, "class=\"pele-cluster\""), content="2")
  inspect(count(out, "class=\"pele-node "), content="3")
  inspect(out.contains("data-id=\"__proto__\""), content="true")
}
