///|
const NODE_SEP : Double = 40

///|
const EDGE_SEP : Double = 16

///|
const RANK_SEP : Double = 56

///|
const PAD_X : Double = 14

///|
const PAD_Y : Double = 10

///|
const ROW_GAP : Double = 2

///|
const COLUMN_GAP : Double = 12

///|
const MIN_WIDTH : Double = 120

///|
const NAME_WRAP : Double = 280

///|
const VALUE_WRAP : Double = 240

///|
const LOOP : Double = 26

///|
const CONTAINS_RADIUS : Double = 6

///|
const ARROW_LENGTH : Double = 9

///|
const ARROW_HALF : Double = 4.5

///|
const END_STEP : Double = 28

///|
const END_MARGIN : Double = 14

///|
priv struct Row {
  key : @text.Label
  value : @text.Label
  height : Double
}

///|
priv struct NodeView {
  node : GraphNode
  style : @svg.ResolvedStyle
  kind : @text.Label
  name : @text.Label
  rows : Array[Row]
  key_width : Double
  head_height : Double
  w : Double
  h : Double
}

///|
/// Adds bold or italic to a whole label after its markdown is read, since emphasis markers only
/// toggle styles the label does not start with.
fn restyle(
  label : @text.Label,
  bits : Int32,
  measurer : @text.TextMeasurer,
) -> @text.Label {
  if bits == 0 || label.lines.is_empty() {
    return label
  }
  let mut width = 0.0
  let widths = []
  let lines = label.lines.map(line => {
    let mut total = 0.0
    let spans = line.map(span => {
      let style = span.style | bits
      let w = if span.icon is Some(_) || span.math is Some(_) {
        span.width
      } else {
        measurer.width(span.text, label.size, style)
      }
      total += w
      { ..span, style, width: w, }
    })
    widths.push(total)
    if total > width {
      width = total
    }
    spans
  })
  { ..label, lines, widths, width, }
}

///|
/// Writes a measured label to `out` with its lines starting at `x`, the first line's box starting at `top`.
fn write_start_text(
  out : @svg.Markup,
  label : @text.Label,
  x : Double,
  top : Double,
  attrs : String,
) -> Unit raise @errors.PeleError {
  let shared = @svg.shared_style(label)
  let body = @svg.Markup::new()
  let math = @svg.Markup::new()
  for i, line in label.lines {
    let middle = top + @text.line_middle(label, i)
    if @text.has_math(line) {
      @svg.write_label(
        math,
        @text.label_line(label, i),
        x + label.widths[i] / 2,
        middle,
        attrs,
      )
      continue
    }
    let y = middle + label.size * 0.35
    let mut first = true
    for span in line {
      if span.text == "" {
        continue
      }
      let pos = if first {
        " x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y)}\""
      } else {
        ""
      }
      body.write(
        "<tspan\{pos}\{@svg.span_style(span.style & shared.lnot())}>\{@svg.esc(span.text)}</tspan>",
      )
      first = false
    }
  }
  if !body.is_empty() {
    out.write_group(
      "<text\{@svg.text_style(attrs, shared)} text-anchor=\"start\" xml:space=\"preserve\">",
      body,
      "</text>",
    )
  }
  out.write_markup(math)
}

///|
/// The containment mark: a circled plus whose rim touches (`x`, `y`), where (`dx`, `dy`) points at the node.
fn contains_marker(x : Double, y : Double, dx : Double, dy : Double) -> String {
  let r = CONTAINS_RADIUS
  let cx = x - dx * r
  let cy = y - dy * r
  let n = @svg.num
  "<circle class=\"pele-marker\" cx=\"\{n(cx)}\" cy=\"\{n(cy)}\" r=\"\{r}\"/>" +
  "<path class=\"pele-marker\" d=\"M\{n(cx - dx * r)},\{n(cy - dy * r)}L\{n(cx + dx * r)},\{n(cy + dy * r)}M\{n(cx + dy * r)},\{n(cy - dx * r)}L\{n(cx - dy * r)},\{n(cy + dx * r)}\"/>"
}

///|
/// An open arrowhead with its tip at (`x`, `y`), pointing along (`dx`, `dy`).
fn arrow_marker(x : Double, y : Double, dx : Double, dy : Double) -> String {
  let bx = x - dx * ARROW_LENGTH
  let by = y - dy * ARROW_LENGTH
  let n = @svg.num
  "<path class=\"pele-marker\" d=\"M\{n(bx - dy * ARROW_HALF)},\{n(by + dx * ARROW_HALF)}L\{n(x)},\{n(y)}L\{n(bx + dy * ARROW_HALF)},\{n(by - dx * ARROW_HALF)}\" stroke-linejoin=\"round\"/>"
}

///|
priv struct End {
  route : Array[Double]
  at : Int32
  toward : Double
  order : Int32
}

///|
/// The layout attaches every edge to the middle of a node's side.
/// Ends that share a side are spread along it, in the order of where they head, so their markers
/// do not sit on each other.
fn spread_ends(
  cnodes : Array[@layout.CNode],
  cedges : Array[@layout.CEdge],
  views : Array[NodeView],
) -> Unit {
  let sides : Map[Int32, Array[End]] = Map([])
  for edge in cedges {
    let route = edge.route
    if edge.src == edge.dst || route.length() < 6 {
      continue
    }
    for at in [0, route.length() - 3] {
      let node = if at == 0 { edge.src } else { edge.dst }
      let c = cnodes[node]
      let dx = route[at] - c.x
      let dy = route[at + 1] - c.y
      let next = if at == 0 { 3 } else { at - 3 }
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
        continue
      }
      let key = node * 4 + side
      let toward = route[if side % 2 == 0 { next } else { next + 1 }]
      match sides.get(key) {
        Some(list) => list.push({ route, at, toward, order: list.length(), })
        None => sides.set(key, [{ route, at, toward, order: 0, }])
      }
    }
  }
  for key, list in sides {
    if list.length() < 2 {
      continue
    }
    let node = key >> 2
    let vertical = key % 2 == 1
    let span = (if vertical { views[node].h } else { views[node].w }) -
      2.0 * END_MARGIN
    let step = @util.js_max(
      0,
      @util.js_min(END_STEP, span / (list.length() - 1).to_double()),
    )
    list.sort_by((a, b) => {
      let by_toward = a.toward.compare(b.toward)
      if by_toward != 0 {
        by_toward
      } else {
        a.order.compare(b.order)
      }
    })
    for j, end in list {
      let offset = (j.to_double() - (list.length() - 1).to_double() / 2) * step
      if vertical {
        end.route[end.at + 1] = cnodes[node].y + offset
      } else {
        end.route[end.at] = cnodes[node].x + offset
      }
    }
  }
}

///|
/// Draws a requirement diagram, turned to run down when a narrow host needs it.
pub fn render_requirement(
  db : RequirementDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  ignore(config)
  if !@common.runs_across(Some(db.direction)) {
    return draw(db, options, false)
  }
  @common.turn_to_fit(options, down => draw(db, options, down))
}

///|
fn label(
  text : String,
  markdown : Bool,
  measurer : @text.TextMeasurer,
  size : Double,
  wrap : Double,
) -> @text.Label {
  @text.layout_label(Some(text), markdown, measurer, size, wrap)
}

///|
/// `turned` draws a diagram that runs across as one that runs down.
fn draw(
  db : RequirementDb,
  options : @types.RenderOptions,
  turned : Bool,
) -> @types.Rendered raise @errors.PeleError {
  let graph = build_requirement_graph(db)
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.875).round()
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let index : Map[String, Int32] = Map([])
  let views : Array[NodeView] = []
  let cnodes : Array[@layout.CNode] = []
  for node in graph.nodes {
    let style = @svg.resolve_style(node.css_styles)
    let base = (if style.bold { @text.STYLE_BOLD } else { 0 }) |
      (if style.italic { @text.STYLE_ITALIC } else { 0 })
    let name_size = style.font_size.unwrap_or(size)
    let body_size = style.font_size.unwrap_or(small)
    let kind_name = match node.requirement {
      Some(requirement) => requirement.kind
      None => "Element"
    }
    let kind = restyle(
      label("«\{kind_name}»", false, measurer, body_size, 4000),
      base,
      measurer,
    )
    let name = restyle(
      label(node.id, true, measurer, name_size, NAME_WRAP),
      base | @text.STYLE_BOLD,
      measurer,
    )
    let fields = match (node.requirement, node.element) {
      (Some(requirement), _) =>
        [
          ("ID", requirement.requirement_id),
          ("Text", requirement.text),
          ("Risk", requirement.risk),
          ("Verification", requirement.verify_method),
        ]
      (None, Some(element)) =>
        [("Type", element.kind), ("Doc Ref", element.doc_ref)]
      (None, None) => []
    }
    let rows : Array[Row] = []
    let mut key_width = 0.0
    let mut value_width = 0.0
    let mut body_height = 0.0
    for field in fields {
      let (name, text) = field
      if text == "" {
        continue
      }
      let key = restyle(
        label(name, false, measurer, body_size, 4000),
        base,
        measurer,
      )
      let value = restyle(
        label(text, true, measurer, body_size, VALUE_WRAP),
        base,
        measurer,
      )
      let height = @util.js_max(key.height, value.height)
      rows.push({ key, value, height, })
      key_width = @util.js_max(key_width, key.width)
      value_width = @util.js_max(value_width, value.width)
      body_height += height + ROW_GAP
    }
    if rows.length() > 0 {
      body_height += 2.0 * PAD_Y - ROW_GAP
    }
    let head_height = 2.0 * PAD_Y + kind.height + name.height
    let w = @util.js_max(
      MIN_WIDTH,
      @util.js_max(
        @util.js_max(kind.width, name.width) + 2.0 * PAD_X,
        if rows.length() > 0 {
          key_width + COLUMN_GAP + value_width + 2.0 * PAD_X
        } else {
          0
        },
      ),
    )
    // A requirement and an element may share a name; relationships then go to the requirement.
    if !index.contains(node.id) {
      index.set(node.id, views.length())
    }
    let c = @layout.cnode(w, head_height + body_height)
    c.seq = views.length().to_double()
    views.push({
      node,
      style,
      kind,
      name,
      rows,
      key_width,
      head_height,
      w,
      h: head_height + body_height,
    })
    cnodes.push(c)
  }
  let root_dir = if turned {
    @layout.Dir::TB
  } else {
    @layout.direction(Some(graph.direction))
  }
  let sideways = root_dir is (LR | RL)
  let cedges : Array[@layout.CEdge] = []
  let edge_labels : Array[@text.Label] = []
  let drawn : Array[GraphEdge] = []
  for edge in graph.edges {
    let src = match edge.start {
      Some(start) => index.get(start)
      None => None
    }
    let dst = match edge.end {
      Some(end) => index.get(end)
      None => None
    }
    guard src is Some(src) && dst is Some(dst) else { continue }
    let edge_label = label("«\{edge.kind}»", false, measurer, small, 4000)
    if src == dst {
      // A self-loop sits beside the node, across the flow, and the node's box grows to hold it.
      if sideways {
        cnodes[src].h += 2.0 * (LOOP + edge_label.height + 8)
      } else {
        cnodes[src].w += 2.0 * (LOOP + edge_label.width + 12)
      }
    }
    drawn.push(edge)
    edge_labels.push(edge_label)
    cedges.push({
      src,
      dst,
      minlen: 1,
      label_w: edge_label.width + 12,
      label_h: edge_label.height + 4,
      route: [],
      label_x: 0,
      label_y: 0,
    })
  }
  let layout = @layout.compound_layout(
    cnodes,
    cedges,
    root_dir,
    @layout.LayeredOptions::new(
      node_sep=NODE_SEP,
      edge_sep=EDGE_SEP,
      rank_sep=RANK_SEP,
      port_sep=20,
    ),
  )
  spread_ends(cnodes, cedges, views)
  let title = @svg.title_label(db.title, measurer, size, 4000)
  let title_height = if title.height > 0 { title.height + 12 } else { 0 }
  let inner = @util.js_max(layout.width, title.width)
  let ox = pad + (inner - layout.width) / 2
  let oy = pad + title_height
  let width = (inner + 2.0 * pad).ceil()
  let height = (layout.height + title_height + 2.0 * pad).ceil()
  let n = @svg.num
  let nodes_out = @svg.Markup::new()
  for i, view in views {
    let { w, h, style, .. } = view
    let left = -w / 2
    let top = -h / 2
    let body = @svg.Markup::new()
    body.write(
      "<rect x=\"\{n(left)}\" y=\"\{n(top)}\" width=\"\{n(w)}\" height=\"\{n(h)}\" fill=\"var(--_s)\" stroke=\"var(--_b)\"\{@svg.rounded(style.shape)}/>",
    )
    @svg.write_label(
      body,
      view.kind,
      0,
      top + PAD_Y + view.kind.height / 2,
      " class=\"pele-stereotype\" font-size=\"\{view.kind.size}\" fill=\"var(--_m)\"\{style.text}",
    )
    @svg.write_label(
      body,
      view.name,
      0,
      top + PAD_Y + view.kind.height + view.name.height / 2,
      " class=\"pele-label\" font-size=\"\{view.name.size}\" font-weight=\"var(--_hw)\"\{style.text}",
    )
    if view.rows.length() > 0 {
      let divider = top + view.head_height
      body.write(
        "<path class=\"pele-divider\" d=\"M\{n(left)},\{n(divider)}H\{n(-left)}\" stroke=\"var(--_b)\"\{style.line}/>",
      )
      let mut y = divider + PAD_Y
      let rows = @svg.Markup::new()
      for row in view.rows {
        write_start_text(
          rows,
          row.key,
          left + PAD_X,
          y,
          " class=\"pele-field\" fill=\"var(--_m)\"\{style.text}",
        )
        write_start_text(
          rows,
          row.value,
          left + PAD_X + view.key_width + COLUMN_GAP,
          y,
          " class=\"pele-value\"\{style.text}",
        )
        y += row.height + ROW_GAP
      }
      body.write_group(
        "<g class=\"pele-fields\" font-size=\"\{view.rows[0].key.size}\">",
        rows,
        "</g>",
      )
    }
    let kind_class = if view.node.requirement is Some(_) {
      "pele-requirement"
    } else {
      "pele-element"
    }
    nodes_out.write_group(
      "<g class=\"pele-node \{kind_class}\{@svg.node_class_names(view.node.css_classes)}\" data-id=\"\{@svg.esc_text(view.node.id)}\" transform=\"translate(\{n(cnodes[i].x + ox)},\{n(cnodes[i].y + oy)})\">",
      body,
      "</g>",
    )
  }
  let edges_out = @svg.Markup::new()
  let labels_out = @svg.Markup::new()
  let loop_seen : Map[Int32, Int32] = Map([])
  for i, ce in cedges {
    let edge = drawn[i]
    let edge_label = edge_labels[i]
    let start_trim = if edge.contains { 2.0 * CONTAINS_RADIUS } else { 0 }
    let mut label_x = ce.label_x + ox
    let mut label_y = ce.label_y + oy
    let path = if ce.src == ce.dst {
      let view = views[ce.src]
      let cx = cnodes[ce.src].x + ox
      let cy = cnodes[ce.src].y + oy
      let k = loop_seen.get(ce.src).unwrap_or(0)
      loop_seen.set(ce.src, k + 1)
      let half = (if sideways { view.w } else { view.h }) / 2
      let spread = @util.js_min(half - 4, 12 + k.to_double() * 6)
      let reach = LOOP + k.to_double() * 8
      // Local frame: `out` points away from the node, `along` runs along its side.
      let at = (out : Double, along : Double) => {
        if sideways {
          "\{n(cx + along)},\{n(cy + view.h / 2 + out)}"
        } else {
          "\{n(cx + view.w / 2 + out)},\{n(cy + along)}"
        }
      }
      // A cubic whose control points are this far out peaks at `reach`.
      let pull = reach / 0.75
      if sideways {
        label_x = cx
        label_y = cy + view.h / 2 + reach + 4 + ce.label_h / 2
      } else {
        label_x = cx + view.w / 2 + reach + 4 + ce.label_w / 2
        label_y = cy
      }
      @svg.EdgePath::{
        d: "M\{at(start_trim, -spread)}C\{at(pull, -spread)} \{at(pull, spread)} \{at(0, spread)}",
        sx: if sideways {
          cx - spread
        } else {
          cx + view.w / 2
        },
        sy: if sideways {
          cy + view.h / 2
        } else {
          cy - spread
        },
        sdx: if sideways {
          0
        } else {
          -1
        },
        sdy: if sideways {
          -1
        } else {
          0
        },
        ex: if sideways {
          cx + spread
        } else {
          cx + view.w / 2
        },
        ey: if sideways {
          cy + view.h / 2
        } else {
          cy + spread
        },
        edx: if sideways {
          0
        } else {
          -1
        },
        edy: if sideways {
          -1
        } else {
          0
        },
      }
    } else {
      let route = ce.route.copy()
      for k = 0; k < route.length(); k = k + 3 {
        route[k] += ox
        route[k + 1] += oy
      }
      @svg.route_path(route, None, start_trim, 0)
    }
    let (relationship, dash) = if edge.contains {
      ("contains", "")
    } else {
      ("arrow", " stroke-dasharray=\"5 4\"")
    }
    let mark = if edge.contains {
      contains_marker(path.sx, path.sy, path.sdx, path.sdy)
    } else {
      arrow_marker(path.ex, path.ey, path.edx, path.edy)
    }
    edges_out.write(
      "<g class=\"pele-edge pele-relationship-\{relationship}\" data-id=\"\{@svg.esc_text(edge.id)}\"><path d=\"\{path.d}\"\{dash}/>\{mark}</g>",
    )
    @svg.write_edge_label(labels_out, edge.id, edge_label, label_x, label_y, "")
  }
  let content = @svg.Markup::new()
  content.write(
    @svg.label_svg(
      title,
      width / 2,
      pad + title.height / 2,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
    ),
  )
  if !edges_out.is_empty() {
    content.write_group(
      "<g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\">",
      edges_out, "</g>",
    )
  }
  if !labels_out.is_empty() {
    content.write_group(
      "<g class=\"pele-edge-labels\" font-size=\"\{small}\" fill=\"var(--_m)\">",
      labels_out,
      "</g>",
    )
  }
  content.write_group("<g class=\"pele-nodes\">", nodes_out, "</g>")
  let svg = @svg.markup_document(
    "requirement",
    width,
    height,
    size,
    options,
    db.acc_title,
    db.acc_descr,
    content,
  )
  { svg, width, height, links: [], }
}
