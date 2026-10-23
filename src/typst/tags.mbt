///|
/// An attribute of a start tag, with its value as written between the quotes.
priv struct Attribute {
  name : String
  value : String
}

///|
/// A start tag, from its `<` up to the `>` or `/>` that ends it.
priv struct Tag {
  start : Int32
  end : Int32
  name : String
  attributes : Array[Attribute]
}

///|
fn is_name_end(c : Int32) -> Bool {
  c == ' ' ||
  c == '\t' ||
  c == '\n' ||
  c == '\r' ||
  c == '>' ||
  c == '/' ||
  c == '='
}

///|
fn is_letter(c : Int32) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
/// Reads the start tag at `start`, or `None` when the text there is not one.
fn read_tag(svg : String, start : Int32) -> Tag? {
  let n = svg.length()
  let mut i = start + 1
  while i < n && !is_name_end(@util.code_at(svg, i)) {
    i += 1
  }
  let name = @util.slice(svg, start + 1, end=i)
  let attributes = []
  while true {
    while i < n && @util.code_at(svg, i) == ' ' {
      i += 1
    }
    if i >= n {
      return None
    }
    let c = @util.code_at(svg, i)
    if c == '>' || c == '/' {
      break
    }
    let name_start = i
    while i < n && !is_name_end(@util.code_at(svg, i)) {
      i += 1
    }
    if i + 1 >= n ||
      @util.code_at(svg, i) != '=' ||
      @util.code_at(svg, i + 1) != '"' {
      return None
    }
    let close = @util.index_of(svg, "\"", from=i + 2)
    if close < 0 {
      return None
    }
    attributes.push({
      name: @util.slice(svg, name_start, end=i),
      value: @util.slice(svg, i + 2, end=close),
    })
    i = close + 1
  }
  Some({ start, end: i, name, attributes, })
}

///|
/// The start tags of pele's SVG in document order.
/// pele quotes every attribute value with double quotes and escapes `<` everywhere else, so a `<` before a letter always starts a tag.
fn tags(svg : String) -> Array[Tag] {
  let found = []
  let mut at = @util.index_of(svg, "<")
  while at >= 0 {
    let next = if at + 1 < svg.length() &&
      is_letter(@util.code_at(svg, at + 1)) &&
      read_tag(svg, at) is Some(tag) {
      found.push(tag)
      tag.end
    } else {
      at + 1
    }
    at = @util.index_of(svg, "<", from=next)
  }
  found
}

///|
/// Rewrites the attributes of every start tag, keeping everything else as written.
fn map_tags(
  svg : String,
  rewrite : (Array[Attribute]) -> Array[Attribute],
) -> String {
  let out = StringBuilder()
  let mut copied = 0
  for tag in tags(svg) {
    @util.write_range(out, svg, copied, tag.start)
    out.write_string("<")
    out.write_string(tag.name)
    for attribute in rewrite(tag.attributes) {
      out.write_string(" \{attribute.name}=\"\{attribute.value}\"")
    }
    copied = tag.end
  }
  @util.write_range(out, svg, copied, svg.length())
  out.to_string()
}
