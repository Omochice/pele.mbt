///|
/// The number of series colors, which is the palette Mermaid's slot rules are applied to.
const PALETTE : Int32 = 8

///|
const NODE_SEP : Double = 40

///|
const EDGE_SEP : Double = 16

///|
const RANK_SEP : Double = 48

///|
const GROUP_PAD : Double = 20

///|
const LOOP : Double = 26

///|
const DOTS : Double = 14

///|
const COLLAPSED : String = "collapsed"

///|
/// The side a flow runs toward, with sides numbered clockwise from the top.
fn flow_end(dir : @layout.Dir) -> Int32 {
  match dir {
    TB => 2
    RL => 3
    BT => 0
    LR => 1
  }
}

///|
/// The graph drawn from the model, built the first time it is asked for with the curve the `flowchart` section names.
/// Building it records the model's shape and containment diagnostics.
pub fn agent_graph(db : AgentflowDb, config : @types.Config) -> AgentGraph {
  match db.graph {
    Some(graph) => graph
    None => {
      let curve = match config.get("flowchart") {
        Some(Object(flow)) =>
          match flow.get("curve") {
            Some(String(curve)) => Some(curve)
            _ => None
          }
        _ => None
      }
      let graph = build_agent_graph(db, PALETTE, default_curve?=curve)
      db.graph = Some(graph)
      graph
    }
  }
}

///|
fn agentflow_section(config : @types.Config) -> Map[String, Json] {
  match config.get("agentflow") {
    Some(Object(section)) => section
    _ => {}
  }
}

///|
/// A palette color as an outline with a light wash of the same color inside.
/// A fill the author set replaces the wash and stays opaque.
fn tint(slot : Int32, wash : String, style : @svg.ResolvedStyle) -> String {
  let color = @svg.series_color(slot)
  let opacity = if style.shape.contains("\"fill:") ||
    style.shape.contains(";fill:") {
    ""
  } else {
    " fill-opacity=\"\{wash}\""
  }
  " fill=\"\{color}\"\{opacity} stroke=\"\{color}\""
}

///|
fn dot(x : Double, y : Double) -> String {
  "M\{@svg.num(x - 1.75)},\{@svg.num(y)}a1.75,1.75 0 1 0 3.5,0a1.75,1.75 0 1 0 -3.5,0Z"
}

///|
priv struct NodeView {
  node : GraphNode
  style : @svg.ResolvedStyle
  label : @text.Label
  shape : String
  w : Double
  h : Double
  dy : Double
}

///|
/// An edge between a node and a container around it, drawn after the layout.
priv struct Held {
  edge : GraphEdge
  label : @text.Label
  src : Int32
  dst : Int32
}

///|
/// Draws an agentflow, turned to run down when a narrow host needs it.
pub fn render_agentflow(
  db : AgentflowDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  if @common.runs_across(db.direction) {
    @common.turn_to_fit(options, down => draw(db, config, options, down))
  } else {
    draw(db, config, options, false)
  }
}

///|
/// `turned` draws a diagram that runs across as one that runs down.
fn draw(
  db : AgentflowDb,
  config : @types.Config,
  options : @types.RenderOptions,
  turned : Bool,
) -> @types.Rendered raise @errors.PeleError {
  let graph = agent_graph(db, config)
  let section = agentflow_section(config)
  let size = options.font_size.unwrap_or(16)
  let edge_size = (size * 0.875).round()
  let measurer = options.text_measurer()
  let wrap_width = @flowchart.number_option(section, "wrappingWidth", 120)
  let min_width = @flowchart.number_option(section, "minNodeWidth", 120)
  let pad = options.padding.unwrap_or(8)
  let index : Map[String, Int32] = Map([])
  let views : Array[NodeView] = []
  let cnodes : Array[@layout.CNode] = []
  for i, node in graph.nodes {
    index[node.id] = i
  }
  for node in graph.nodes {
    let style = @svg.resolve_style(
      if node.css_styles.length() > 0 {
        node.css_compiled_styles + node.css_styles
      } else {
        node.css_compiled_styles
      },
    )
    let text_style = (if style.bold { @text.STYLE_BOLD } else { 0 }) |
      (if style.italic { @text.STYLE_ITALIC } else { 0 })
    let markdown = node.label_type is Markdown
    let font_size = style.font_size.unwrap_or(size)
    let (view, c) = if node.is_group {
      let label = @text.layout_label(
        node.label,
        markdown,
        measurer,
        font_size,
        4000,
        base=text_style,
      )
      let c = @layout.cnode(0, 0)
      c.is_group = true
      c.dir = match node.dir {
        Some(dir) if dir != "" => Some(@layout.direction(Some(dir)))
        _ => None
      }
      c.pad_x = GROUP_PAD
      c.pad_top = if label.height > 0 { label.height + 16 } else { GROUP_PAD }
      c.pad_bottom = GROUP_PAD
      c.min_w = label.width + 2 * GROUP_PAD - 12
      ({ node, style, label, shape: "group", w: 0, h: 0, dy: 0, }, c)
    } else if node.shape == "collapsedGroup" {
      let label = @text.layout_label(
        node.label,
        markdown,
        measurer,
        font_size,
        wrap_width,
        base=text_style,
      )
      let w = @util.js_max(label.width, min_width) + 2 * @svg.PAD_X
      let h = label.height + 2 * @svg.PAD_Y + DOTS
      (
        { node, style, label, shape: COLLAPSED, w, h, dy: -DOTS / 2, },
        @layout.cnode(w, h),
      )
    } else {
      let shape = @flowchart.canonical_shape(Some(node.shape))
      let label = @text.layout_label(
        node.label,
        markdown,
        measurer,
        font_size,
        wrap_width,
        base=text_style,
      )
      // A diamond grows twice as fast as its label, so it keeps the label's own width.
      let s = @svg.shape_size(
        shape,
        if shape == "diam" {
          label.width
        } else {
          @util.js_max(label.width, min_width)
        },
        label.height,
      )
      (
        { node, style, label, shape, w: s.w, h: s.h, dy: s.dy, },
        @layout.cnode(s.w, s.h),
      )
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
  let root_dir = if turned {
    @layout.Dir::TB
  } else {
    @layout.direction(db.direction)
  }
  // The direction of the level a node sits in.
  let flow_of = (i : Int32) => {
    let mut dir : @layout.Dir? = None
    let mut p = cnodes[i].parent
    let mut hops = 0
    while p >= 0 && dir is None && hops < 10000 {
      dir = cnodes[p].dir
      p = cnodes[p].parent
      hops += 1
    }
    dir.unwrap_or(root_dir)
  }
  let flows_sideways = (i : Int32) => flow_of(i) is (LR | RL)
  let depth : Array[Int32] = Array::make(cnodes.length(), -1)
  for i in 0..<cnodes.length() {
    let chain = []
    let mut j = i
    while j >= 0 && depth[j] < 0 && chain.length() <= cnodes.length() {
      chain.push(j)
      j = cnodes[j].parent
    }
    let mut d = if j >= 0 { depth[j] + 1 } else { 0 }
    for k = chain.length() - 1; k >= 0; k = k - 1 {
      depth[chain[k]] = d
      d += 1
    }
  }
  let contains = (group : Int32, i : Int32) => {
    let mut j = i
    let mut d = depth[i]
    while d > depth[group] {
      j = cnodes[j].parent
      d -= 1
    }
    j == group && i != group
  }
  let cedges : Array[@layout.CEdge] = []
  let edge_labels : Array[@text.Label] = []
  let drawn : Array[GraphEdge] = []
  // Edges between a node and a container around it have no place in the layout, so they are drawn afterwards, between the node and the container's border.
  let held : Array[Held] = []
  for edge in graph.edges {
    guard index.get(edge.start) is Some(src) && index.get(edge.end) is Some(dst) else {
      continue
    }
    let label = @text.layout_label(
      Some(edge.label),
      edge.label_type is Markdown,
      measurer,
      edge_size,
      wrap_width,
    )
    if contains(src, dst) || contains(dst, src) {
      held.push({ edge, label, src, dst, })
      continue
    }
    if src == dst {
      // A self-loop sits beside the node, across the flow, and the node's box grows to hold it.
      if flows_sideways(src) {
        cnodes[src].h += 2 *
          (LOOP + (if label.height > 0 { label.height + 8 } else { 0 }))
      } else {
        cnodes[src].w += 2 *
          (LOOP + (if label.width > 0 { label.width + 12 } else { 0 }))
      }
    }
    drawn.push(edge)
    edge_labels.push(label)
    cedges.push({
      src,
      dst,
      minlen: edge.minlen.unwrap_or(1),
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
  let layout = @layout.compound_layout(
    cnodes,
    cedges,
    root_dir,
    @layout.LayeredOptions::new(
      node_sep=@flowchart.number_option(section, "nodeSpacing", NODE_SEP),
      edge_sep=EDGE_SEP,
      rank_sep=@flowchart.number_option(section, "rankSpacing", RANK_SEP),
      port_sep=20,
    ),
  )
  let title = @svg.title_label(db.title, measurer, size, 4000)
  let title_height = if title.height > 0 { title.height + 12 } else { 0 }
  let inner = @util.js_max(layout.width, title.width)
  let ox = pad + (inner - layout.width) / 2
  let oy = pad + title_height
  @layout.shift_layout(cnodes, cedges, ox, oy)
  let width = (inner + 2 * pad).ceil()
  let height = (layout.height + title_height + 2 * pad).ceil()
  let links : Array[@types.LinkInfo] = []
  let held_paths = []
  let held_labels = []
  let held_routes = []
  let careful = held.length() * cnodes.length() < 2000000
  for h in held {
    // An edge between a node and a container around it runs straight between the node and the container's border: out along the flow, or in against it.
    // If another node is in the way it takes a side instead, and failing that the far end.
    let out = contains(h.dst, h.src)
    let outer = if out { h.dst } else { h.src }
    let i = if out { h.src } else { h.dst }
    let g = cnodes[outer]
    let n = cnodes[i]
    let end = flow_end(g.dir.unwrap_or(flow_of(outer)))
    let first = if out { end } else { (end + 2) & 3 }
    let toward = (side : Int32) => {
      let upright = (side & 1) == 0
      let sign = if side == 0 || side == 3 { -1.0 } else { 1.0 }
      let nx = if upright { n.x } else { n.x + sign * n.w / 2 }
      let ny = if upright { n.y + sign * n.h / 2 } else { n.y }
      let bx = if upright { n.x } else { g.x + sign * g.w / 2 }
      let by = if upright { g.y + sign * g.h / 2 } else { n.y }
      let axis = if upright { 0.0 } else { 1.0 }
      if out {
        [nx, ny, axis, bx, by, axis]
      } else {
        [bx, by, axis, nx, ny, axis]
      }
    }
    let blocked = (r : Array[Double]) => {
      for k, c in cnodes {
        if k != i &&
          !c.is_group &&
          c.x + c.w / 2 > @util.js_min(r[0], r[3]) - 1 &&
          c.x - c.w / 2 < @util.js_max(r[0], r[3]) + 1 &&
          c.y + c.h / 2 > @util.js_min(r[1], r[4]) - 1 &&
          c.y - c.h / 2 < @util.js_max(r[1], r[4]) + 1 {
          return true
        }
      }
      false
    }
    let mut route = toward(first)
    if careful && blocked(route) {
      for side in [(first + 1) & 3, (first + 3) & 3, (first + 2) & 3] {
        let other = toward(side)
        if !blocked(other) {
          route = other
          break
        }
      }
    }
    held_routes.push(route)
    held_labels.push(((route[0] + route[3]) / 2, (route[1] + route[4]) / 2))
    let drawn_route = route.copy()
    let view = views[i]
    @svg.inset_route(
      drawn_route,
      if out {
        0
      } else {
        3
      },
      n,
      shape=view.shape,
      w=view.w,
      h=view.h,
    )
    held_paths.push(
      @svg.route_path(
        drawn_route,
        Some("linear"),
        0,
        @svg.marker_trim(h.edge.arrow_type_end),
      ),
    )
  }
  let crossings = @svg.Crossings::new()
  if cnodes.iter().any(c => c.is_group) {
    for e in cedges {
      @svg.mark_crossings(crossings, e.route)
    }
    for route in held_routes {
      @svg.mark_crossings(crossings, route)
    }
  }
  let clusters = @svg.Markup::new()
  let nodes_out = @svg.Markup::new()
  for i, view in views {
    let c = cnodes[i]
    let node = view.node
    let classes = @svg.node_class_names(node.css_classes)
    let id = @svg.esc_text(node.id)
    let container_slot = node.color_index.unwrap_or(KIND_COUNT)
    if c.is_group {
      let title_x = @svg.cluster_title_x(
        c,
        view.label.width,
        crossings,
        GROUP_PAD,
      )
      clusters.write(
        "<g class=\"pele-cluster pele-flow\{classes}\" data-id=\"\{id}\">",
      )
      clusters.write(
        "<rect x=\"\{@svg.num(c.x - c.w / 2)}\" y=\"\{@svg.num(c.y - c.h / 2)}\" width=\"\{@svg.num(c.w)}\" height=\"\{@svg.num(c.h)}\"\{@svg.rounded(tint(container_slot, "0.06", view.style) + view.style.shape)}/>",
      )
      @svg.write_label(
        clusters,
        view.label,
        title_x,
        c.y - c.h / 2 + 8 + view.label.height / 2,
        " class=\"pele-cluster-label\" fill=\"var(--_m)\"\{view.style.text}",
        icons?=options.icons,
      )
      clusters.write("</g>")
      continue
    }
    let w = view.w
    let h = view.h
    let (shape, kind) = if view.shape == COLLAPSED {
      let color = @svg.series_color(container_slot)
      let line = h / 2 - DOTS - 2
      let dots = line + (DOTS + 2) / 2
      let frame = "<rect x=\"\{@svg.num(-w / 2)}\" y=\"\{@svg.num(-h / 2)}\" width=\"\{@svg.num(w)}\" height=\"\{@svg.num(h)}\"\{@svg.rounded(tint(container_slot, "0.06", view.style) + view.style.shape)}/>"
      let rule = "<path d=\"M\{@svg.num(-w / 2 + 10)},\{@svg.num(line)}H\{@svg.num(w / 2 - 10)}\" fill=\"none\" stroke=\"\{color}\" stroke-dasharray=\"3 3\"\{view.style.line}/>"
      let mark = "<path class=\"pele-collapsed-mark\" d=\"\{dot(-9, dots)}\{dot(0, dots)}\{dot(9, dots)}\" fill=\"\{color}\" stroke=\"none\"/>"
      (frame + rule + mark, "")
    } else {
      let kind = node.kind.unwrap_or("task")
      let slot = kind_slot(kind).unwrap_or(1)
      (
        @svg.draw_shape(
          view.shape,
          w,
          h,
          tint(slot, "0.14", view.style) + view.style.shape,
          " stroke=\"\{@svg.series_color(slot)}\"" + view.style.line,
        ),
        " pele-kind-\{kind}",
      )
    }
    let text = @svg.Markup::new()
    @svg.write_label(
      text,
      view.label,
      0,
      view.dy,
      " class=\"pele-label\"\{view.style.text}",
      icons?=options.icons,
    )
    let body = @svg.Markup::new()
    if node.tooltip is Some(tooltip) && tooltip != "" {
      body.write("<title>\{@svg.esc_text(tooltip)}</title>")
    }
    body.write(shape)
    if (classes + " ").contains(" internal-link ") &&
      node.label is Some(note) &&
      note != "" &&
      options.links != Some(false) {
      // The label is a note name, but it still ends up in an href, so it gets the same check as a URL.
      let name = @text.decode_entities(note)
      let target = @svg.esc(name)
      let href = if @url.link_url(@url.sanitize_url(name), options) is Some(_) {
        " href=\"\{target}\"\{@url.rel_attr(options)}"
      } else {
        ""
      }
      body.write_group(
        "<a class=\"internal-link\"\{href} data-href=\"\{target}\">",
        text,
        "</a>",
      )
      links.push({ id: node.id, href: name, internal: true, })
    } else {
      body.write_markup(text)
    }
    let link_start = match node.link {
      Some(link) if link != "" => {
        let attrs = match node.link_target {
          Some(target) if target != "" => " target=\"\{@svg.esc(target)}\""
          _ => ""
        }
        @url.link_start(link, node.id, links, options, attrs~)
      }
      _ => None
    }
    nodes_out.write(
      "<g class=\"pele-node pele-shape-\{view.shape}\{kind}\{classes}\" data-id=\"\{id}\" transform=\"translate(\{@svg.num(c.x)},\{@svg.num(c.y)})\">",
    )
    match link_start {
      Some(start) => nodes_out.write_group(start, body, "</a>")
      None => nodes_out.write_markup(body)
    }
    nodes_out.write("</g>")
  }
  let edges_out = @svg.Markup::new()
  let labels_out = @svg.Markup::new()
  let put = (
    edge : GraphEdge,
    label : @text.Label,
    path : @svg.EdgePath,
    x : Double,
    y : Double,
  ) => {
    let style = if edge.style.length() > 0 ||
      edge.css_compiled_styles.length() > 0 {
      Some(@svg.resolve_style(edge.css_compiled_styles + edge.style))
    } else {
      None
    }
    let end_type = edge.arrow_type_end
    let color = match style {
      Some({ stroke: Some(stroke), .. }) if stroke != "" => @svg.esc(stroke)
      _ => "var(--_l)"
    }
    let dotted = edge.thickness is Some("dotted")
    let kind = if dotted {
      "reference"
    } else if end_type == "arrow_cross" {
      "failure"
    } else {
      "sequence"
    }
    let line = match style {
      Some(style) => style.line
      None => ""
    }
    edges_out.write(
      "<g class=\"pele-edge pele-edge-\{kind}\{@flowchart.edge_classes(edge.classes)}\" data-id=\"\{@svg.esc_text(edge.id)}\"\{line}>",
    )
    edges_out.write(
      "<path d=\"\{path.d}\"\{if dotted { " stroke-dasharray=\"3 4\"" } else { "" }}/>",
    )
    edges_out.write(
      @svg.marker(end_type, path.ex, path.ey, path.edx, path.edy, color),
    )
    edges_out.write("</g>")
    if label.width > 0 {
      let text = match style {
        Some(style) => style.text
        None => ""
      }
      @svg.write_edge_label(
        labels_out,
        edge.id,
        label,
        x,
        y,
        text,
        icons?=options.icons,
      )
    }
  }
  let loop_seen : Map[Int32, Int32] = Map([])
  for i, ce in cedges {
    let edge = drawn[i]
    let end_type = edge.arrow_type_end
    let path = if ce.src == ce.dst {
      let view = views[ce.src]
      let k = loop_seen.get(ce.src).unwrap_or(0)
      loop_seen[ce.src] = k + 1
      @svg.loop_path(
        cnodes[ce.src],
        view.w,
        view.h,
        k,
        flows_sideways(ce.src),
        LOOP,
        @svg.marker_trim(end_type),
        ce,
      )
    } else {
      let route = ce.route.copy()
      let from = views[ce.src]
      let to = views[ce.dst]
      @svg.inset_route(
        route,
        0,
        cnodes[ce.src],
        shape=from.shape,
        w=from.w,
        h=from.h,
      )
      @svg.inset_route(
        route,
        route.length() - 3,
        cnodes[ce.dst],
        shape=to.shape,
        w=to.w,
        h=to.h,
      )
      let curve = match edge.curve {
        Some(String(name)) => Some(name)
        _ => None
      }
      @svg.route_path(route, curve, 0, @svg.marker_trim(end_type))
    }
    put(edge, edge_labels[i], path, ce.label_x, ce.label_y)
  }
  for i, h in held {
    let (x, y) = held_labels[i]
    put(h.edge, h.label, held_paths[i], x, y)
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
      "<g class=\"pele-edge-labels\" font-size=\"\{edge_size}\">",
      labels_out,
      "</g>",
    )
  }
  content.write_group("<g class=\"pele-nodes\">", nodes_out, "</g>")
  let svg = @svg.markup_document(
    "agentflow",
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
