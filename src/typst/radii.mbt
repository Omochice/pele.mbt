///|
fn find_attribute(attributes : Array[Attribute], name : String) -> Int32? {
  for i, attribute in attributes {
    if attribute.name == name {
      return Some(i)
    }
  }
  None
}

///|
/// Moves the corner radii that pele writes in `style` into `rx` and `ry` attributes.
/// typst reads radii only from attributes, so a radius set in `style` draws square corners.
pub fn hoist_radii(svg : String) -> String {
  map_tags(svg, attributes => {
    guard find_attribute(attributes, "style") is Some(at) else {
      return attributes
    }
    let radii : Array[Attribute] = []
    let kept = []
    for declaration in attributes[at].value.split(";") {
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
      let radius = {
        name: property,
        value: css_trim(@util.slice(declaration, colon + 1)),
      }
      match find_attribute(radii, property) {
        Some(i) => radii[i] = radius
        None => radii.push(radius)
      }
    }
    if radii.is_empty() {
      return attributes
    }
    let out = []
    for i, attribute in attributes {
      if i == at {
        for radius in radii {
          if find_attribute(attributes, radius.name) is None {
            out.push(radius)
          }
        }
        let style = kept.join(";")
        if style != "" {
          out.push({ ..attribute, value: style, })
        }
        continue
      }
      match find_attribute(radii, attribute.name) {
        Some(r) => out.push(radii[r])
        None => out.push(attribute)
      }
    }
    out
  })
}
