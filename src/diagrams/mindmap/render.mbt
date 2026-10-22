///|
/// How much of a branch's color tints the nodes drawn in it.
const TINT : Double = 0.22

///|
fn render_mindmap(
  model : MindmapModel,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered {
  @common.turn_to_fit(options, down => draw(model, config, options, down))
}

///|
fn draw(
  model : MindmapModel,
  config : @types.Config,
  options : @types.RenderOptions,
  down : Bool,
) -> @types.Rendered {
  let size = options.font_size.unwrap_or(16)
  let measurer = @text.metrics_measurer
  let pad = options.padding.unwrap_or(8)
  let nodes = model.nodes
  let n = nodes.length()
  let { parent, shapes, labels, w, h, dy, anchor, x, y, side, } = layout(
    model, config, options, down,
  )
  let mut min_x = 0.0
  let mut max_x = 0.0
  let mut min_y = 0.0
  let mut max_y = 0.0
  let out = StringBuilder()
  let edges = StringBuilder()
  let body = StringBuilder()
  let mut color = ""
  let flush = (section : Int32?) => {
    if body.is_empty() {
      return
    }
    out.write_string(
      "<g class=\"pele-branch pele-section-\{section.unwrap_or(0)}\">" +
      "<g class=\"pele-edges\" fill=\"none\" stroke=\"\{color}\" stroke-width=\"1.5\">\{edges.to_string()}</g>\{body.to_string()}</g>",
    )
    edges.reset()
    body.reset()
  }

  // The root is drawn last, on top of the links that leave it.
  for k = 1; k <= n; k = k + 1 {
    let i = k % n
    let node = nodes[i]
    let shape = shapes[i]
    let label = labels[i]
    let cx = x[i]
    let top = y[i]
    min_x = @util.js_min(min_x, cx - w[i] / 2)
    max_x = @util.js_max(max_x, cx + w[i] / 2)
    min_y = @util.js_min(min_y, top)
    max_y = @util.js_max(max_y, top + h[i])
    if i == 0 || parent[i] == 0 {
      flush(nodes[k - 1].section)
    }
    if i > 0 {
      if parent[i] == 0 {
        color = @svg.series_color(node.section.unwrap_or(0))
      }
      let p = parent[i]
      let dir = side[i]
      let from = if dir > 0 { 1 } else { 3 }
      let x1 = x[p] +
        dir.to_double() *
        (
          w[p] / 2 -
          (if shapes[p] != "" {
            @svg.shape_inset(shapes[p], w[p], h[p], from)
          } else {
            0
          })
        )
      let y1 = y[p] + anchor[p]
      let near = cx - dir.to_double() * w[i] / 2
      let x2 = near +
        (if shape != "" {
          dir.to_double() * @svg.shape_inset(shape, w[i], h[i], 4 - from)
        } else {
          0
        })
      let y2 = top + anchor[i]
      let mid = @svg.num((x1 + x2) / 2)
      edges.write_string(
        "<path class=\"pele-edge\" d=\"M\{@svg.num(x1)},\{@svg.num(y1)}C\{mid},\{@svg.num(y1)} \{mid},\{@svg.num(y2)} \{@svg.num(x2)},\{@svg.num(y2)}\"/>",
      )
    }
    let pill = shape == "" && !node.children.is_empty()
    // Every node off the root is filled with a tint of its branch's color and outlined in it,
    // whether its shape was given in the source or is the pill of a node that branches.
    // The root is neutral.
    let tint = " fill=\"\{color}\" fill-opacity=\"\{TINT}\" stroke=\"\{color}\""
    let inner = if shape != "" {
      if i > 0 {
        @svg.draw_shape(shape, w[i], h[i], tint, " stroke=\"\{color}\"")
      } else {
        @svg.draw_shape(
          shape,
          w[i],
          h[i],
          " fill=\"var(--_s)\" stroke=\"var(--_b)\"",
          " stroke=\"var(--_b)\"",
        )
      }
    } else if pill {
      "<rect x=\"\{@svg.num(-w[i] / 2)}\" y=\"\{@svg.num(-h[i] / 2)}\" width=\"\{@svg.num(w[i])}\" height=\"\{@svg.num(h[i])}\" rx=\"\{@svg.num(h[i] / 2)}\"\{tint}/>"
    } else {
      ""
    }
    let kind = if shape != "" {
      shape
    } else if pill {
      "branch"
    } else {
      "text"
    }
    let group = "<g class=\"pele-node pele-shape-\{kind}\{if i > 0 { "" } else { " pele-root" }}\{@svg.class_names(node.class_.unwrap_or(""))}\" data-id=\"\{@svg.esc_text(node.node_id)}\" transform=\"translate(\{@svg.num(cx)},\{@svg.num(top + h[i] / 2)})\">" +
      inner +
      @svg.label_svg(label, 0, dy[i], " class=\"pele-label\"") +
      "</g>"
    if i > 0 {
      body.write_string(group)
    } else {
      out.write_string(group)
    }
  }
  let title = @svg.title_label(
    model.title,
    measurer,
    size,
    @common.title_room(options),
  )
  let title_height = if title.height > 0 { title.height + 16 } else { 0 }
  let width = @util.js_max(max_x - min_x, title.width)
  let total_width = (width + 2 * pad).ceil()
  let total_height = (max_y - min_y + title_height + 2 * pad).ceil()
  let content = @svg.label_svg(
      title,
      total_width / 2,
      pad + title.height / 2,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
    ) +
    "<g transform=\"translate(\{@svg.num(pad - min_x + (width - max_x + min_x) / 2)},\{@svg.num(pad + title_height - min_y)})\">\{out.to_string()}</g>"
  {
    svg: @svg.svg_document(
      "mindmap",
      total_width,
      total_height,
      size,
      options,
      None,
      None,
      content,
    ),
    width: total_width,
    height: total_height,
    links: [],
  }
}
