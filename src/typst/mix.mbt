///|
/// A color of `color-mix()` and the percentage it is mixed in, `None` when omitted.
priv struct MixItem {
  color : Srgb
  percentage : Double?
}

///|
/// A percentage that `color-mix()` takes, which must lie from 0% to 100%.
fn mix_percentage(text : String) -> Double? {
  guard css_percentage(text) is Some(value) && value >= 0 && value <= 100 else {
    return None
  }
  Some(value)
}

///|
/// A color with an optional percentage before or after it.
fn mix_item(text : String) -> MixItem? {
  match components(text) {
    Some([color]) =>
      parse_color(color).map(color => { color, percentage: None, })
    Some([first, second]) =>
      match (mix_percentage(first), mix_percentage(second)) {
        (Some(percentage), None) =>
          parse_color(second).map(color => {
            color,
            percentage: Some(percentage),
          })
        (None, Some(percentage)) =>
          parse_color(first).map(color => {
            color,
            percentage: Some(percentage),
          })
        _ => None
      }
    _ => None
  }
}

///|
/// A component of `a` and `b` where one may be missing, which then takes the other's value.
fn fill_missing(a : Double?, b : Double?) -> (Double?, Double?) {
  match (a, b) {
    (Some(_), None) => (a, a)
    (None, Some(_)) => (b, b)
    _ => (a, b)
  }
}

///|
/// `a` and `b` interpolated in sRGB by `progress` from `a` to `b`, premultiplied by their alpha as CSS Color 4 interpolates.
fn interpolate(a : Srgb, b : Srgb, progress : Double) -> Srgb {
  let (alpha_a, alpha_b) = fill_missing(a.alpha, b.alpha)
  let alpha = match (alpha_a, alpha_b) {
    (Some(x), Some(y)) => Some(x * (1 - progress) + y * progress)
    _ => None
  }
  let channels = Array::makei(3, i => {
    match fill_missing(a.channels[i], b.channels[i]) {
      (Some(x), Some(y)) => {
        let mixed = x * alpha_a.unwrap_or(1) * (1 - progress) +
          y * alpha_b.unwrap_or(1) * progress
        match alpha {
          Some(alpha) if alpha != 0 => Some(mixed / alpha)
          _ => Some(mixed)
        }
      }
      _ => None
    }
  })
  { channels, alpha, }
}

///|
/// The color that the arguments of `color-mix()` compute to, or `None` when they are not two colors mixed in sRGB.
fn color_mix(body : String) -> Srgb? {
  guard split_outside_parens(body, c => c == ',')
    is Some([space, first, second]) &&
    components(space) is Some(["in", "srgb"]) &&
    mix_item(first) is Some(first) &&
    mix_item(second) is Some(second) else {
    return None
  }
  let specified = clamp(
    first.percentage.unwrap_or(0) + second.percentage.unwrap_or(0),
    0,
    100,
  )
  let omitted = (if first.percentage is None { 1 } else { 0 }) +
    (if second.percentage is None { 1 } else { 0 })
  let share = if omitted > 0 {
    (100.0 - specified) / omitted.to_double()
  } else {
    0.0
  }
  let p1 = first.percentage.unwrap_or(share)
  let p2 = second.percentage.unwrap_or(share)
  let total = p1 + p2
  let leftover = if total < 100 { 100.0 - total } else { 0.0 }
  let progress = if total > 0 { p2 / total } else { 0.5 }
  let mixed = interpolate(first.color, second.color, progress)
  Some({
    ..mixed,
    alpha: mixed.alpha.map(alpha => alpha * (100.0 - leftover) / 100),
  })
}

///|
/// `value` with every `color-mix()` it can evaluate replaced by the hex code of its color.
fn evaluate_mixes(value : String) -> String {
  let lower = ascii_lower(value)
  let out = StringBuilder()
  let mut copied = 0
  let mut from = 0
  while true {
    let at = @util.index_of(lower, "color-mix(", from~)
    guard at >= 0 && closing_paren(lower, at + 9) is Some(close) else { break }
    if parse_color(@util.slice(lower, at, end=close + 1)) is Some(color) {
      @util.write_range(out, value, copied, at)
      out.write_string(color.to_hex())
      copied = close + 1
    }
    from = close + 1
  }
  @util.write_range(out, value, copied, value.length())
  out.to_string()
}

///|
/// Replaces every `color-mix()` in sRGB in the CSS of pele's SVG with the color it computes to.
/// typst does not evaluate `color-mix()`, so whatever is painted with one is not drawn.
/// A mix is left as written when CSS rejects it, when it mixes in another space, or when one of its colors is not a hex code, `rgb()`, `rgba()`, a named color, `transparent` or such a mix.
pub fn mix_colors(svg : String) -> String {
  map_tags(svg, attributes => {
    attributes.map(attribute => {
      if css_attributes.contains(attribute.name) {
        { ..attribute, value: evaluate_mixes(attribute.value), }
      } else {
        attribute
      }
    })
  })
}
