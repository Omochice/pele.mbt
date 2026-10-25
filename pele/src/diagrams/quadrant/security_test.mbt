///|
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
let elements : Array[String] = [
  "svg", "g", "rect", "circle", "path", "text", "tspan", "title", "desc",
]

///|
let attributes : Array[String] = [
  "xmlns", "class", "viewBox", "width", "height", "style", "font-size", "font-weight",
  "font-style", "fill", "stroke", "stroke-width", "role", "aria-roledescription",
  "aria-labelledby", "aria-describedby", "id", "data-id", "transform", "x", "y",
  "rx", "r", "cx", "cy", "text-anchor", "xml:space",
]

///|
/// The first thing about the markup that is not inert, or `None`.
/// Only drawing elements and presentation attributes may appear, and no value may hold markup or a way to load anything.
fn inert_problem(svg : String) -> String? {
  let mut at = 0
  while true {
    let open = @util.index_of(svg, "<", from=at)
    if open == -1 {
      break
    }
    if @util.code_at(svg, open + 1) == '/'.to_int() {
      let close = @util.index_of(svg, ">", from=open)
      at = close + 1
      continue
    }
    let mut i = open + 1
    while @util.code_at(svg, i) >= 'a'.to_int() &&
          @util.code_at(svg, i) <= 'z'.to_int() {
      i += 1
    }
    let name = @util.slice(svg, open + 1, end=i)
    if !elements.contains(name) {
      return Some("element <\{name}>")
    }
    while true {
      while @util.code_at(svg, i) == ' '.to_int() {
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
      let from = i
      while @util.code_at(svg, i) != '='.to_int() &&
            @util.code_at(svg, i) != '>'.to_int() &&
            @util.code_at(svg, i) >= 0 {
        i += 1
      }
      let attribute = @util.slice(svg, from, end=i)
      if @util.code_at(svg, i) != '='.to_int() ||
        @util.code_at(svg, i + 1) != '"'.to_int() {
        return Some("attribute \{attribute} of <\{name}> has no quoted value")
      }
      if !attributes.contains(attribute) && !attribute.has_prefix("--_") {
        return Some("attribute \{attribute} on <\{name}>")
      }
      let close = @util.index_of(svg, "\"", from=i + 2)
      if close == -1 {
        return Some("attribute \{attribute} is not closed")
      }
      let value = @util.slice(svg, i + 2, end=close)
      if value.contains("<") || value.contains(">") {
        return Some("\{attribute}=\"\{value}\" holds markup")
      }
      if attribute == "style" || attribute == "fill" || attribute == "stroke" {
        let lower = value.to_lower()
        for
          bad in [
            "url(", "expression", "@import", "javascript:", "{", "}", "\\",
          ] {
          if lower.contains(bad) {
            return Some("\{attribute}=\"\{value}\" holds \{bad}")
          }
        }
      }
      i = close + 1
    }
    at = i
  }
  None
}

///|
fn check(source : String, options? : @types.RenderOptions) -> Bool raise {
  match big(source, options?) {
    Ok(result) =>
      match inert_problem(result.svg) {
        Some(problem) => fail("\{problem} for \{source.escape()}")
        None => true
      }
    Err(_) => false
  }
}

///|
let templates : Array[(String) -> String] = [
  p => "quadrantChart\n  title \{p}\n  A: [0.5, 0.5]",
  p => "quadrantChart\n  x-axis \{p} --> \{p}",
  p => "quadrantChart\n  x-axis \"\{p}\" --> \"\{p}\"\n  A: [0.5, 0.5]",
  p => "quadrantChart\n  y-axis \"\{p}\" --> \"\{p}\"",
  p => "quadrantChart\n  y-axis \{p}\n  A: [0.5, 0.5]",
  p => "quadrantChart\n  x-axis \"\{p}\" -->",
  p => "quadrantChart\n  quadrant-1 \{p}\n  quadrant-2 \"\{p}\"",
  p => {
    "quadrantChart\n  quadrant-3 \"`\{p}`\"\n  quadrant-4 \"`**\{p}**`\"\n  A: [0.1, 0.9]"
  },
  p => "quadrantChart\n  \{p}: [0.5, 0.5]",
  p => "quadrantChart\n  \"\{p}\": [0.5, 0.5]",
  p => "quadrantChart\n  \"`\{p}`\": [0.5, 0.5]",
  p => "quadrantChart\n  A:::\{p}: [0.5, 0.5]",
  p => "quadrantChart\n  A:::k: [0.5, 0.5]\n  classDef \{p} color: #f00",
  p => "quadrantChart\n  A:::k: [0.5, 0.5]\n  classDef k color: \{p}",
  p => "quadrantChart\n  A:::k: [0.5, 0.5]\n  classDef k \{p}: 3",
  p => "quadrantChart\n  A: [0.5, 0.5] color: \{p}",
  p => {
    "quadrantChart\n  A: [0.5, 0.5] radius: \{p}, stroke-width: \{p}, stroke-color: \{p}"
  },
  p => "quadrantChart\n  A: [0.5, 0.5] \{p}",
  p => "quadrantChart\n  A: [\{p}, 0.5]",
  p => "quadrantChart\n  A: [0.5, \{p}]",
  p => "quadrantChart\n  accTitle: \{p}\n  accDescr: \{p}\n  A: [0.5, 0.5]",
  p => "quadrantChart\n  accDescr {\n \{p}\n }\n  A: [0.5, 0.5]",
  p => "---\ntitle: \"\{p}\"\n---\nquadrantChart\n  A: [0.5, 0.5]",
  p => {
    "---\nconfig:\n  quadrantChart:\n    chartWidth: \"\{p}\"\n    chartHeight: \"\{p}\"\n    pointRadius: \"\{p}\"\n    quadrantPadding: \"\{p}\"\n    xAxisPosition: \"\{p}\"\n    yAxisPosition: \"\{p}\"\n---\nquadrantChart\n  x-axis a --> b\n  y-axis c --> d\n  A: [0.5, 0.5]"
  },
  p => {
    "---\nconfig:\n  quadrantChart: \"\{p}\"\n---\nquadrantChart\n  A: [0.5, 0.5]"
  },
  p => {
    "%%{init: {\"quadrantChart\": {\"chartWidth\": \"\{p}\", \"titlePadding\": \"\{p}\"}, \"themeVariables\": {\"quadrant1Fill\": \"\{p}\"}}}%%\nquadrantChart\n  title t\n  A: [0.5, 0.5]"
  },
  p => "quadrantChart \{p}\n  A: [0.5, 0.5]",
  p => "quadrantChart\n  %% \{p}\n  A: [0.5, 0.5]",
]

///|
test "the output is inert with hostile text in every position" {
  let mut rendered = 0
  for template in templates {
    for payload in payloads {
      if check(template(payload)) {
        rendered += 1
      }
    }
  }
  inspect(rendered > 250, content="true")
}

///|
test "the output is inert with hostile option values" {
  for payload in payloads {
    let options = {
      ..@types.RenderOptions::default(),
      id_prefix: Some(payload),
      font_family: Some(payload),
    }
    inspect(
      check("quadrantChart\n  accTitle: t\n  A: [0.5, 0.5]", options~),
      content="true",
    )
  }
}

///|
test "the output is inert with extreme numbers" {
  for
    value in [
      ".inf", "-1", "0", "0.0001", "99999999", ".nan", "-.inf", "[1]", "{a: 1}",
      "true", "null",
    ] {
    let keys = [
      "chartWidth", "chartHeight", "titlePadding", "quadrantPadding", "xAxisLabelPadding",
      "yAxisLabelPadding", "quadrantTextTopPadding", "pointTextPadding", "pointRadius",
    ]
    let config = keys.map(key => "    \{key}: \{value}").join("\n")
    let source = "---\nconfig:\n  quadrantChart:\n\{config}\n---\nquadrantChart\n  title t\n  x-axis a --> b\n  y-axis c --> d\n  quadrant-1 q\n  A: [0.5, 0.5]"
    inspect(check(source), content="true")
  }
  inspect(
    check(
      "quadrantChart\n  A: [0.5, 0.5] radius: \{"9".repeat(400)}, stroke-width: \{"9".repeat(400)}px",
    ),
    content="true",
  )
  inspect(
    check("quadrantChart\n  A: [0x5, 0e9]\n  B: [0,5, 0 5]\n  C: [055, 0b1]"),
    content="true",
  )
}

///|
test "names that are object keys in pele are plain names" {
  let source = "quadrantChart\n  __proto__:::__proto__: [0.5, 0.5]\n  constructor:::constructor: [0.1, 0.1]\n  toString:::toString: [0.2, 0.2]\n  classDef constructor radius: 3\n  classDef hasOwnProperty color: #f00"
  let svg = big(source).unwrap().svg
  inspect(count("circle", source), content="3")
  inspect(svg.contains(" r=\"3\""), content="true")
  inspect(svg.contains("[object"), content="false")
}
