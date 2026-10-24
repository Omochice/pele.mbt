///|
const NODE_SEP : Double = 48

///|
const EDGE_SEP : Double = 20

///|
const RANK_SEP : Double = 64

///|
const GROUP_PAD : Double = 20

///|
const LOOP : Double = 28

///|
const LOOP_BAND : Double = 38

///|
const MIN_WIDTH : Double = 96

///|
const BOX_PAD_X : Double = 18

///|
const BOX_PAD_Y : Double = 12

///|
const HEAD_PAD_Y : Double = 9

///|
const CELL_PAD_X : Double = 12

///|
const CELL_GAP : Double = 16

///|
const ROW_PAD : Double = 9

///|
const COMMENT_WRAP : Double = 260

///|
const NO_WRAP : Double = 1000000

///|
const PORT_GAP : Double = 18

///|
const PORT_MARGIN : Double = 14

///|
const BOX_ATTRS : String = " fill=\"var(--_s)\" stroke=\"var(--_b)\""

///|
fn number_option(
  config : @types.Config,
  key : String,
  fallback : Double,
) -> Double {
  match config.get("er") {
    Some(Object(section)) =>
      match section.get(key) {
        Some(Number(value, ..)) if value > 0 => @util.js_min(value, 2000)
        _ => fallback
      }
    _ => fallback
  }
}

///|
/// One row of an attribute table: its type, name, keys and comment cells, and its height.
priv struct Row {
  cells : FixedArray[@text.Label]
  h : Double
}

///|
priv struct NodeView {
  node : ErGraphNode
  style : @svg.ResolvedStyle
  label : @text.Label
  mut w : Double
  mut h : Double
  mut head_h : Double
  rows : Array[Row]
  /// The left edge of each column, measured from the left edge of the box.
  cols : Array[Double]
  row_size : Double
  key_size : Double
  /// Whether self-relationships loop out of the bottom side rather than the right.
  below : Bool
}

///|
/// A relationship from an entity to itself, with the stretch of the side it loops out of.
priv struct Loop {
  label : @text.Label
  mut band : Double
  mut at : Double
}

///|
/// Writes a measured label to `out` starting at `x`, with the baseline of its first line at `y`.
/// Icon spans are drawn in place by `icons`, and the text after one is positioned anew.
fn write_text_left(
  out : @svg.Markup,
  label : @text.Label,
  x : Double,
  y : Double,
  attrs : String,
  icons : @types.IconResolver?,
) -> Unit raise @errors.PeleError {
  let lines = label.lines
  if lines.length() == 0 {
    return
  }
  if lines.length() == 1 &&
    lines[0].length() == 1 &&
    lines[0][0].icon is None &&
    lines[0][0].math is None &&
    lines[0][0].style == 0 {
    out.write("<text\{attrs} x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y)}\">")
    out.write_esc(lines[0][0].text)
    out.write("</text>")
    return
  }
  let shared = @svg.shared_style(label)
  let shift = label.size * 0.35
  let top = y - shift - label.line_height / 2
  let body = @svg.Markup::new()
  let extra = @svg.Markup::new()
  for i, line in lines {
    let middle = top + @text.line_middle(label, i)
    if @text.has_math(line) {
      @svg.write_label(
        extra,
        @text.label_line(label, i),
        x + label.widths[i] / 2,
        middle,
        attrs,
        icons?,
      )
      continue
    }
    let line_y = middle + shift
    let has_icon = line.iter().any(span => span.icon is Some(_))
    let mut sx = x
    let mut placed = false
    for span in line {
      if span.icon is Some(name) {
        let side = label.size * 1.1
        @common.write_icon(
          extra,
          name,
          sx,
          line_y - shift - side / 2,
          side,
          icons?,
        )
      } else if span.text != "" {
        let pos = if has_icon || !placed {
          " x=\"\{@svg.num(sx)}\" y=\"\{@svg.num(line_y)}\""
        } else {
          ""
        }
        body.write(
          "<tspan\{pos}\{@svg.span_style(span.style & shared.lnot())}>",
        )
        body.write_esc(span.text)
        body.write("</tspan>")
        placed = true
      }
      sx += span.width
    }
  }
  out.write_group(
    "<text\{@svg.text_style(attrs, shared)} xml:space=\"preserve\">",
    body,
    "</text>",
  )
  out.write_markup(extra)
}

///|
/// Mermaid reads `~` pairs as angle brackets.
/// They are written as entities so the label parser does not take `<int>` for a tag.
fn cell_text(raw : String) -> String {
  let converted = @common.parse_generic_types(raw)
  if converted == raw {
    raw
  } else {
    converted.replace_all(old="<", new="&lt;").replace_all(old=">", new="&gt;")
  }
}

///|
/// Draws an ER diagram, turned to run down when a narrow host needs it.
pub fn render_er(
  db : ErDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  if !@common.runs_across(Some(db.direction)) {
    return draw(db, config, options, false)
  }
  @common.turn_to_fit(options, down => draw(db, config, options, down))
}

///|
fn js_sign(value : Double) -> Double {
  if value > 0 {
    1
  } else if value < 0 {
    -1
  } else {
    value
  }
}

///|
/// Draws the diagram; `turned` draws one that runs across as one that runs down.
fn draw(
  db : ErDb,
  config : @types.Config,
  options : @types.RenderOptions,
  turned : Bool,
) -> @types.Rendered raise @errors.PeleError {
  let graph = build_er_graph(db)
  let size = options.font_size.unwrap_or(16)
  let small_size = (size * 0.875).round()
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let index : Map[String, Int32] = Map([])
  for i, node in graph.nodes {
    index.set(node.id, i)
  }
  let views : Array[NodeView] = []
  let cnodes : Array[@layout.CNode] = []
  let cedges : Array[@layout.CEdge] = []
  let edge_labels : Array[@text.Label] = []
  let drawn : Array[ErGraphEdge] = []
  let loops : Map[Int32, Array[Loop]] = Map([])
  let loop_of : Array[Loop?] = []
  for edge in graph.edges {
    guard index.get(edge.start) is Some(src) && index.get(edge.end) is Some(dst) else {
      continue
    }
    let label = @text.layout_label(
      Some(edge.label),
      true,
      measurer,
      small_size,
      200,
    )
    let mut loop_ = None
    if src == dst {
      let made = { label, band: 0, at: 0, }
      loop_ = Some(made)
      match loops.get(src) {
        Some(list) => list.push(made)
        None => loops.set(src, [made])
      }
    }
    loop_of.push(loop_)
    drawn.push(edge)
    edge_labels.push(label)
    cedges.push({
      src,
      dst,
      minlen: 1,
      label_w: if label.width > 0 {
        label.width + 12
      } else {
        0
      },
      label_h: if label.height > 0 {
        label.height + 4
      } else {
        0
      },
      route: [],
      label_x: 0,
      label_y: 0,
    })
  }

  // The direction of the level a node is laid out in: its nearest subgraph that sets one, or the diagram's.
  let horizontal = (i : Int32) => {
    let mut at = i
    let mut found = None
    // Subgraphs can name each other as members, so the walk up is bounded.
    for _ in 0..<graph.nodes.length() {
      guard graph.nodes[at].parent_id is Some(parent) &&
        index.get(parent) is Some(up) else {
        break
      }
      if graph.nodes[up].dir is Some(dir) && dir != "" {
        found = Some(dir == "LR" || dir == "RL")
        break
      }
      at = up
    }
    match found {
      Some(across) => across
      None => db.direction == "LR" || db.direction == "RL"
    }
  }
  for i, node in graph.nodes {
    let style = @svg.resolve_style(
      if node.css_styles.length() > 0 {
        node.css_compiled_styles + node.css_styles
      } else {
        node.css_compiled_styles
      },
    )
    let base = (if style.bold { @text.STYLE_BOLD } else { 0 }) |
      (if style.italic { @text.STYLE_ITALIC } else { 0 })
    let name_size = style.font_size.unwrap_or(size)
    let row_size = style.font_size.unwrap_or(small_size)
    let key_size = style.font_size.unwrap_or((size * 0.75).round())
    let label = if node.is_group {
      @text.layout_label(
        Some(node.label),
        true,
        measurer,
        name_size,
        4000,
        base~,
      )
    } else {
      let shown = if node.alias_name != "" {
        node.alias_name
      } else {
        node.label
      }
      @text.layout_label(Some(shown), true, measurer, name_size, 240, base~)
    }
    let own = loops.get(i).unwrap_or([])
    // Loops leave by a side the layout keeps free of other edges: the right when ranks run down, the bottom when they run across.
    let below = own.length() > 0 && !node.is_group && horizontal(i)
    let view = {
      node,
      style,
      label,
      w: 0,
      h: 0,
      head_h: 0,
      rows: [],
      cols: [],
      row_size,
      key_size,
      below,
    }
    let mut reach = 0.0
    let mut bands = 0.0
    for loop_ in own {
      loop_.band = @util.js_max(
        LOOP_BAND,
        if below {
          loop_.label.width + 12
        } else {
          loop_.label.height + 6
        },
      )
      bands += loop_.band
      reach = @util.js_max(
        reach,
        if below {
          loop_.label.height
        } else {
          loop_.label.width
        },
      )
    }
    let min_w = @util.js_max(MIN_WIDTH, if below { bands + 8 } else { 0 })
    let c = if node.is_group {
      let c = @layout.cnode(0, 0)
      c.is_group = true
      c.dir = match node.dir {
        Some(dir) if dir != "" => Some(@layout.direction(Some(dir)))
        _ => None
      }
      c.pad_x = GROUP_PAD
      c.pad_top = if label.height > 0 { label.height + 16 } else { GROUP_PAD }
      c.pad_bottom = GROUP_PAD
      c.min_w = @util.js_max(label.width + 2 * GROUP_PAD - 12, MIN_WIDTH)
      c
    } else {
      let name_h = @util.js_max(label.height, (name_size * 1.5).round())
      if node.attributes.length() == 0 {
        view.w = @util.js_max(label.width + 2 * BOX_PAD_X, min_w)
        view.h = @util.js_max(
          name_h + 2 * BOX_PAD_Y,
          if below {
            0
          } else {
            bands + 8
          },
        )
      } else {
        let row_line = (row_size * 1.5).round()
        let widths = FixedArray::make(4, 0.0)
        for attribute in node.attributes {
          let cells : FixedArray[@text.Label] = [
            @text.layout_label(
              Some(cell_text(attribute.data_type)),
              true,
              measurer,
              row_size,
              NO_WRAP,
              base~,
            ),
            @text.layout_label(
              Some(cell_text(attribute.name)),
              true,
              measurer,
              row_size,
              NO_WRAP,
              base~,
            ),
            @text.layout_label(
              Some(attribute.keys.join(", ")),
              false,
              measurer,
              key_size,
              NO_WRAP,
              base~,
            ),
            @text.layout_label(
              Some(cell_text(attribute.comment)),
              true,
              measurer,
              row_size,
              COMMENT_WRAP,
              base~,
            ),
          ]
          let mut h = row_line
          for k in 0..<4 {
            if cells[k].width > widths[k] {
              widths[k] = cells[k].width
            }
            if cells[k].height > h {
              h = cells[k].height
            }
          }
          view.rows.push({ cells, h: h + ROW_PAD, })
          view.h += h + ROW_PAD
        }
        let mut columns = 0
        let mut inner = 0.0
        for w in widths {
          if w == 0 {
            continue
          }
          inner += w + (if columns > 0 { CELL_GAP } else { 0 })
          columns += 1
        }
        view.w = @util.js_max(
          @util.js_max(inner + 2 * CELL_PAD_X, label.width + 2 * BOX_PAD_X),
          min_w,
        )
        // A box wider than its table shares the spare width between the columns.
        let spare = if columns > 0 {
          (view.w - inner - 2 * CELL_PAD_X) / columns.to_double()
        } else {
          0
        }
        let mut x = CELL_PAD_X
        for w in widths {
          view.cols.push(x)
          if w > 0 {
            x += w + spare + CELL_GAP
          }
        }
        view.head_h = name_h + 2 * HEAD_PAD_Y
        view.h += view.head_h
      }
      // The layout keeps a node centered in its box, so room for loops is added on both sides.
      let room : Double = if own.length() > 0 {
        2.0 * (MARKER_LENGTH + LOOP * 0.75 + 10 + reach)
      } else {
        0
      }
      if below {
        @layout.cnode(view.w, view.h + room)
      } else {
        @layout.cnode(view.w + room, view.h)
      }
    }
    c.seq = views.length().to_double()
    views.push(view)
    cnodes.push(c)
  }
  for i, node in graph.nodes {
    cnodes[i].parent = match node.parent_id {
      Some(parent) => index.get(parent).unwrap_or(-1)
      None => -1
    }
  }
  let layout = @layout.compound_layout(
    cnodes,
    cedges,
    if turned {
      TB
    } else {
      @layout.direction(Some(db.direction))
    },
    @layout.LayeredOptions::new(
      node_sep=number_option(config, "nodeSpacing", NODE_SEP),
      edge_sep=EDGE_SEP,
      rank_sep=number_option(config, "rankSpacing", RANK_SEP),
      port_sep=24,
    ),
  )
  spread_ends(cedges, cnodes, views)

  // A subgraph gets its size from the layout, so its loops hang outside it and may widen the diagram.
  let mut layout_width = layout.width
  for i, own in loops {
    let c = cnodes[i]
    if !c.is_group {
      continue
    }
    let mut reach = 0.0
    for loop_ in own {
      reach = @util.js_max(reach, loop_.label.width)
    }
    layout_width = @util.js_max(
      layout_width,
      c.x + c.w / 2 + MARKER_LENGTH + LOOP * 0.75 + 10 + reach,
    )
  }
  let title = @svg.title_label(db.title, measurer, size, 4000)
  let title_height = if title.height > 0 { title.height + 12 } else { 0 }
  let inner = @util.js_max(layout_width, title.width)
  let ox = pad + (inner - layout_width) / 2
  let oy = pad + title_height
  @layout.shift_layout(cnodes, cedges, ox, oy)
  let width = (inner + 2 * pad).ceil()
  let height = (layout.height + title_height + 2 * pad).ceil()
  let links : Array[@types.LinkInfo] = []
  let crossings = @svg.Crossings::new()
  if cnodes.iter().any(c => c.is_group) {
    for e in cedges {
      @svg.mark_crossings(crossings, e.route)
    }
  }
  let clusters = @svg.Markup::new()
  let nodes_out = @svg.Markup::new()
  for i, view in views {
    let c = cnodes[i]
    let node = view.node
    let classes = @svg.node_class_names(node.css_classes)
    if c.is_group {
      view.w = c.w
      view.h = c.h
      let x = c.x - c.w / 2
      let y = c.y - c.h / 2
      let title_x = @svg.cluster_title_x(
        c,
        view.label.width,
        crossings,
        GROUP_PAD,
      )
      clusters.write("<g class=\"pele-cluster\{classes}\"")
      clusters.write_data_id(node.id)
      clusters.write(
        "><rect x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y)}\" width=\"\{@svg.num(c.w)}\" height=\"\{@svg.num(c.h)}\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\"\{@svg.rounded(view.style.shape)}/>",
      )
      @svg.write_label(
        clusters,
        view.label,
        title_x,
        y + 8 + view.label.height / 2,
        " class=\"pele-cluster-label\" fill=\"var(--_m)\"\{view.style.text}",
        icons?=options.icons,
      )
      clusters.write("</g>")
      continue
    }
    let w = view.w
    let h = view.h
    let x0 = -w / 2
    let y0 = -h / 2
    let text = view.style.text
    let shape = "x=\"\{@svg.num(x0)}\" y=\"\{@svg.num(y0)}\" width=\"\{@svg.num(w)}\" height=\"\{@svg.num(h)}\""
    let label = @svg.Markup::new()
    @svg.write_label(
      label,
      view.label,
      0,
      if view.rows.length() > 0 {
        y0 + view.head_h / 2
      } else {
        0
      },
      " class=\"pele-label\"\{text}",
      icons?=options.icons,
    )
    let display = @text.decode_entities(
      if node.alias_name != "" {
        node.alias_name
      } else {
        node.label
      },
    )
    let name = @svg.Markup::new()
    if (classes + " ").contains(" internal-link ") &&
      !label.is_empty() &&
      options.links != Some(false) {
      name.write("<a class=\"internal-link\"")
      // The name ends up in an href, so it gets the same check as a URL.
      if @url.link_url(@url.sanitize_url(display), options) is Some(_) {
        name.write(" href=\"")
        name.write_esc(display)
        name.write("\"\{@url.rel_attr(options)}")
      }
      name.write(" data-href=\"")
      name.write_esc(display)
      name.write_group("\">", label, "</a>")
      links.push({ id: node.label, href: display, internal: true, })
    } else {
      name.write_markup(label)
    }
    nodes_out.write("<g class=\"pele-node pele-entity\{classes}\"")
    nodes_out.write_data_id(node.label)
    nodes_out.write(
      " transform=\"translate(\{@svg.num(c.x)},\{@svg.num(c.y)})\">",
    )
    if view.rows.length() == 0 {
      nodes_out.write(
        "<rect \{shape}\{@svg.rounded(BOX_ATTRS + view.style.shape)}/>",
      )
      nodes_out.write_markup(name)
    } else {
      let row_line = (view.row_size * 1.5).round()
      let line_color = match view.style.stroke {
        Some(stroke) if stroke != "" => @svg.esc(stroke)
        _ => "var(--_b)"
      }
      let stripes = @svg.Markup::new()
      let cells = @svg.Markup::new()
      let mut y = y0 + view.head_h
      for r, row in view.rows {
        if r % 2 == 0 {
          let span = "x=\"\{@svg.num(x0)}\" width=\"\{@svg.num(w)}\""
          if r == view.rows.length() - 1 {
            // The last row follows the box's rounded bottom corners: a rounded rect, squared off on top.
            stripes.write(
              "<rect \{span} y=\"\{@svg.num(y)}\" height=\"\{@svg.num(row.h)}\"\{@svg.ROUNDED}/>" +
              "<rect \{span} y=\"\{@svg.num(y)}\" height=\"\{@svg.num(row.h / 2)}\"/>",
            )
          } else {
            stripes.write(
              "<rect \{span} y=\"\{@svg.num(y)}\" height=\"\{@svg.num(row.h)}\"/>",
            )
          }
        }
        let baseline = y + ROW_PAD / 2 + row_line / 2 + view.row_size * 0.35
        write_text_left(
          cells,
          row.cells[0],
          x0 + view.cols[0],
          baseline,
          " class=\"pele-er-type\" fill=\"var(--_m)\"\{text}",
          options.icons,
        )
        write_text_left(
          cells,
          row.cells[1],
          x0 + view.cols[1],
          baseline,
          " class=\"pele-er-name\"\{text}",
          options.icons,
        )
        write_text_left(
          cells,
          row.cells[2],
          x0 + view.cols[2],
          baseline,
          " class=\"pele-er-keys\" font-size=\"\{view.key_size}\" fill=\"var(--_m)\"\{text}",
          options.icons,
        )
        write_text_left(
          cells,
          row.cells[3],
          x0 + view.cols[3],
          baseline,
          " class=\"pele-er-comment\" fill=\"var(--_m)\"\{text}",
          options.icons,
        )
        y += row.h
      }
      let divider_y = @svg.num(y0 + view.head_h)
      // Over a fill the diagram chose, the shading is a tint of that fill.
      // The opacity is on the group because the two parts of the last row overlap.
      let tint = if view.style.shape.contains("fill:") {
        " opacity=\"0.6\""
      } else {
        ""
      }
      nodes_out.write(
        "<rect \{shape}\{@svg.rounded(BOX_ATTRS + view.style.shape)}/>",
      )
      nodes_out.write_group(
        "<g class=\"pele-er-stripes\" fill=\"var(--_bg)\"\{tint}>",
        stripes,
        "</g>",
      )
      nodes_out.write(
        "<path class=\"pele-er-divider\" d=\"M\{@svg.num(x0)},\{divider_y}H\{@svg.num(x0 + w)}\" stroke=\"\{line_color}\"/>" +
        "<rect \{shape} fill=\"none\" stroke=\"var(--_b)\"\{@svg.rounded(view.style.line)}/>",
      )
      nodes_out.write_markup(name)
      nodes_out.write_group(
        "<g class=\"pele-er-attributes\" font-size=\"\{view.row_size}\">",
        cells,
        "</g>",
      )
    }
    nodes_out.write("</g>")
  }

  // Self-relationships share the side they loop out of, squeezed together if it is too short for them.
  for i, own in loops {
    let view = views[i]
    let mut total = 0.0
    for loop_ in own {
      total += loop_.band
    }
    let side = if view.below { view.w } else { view.h }
    let scale = @util.js_min(1, @util.js_max(side - 8, 0) / total)
    let mut at = -total * scale / 2
    for loop_ in own {
      loop_.band *= scale
      loop_.at = at + loop_.band / 2
      at += loop_.band
    }
  }
  let edges_out = @svg.Markup::new()
  let labels_out = @svg.Markup::new()
  for i, ce in cedges {
    let edge = drawn[i]
    let label = edge_labels[i]
    let mut d = ""
    let mut start = ""
    let mut end = ""
    match loop_of[i] {
      Some(loop_) => {
        let c = cnodes[ce.src]
        let view = views[ce.src]
        let spread = @util.js_max(@util.js_min(loop_.band / 2 - 6, 13), 1)
        let far = MARKER_LENGTH + LOOP * 0.75 + 6
        if view.below {
          let x = c.x + loop_.at
          let y = c.y + view.h / 2
          let turn = @svg.num(y + MARKER_LENGTH)
          let out = @svg.num(y + MARKER_LENGTH + LOOP)
          d = "M\{@svg.num(x - spread)},\{@svg.num(y)}V\{turn}C\{@svg.num(x - spread)},\{out} \{@svg.num(x + spread)},\{out} \{@svg.num(x + spread)},\{turn}V\{@svg.num(y)}"
          start = er_marker(edge.arrow_type_start, x - spread, y, 0, -1)
          end = er_marker(edge.arrow_type_end, x + spread, y, 0, -1)
          ce.label_x = x
          ce.label_y = y + far + label.height / 2
        } else {
          let x = c.x + view.w / 2
          let y = c.y + loop_.at
          let turn = @svg.num(x + MARKER_LENGTH)
          let out = @svg.num(x + MARKER_LENGTH + LOOP)
          d = "M\{@svg.num(x)},\{@svg.num(y - spread)}H\{turn}C\{out},\{@svg.num(y - spread)} \{out},\{@svg.num(y + spread)} \{turn},\{@svg.num(y + spread)}H\{@svg.num(x)}"
          start = er_marker(edge.arrow_type_start, x, y - spread, -1, 0)
          end = er_marker(edge.arrow_type_end, x, y + spread, -1, 0)
          ce.label_x = x + far + label.width / 2
          ce.label_y = y
        }
      }
      None => {
        let route = straighten(ce.route)
        if route.length() < 6 {
          continue
        }
        inset(route, 0, views[ce.src], cnodes[ce.src])
        inset(route, route.length() - 3, views[ce.dst], cnodes[ce.dst])
        // A curve stops short of each box so that the marker sits on a straight run of line.
        let dx = (route[route.length() - 3] - route[0]).abs()
        let dy = (route[route.length() - 2] - route[1]).abs()
        let direct = route.length() == 6 &&
          (
            dx < 0.01 ||
            dy < 0.01 ||
            @util.js_hypot(dx, dy) <= 3 * MARKER_LENGTH
          )
        let stub = if direct { 0.0 } else { MARKER_LENGTH }
        let path = @svg.route_path(route, None, stub, stub)
        d = if stub > 0 {
          "M\{@svg.num(path.sx)},\{@svg.num(path.sy)}L\{@util.slice(path.d, 1)}L\{@svg.num(path.ex)},\{@svg.num(path.ey)}"
        } else {
          path.d
        }
        start = er_marker(
          edge.arrow_type_start,
          path.sx,
          path.sy,
          path.sdx,
          path.sdy,
        )
        end = er_marker(
          edge.arrow_type_end,
          path.ex,
          path.ey,
          path.edx,
          path.edy,
        )
      }
    }
    let kind = if edge.dashed { "non-identifying" } else { "identifying" }
    let dash = if edge.dashed { " stroke-dasharray=\"4 3\"" } else { "" }
    edges_out.write("<g class=\"pele-edge pele-er-\{kind}\"")
    edges_out.write_data_id(edge.id)
    edges_out.write("><path d=\"\{d}\"\{dash}/>" + start + end + "</g>")
    if label.width > 0 {
      @svg.write_edge_label_with_id(
        labels_out,
        edge.id,
        label,
        ce.label_x,
        ce.label_y,
        "",
        icons?=options.icons,
      )
    }
  }
  let content = @svg.Markup::new()
  @svg.write_label(
    content,
    title,
    width / 2,
    pad + title.height / 2,
    " class=\"pele-title\" font-weight=\"var(--_tw)\"",
  )
  if !clusters.is_empty() {
    content.write_group("<g class=\"pele-clusters\">", clusters, "</g>")
  }
  if !edges_out.is_empty() {
    content.write_group(
      "<g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\">",
      edges_out, "</g>",
    )
  }
  if !labels_out.is_empty() {
    content.write_group(
      "<g class=\"pele-edge-labels\" font-size=\"\{small_size}\">",
      labels_out,
      "</g>",
    )
  }
  content.write_group("<g class=\"pele-nodes\">", nodes_out, "</g>")
  let svg = @svg.markup_document(
    "er",
    width,
    height,
    size,
    options,
    db.acc_title,
    db.acc_descr,
    content,
  )
  { svg, width, height, links, }
}

///|
/// Drops the middle point of three that lie on one horizontal or vertical line.
fn straighten(route : Array[Double]) -> Array[Double] {
  let out = route[0:3].to_owned()
  let mut k = 3
  while k < route.length() {
    let prev = out.length() - 3
    let flat = (axis : Int32) => {
      (out[prev + axis] - route[k + axis]).abs() < 0.01 &&
      (route[k + axis] - route[k + 3 + axis]).abs() < 0.01
    }
    if k + 3 < route.length() && (flat(0) || flat(1)) {
      k += 3
      continue
    }
    out.push(route[k])
    out.push(route[k + 1])
    out.push(route[k + 2])
    k += 3
  }
  out
}

///|
priv struct End {
  route : Array[Double]
  at : Int32
  toward : Double
}

///|
/// The layout brings every edge that ends on one side of a box to the middle of that side, where their markers would cover each other.
/// This spaces them along the side, in the order they fan out.
fn spread_ends(
  cedges : Array[@layout.CEdge],
  cnodes : Array[@layout.CNode],
  views : Array[NodeView],
) -> Unit {
  let sides : Map[Int32, Array[End]] = Map([])
  let add = (node : Int32, route : Array[Double], at : Int32, next : Int32) => {
    let c = cnodes[node]
    let dx = route[at] - c.x
    let dy = route[at + 1] - c.y
    let side = if (dy.abs() - c.h / 2).abs() < 0.5 {
      if dy < 0 {
        0
      } else {
        2
      }
    } else if (dx.abs() - c.w / 2).abs() < 0.5 {
      if dx < 0 {
        3
      } else {
        1
      }
    } else {
      return
    }
    let key = node * 4 + side
    let end = {
      route,
      at,
      toward: route[next + (if (side & 1) != 0 { 1 } else { 0 })],
    }
    match sides.get(key) {
      Some(list) => list.push(end)
      None => sides.set(key, [end])
    }
  }
  for e in cedges {
    let last = e.route.length() - 3
    if e.src == e.dst || last < 3 {
      continue
    }
    add(e.src, e.route, 0, 3)
    add(e.dst, e.route, last, last - 3)
  }
  for key, ends in sides {
    if ends.length() < 2 {
      continue
    }
    let node = key >> 2
    let vertical = (key & 1) == 1
    let length = if cnodes[node].is_group {
      if vertical {
        cnodes[node].h
      } else {
        cnodes[node].w
      }
    } else if vertical {
      views[node].h
    } else {
      views[node].w
    }
    let step = @util.js_max(
      @util.js_min(
        PORT_GAP,
        (length - 2 * PORT_MARGIN) / (ends.length() - 1).to_double(),
      ),
      0,
    )
    let center = if vertical { cnodes[node].y } else { cnodes[node].x }
    // A stable sort, as JavaScript's: ties keep the order the ends were found in.
    let order = Array::makei(ends.length(), i => i)
    order.sort_by((a, b) => {
      let by_toward = ends[a].toward.compare(ends[b].toward)
      if by_toward != 0 {
        by_toward
      } else {
        a.compare(b)
      }
    })
    let count = ends.length().to_double()
    for i, which in order {
      let end = ends[which]
      end.route[end.at + (if vertical { 1 } else { 0 })] = center +
        (i.to_double() - (count - 1) / 2) * step
    }
  }
}

///|
/// An entity with a self-relationship is laid out larger than it is drawn.
/// This moves a route end from the side of that larger box onto the entity's own side.
fn inset(
  route : Array[Double],
  at : Int32,
  view : NodeView,
  c : @layout.CNode,
) -> Unit {
  if c.is_group {
    return
  }
  let dx = route[at] - c.x
  let dy = route[at + 1] - c.y
  if c.w != view.w && (dx.abs() - c.w / 2).abs() < 0.5 {
    route[at] -= js_sign(dx) * (c.w - view.w) / 2
  }
  if c.h != view.h && (dy.abs() - c.h / 2).abs() < 0.5 {
    route[at + 1] -= js_sign(dy) * (c.h - view.h) / 2
  }
}
