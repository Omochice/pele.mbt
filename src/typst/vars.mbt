///|
/// The attributes whose value is CSS.
/// The others, such as `data-id`, `href` or `aria-label`, carry user text, where something that looks like a reference is not one.
let css_attributes : Array[String] = [
  "style", "fill", "stroke", "color", "font-family", "font-size", "font-style", "font-weight",
  "opacity", "fill-opacity", "stroke-opacity", "stroke-width", "stroke-dasharray",
  "stroke-dashoffset", "stop-color", "stop-opacity",
]

///|
/// How many references deep a value may go before it counts as a cycle.
const MAX_DEPTH : Int32 = 32

///|
fn is_css_space(c : Int32) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\u{c}'
}

///|
fn css_trim(text : String) -> String {
  let mut from = 0
  let mut to = text.length()
  while from < to && is_css_space(@util.code_at(text, from)) {
    from += 1
  }
  while to > from && is_css_space(@util.code_at(text, to - 1)) {
    to -= 1
  }
  @util.slice(text, from, end=to)
}

///|
/// A theme value as it may be written into an attribute, or `None` when it could end the declaration it lands in.
fn theme_value(raw : String) -> String? {
  for i in 0..<raw.length() {
    match @util.code_at(raw, i) {
      ';' | '{' | '}' => return None
      _ => ()
    }
  }
  Some(@svg.esc(raw))
}

///|
priv struct Resolver {
  definitions : Map[String, String]
  theme : Map[String, String]
}

///|
/// The custom properties the SVG defines, by name.
/// pele defines its aliases once, on the root element, so the first definition of a name is the one every reference sees.
fn definitions(svg : String) -> Map[String, String] {
  let found : Map[String, String] = Map([])
  each_tag(svg, tag => {
    for attribute in tag.attributes {
      guard attribute.name == "style" else { continue }
      for declaration in attribute.value.split(";") {
        let declaration = declaration.to_owned()
        guard declaration.find(":") is Some(colon) else { continue }
        let name = css_trim(@util.slice(declaration, 0, end=colon))
        if name.has_prefix("--") && !found.contains(name) {
          found[name] = css_trim(@util.slice(declaration, colon + 1))
        }
      }
    }
  })
  found
}

///|
/// The value of the custom property `name`, or `None` when it is undefined or part of a cycle.
fn Resolver::value(self : Resolver, name : String, depth : Int32) -> String? {
  if depth > MAX_DEPTH {
    return None
  }
  match self.definitions.get(name) {
    Some(raw) => self.substitute(raw, depth + 1)
    None =>
      if name.has_prefix("--pele-") {
        self.theme.get(@util.slice(name, 7))
      } else {
        None
      }
  }
}

///|
/// `text` with every reference replaced, or `None` when one of them has neither a value nor a fallback, which makes the whole declaration invalid.
fn Resolver::substitute(
  self : Resolver,
  text : String,
  depth : Int32,
) -> String? {
  let out = StringBuilder()
  let mut copied = 0
  while true {
    let at = @util.index_of(text, "var(", from=copied)
    if at < 0 {
      break
    }
    let mut level = 1
    let mut comma = -1
    let mut i = at + 4
    while i < text.length() && level > 0 {
      match @util.code_at(text, i) {
        '(' => level += 1
        ')' => level -= 1
        ',' if level == 1 && comma < 0 => comma = i
        _ => ()
      }
      i += 1
    }
    if level > 0 {
      return None
    }
    let close = i - 1
    let name = css_trim(
      @util.slice(text, at + 4, end=if comma < 0 { close } else { comma }),
    )
    let resolved = match self.value(name, depth) {
      Some(value) => value
      None => {
        guard comma >= 0 else { return None }
        let fallback = css_trim(@util.slice(text, comma + 1, end=close))
        guard self.substitute(fallback, depth + 1) is Some(value) else {
          return None
        }
        value
      }
    }
    @util.write_range(out, text, copied, at)
    out.write_string(resolved)
    copied = i
  }
  @util.write_range(out, text, copied, text.length())
  Some(out.to_string())
}

///|
/// The declarations of `style` with their references resolved, leaving out custom properties and the declarations that do not resolve.
fn Resolver::style(self : Resolver, style : String) -> String {
  let kept = []
  for declaration in style.split(";") {
    let declaration = declaration.to_owned()
    if css_trim(declaration).has_prefix("--") {
      continue
    }
    if self.substitute(declaration, 0) is Some(resolved) {
      kept.push(resolved)
    }
  }
  kept.join(";")
}

///|
/// Replaces every CSS custom property reference in pele's SVG with its value, and drops the custom property declarations.
/// `theme` holds values for pele's `--pele-*` properties, keyed by the name without `--pele-`; absent ones take pele's fallbacks.
/// A value holding `;`, `{` or `}` is ignored, as it could end the declaration it lands in.
/// A declaration or attribute with a reference that resolves to nothing is dropped, as CSS treats it as unset.
pub fn resolve_vars(svg : String, theme : Map[String, String]) -> String {
  let resolver = Resolver::new(svg, theme)
  rewrite_tags(svg, attributes => resolver.attributes(attributes))
}

///|
/// The resolver of the references in `svg` under `theme`.
fn Resolver::new(svg : String, theme : Map[String, String]) -> Resolver {
  let usable : Map[String, String] = Map([])
  for name, raw in theme {
    if theme_value(raw) is Some(value) {
      usable[name] = value
    }
  }
  { definitions: definitions(svg), theme: usable, }
}

///|
/// The attributes of a tag with the references in their CSS resolved as `resolve_vars` resolves them.
fn Resolver::attributes(
  self : Resolver,
  attributes : Array[Attribute],
) -> Array[Attribute] {
  attributes.filter_map(attribute => {
    if !css_attributes.contains(attribute.name) {
      return Some(attribute)
    }
    let resolved = if attribute.name == "style" {
      Some(self.style(attribute.value))
    } else {
      self.substitute(attribute.value, 0)
    }
    match resolved {
      Some("") | None => None
      Some(value) => Some({ ..attribute, value, })
    }
  })
}
