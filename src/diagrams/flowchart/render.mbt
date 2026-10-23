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
const SHAPE_ATTRS : String = " fill=\"var(--_s)\" stroke=\"var(--_b)\""

///|
const LINE_ATTRS : String = " stroke=\"var(--_b)\""

///|
/// A positive number set under `key`, capped at 2000, or `fallback`.
pub fn number_option(
  section : Map[String, Json],
  key : String,
  fallback : Double,
) -> Double {
  match section.get(key) {
    Some(Number(value, ..)) if value > 0 => @util.js_min(value, 2000)
    _ => fallback
  }
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
/// Draws a flowchart, turned to run down when a narrow host needs it and drawn tightly when it does not fit.
pub fn render_flowchart(
  db : FlowDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered {
  let fitted = (down : Bool) => {
    @common.tighten(options, tight => draw(db, config, options, down, tight))
  }
  if @common.runs_across(db.direction) {
    @common.turn_to_fit(options, fitted)
  } else {
    fitted(false)
  }
}

///|
fn flow_section(config : @types.Config) -> Map[String, Json] {
  match config.get("flowchart") {
    Some(Object(section)) => section
    _ => {}
  }
}

///|
/// The edge's classes without the three that every drawn edge carries.
pub fn edge_classes(classes : String) -> String {
  // The graph gives an edge these three classes or none, so removing them one after another matches pele's single-pass regex.
  @svg.class_names(
    classes
    .replace_all(old="edge-thickness-normal", new="")
    .replace_all(old="edge-pattern-solid", new="")
    .replace_all(old="flowchart-link", new=""),
  )
}

///|
/// `turned` draws a flowchart that runs across as one that runs down; `tight` sets nodes closer together.
fn draw(
  db : FlowDb,
  config : @types.Config,
  options : @types.RenderOptions,
  turned : Bool,
  tight : Bool,
) -> @types.Rendered {
  let group_pad = if tight { 12.0 } else { GROUP_PAD }
  let flow = flow_section(config)
  let curve = match flow.get("curve") {
    Some(String(name)) => Some(name)
    _ => None
  }
  let graph = build_flow_graph(db, default_curve?=curve)
  let size = options.font_size.unwrap_or(16)
  let edge_size = (size * 0.875).round()
  let measurer = @text.metrics_measurer
  let wrap_width = number_option(flow, "wrappingWidth", 200)
  let pad = options.padding.unwrap_or(8)
  let index : Map[String, Int32] = Map([])
  let views : Array[NodeView] = []
  let cnodes : Array[@layout.CNode] = []
  for i, node in graph.nodes {
    index.set(node.id, i)
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
      c.pad_x = group_pad
      c.pad_top = if label.height > 0 { label.height + 16 } else { GROUP_PAD }
      c.pad_bottom = group_pad
      c.min_w = label.width + 2 * group_pad - 12
      ({ node, style, label, shape: "group", w: 0, h: 0, dy: 0, }, c)
    } else {
      let shape = canonical_shape(Some(node.shape))
      let text = if has_asset(node) || @svg.shape_has_label(shape) {
        node.label
      } else {
        None
      }
      let label = @text.layout_label(
        text,
        markdown,
        measurer,
        font_size,
        wrap_width,
        base=text_style,
      )
      let (w, h, dy) = if has_asset(node) {
        let box = if is_set(node.img) { 80.0 } else { 48.0 }
        let aw = asset_size(node.asset_width, box)
        let ah = asset_size(node.asset_height, box)
        let dy = if label.height == 0 {
          0.0
        } else if node.pos is Some("t") {
          -ah / 2
        } else {
          ah / 2
        }
        (
          @util.js_max(aw, label.width + 8),
          ah + (if label.height > 0 { label.height + 6 } else { 0 }),
          dy,
        )
      } else {
        let s = @svg.shape_size(shape, label.width, label.height)
        (s.w, s.h, s.dy)
      }
      ({ node, style, label, shape, w, h, dy, }, @layout.cnode(w, h))
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
  let flows_sideways = (i : Int32) => {
    let mut dir : @layout.Dir? = None
    let mut p = cnodes[i].parent
    let mut hops = 0
    while p >= 0 && dir is None && hops < 10000 {
      dir = cnodes[p].dir
      p = cnodes[p].parent
      hops += 1
    }
    dir.unwrap_or(root_dir) is (LR | RL)
  }
  // The edges on one side of a node spread along it; a picture or an icon keeps them at its middle.
  for i, view in views {
    if view.node.is_group {
      cnodes[i].span = @double.infinity
    } else if !has_asset(view.node) {
      cnodes[i].span = @svg.shape_span(
        view.shape,
        view.w,
        view.h,
        flows_sideways(i),
      )
    }
  }
  let cedges : Array[@layout.CEdge] = []
  let edge_labels : Array[@text.Label] = []
  let drawn : Array[GraphEdge] = []
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
    if src == dst {
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
  let layout_options = @layout.LayeredOptions::new(
    node_sep=number_option(flow, "nodeSpacing", NODE_SEP) *
      (if tight { 0.5 } else { 1 }),
    edge_sep=EDGE_SEP,
    rank_sep=number_option(flow, "rankSpacing", RANK_SEP) *
      (if tight { 0.75 } else { 1 }),
    port_sep=20,
    tracks=curve is Some(name) && name.has_prefix("step"),
    straight=curve is Some("linear"),
    head_room=@svg.marker_trim("arrow_point"),
  )
  let layout = @layout.compound_layout(cnodes, cedges, root_dir, layout_options)
  let title = @svg.title_label(
    db.title,
    measurer,
    size,
    if tight {
      @common.title_room(options)
    } else {
      4000
    },
  )
  let title_height = if title.height > 0 { title.height + 12 } else { 0 }
  let inner = @util.js_max(layout.width, title.width)
  let ox = pad + (inner - layout.width) / 2
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
  let clusters = StringBuilder()
  let struck_titles = StringBuilder()
  let nodes_out = StringBuilder()
  for i, view in views {
    let c = cnodes[i]
    let node = view.node
    let classes = @svg.node_class_names(node.css_classes)
    let id = @svg.esc_text(node.id)
    if c.is_group {
      let title_x = @svg.cluster_title_x(
        c,
        view.label.width,
        crossings,
        group_pad,
      )
      let title_y = c.y - c.h / 2 + 8 + view.label.height / 2
      let title_attrs = " class=\"pele-cluster-label\" fill=\"var(--_m)\"\{view.style.text}"
      let struck = @svg.title_crossed(c, view.label.width, title_x, crossings)
      if struck {
        struck_titles.write_string(
          @svg.struck_title(
            view.label,
            title_x,
            title_y,
            title_attrs,
            id,
            cnodes,
            i,
          ),
        )
      }
      clusters.write_string(
        "<g class=\"pele-cluster\{classes}\" data-id=\"\{id}\">",
      )
      clusters.write_string(
        "<rect x=\"\{@svg.num(c.x - c.w / 2)}\" y=\"\{@svg.num(c.y - c.h / 2)}\" width=\"\{@svg.num(c.w)}\" height=\"\{@svg.num(c.h)}\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\"\{@svg.rounded(view.style.shape)}/>",
      )
      if !struck {
        clusters.write_string(
          @svg.label_svg(view.label, title_x, title_y, title_attrs),
        )
      }
      clusters.write_string("</g>")
      continue
    }
    let inner = if node.img is Some(img) && img != "" {
      picture(node, img, view, options)
    } else if node.icon is Some(icon) && icon != "" {
      icon_svg(node, icon, view)
    } else {
      @svg.draw_shape(
        view.shape,
        view.w,
        view.h,
        SHAPE_ATTRS + view.style.shape,
        LINE_ATTRS + view.style.line,
      )
    }
    let mut text = @svg.label_svg(
      view.label,
      0,
      view.dy,
      " class=\"pele-label\"\{view.style.text}",
    )
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
      text = "<a class=\"internal-link\"\{href} data-href=\"\{target}\">\{text}</a>"
      links.push({ id: node.id, href: name, internal: true, })
    }
    let mut body = inner + text
    if node.tooltip is Some(tooltip) && tooltip != "" {
      body = "<title>\{@svg.esc_text(tooltip)}</title>" + body
    }
    if node.link is Some(link) && link != "" {
      let attrs = match node.link_target {
        Some(target) if target != "" => " target=\"\{@svg.esc(target)}\""
        _ => ""
      }
      body = @url.linked(body, link, node.id, links, options, attrs~)
    }
    nodes_out.write_string(
      "<g class=\"pele-node pele-shape-\{view.shape}\{classes}\" data-id=\"\{id}\" transform=\"translate(\{@svg.num(c.x)},\{@svg.num(c.y)})\">\{body}</g>",
    )
  }
  let reach = @svg.SideReach::new()
  for i, ce in cedges {
    if ce.src == ce.dst ||
      drawn[i].thickness == Some("invisible") ||
      ce.route.length() < 6 {
      continue
    }
    reach.add(
      ce.src,
      @svg.end_side(ce.route, 0, cnodes[ce.src]),
      drawn[i].arrow_type_start,
    )
    reach.add(
      ce.dst,
      @svg.end_side(ce.route, ce.route.length() - 3, cnodes[ce.dst]),
      drawn[i].arrow_type_end,
    )
  }
  let edges_out = StringBuilder()
  let labels_out = StringBuilder()
  let loop_seen : Map[Int32, Int32] = Map([])
  for i, ce in cedges {
    let edge = drawn[i]
    let label = edge_labels[i]
    let style = if edge.style.length() > 0 ||
      edge.css_compiled_styles.length() > 0 {
      Some(@svg.resolve_style(edge.css_compiled_styles + edge.style))
    } else {
      None
    }
    if edge.thickness != Some("invisible") {
      let start_type = edge.arrow_type_start
      let end_type = edge.arrow_type_end
      let path = if ce.src == ce.dst {
        let view = views[ce.src]
        let k = loop_seen.get(ce.src).unwrap_or(0)
        loop_seen.set(ce.src, k + 1)
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
        let leaves = reach.of(ce.src, @svg.end_side(route, 0, cnodes[ce.src]))
        let arrives = reach.of(
          ce.dst,
          @svg.end_side(route, route.length() - 3, cnodes[ce.dst]),
        )
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
        @svg.route_path(
          route,
          curve,
          @svg.marker_trim(start_type),
          @svg.marker_trim(end_type),
          start_reach=leaves,
          end_reach=arrives,
        )
      }
      let color = match style {
        Some({ stroke: Some(stroke), .. }) if stroke != "" => @svg.esc(stroke)
        _ => "var(--_l)"
      }
      let attrs = match edge.thickness {
        Some("thick") => " stroke-width=\"2.5\""
        Some("dotted") => " stroke-dasharray=\"3 4\""
        _ => ""
      }
      let line = match style {
        Some(style) => style.line
        None => ""
      }
      edges_out.write_string(
        "<g class=\"pele-edge\{edge_classes(edge.classes)}\" data-id=\"\{@svg.esc_text(edge.id)}\"\{line}>",
      )
      edges_out.write_string("<path d=\"\{path.d}\"\{attrs}/>")
      edges_out.write_string(
        @svg.marker(start_type, path.sx, path.sy, path.sdx, path.sdy, color),
      )
      edges_out.write_string(
        @svg.marker(end_type, path.ex, path.ey, path.edx, path.edy, color),
      )
      edges_out.write_string("</g>")
    }
    if label.width > 0 {
      let text = match style {
        Some(style) => style.text
        None => ""
      }
      labels_out.write_string(
        @svg.edge_label_svg(edge.id, label, ce.label_x, ce.label_y, text),
      )
    }
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
  let clusters_svg = clusters.to_string()
  if clusters_svg != "" {
    content.write_string("<g class=\"pele-clusters\">\{clusters_svg}</g>")
  }
  let edges_svg = edges_out.to_string()
  if edges_svg != "" {
    content.write_string(
      "<g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\">\{edges_svg}</g>",
    )
  }
  let struck_svg = struck_titles.to_string()
  if struck_svg != "" {
    content.write_string("<g class=\"pele-cluster-titles\">\{struck_svg}</g>")
  }
  let labels_svg = labels_out.to_string()
  if labels_svg != "" {
    content.write_string(
      "<g class=\"pele-edge-labels\" font-size=\"\{edge_size}\">\{labels_svg}</g>",
    )
  }
  content.write_string("<g class=\"pele-nodes\">\{nodes_out.to_string()}</g>")
  let svg = @svg.svg_document(
    "flowchart",
    width,
    height,
    size,
    options,
    db.acc_title,
    db.acc_descr,
    content.to_string(),
  )
  { svg, width, height, links, }
}
