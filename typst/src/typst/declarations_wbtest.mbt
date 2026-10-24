///|
let style_samples : Array[String] = [
  "", ";", "stroke:&amp;&amp;;", "fill:red", " --x:1", "fill:red; --x:1", "a;--",
  "fill:var(--_c)", "rx:4", " rx :4", "ry: 2;fill:red", "rxx:1", "r x:1", "fill:a;rx",
  "x:rx:1", "rx:1;rx:2;ry:3", "COLOR-MIX(in srgb, red, blue)", "fill:Color-Mix(in srgb, red 50%, blue)",
  "color-mix", "a\tb:c", "rx:var(--_r);fill:&amp;&amp;",
]

///|
test "a style is resolved as splitting it into declarations and joining them resolves it" {
  let resolver = Resolver::new("<svg style=\"--_c:#123;--_r:4\"></svg>", {})
  for style in style_samples {
    let kept = []
    for declaration in style.split(";") {
      let declaration = declaration.to_owned()
      if css_trim(declaration).has_prefix("--") {
        continue
      }
      if resolver.substitute(declaration, 0) is Some(resolved) {
        kept.push(resolved)
      }
    }
    assert_eq(resolver.style(style), kept.join(";"))
  }
}

///|
test "radii are hoisted as splitting the style into declarations hoists them" {
  for style in style_samples {
    let radii : Array[(String, String)] = []
    let kept = []
    for declaration in style.split(";") {
      let declaration = declaration.to_owned()
      guard declaration.find(":") is Some(colon) else {
        kept.push(declaration)
        continue
      }
      let property = css_trim(@util.slice(declaration, 0, end=colon))
      guard property == "rx" || property == "ry" else {
        kept.push(declaration)
        continue
      }
      let value = css_trim(@util.slice(declaration, colon + 1))
      match radii.search_by(radius => radius.0 == property) {
        Some(i) => radii[i] = (property, value)
        None => radii.push((property, value))
      }
    }
    let want = if radii.is_empty() {
      [("style", style)]
    } else {
      radii
      .copy()
      ..append(
        if kept.join(";") == "" {
          []
        } else {
          [("style", kept.join(";"))]
        },
      )
    }
    let got = hoist_attributes([{ name: "style", value: style, }]).map(attribute => {
      (attribute.name, attribute.value)
    })
    assert_eq(got, want)
  }
}

///|
test "a mix is found in any letter case" {
  for value in style_samples {
    assert_eq(
      index_ignoring_case(value, "color-mix(", 0) >= 0,
      ascii_lower(value).contains("color-mix("),
    )
  }
}
