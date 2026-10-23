///|
/// How much of a branch's color tints the nodes drawn in it.
const TINT : Double = 0.22

///|
/// Running down, links leave a node this far from its left edge, and turn in with a bend of this size.
const STEM : Double = 12

///|
const BEND : Double = 8

///|
/// A label with each line starting at `left`, for an outline, where centered lines would look ragged.
fn left_label(
  label : @text.Label,
  left : Double,
  cy : Double,
  icons : @types.IconResolver?,
) -> @svg.Markup raise @errors.PeleError {
  let attrs = " class=\"pele-label\""
  let out = @svg.Markup::new()
  if label.lines.length() < 2 {
    @svg.write_label(out, label, left + label.width / 2, cy, attrs, icons?)
    return out
  }
  let top = cy - label.height / 2
  for k in 0..<label.lines.length() {
    @svg.write_label(
      out,
      @text.label_line(label, k),
      left + label.widths[k] / 2,
      top + @text.line_middle(label, k),
      attrs,
      icons?,
    )
  }
  out
}

///|
fn render_mindmap(
  model : MindmapModel,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  @common.turn_to_fit(options, down => draw(model, config, options, down))
}

///|
fn draw(
  model : MindmapModel,
  config : @types.Config,
  options : @types.RenderOptions,
  down : Bool,
) -> @types.Rendered raise @errors.PeleError {
  let size = options.font_size.unwrap_or(16)
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let nodes = model.nodes
  let n = nodes.length()
  let { parent, shapes, labels, drawn, glyph, w, h, dy, anchor, x, y, side, } = layout(
    model, config, options, down,
  )
  let mut min_x = 0.0
  let mut max_x = 0.0
  let mut min_y = 0.0
  let mut max_y = 0.0
  let out = @svg.Markup::new()
  let mut edges = @svg.Markup::new()
  let mut body = @svg.Markup::new()
  let mut color = ""
  // Running down: how far the trunk under each node has been drawn.
  let trunk = Array::make(n, 0.0)
  fn flush(section : Int32?) raise @errors.PeleError {
    if body.is_empty() {
      return
    }
    out.write("<g class=\"pele-branch pele-section-\{section.unwrap_or(0)}\">")
    out.write_group(
      "<g class=\"pele-edges\" fill=\"none\" stroke=\"\{color}\" stroke-width=\"1.5\">",
      edges,
      "</g>",
    )
    out.write_markup(body)
    out.write("</g>")
    edges = @svg.Markup::new()
    body = @svg.Markup::new()
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
    if i > 0 && down {
      if parent[i] == 0 {
        color = @svg.series_color(node.section.unwrap_or(0))
      }
      let p = parent[i]
      // The link drops from under its parent and turns in to the node's left.
      // It starts where the link to the sibling above turned in, so each stretch of a shared trunk has one color.
      // Under the root's rounded end, the trunk starts where that end has come down to the bottom.
      let stem = if p == 0 {
        @util.js_min(@util.js_max(STEM, h[0] / 2), INDENT - BEND)
      } else {
        STEM
      }
      let x1 = x[p] - w[p] / 2 + @util.js_min(stem, w[p] / 2)
      let y1 = if trunk[p] != 0 { trunk[p] } else { y[p] + h[p] }
      let left = cx - w[i] / 2
      let x2 = left +
        (if shape != "" { @svg.shape_inset(shape, w[i], h[i], 3) } else { 0 })
      let y2 = top + anchor[i]
      let bend = @util.js_max(
        0,
        @util.js_min(@util.js_min(BEND, x2 - x1), y2 - y1),
      )
      // The next link carries on from where this one leaves the trunk, so the trunk has no gap.
      trunk[p] = y2 - bend
      edges.write(
        "<path class=\"pele-edge\" d=\"M\{@svg.num(x1)},\{@svg.num(y1)}V\{@svg.num(y2 - bend)}Q\{@svg.num(x1)},\{@svg.num(y2)} \{@svg.num(x1 + bend)},\{@svg.num(y2)}H\{@svg.num(x2)}\"/>",
      )
    } else if i > 0 {
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
      edges.write(
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
    let shift = if drawn[i] {
      (glyph + (if label.width > 0 { ICON_GAP } else { 0 })) / 2
    } else {
      0
    }
    let inner = match node.icon {
      Some(icon) if drawn[i] =>
        inner +
        @common.icon_svg(
          icon,
          -shift - label.width / 2,
          dy[i] - glyph / 2,
          glyph,
          icons?=options.icons,
        )
      _ => inner
    }
    let kind = if shape != "" {
      shape
    } else if pill {
      "branch"
    } else {
      "text"
    }
    let text = if down && shape == "" {
      left_label(label, shift - label.width / 2, dy[i], options.icons)
    } else {
      let text = @svg.Markup::new()
      @svg.write_label(
        text,
        label,
        shift,
        dy[i],
        " class=\"pele-label\"",
        icons?=options.icons,
      )
      text
    }
    let into = if i > 0 { body } else { out }
    into.write(
      "<g class=\"pele-node pele-shape-\{kind}\{if i > 0 { "" } else { " pele-root" }}\{@svg.class_names(node.class_.unwrap_or(""))}\" data-id=\"",
    )
    @svg.write_esc_text(into, node.node_id)
    into.write_group(
      "\" transform=\"translate(\{@svg.num(cx)},\{@svg.num(top + h[i] / 2)})\">" +
      inner,
      text,
      "</g>",
    )
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
  let content = @svg.Markup::new()
  content.write(
    @svg.label_svg(
      title,
      total_width / 2,
      pad + title.height / 2,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
    ),
  )
  content.write_group(
    "<g transform=\"translate(\{@svg.num(pad - min_x + (width - max_x + min_x) / 2)},\{@svg.num(pad + title_height - min_y)})\">",
    out,
    "</g>",
  )
  {
    svg: @svg.markup_document(
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
