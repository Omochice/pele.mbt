// Ported from pele v1.8.0 tests/render/requirement.test.ts; the drawings it checks with patterns are pinned whole where pele's output is short.

///|
fn render(
  source : String,
  max_width? : Double,
) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), max_width, }
  Ok(@core.render([@requirement.requirement], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn svg(source : String, max_width? : Double) -> String {
  match render(source, max_width?) {
    Ok(result) => "\{result.width}x\{result.height} \{result.svg}"
    Err(failure) => failure.message
  }
}

///|
fn drawing(source : String) -> String {
  render(source).unwrap().svg
}

///|
fn count(text : String, part : String) -> Int32 {
  let mut found = 0
  let mut from = 0
  while true {
    let at = @util.index_of(text, part, from~)
    if at == -1 {
      break
    }
    found += 1
    from = at + part.length()
  }
  found
}

///|
const BASIC : String = "requirementDiagram\n\nrequirement test_req {\nid: 1\ntext: the test text.\nrisk: high\nverifymethod: test\n}\n\nelement test_entity {\ntype: simulation\ndocRef: reqs/test_entity\n}\n\ntest_entity - satisfies -> test_req\n"

///|
test "draws a box per requirement and element, with a header and fields" {
  let result = render(BASIC).unwrap()
  inspect(result.kind, content="requirement")
  let out = result.svg
  inspect(
    out.has_prefix(
      "<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-requirement\"",
    ),
    content="true",
  )
  inspect(count(out, "class=\"pele-node pele-requirement\""), content="1")
  inspect(count(out, "class=\"pele-node pele-element\""), content="1")
  inspect(out.contains("data-id=\"test_req\""), content="true")
  inspect(out.contains(">«Requirement»<"), content="true")
  inspect(out.contains(">«Element»<"), content="true")
  for
    text in [
      "ID", "Text", "Risk", "Verification", "Type", "Doc Ref", "1", "the test text.",
      "High", "Test", "simulation", "reqs/test_entity",
    ] {
    assert_true(out.contains(">\{text}<"), msg=text)
  }
  inspect(count(out, "class=\"pele-divider\""), content="2")
}

///|
test "names each requirement type" {
  let kinds = [
    ("requirement", "Requirement"),
    ("functionalRequirement", "Functional Requirement"),
    ("interfaceRequirement", "Interface Requirement"),
    ("performanceRequirement", "Performance Requirement"),
    ("physicalRequirement", "Physical Requirement"),
    ("designConstraint", "Design Constraint"),
  ]
  for kind in kinds {
    let (keyword, name) = kind
    assert_true(
      drawing("requirementDiagram\n\{keyword} r {\n}\n").contains(
        ">«\{name}»<",
      ),
      msg=keyword,
    )
  }
}

///|
test "leaves out empty fields and the divider of an empty body" {
  let out = drawing(
    "requirementDiagram\nrequirement r {\nid: 7\n}\nelement e {\n}\n",
  )
  inspect(out.contains(">ID<"), content="true")
  inspect(out.contains(">Text<"), content="false")
  inspect(out.contains(">Type<"), content="false")
  inspect(count(out, "class=\"pele-divider\""), content="1")
}

///|
test "draws contains with a circled plus and the rest as dashed arrows" {
  let contains = drawing(
    "requirementDiagram\nrequirement a {\n}\nrequirement b {\n}\na - contains -> b\n",
  )
  inspect(
    contains.contains(
      "class=\"pele-edge pele-relationship-contains\" data-id=\"a-b-0\"",
    ),
    content="true",
  )
  inspect(count(contains, "<circle class=\"pele-marker\""), content="1")
  inspect(contains.contains("stroke-dasharray"), content="false")
  inspect(contains.contains(">«contains»<"), content="true")
  for
    kind in ["copies", "derives", "satisfies", "verifies", "refines", "traces"] {
    let out = drawing(
      "requirementDiagram\nrequirement a {\n}\nrequirement b {\n}\na - \{kind} -> b\n",
    )
    assert_true(
      out.contains("class=\"pele-edge pele-relationship-arrow\""),
      msg=kind,
    )
    assert_true(out.contains("stroke-dasharray=\"5 4\""), msg=kind)
    assert_true(out.contains(">«\{kind}»<"), msg=kind)
    assert_false(out.contains("<circle"), msg=kind)
  }
}

///|
test "reads a left arrow as the same relationship written the other way round" {
  let forward = drawing(
    "requirementDiagram\nrequirement a {\n}\nelement b {\n}\nb - satisfies -> a\n",
  )
  let backward = drawing(
    "requirementDiagram\nrequirement a {\n}\nelement b {\n}\na <- satisfies - b\n",
  )
  inspect(backward == forward, content="true")
}

///|
test "lays out along the declared direction" {
  let body = "requirement a {\n}\nrequirement b {\n}\nrequirement c {\n}\na - contains -> b\nb - contains -> c\n"
  let tall = render("requirementDiagram\n\{body}").unwrap()
  let wide = render("requirementDiagram\ndirection LR\n\{body}").unwrap()
  inspect(tall.height > tall.width, content="true")
  inspect(wide.width > wide.height, content="true")
  inspect(
    drawing("requirementDiagram\ndirection BT\n\{body}") != tall.svg,
    content="true",
  )
  inspect(
    drawing("requirementDiagram\ndirection RL\n\{body}") != wide.svg,
    content="true",
  )
}

///|
test "does not draw a relationship whose end is not defined" {
  let out = drawing(
    "requirementDiagram\nrequirement a {\n}\na - contains -> missing\n",
  )
  inspect(out.contains("pele-edge"), content="false")
  inspect(out.contains("missing"), content="false")
}

///|
test "wraps long text and grows the box to hold it" {
  let short = render("requirementDiagram\nrequirement a {\ntext: short\n}\n").unwrap()
  let long = render(
    "requirementDiagram\nrequirement a {\ntext: \"\{"many words in a row ".repeat(12)}\"\n}\n",
  ).unwrap()
  inspect(long.height > short.height + 60, content="true")
  inspect(long.width < 420, content="true")
}

///|
test "rejects what Mermaid rejects" {
  for
    source in [
      "requirementDiagram\nrequirement a {\nid: REQ-1\n}\n", "requirementDiagram\nrequirement a { \n}\n",
      "requirementDiagram\nrequirement a {\ntext: test the thing\n}\n", "requirementDiagram\na - contains - b\n",
      "requirementDiagram\nstyle a stroke-width:1.5px\n", "requirementDiagram\ntitle My diagram\n",
      "requirement a {\n}\n",
    ] {
    assert_true(render(source) is Err(_), msg=source)
  }
  let message = svg("requirementDiagram\nrequirement a {\nid: REQ-1\n}\n")
  inspect(message.contains("Expecting 'NEWLINE', got 'LINE'"), content="true")
}

///|
test "refuses a diagram that copies class styles without bound" {
  let source = "requirementDiagram\nrequirement a {\n}\nclassDef c " +
    "a:b,".repeat(2000) +
    "a:b\n" +
    "class a c\n".repeat(600)
  inspect(svg(source).contains("too many style declarations"), content="true")
}

///|
test "draws a requirement satisfied by an element" {
  inspect(
    svg(
      "requirementDiagram\n\nrequirement test_req {\nid: 1\ntext: the test text.\nrisk: high\nverifymethod: test\n}\n\nelement test_entity {\ntype: simulation\ndocRef: reqs/test_entity\n}\n\ntest_entity - satisfies -> test_req\n",
    ),
    content="202x401 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-requirement\" viewBox=\"0 0 202 401\" width=\"202\" height=\"401\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_hw:var(--pele-heading-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"requirement\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-relationship-arrow\" data-id=\"test_entity-test_req-0\"><path d=\"M100.76,137L100.76,218\" stroke-dasharray=\"5 4\"/><path class=\"pele-marker\" d=\"M96.26,209L100.76,218L105.26,209\" stroke-linejoin=\"round\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\" fill=\"var(--_m)\"><g class=\"pele-edge-label\" data-id=\"test_entity-test_req-0\"><rect x=\"63.35\" y=\"167\" width=\"74.81\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"100.76\" y=\"182.4\" text-anchor=\"middle\">«satisfies»</text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-requirement\" data-id=\"test_req\" transform=\"translate(100.76,305.5)\"><rect x=\"-92.76\" y=\"-87.5\" width=\"185.52\" height=\"175\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-stereotype\" font-size=\"14\" fill=\"var(--_m)\" x=\"0\" y=\"-62.1\" text-anchor=\"middle\">«Requirement»</text><text class=\"pele-label\" font-size=\"16\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"-38.9\">test_req</tspan></text><path class=\"pele-divider\" d=\"M-92.76,-22.5H92.76\" stroke=\"var(--_b)\"/><g class=\"pele-fields\" font-size=\"14\"><text class=\"pele-field\" fill=\"var(--_m)\" text-anchor=\"start\" xml:space=\"preserve\"><tspan x=\"-78.76\" y=\"2.9\">ID</tspan></text><text class=\"pele-value\" text-anchor=\"start\" xml:space=\"preserve\"><tspan x=\"2.49\" y=\"2.9\">1</tspan></text><text class=\"pele-field\" fill=\"var(--_m)\" text-anchor=\"start\" xml:space=\"preserve\"><tspan x=\"-78.76\" y=\"25.9\">Text</tspan></text><text class=\"pele-value\" text-anchor=\"start\" xml:space=\"preserve\"><tspan x=\"2.49\" y=\"25.9\">the test text.</tspan></text><text class=\"pele-field\" fill=\"var(--_m)\" text-anchor=\"start\" xml:space=\"preserve\"><tspan x=\"-78.76\" y=\"48.9\">Risk</tspan></text><text class=\"pele-value\" text-anchor=\"start\" xml:space=\"preserve\"><tspan x=\"2.49\" y=\"48.9\">High</tspan></text><text class=\"pele-field\" fill=\"var(--_m)\" text-anchor=\"start\" xml:space=\"preserve\"><tspan x=\"-78.76\" y=\"71.9\">Verification</tspan></text><text class=\"pele-value\" text-anchor=\"start\" xml:space=\"preserve\"><tspan x=\"2.49\" y=\"71.9\">Test</tspan></text></g></g><g class=\"pele-node pele-element\" data-id=\"test_entity\" transform=\"translate(100.76,72.5)\"><rect x=\"-92.75\" y=\"-64.5\" width=\"185.5\" height=\"129\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-stereotype\" font-size=\"14\" fill=\"var(--_m)\" x=\"0\" y=\"-39.1\" text-anchor=\"middle\">«Element»</text><text class=\"pele-label\" font-size=\"16\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"-15.9\">test_entity</tspan></text><path class=\"pele-divider\" d=\"M-92.75,0.5H92.75\" stroke=\"var(--_b)\"/><g class=\"pele-fields\" font-size=\"14\"><text class=\"pele-field\" fill=\"var(--_m)\" text-anchor=\"start\" xml:space=\"preserve\"><tspan x=\"-78.75\" y=\"25.9\">Type</tspan></text><text class=\"pele-value\" text-anchor=\"start\" xml:space=\"preserve\"><tspan x=\"-16.18\" y=\"25.9\">simulation</tspan></text><text class=\"pele-field\" fill=\"var(--_m)\" text-anchor=\"start\" xml:space=\"preserve\"><tspan x=\"-78.75\" y=\"48.9\">Doc Ref</tspan></text><text class=\"pele-value\" text-anchor=\"start\" xml:space=\"preserve\"><tspan x=\"-16.18\" y=\"48.9\">reqs/test_entity</tspan></text></g></g></g></svg>",
  )
}

///|
test "draws a self relationship beside a node and parallel relationships apart" {
  inspect(
    svg(
      "requirementDiagram\nrequirement a {\n}\nrequirement b {\n}\na - contains -> a\na - traces -> b\na - refines -> b\n",
    ),
    content="354x227 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-requirement\" viewBox=\"0 0 354 227\" width=\"354\" height=\"227\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_hw:var(--pele-heading-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"requirement\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-relationship-contains\" data-id=\"a-a-0\"><path d=\"M250.75,28.5C273.42,28.5 273.42,52.5 238.75,52.5\"/><circle class=\"pele-marker\" cx=\"244.75\" cy=\"28.5\" r=\"6\"/><path class=\"pele-marker\" d=\"M250.75,28.5L238.75,28.5M244.75,34.5L244.75,22.5\"/></g><g class=\"pele-edge pele-relationship-arrow\" data-id=\"a-b-1\"><path d=\"M162.56,73C162.56,87 134.41,87 134.41,101L134.41,126C134.41,140 162.56,140 162.56,154\" stroke-dasharray=\"5 4\"/><path class=\"pele-marker\" d=\"M158.06,145L162.56,154L167.06,145\" stroke-linejoin=\"round\"/></g><g class=\"pele-edge pele-relationship-arrow\" data-id=\"a-b-2\"><path d=\"M190.56,73C190.56,87 218.72,87 218.72,101L218.72,126C218.72,140 190.56,140 190.56,154\" stroke-dasharray=\"5 4\"/><path class=\"pele-marker\" d=\"M186.06,145L190.56,154L195.06,145\" stroke-linejoin=\"round\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\" fill=\"var(--_m)\"><g class=\"pele-edge-label\" data-id=\"a-a-0\"><rect x=\"270.75\" y=\"30\" width=\"76.38\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"308.94\" y=\"45.4\" text-anchor=\"middle\">«contains»</text></g><g class=\"pele-edge-label\" data-id=\"a-b-1\"><rect x=\"103.23\" y=\"103\" width=\"62.36\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"134.41\" y=\"118.4\" text-anchor=\"middle\">«traces»</text></g><g class=\"pele-edge-label\" data-id=\"a-b-2\"><rect x=\"185.59\" y=\"103\" width=\"66.25\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"218.72\" y=\"118.4\" text-anchor=\"middle\">«refines»</text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-requirement\" data-id=\"a\" transform=\"translate(176.56,40.5)\"><rect x=\"-62.19\" y=\"-32.5\" width=\"124.38\" height=\"65\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-stereotype\" font-size=\"14\" fill=\"var(--_m)\" x=\"0\" y=\"-7.1\" text-anchor=\"middle\">«Requirement»</text><text class=\"pele-label\" font-size=\"16\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"16.1\">a</tspan></text></g><g class=\"pele-node pele-requirement\" data-id=\"b\" transform=\"translate(176.56,186.5)\"><rect x=\"-62.19\" y=\"-32.5\" width=\"124.38\" height=\"65\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-stereotype\" font-size=\"14\" fill=\"var(--_m)\" x=\"0\" y=\"-7.1\" text-anchor=\"middle\">«Requirement»</text><text class=\"pele-label\" font-size=\"16\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"16.1\">b</tspan></text></g></g></svg>",
  )
}

///|
test "draws self relationships below a node when the diagram runs across" {
  inspect(
    svg(
      "requirementDiagram\ndirection LR\nrequirement a {\n}\nrequirement b {\n}\na - contains -> a\na - verifies -> a\na - contains -> b\n",
    ),
    content="402x301 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-requirement\" viewBox=\"0 0 402 301\" width=\"402\" height=\"301\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_hw:var(--pele-heading-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"requirement\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-relationship-contains\" data-id=\"a-a-0\"><path d=\"M58.19,195C58.19,217.67 82.19,217.67 82.19,183\"/><circle class=\"pele-marker\" cx=\"58.19\" cy=\"189\" r=\"6\"/><path class=\"pele-marker\" d=\"M58.19,195L58.19,183M52.19,189L64.19,189\"/></g><g class=\"pele-edge pele-relationship-arrow\" data-id=\"a-a-1\"><path d=\"M52.19,183C52.19,228.33 88.19,228.33 88.19,183\" stroke-dasharray=\"5 4\"/><path class=\"pele-marker\" d=\"M92.69,192L88.19,183L83.69,192\" stroke-linejoin=\"round\"/></g><g class=\"pele-edge pele-relationship-contains\" data-id=\"a-b-2\"><path d=\"M144.38,150.5L268.75,150.5\"/><circle class=\"pele-marker\" cx=\"138.38\" cy=\"150.5\" r=\"6\"/><path class=\"pele-marker\" d=\"M144.38,150.5L132.38,150.5M138.38,156.5L138.38,144.5\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\" fill=\"var(--_m)\"><g class=\"pele-edge-label\" data-id=\"a-a-0\"><rect x=\"32\" y=\"215\" width=\"76.38\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"70.19\" y=\"230.4\" text-anchor=\"middle\">«contains»</text></g><g class=\"pele-edge-label\" data-id=\"a-a-1\"><rect x=\"35.9\" y=\"223\" width=\"68.58\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"70.19\" y=\"238.4\" text-anchor=\"middle\">«verifies»</text></g><g class=\"pele-edge-label\" data-id=\"a-b-2\"><rect x=\"162.38\" y=\"140\" width=\"76.38\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"200.56\" y=\"155.4\" text-anchor=\"middle\">«contains»</text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-requirement\" data-id=\"a\" transform=\"translate(70.19,150.5)\"><rect x=\"-62.19\" y=\"-32.5\" width=\"124.38\" height=\"65\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-stereotype\" font-size=\"14\" fill=\"var(--_m)\" x=\"0\" y=\"-7.1\" text-anchor=\"middle\">«Requirement»</text><text class=\"pele-label\" font-size=\"16\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"16.1\">a</tspan></text></g><g class=\"pele-node pele-requirement\" data-id=\"b\" transform=\"translate(330.94,150.5)\"><rect x=\"-62.19\" y=\"-32.5\" width=\"124.38\" height=\"65\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-stereotype\" font-size=\"14\" fill=\"var(--_m)\" x=\"0\" y=\"-7.1\" text-anchor=\"middle\">«Requirement»</text><text class=\"pele-label\" font-size=\"16\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"16.1\">b</tspan></text></g></g></svg>",
  )
}

///|
test "spreads the ends of edges that share a side" {
  inspect(
    svg(
      "requirementDiagram\nrequirement a {\n}\nrequirement b {\n}\nrequirement c {\n}\na - contains -> b\na - contains -> c\n",
    ),
    content="305x227 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-requirement\" viewBox=\"0 0 305 227\" width=\"305\" height=\"227\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_hw:var(--pele-heading-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"requirement\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-relationship-contains\" data-id=\"a-b-0\"><path d=\"M138.38,85L138.38,89C138.38,95 70.19,95 70.19,101L70.19,154\"/><circle class=\"pele-marker\" cx=\"138.38\" cy=\"79\" r=\"6\"/><path class=\"pele-marker\" d=\"M138.38,85L138.38,73M132.38,79L144.38,79\"/></g><g class=\"pele-edge pele-relationship-contains\" data-id=\"a-c-1\"><path d=\"M166.38,85L166.38,89C166.38,95 234.56,95 234.56,101L234.56,154\"/><circle class=\"pele-marker\" cx=\"166.38\" cy=\"79\" r=\"6\"/><path class=\"pele-marker\" d=\"M166.38,85L166.38,73M160.38,79L172.38,79\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\" fill=\"var(--_m)\"><g class=\"pele-edge-label\" data-id=\"a-b-0\"><rect x=\"32\" y=\"103\" width=\"76.38\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"70.19\" y=\"118.4\" text-anchor=\"middle\">«contains»</text></g><g class=\"pele-edge-label\" data-id=\"a-c-1\"><rect x=\"196.38\" y=\"103\" width=\"76.38\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"234.56\" y=\"118.4\" text-anchor=\"middle\">«contains»</text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-requirement\" data-id=\"a\" transform=\"translate(152.38,40.5)\"><rect x=\"-62.19\" y=\"-32.5\" width=\"124.38\" height=\"65\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-stereotype\" font-size=\"14\" fill=\"var(--_m)\" x=\"0\" y=\"-7.1\" text-anchor=\"middle\">«Requirement»</text><text class=\"pele-label\" font-size=\"16\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"16.1\">a</tspan></text></g><g class=\"pele-node pele-requirement\" data-id=\"b\" transform=\"translate(70.19,186.5)\"><rect x=\"-62.19\" y=\"-32.5\" width=\"124.38\" height=\"65\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-stereotype\" font-size=\"14\" fill=\"var(--_m)\" x=\"0\" y=\"-7.1\" text-anchor=\"middle\">«Requirement»</text><text class=\"pele-label\" font-size=\"16\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"16.1\">b</tspan></text></g><g class=\"pele-node pele-requirement\" data-id=\"c\" transform=\"translate(234.56,186.5)\"><rect x=\"-62.19\" y=\"-32.5\" width=\"124.38\" height=\"65\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-stereotype\" font-size=\"14\" fill=\"var(--_m)\" x=\"0\" y=\"-7.1\" text-anchor=\"middle\">«Requirement»</text><text class=\"pele-label\" font-size=\"16\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"16.1\">c</tspan></text></g></g></svg>",
  )
}

///|
test "picks a contrasting text color on fills a style sets" {
  let drawn = drawing(
    "requirementDiagram\nrequirement a {\nid: 1\ntext: words\n}\nelement b {\ntype: t\n}\nelement c {\n}\nstyle a fill:#1f3a5f\nstyle b fill:#1f3a5f,color:#eee\n",
  )
  let node = (id : String) => {
    let at = @util.index_of(drawn, "data-id=\"\{id}\"")
    @util.slice(drawn, at, end=@util.index_of(drawn, "</g></g>", from=at))
  }
  let tag = (part : String, text : String) => {
    let at = @util.index_of(text, "<text class=\"\{part}\"")
    @util.slice(text, at, end=@util.index_of(text, ">", from=at) + 1)
  }
  for part in ["pele-stereotype", "pele-label", "pele-field", "pele-value"] {
    assert_true(
      tag(part, node("a")).contains(" fill=\"var(--pele-fg-on-dark,#fff)\""),
      msg=part,
    )
  }
  assert_true(tag("pele-label", node("b")).contains(" style=\"fill:#eee;\""))
  assert_false(node("b").contains("--pele-fg-on"))
  assert_true(tag("pele-stereotype", node("c")).contains(" fill=\"var(--_m)\""))
}

///|
test "reads markdown emphasis in names and values" {
  inspect(
    svg(
      "requirementDiagram\nrequirement \"__name__\" {\ntext: \"*slanted* and **heavy** words\"\n}\n",
    ),
    content="241x122 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-requirement\" viewBox=\"0 0 241 122\" width=\"241\" height=\"122\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_hw:var(--pele-heading-weight,bold);--_w:var(--pele-bold-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"requirement\"><g class=\"pele-nodes\"><g class=\"pele-node pele-requirement\" data-id=\"__name__\" transform=\"translate(120.21,61)\"><rect x=\"-112.21\" y=\"-53\" width=\"224.42\" height=\"106\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-stereotype\" font-size=\"14\" fill=\"var(--_m)\" x=\"0\" y=\"-27.6\" text-anchor=\"middle\">«Requirement»</text><text class=\"pele-label\" font-size=\"16\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"-4.4\">name</tspan></text><path class=\"pele-divider\" d=\"M-112.21,12H112.21\" stroke=\"var(--_b)\"/><g class=\"pele-fields\" font-size=\"14\"><text class=\"pele-field\" fill=\"var(--_m)\" text-anchor=\"start\" xml:space=\"preserve\"><tspan x=\"-98.21\" y=\"37.4\">Text</tspan></text><text class=\"pele-value\" text-anchor=\"start\" xml:space=\"preserve\"><tspan x=\"-58.98\" y=\"37.4\" font-style=\"italic\">slanted</tspan><tspan> and </tspan><tspan font-weight=\"var(--_w)\">heavy</tspan><tspan> words</tspan></text></g></g></g></svg>",
  )
}

///|
test "styles nodes by style, classDef, class and the ::: shorthand" {
  inspect(
    svg(
      "requirementDiagram\nrequirement a:::hot {\nid: 1\n}\nelement b {\ntype: t\n}\nelement c {\n}\nclassDef hot fill:#f96,stroke:#333,stroke-width:4px\nclassDef cold color:blue\nclass b cold\nc:::hot,cold\nstyle c stroke:#0a0\n",
    ),
    content=(
      #|461x122 <svg xmlns="http://www.w3.org/2000/svg" class="pele pele-requirement" viewBox="0 0 461 122" width="461" height="122" style="max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_hw:var(--pele-heading-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)" fill="var(--_fg)" role="graphics-document document" aria-roledescription="requirement"><g class="pele-nodes"><g class="pele-node pele-requirement hot" data-id="a" transform="translate(70.19,61)"><rect x="-62.19" y="-53" width="124.38" height="106" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r);fill:#f96;stroke:#333;stroke-width:4px;"/><text class="pele-stereotype" font-size="14" fill="var(--pele-fg-on-light,#1f1f1f)" x="0" y="-27.6" text-anchor="middle">«Requirement»</text><text class="pele-label" font-size="16" font-weight="var(--_hw)" fill="var(--pele-fg-on-light,#1f1f1f)" text-anchor="middle" xml:space="preserve"><tspan x="0" y="-4.4">a</tspan></text><path class="pele-divider" d="M-62.19,12H62.19" stroke="var(--_b)" style="stroke:#333;stroke-width:4px;"/><g class="pele-fields" font-size="14"><text class="pele-field" fill="var(--pele-fg-on-light,#1f1f1f)" text-anchor="start" xml:space="preserve"><tspan x="-48.19" y="37.4">ID</tspan></text><text class="pele-value" fill="var(--pele-fg-on-light,#1f1f1f)" text-anchor="start" xml:space="preserve"><tspan x="-22.19" y="37.4">1</tspan></text></g></g><g class="pele-node pele-element cold" data-id="b" transform="translate(232.38,61)"><rect x="-60" y="-53" width="120" height="106" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-stereotype" font-size="14" fill="var(--_m)" style="fill:blue;" x="0" y="-27.6" text-anchor="middle">«Element»</text><text class="pele-label" font-size="16" font-weight="var(--_hw)" style="fill:blue;" text-anchor="middle" xml:space="preserve"><tspan x="0" y="-4.4">b</tspan></text><path class="pele-divider" d="M-60,12H60" stroke="var(--_b)"/><g class="pele-fields" font-size="14"><text class="pele-field" fill="var(--_m)" style="fill:blue;" text-anchor="start" xml:space="preserve"><tspan x="-46" y="37.4">Type</tspan></text><text class="pele-value" style="fill:blue;" text-anchor="start" xml:space="preserve"><tspan x="-2.88" y="37.4">t</tspan></text></g></g><g class="pele-node pele-element hot cold" data-id="c" transform="translate(392.38,61)"><rect x="-60" y="-32.5" width="120" height="65" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r);fill:#f96;stroke:#0a0;stroke-width:4px;"/><text class="pele-stereotype" font-size="14" fill="var(--_m)" style="fill:blue;" x="0" y="-7.1" text-anchor="middle">«Element»</text><text class="pele-label" font-size="16" font-weight="var(--_hw)" style="fill:blue;" text-anchor="middle" xml:space="preserve"><tspan x="0" y="16.1">c</tspan></text></g></g></svg>
    ),
  )
}

///|
test "draws the front matter title and the accessible names" {
  inspect(
    svg(
      "---\ntitle: Checkout\n---\nrequirementDiagram\naccTitle: Short name\naccDescr: Longer text\nrequirement a {\n}\n",
    ),
    content="141x117 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-requirement\" viewBox=\"0 0 141 117\" width=\"141\" height=\"117\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_tw:var(--pele-title-weight,bold);--_hw:var(--pele-heading-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"requirement\" aria-labelledby=\"pele-title\" aria-describedby=\"pele-desc\"><title id=\"pele-title\">Short name</title><desc id=\"pele-desc\">Longer text</desc><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"70.5\" y=\"25.6\">Checkout</tspan></text><g class=\"pele-nodes\"><g class=\"pele-node pele-requirement\" data-id=\"a\" transform=\"translate(70.19,76.5)\"><rect x=\"-62.19\" y=\"-32.5\" width=\"124.38\" height=\"65\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-stereotype\" font-size=\"14\" fill=\"var(--_m)\" x=\"0\" y=\"-7.1\" text-anchor=\"middle\">«Requirement»</text><text class=\"pele-label\" font-size=\"16\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"16.1\">a</tspan></text></g></g></svg>",
  )
}

///|
test "turns a diagram that runs across to run down when it does not fit" {
  inspect(
    svg(
      "requirementDiagram\ndirection LR\nrequirement a {\n}\nrequirement b {\n}\nrequirement c {\n}\na - contains -> b\nb - contains -> c\n",
      max_width=400,
    ),
    content="141x373 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-requirement\" viewBox=\"0 0 141 373\" width=\"141\" height=\"373\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_hw:var(--pele-heading-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"requirement\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-relationship-contains\" data-id=\"a-b-0\"><path d=\"M70.19,85L70.19,154\"/><circle class=\"pele-marker\" cx=\"70.19\" cy=\"79\" r=\"6\"/><path class=\"pele-marker\" d=\"M70.19,85L70.19,73M64.19,79L76.19,79\"/></g><g class=\"pele-edge pele-relationship-contains\" data-id=\"b-c-1\"><path d=\"M70.19,231L70.19,300\"/><circle class=\"pele-marker\" cx=\"70.19\" cy=\"225\" r=\"6\"/><path class=\"pele-marker\" d=\"M70.19,231L70.19,219M64.19,225L76.19,225\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\" fill=\"var(--_m)\"><g class=\"pele-edge-label\" data-id=\"a-b-0\"><rect x=\"32\" y=\"103\" width=\"76.38\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"70.19\" y=\"118.4\" text-anchor=\"middle\">«contains»</text></g><g class=\"pele-edge-label\" data-id=\"b-c-1\"><rect x=\"32\" y=\"249\" width=\"76.38\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"70.19\" y=\"264.4\" text-anchor=\"middle\">«contains»</text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-requirement\" data-id=\"a\" transform=\"translate(70.19,40.5)\"><rect x=\"-62.19\" y=\"-32.5\" width=\"124.38\" height=\"65\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-stereotype\" font-size=\"14\" fill=\"var(--_m)\" x=\"0\" y=\"-7.1\" text-anchor=\"middle\">«Requirement»</text><text class=\"pele-label\" font-size=\"16\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"16.1\">a</tspan></text></g><g class=\"pele-node pele-requirement\" data-id=\"b\" transform=\"translate(70.19,186.5)\"><rect x=\"-62.19\" y=\"-32.5\" width=\"124.38\" height=\"65\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-stereotype\" font-size=\"14\" fill=\"var(--_m)\" x=\"0\" y=\"-7.1\" text-anchor=\"middle\">«Requirement»</text><text class=\"pele-label\" font-size=\"16\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"16.1\">b</tspan></text></g><g class=\"pele-node pele-requirement\" data-id=\"c\" transform=\"translate(70.19,332.5)\"><rect x=\"-62.19\" y=\"-32.5\" width=\"124.38\" height=\"65\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-stereotype\" font-size=\"14\" fill=\"var(--_m)\" x=\"0\" y=\"-7.1\" text-anchor=\"middle\">«Requirement»</text><text class=\"pele-label\" font-size=\"16\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"16.1\">c</tspan></text></g></g></svg>",
  )
}

///|
test "draws an empty diagram" {
  inspect(
    svg("requirementDiagram\n"),
    content="16x16 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-requirement\" viewBox=\"0 0 16 16\" width=\"16\" height=\"16\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"requirement\"><g class=\"pele-nodes\"></g></svg>",
  )
}
