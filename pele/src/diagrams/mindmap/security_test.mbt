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
  "#92;#92;nevil.example/share",
  "\u{9}/#92;nevil.example/share",
  "smb://evil.example/share",
  "obsidian://open?vault=x",
  "\\\"><script>",
]

///|
let templates : Array[(String) -> String] = [
  p => "mindmap\n  \{p}\n    child",
  p => "mindmap\n  root\n    \{p}",
  p => "mindmap\n  root[\{p}]",
  p => "mindmap\n  root\n    id(\{p})",
  p => "mindmap\n  root\n    id((\{p}))",
  p => "mindmap\n  root\n    id))\{p}((",
  p => "mindmap\n  root\n    id)\{p}(",
  p => "mindmap\n  root\n    id{{\{p}}}",
  p => "mindmap\n  root\n    \{p}[text]",
  p => "mindmap\n  root\n    \{p}((text))",
  p => "mindmap\n  root[\"\{p}\"]\n    [\"\{p}\"]",
  p => "mindmap\n  root[\"`\{p}`\"]\n    a[\"`**\{p}**\n\{p}`\"]",
  p => "mindmap\n  root\n    a\n    ::icon(\{p})",
  p => "mindmap\n  root\n  ::icon(\{p})\n    a(b)\n    ::icon(\{p})",
  p => "mindmap\n  root\n    a\n    :::\{p}",
  p => "mindmap\n  root\n  :::\{p}\n    a[b]\n    :::\{p} \{p}",
  p => "mindmap\n  root\n    a %% \{p}\n    b(c) %% \{p}",
  p => "mindmap\n  root\n    fa:fa-\{p} x",
  p => "mindmap \{p}\n  root",
  p => "---\ntitle: \"\{p}\"\n---\nmindmap\n  root\n    a",
  p => {
    "---\nconfig:\n  mindmap:\n    maxNodeWidth: \"\{p}\"\n    padding: \"\{p}\"\n---\nmindmap\n  root\n    a"
  },
  p => {
    "%%{init: {\"mindmap\": {\"maxNodeWidth\": \"\{p}\"}, \"themeVariables\": {\"fontFamily\": \"\{p}\"}}}%%\nmindmap\n  root"
  },
]

///|
/// Renders `source` and returns the first thing that is not inert, or `None`.
/// Text pele rejects has no output to check, and is reported as `Some("rejected")` only by the caller's count.
fn check(source : String, options : @types.RenderOptions) -> (Bool, String?) {
  let result = @core.render([@mindmap.mindmap], source, options) catch {
    @errors.PeleError(_) => return (false, None)
  }
  (true, inert_problem(result.svg))
}

///|
test "the checker accepts what pele draws and rejects what it must not" {
  let result = @core.render(
    [@mindmap.mindmap],
    "mindmap\n  root\n    a",
    @types.RenderOptions::default(),
  )
  assert_eq(inert_problem(result.svg), None)
  assert_eq(
    inert_problem("<svg><script>x</script></svg>"),
    Some("element <script>"),
  )
  assert_eq(
    inert_problem("<svg onload=\"x\"></svg>"),
    Some("attribute onload on <svg>"),
  )
  assert_eq(
    inert_problem("<svg><rect fill=\"url(#x)\"/></svg>"),
    Some("fill=\"url(#x)\""),
  )
  assert_eq(
    inert_problem("<svg><rect x=\"a\"/></svg>"),
    Some("x=\"a\" is not a number"),
  )
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
test "text, ids and classes are escaped" {
  let result = @core.render(
    [@mindmap.mindmap],
    "mindmap\n  a<b>\"&[<i onload=x>\"&]\n  ::icon(x\" onload=\"y)\n  :::a\"b <c> d=e",
    @types.RenderOptions::default(),
  )
  assert_true(result.svg.contains("data-id=\"a&lt;b&gt;&quot;&amp;\""))
  assert_true(
    result.svg.contains(
      "class=\"pele-node pele-shape-rect pele-root a b c d e\"",
    ),
  )
  assert_false(result.svg.contains("<i"))
}

///|
test "hostile option values stay inert" {
  for payload in payloads {
    let options = {
      ..@types.RenderOptions::default(),
      id_prefix: Some(payload),
      font_family: Some(payload),
    }
    let (drawn, problem) = check(
      "mindmap\n  root\n    a\n    ::icon(x)", options,
    )
    assert_true(drawn)
    assert_eq(problem, None, msg=payload.escape())
  }
}

///|
test "names that are special to JavaScript are ordinary text" {
  let result = @core.render(
    [@mindmap.mindmap],
    "mindmap\n  __proto__\n    constructor\n    :::__proto__ constructor\n    ::icon(__proto__)\n    toString[hasOwnProperty]",
    @types.RenderOptions::default(),
  )
  assert_true(result.svg.contains("data-id=\"__proto__\""))
  assert_true(result.svg.contains("data-id=\"constructor\""))
  assert_true(result.svg.contains("data-id=\"toString\""))
  assert_true(result.svg.contains(">hasOwnProperty</text>"))
}
