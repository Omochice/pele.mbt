///|
const LABEL_GAP : Double = 6

///|
const VALUE_GAP : Double = 15

///|
fn section(config : @types.Config) -> Map[String, Json] {
  match config.get("sankey") {
    Some(Object(conf)) => conf
    _ => Map([])
  }
}

///|
fn number_option(
  conf : Map[String, Json],
  key : String,
  fallback : Double,
  min : Double,
  max : Double,
) -> Double {
  match conf.get(key) {
    Some(Number(value, ..)) if value >= min => @cmp.minimum(value, max)
    _ => fallback
  }
}

///|
fn text_option(conf : Map[String, Json], key : String) -> String {
  match conf.get(key) {
    Some(String(text)) => text
    Some(Number(value, ..) as number) if !value.is_inf() && !value.is_nan() =>
      @util.js_string(number)
    _ => ""
  }
}

///|
/// Two decimals, as Mermaid shows values; numbers too large for that are left as they are.
fn rounded(value : Double) -> String {
  if value.abs() < 1.0e15 {
    ((value * 100).round() / 100).to_string()
  } else {
    value.to_string()
  }
}

///|
/// A colour from the configuration, as the CSS of an inline style that overrides the series colour.
fn fill_css(color : String) -> String {
  @svg.resolve_raw_style(["fill:" + color]).shape
}

///|
/// Draws a sankey diagram.
/// Raises a semantic `PeleError` when the links form a cycle.
pub fn render_sankey(
  db : SankeyDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  let conf = section(config)
  @common.fit_width(options, number_option(conf, "width", 600, 1, 10000), 160, (
    chart_width,
    _,
  ) => draw(db, conf, options, chart_width))
}

///|
fn draw(
  db : SankeyDb,
  conf : Map[String, Json],
  options : @types.RenderOptions,
  chart_width : Double,
) -> @types.Rendered raise @errors.PeleError {
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.875).round()
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let chart_height = number_option(conf, "height", 400, 1, 10000)
  let node_width = @cmp.minimum(
    number_option(conf, "nodeWidth", 10, 1, 200),
    chart_width,
  )
  let show_values = !(conf.get("showValues") is Some(False))
  let prefix = text_option(conf, "prefix")
  let suffix = text_option(conf, "suffix")
  let outlined = conf.get("labelStyle") is Some(String("outlined"))
  let alignment = match conf.get("nodeAlignment") {
    Some(String("left")) => Left
    Some(String("right")) => Right
    Some(String("center")) => Center
    _ => Justify
  }
  let link_color = match conf.get("linkColor") {
    Some(String(text)) => text
    _ => "gradient"
  }
  let layout = layout_sankey(db, {
    width: chart_width,
    height: chart_height,
    node_width,
    node_padding: number_option(conf, "nodePadding", 12, 0, 200) +
    (if show_values { VALUE_GAP } else { 0 }),
    label_height: small * 1.15,
    alignment,
  })
  let nodes = layout.nodes

  let custom : Map[String, String] = Map([])
  if conf.get("nodeColors") is Some(Object(colors)) {
    for id, color in colors {
      if color is String(text) {
        let style = fill_css(text)
        if style != "" {
          custom[id] = style
        }
      }
    }
  }
  let node_style = (i : Int32) => custom.get(db.nodes[i].id).unwrap_or("")

  // Labels sit beside the bars, on the side that faces the middle of the chart.
  let mut central = 0
  let mut most = 0.0
  for node in nodes {
    if node.value > most {
      most = node.value
      central = node.layer
    }
  }
  let mut min_x = 0.0
  let mut max_x = chart_width
  let mut min_y = 0.0
  let mut max_y = chart_height
  let labels_out = @svg.Markup::new()
  let nodes_out = @svg.Markup::new()
  for i, node in nodes {
    let id = db.nodes[i].id
    let height = @cmp.maximum(node.height, 1.0)
    nodes_out.write("<rect class=\"pele-sankey-node\" data-id=\"")
    @svg.write_esc_text(nodes_out, id)
    nodes_out.write(
      "\" x=\"\{@svg.num(node.x)}\" y=\"\{@svg.num(node.y)}\" width=\"\{@svg.num(node_width)}\" height=\"\{@svg.num(height)}\" rx=\"\{@svg.num(@cmp.minimum(2.0, height / 2))}\" fill=\"\{@svg.series_color(i)}\"",
    )
    @svg.write_style(nodes_out, node_style(i))
    nodes_out.write("/>")
    let value = if show_values {
      "\{prefix}\{rounded(node.value)}\{suffix}"
    } else {
      ""
    }
    let after = if outlined {
      node.layer >= central
    } else {
      node.x < chart_width / 2
    }
    let text_width = measurer.width(
      if value != "" {
        "\{id} \{value}"
      } else {
        id
      },
      small,
      0,
    )
    let x = if after {
      node.x + node_width + LABEL_GAP
    } else {
      node.x - LABEL_GAP
    }
    let y = node.y + node.height / 2
    min_x = @cmp.minimum(min_x, if after { x } else { x - text_width })
    max_x = @cmp.maximum(max_x, if after { x + text_width } else { x })
    min_y = @cmp.minimum(min_y, y - small * 0.75)
    max_y = @cmp.maximum(max_y, y + small * 0.75)
    let position = " x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y + small * 0.35)}\" text-anchor=\"\{if after { "start" } else { "end" }}\""
    labels_out.write("<g class=\"pele-label\" data-id=\"")
    @svg.write_esc_text(labels_out, id)
    labels_out.write("\">")
    if outlined {
      labels_out.write(
        "<text\{position} fill=\"none\" stroke=\"var(--_bg)\" stroke-width=\"3\" stroke-linejoin=\"round\">",
      )
      @svg.write_esc(labels_out, id)
      if value != "" {
        labels_out.write(" ")
        @svg.write_esc(labels_out, value)
      }
      labels_out.write("</text>")
    }
    labels_out.write("<text\{position}>")
    @svg.write_esc(labels_out, id)
    if value != "" {
      labels_out.write(
        " <tspan class=\"pele-sankey-value\" fill=\"var(--_m)\">",
      )
      @svg.write_esc(labels_out, value)
      labels_out.write("</tspan>")
    }
    labels_out.write("</text></g>")
  }

  let fixed = if link_color == "gradient" ||
    link_color == "source" ||
    link_color == "target" {
    ""
  } else {
    fill_css(link_color)
  }
  let links_out = @svg.Markup::new()
  for link in layout.links {
    // Without definitions there are no gradients, so a gradient link takes its source's colour.
    let end = if link_color == "target" { link.target } else { link.source }
    let half = @cmp.maximum(link.thickness, 1.0) / 2
    let x0 = nodes[link.source].x + node_width
    let x1 = nodes[link.target].x
    let mid = @svg.num((x0 + x1) / 2)
    let from = db.nodes[link.source].id
    let to = db.nodes[link.target].id
    let top_source = @svg.num(link.source_y - half)
    let top_target = @svg.num(link.target_y - half)
    let bottom_target = @svg.num(link.target_y + half)
    let bottom_source = @svg.num(link.source_y + half)
    let style = if fixed != "" { fixed } else { node_style(end) }
    links_out.write("<path class=\"pele-sankey-link\" data-id=\"")
    @svg.write_esc_text(links_out, from)
    links_out.write("-&gt;")
    @svg.write_esc_text(links_out, to)
    links_out.write(
      "\" d=\"M\{@svg.num(x0)},\{top_source}C\{mid},\{top_source} \{mid},\{top_target} \{@svg.num(x1)},\{top_target}L\{@svg.num(x1)},\{bottom_target}C\{mid},\{bottom_target} \{mid},\{bottom_source} \{@svg.num(x0)},\{bottom_source}Z\" fill=\"\{@svg.series_color(end)}\"",
    )
    @svg.write_style(links_out, style)
    links_out.write("><title>")
    @svg.write_esc_text(links_out, from)
    links_out.write(" → ")
    @svg.write_esc_text(links_out, to)
    links_out.write(": ")
    @svg.write_esc_text(links_out, prefix)
    links_out.write(rounded(link.value))
    @svg.write_esc_text(links_out, suffix)
    links_out.write("</title></path>")
  }

  let title = @text.layout_label(
    db.title,
    false,
    measurer,
    size,
    @common.title_room(options),
    base=@text.STYLE_BOLD,
  )
  let title_height = if title.height > 0 { title.height + 12 } else { 0 }
  let inner = @cmp.maximum(max_x - min_x, title.width)
  let ox = pad - min_x + (inner - (max_x - min_x)) / 2
  let oy = pad + title_height - min_y
  let width = (inner + 2 * pad).ceil()
  let height = (max_y - min_y + title_height + 2 * pad).ceil()
  let content = @svg.Markup::new()
  @svg.write_label(
    content,
    title,
    width / 2,
    pad + title.height / 2,
    " class=\"pele-title\" font-weight=\"var(--_tw)\"",
  )
  content.write("<g transform=\"translate(\{@svg.num(ox)},\{@svg.num(oy)})\">")
  content.write_group(
    "<g class=\"pele-sankey-links\" fill-opacity=\"0.4\">", links_out, "</g>",
  )
  content.write_group("<g class=\"pele-sankey-nodes\">", nodes_out, "</g>")
  content.write_group(
    "<g class=\"pele-labels\" font-size=\"\{small}\">",
    labels_out,
    "</g>",
  )
  content.write("</g>")
  {
    svg: @svg.markup_document(
      "sankey",
      width,
      height,
      size,
      options,
      None,
      None,
      content,
    ),
    width,
    height,
    links: [],
  }
}
