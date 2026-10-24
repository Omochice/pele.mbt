///|
/// Markup the host typeset, drawn in a nested `<svg>` or in a `<foreignObject>`.
pub(all) enum MathBody {
  Svg(String)
  Html(String)
}

///|
/// Typeset math that passed pele's check, with the size of the box it is drawn in.
pub(all) struct MathMarkup {
  body : MathBody
  width : Double
  height : Double
}

///|
/// The typesetter of the render in progress.
/// pele keeps it in module state rather than passing it down, as every label path reaches it.
let resolver : Ref[((String, Double) -> Json?)?] = { val: None, }

///|
/// What the typesetter answered in the render in progress, keyed by size and TeX.
let found : Ref[Map[String, MathMarkup?]] = { val: Map([]), }

///|
/// Runs `run` with `math` as the typesetter that labels ask, and with nothing typeset yet.
pub fn[T] with_math(
  math : ((String, Double) -> Json?)?,
  run : () -> T raise?,
) -> T raise? {
  let outer = resolver.val
  let outer_found = found.val
  resolver.val = math
  found.val = Map([])
  defer {
    resolver.val = outer
    found.val = outer_found
  }
  run()
}

///|
/// Whether labels are laid out with a typesetter.
pub fn math_active() -> Bool {
  resolver.val is Some(_)
}

///|
fn valid(size : Json?) -> Double? {
  match size {
    Some(Number(size, ..)) if !size.is_nan() && !size.is_inf() && size > 0 =>
      Some(size)
    _ => None
  }
}

///|
/// The markup in what the host returned, when pele would draw it.
fn checked(result : Json?) -> MathMarkup? {
  guard result is Some(Object(fields)) else { return None }
  guard valid(fields.get("width")) is Some(width) &&
    valid(fields.get("height")) is Some(height) else {
    return None
  }
  let body = match fields.get("svg") {
    Some(String(svg)) => Svg(svg)
    Some(_) => return None
    None =>
      match fields.get("html") {
        Some(String(html)) => Html(html)
        _ => return None
      }
  }
  Some({ body, width, height, })
}

///|
/// The host's markup for `tex` at font size `size`, or `None` when there is no typesetter or the
/// markup fails pele's check.
pub fn typeset(tex : String, size : Double) -> MathMarkup? {
  guard resolver.val is Some(resolve) else { return None }
  let key = @util.js_string(Json::number(size)) + "\n" + tex
  if found.val.get(key) is Some(markup) {
    return markup
  }
  let markup = checked(resolve(tex, size))
  found.val[key] = markup
  markup
}

///|
/// Runs `run` with no typesetter, as Mermaid draws diagram titles as text.
pub fn[T] without_math(run : () -> T raise?) -> T raise? {
  let outer = resolver.val
  resolver.val = None
  defer {
    resolver.val = outer
  }
  run()
}
