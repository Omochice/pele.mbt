///|
const SWATCH : Double = 12

///|
const ROW : Double = 26

///|
const GAP : Double = 24

///|
pub(all) struct Point {
  x : Double
  y : Double
}

///|
fn number_option(
  config : @types.Config,
  key : String,
  fallback : Double,
  min : Double,
  max : Double,
) -> Double {
  guard config.get("radar") is Some(Object(radar)) else { return fallback }
  match radar.get(key) {
    Some(Number(value, ..)) if value >= min => @cmp.minimum(value, max)
    _ => fallback
  }
}

///|
/// Where a value lies between `min` and `max` as a distance from the center, clipped to the range.
pub fn relative_radius(
  value : Double,
  min : Double,
  max : Double,
  radius : Double,
) -> Double {
  let clipped = @cmp.minimum(@cmp.maximum(value, min), max)
  radius * (clipped - min) / (max - min)
}

///|
/// Writes a closed Catmull-Rom spline through the points, as cubic Bezier segments, one segment at a time.
fn write_closed_round_curve(
  points : Array[Point],
  tension : Double,
  write : (String) -> Unit raise?,
) -> Unit raise? {
  let n = points.length()
  write("M\{@svg.num(points[0].x)},\{@svg.num(points[0].y)}")
  for i in 0..<n {
    let p0 = points[(i - 1 + n) % n]
    let p1 = points[i]
    let p2 = points[(i + 1) % n]
    let p3 = points[(i + 2) % n]
    write(
      " C\{@svg.num(p1.x + (p2.x - p0.x) * tension)},\{@svg.num(p1.y + (p2.y - p0.y) * tension)}" +
      " \{@svg.num(p2.x - (p3.x - p1.x) * tension)},\{@svg.num(p2.y - (p3.y - p1.y) * tension)} \{@svg.num(p2.x)},\{@svg.num(p2.y)}",
    )
  }
  write(" Z")
}

///|
/// A closed Catmull-Rom spline through the points, as cubic Bezier segments.
pub fn closed_round_curve(points : Array[Point], tension : Double) -> String {
  let d = StringBuilder()
  write_closed_round_curve(points, tension, segment => d.write_string(segment))
  d.to_string()
}

///|
/// Writes the points of a polygon one at a time.
fn write_polygon(
  points : Array[Point],
  write : (String) -> Unit raise?,
) -> Unit raise? {
  for i, p in points {
    write("\{if i > 0 { " " } else { "" }}\{@svg.num(p.x)},\{@svg.num(p.y)}")
  }
}

///|
fn is_finite(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}

///|
fn render_radar(
  model : RadarModel,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  let natural = number_option(config, "width", 320, 1, 4000)
  @common.fit_width(options, natural, 160, (width, tight) => {
    let height = number_option(config, "height", 320, 1, 4000) * width / natural
    draw(model, config, options, width, height, tight)
  })
}

///|
/// `tight` is set when the chart does not fit the width it has with its legend beside it.
fn draw(
  model : RadarModel,
  config : @types.Config,
  options : @types.RenderOptions,
  width : Double,
  height : Double,
  tight : Bool,
) -> @types.Rendered raise @errors.PeleError {
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.875).round()
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let axis_scale = number_option(config, "axisScaleFactor", 1, 0, 10)
  let label_factor = number_option(config, "axisLabelFactor", 1.05, 0, 10)
  let tension = number_option(config, "curveTension", 0.17, 0, 1)
  let radius = @cmp.minimum(width, height) / 2
  let axes = model.axes
  let curves = model.curves
  let ticks = model.options.ticks
  let graticule = model.options.graticule
  let min = model.options.min
  let count = axes.length()
  let unit : Array[Point] = Array::makei(count, i => {
    let angle = 2.0 * @math.PI * i.to_double() / count.to_double() -
      @math.PI / 2
    { x: @math.cos(angle), y: @math.sin(angle), }
  })
  let max = match model.options.max {
    Some(given) => given
    None => {
      let mut largest = @double.neg_infinity
      for curve in curves {
        for value in curve.entries {
          if value > largest {
            largest = value
          }
        }
      }
      largest
    }
  }
  // The chart is drawn around the origin.
  // Margins reserve space, and labels and the legend widen it.
  let mut x0 = -width / 2 - number_option(config, "marginLeft", 16, 0, 2000)
  let mut x1 = width / 2 + number_option(config, "marginRight", 16, 0, 2000)
  let mut y0 = -height / 2 - number_option(config, "marginTop", 16, 0, 2000)
  let mut y1 = height / 2 + number_option(config, "marginBottom", 16, 0, 2000)
  let grid = @svg.Markup::new()
  let mut i = 0
  while i.to_double() < ticks {
    let r = @cmp.minimum(radius, radius * (i + 1).to_double() / ticks)
    if graticule == "circle" {
      grid.write("<circle r=\"\{@svg.num(r)}\"/>")
    } else {
      grid.write("<polygon points=\"")
      write_polygon(unit.map(u => { x: u.x * r, y: u.y * r, }), point => {
        grid.write(point)
      })
      grid.write("\"/>")
    }
    i += 1
  }
  let spokes = @svg.Markup::new()
  let labels = @svg.Markup::new()
  for i, u in unit {
    let reach = radius * axis_scale
    spokes.write("M0,0L\{@svg.num(u.x * reach)},\{@svg.num(u.y * reach)}")
    let label = @text.layout_label(
      Some(axes[i].label),
      false,
      measurer,
      small,
      4000,
    )
    let at = radius * label_factor + 6
    // Each label hangs off its axis on the side away from the center.
    let cx = u.x * at +
      (if u.x > 0.01 {
        label.width / 2
      } else if u.x < -0.01 {
        -label.width / 2
      } else {
        0
      })
    let cy = u.y * at +
      (if u.y > 0.01 {
        label.height / 2
      } else if u.y < -0.01 {
        -label.height / 2
      } else {
        0
      })
    labels.write("<g class=\"pele-axis-label\" data-id=\"")
    @svg.write_esc_text(labels, axes[i].name)
    labels.write("\">")
    @svg.write_label(labels, label, cx, cy, "")
    labels.write("</g>")
    x0 = @cmp.minimum(x0, cx - label.width / 2)
    x1 = @cmp.maximum(x1, cx + label.width / 2)
    y0 = @cmp.minimum(y0, cy - label.height / 2)
    y1 = @cmp.maximum(y1, cy + label.height / 2)
  }
  let shapes = @svg.Markup::new()
  for index, curve in curves {
    // Mermaid leaves out a curve that does not have a value for every axis.
    if curve.entries.length() != count {
      continue
    }
    let points : Array[Point] = curve.entries.mapi((i, value) => {
      let r = relative_radius(value, min, max, radius)
      let safe = if is_finite(r) { r } else { 0 }
      { x: unit[i].x * safe, y: unit[i].y * safe, }
    })
    let color = @svg.series_color(index)
    let element = if graticule == "circle" { "path" } else { "polygon" }
    shapes.write("<\{element} class=\"pele-curve\" data-id=\"")
    @svg.write_esc_text(shapes, curve.name)
    shapes.write("\" fill=\"\{color}\" stroke=\"\{color}\"")
    if graticule == "circle" {
      shapes.write(" d=\"")
      write_closed_round_curve(points, tension, segment => shapes.write(segment))
    } else {
      shapes.write(" points=\"")
      write_polygon(points, point => shapes.write(point))
    }
    shapes.write("\"/>")
  }
  let legend = if model.options.show_legend {
    curves.map(curve => {
      @text.layout_label(Some(curve.label), false, measurer, small, 4000)
    })
  } else {
    []
  }
  let mut legend_width = 0.0
  for label in legend {
    legend_width = @cmp.maximum(legend_width, label.width)
  }
  let legend_height = legend.length().to_double() * ROW
  let legend_x = if tight { -(SWATCH + 8 + legend_width) / 2 } else { x1 + GAP }
  let legend_top = if tight { y1 + GAP / 2 } else { -legend_height / 2 }
  if legend.length() > 0 && tight {
    x0 = @cmp.minimum(x0, legend_x)
    x1 = @cmp.maximum(x1, -legend_x)
    y1 = legend_top + legend_height
  } else if legend.length() > 0 {
    x1 = legend_x + SWATCH + 8 + legend_width
    y0 = @cmp.minimum(y0, -legend_height / 2)
    y1 = @cmp.maximum(y1, legend_height / 2)
  }
  let legend_out = @svg.Markup::new()
  for index, label in legend {
    let y = legend_top + index.to_double() * ROW + ROW / 2
    let color = @svg.series_color(index)
    legend_out.write("<g class=\"pele-legend-item\" data-id=\"")
    @svg.write_esc_text(legend_out, curves[index].name)
    legend_out.write(
      "\"><rect x=\"\{@svg.num(legend_x)}\" y=\"\{@svg.num(y - SWATCH / 2)}\" width=\"\{SWATCH}\" height=\"\{SWATCH}\" rx=\"2\" fill=\"\{color}\" fill-opacity=\"0.4\" stroke=\"\{color}\"/>",
    )
    @svg.write_label(
      legend_out,
      label,
      legend_x + SWATCH + 8 + label.width / 2,
      y,
      "",
    )
    legend_out.write("</g>")
  }
  let title = @text.layout_label(
    model.title,
    false,
    measurer,
    size,
    @common.title_room(options),
    base=@text.STYLE_BOLD,
  )
  let title_height = if title.height > 0 { title.height + 8 } else { 0 }
  let body_width = @cmp.maximum(x1 - x0, title.width)
  let total_width = (body_width + 2 * pad).ceil()
  let total_height = (y1 - y0 + title_height + 2 * pad).ceil()
  let origin = "translate(\{@svg.num(pad + (body_width - (x1 - x0)) / 2 - x0)},\{@svg.num(pad + title_height - y0)})"
  let content = @svg.Markup::new()
  @svg.write_label(
    content,
    title,
    total_width / 2,
    pad + title.height / 2,
    " class=\"pele-title\" font-weight=\"var(--_tw)\"",
  )
  content.write("<g transform=\"\{origin}\">")
  if !grid.is_empty() {
    content.write_group(
      "<g class=\"pele-graticule\" fill=\"none\" stroke=\"var(--_a)\">", grid, "</g>",
    )
  }
  if !spokes.is_empty() {
    content.write_group(
      "<path class=\"pele-axes\" d=\"", spokes, "\" fill=\"none\" stroke=\"var(--_b)\"/>",
    )
  }
  if !shapes.is_empty() {
    content.write_group(
      "<g class=\"pele-curves\" fill-opacity=\"0.2\" stroke-width=\"1.5\" stroke-linejoin=\"round\">",
      shapes, "</g>",
    )
  }
  if !labels.is_empty() {
    content.write_group(
      "<g class=\"pele-axis-labels\" font-size=\"\{small}\">",
      labels,
      "</g>",
    )
  }
  if !legend_out.is_empty() {
    content.write_group(
      "<g class=\"pele-legend\" font-size=\"\{small}\">",
      legend_out,
      "</g>",
    )
  }
  content.write("</g>")
  {
    svg: @svg.markup_document(
      "radar",
      total_width,
      total_height,
      size,
      options,
      model.acc_title,
      model.acc_descr,
      content,
    ),
    width: total_width,
    height: total_height,
    links: [],
  }
}
