///|
const WIDTH : Double = 800

///|
const MIN_PLOT : Double = 240

///|
const LABEL_GAP : Double = 8

///|
fn setting(
  config : @types.Config,
  key : String,
  min : Double,
  max : Double,
) -> Double? {
  guard config.get("gantt") is Some(Object(gantt)) else { return None }
  match gantt.get(key) {
    Some(Number(value, ..)) if !value.is_nan() && !value.is_inf() =>
      Some(@util.js_min(max, @util.js_max(min, value)))
    _ => None
  }
}

///|
fn text_setting(config : @types.Config, key : String) -> String? {
  guard config.get("gantt") is Some(Object(gantt)) else { return None }
  match gantt.get(key) {
    Some(String(value)) => Some(value)
    _ => None
  }
}

///|
fn flag(config : @types.Config, key : String) -> Bool {
  guard config.get("gantt") is Some(Object(gantt)) else { return false }
  gantt.get(key) is Some(True)
}

///|
/// The text with every `<br>` turned into a space, as `replace(/<br\s*\/?>/gi, ' ')`.
fn breaks_to_spaces(raw : String) -> String {
  let out = StringBuilder()
  let n = raw.length()
  let mut i = 0
  while i < n {
    if caseless_at(raw, i, "<br") {
      let mut e = skip_spaces(raw, i + 3)
      if @util.code_at(raw, e) == 47 {
        e += 1
      }
      if @util.code_at(raw, e) == 62 {
        out.write_char(' ')
        i = e + 1
        continue
      }
    }
    @util.write_range(out, raw, i, i + 1)
    i += 1
  }
  out.to_string()
}

///|
/// A task label sits on one row, so only its first line is kept.
fn one_line(
  raw : String,
  measurer : @text.TextMeasurer,
  size : Double,
) -> @text.Label {
  let label = @text.layout_label(
    Some(breaks_to_spaces(raw)),
    false,
    measurer,
    size,
    4000,
  )
  if label.lines.length() <= 1 {
    return label
  }
  {
    ..label,
    lines: [label.lines[0]],
    widths: [label.widths[0]],
    width: label.widths[0],
    height: label.line_height,
  }
}

///|
/// Whether scheduling gave the task a start and an end.
/// One that waits on a task that never resolves has neither.
fn scheduled(task : GanttTask) -> Bool {
  let finite = (date : @date.JsDate?) => {
    match date {
      Some(d) => !d.time.is_nan()
      None => false
    }
  }
  finite(task.start_time) && finite(task.end_time)
}

///|
fn start_of(task : GanttTask) -> Double {
  time_or_nan(task.start_time)
}

///|
fn end_of(task : GanttTask) -> Double {
  time_or_nan(task.end_time)
}

///|
/// Mermaid's compact mode: within a section, a task goes on the first row that is free when it starts.
fn pack_rows(
  tasks : Array[GanttTask],
  offset : Int32,
  row_of : Array[Int32],
) -> Int32 {
  let sorted = tasks.filter(scheduled)
  sorted.sort_by((a, b) => {
    let by_start = start_of(a) - start_of(b)
    if by_start != 0 && !by_start.is_nan() {
      by_start.compare(0)
    } else {
      a.order.compare(b.order)
    }
  })
  let free : Array[Double] = []
  for task in sorted {
    let start = start_of(task)
    let mut row = 0
    while row < free.length() && start < free[row] {
      row += 1
    }
    if row == free.length() {
      free.push(end_of(task))
    } else {
      free[row] = end_of(task)
    }
    row_of[task.order] = offset + row
  }
  let mut rows = free.length()
  for task in tasks {
    if row_of[task.order] < 0 {
      row_of[task.order] = offset + rows
      rows += 1
    }
  }
  if rows < 1 {
    1
  } else {
    rows
  }
}

///|
priv struct Bar {
  task : GanttTask
  label : @text.Label
  row : Int32
  x0 : Double
  x1 : Double
  label_x : Double
  inside : Bool
}

///|
/// Draws a gantt chart, scheduled against the time the options give.
pub fn render_gantt(
  model : GanttDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  let size = options.font_size.unwrap_or(16)
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let now = clock(options.now)
  let label_size = setting(config, "fontSize", 4, 72).unwrap_or(
    (size * 0.8125).round(),
  )
  let section_size = setting(config, "sectionFontSize", 4, 72).unwrap_or(
    label_size,
  )
  let tick_size = (size * 0.75).round()
  let bar_height = setting(config, "barHeight", 4, 400).unwrap_or(
    (label_size * 1.85).round(),
  )
  let bar_gap = setting(config, "barGap", 0, 400).unwrap_or(
    (bar_height / 4).round(),
  )
  let row_height = bar_height + bar_gap
  let section_styles = setting(config, "numberSectionStyles", 1, 1000)
    .unwrap_or(4)
    .round()
  let compact = model.display_mode == "compact"
  let top_axis = model.top_axis || flag(config, "topAxis")
  let tasks = model.get_tasks(now)
  let row_tasks = tasks.filter(task => !task.vert)
  let verts = tasks.filter(task => task.vert && scheduled(task))
  let categories : Map[String, Int32] = Map([])
  for task in row_tasks {
    if !categories.contains(task.section) {
      categories[task.section] = categories.length()
    }
  }
  // Row tasks are numbered from zero in source order, so their order indexes their row.
  let row_of = Array::make(row_tasks.length(), -1)
  let row_section : Array[String] = []
  if compact {
    let groups : Map[String, Array[GanttTask]] = Map([])
    for task in row_tasks {
      match groups.get(task.section) {
        Some(group) => group.push(task)
        None => groups[task.section] = [task]
      }
    }
    for section, group in groups {
      let rows = pack_rows(group, row_section.length(), row_of)
      for _ in 0..<rows {
        row_section.push(section)
      }
    }
  } else {
    for task in row_tasks {
      row_of[task.order] = row_section.length()
      row_section.push(task.section)
    }
  }
  let row_count = row_section.length()
  let mut start = @double.infinity
  let mut stop = -@double.infinity
  for task in tasks {
    if !scheduled(task) {
      continue
    }
    start = @util.js_min(start, start_of(task))
    stop = @util.js_max(stop, end_of(task))
  }
  let has_plot = start <= stop
  let title = @text.layout_label(
    model.title,
    false,
    measurer,
    size,
    4000,
    base=@text.STYLE_BOLD,
  )
  let title_height = if title.height > 0 { title.height + 16 } else { 0 }
  let title_attrs = " class=\"pele-title\" font-weight=\"var(--_tw)\""
  if !has_plot {
    let width = (@util.js_max(title.width, 1) + 2 * pad).ceil()
    let height = (@util.js_max(title.height, 1) + 2 * pad).ceil()
    let content = @svg.Markup::new()
    @svg.write_label(
      content,
      title,
      width / 2,
      pad + title.height / 2,
      title_attrs,
    )
    return {
      svg: @svg.markup_document(
        "gantt",
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
  let section_labels : Map[String, @text.Label] = Map([])
  let mut section_width = 0.0
  for section, _ in categories {
    let label = @text.layout_label(
      Some(section),
      false,
      measurer,
      section_size,
      180,
    )
    section_labels[section] = label
    section_width = @util.js_max(section_width, label.width)
  }
  let axis_format = if model.axis_format != "" {
    model.axis_format
  } else if model.date_format == "D" {
    "%d"
  } else {
    text_setting(config, "axisFormat").unwrap_or("%Y-%m-%d")
  }
  let tick_label = (t : Double) => {
    time_format(axis_format, @date.JsDate::from_time(t))
  }
  let sample_width = @util.js_max(
    measurer.width(tick_label(start), tick_size, 0),
    measurer.width(tick_label(stop), tick_size, 0),
  )
  let left = pad +
    setting(config, "leftPadding", 0, 2000).unwrap_or(
      @util.js_max(
        if section_width > 0 {
          section_width + 24
        } else {
          0
        },
        sample_width / 2,
      ),
    )
  let right_padding = setting(config, "rightPadding", 0, 2000).unwrap_or(
    @util.js_max(16, sample_width / 2),
  )
  let target = @common.cap_width(
    options,
    setting(config, "useWidth", 100, 20000).unwrap_or(WIDTH),
    280,
  )
  let plot_width = @util.js_max(MIN_PLOT, target - left - right_padding - pad)
  let right = left + plot_width
  let scale = if stop > start { plot_width / (stop - start) } else { 0 }
  let x = (t : Double) => {
    if scale == 0 {
      left + plot_width / 2
    } else {
      left + (t - start) * scale
    }
  }
  let tick_height = (tick_size * 1.75).round()
  let top_padding = setting(config, "topPadding", 0, 2000)
  let grid_start = setting(config, "gridLineStartPadding", 0, 2000)
  let head_height = pad +
    title_height +
    (if top_axis { tick_height } else { 0 })
  let plot_top = @util.js_max(head_height, top_padding.unwrap_or(0))
  // Mermaid starts its grid lines above the first row by the difference between these two settings.
  // Here that only uses room a larger `topPadding` leaves free.
  let grid_lead = match (top_padding, grid_start) {
    (Some(top), Some(grid)) =>
      @util.js_max(0, @util.js_min(top - grid, plot_top - head_height))
    _ => 0
  }
  let plot_height = @util.js_max(row_count.to_double(), 1) * row_height
  let plot_bottom = plot_top + plot_height

  // Bars and where their labels go: inside when they fit, otherwise beside the bar on the side with room.
  let bars : Array[Bar] = []
  let mut extent = right + right_padding
  for task in row_tasks {
    let label = one_line(task.task, measurer, label_size)
    let row = row_of[task.order]
    if !scheduled(task) {
      let label_x = left + LABEL_GAP + label.width / 2
      extent = @util.js_max(extent, label_x + label.width / 2)
      bars.push({
        task,
        label,
        row,
        x0: @double.not_a_number,
        x1: @double.not_a_number,
        label_x,
        inside: false,
      })
      continue
    }
    let mut x0 = x(start_of(task))
    let render_end = match task.render_end_time {
      Some(d) => d.time
      None => end_of(task)
    }
    let mut x1 = @util.js_max(
      x(render_end),
      x0 + (if task.milestone { 0 } else { 2 }),
    )
    if task.milestone {
      let mid = x0 + (x(end_of(task)) - x0) / 2
      x0 = mid - bar_height / 2
      x1 = mid + bar_height / 2
    }
    let inside = !task.milestone && label.width + 2 * LABEL_GAP <= x1 - x0
    let mut label_x = (x0 + x1) / 2
    if !inside {
      let fits_right = x1 + LABEL_GAP + label.width <= right + right_padding
      let fits_left = x0 - LABEL_GAP - label.width >= left
      label_x = if fits_right || !fits_left {
        x1 + LABEL_GAP + label.width / 2
      } else {
        x0 - LABEL_GAP - label.width / 2
      }
      extent = @util.js_max(extent, label_x + label.width / 2)
    }
    bars.push({ task, label, row, x0, x1, label_x, inside, })
  }
  let interval = match model.tick_interval {
    Some(value) if value != "" => value
    _ => text_setting(config, "tickInterval").unwrap_or("")
  }
  let weekday = match model.weekday {
    Some(day) => day
    None => text_setting(config, "weekday").unwrap_or("sunday")
  }
  let count = @util.js_max(
    2,
    @util.js_min(10, (plot_width / (sample_width + 24)).floor()),
  )
  let ticks = match
    interval_ticks(interval, weekday, start, stop, (plot_width / 3).ceil()) {
    Some(ticks) => ticks
    None => auto_ticks(start, stop, count)
  }
  let grid = StringBuilder()
  let axis_bottom = @svg.Markup::new()
  let axis_top = @svg.Markup::new()
  let mut last_right = -@double.infinity
  let mut last_label = ""
  let bottom_y = plot_bottom + tick_height / 2 + 2
  let top_y = plot_top - grid_lead - tick_height / 2 - 2
  for t in ticks {
    let tx = x(t)
    grid.write_string(
      "M\{@svg.num(tx)},\{@svg.num(plot_top - grid_lead)}V\{@svg.num(plot_bottom)}",
    )
    let label = tick_label(t)
    let width = measurer.width(label, tick_size, 0)
    // A label is skipped when it would run into the one before it or only repeat it; its grid line stays.
    if tx - width / 2 < last_right + 8 || label == last_label {
      continue
    }
    last_right = tx + width / 2
    last_label = label
    extent = @util.js_max(extent, last_right)
    let write_tick = (axis : @svg.Markup, y : Double) => {
      axis.write(
        "<text x=\"\{@svg.num(tx)}\" y=\"\{@svg.num(y + tick_size * 0.35)}\" text-anchor=\"middle\">",
      )
      @svg.write_esc(axis, label)
      axis.write("</text>")
    }
    write_tick(axis_bottom, bottom_y)
    if top_axis {
      write_tick(axis_top, top_y)
    }
  }

  // Vertical markers take no row. Their labels go under the axis, on as many lines as it takes to keep them apart.
  let vert_lines = @svg.Markup::new()
  let vert_labels = @svg.Markup::new()
  let vert_ends : Array[Double] = []
  let vert_top = plot_bottom + tick_height + 4
  let vert_line = (label_size * 1.5).round()
  let ordered = verts.mapi((i, task) => (i, task))
  ordered.sort_by((a, b) => {
    let by_start = start_of(a.1) - start_of(b.1)
    if by_start != 0 {
      by_start.compare(0)
    } else {
      a.0.compare(b.0)
    }
  })
  for entry in ordered {
    let task = entry.1
    let vx = x(start_of(task))
    let label = one_line(task.task, measurer, label_size)
    let cx = @util.js_max(pad + label.width / 2, vx)
    let mut line = 0
    while line < vert_ends.length() &&
          cx - label.width / 2 < vert_ends[line] + 8 {
      line += 1
    }
    if line == vert_ends.length() {
      vert_ends.push(cx + label.width / 2)
    } else {
      vert_ends[line] = cx + label.width / 2
    }
    extent = @util.js_max(extent, vert_ends[line])
    vert_lines.write("<path class=\"pele-vert\"")
    @svg.write_data_id(vert_lines, task.id)
    vert_lines.write(
      " d=\"M\{@svg.num(vx)},\{@svg.num(plot_top - grid_lead)}V\{@svg.num(plot_bottom)}\"/>",
    )
    @svg.write_label_with_id(
      vert_labels,
      label,
      cx,
      vert_top + line.to_double() * vert_line + vert_line / 2,
      " class=\"pele-vert-label\" data-id=\"",
      task.id,
      "\"",
      "",
    )
  }
  let width = (@util.js_max(extent, pad + title.width) + pad).ceil()
  let height = (plot_bottom +
  tick_height +
  (if vert_ends.length() > 0 {
    4 + vert_ends.length().to_double() * vert_line
  } else {
    0
  }) +
  pad).ceil()

  // Section bands, one per run of rows that share a section, shaded on alternate sections.
  let bands = @svg.Markup::new()
  let section_out = @svg.Markup::new()
  let mut row = 0
  while row < row_count {
    let section = row_section[row]
    let mut end = row + 1
    while end < row_count && row_section[end] == section {
      end += 1
    }
    let index = categories[section].to_double() % section_styles
    let y = plot_top + row.to_double() * row_height
    let h = (end - row).to_double() * row_height
    if categories.length() > 1 || section != "" {
      let fill = if index % 2 == 0 { "var(--_s)" } else { "none" }
      bands.write(
        "<rect class=\"pele-section pele-section-\{index}\" x=\"0\" y=\"\{@svg.num(y)}\" width=\"\{width}\" height=\"\{@svg.num(h)}\" fill=\"\{fill}\"/>",
      )
    }
    let label = section_labels[section]
    @svg.write_label_with_id(
      section_out,
      label,
      pad + 8 + label.width / 2,
      y + h / 2,
      " class=\"pele-section-label\" data-id=\"",
      section,
      "\"",
      "",
      icons?=options.icons,
    )
    row = end
  }

  // Excluded days, as Mermaid marks them: a day at a time from the first task's start, and not at all
  // when the chart spans more than five years.
  let excluded = StringBuilder()
  if (model.excludes.length() > 0 || model.includes.length() > 0) &&
    add_time(@date.JsDate::from_time(start), 6, "y").time > stop {
    let mut from : @date.JsDate? = None
    let mut to : @date.JsDate? = None
    let flush = () => {
      guard from is Some(first) && to is Some(last) else { return }
      let day_start = first.copy()
      day_start.set_hours(0, minutes=0, seconds=0, ms=0)
      let day_end = last.copy()
      day_end.set_hours(23, minutes=59, seconds=59, ms=999)
      let ex0 = @util.js_max(left, x(day_start.time))
      let ex1 = @util.js_min(right, x(day_end.time))
      if ex1 > ex0 {
        excluded.write_string(
          "<rect x=\"\{@svg.num(ex0)}\" y=\"\{@svg.num(plot_top)}\" width=\"\{@svg.num(ex1 - ex0)}\" height=\"\{@svg.num(plot_height)}\"/>",
        )
      }
      from = None
      to = None
    }
    let mut day = @date.JsDate::from_time(start)
    while day.time <= stop {
      if model.is_invalid_date(day) {
        if from is None {
          from = Some(day)
        }
        to = Some(day)
      } else {
        flush()
      }
      day = add_days(day, 1)
    }
    flush()
  }
  let links : Array[@types.LinkInfo] = []
  let tasks_out = @svg.Markup::new()
  for bar in bars {
    let task = bar.task
    let cy = plot_top + bar.row.to_double() * row_height + row_height / 2
    let state = if task.active {
      "active"
    } else if task.done {
      "done"
    } else {
      ""
    }
    let classes = StringBuilder()
    classes.write_string("pele-task")
    if state != "" {
      classes.write_string(" pele-" + state)
    }
    if task.crit {
      classes.write_string(" pele-crit")
    }
    if task.milestone {
      classes.write_string(" pele-milestone")
    }
    if task.classes.contains("clickable") {
      classes.write_string(" pele-clickable")
    }
    let mut shape = ""
    let mut text_fill = ""
    if bar.x0.is_nan() {
      classes.write_string(" pele-unscheduled")
      text_fill = " fill=\"var(--_m)\""
    } else {
      // A critical task takes the critical color in place of the accent.
      // Done, it keeps the fill of finished work and only its border is in that color.
      let color = if task.crit { @svg.CRITICAL } else { "var(--_c)" }
      let paint = match state {
        "done" => "fill=\"var(--_a)\""
        "active" => "fill=\"\{color}\" fill-opacity=\"0.25\""
        _ => "fill=\"\{color}\""
      }
      let stroke_color = if state == "done" && !task.crit {
        "var(--_b)"
      } else {
        color
      }
      let stroke = "stroke=\"\{stroke_color}\""
      if task.milestone {
        let cx = (bar.x0 + bar.x1) / 2
        let r = bar_height / 2
        shape = "<path d=\"M\{@svg.num(cx)},\{@svg.num(cy - r)}L\{@svg.num(cx + r)},\{@svg.num(cy)}L\{@svg.num(cx)},\{@svg.num(cy + r)}L\{@svg.num(cx - r)},\{@svg.num(cy)}Z\" \{paint} \{stroke} stroke-linejoin=\"round\"/>"
      } else {
        shape = "<rect x=\"\{@svg.num(bar.x0)}\" y=\"\{@svg.num(cy - bar_height / 2)}\" width=\"\{@svg.num(bar.x1 - bar.x0)}\" height=\"\{@svg.num(bar_height)}\" \{paint} \{stroke}\{@svg.ROUNDED}/>"
      }
      if bar.inside {
        text_fill = if state == "" { " fill=\"var(--_bg)\"" } else { "" }
      } else if state == "done" {
        text_fill = " fill=\"var(--_m)\""
      }
    }
    let body = @svg.Markup::new()
    body.write(shape)
    @svg.write_label(
      body,
      bar.label,
      bar.label_x,
      cy,
      " class=\"pele-label\"\{text_fill}",
    )
    tasks_out.write("<g class=\"\{classes.to_string()}\"")
    @svg.write_data_id(tasks_out, task.id)
    tasks_out.write(">")
    let linked = match model.links.get(task.id) {
      Some(url) =>
        @url.write_link_start(tasks_out, url, task.id, links, options)
      None => false
    }
    tasks_out.write_markup(body)
    if linked {
      tasks_out.write("</a>")
    }
    tasks_out.write("</g>")
  }
  let today = @svg.Markup::new()
  if model.today_marker != "off" && now >= start && now <= stop && stop > start {
    let tx = x(now)
    let top = plot_top - grid_lead
    let style = if model.today_marker != "" {
      @svg.resolve_raw_style(
        model.today_marker.split(",").map(part => part.to_owned()).collect(),
      ).line
    } else {
      ""
    }
    today.write(
      "<g class=\"pele-today\"><path d=\"M\{@svg.num(tx)},\{@svg.num(top)}V\{@svg.num(plot_bottom)}\" fill=\"none\" stroke=\"var(--_c)\" stroke-width=\"2\"",
    )
    @svg.write_style(today, style)
    today.write("/>")
    if style == "" {
      today.write(
        "<path d=\"M\{@svg.num(tx - 4)},\{@svg.num(top - 5)}H\{@svg.num(tx + 4)}L\{@svg.num(tx)},\{@svg.num(top + 1)}Z\" fill=\"var(--_c)\"/>",
      )
    }
    today.write("</g>")
  }
  let axis_line = "M\{@svg.num(left)},\{@svg.num(plot_bottom)}H\{@svg.num(right)}" +
    (if top_axis {
      "M\{@svg.num(left)},\{@svg.num(plot_top - grid_lead)}H\{@svg.num(right)}"
    } else {
      ""
    })
  let content = @svg.Markup::new()
  @svg.write_label(
    content,
    title,
    width / 2,
    pad + title.height / 2,
    title_attrs,
  )
  if !bands.is_empty() {
    content.write_group("<g class=\"pele-sections\">", bands, "</g>")
  }
  if excluded.to_string() != "" {
    content.write(
      "<g class=\"pele-excluded\" fill=\"var(--_a)\">\{excluded.to_string()}</g>",
    )
  }
  content.write(
    "<g class=\"pele-grid\" fill=\"none\"><path d=\"\{grid.to_string()}\" stroke=\"var(--_b)\" stroke-dasharray=\"1 3\"/><path d=\"\{axis_line}\" stroke=\"var(--_b)\"/></g>",
  )
  if !vert_lines.is_empty() {
    content.write_group(
      "<g class=\"pele-verts\" fill=\"none\" stroke=\"var(--_l)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\">",
      vert_lines, "</g>",
    )
  }
  content.write_markup(today)
  content.write_group(
    "<g class=\"pele-tasks\" font-size=\"\{@svg.num(label_size)}\">",
    tasks_out,
    "</g>",
  )
  content.write_group(
    "<g class=\"pele-section-labels\" font-size=\"\{@svg.num(section_size)}\">",
    section_out,
    "</g>",
  )
  content.write(
    "<g class=\"pele-axis\" font-size=\"\{tick_size}\" fill=\"var(--_m)\">",
  )
  content.write_markup(axis_bottom)
  content.write_markup(axis_top)
  content.write("</g>")
  if !vert_labels.is_empty() {
    content.write_group(
      "<g class=\"pele-vert-labels\" font-size=\"\{@svg.num(label_size)}\">",
      vert_labels,
      "</g>",
    )
  }
  {
    svg: @svg.markup_document(
      "gantt",
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
    links,
  }
}
