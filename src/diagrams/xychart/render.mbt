///|
const TICK : Double = 4

///|
const SWATCH : Double = 12

///|
const ROW : Double = 26

///|
const LEGEND_GAP : Double = 24

///|
const LIMIT : Double = 1.0e300

///|
priv struct Mark {
  at : Double
  label : @text.Label
}

///|
fn record(value : Json?) -> Map[String, Json] {
  match value {
    Some(Object(fields)) => fields
    _ => {}
  }
}

///|
fn on(
  config : Map[String, Json],
  key : String,
  fallback~ : Bool = true,
) -> Bool {
  match config.get(key) {
    Some(True) => true
    Some(False) => false
    _ => fallback
  }
}

///|
fn dimension(value : Json?, fallback : Double) -> Double {
  match value {
    Some(Number(number, ..)) if number > 0 =>
      @util.js_min(@util.js_max(number, 100), 4000).round()
    _ => fallback
  }
}

///|
/// A number inside the range the drawing can hold, and none for one that is not finite.
fn finite(value : Double?) -> Double? {
  match value {
    Some(number) if !number.is_nan() && !number.is_inf() =>
      Some(@util.js_min(@util.js_max(number, -LIMIT), LIMIT))
    _ => None
  }
}

///|
fn widest(marks : Array[Mark]) -> Double {
  let mut width = 0.0
  for mark in marks {
    width = @util.js_max(width, mark.label.width)
  }
  width
}

///|
priv enum Anchor {
  Start
  Middle
  End
}

///|
fn Anchor::name(self : Anchor) -> String {
  match self {
    Start => "start"
    Middle => "middle"
    End => "end"
  }
}

///|
/// Writes a label with its left edge, center or right edge at `x`.
/// A plain one-line label keeps its place when the text is wider or narrower than measured.
fn aligned(
  label : @text.Label,
  x : Double,
  y : Double,
  anchor : Anchor,
) -> String {
  if label.lines.length() == 1 &&
    label.lines[0].length() == 1 &&
    label.lines[0][0].style == 0 {
    return "<text x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y + label.size * 0.35)}\" text-anchor=\"\{anchor.name()}\">\{@svg.esc(label.lines[0][0].text)}</text>"
  }
  let shift = match anchor {
    Start => label.width / 2
    End => -label.width / 2
    Middle => 0
  }
  @svg.label_svg(label, x + shift, y, "")
}

///|
fn clamp(v : Double) -> Double {
  @util.js_min(@util.js_max(v, 0), 1)
}

///|
/// Draws an XY chart.
/// Raises a semantic `PeleError` when the chart has no series.
pub fn render_xychart(
  model : XyChartDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  if model.plots.is_empty() {
    raise @errors.pele_error(
      "No Plot to render, please provide a plot with some data",
      code=Semantic,
      kind="xychart",
    )
  }
  let chart = record(config.get("xyChart"))
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.875).round()
  let tiny = (size * 0.75).round()
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let natural = dimension(chart.get("width"), 700)
  let width = @common.cap_width(options, natural, 240)
  // A narrower chart is not as much shorter, so that the plot keeps room for its marks.
  let height = (dimension(chart.get("height"), 500) *
  @util.js_max(0.6, width / natural)).round()
  let horizontal = match model.orientation {
    Some(orientation) => orientation is Horizontal
    None => chart.get("chartOrientation") is Some(String("horizontal"))
  }
  // The value of a bar is always written past its end, which is what showDataLabelOutsideBar asks
  // for in Mermaid.
  // Inside, whether it fits changes from bar to bar and with the width of the chart.
  let show_values = on(chart, "showDataLabel", fallback=false)
  let x_axis = model.x_axis
  let plots = model.plots
  let text = (raw : String?, font_size : Double, max : Double) => {
    @text.layout_label(raw, false, measurer, font_size, max)
  }
  let line_height = text(Some("0"), small, 4000).height
  let tiny_height = text(Some("0"), tiny, 4000).height
  let title = @text.layout_label(
    if on(chart, "showTitle") {
      model.title
    } else {
      None
    },
    false,
    measurer,
    size,
    width - 2 * pad,
    base=@text.STYLE_BOLD,
  )
  let title_space = if title.height > 0 { title.height + 12 } else { 0 }
  let legend : Array[(Int32, @text.Label)] = []
  let mut legend_width = 0.0
  if on(chart, "showLegend") {
    for index, plot in plots {
      if plot.title == "" {
        continue
      }
      let label = text(Some(plot.title), small, width * 0.3)
      legend.push((index, label))
      legend_width = @util.js_max(legend_width, label.width + SWATCH + 8)
    }
  }
  let legend_space = if legend.length() > 0 {
    legend_width + LEGEND_GAP
  } else {
    0
  }

  // The value range: as written, or taken from the data, where bars stand on zero and the
  // range grows to whole steps.
  let bars = plots.filter(plot => plot.kind is Bar).length()
  let mut lo = model.y_axis.min
  let mut hi = model.y_axis.max
  let exact = model.has_set_y_axis &&
    !lo.is_nan() &&
    !lo.is_inf() &&
    !hi.is_nan() &&
    !hi.is_inf() &&
    lo != hi
  if exact {
    lo = finite(Some(lo)).unwrap()
    hi = finite(Some(hi)).unwrap()
  } else {
    lo = @double.infinity
    hi = @double.neg_infinity
    for plot in plots {
      for entry in plot.data {
        guard finite(entry.1) is Some(value) else { continue }
        if value < lo {
          lo = value
        }
        if value > hi {
          hi = value
        }
      }
    }
    if lo > hi {
      lo = 0
      hi = 0
    }
    if bars > 0 {
      lo = @util.js_min(lo, 0)
      hi = @util.js_max(hi, 0)
    }
    if lo == hi {
      if lo == 0 {
        hi = 1
      } else {
        lo -= lo.abs() / 2
        hi += hi.abs() / 2
      }
    }
  }
  let value_marks = (length : Double, spacing : Double) => {
    let step = tick_step(
      (hi - lo).abs(),
      @util.js_max(2, @util.js_min(10, (length / spacing).floor())),
    )
    if !exact {
      lo = tick_value(step, (tick_index(step, lo) + 1.0e-9).floor())
      hi = tick_value(step, (tick_index(step, hi) - 1.0e-9).ceil())
    }
    ticks_between(@util.js_min(lo, hi), @util.js_max(lo, hi), step).map(value => {
      at: (value - lo) / (hi - lo),
      label: text(Some(number_text(value)), small, 4000),
    })
  }

  // Places along the category axis are fractions of its length.
  // Categories and bars sit in the middle of equal slots; the points of a line on a numeric axis run from end to end.
  let mut count = 1.0
  match x_axis.kind {
    Band(categories) => count = @util.js_max(categories.length().to_double(), 1)
    Linear(_, _) =>
      for plot in plots {
        count = @util.js_max(count, plot.data.length().to_double())
      }
  }
  let slot = 1.0 / count
  let band = x_axis.kind is Band(_)
  let inset = if band || bars > 0 { slot / 2 } else { 0.0 }
  let (x0, x1) = match x_axis.kind {
    Linear(min, max) => (finite(Some(min)), finite(Some(max)))
    Band(_) => (None, None)
  }
  let ranged = match (x0, x1) {
    (Some(a), Some(b)) => a != b
    _ => false
  }
  let place = (i : Int32, n : Int32) => {
    if band {
      (i.to_double() + 0.5) * slot
    } else {
      let along = if n > 1 {
        i.to_double() / (n - 1).to_double()
      } else if ranged {
        0.0
      } else {
        0.5
      }
      inset + along * (1 - 2 * inset)
    }
  }
  let category_conf = record(chart.get("xAxis"))
  let value_conf = record(chart.get("yAxis"))
  let left_conf = if horizontal { category_conf } else { value_conf }
  let bottom_conf = if horizontal { value_conf } else { category_conf }
  let left_title = text(
    if on(left_conf, "showTitle") {
      Some(if horizontal { x_axis.title } else { model.y_axis.title })
    } else {
      None
    },
    small,
    height * 0.8,
  )
  let bottom_title = text(
    if on(bottom_conf, "showTitle") {
      Some(if horizontal { model.y_axis.title } else { x_axis.title })
    } else {
      None
    },
    small,
    width * 0.8,
  )
  let left_tick = if on(left_conf, "showTick") { TICK } else { 0 }
  let bottom_tick = if on(bottom_conf, "showTick") { TICK } else { 0 }
  let left_labels = on(left_conf, "showLabel")
  let bottom_labels = on(bottom_conf, "showLabel")
  let wrap_at = if horizontal {
    width * 0.3
  } else {
    @util.js_max(48, (width - 2 * pad - 64 - legend_space) * slot - 8)
  }
  let categories = match x_axis.kind {
    Band(names) if on(category_conf, "showLabel") =>
      names.map(name => text(Some(name), small, wrap_at))
    _ => []
  }
  let mut category_width = 0.0
  let mut category_height = 0.0
  for label in categories {
    category_width = @util.js_max(category_width, label.width)
    category_height = @util.js_max(category_height, label.height)
  }

  // The labelled places of the category axis.
  // Labels that would run into each other are thinned out.
  let category_marks = (length : Double) => {
    let marks : Array[Mark] = []
    match x_axis.kind {
      Band(names) => {
        let need = if categories.is_empty() {
          8.0
        } else if horizontal {
          category_height
        } else {
          category_width + 12
        }
        let every = @util.js_max(1, (need / (length * slot)).ceil())
        let mut i = 0.0
        while i < names.length().to_double() {
          marks.push({
            at: (i + 0.5) * slot,
            label: if i < categories.length().to_double() {
              categories[i.to_int()]
            } else {
              text(None, small, 0)
            },
          })
          i += every
        }
      }
      Linear(_, _) =>
        if ranged {
          let a = x0.unwrap()
          let b = x1.unwrap()
          let step = tick_step(
            (b - a).abs(),
            @util.js_max(
              2,
              @util.js_min(
                10,
                (length / (if horizontal { 32.0 } else { 80.0 })).floor(),
              ),
            ),
          )
          for
            value in ticks_between(@util.js_min(a, b), @util.js_max(a, b), step) {
            marks.push({
              at: inset + (value - a) / (b - a) * (1 - 2 * inset),
              label: text(Some(number_text(value)), small, 4000),
            })
          }
        } else if x0 is Some(a) {
          marks.push({
            at: 0.5,
            label: text(Some(number_text(a)), small, 4000),
          })
        }
    }
    marks
  }

  // Room past the end of the value axis for what is written beside a point or a bar.
  let mut point_label_width = 0.0
  let mut value_width = 0.0
  for plot in plots {
    for label in plot.point_labels.unwrap_or([]) {
      point_label_width = @util.js_max(
        point_label_width,
        measurer.width(label, tiny, 0),
      )
    }
    if show_values && horizontal && plot.kind is Bar {
      for entry in plot.data {
        let shown = match finite(entry.1) {
          Some(value) => number_text(value)
          None => ""
        }
        value_width = @util.js_max(value_width, measurer.width(shown, tiny, 0))
      }
    }
  }
  let bottom_label_height = if !bottom_labels {
    0.0
  } else if horizontal || !band {
    line_height
  } else {
    category_height
  }
  let bottom_space = bottom_tick +
    (if bottom_label_height > 0 { bottom_label_height + 4 } else { 0 }) +
    (if bottom_title.height > 0 { bottom_title.height + 4 } else { 0 })
  let headroom = if horizontal {
    0.0
  } else if point_label_width > 0 || show_values {
    tiny_height + 4
  } else if left_labels {
    line_height / 2
  } else {
    0.0
  }
  let top = pad + title_space + headroom
  let plot_height = @util.js_max(1, height - pad - bottom_space - top)
  let bottom = top + plot_height
  let left_marks = if horizontal {
    category_marks(plot_height)
  } else {
    value_marks(plot_height, 56)
  }
  let left_label_width = if left_labels { widest(left_marks) } else { 0.0 }
  let left = pad +
    (if left_title.height > 0 { left_title.height + 6 } else { 0 }) +
    (if left_label_width > 0 { left_label_width + 6 } else { 0 }) +
    left_tick
  let beside = @util.js_max(
    if point_label_width > 0 {
      point_label_width + 12
    } else {
      0
    },
    if value_width > 0 {
      value_width + 8
    } else {
      0
    },
  )
  let reach = if horizontal { @util.js_min(width * 0.25, beside) } else { 0.0 }
  let mut plot_width = @util.js_max(
    1,
    width - pad - left - legend_space - reach,
  )
  let bottom_marks = if horizontal {
    value_marks(plot_width, 80)
  } else {
    category_marks(plot_width)
  }
  if bottom_labels && legend_space + reach == 0 {
    let mut over = 0.0
    for mark in bottom_marks {
      over = @util.js_max(
        over,
        mark.at * plot_width + mark.label.width / 2 - plot_width,
      )
    }
    plot_width = @util.js_max(1, plot_width - over)
  }
  let right = left + plot_width
  let px = (c : Double, v : Double) => {
    if horizontal {
      left + v * plot_width
    } else {
      left + c * plot_width
    }
  }
  let py = (c : Double, v : Double) => {
    if horizontal {
      top + c * plot_height
    } else {
      bottom - v * plot_height
    }
  }
  let scale = (value : Double) => (value - lo) / (hi - lo)

  // A line across the plot at a place on the value axis.
  let rule = (v : Double) => {
    if horizontal {
      "M\{@svg.num(px(0, v))},\{@svg.num(top)}V\{@svg.num(bottom)}"
    } else {
      "M\{@svg.num(left)},\{@svg.num(py(0, v))}H\{@svg.num(right)}"
    }
  }
  let grid = StringBuilder()
  for mark in (if horizontal { bottom_marks } else { left_marks }) {
    grid.write_string(rule(mark.at))
  }
  let axis = StringBuilder()
  let labels = StringBuilder()
  if on(left_conf, "showAxisLine") {
    axis.write_string("M\{@svg.num(left)},\{@svg.num(top)}V\{@svg.num(bottom)}")
  }
  if on(bottom_conf, "showAxisLine") {
    axis.write_string(
      "M\{@svg.num(left)},\{@svg.num(bottom)}H\{@svg.num(right)}",
    )
  }
  for mark in left_marks {
    let y = if horizontal {
      top + mark.at * plot_height
    } else {
      bottom - mark.at * plot_height
    }
    if left_tick != 0 {
      axis.write_string(
        "M\{@svg.num(left)},\{@svg.num(y)}h\{@svg.num(-left_tick)}",
      )
    }
    if left_labels {
      labels.write_string(aligned(mark.label, left - left_tick - 6, y, End))
    }
  }
  for mark in bottom_marks {
    let at = left + mark.at * plot_width
    if bottom_tick != 0 {
      axis.write_string(
        "M\{@svg.num(at)},\{@svg.num(bottom)}v\{@svg.num(bottom_tick)}",
      )
    }
    if bottom_labels {
      labels.write_string(
        aligned(
          mark.label,
          at,
          bottom + bottom_tick + 4 + mark.label.height / 2,
          Middle,
        ),
      )
    }
  }
  let span = (if horizontal { plot_height } else { plot_width }) * slot
  let group = span * 0.7
  let thickness = group / @util.js_max(bars.to_double(), 1)
  let gap = if bars > 1 { @util.js_min(2, thickness * 0.2) } else { 0.0 }
  let base = clamp(scale(0))
  // Bars that go both ways get a line to stand on.
  if bars > 0 && base > 0 && base < 1 {
    axis.write_string(rule(base))
  }
  // Lines are drawn over the bars wherever they were declared, as a bar would hide part of one
  // under it.
  // A series keeps the color of its place in the source.
  let series = StringBuilder()
  let lines = StringBuilder()
  let outside = StringBuilder()
  let point_labels = StringBuilder()
  let mut bar = 0
  for index, plot in plots {
    let color = @svg.series_color(index)
    let id = if plot.title != "" {
      " data-id=\"\{@svg.esc_text(plot.title)}\""
    } else {
      ""
    }
    // A series declared before the categories can hold more values than there are categories.
    let n = if band {
      plot.data.length().min(count.to_int())
    } else {
      plot.data.length()
    }
    if plot.kind is Bar {
      let offset = (bar.to_double() - (bars - 1).to_double() / 2) * thickness -
        (thickness - gap) / 2
      bar += 1
      let rects = StringBuilder()
      for i in 0..<n {
        guard finite(plot.data[i].1) is Some(value) else { continue }
        let c = place(i, n)
        let v = clamp(scale(value))
        let from = @util.js_min(base, v)
        let to = @util.js_max(base, v)
        let bx = if horizontal { px(c, from) } else { px(c, 0) + offset }
        let by = if horizontal { py(c, 0) + offset } else { py(c, to) }
        let bw = if horizontal {
          (to - from) * plot_width
        } else {
          thickness - gap
        }
        let bh = if horizontal {
          thickness - gap
        } else {
          (to - from) * plot_height
        }
        rects.write_string(
          "<rect x=\"\{@svg.num(bx)}\" y=\"\{@svg.num(by)}\" width=\"\{@svg.num(bw)}\" height=\"\{@svg.num(bh)}\"/>",
        )
        if !show_values {
          continue
        }
        let label = number_text(value)
        let w = measurer.width(label, tiny, 0)
        // Towards the end of the bar: 1 when it runs up or right from the baseline, -1 the other way.
        let out = if v >= base { 1.0 } else { -1.0 }
        let mut tx = bx + bw / 2
        let mut ty = by + bh / 2
        let mut anchor = "middle"
        if horizontal {
          if bh < tiny {
            continue
          }
          tx = (if out > 0 { bx + bw } else { bx }) + out * 6
          anchor = if out > 0 { "start" } else { "end" }
        } else {
          if w + 2 > span / bars.to_double() {
            continue
          }
          ty = (if out > 0 { by } else { by + bh }) -
            out * (tiny_height / 2 + 2)
        }
        outside.write_string(
          "<text x=\"\{@svg.num(tx)}\" y=\"\{@svg.num(ty + tiny * 0.35)}\" text-anchor=\"\{anchor}\">\{label}</text>",
        )
      }
      series.write_string(
        "<g class=\"pele-series pele-bars\"\{id} fill=\"\{color}\">\{rects.to_string()}</g>",
      )
      continue
    }

    // A line is cut where it leaves the value range, so it stays inside the plot.
    let d = StringBuilder()
    let dots = StringBuilder()
    let mut pen = false
    let mut pc = 0.0
    let mut pv = @double.not_a_number
    for i in 0..<n {
      guard finite(plot.data[i].1) is Some(value) else {
        pv = @double.not_a_number
        continue
      }
      let c = place(i, n)
      let v = scale(value)
      let visible = v >= 0 && v <= 1
      if pv.is_nan() {
        if visible {
          d.write_string("M\{@svg.num(px(c, v))},\{@svg.num(py(c, v))}")
        }
        pen = visible
      } else {
        let dv = v - pv
        let mut t0 = 0.0
        let mut t1 = 1.0
        if dv != 0 {
          let a = -pv / dv
          let b = (1.0 - pv) / dv
          t0 = @util.js_max(t0, @util.js_min(a, b))
          t1 = @util.js_min(t1, @util.js_max(a, b))
        } else if !visible {
          t0 = 2
        }
        if t0 <= t1 {
          let c0 = pc + (c - pc) * t0
          let v0 = pv + dv * t0
          let c1 = pc + (c - pc) * t1
          let v1 = pv + dv * t1
          if !pen || t0 > 0 {
            d.write_string("M\{@svg.num(px(c0, v0))},\{@svg.num(py(c0, v0))}")
          }
          d.write_string("L\{@svg.num(px(c1, v1))},\{@svg.num(py(c1, v1))}")
        }
        pen = visible
      }
      pc = c
      pv = v
      if !visible {
        continue
      }
      let cx = px(c, v)
      let cy = py(c, v)
      if span >= 12 {
        dots.write_string(
          "<circle cx=\"\{@svg.num(cx)}\" cy=\"\{@svg.num(cy)}\" r=\"3\"/>",
        )
      }
      let label = text(
        match plot.point_labels {
          Some(names) if i < names.length() => Some(names[i])
          _ => None
        },
        tiny,
        4000,
      )
      if label.height > 0 {
        let half = label.width / 2
        point_labels.write_string(
          if horizontal {
            aligned(label, cx + 10, cy, Start)
          } else {
            aligned(
              label,
              @util.js_max(@util.js_min(cx, right - half), left + half),
              cy - 6 - label.height / 2,
              Middle,
            )
          },
        )
      }
    }
    lines.write_string(
      "<g class=\"pele-series pele-line\"\{id} fill=\"\{color}\">" +
      (if d.is_empty() {
        ""
      } else {
        "<path d=\"\{d.to_string()}\" fill=\"none\" stroke=\"\{color}\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>"
      }) +
      dots.to_string() +
      "</g>",
    )
  }
  let titles = StringBuilder()
  if left_title.height > 0 {
    let rotated = @svg.label_svg(left_title, 0, 0, "")
    titles.write_string(
      "<g transform=\"translate(\{@svg.num(pad + left_title.height / 2)},\{@svg.num(top + plot_height / 2)}) rotate(-90)\">\{rotated}</g>",
    )
  }
  titles.write_string(
    @svg.label_svg(
      bottom_title,
      left + plot_width / 2,
      height - pad - bottom_title.height / 2,
      "",
    ),
  )
  let legend_out = StringBuilder()
  let mut legend_height = 0.0
  for item in legend {
    legend_height += @util.js_max(ROW, item.1.height + 6)
  }
  let mut ly = top + @util.js_max(0, (plot_height - legend_height) / 2)
  let lx = right + reach + LEGEND_GAP
  for item in legend {
    let (index, label) = item
    let row = @util.js_max(ROW, label.height + 6)
    if ly + row > height {
      break
    }
    let y = ly + row / 2
    let color = @svg.series_color(index)
    legend_out.write_string(
      "<g class=\"pele-legend-item\" data-id=\"\{@svg.esc_text(plots[index].title)}\">" +
      (if plots[index].kind is Bar {
        "<rect x=\"\{@svg.num(lx)}\" y=\"\{@svg.num(y - SWATCH / 2)}\" width=\"\{SWATCH}\" height=\"\{SWATCH}\" rx=\"2\" fill=\"\{color}\"/>"
      } else {
        "<path d=\"M\{@svg.num(lx)},\{@svg.num(y)}h\{SWATCH}\" stroke=\"\{color}\" stroke-width=\"2\" stroke-linecap=\"round\"/>"
      }) +
      @svg.label_svg(label, lx + SWATCH + 8 + label.width / 2, y, "") +
      "</g>",
    )
    ly += row
  }
  let content = StringBuilder()
  content.write_string(
    @svg.label_svg(
      title,
      width / 2,
      pad + title.height / 2,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
    ),
  )
  if !grid.is_empty() {
    content.write_string(
      "<path class=\"pele-grid\" d=\"\{grid.to_string()}\" stroke=\"var(--_a)\"/>",
    )
  }
  content.write_string(
    "<g class=\"pele-plot\">\{series.to_string()}\{lines.to_string()}</g>",
  )
  if !axis.is_empty() {
    content.write_string(
      "<path class=\"pele-axis\" d=\"\{axis.to_string()}\" fill=\"none\" stroke=\"var(--_b)\"/>",
    )
  }
  if !labels.is_empty() {
    content.write_string(
      "<g class=\"pele-axis-labels\" font-size=\"\{small}\" fill=\"var(--_m)\">\{labels.to_string()}</g>",
    )
  }
  if !titles.is_empty() {
    content.write_string(
      "<g class=\"pele-axis-titles\" font-size=\"\{small}\">\{titles.to_string()}</g>",
    )
  }
  if !outside.is_empty() {
    content.write_string(
      "<g class=\"pele-data-labels\" font-size=\"\{tiny}\">\{outside.to_string()}</g>",
    )
  }
  if !point_labels.is_empty() {
    content.write_string(
      "<g class=\"pele-point-labels\" font-size=\"\{tiny}\">\{point_labels.to_string()}</g>",
    )
  }
  if !legend_out.is_empty() {
    content.write_string(
      "<g class=\"pele-legend\" font-size=\"\{small}\">\{legend_out.to_string()}</g>",
    )
  }
  {
    svg: @svg.svg_document(
      "xychart",
      width,
      height,
      size,
      options,
      model.acc_title,
      model.acc_descr,
      content.to_string(),
    ),
    width,
    height,
    links: [],
  }
}
