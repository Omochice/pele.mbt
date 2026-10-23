///|
const GAP : Double = 4

///|
/// The most points for which a label looks for a place clear of the others.
const CAREFUL : Int32 = 300

///|
/// A point as it is placed, ready for its label to be.
priv struct Dot {
  cx : Double
  cy : Double
  reach : Double
  text : @text.Label
}

///|
fn setting(config : @types.Config, key : String) -> Json? {
  guard config.get("quadrantChart") is Some(Object(fields)) else { return None }
  fields.get(key)
}

///|
fn length(
  config : @types.Config,
  key : String,
  fallback : Double,
  max : Double,
) -> Double {
  match setting(config, key) {
    Some(Number(value, ..)) if value >= 0 => @util.js_min(value, max)
    _ => fallback
  }
}

///|
/// What `first ?? second` gives.
fn[T] either(first : T?, second : T?) -> T? {
  match first {
    Some(_) => first
    None => second
  }
}

///|
fn hex(color : String) -> String {
  if color.has_prefix("#") {
    color
  } else {
    "#" + color
  }
}

///|
/// Draws a quadrant chart.
fn render_quadrant(
  model : QuadrantDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  let size = options.font_size.unwrap_or(16)
  let axis_size = (size * 0.875).round()
  let point_size = (size * 0.75).round()
  let measurer = options.text_measurer()
  let natural = @util.js_max(100, length(config, "chartWidth", 500, 4000)).round()
  let width = @common.cap_width(options, natural, 280).round()
  let height = (@util.js_max(100, length(config, "chartHeight", 500, 4000)) *
  width /
  natural).round()
  let outer = length(
    config,
    "quadrantPadding",
    options.padding.unwrap_or(8),
    200,
  )
  let x_pad = length(config, "xAxisLabelPadding", 5, 200)
  let y_pad = length(config, "yAxisLabelPadding", 5, 200)
  let has_points = !model.points.is_empty()
  let label = (text : QuadrantText?, font_size : Double, max : Double) => {
    @text.layout_label(
      text.map(t => t.text),
      text.map(t => t.markdown).unwrap_or(false),
      measurer,
      font_size,
      @util.js_max(max, 40),
    )
  }
  let title = @text.layout_label(
    model.title,
    false,
    measurer,
    size,
    @util.js_max(width - 2 * outer, 40),
    base=@text.STYLE_BOLD,
  )
  let title_pad = length(config, "titlePadding", 10, 200)
  let title_space = if title.height > 0 { title.height + title_pad } else { 0 }
  let has_x = is_written(model.x_axis_left) || is_written(model.x_axis_right)
  let has_y = is_written(model.y_axis_bottom) || is_written(model.y_axis_top)
  // Mermaid moves the x axis labels below the chart as soon as there are points.
  let x_below = has_points ||
    setting(config, "xAxisPosition") is Some(String("bottom"))
  let y_right = setting(config, "yAxisPosition") is Some(String("right"))
  let side = width - 2 * outer
  let x_left = label(
    model.x_axis_left,
    axis_size,
    if model.x_axis_right is Some(_) {
      side / 2 - 16
    } else {
      side
    },
  )
  let x_right = label(model.x_axis_right, axis_size, side / 2 - 16)
  let x_height = @util.js_max(x_left.height, x_right.height)
  let x_space = if has_x { x_height + x_pad } else { 0 }
  let tall = height - 2 * outer - title_space - x_space
  let y_bottom = label(
    model.y_axis_bottom,
    axis_size,
    if model.y_axis_top is Some(_) {
      tall / 2 - 16
    } else {
      tall
    },
  )
  let y_top = label(model.y_axis_top, axis_size, tall / 2 - 16)
  let y_height = @util.js_max(y_bottom.height, y_top.height)
  let y_space = if has_y { y_height + y_pad } else { 0 }
  let left = outer + (if y_right { 0 } else { y_space })
  let top = outer + title_space + (if x_below { 0 } else { x_space })
  let w = @util.js_max(0, side - y_space)
  let h = @util.js_max(0, tall)
  let tile_w = @util.js_max(0, (w - GAP) / 2)
  let tile_h = @util.js_max(0, (h - GAP) / 2)
  // Boxes a point label keeps clear of: the gaps between quadrants, quadrant labels, points,
  // and the labels placed before it.
  let taken = [
    left + tile_w,
    top,
    left + w - tile_w,
    top + h,
    left,
    top + tile_h,
    left + w,
    top + h - tile_h,
  ]
  let is_clear = (
    from : Int32,
    x0 : Double,
    y0 : Double,
    x1 : Double,
    y1 : Double,
  ) => {
    let mut k = from
    while k < taken.length() {
      if x0 < taken[k + 2] &&
        x1 > taken[k] &&
        y0 < taken[k + 3] &&
        y1 > taken[k + 1] {
        return false
      }
      k += 4
    }
    true
  }
  let text_top = length(config, "quadrantTextTopPadding", 5, 200)
  let quadrants = @svg.Markup::new()
  for k in 0..<4 {
    let x = if k == 0 || k == 3 { left + w - tile_w } else { left }
    let y = if k < 2 { top } else { top + h - tile_h }
    let text = label(model.quadrants[k], size, tile_w - 16)
    let cx = x + tile_w / 2
    let cy = if has_points {
      y + text_top + text.height / 2
    } else {
      y + tile_h / 2
    }
    taken.push(cx - text.width / 2)
    taken.push(cy - text.height / 2)
    taken.push(cx + text.width / 2)
    taken.push(cy + text.height / 2)
    quadrants.write(
      "<g class=\"pele-quadrant\" data-id=\"\{k + 1}\">" +
      "<rect x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y)}\" width=\"\{@svg.num(tile_w)}\" height=\"\{@svg.num(tile_h)}\"\{@svg.ROUNDED}/>" +
      @svg.label_svg(
        text, cx, cy, " class=\"pele-label\" fill=\"var(--_fg)\" stroke=\"none\"",
      ) +
      "</g>",
    )
  }
  let axes = @svg.Markup::new()
  if has_x {
    let y = if x_below {
      top + h + x_pad + x_height / 2
    } else {
      top - x_pad - x_height / 2
    }
    axes.write(
      @svg.label_svg(
        x_left,
        if x_right.height > 0 {
          left + w / 4
        } else {
          left + x_left.width / 2
        },
        y,
        "",
      ) +
      @svg.label_svg(x_right, left + w * 3 / 4, y, ""),
    )
  }
  if has_y {
    let x = if y_right {
      left + w + y_pad + y_height / 2
    } else {
      left - y_pad - y_height / 2
    }
    let turned = (text : @text.Label, y : Double) => {
      if text.height > 0 {
        "<g transform=\"translate(\{@svg.num(x)},\{@svg.num(y)}) rotate(-90)\">\{@svg.label_svg(text, 0, 0, "")}</g>"
      } else {
        ""
      }
    }
    axes.write(
      turned(
        y_bottom,
        if y_top.height > 0 {
          top + h * 3 / 4
        } else {
          top + h - y_bottom.width / 2
        },
      ) +
      turned(y_top, top + h / 4),
    )
  }
  let radius = length(config, "pointRadius", 5, 200)
  let text_pad = length(config, "pointTextPadding", 5, 200)
  let fill = @svg.series_color(0)
  let dots : Array[Dot] = []
  let circles : Array[String] = []
  for point in model.points {
    if !(point.x >= 0 && point.x <= 1 && point.y >= 0 && point.y <= 1) {
      continue
    }
    let shared = model.classes.get(point.class_name)
    let r = @util.js_min(
      either(point.style.radius, shared.bind(s => s.radius)).unwrap_or(radius),
      2000,
    )
    let color = either(point.style.color, shared.bind(s => s.color))
    let stroke_color = either(
      point.style.stroke_color,
      shared.bind(s => s.stroke_color),
    )
    let stroke_width = either(
      point.style.stroke_width,
      shared.bind(s => s.stroke_width),
    )
    let styles = []
    if color is Some(color) {
      styles.push("fill:" + hex(color))
    }
    if stroke_width is Some(stroke_width) {
      if stroke_color is Some(stroke_color) {
        styles.push("stroke:" + hex(stroke_color))
      }
      styles.push("stroke-width:" + stroke_width)
    }
    let cx = left + point.x * w
    let cy = top + (1 - point.y) * h
    dots.push({
      cx,
      cy,
      reach: r +
      (match stroke_width {
        Some(stroke_width) =>
          @util.js_min(@util.parse_float(stroke_width), 400) / 2
        None => 0
      }),
      text: label(Some(point.text), point_size, 200),
    })
    circles.push(
      "<circle class=\"pele-point\{@svg.class_names(point.class_name)}\" data-id=\"\{@svg.esc_text(point.text.text)}\" cx=\"\{@svg.num(cx)}\" cy=\"\{@svg.num(cy)}\" r=\"\{@svg.num(r)}\"\{if stroke_width is Some(_) && stroke_color is None { " stroke=\"\{fill}\"" } else { "" }}\{@svg.resolve_style(styles).shape}/>",
    )
  }
  // A label goes below its point, or above, right or left of it when that is the first place
  // that is inside the chart and free. A second round lets it cross the gaps between quadrants.
  // Large charts skip the search for a free place.
  let careful = dots.length() <= CAREFUL
  if careful {
    for dot in dots {
      taken.push(dot.cx - dot.reach)
      taken.push(dot.cy - dot.reach)
      taken.push(dot.cx + dot.reach)
      taken.push(dot.cy + dot.reach)
    }
  }
  let labels = @svg.Markup::new()
  for dot in dots {
    let { cx, cy, reach, text, } = dot
    let half_w = text.width / 2
    let half_h = text.size * 0.6 + (text.height - text.line_height) / 2
    let away = reach + text_pad
    let spots = [
      cx,
      cy + away + half_h,
      cx,
      cy - away - half_h,
      cx + away + half_w,
      cy,
      cx - away - half_w,
      cy,
    ]
    let mut tx = cx
    let mut ty = spots[1]
    let mut found = false
    for k = 0; k < 16; k = k + 2 {
      let spot = k % 8
      let x = if spot < 4 && text.width < w {
        @util.js_min(
          @util.js_max(spots[spot], left + half_w),
          left + w - half_w,
        )
      } else {
        spots[spot]
      }
      let y = spots[spot + 1]
      if x - half_w < left ||
        x + half_w > left + w ||
        y - half_h < top ||
        y + half_h > top + h {
        continue
      }
      let free = !careful ||
        is_clear(
          if k < 8 {
            0
          } else {
            8
          },
          x - half_w,
          y - half_h,
          x + half_w,
          y + half_h,
        )
      if !found || free {
        tx = x
        ty = y
        found = true
      }
      if free {
        break
      }
    }
    if careful {
      taken.push(tx - half_w)
      taken.push(ty - half_h)
      taken.push(tx + half_w)
      taken.push(ty + half_h)
    }
    labels.write(@svg.label_svg(text, tx, ty, " class=\"pele-label\""))
  }
  // Mermaid puts each new point under the ones before it.
  circles.rev_in_place()
  let content = @svg.Markup::new()
  content.write(
    @svg.label_svg(
      title,
      width / 2,
      title_pad / 2 + title.height / 2,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
    ),
  )
  content.write_group(
    "<g class=\"pele-quadrants\" fill=\"var(--_s)\" stroke=\"var(--_b)\">", quadrants,
    "</g>",
  )
  if !axes.is_empty() {
    content.write_group(
      "<g class=\"pele-axis-labels\" font-size=\"\{axis_size}\" fill=\"var(--_m)\">",
      axes,
      "</g>",
    )
  }
  if !dots.is_empty() {
    content.write("<g class=\"pele-points\" fill=\"\{fill}\">")
    for circle in circles {
      content.write(circle)
    }
    content.write("</g>")
    content.write_group(
      "<g class=\"pele-point-labels\" font-size=\"\{point_size}\">",
      labels,
      "</g>",
    )
  }
  {
    svg: @svg.markup_document(
      "quadrantChart",
      width,
      height,
      size,
      options,
      model.acc_title,
      model.acc_descr,
      content,
    ),
    width,
    height,
    links: [],
  }
}

///|
/// Whether a label has text, which an empty string written in quotes does not.
fn is_written(label : QuadrantText?) -> Bool {
  match label {
    Some({ text, .. }) => text != ""
    None => false
  }
}
