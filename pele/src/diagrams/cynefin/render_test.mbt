///|
fn render(source : String, max_width? : Double) -> String {
  let options = { ..@types.RenderOptions::default(), max_width, }
  let result = @core.render([@cynefin.cynefin], source, options) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "\{result.width}x\{result.height} \{result.svg}"
}

///|
fn size(source : String) -> (Double, Double) {
  let result = @core.render(
    [@cynefin.cynefin],
    source,
    @types.RenderOptions::default(),
  ) catch {
    _ => return (0, 0)
  }
  (result.width, result.height)
}

///|
fn count(text : String, needle : String) -> Int32 {
  let mut n = 0
  let mut at = @util.index_of(text, needle)
  while at != -1 {
    n += 1
    at = @util.index_of(text, needle, from=at + needle.length())
  }
  n
}

///|
let basic : String =
  #|cynefin-beta
  #|  title Incident Response
  #|  complex
  #|    "Investigate root cause"
  #|    "Run chaos experiment"
  #|  complicated
  #|    "Expert review needed"
  #|  clear
  #|    "Restart service"
  #|  chaotic
  #|    "Page on-call immediately"
  #|  confusion
  #|    "Unknown failure mode"
  #|

///|
test "draws the five domains, their items, and the boundaries" {
  let svg = render(basic)
  inspect(count(svg, "class=\"pele-cynefin-region\""), content="5")
  inspect(count(svg, "class=\"pele-cynefin-domain\""), content="5")
  inspect(count(svg, "class=\"pele-node\""), content="6")
  for name in ["Complex", "Complicated", "Clear", "Chaotic", "Confusion"] {
    assert_true(svg.contains(">\{name}<"))
  }
  assert_true(svg.contains("Probe → Sense → Respond"))
  assert_true(svg.contains(">Disorder<"))
  assert_true(svg.contains("class=\"pele-cynefin-cliff\""))
  assert_true(svg.contains(">Incident Response<"))
  for i in 1..<=5 {
    assert_true(svg.contains("var(--pele-series-\{i},"))
  }
  assert_false(svg.contains("NaN"))
}

///|
test "draws every domain even when none is declared" {
  let svg = render("cynefin-beta")
  inspect(count(svg, "class=\"pele-cynefin-domain\""), content="5")
  inspect(count(svg, "class=\"pele-node"), content="0")
}

///|
test "draws transitions with arrowheads and labels, and drops self loops" {
  let svg = render(
    "cynefin-beta\ncomplex --> complicated : \"Pattern identified\"\nclear --> chaotic\nclear --> clear : \"ignored\"\ncomplex --> clear : \"diagonal\"\nconfusion --> chaotic\n",
  )
  inspect(count(svg, "class=\"pele-edge\""), content="4")
  inspect(count(svg, "class=\"pele-marker\""), content="4")
  assert_true(svg.contains("data-id=\"complex-complicated\""))
  assert_true(svg.contains(">Pattern identified</text>"))
  assert_false(svg.contains("ignored"))
}

///|
test "caps the confusion list at three items" {
  let svg = render(
    "cynefin-beta\nconfusion\n\"a\"\n\"b\"\n\"c\"\n\"d\"\n\"e\"\n",
  )
  inspect(count(svg, "class=\"pele-node\""), content="3")
  assert_true(svg.contains("class=\"pele-node pele-cynefin-overflow\""))
  assert_true(svg.contains(">+2 more</text>"))
}

///|
test "grows to fit long lists and wraps long labels" {
  let base = size("cynefin-beta\ncomplex\n\"a\"\n")
  let tall = size("cynefin-beta\ncomplex\n" + "\"an item\"\n".repeat(20))
  let words = "word ".repeat(30)
  let wide_source = "cynefin-beta\ncomplex\n\"\{words}\"\n"
  let wide = size(wide_source)
  assert_true(tall.1 > base.1)
  assert_true(wide.0 < base.0 + 200)
  assert_true(count(render(wide_source), "<tspan") > 3)
}

///|
test "honours the options" {
  let base = render(basic)
  let front = body => "---\nconfig:\n  cynefin:\n\{body}---\n\{basic}"
  assert_false(
    render(front("    showDomainDescriptions: false\n")).contains("Probe"),
  )
  let large = size(front("    width: 1200\n    height: 900\n"))
  assert_true(large.0 > size(basic).0)
  assert_true(render(front("    boundaryAmplitude: 0\n")) != base)
  assert_true(render(front("    seed: 5\n")) != render(front("    seed: 6\n")))
  inspect(render(basic) == base, content="true")
}

///|
test "draws titles and accessible names" {
  let svg = render(
    "---\ntitle: Front\n---\ncynefin-beta\naccTitle: Acc\naccDescr: Described\nclear\n\"a\"\n",
  )
  assert_true(svg.contains(">Front<"))
  assert_true(svg.contains("<title id=\"pele-title\">Acc</title>"))
  assert_true(svg.contains("<desc id=\"pele-desc\">Described</desc>"))
  assert_true(
    render("---\ntitle: Front\n---\ncynefin-beta\ntitle Own\n").contains(
      ">Own<",
    ),
  )
}

///|
test "rejects what Mermaid rejects" {
  for
    source in [
      "cynefin-beta\n\"orphan\"", "cynefin-beta\ncomplexity", "cynefin-beta\ncomplex --> nowhere",
      "cynefin-beta\ncomplex --> clear clear", "cynefin-betax",
    ] {
    let result = @core.render(
      [@cynefin.cynefin],
      source,
      @types.RenderOptions::default(),
    ) catch {
      @errors.PeleError(_) => continue
    }
    fail("rendered \{source.escape()}: \{result.svg.length()}")
  }
}

///|
test "the whole drawing of two domains and a transition" {
  inspect(
    render(
      "cynefin-beta\n  complex\n    \"Practice\"\n  complicated\n    \"Analysis\"\n  complex --> complicated : \"Pattern found\"\n",
    ),
    content="656x456 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-cynefin\" viewBox=\"0 0 656 456\" width=\"656\" height=\"456\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_hw:var(--pele-heading-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"cynefin\"><g class=\"pele-cynefin-regions\"><path class=\"pele-cynefin-region\" data-id=\"complex\" d=\"M8,8L329.54,8C334.01,35.5 326.9,35.5 331.38,63C319.77,90.5 339.17,90.5 327.56,118C337.92,145.5 314.98,145.5 325.33,173C324.48,200.5 328.85,200.5 328,228C288,234.26 288,222.73 248,228.99C208,227.74 208,222.27 168,221.01C128,224.75 128,217.73 88,221.47C48,213.17 48,229.44 8,221.14Z\" fill=\"var(--pele-series-1,#4c78a8)\" fill-opacity=\"0.14\"/><path class=\"pele-cynefin-region\" data-id=\"complicated\" d=\"M329.54,8L648,8L648,230.72C608,235.3 608,222.64 568,227.21C528,221.06 528,235.01 488,228.86C448,240.82 448,223.89 408,235.86C368,224.46 368,239.39 328,228C328.85,200.5 324.48,200.5 325.33,173C314.98,145.5 337.92,145.5 327.56,118C339.17,90.5 319.77,90.5 331.38,63C326.9,35.5 334.01,35.5 329.54,8Z\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\"/><path class=\"pele-cynefin-region\" data-id=\"chaotic\" d=\"M8,221.14C48,229.44 48,213.17 88,221.47C128,217.73 128,224.75 168,221.01C208,222.27 208,227.74 248,228.99C288,222.73 288,234.26 328,228C347.2,272 299.2,349 337.6,393C308.8,415 333.76,437 328,448L8,448Z\" fill=\"var(--pele-series-4,#e45756)\" fill-opacity=\"0.14\"/><path class=\"pele-cynefin-region\" data-id=\"clear\" d=\"M328,228C368,239.39 368,224.46 408,235.86C448,223.89 448,240.82 488,228.86C528,235.01 528,221.06 568,227.21C608,222.64 608,235.3 648,230.72L648,448L328,448C333.76,437 308.8,415 337.6,393C299.2,349 347.2,272 328,228Z\" fill=\"var(--pele-series-3,#54a24b)\" fill-opacity=\"0.14\"/></g><g class=\"pele-cynefin-boundaries\" fill=\"none\" stroke=\"var(--_b)\" stroke-dasharray=\"6 3\"><path d=\"M329.54,8C334.01,35.5 326.9,35.5 331.38,63C319.77,90.5 339.17,90.5 327.56,118C337.92,145.5 314.98,145.5 325.33,173C324.48,200.5 328.85,200.5 328,228\"/><path d=\"M8,221.14C48,229.44 48,213.17 88,221.47C128,217.73 128,224.75 168,221.01C208,222.27 208,227.74 248,228.99C288,222.73 288,234.26 328,228\"/><path d=\"M328,228C368,239.39 368,224.46 408,235.86C448,223.89 448,240.82 488,228.86C528,235.01 528,221.06 568,227.21C608,222.64 608,235.3 648,230.72\"/><path class=\"pele-cynefin-cliff\" d=\"M328,228C347.2,272 299.2,349 337.6,393C308.8,415 333.76,437 328,448\" stroke=\"var(--_l)\" stroke-width=\"2\" stroke-dasharray=\"none\" stroke-linecap=\"round\"/></g><path d=\"M240,228A88,64 0 1,1 416,228A88,64 0 1,1 240,228Z\" fill=\"var(--_bg)\"/><path class=\"pele-cynefin-region\" data-id=\"confusion\" d=\"M240,228A88,64 0 1,1 416,228A88,64 0 1,1 240,228Z\" fill=\"var(--pele-series-5,#72b7b2)\" fill-opacity=\"0.18\" stroke=\"var(--_b)\" stroke-dasharray=\"4 2\"/><g class=\"pele-cynefin-domain\" data-id=\"complex\"><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"168\" y=\"84.1\">Complex</tspan></text><text class=\"pele-cynefin-subtitle\" font-size=\"13\" font-style=\"italic\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"168\" y=\"105.05\">Probe → Sense → Respond</tspan></text><text class=\"pele-cynefin-subtitle\" font-size=\"13\" font-style=\"italic\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"168\" y=\"125.05\">Emergent Practices</tspan></text><g class=\"pele-node\" data-id=\"Practice\"><rect x=\"132.72\" y=\"140.5\" width=\"70.57\" height=\"29\" fill=\"var(--_bg)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" font-size=\"14\" x=\"168\" y=\"159.9\" text-anchor=\"middle\">Practice</text></g></g><g class=\"pele-cynefin-domain\" data-id=\"complicated\"><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"488\" y=\"84.1\">Complicated</tspan></text><text class=\"pele-cynefin-subtitle\" font-size=\"13\" font-style=\"italic\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"488\" y=\"105.05\">Sense → Analyse → Respond</tspan></text><text class=\"pele-cynefin-subtitle\" font-size=\"13\" font-style=\"italic\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"488\" y=\"125.05\">Good Practices</tspan></text><g class=\"pele-node\" data-id=\"Analysis\"><rect x=\"451.94\" y=\"140.5\" width=\"72.12\" height=\"29\" fill=\"var(--_bg)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" font-size=\"14\" x=\"488\" y=\"159.9\" text-anchor=\"middle\">Analysis</text></g></g><g class=\"pele-cynefin-domain\" data-id=\"chaotic\"><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"168\" y=\"323.6\">Chaotic</tspan></text><text class=\"pele-cynefin-subtitle\" font-size=\"13\" font-style=\"italic\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"168\" y=\"344.55\">Act → Sense → Respond</tspan></text><text class=\"pele-cynefin-subtitle\" font-size=\"13\" font-style=\"italic\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"168\" y=\"364.55\">Novel Practices</tspan></text></g><g class=\"pele-cynefin-domain\" data-id=\"clear\"><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"488\" y=\"323.6\">Clear</tspan></text><text class=\"pele-cynefin-subtitle\" font-size=\"13\" font-style=\"italic\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"488\" y=\"344.55\">Sense → Categorise → Respond</tspan></text><text class=\"pele-cynefin-subtitle\" font-size=\"13\" font-style=\"italic\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"488\" y=\"364.55\">Best Practices</tspan></text></g><g class=\"pele-cynefin-domain\" data-id=\"confusion\"><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"328\" y=\"223.6\">Confusion</tspan></text><text class=\"pele-cynefin-subtitle\" font-size=\"13\" font-style=\"italic\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"328\" y=\"244.55\">Disorder</tspan></text></g><g class=\"pele-edges\"><g class=\"pele-edge\" data-id=\"complex-complicated\"><path d=\"M252.55,99.34Q325.11,89.07 390.73,97.64\" fill=\"none\" stroke=\"var(--_l)\"/><path class=\"pele-marker\" d=\"M397.67,98.55L389.3,100.85L390.17,94.18Z\" fill=\"var(--_l)\" stroke=\"none\"/><text class=\"pele-edge-label\" font-size=\"13\" x=\"325.11\" y=\"82.56\" text-anchor=\"middle\">Pattern found</text></g></g></svg>",
  )
}

///|
test "the whole drawing of straight boundaries and no descriptions" {
  inspect(
    render(
      "---\nconfig:\n  cynefin:\n    seed: 5\n    boundaryAmplitude: 0\n    showDomainDescriptions: false\n---\ncynefin-beta\nclear\n\"a\"\n",
    ),
    content="656x456 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-cynefin\" viewBox=\"0 0 656 456\" width=\"656\" height=\"456\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_hw:var(--pele-heading-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"cynefin\"><g class=\"pele-cynefin-regions\"><path class=\"pele-cynefin-region\" data-id=\"complex\" d=\"M8,8L328,8C328,35.5 328,35.5 328,63C328,90.5 328,90.5 328,118C328,145.5 328,145.5 328,173C328,200.5 328,200.5 328,228C288,228 288,228 248,228C208,228 208,228 168,228C128,228 128,228 88,228C48,228 48,228 8,228Z\" fill=\"var(--pele-series-1,#4c78a8)\" fill-opacity=\"0.14\"/><path class=\"pele-cynefin-region\" data-id=\"complicated\" d=\"M328,8L648,8L648,228C608,228 608,228 568,228C528,228 528,228 488,228C448,228 448,228 408,228C368,228 368,228 328,228C328,200.5 328,200.5 328,173C328,145.5 328,145.5 328,118C328,90.5 328,90.5 328,63C328,35.5 328,35.5 328,8Z\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\"/><path class=\"pele-cynefin-region\" data-id=\"chaotic\" d=\"M8,228C48,228 48,228 88,228C128,228 128,228 168,228C208,228 208,228 248,228C288,228 288,228 328,228C347.2,272 299.2,349 337.6,393C308.8,415 333.76,437 328,448L8,448Z\" fill=\"var(--pele-series-4,#e45756)\" fill-opacity=\"0.14\"/><path class=\"pele-cynefin-region\" data-id=\"clear\" d=\"M328,228C368,228 368,228 408,228C448,228 448,228 488,228C528,228 528,228 568,228C608,228 608,228 648,228L648,448L328,448C333.76,437 308.8,415 337.6,393C299.2,349 347.2,272 328,228Z\" fill=\"var(--pele-series-3,#54a24b)\" fill-opacity=\"0.14\"/></g><g class=\"pele-cynefin-boundaries\" fill=\"none\" stroke=\"var(--_b)\" stroke-dasharray=\"6 3\"><path d=\"M328,8C328,35.5 328,35.5 328,63C328,90.5 328,90.5 328,118C328,145.5 328,145.5 328,173C328,200.5 328,200.5 328,228\"/><path d=\"M8,228C48,228 48,228 88,228C128,228 128,228 168,228C208,228 208,228 248,228C288,228 288,228 328,228\"/><path d=\"M328,228C368,228 368,228 408,228C448,228 448,228 488,228C528,228 528,228 568,228C608,228 608,228 648,228\"/><path class=\"pele-cynefin-cliff\" d=\"M328,228C347.2,272 299.2,349 337.6,393C308.8,415 333.76,437 328,448\" stroke=\"var(--_l)\" stroke-width=\"2\" stroke-dasharray=\"none\" stroke-linecap=\"round\"/></g><path d=\"M240,228A88,64 0 1,1 416,228A88,64 0 1,1 240,228Z\" fill=\"var(--_bg)\"/><path class=\"pele-cynefin-region\" data-id=\"confusion\" d=\"M240,228A88,64 0 1,1 416,228A88,64 0 1,1 240,228Z\" fill=\"var(--pele-series-5,#72b7b2)\" fill-opacity=\"0.18\" stroke=\"var(--_b)\" stroke-dasharray=\"4 2\"/><g class=\"pele-cynefin-domain\" data-id=\"complex\"><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"168\" y=\"123.6\">Complex</tspan></text></g><g class=\"pele-cynefin-domain\" data-id=\"complicated\"><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"488\" y=\"123.6\">Complicated</tspan></text></g><g class=\"pele-cynefin-domain\" data-id=\"chaotic\"><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"168\" y=\"343.6\">Chaotic</tspan></text></g><g class=\"pele-cynefin-domain\" data-id=\"clear\"><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"488\" y=\"324.1\">Clear</tspan></text><g class=\"pele-node\" data-id=\"a\"><rect x=\"474.11\" y=\"340.5\" width=\"27.78\" height=\"29\" fill=\"var(--_bg)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" font-size=\"14\" x=\"488\" y=\"359.9\" text-anchor=\"middle\">a</text></g></g><g class=\"pele-cynefin-domain\" data-id=\"confusion\"><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"328\" y=\"233.6\">Confusion</tspan></text></g></svg>",
  )
}
