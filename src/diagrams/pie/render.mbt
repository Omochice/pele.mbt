///|
const RADIUS : Double = 120

///|
const SWATCH : Double = 12

///|
const ROW : Double = 26

///|
const GAP : Double = 32

///|
const OUTSIDE : Double = 28

///|
fn option(config : @types.Config, key : String) -> Json? {
  guard config.get("pie") is Some(Object(pie)) else { return None }
  pie.get(key)
}

///|
fn number_option(config : @types.Config, key : String) -> Double? {
  match option(config, key) {
    Some(Number(value, ..)) => Some(value)
    _ => None
  }
}

///|
fn point(angle : Double, radius : Double) -> String {
  "\{@svg.num(@math.sin(angle) * radius)},\{@svg.num(-@math.cos(angle) * radius)}"
}

///|
fn ring(r : Double, sweep : Int32) -> String {
  let n = @svg.num(r)
  "M0,\{@svg.num(-r)}A\{n},\{n} 0 1 \{sweep} 0,\{n}A\{n},\{n} 0 1 \{sweep} 0,\{@svg.num(-r)}Z"
}

///|
fn slice(
  start : Double,
  end : Double,
  outer : Double,
  inner : Double,
) -> String {
  if end - start >= @math.PI * 2 - 1.0e-9 {
    return ring(outer, 1) + (if inner > 0 { ring(inner, 0) } else { "" })
  }
  let large = if end - start > @math.PI { 1 } else { 0 }
  let o = @svg.num(outer)
  if inner <= 0 {
    return "M0,0L\{point(start, outer)}A\{o},\{o} 0 \{large} 1 \{point(end, outer)}Z"
  }
  let i = @svg.num(inner)
  "M\{point(start, outer)}A\{o},\{o} 0 \{large} 1 \{point(end, outer)}" +
  "L\{point(end, inner)}A\{i},\{i} 0 \{large} 0 \{point(start, inner)}Z"
}

///|
fn render_pie(
  model : PieModel,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  // The legend position is the only value pele writes with String() that config from JSON can nest without bound.
  if option(config, "legendPosition") is Some(value) &&
    @util.js_string_too_deep(value) {
    raise @errors.nested_too_deeply()
  }
  @common.fit_width(options, RADIUS * 2, 140, (diameter, tight) => {
    draw(model, config, options, diameter / 2, tight)
  })
}

///|
priv struct Placed {
  x : Double
  y : Double
  width : Double
}

///|
/// `tight` is set when the chart does not fit the width it has with its legend beside it.
fn draw(
  model : PieModel,
  config : @types.Config,
  options : @types.RenderOptions,
  radius : Double,
  tight : Bool,
) -> @types.Rendered {
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.875).round()
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let text_position = match number_option(config, "textPosition") {
    Some(position) if position >= 0 && position <= 1 => position
    _ => 0.75
  }
  let inner = match number_option(config, "donutHole") {
    Some(hole) if hole > 0 && hole <= 0.9 => hole * radius
    _ => 0
  }
  let placed = match option(config, "legendPosition") {
    Some(Null) | None => "right"
    Some(value) => @util.js_string(value)
  }
  let legend_position = if tight && (placed == "left" || placed == "right") {
    "bottom"
  } else {
    placed
  }
  let entries = model.sections
  let mut sum = 0.0
  for entry in entries {
    sum += entry.1
  }
  let legend = entries.map(entry => {
    let (label, value) = entry
    @text.layout_label(
      Some(if model.show_data { "\{label} [\{value}]" } else { label }),
      false,
      measurer,
      small,
      4000,
    )
  })
  let mut legend_width = 0.0
  for label in legend {
    legend_width = @cmp.maximum(legend_width, label.width)
  }
  legend_width += if legend.length() > 0 { SWATCH + 8 } else { 0 }
  let legend_height = legend.length().to_double() * ROW
  let title = @text.layout_label(
    model.title,
    false,
    measurer,
    size,
    @common.title_room(options),
    base=@text.STYLE_BOLD,
  )
  let title_height = if title.height > 0 { title.height + 16 } else { 0 }
  // A slice too thin for its percentage gets the label outside the rim, which needs a margin.
  let shares = entries.map(entry => {
    let share = if sum > 0 { entry.1 / sum } else { 0 }
    if share * 100 >= 1 && @util.to_fixed0(share * 100) != "0" {
      share
    } else {
      0
    }
  })
  let narrow = shares.map(share => {
    if share == 0 || share >= 0.5 {
      return false
    }
    let chord = 2.0 * radius * text_position * @math.sin(share * @math.PI)
    chord < measurer.width(@util.to_fixed0(share * 100) + "%", small, 0) + 6
  })
  let margin = if narrow.contains(true) { OUTSIDE } else { 0 }
  let side = if legend_position is ("left" | "right" | "center") {
    legend_position
  } else {
    ""
  }
  let stacked = legend_position is ("top" | "bottom")
  let diameter = (radius + margin) * 2
  let mut width = diameter
  let mut height = diameter
  if side == "left" || side == "right" {
    width += if legend_width > 0 { GAP + legend_width } else { 0 }
    height = @cmp.maximum(height, legend_height)
  } else if stacked {
    width = @cmp.maximum(width, legend_width)
    height += if legend_height > 0 { 20 + legend_height } else { 0 }
  }
  width = @cmp.maximum(width, title.width)
  let cx = pad +
    (if side == "left" {
      legend_width + GAP + diameter / 2
    } else if side == "right" {
      diameter / 2
    } else {
      width / 2
    })
  let body_top = pad + title_height
  let cy = body_top +
    (if legend_position == "top" {
      legend_height + 20 + diameter / 2
    } else if stacked {
      diameter / 2
    } else {
      height / 2
    })
  let slices = StringBuilder()
  let labels = StringBuilder()
  let outside = StringBuilder()
  let mut angle = 0.0
  let rim = radius + OUTSIDE / 2
  let placed_outside : Array[Placed] = []
  let clear = (x : Double, y : Double, width : Double) => {
    placed_outside
    .iter()
    .all(other => {
      (x - other.x).abs() >= (width + other.width) / 2 + 2 ||
      (y - other.y).abs() >= small + 2
    })
  }
  for index, entry in entries {
    let share = shares[index]
    if share == 0 {
      continue
    }
    let end = angle + share * @math.PI * 2
    slices.write_string(
      "<path class=\"pele-slice\" data-id=\"\{@svg.esc_text(entry.0)}\" d=\"\{slice(angle, end, radius, inner)}\" fill=\"\{@svg.series_color(index)}\"/>",
    )
    let mid = (angle + end) / 2
    let text = @util.to_fixed0(share * 100) + "%"
    if narrow[index] {
      let text_width = measurer.width(text, small, 0)
      let mut at = mid
      for step = 0
          step < 360 &&
         !clear(@math.sin(at) * rim, -@math.cos(at) * rim, text_width)
          step = step + 1 {
        at += 2 / rim
      }
      let x = @math.sin(at) * rim
      let y = -@math.cos(at) * rim
      placed_outside.push({ x, y, width: text_width, })
      outside.write_string(
        "<text x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y + small * 0.35)}\">\{text}</text>",
      )
    } else {
      let r = radius * text_position
      labels.write_string(
        "<text x=\"\{@svg.num(@math.sin(mid) * r)}\" y=\"\{@svg.num(-@math.cos(mid) * r + small * 0.35)}\">\{text}</text>",
      )
    }
    angle = end
  }
  if slices.is_empty() {
    slices.write_string(
      "<circle class=\"pele-slice\" r=\"\{radius}\" fill=\"none\" stroke=\"var(--_b)\"/>",
    )
  }
  let (lx, ly) = if side == "right" {
    (cx + diameter / 2 + GAP, body_top + (height - legend_height) / 2)
  } else if side == "left" {
    (pad, body_top + (height - legend_height) / 2)
  } else if side == "center" {
    (cx - legend_width / 2, cy - legend_height / 2)
  } else {
    (
      pad + (width - legend_width) / 2,
      if legend_position == "top" {
        body_top
      } else {
        body_top + diameter + 20
      },
    )
  }
  let legend_out = StringBuilder()
  for index, label in legend {
    let y = ly + index.to_double() * ROW + ROW / 2
    legend_out.write_string(
      "<g class=\"pele-legend-item\" data-id=\"\{@svg.esc_text(entries[index].0)}\">" +
      "<rect x=\"\{@svg.num(lx)}\" y=\"\{@svg.num(y - SWATCH / 2)}\" width=\"\{SWATCH}\" height=\"\{SWATCH}\" rx=\"2\" fill=\"\{@svg.series_color(index)}\"/>" +
      @svg.label_svg(label, lx + SWATCH + 8 + label.width / 2, y, "") +
      "</g>",
    )
  }
  let total_width = (width + 2 * pad).ceil()
  let total_height = (height + title_height + 2 * pad).ceil()
  let translate = "translate(\{@svg.num(cx)},\{@svg.num(cy)})"
  let content = StringBuilder()
  content.write_string(
    @svg.label_svg(
      title,
      total_width / 2,
      pad + title.height / 2,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
    ),
  )
  content.write_string(
    "<g class=\"pele-slices\" transform=\"\{translate}\" stroke=\"var(--_bg)\" stroke-width=\"1\" stroke-linejoin=\"round\">\{slices.to_string()}</g>",
  )
  if !labels.is_empty() {
    content.write_string(
      "<g class=\"pele-slice-labels\" transform=\"\{translate}\" font-size=\"\{small}\" text-anchor=\"middle\" fill=\"var(--_bg)\">\{labels.to_string()}</g>",
    )
  }
  if !outside.is_empty() {
    content.write_string(
      "<g class=\"pele-slice-labels\" transform=\"\{translate}\" font-size=\"\{small}\" text-anchor=\"middle\">\{outside.to_string()}</g>",
    )
  }
  if !legend_out.is_empty() {
    content.write_string(
      "<g class=\"pele-legend\" font-size=\"\{small}\">\{legend_out.to_string()}</g>",
    )
  }
  {
    svg: @svg.svg_document(
      "pie",
      total_width,
      total_height,
      size,
      options,
      model.acc_title,
      model.acc_descr,
      content.to_string(),
    ),
    width: total_width,
    height: total_height,
    links: [],
  }
}
