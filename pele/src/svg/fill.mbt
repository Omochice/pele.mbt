///|
/// A fill a style sets, as an edge drawn over it reads it.
pub(all) struct Fill {
  /// The bounds of the fill: left, top, right and bottom.
  box : Array[Double]
  /// The label color that contrasts with the fill, as `ink` picks it.
  ink : String?
  /// The fill's color as its style writes it.
  color : String?
}

///|
/// The fill inside `box` that the `style` attribute `shape` sets.
/// Styles come from `resolve_style`.
pub fn Fill::new(box : Array[Double], shape : String) -> Fill {
  {
    box,
    ink: ink(shape),
    color: attribute_value(shape, "fill").map(@util.trim),
  }
}

///|
/// The fill inside `box` that the `style` attribute `resolve_style` makes of the raw CSS `css` sets.
/// Styles come from `resolve_raw_style`.
pub fn Fill::raw(box : Array[Double], css : String) -> Fill {
  { box, ink: raw_ink(css), color: raw_value(css, "fill").map(@util.trim), }
}

///|
/// Where an edge lies among the fills.
pub(all) enum FillUnder {
  /// It touches none of them.
  Off
  /// It crosses the border of one it touches.
  Across
  /// The innermost one it touches holds all of it.
  On(Fill)
}

///|
/// Where the path `d`, with marker tips at the x, y pairs of `tips`, lies among the `fills`.
/// `tokens` are the commands of `d`, which `d` is read for when they are not given.
/// A path that only runs along a border or ends on one touches no fill.
pub fn fill_under(
  d : String,
  tips : Array[Double],
  fills : Array[Fill],
  tokens? : Array[Double],
) -> FillUnder {
  if fills.is_empty() {
    return Off
  }
  let points = match tokens {
    Some(tokens) => sample(tokens)
    None => path_points(d)
  }
  let mut min_x = @double.infinity
  let mut min_y = @double.infinity
  let mut max_x = @double.neg_infinity
  let mut max_y = @double.neg_infinity
  for all in [points, tips] {
    for k = 0; k < all.length(); k = k + 2 {
      let x = all[k]
      let y = all[k + 1]
      if x < min_x {
        min_x = x
      }
      if x > max_x {
        max_x = x
      }
      if y < min_y {
        min_y = y
      }
      if y > max_y {
        max_y = y
      }
    }
  }
  let mut holder = None
  let mut least = @double.infinity
  for fill in fills {
    let l = fill.box[0]
    let t = fill.box[1]
    let r = fill.box[2]
    let b = fill.box[3]
    if max_x < l + 0.5 || min_x > r - 0.5 || max_y < t + 0.5 || min_y > b - 0.5 {
      continue
    }
    let mut touched = enters(points, l + 0.5, t + 0.5, r - 0.5, b - 0.5)
    for k = 0; k < tips.length() && !touched; k = k + 2 {
      touched = tips[k] > l + 0.5 &&
        tips[k] < r - 0.5 &&
        tips[k + 1] > t + 0.5 &&
        tips[k + 1] < b - 0.5
    }
    if !touched {
      continue
    }
    if min_x < l || max_x > r || min_y < t || max_y > b {
      return Across
    }
    let area = (r - l) * (b - t)
    if area < least {
      least = area
      holder = Some(fill)
    }
  }
  match holder {
    Some(fill) => On(fill)
    None => Off
  }
}

///|
/// The color of an edge on `fill`, or an empty string, which asks for a casing, when the fill's color
/// is unknown or when the edge's line style `line` sets a stroke of its own.
/// Styles come from `resolve_style`.
pub fn edge_ink(fill : Fill, line~ : String = "") -> String {
  if attribute_value(line, "stroke") is Some(_) {
    return ""
  }
  fill.ink.unwrap_or("")
}

///|
/// `edge_ink` of an edge whose line style is the raw CSS `css`.
/// Styles come from `resolve_raw_style`.
pub fn raw_edge_ink(fill : Fill, css~ : String) -> String {
  if raw_value(css, "stroke") is Some(_) {
    return ""
  }
  fill.ink.unwrap_or("")
}

///|
/// The `markers` with the fill's color in place of the page color inside them, so that a hollow
/// marker on the fill shows the fill through it.
pub fn hollow_on(markers : String, fill : Fill) -> String {
  match fill.color {
    Some(color) if color != "" =>
      markers.replace_all(old=" fill=\"var(--_bg)\"", new=" fill=\"\{color}\"")
    _ => markers
  }
}

///|
/// The color of the path `d`, with marker tips at `tips`, where it lies on one of the `fills`: that
/// fill's `edge_ink` when the innermost fill it touches holds all of it, an empty string, which asks
/// for a casing, when it crosses a border, and `None` off them all.
/// `tokens` are the commands of `d`, as `fill_under` takes them.
/// Styles come from `resolve_style`.
pub fn over_fills(
  d : String,
  tips : Array[Double],
  fills : Array[Fill],
  line~ : String = "",
  tokens? : Array[Double],
) -> String? {
  match fill_under(d, tips, fills, tokens?) {
    On(fill) => Some(edge_ink(fill, line~))
    Across => Some("")
    Off => None
  }
}

///|
/// `over_fills` of an edge whose line style is the raw CSS `css`.
/// Styles come from `resolve_raw_style`.
pub fn raw_over_fills(
  d : String,
  tips : Array[Double],
  fills : Array[Fill],
  css~ : String,
) -> String? {
  match fill_under(d, tips, fills) {
    On(fill) => Some(raw_edge_ink(fill, css~))
    Across => Some("")
    Off => None
  }
}
