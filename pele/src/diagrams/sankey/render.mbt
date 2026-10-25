///|
const LABEL_GAP : Double = 6

///|
const VALUE_GAP : Double = 15

///|
/// The most nodes whose labels are moved apart, as each move compares a label with every bar.
const CAREFUL : Int32 = 300

///|
/// A node's label: where it sits, which side of its bar it is on, and the extent of its text.
priv struct NodeLabel {
  value : String
  width : Double
  mut after : Bool
  mut left : Double
  mut y : Double
}

///|
/// The band of lines that `y` falls in.
/// Zero is added because the floor of a small negative quotient is negative zero, which hashes
/// apart from zero.
fn band(y : Double, line_height : Double) -> Double {
  (y / line_height).floor() + 0.0
}

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
  let line_height = small * 1.5
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

  // Labels sit beside the bars, on the side that faces the middle of the chart unless that
  // side is crowded.
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
  let labels = nodes.mapi((i, node) => {
    let id = db.nodes[i].id
    let value = if show_values {
      "\{prefix}\{rounded(node.value)}\{suffix}"
    } else {
      ""
    }
    let width = measurer.width(
      if value != "" {
        // Joined at its final size, because interpolating a name of hundreds of millions of
        // characters would need a doubling builder's block past what wasm allocates.
        [id, " ", value].join("")
      } else {
        id
      },
      small,
      0,
    )
    let after = if outlined {
      node.layer >= central
    } else {
      node.x < chart_width / 2
    }
    let x = if after {
      node.x + node_width + LABEL_GAP
    } else {
      node.x - LABEL_GAP
    }
    let y = node.y + node.height / 2
    min_x = @cmp.minimum(min_x, if after { x } else { x - width })
    max_x = @cmp.maximum(max_x, if after { x + width } else { x })
    min_y = @cmp.minimum(min_y, y - small * 0.75)
    max_y = @cmp.maximum(max_y, y + small * 0.75)
    { value, width, after, left: if after { x } else { x - width }, y, }
  })
  // A label moves at most one line, so each band keeps the labels of the two bands on either side.
  let bands : Map[Double, Array[Int32]] = Map([])
  if nodes.length() <= CAREFUL {
    for i, label in labels {
      let at = band(label.y, line_height)
      for key in [at - 2, at - 1, at, at + 1, at + 2] {
        match bands.get(key) {
          Some(nearby) => nearby.push(i)
          None => bands[key] = [i]
        }
      }
    }
  }
  let labels_out = @svg.Markup::new()
  let nodes_out = @svg.Markup::new()
  for i, node in nodes {
    let id = db.nodes[i].id
    let height = @cmp.maximum(node.height, 1.0)
    nodes_out.write("<rect class=\"pele-sankey-node\" data-id=\"")
    nodes_out.write_esc_text(id)
    nodes_out.write(
      "\" x=\"\{@svg.num(node.x)}\" y=\"\{@svg.num(node.y)}\" width=\"\{@svg.num(node_width)}\" height=\"\{@svg.num(height)}\" rx=\"\{@svg.num(@cmp.minimum(2.0, height / 2))}\" fill=\"\{@svg.series_color(i)}\"",
    )
    @svg.write_style(nodes_out, node_style(i))
    nodes_out.write("/>")
    let label = labels[i]
    let overlaps_label = (left : Double, y : Double) => {
      let nearby = bands.get(band(y, line_height)).unwrap_or([])
      nearby
      .iter()
      .any(j => {
        let other = labels[j]
        j != i &&
        (other.y - y).abs() < line_height &&
        left < other.left + other.width + LABEL_GAP &&
        left + label.width > other.left - LABEL_GAP
      })
    }
    let any_other = (hit : (PlacedNode) -> Bool) => {
      for j, bar in nodes {
        if j != i && hit(bar) {
          return true
        }
      }
      false
    }
    // Try the other side, then an adjacent line when both sides are crowded.
    let place = () => {
      for dy in [0.0, -line_height, line_height] {
        for after in [label.after, !label.after] {
          let left = if after {
            node.x + node_width + LABEL_GAP
          } else {
            node.x - LABEL_GAP - label.width
          }
          let y = label.y + dy
          if overlaps_label(left, y) ||
            left < min_x ||
            left + label.width > max_x ||
            y - small * 0.75 < min_y ||
            y + small * 0.75 > max_y {
            continue
          }
          let blocked = any_other(bar => {
            left < bar.x + node_width + LABEL_GAP &&
            left + label.width > bar.x - LABEL_GAP &&
            y - small * 0.75 < bar.y + bar.height &&
            y + small * 0.75 > bar.y
          })
          if blocked {
            continue
          }
          // A label stays nearer its own bar than any other in the column, so it can't name that one.
          let own = @util.js_max(
            0,
            @util.js_max(node.y - y, y - node.y - node.height),
          )
          let nearer = any_other(bar => {
            bar.x == node.x &&
            @util.js_max(0, @util.js_max(bar.y - y, y - bar.y - bar.height)) <=
            own
          })
          if nearer {
            continue
          }
          label.left = left
          label.y = y
          label.after = after
          return
        }
      }
    }
    if nodes.length() <= CAREFUL && overlaps_label(label.left, label.y) {
      place()
    }
    let { value, after, y, .. } = label
    let x = if after {
      node.x + node_width + LABEL_GAP
    } else {
      node.x - LABEL_GAP
    }
    let position = " x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y + small * 0.35)}\" text-anchor=\"\{if after { "start" } else { "end" }}\""
    labels_out.write("<g class=\"pele-label\" data-id=\"")
    labels_out.write_esc_text(id)
    labels_out.write("\">")
    if outlined {
      labels_out.write(
        "<text\{position} fill=\"none\" stroke=\"var(--_bg)\" stroke-width=\"3\" stroke-linejoin=\"round\">",
      )
      labels_out.write_esc(id)
      if value != "" {
        labels_out.write(" ")
        labels_out.write_esc(value)
      }
      labels_out.write("</text>")
    }
    labels_out.write("<text\{position}>")
    labels_out.write_esc(id)
    if value != "" {
      labels_out.write(
        " <tspan class=\"pele-sankey-value\" fill=\"var(--_m)\">",
      )
      labels_out.write_esc(value)
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
    links_out.write_esc_text(from)
    links_out.write("-&gt;")
    links_out.write_esc_text(to)
    links_out.write(
      "\" d=\"M\{@svg.num(x0)},\{top_source}C\{mid},\{top_source} \{mid},\{top_target} \{@svg.num(x1)},\{top_target}L\{@svg.num(x1)},\{bottom_target}C\{mid},\{bottom_target} \{mid},\{bottom_source} \{@svg.num(x0)},\{bottom_source}Z\" fill=\"\{@svg.series_color(end)}\"",
    )
    @svg.write_style(links_out, style)
    links_out.write("><title>")
    links_out.write_esc_text(from)
    links_out.write(" → ")
    links_out.write_esc_text(to)
    links_out.write(": ")
    links_out.write_esc_text(prefix)
    links_out.write(rounded(link.value))
    links_out.write_esc_text(suffix)
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
