///|
let default_stages : Array[String] = [
  "Genesis", "Custom Built", "Product", "Commodity",
]

///|
/// Mermaid's canvas has this much room around the plot on every side.
const CANVAS_MARGIN : Double = 48

///|
const R : Double = 6

///|
const SQUARE : Double = 10

///|
const LABEL_OFFSET : Double = 8

///|
const PIPELINE_PAD : Double = 15

///|
const FORCE_WIDTH : Double = 60

///|
const FORCE_HEIGHT : Double = 30

///|
const FORCE_HEAD : Double = 20

///|
const ACCENT : String = "var(--_c)"

///|
const LINE : String = "var(--_l)"

///|
/// Where a node is drawn, which a pipeline moves its parent from.
priv struct Placed {
  mut x : Double
  mut y : Double
  node : WardleyNode
}

///|
/// The extent of everything drawn, which starts as the plot.
priv struct Bounds {
  mut min_x : Double
  mut min_y : Double
  mut max_x : Double
  mut max_y : Double
}

///|
fn Bounds::grow(
  self : Bounds,
  x0 : Double,
  y0 : Double,
  x1 : Double,
  y1 : Double,
) -> Unit {
  if x0 < self.min_x {
    self.min_x = x0
  }
  if y0 < self.min_y {
    self.min_y = y0
  }
  if x1 > self.max_x {
    self.max_x = x1
  }
  if y1 > self.max_y {
    self.max_y = y1
  }
}

///|
fn section(config : @types.Config) -> Map[String, Json] {
  match config.get("wardley-beta") {
    Some(Object(fields)) => fields
    _ => {}
  }
}

///|
fn setting(
  config : @types.Config,
  key : String,
  fallback : Double,
  min : Double,
  max : Double,
) -> Double {
  match section(config).get(key) {
    Some(Number(value, ..)) if value >= min && value <= max => value
    _ => fallback
  }
}

///|
fn clamp(value : Double, min : Double, max : Double) -> Double {
  if value < min {
    min
  } else if value > max {
    max
  } else {
    value
  }
}

///|
fn dimension(
  config : @types.Config,
  given : Double?,
  key : String,
  fallback : Double,
) -> Double {
  let value = match given {
    Some(n) if !n.is_nan() && !n.is_inf() => n
    _ => setting(config, key, fallback, 1, 1.0e6)
  }
  clamp(value, 200, 10000) - 2 * CANVAS_MARGIN
}

///|
/// Writes a label to `out` with its lines starting at `x` and its first baseline at `y`.
fn write_start_label(
  out : @svg.Markup,
  label : @text.Label,
  x : Double,
  y : Double,
  attrs : String,
) -> Unit raise @errors.PeleError {
  let shared = @svg.shared_style(label)
  let body = @svg.Markup::new()
  let mut baseline = y
  for line in label.lines {
    let mut first = true
    for span in line {
      if span.icon is Some(_) {
        continue
      }
      let style = @svg.span_style(span.style & shared.lnot())
      let at = if first {
        " x=\"\{@svg.num(x)}\" y=\"\{@svg.num(baseline)}\""
      } else {
        ""
      }
      body.write("<tspan\{at}\{style}>")
      @svg.write_esc(body, span.text)
      body.write("</tspan>")
      first = false
    }
    baseline += label.line_height
  }
  if !body.is_empty() {
    out.write_group(
      "<text\{@svg.text_style(attrs, shared)} xml:space=\"preserve\">",
      body,
      "</text>",
    )
  }
}

///|
fn layout(
  measurer : @text.TextMeasurer,
  raw : String,
  font_size : Double,
  max_width : Double,
  style~ : Int32 = 0,
) -> @text.Label {
  @text.layout_label(
    Some(raw),
    false,
    measurer,
    font_size,
    max_width,
    base=style,
  )
}

///|
/// Sorts by `key`, keeping the order of equal keys as JavaScript's sort does.
fn[T] stable_sorted(items : Array[T], key : (T) -> Double) -> Array[T] {
  let indexed = items.mapi((i, item) => (i, item))
  indexed.sort_by((a, b) => {
    let by_key = key(a.1).compare(key(b.1))
    if by_key != 0 {
      by_key
    } else {
      a.0.compare(b.0)
    }
  })
  indexed.map(pair => pair.1)
}

///|
/// Draws a Wardley map.
pub fn render_wardley(
  model : WardleyModel,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  let natural = dimension(config, model.size.map(s => s.0), "width", 900)
  @common.fit_width(options, natural, 160, (plot_w, tight) => {
    draw(model, config, options, plot_w, natural, tight)
  })
}

///|
fn draw(
  model : WardleyModel,
  config : @types.Config,
  options : @types.RenderOptions,
  plot_w : Double,
  natural_w : Double,
  tight : Bool,
) -> @types.Rendered raise @errors.PeleError {
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.8125).round()
  let tiny = (size * 0.6875).round()
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)

  // A narrower map is not as much shorter, so that components keep some room between them.
  let plot_h = dimension(config, model.size.map(s => s.1), "height", 600) *
    @util.js_max(0.75, plot_w / natural_w)
  let show_grid = section(config).get("showGrid") is Some(True)
  let bounds = { min_x: 0, min_y: 0, max_x: plot_w, max_y: plot_h, }
  fn centered(
    out : @svg.Markup,
    label : @text.Label,
    cx : Double,
    cy : Double,
    attrs : String,
  ) -> Unit raise @errors.PeleError {
    bounds.grow(
      cx - label.width / 2,
      cy - label.height / 2,
      cx + label.width / 2,
      cy + label.height / 2,
    )
    @svg.write_label(out, label, cx, cy, attrs, icons?=options.icons)
  }
  fn starting(
    out : @svg.Markup,
    label : @text.Label,
    x : Double,
    y : Double,
    attrs : String,
  ) -> Unit raise @errors.PeleError {
    bounds.grow(
      x,
      y - label.size,
      x + label.width,
      y - label.size + label.height + 4,
    )
    write_start_label(out, label, x, y, attrs)
  }
  let wrap = if tight {
    @util.js_max(64, @util.js_min(120, plot_w / 2))
  } else {
    4000
  }
  let project_x = (value : Double) => value / 100 * plot_w
  let project_y = (value : Double) => plot_h - value / 100 * plot_h
  let stages = match model.stages {
    Some(given) if given.length() > 0 => given
    _ => default_stages
  }
  let boundaries = model.stage_boundaries.unwrap_or([])
  let custom = model.stage_boundaries is Some(_) &&
    boundaries.length() == stages.length()
  let frame = @svg.Markup::new()
  let stage_labels = @svg.Markup::new()
  let mut stage_bottom = plot_h
  let mut previous = 0.0
  let count = stages.length().to_double()
  for index, stage in stages {
    let start = if custom { previous } else { index.to_double() / count }
    let end = if custom {
      clamp(boundaries[index], 0, 1)
    } else {
      (index + 1).to_double() / count
    }
    previous = end
    if index > 0 {
      frame.write(
        "<path class=\"pele-wardley-stage\" d=\"M\{@svg.num(start * plot_w)},0V\{@svg.num(plot_h)}\" stroke=\"var(--_b)\" stroke-dasharray=\"4 4\"/>",
      )
    }
    let label = layout(
      measurer,
      stage,
      small,
      @util.js_max(48, (end - start).abs() * plot_w - 12),
    )
    centered(
      stage_labels,
      label,
      (start + end) / 2 * plot_w,
      plot_h + 8 + label.height / 2,
      " class=\"pele-wardley-stage-label\" font-size=\"\{small}\" fill=\"var(--_m)\"",
    )
    stage_bottom = @util.js_max(stage_bottom, plot_h + 8 + label.height)
  }
  if show_grid {
    for i in 1..<4 {
      let at = i.to_double()
      frame.write(
        "<path class=\"pele-wardley-grid\" d=\"M\{@svg.num(plot_w * at / 4)},0V\{@svg.num(plot_h)}M0,\{@svg.num(plot_h * at / 4)}H\{@svg.num(plot_w)}\" stroke=\"var(--_b)\" stroke-dasharray=\"2 6\"/>",
      )
    }
  }
  frame.write(
    "<path class=\"pele-wardley-axis\" d=\"M0,0V\{@svg.num(plot_h)}H\{@svg.num(plot_w)}\" stroke=\"\{LINE}\"/>",
  )
  let x_title = layout(measurer, "Evolution", small, wrap)
  let y_title = layout(measurer, "Visibility", small, wrap)
  let axis_attrs = " class=\"pele-wardley-axis-label\" font-size=\"\{small}\" font-weight=\"var(--_hw)\""
  let axis_labels = @svg.Markup::new()
  centered(
    axis_labels,
    x_title,
    plot_w / 2,
    stage_bottom + 6 + x_title.height / 2,
    axis_attrs,
  )
  @svg.write_label(
    axis_labels,
    y_title,
    -16,
    plot_h / 2,
    "\{axis_attrs} transform=\"rotate(-90 -16 \{@svg.num(plot_h / 2)})\"",
  )
  bounds.grow(-16 - y_title.height / 2, 0, 0, 0)
  let legend_top = stage_bottom + 6 + x_title.height + 10
  let positions : Map[String, Placed] = Map([])
  for node in model.nodes {
    positions.set(node.id, { x: project_x(node.x), y: project_y(node.y), node, })
  }

  // Pipelines: a box around the components, with the parent as a square on its top edge.
  let pipelines = @svg.Markup::new()
  let members : Map[String, Set[String]] = Map([])
  for pipeline in model.pipelines {
    members.set(pipeline.node_id, Set::from_array(pipeline.component_ids))
    let found = pipeline.component_ids.filter_map(id => positions.get(id))
    if found.is_empty() {
      continue
    }
    let parts = stable_sorted(found, p => p.x)
    let left = parts[0].x
    let right = parts[parts.length() - 1].x
    let y = parts[0].y
    let top = y - 2 * R
    if positions.get(pipeline.node_id) is Some(parent) {
      parent.x = (left + right) / 2
      parent.y = top - SQUARE / 6
    }
    bounds.grow(left - PIPELINE_PAD, top, right + PIPELINE_PAD, top + 4 * R)
    let dashes = if parts.length() > 1 {
      "<path d=\"M\{@svg.num(left)},\{@svg.num(y)}H\{@svg.num(right)}\" stroke=\"\{LINE}\" stroke-dasharray=\"4 4\"/>"
    } else {
      ""
    }
    pipelines.write("<g class=\"pele-wardley-pipeline\" data-id=\"")
    @svg.write_esc_text(pipelines, pipeline.node_id)
    pipelines.write(
      "\">" +
      "<rect x=\"\{@svg.num(left - PIPELINE_PAD)}\" y=\"\{@svg.num(top)}\" width=\"\{@svg.num(right - left + 2 * PIPELINE_PAD)}\" height=\"\{@svg.num(4 * R)}\" fill=\"var(--_s)\" stroke=\"var(--_b)\"\{@svg.ROUNDED}/>" +
      dashes +
      "</g>",
    )
  }
  let anchor_wrap = if tight { @util.js_max(64, plot_w / 2) } else { 4000 }
  let anchor_labels : Map[String, @text.Label] = Map([])
  let anchor_label = (node : WardleyNode) => {
    match anchor_labels.get(node.id) {
      Some(label) => label
      None => {
        let label = layout(
          measurer,
          node.label,
          small,
          anchor_wrap,
          style=@text.STYLE_BOLD,
        )
        anchor_labels.set(node.id, label)
        label
      }
    }
  }

  // How far from a node's center a line to it stops.
  let reach = (at : Placed, ux : Double, uy : Double) => {
    let node = at.node
    if node.class_name == "anchor" {
      let label = anchor_label(node)
      return 1.0 /
        @util.js_hypot(ux / (label.width / 2 + 5), uy / (small * 0.8))
    }
    if node.is_pipeline_parent {
      SQUARE / 2.0.sqrt()
    } else if node.source_strategy is Some(_) {
      2 * R
    } else {
      R
    }
  }

  // Quadrants around a node that a link runs through: 1 up and right, 2 down and right, 4 up and left, 8 down and left.
  let taken : Map[String, Int32] = Map([])
  let occupy = (at : Placed, ux : Double, uy : Double) => {
    if ux.abs() < 0.25 || uy.abs() < 0.25 {
      return
    }
    let quadrant = if ux > 0 {
      if uy < 0 {
        1
      } else {
        2
      }
    } else if uy < 0 {
      4
    } else {
      8
    }
    taken.set(at.node.id, taken.get(at.node.id).unwrap_or(0) | quadrant)
  }
  let links = @svg.Markup::new()
  for link in model.links {
    guard positions.get(link.source) is Some(from) &&
      positions.get(link.target) is Some(to) &&
      link.source != link.target else {
      continue
    }
    // A pipeline component belongs to its parent already.
    if members.get(link.target) is Some(set) && set.contains(link.source) {
      continue
    }
    let dx = to.x - from.x
    let dy = to.y - from.y
    let distance = @util.js_hypot(dx, dy)
    if distance < 0.01 {
      continue
    }
    let ux = dx / distance
    let uy = dy / distance
    let start = reach(from, ux, uy)
    let end = reach(to, ux, uy)
    if start + end >= distance {
      continue
    }
    occupy(from, ux, uy)
    occupy(to, -ux, -uy)
    let mut x1 = from.x + ux * start
    let mut y1 = from.y + uy * start
    let mut x2 = to.x - ux * end
    let mut y2 = to.y - uy * end
    let heads = StringBuilder()
    let trim = @svg.marker_trim("arrow_point")
    if link.flow is Some(Forward | Bidirectional) {
      heads.write_string(@svg.marker("arrow_point", x2, y2, ux, uy, LINE))
      x2 -= ux * trim
      y2 -= uy * trim
    }
    if link.flow is Some(Backward | Bidirectional) {
      heads.write_string(@svg.marker("arrow_point", x1, y1, -ux, -uy, LINE))
      x1 += ux * trim
      y1 += uy * trim
    }
    let caption = @svg.Markup::new()
    if link.label is Some(raw) && raw != "" {
      let label = layout(measurer, raw, tiny + 1, 200)
      // Beside the middle of the line, on its upper side.
      let side = if ux >= 0 { 1.0 } else { -1.0 }
      let px = uy * side
      let py = -ux * side
      let away = 5.0 + px.abs() * label.width / 2 + py.abs() * label.height / 2
      centered(
        caption,
        label,
        (from.x + to.x) / 2 + px * away,
        (from.y + to.y) / 2 + py * away,
        " class=\"pele-edge-label\" font-size=\"\{tiny + 1}\" fill=\"var(--_m)\"",
      )
    }
    let dashed_class = if link.dashed { " pele-wardley-dashed" } else { "" }
    let dashed_stroke = if link.dashed {
      " stroke-dasharray=\"6 6\""
    } else {
      ""
    }
    links.write("<g class=\"pele-edge\{dashed_class}\" data-id=\"")
    @svg.write_esc_text(links, link.source)
    links.write("-")
    @svg.write_esc_text(links, link.target)
    links.write_group(
      "\">" +
      "<path d=\"M\{@svg.num(x1)},\{@svg.num(y1)}L\{@svg.num(x2)},\{@svg.num(y2)}\" stroke=\"\{LINE}\"\{dashed_stroke}/>" +
      heads.to_string(),
      caption,
      "</g>",
    )
  }

  // Evolution: a dashed arrow to where the component is heading, drawn as an open circle.
  let trends = @svg.Markup::new()
  for trend in model.trends {
    guard positions.get(trend.node_id) is Some(origin) else { continue }
    let tx = project_x(trend.target_x)
    let ty = project_y(trend.target_y)
    let dx = tx - origin.x
    let dy = ty - origin.y
    let distance = @util.js_hypot(dx, dy)
    let start = if distance > 0 {
      reach(origin, dx / distance, dy / distance)
    } else {
      0
    }
    let arrow = if distance > start + R + 4 {
      let ux = dx / distance
      let uy = dy / distance
      let ex = tx - ux * (R + 2)
      let ey = ty - uy * (R + 2)
      let trim = @svg.marker_trim("arrow_point")
      "<path d=\"M\{@svg.num(origin.x + ux * start)},\{@svg.num(origin.y + uy * start)}L\{@svg.num(ex - ux * trim)},\{@svg.num(ey - uy * trim)}\" stroke=\"\{ACCENT}\" stroke-dasharray=\"4 4\"/>" +
      @svg.marker("arrow_point", ex, ey, ux, uy, ACCENT)
    } else {
      ""
    }
    bounds.grow(tx - R, ty - R, tx + R, ty + R)
    trends.write("<g class=\"pele-wardley-trend\" data-id=\"")
    @svg.write_esc_text(trends, trend.node_id)
    trends.write(
      "\">\{arrow}" +
      "<circle cx=\"\{@svg.num(tx)}\" cy=\"\{@svg.num(ty)}\" r=\"\{R}\" fill=\"var(--_bg)\" stroke=\"\{ACCENT}\"/></g>",
    )
  }
  let nodes = @svg.Markup::new()
  let tri = 1.2 * R
  let dot = 0.7 * R
  for _, at in positions {
    let node = at.node
    let x = at.x
    let y = at.y
    let anchor = node.class_name == "anchor"
    let strategy = node.source_strategy
    let shape = StringBuilder()
    if strategy is Some(kind) {
      let fill = match kind {
        "outsource" => "var(--_m)"
        "buy" => "var(--_a)"
        "build" => "var(--_s)"
        _ => "var(--_bg)"
      }
      shape.write_string(
        "<circle class=\"pele-wardley-\{kind}\" cx=\"\{@svg.num(x)}\" cy=\"\{@svg.num(y)}\" r=\"\{2.0 * R}\" fill=\"\{fill}\" stroke=\"\{LINE}\"/>",
      )
    }
    if strategy is Some("market") {
      let bx = tri * @math.cos(@math.PI / 6)
      let by = y + tri * @math.sin(@math.PI / 6)
      shape.write_string(
        "<path d=\"M\{@svg.num(x)},\{@svg.num(y - tri)}L\{@svg.num(x - bx)},\{@svg.num(by)}H\{@svg.num(x + bx)}Z\" fill=\"none\" stroke=\"\{LINE}\"/>",
      )
      for corner in [(x, y - tri), (x - bx, by), (x + bx, by)] {
        shape.write_string(
          "<circle cx=\"\{@svg.num(corner.0)}\" cy=\"\{@svg.num(corner.1)}\" r=\"\{@svg.num(dot)}\" fill=\"var(--_bg)\" stroke=\"\{LINE}\"/>",
        )
      }
    } else if node.is_pipeline_parent {
      shape.write_string(
        "<rect x=\"\{@svg.num(x - SQUARE / 2)}\" y=\"\{@svg.num(y - SQUARE / 2)}\" width=\"\{SQUARE}\" height=\"\{SQUARE}\" fill=\"var(--_bg)\" stroke=\"\{LINE}\"/>",
      )
    } else if !anchor {
      shape.write_string(
        "<circle cx=\"\{@svg.num(x)}\" cy=\"\{@svg.num(y)}\" r=\"\{R}\" fill=\"var(--_bg)\" stroke=\"\{LINE}\"/>",
      )
    }
    if node.inertia {
      let offset = (if node.is_pipeline_parent { SQUARE / 2 } else { R }) +
        10 +
        (if strategy is Some(_) { R + 4 } else { 0 })
      shape.write_string(
        "<rect class=\"pele-wardley-inertia\" x=\"\{@svg.num(x + offset)}\" y=\"\{@svg.num(y - R)}\" width=\"4\" height=\"\{2.0 * R}\" fill=\"\{LINE}\"/>",
      )
    }
    let ox = node.label_offset_x.map(v => clamp(v, -5000, 5000))
    let oy = node.label_offset_y.map(v => clamp(v, -5000, 5000))
    let caption = @svg.Markup::new()
    if anchor {
      centered(
        caption,
        anchor_label(node),
        x + ox.unwrap_or(0),
        y + oy.unwrap_or(-3),
        " class=\"pele-label\" font-size=\"\{small}\" font-weight=\"var(--_hw)\"",
      )
    } else {
      let label = layout(measurer, node.label, small, wrap)
      let attrs = " class=\"pele-label\" font-size=\"\{small}\""
      let lift = LABEL_OFFSET + (if strategy is Some(_) { 10 } else { 0 })
      if ox is Some(_) || oy is Some(_) {
        starting(
          caption,
          label,
          x + ox.unwrap_or(lift),
          y + oy.unwrap_or(-lift),
          attrs,
        )
      } else if node.in_pipeline {
        centered(caption, label, x, y + 2 * R + 4 + label.height / 2, attrs)
      } else {
        // The label goes up and to the right unless a link leaves that way; then the next free corner.
        let busy = taken.get(node.id).unwrap_or(0)
        let corner = if (busy & 1) == 0 {
          1
        } else if (busy & 2) == 0 {
          2
        } else if (busy & 4) == 0 {
          4
        } else if (busy & 8) == 0 {
          8
        } else {
          1
        }
        let right = corner == 1 || corner == 2
        let up = corner == 1 || corner == 4
        starting(
          caption,
          label,
          if right {
            x + lift
          } else {
            x - lift - label.width
          },
          if up {
            y - lift
          } else {
            y + lift + small * 0.75
          },
          attrs,
        )
      }
    }
    bounds.grow(x - 2 * R, y - 2 * R, x + 2 * R + 20, y + 2 * R)
    let kind = if anchor {
      "anchor"
    } else if node.is_pipeline_parent {
      "pipeline-parent"
    } else if node.in_pipeline {
      "pipeline-component"
    } else {
      "component"
    }
    nodes.write("<g class=\"pele-node pele-wardley-\{kind}\" data-id=\"")
    @svg.write_esc_text(nodes, node.id)
    nodes.write_group("\">\{shape.to_string()}", caption, "</g>")
  }
  let annotations = @svg.Markup::new()
  for annotation in model.annotations {
    let label = layout(
      measurer,
      annotation.number.to_string(),
      tiny,
      4000,
      style=@text.STYLE_BOLD,
    )
    let x = project_x(annotation.x)
    let y = project_y(annotation.y)
    let r = @util.js_max(10, label.width / 2 + 4)
    bounds.grow(x - r, y - r, x + r, y + r)
    let mark = "<circle cx=\"\{@svg.num(x)}\" cy=\"\{@svg.num(y)}\" r=\"\{@svg.num(r)}\" fill=\"var(--_bg)\" stroke=\"\{LINE}\"/>" +
      @svg.label_svg(
        label,
        x,
        y,
        " font-size=\"\{tiny}\" font-weight=\"var(--_hw)\"",
      )
    annotations.write(
      "<g class=\"pele-wardley-annotation\" data-id=\"\{@svg.esc_text(annotation.number.to_string())}\">\{mark}</g>",
    )
  }
  let listed = stable_sorted(model.annotations.filter(a => a.text != ""), a => {
    a.number
  })
  if !listed.is_empty() {
    let list_wrap = if tight { @util.js_max(80, plot_w - 20) } else { 320 }
    let lines = listed.map(a => {
      layout(measurer, "\{a.number}. \{a.text}", small, list_wrap)
    })
    let mut width = 0.0
    let mut height = 0.0
    for line in lines {
      width = @util.js_max(width, line.width)
      height += line.height
    }
    width += 20
    height += 14
    // Without a position the list goes under the map, where it covers nothing.
    let (bx, by) = match model.annotations_box {
      Some((x, y)) =>
        (
          clamp(project_x(x), 0, @util.js_max(0, plot_w - width)),
          clamp(project_y(y), 0, @util.js_max(0, plot_h - height)),
        )
      None => (0, legend_top)
    }
    bounds.grow(bx, by, bx + width, by + height)
    let rows = @svg.Markup::new()
    let mut y = by + 7
    for line in lines {
      write_start_label(
        rows,
        line,
        bx + 10,
        y + line.line_height / 2 + small * 0.35,
        " font-size=\"\{small}\"",
      )
      y += line.height
    }
    annotations.write_group(
      "<g class=\"pele-wardley-annotations\"><rect x=\"\{@svg.num(bx)}\" y=\"\{@svg.num(by)}\" width=\"\{@svg.num(width)}\" height=\"\{@svg.num(height)}\" fill=\"var(--_bg)\" stroke=\"var(--_b)\"\{@svg.ROUNDED}/>",
      rows,
      "</g>",
    )
  }
  let notes = @svg.Markup::new()
  for note in model.notes {
    starting(
      notes,
      layout(
        measurer,
        note.text,
        small,
        @util.js_min(360, plot_w * 0.6),
        style=@text.STYLE_BOLD,
      ),
      project_x(note.x),
      project_y(note.y),
      " class=\"pele-wardley-note\" font-size=\"\{small}\" font-weight=\"var(--_hw)\"",
    )
  }

  // Accelerators point right, deaccelerators left.
  let forces = @svg.Markup::new()
  fn force(
    name : String,
    px : Double,
    py : Double,
    forward : Bool,
  ) -> Unit raise @errors.PeleError {
    let x = project_x(px)
    let y = project_y(py)
    let half = FORCE_HEIGHT / 2
    let tip = if forward { x + FORCE_WIDTH } else { x }
    let tail = if forward { x } else { x + FORCE_WIDTH }
    let neck = if forward {
      x + FORCE_WIDTH - FORCE_HEAD
    } else {
      x + FORCE_HEAD
    }
    let d = "M\{@svg.num(tail)},\{@svg.num(y - half)}H\{@svg.num(neck)}V\{@svg.num(y - half - 8)}L\{@svg.num(tip)},\{@svg.num(y)}L\{@svg.num(neck)},\{@svg.num(y + half + 8)}V\{@svg.num(y + half)}H\{@svg.num(tail)}Z"
    bounds.grow(x, y - half - 8, x + FORCE_WIDTH, y + half + 8)
    let kind = if forward { "accelerator" } else { "deaccelerator" }
    forces.write("<g class=\"pele-wardley-\{kind}\" data-id=\"")
    @svg.write_esc_text(forces, name)
    forces.write("\"><path d=\"\{d}\" fill=\"var(--_s)\" stroke=\"\{LINE}\"/>")
    centered(
      forces,
      layout(measurer, name, tiny + 1, 160, style=@text.STYLE_BOLD),
      x + FORCE_WIDTH / 2,
      y + half + 8 + 12,
      " font-size=\"\{tiny + 1}\" font-weight=\"var(--_hw)\"",
    )
    forces.write("</g>")
  }
  for a in model.accelerators {
    force(a.name, a.x, a.y, true)
  }
  for d in model.deaccelerators {
    force(d.name, d.x, d.y, false)
  }
  let title = @text.layout_label(
    model.title,
    false,
    measurer,
    size,
    if tight {
      @util.js_max(80, plot_w)
    } else {
      4000
    },
    base=@text.STYLE_BOLD,
  )
  let title_height = if title.height > 0 { title.height + 12 } else { 0 }
  let left = @util.js_min(bounds.min_x, plot_w / 2 - title.width / 2)
  let right = @util.js_max(bounds.max_x, plot_w / 2 + title.width / 2)
  let tx = pad - left
  let ty = pad + title_height - bounds.min_y
  let total_width = (right - left + 2 * pad).ceil()
  let total_height = (bounds.max_y - bounds.min_y + title_height + 2 * pad).ceil()
  let content = @svg.Markup::new()
  @svg.write_label(
    content,
    title,
    tx + plot_w / 2,
    pad + title.height / 2,
    " class=\"pele-title\" font-weight=\"var(--_tw)\"",
  )
  content.write("<g transform=\"translate(\{@svg.num(tx)},\{@svg.num(ty)})\">")
  content.write_group(
    "<g class=\"pele-wardley-frame\" fill=\"none\">", frame, "</g>",
  )
  content.write_markup(stage_labels)
  content.write_markup(axis_labels)
  content.write_markup(pipelines)
  if !links.is_empty() {
    content.write_group("<g class=\"pele-edges\" fill=\"none\">", links, "</g>")
  }
  if !trends.is_empty() {
    content.write_group(
      "<g class=\"pele-wardley-trends\" fill=\"none\">", trends, "</g>",
    )
  }
  content.write_markup(nodes)
  content.write_markup(annotations)
  content.write_markup(notes)
  content.write_markup(forces)
  content.write("</g>")
  {
    svg: @svg.markup_document(
      "wardley",
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
