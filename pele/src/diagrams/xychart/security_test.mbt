///|
let payloads : Array[String] = [
  "<script>alert(1)</script>", "\"><script>alert(1)</script>", "<img src=x onerror=alert(1)>",
  "<svg onload=alert(1)>", "<a href=\"javascript:alert(1)\">x</a>", "<foreignObject><iframe src=javascript:alert(1)></iframe></foreignObject>",
  "</text></g></svg><script>alert(1)</script>", "javascript:alert(1)", "JaVaScRiPt:alert(1)",
  " javascript:alert(1)", "jav&#x09;ascript:alert(1)", "data:text/html,<script>alert(1)</script>",
  "vbscript:msgbox(1)", "' onload='alert(1)", "\" onmouseover=\"alert(1)", "x\" onclick=\"alert(1)\" y=\"",
  "#60;script#62;alert(1)#60;/script#62;", "#106;avascript:alert(1)", "#34; onload=#34;alert(1)",
  "url#40;javascript:alert#40;1#41;#41;", "red#59;background:url#40;//evil.example/x#41;",
  "&lt;script&gt;alert(1)&lt;/script&gt;", "&#60;script&#62;", "url(javascript:alert(1))",
  "expression(alert(1))", "red;background:url(//evil.example/x)", "red\" onload=\"alert(1)",
  "]]><script>alert(1)</script>", "--><script>alert(1)</script>", "\u{0}\u{1}\u{8}\u{b}\u{1f}",
  "__proto__", "constructor", "toString", "hasOwnProperty", "{{7*7}}", "${alert(1)}",
  "%0ajavascript:alert(1)", "file:///etc/passwd", "//evil.example/share", "\\\\evil.example\\share",
  "smb://evil.example/share", "obsidian://open?vault=x", "\\\"><script>",
]

///|
let elements : Array[String] = [
  "svg", "g", "rect", "circle", "path", "text", "tspan", "title", "desc",
]

///|
let attributes : Array[String] = [
  "xmlns", "class", "viewBox", "width", "height", "style", "font-family", "font-size",
  "font-weight", "font-style", "fill", "fill-opacity", "opacity", "stroke", "stroke-width",
  "stroke-linecap", "stroke-linejoin", "role", "aria-roledescription", "aria-labelledby",
  "aria-describedby", "id", "data-id", "transform", "x", "y", "rx", "r", "cx", "cy",
  "d", "text-anchor", "xml:space",
]

///|
/// The first thing about the markup that is not drawing: an element or attribute outside the
/// ones an XY chart uses, a value that can load something, or a tag that does not close.
fn problem(svg : String) -> String? {
  let mut at = @util.index_of(svg, "<")
  while at != -1 {
    let close = @util.index_of(svg, ">", from=at)
    if close == -1 {
      return Some("a tag that is not closed")
    }
    let tag = @util.slice(svg, at + 1, end=close)
    if tag.has_prefix("/") {
      at = @util.index_of(svg, "<", from=close)
      continue
    }
    let space = @util.index_of(tag, " ")
    let name_end = if space == -1 { tag.length() } else { space }
    let name = @util.slice(tag, 0, end=name_end)
    if !elements.contains(name) {
      return Some("element <\{name}>")
    }
    let mut i = name_end
    while i < tag.length() {
      if @util.code_at(tag, i) == 32 || @util.code_at(tag, i) == 47 {
        i += 1
        continue
      }
      let eq = @util.index_of(tag, "=\"", from=i)
      if eq == -1 {
        return Some("an attribute without a value in <\{name}>")
      }
      let attribute = @util.slice(tag, i, end=eq)
      if !attributes.contains(attribute) {
        return Some("attribute \{attribute} on <\{name}>")
      }
      let end = @util.index_of(tag, "\"", from=eq + 2)
      if end == -1 {
        return Some("a value that is not closed in <\{name}>")
      }
      let value = @util.slice(tag, eq + 2, end~)
      if attribute == "style" && (value.contains("url(") || value.contains("{")) {
        return Some("style=\"\{value}\"")
      }
      if (
          attribute == "fill" ||
          attribute == "stroke" ||
          attribute == "font-family"
        ) &&
        (value.contains("url(") || value.contains("javascript:")) {
        return Some("\{attribute}=\"\{value}\"")
      }
      i = end + 1
    }
    at = @util.index_of(svg, "<", from=close)
  }
  None
}

///|
fn check(
  source : String,
  options~ : @types.RenderOptions = @types.RenderOptions::default(),
) -> Bool raise {
  let result = @core.render([@xychart.xychart], source, options) catch {
    @errors.PeleError(_) => return false
  }
  if problem(result.svg) is Some(found) {
    fail("\{found} for \{source.escape()}")
  }
  true
}

///|
fn templates(p : String) -> Array[String] {
  [
    "xychart\n  title \"\{p}\"\n  line [1, 2]",
    "xychart\n  title \{p}\n  line [1, 2]",
    "xychart\n  x-axis \"\{p}\" [\"\{p}\", \"b\"]\n  bar [1, 2]",
    "xychart\n  x-axis \{p} [\{p}, b]\n  bar [1, 2]",
    "xychart\n  x-axis \"\{p}\" 1 --> 5\n  line [1, 2]",
    "xychart\n  x-axis \{p} --> \{p}\n  line [1, 2]",
    "xychart\n  y-axis \"\{p}\"\n  line [1, 2]",
    "xychart\n  y-axis \"\{p}\" 0 --> 10\n  bar [1, 2]",
    "xychart\n  y-axis \{p} --> \{p}\n  bar [1, 2]",
    "xychart\n  line \"\{p}\" [1, 2]\n  bar \"\{p}\" [2, 1]",
    "xychart\n  line \{p} [1, 2]",
    "xychart\n  line [1 \"\{p}\", 2 \"\{p}\"]",
    "xychart horizontal\n  x-axis [\"\{p}\", \"b\"]\n  line \"\{p}\" [1 \"\{p}\", 2]\n  bar [3, 4]",
    "xychart\n  line [\{p}, 2]",
    "xychart\n  bar [1, \{p}]",
    "xychart \{p}\n  line [1, 2]",
    "xychart\n  accTitle: \{p}\n  accDescr: \{p}\n  line [1, 2]",
    "xychart\n  accDescr {\n \{p}\n }\n  line [1, 2]",
    "---\ntitle: \"\{p}\"\n---\nxychart\n  line [1, 2]",
    "---\nconfig:\n  xyChart:\n    width: \"\{p}\"\n    height: \"\{p}\"\n    chartOrientation: \"\{p}\"\n    showDataLabel: \"\{p}\"\n    showTitle: \"\{p}\"\n    xAxis:\n      showLabel: \"\{p}\"\n      showTick: \"\{p}\"\n    yAxis: \"\{p}\"\n---\nxychart\n  title t\n  x-axis x [a, b]\n  y-axis y\n  bar \"s\" [1, 2]",
    "---\nconfig:\n  xyChart: \"\{p}\"\n---\nxychart\n  line [1, 2]",
    "---\nconfig:\n  xyChart:\n    xAxis: [\"\{p}\"]\n    yAxis:\n      \"\{p}\": true\n---\nxychart\n  line [1, 2]",
    "%%{init: {\"xyChart\": {\"width\": \"\{p}\", \"showDataLabel\": true}, \"themeVariables\": {\"xyChart\": {\"plotColorPalette\": \"\{p}\"}}}}%%\nxychart\n  bar [1, 2]",
    "xychart\n  %% \{p}\n  line [1, 2]",
  ]
}

///|
test "hostile text is inert in every position" {
  let mut rendered = 0
  for payload in payloads {
    for source in templates(payload) {
      if check(source) {
        rendered += 1
      }
    }
  }
  assert_true(rendered > 250)
}

///|
test "hostile option values are inert" {
  for payload in payloads {
    let options = {
      ..@types.RenderOptions::default(),
      id_prefix: Some(payload),
      font_family: Some(payload),
    }
    assert_true(check("xychart\n  accTitle: t\n  line \"s\" [1, 2]", options~))
  }
}

///|
test "extreme numbers are drawn or refused" {
  let huge = "9".repeat(400)
  let charts = [
    "xychart\n  line [\{huge}, 1]",
    "xychart\n  bar [-\{huge}, \{huge}]\n  line [1, 2]",
    "xychart\n  y-axis \{huge} --> -\{huge}\n  bar [1, 2]",
    "xychart\n  y-axis 0 --> \{huge}\n  bar [1, 2]",
    "xychart\n  x-axis \{huge} --> \{huge}\n  line [1, 2]\n  bar [1, 2]",
    "xychart\n  x-axis -\{huge} --> 3\n  line [1, 2]",
    "xychart\n  y-axis 5 --> 5\n  bar [5, 5]",
    "xychart\n  y-axis 9 --> 1\n  x-axis 9 --> 1\n  bar [5, 3]\n  line [2, 8]",
    "xychart\n  bar [0, 0, 0]",
    "xychart\n  line [7]",
    "xychart\n  line [0.0000001, 0.0000002]",
    "xychart\n  bar [99999999999999999999, 1]\n  line [-99999999999999999999]",
    "xychart horizontal\n  x-axis 5 --> 5\n  bar [1]",
  ]
  for chart in charts {
    assert_true(check(chart))
  }
  for
    value in [
      "1e999", "-1", "0", "0.0001", "99999999", "NaN", ".inf", "-.inf", "[1]", "{a: 1}",
      "null",
    ] {
    let source = "---\nconfig:\n  xyChart:\n    width: \{value}\n    height: \{value}\n    showDataLabel: true\n---\nxychart\n  x-axis x [a, b]\n  bar \"s\" [1, 2]"
    assert_true(check(source))
  }
}

///|
test "names that are object keys in pele are plain names" {
  assert_true(
    check(
      "xychart\n  x-axis \"__proto__\" [\"__proto__\", \"constructor\", \"toString\"]\n  bar \"__proto__\" [1, 2, 3]\n  line \"constructor\" [3 \"__proto__\", 2, 1]",
    ),
  )
  assert_true(
    check(
      "---\nconfig:\n  xyChart:\n    __proto__:\n      polluted: true\n    constructor: 1\n---\nxychart\n  line [1, 2]",
    ),
  )
}

///|
test "the check finds markup that is not drawing" {
  inspect(
    problem("<svg><g><path d=\"M0,0\"/></g></svg>").unwrap_or("none"),
    content="none",
  )
  inspect(
    problem("<svg><script>alert(1)</script></svg>").unwrap_or("none"),
    content="element <script>",
  )
  inspect(
    problem("<svg><g onload=\"x\"></g></svg>").unwrap_or("none"),
    content="attribute onload on <g>",
  )
  inspect(
    problem("<svg><g fill=\"url(javascript:x)\"></g></svg>").unwrap_or("none"),
    content="fill=\"url(javascript:x)\"",
  )
}
