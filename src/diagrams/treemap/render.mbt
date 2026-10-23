///|
const HEADER : Double = 28

///|
const SIDE : Double = 6

///|
const LINE : Double = 1.25

///|
fn config_value(config : @types.Config, key : String) -> Json? {
  guard config.get("treemap") is Some(Object(treemap)) else { return None }
  treemap.get(key)
}

///|
/// A number option no smaller than `min`, capped at `max`, or `fallback` when it is anything else.
fn number_option(
  config : @types.Config,
  key : String,
  fallback : Double,
  min : Double,
  max : Double,
) -> Double {
  match config_value(config, key) {
    Some(Number(value, ..)) if value >= min => @util.js_min(value, max)
    _ => fallback
  }
}

///|
/// A section is a tint of its color, unless a class gives it a fill of its own.
fn has_own_fill(shape : String) -> Bool {
  shape.contains("\"fill:") || shape.contains(";fill:")
}

///|
/// Draws one section: its box, and a header with its name and, when there is room, its value.
fn draw_section(
  b : Box,
  name : String,
  value : String,
  x : Double,
  y : Double,
  size : Double,
  measurer : @text.TextMeasurer,
) -> String {
  let node = b.node
  let style = @svg.resolve_style(node.css_compiled_styles.unwrap_or([]))
  let classes = @svg.class_names(node.class_selector.unwrap_or(""))
  let color = @svg.series_color(b.series)
  let small = (size * 0.875).round()
  let tiny = (size * 0.75).round()
  let text = StringBuilder()
  if b.h >= HEADER {
    let room = b.w - 2 * SIDE - 4
    let value_width = if value != "" {
      measurer.width(value, tiny, 0)
    } else {
      0
    }
    let with_value = value_width > 0 && room - value_width - 12 >= 3 * small
    let label = @common.fit_text(
      name,
      if with_value {
        room - value_width - 12
      } else {
        room
      },
      small,
      small,
      measurer,
      style=@text.STYLE_BOLD,
    )
    let baseline = y + HEADER / 2 + 1
    if label is Some(label) {
      text.write_string(
        "<text x=\"\{@svg.num(x + SIDE + 2)}\" y=\"\{@svg.num(baseline + small * 0.35)}\" font-weight=\"var(--_hw)\"\{style.text}>\{@svg.esc(label.text)}</text>",
      )
    }
    if with_value {
      text.write_string(
        "<text class=\"pele-value\" x=\"\{@svg.num(x + b.w - SIDE - 2)}\" y=\"\{@svg.num(baseline + tiny * 0.35)}\" font-size=\"\{tiny}\" text-anchor=\"end\" fill=\"var(--_m)\"\{style.text}>\{@svg.esc(value)}</text>",
      )
    }
  }
  let tint = if has_own_fill(style.shape) {
    ""
  } else {
    " fill-opacity=\"0.12\""
  }
  "<g class=\"pele-node pele-section\{classes}\" data-id=\"\{@svg.esc_text(node.name)}\">" +
  "<rect x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y)}\" width=\"\{@svg.num(b.w)}\" height=\"\{@svg.num(b.h)}\" fill=\"\{color}\"" +
  @svg.rounded("\{tint} stroke=\"\{color}\"\{style.shape}") +
  "/>\{text.to_string()}</g>"
}

///|
/// Draws one leaf: its box, and its name and value when they fit.
fn draw_leaf(
  b : Box,
  name : String,
  value : String,
  x : Double,
  y : Double,
  size : Double,
  measurer : @text.TextMeasurer,
) -> String {
  let node = b.node
  let style = @svg.resolve_style(node.css_compiled_styles.unwrap_or([]))
  let classes = @svg.class_names(node.class_selector.unwrap_or(""))
  let least = (size * 0.5625).round()
  let room = b.w - 8
  let tallest = @util.js_min(size, ((b.h - 4) / LINE).floor())
  let label = if tallest >= least {
    @common.fit_text(name, room, tallest, least, measurer)
  } else {
    None
  }
  let mut text = ""
  if label is Some(label) {
    let cx = @svg.num(x + b.w / 2)
    let cy = y + b.h / 2
    let value_size = @util.js_max(least, (label.size * 0.8).round())
    let lines = (label.size + value_size) * LINE
    if value != "" &&
      lines <= b.h - 4 &&
      measurer.width(value, value_size, 0) <= room {
      let first = cy - lines / 2 + label.size * LINE / 2
      let second = cy + lines / 2 - value_size * LINE / 2
      text = "<text x=\"\{cx}\" y=\"\{@svg.num(first + label.size * 0.35)}\" font-size=\"\{@svg.num(label.size)}\"\{style.text}>\{@svg.esc(label.text)}</text>" +
        "<text class=\"pele-value\" x=\"\{cx}\" y=\"\{@svg.num(second + value_size * 0.35)}\" font-size=\"\{@svg.num(value_size)}\"\{style.text}>\{@svg.esc(value)}</text>"
    } else {
      text = "<text x=\"\{cx}\" y=\"\{@svg.num(cy + label.size * 0.35)}\" font-size=\"\{@svg.num(label.size)}\"\{style.text}>\{@svg.esc(label.text)}</text>"
    }
  }
  "<g class=\"pele-node pele-leaf\{classes}\" data-id=\"\{@svg.esc_text(node.name)}\">" +
  "<rect x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y)}\" width=\"\{@svg.num(b.w)}\" height=\"\{@svg.num(b.h)}\" fill=\"\{@svg.series_color(b.series)}\"" +
  @svg.rounded(style.shape) +
  "/>\{text}</g>"
}

///|
fn render_treemap(
  model : TreemapModel,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered {
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.875).round()
  let measurer = options.text_measurer()
  let pad = match options.padding {
    Some(padding) => padding
    None => number_option(config, "diagramPadding", 8, 0, 2000)
  }
  // Mermaid sizes the diagram as ten times `nodeWidth` by ten times `nodeHeight`.
  let width = @common.cap_width(
    options,
    number_option(config, "nodeWidth", 64, 1, 400) * 10,
    200,
    around=2 * pad,
  ).round()
  let height = (number_option(config, "nodeHeight", 40, 1, 400) * 10).round()
  let show_values = !(config_value(config, "showValues") is Some(False))
  let format = formatter(
    match config_value(config, "valueFormat") {
      Some(String(spec)) => spec
      _ => ","
    },
  )
  let boxes = layout_treemap(model.roots, width, height, {
    gap: number_option(config, "padding", 4, 0, 200),
    header: HEADER,
    side: SIDE,
  })
  let title = @text.layout_label(
    model.title,
    false,
    measurer,
    size,
    @common.title_room(options),
    base=@text.STYLE_BOLD,
  )
  let title_height = if title.height > 0 { title.height + 8 } else { 0 }
  let left = pad + @util.js_max(0, (title.width - width) / 2)
  let top = pad + title_height
  let sections = StringBuilder()
  let leaves = StringBuilder()
  for b in boxes {
    let name = @util.trim(@text.decode_entities(b.node.name))
    let value = if show_values { format(b.value) } else { "" }
    let x = left + b.x
    let y = top + b.y
    if b.node.children is Some(_) {
      sections.write_string(draw_section(b, name, value, x, y, size, measurer))
    } else {
      leaves.write_string(draw_leaf(b, name, value, x, y, size, measurer))
    }
  }
  let total_width = (@util.js_max(width, title.width) + 2 * pad).ceil()
  let total_height = (height + title_height + 2 * pad).ceil()
  let content = StringBuilder()
  content.write_string(
    @svg.label_svg(
      title,
      total_width / 2,
      pad + title.height / 2,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
    ),
  )
  if !sections.is_empty() {
    content.write_string(
      "<g class=\"pele-sections\" font-size=\"\{small}\">\{sections.to_string()}</g>",
    )
  }
  if !leaves.is_empty() {
    content.write_string(
      "<g class=\"pele-leaves\" text-anchor=\"middle\" fill=\"var(--_bg)\">\{leaves.to_string()}</g>",
    )
  }
  {
    svg: @svg.svg_document(
      "treemap",
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
