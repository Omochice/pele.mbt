///|
fn render(source : String) -> @types.RenderResult raise @errors.PeleError {
  @core.render([@info.info], source, @types.RenderOptions::default())
}

///|
test "draws Pele's version" {
  let result = render("info")
  inspect(result.kind, content="info")
  inspect(result.width, content="97")
  inspect(result.height, content="40")
  assert_true(result.svg.contains(">Pele v1.8.0<"))
  assert_true(result.svg.contains("class=\"pele-version\""))
}

///|
test "draws the same with and without showInfo" {
  assert_eq(render("info\nshowInfo\n").svg, render("info").svg)
}

///|
test "draws a title from the front matter" {
  let result = render("---\ntitle: From front matter\n---\ninfo")
  inspect(result.width, content="151")
  inspect(result.height, content="72")
  inspect(
    result.svg,
    content="<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-info\" viewBox=\"0 0 151 72\" width=\"151\" height=\"72\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"info\"><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"75.5\" y=\"25.6\">From front matter</tspan></text><text class=\"pele-version\" fill=\"var(--_m)\" x=\"75.5\" y=\"57.6\" text-anchor=\"middle\">Pele v1.8.0</text></svg>",
  )
}

///|
test "the diagram's own title replaces the front matter title" {
  let svg = render("---\ntitle: From front matter\n---\ninfo\ntitle Own").svg
  assert_true(svg.contains(">Own<"))
  assert_false(svg.contains("From front matter"))
}

///|
test "writes accessible names" {
  let svg = render("info showInfo\naccTitle: Name\naccDescr: Text").svg
  assert_true(svg.contains("<title id=\"pele-title\">Name</title>"))
  assert_true(svg.contains("<desc id=\"pele-desc\">Text</desc>"))
}

///|
test "rejects anything else after the keyword" {
  let error = render("info unsupported") catch {
    @errors.PeleError(failure) => failure.message
  } noraise {
    _ => "rendered"
  }
  assert_true(error.contains("Lexical error on line 1"))
  let error = render("info\ntitle a\nshowInfo") catch {
    @errors.PeleError(failure) => failure.message
  } noraise {
    _ => "rendered"
  }
  assert_true(error.contains("Parse error on line 3"))
}
