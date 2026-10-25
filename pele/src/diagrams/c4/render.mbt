///|
const PAIR_SHIFT : Double = 7

///|
const NARROW_GAP : Double = 36

///|
const WIDEN : Double = 24

///|
const MAX_OFFSET : Double = 2000

///|
/// A label may cover this much of a shape's edge, where there is no text.
const EDGE : Double = 8

///|
/// Places along a relation to try for its label, nearest the middle first.
let slide : Array[Double] = [0.5, 0.4, 0.6, 0.3, 0.7, 0.2, 0.8]

///|
/// Above this many box comparisons, labels stay at the middle and lines are not steered around shapes.
const CARE_BUDGET : Double = 2000000

///|
fn user_style(
  fill : String?,
  stroke : String?,
  color : String?,
) -> @svg.RawStyle {
  let declarations = []
  if fill is Some(f) && f != "" {
    declarations.push("fill:" + f)
  }
  if stroke is Some(s) && s != "" {
    declarations.push("stroke:" + s)
  }
  if color is Some(c) && c != "" {
    declarations.push("color:" + c)
  }
  @svg.resolve_raw_style(declarations)
}

///|
/// Entity encoding has hidden any `#name;` in an address; this puts it back, so that the check sees what a browser would.
fn unhide_entities(url : String) -> String {
  guard url.contains("\u{b6}\u{df}") else { return url }
  // The placeholders are those of the entity decoder: U+FB02 U+00B0, with an optional second U+00B0, stands for `#`,
  // and U+00B6 U+00DF for `;`.
  let out = StringBuilder()
  let n = url.length()
  let mut i = 0
  while i < n {
    let c = @util.code_at(url, i)
    if c == 0xfb02 && @util.code_at(url, i + 1) == 0xb0 {
      out.write_char('#')
      i += if @util.code_at(url, i + 2) == 0xb0 { 3 } else { 2 }
      continue
    }
    @util.write_range(out, url, i, i + 1)
    i += 1
  }
  out.to_string().replace_all(old="\u{b6}\u{df}", new=";")
}

///|
/// Writes `body` to `out`, in an anchor to `url` when there is one and the host allows it.
fn write_linked(
  out : @svg.Markup,
  body : @svg.Markup,
  url : String?,
  id : String,
  links : Array[@types.LinkInfo],
  options : @types.RenderOptions,
) -> Unit {
  let linked = match url {
    Some(url) if url != "" =>
      @url.write_link_start(
        out,
        @url.sanitize_url(unhide_entities(url)),
        id,
        links,
        options,
      )
    _ => false
  }
  out.write_markup(body)
  if linked {
    out.write("</a>")
  }
}

///|
/// Draws a C4 diagram, narrowed to the host's width when it allows that.
/// Raises when a relation names something that is not drawn, as Mermaid does.
pub fn render_c4(
  db : C4Db,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  ignore(config)
  let mut failure : @errors.PeleError? = None
  let blank : @types.Rendered = { svg: "", width: 0, height: 0, links: [], }
  let attempt = (tight : Bool, gap : Double) => {
    if failure is Some(_) {
      return (blank, 0)
    }
    draw(db, options, tight, gap) catch {
      error => {
        failure = Some(error)
        (blank, 0)
      }
    }
  }
  let rendered = @common.tighten(options, tight => {
    if !tight {
      return attempt(false, NARROW_GAP).0
    }
    let (first, first_left) = attempt(true, NARROW_GAP)
    let mut best = first
    let mut squeezed = first_left
    let mut gap = NARROW_GAP + WIDEN
    while squeezed > 0 && gap <= NARROW_GAP + 3 * WIDEN {
      let (wider, left) = attempt(true, gap)
      if left < squeezed {
        best = wider
        squeezed = left
      }
      gap += WIDEN
    }
    best
  })
  if failure is Some(error) {
    raise error
  }
  rendered
}

///|
fn draw(
  db : C4Db,
  options : @types.RenderOptions,
  tight : Bool,
  gap : Double,
) -> (@types.Rendered, Int32) raise @errors.PeleError {
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.8125).round()
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let links : Array[@types.LinkInfo] = []
  let room = if tight {
    Some(@util.js_max(80, options.max_width.unwrap_or(320) - 2 * pad))
  } else {
    None
  }
  let { order, boxes, } = layout_c4(db, measurer, size, small, room, gap)
  let root = order[0]
  let mut min_x = 0.0
  let mut min_y = 0.0
  let mut max_x = root.box.w
  let mut max_y = root.box.h
  let grow = (x0 : Double, y0 : Double, x1 : Double, y1 : Double) => {
    min_x = @util.js_min(min_x, x0)
    min_y = @util.js_min(min_y, y0)
    max_x = @util.js_max(max_x, x1)
    max_y = @util.js_max(max_y, y1)
  }
  let ends : Array[Box] = []
  let pairs : Map[Int32, Map[Int32, Bool]] = Map([])
  for rel in db.rels {
    let a = if rel.from_attr is Some(_) {
      None
    } else {
      db.get_c4_shape(rel.from).bind(el => boxes.get(el.id))
    }
    let b = if rel.to_attr is Some(_) {
      None
    } else {
      db.get_c4_shape(rel.to).bind(el => boxes.get(el.id))
    }
    guard a is Some(a) && b is Some(b) else {
      raise @errors.pele_error(
        "C4 rel \"\{rel.from}\" -> \"\{rel.to}\" references an unknown shape or boundary",
        code=Semantic,
        kind="c4",
      )
    }
    ends.push(a)
    ends.push(b)
    match pairs.get(a.id) {
      Some(targets) => targets[b.id] = true
      None => pairs[a.id] = Map([(b.id, true)])
    }
  }

  // What a relation's label should not cover: shapes, arrowheads, boundary headings, and the labels placed before it.
  let nodes : Array[Box] = []
  let taken : Array[Double] = []
  for group in order {
    for node in group.nodes {
      let n = node.box
      nodes.push(n)
      taken.push(n.x + EDGE)
      taken.push(n.y + EDGE)
      taken.push(n.x + n.w - EDGE)
      taken.push(n.y + n.h - EDGE)
    }
  }
  let rel_count = db.rels.length().to_double()
  let careful = rel_count *
    (nodes.length().to_double() + order.length().to_double() + 3 * rel_count) <=
    CARE_BUDGET
  let covered = (x0 : Double, y0 : Double, x1 : Double, y1 : Double) => {
    let mut area = 0.0
    for i = 0; i < taken.length(); i = i + 4 {
      let w = @util.js_min(x1, taken[i + 2]) - @util.js_max(x0, taken[i])
      if w <= 0 {
        continue
      }
      let h = @util.js_min(y1, taken[i + 3]) - @util.js_max(y0, taken[i + 1])
      if h > 0 {
        area += w * h
      }
    }
    area
  }
  let offset = (value : Double?) => {
    match value {
      Some(v) if v != 0 && !v.is_nan() =>
        @util.js_max(-MAX_OFFSET, @util.js_min(MAX_OFFSET, v))
      _ => 0
    }
  }
  let push_box = (x0 : Double, y0 : Double, x1 : Double, y1 : Double) => {
    taken.push(x0)
    taken.push(y0)
    taken.push(x1)
    taken.push(y1)
  }

  // Every line is drawn before any label is placed, so that labels can keep off the arrowheads.
  let edges_out = @svg.Markup::new()
  let trim = @svg.marker_trim("arrow_point")
  let lanes = Lanes::new()
  for i, group in order {
    if i > 0 {
      lanes.frame(group.box)
    }
  }
  let routes : Array[Route] = []
  for index, rel in db.rels {
    let a = ends[index * 2]
    let b = ends[index * 2 + 1]
    let style = user_style(None, rel.line_color, None)
    let write_marker = (x : Double, y : Double, dx : Double, dy : Double) => {
      match style.stroke {
        Some(stroke) if stroke != "" =>
          @svg.write_styled(
            edges_out,
            @svg.marker("arrow_point", x, y, dx, dy, @svg.STROKE_CSS),
            style,
          )
        _ =>
          edges_out.write(@svg.marker("arrow_point", x, y, dx, dy, "var(--_l)"))
      }
    }
    let start_arrow = rel.type_ == "birel" || rel.type_ == "rel_b"
    let end_arrow = rel.type_ != "rel_b"
    let reverse = a.id != b.id &&
      (match pairs.get(b.id) {
        Some(targets) => targets.contains(a.id)
        None => false
      })
    let r = route(
      a,
      b,
      if reverse {
        PAIR_SHIFT
      } else {
        0
      },
      if careful {
        Some(nodes)
      } else {
        None
      },
      lanes,
      if start_arrow {
        trim
      } else {
        0
      },
      if end_arrow {
        trim
      } else {
        0
      },
    )
    grow(
      @util.js_min(r.x0, r.x1),
      @util.js_min(r.y0, r.y1),
      @util.js_max(r.x0, r.x1),
      @util.js_max(r.y0, r.y1),
    )
    if start_arrow && careful {
      push_box(
        r.sx - @svg.ARROW,
        r.sy - @svg.ARROW,
        r.sx + @svg.ARROW,
        r.sy + @svg.ARROW,
      )
    }
    if end_arrow && careful {
      push_box(
        r.ex - @svg.ARROW,
        r.ey - @svg.ARROW,
        r.ex + @svg.ARROW,
        r.ey + @svg.ARROW,
      )
    }
    edges_out.write("<g class=\"pele-edge\" data-id=\"")
    edges_out.write_esc_text(rel.from + "-" + rel.to)
    edges_out.write("\"")
    @svg.write_style(edges_out, style.line)
    edges_out.write("><path d=\"\{r.d}\"/>")
    if start_arrow {
      write_marker(r.sx, r.sy, r.sdx, r.sdy)
    }
    if end_arrow {
      write_marker(r.ex, r.ey, r.edx, r.edy)
    }
    edges_out.write("</g>")
    routes.push(r)
  }

  // A boundary's heading goes at the left, the middle or the right of its top edge: the first of them no line crosses.
  for group in order {
    if !careful || group.head_w == 0 {
      continue
    }
    let g = group.box
    let top = g.y + HEAD_TOP
    let bottom = g.y + group.head - LANE
    let mut fewest = @double.infinity
    for
      x in [HEAD_LEFT, (g.w - group.head_w) / 2, g.w - HEAD_LEFT - group.head_w] {
      let mut count = 0
      for r in routes {
        if crosses(
            r.points,
            g.x + x - 4,
            top,
            g.x + x + group.head_w + 4,
            bottom,
          ) {
          count += 1
        }
      }
      if count.to_double() < fewest {
        fewest = count.to_double()
        group.head_x = x
      }
      if count == 0 {
        break
      }
    }
    push_box(
      g.x + group.head_x - 4,
      top,
      g.x + group.head_x + group.head_w + 4,
      bottom,
    )
  }
  let labels_out = @svg.Markup::new()
  for index, rel in db.rels {
    let r = routes[index]
    let id = rel.from + "-" + rel.to
    let style = user_style(None, None, rel.text_color)
    let text = (if db.c4_type == Some("C4Dynamic") {
        "\{index + 1}: "
      } else {
        ""
      }) +
      rel.label
    let label = @text.layout_label(Some(text), false, measurer, small, r.room)
    let techn = @text.layout_label(
      bracketed(rel.techn),
      false,
      measurer,
      small,
      r.room,
      base=@text.STYLE_ITALIC,
    )
    let lw = @util.js_max(label.width, techn.width) + LABEL_PAD
    let lh = label.height + techn.height
    if lh == 0 {
      continue
    }
    // The label sits on the line, or just beside it when another relation runs the opposite way.
    let beside = r.nx.abs() * (lw / 2) + r.ny.abs() * (lh / 2) + 2
    let aside = if r.lean != 0 && !r.lean.is_nan() {
      @util.js_max(0, @util.js_min(r.lean, beside - 14))
    } else {
      beside
    }
    // Manual offsets are tuned to the original spacing.
    // Compact labels are put back beside their routed arrows so that an offset cannot leave them floating outside a boundary.
    let mut dx = r.nx * aside + (if tight { 0 } else { offset(rel.offset_x) })
    let mut dy = r.ny * aside + (if tight { 0 } else { offset(rel.offset_y) })
    let mut at = 0.5
    if careful {
      // Slide along the line to the spot that covers least.
      // Offsets from the diagram are kept unless a spot on the line itself covers less than any they lead to:
      // they are often tuned for Mermaid's spacing.
      let mut least = @double.infinity
      let moved = dx != r.nx * aside || dy != r.ny * aside
      let passes = if moved { 2 } else { 1 }
      for pass = 0; pass < passes && least > 0; pass = pass + 1 {
        let px = if pass > 0 { r.nx * aside } else { dx }
        let py = if pass > 0 { r.ny * aside } else { dy }
        for t in slide {
          let cx = r.x0 + (r.x1 - r.x0) * t + px
          let cy = r.y0 + (r.y1 - r.y0) * t + py
          let area = covered(cx - lw / 2, cy - lh / 2, cx + lw / 2, cy + lh / 2)
          if area < least {
            least = area
            at = t
            dx = px
            dy = py
          }
          if area == 0 {
            break
          }
        }
      }
    }
    let cx = r.x0 + (r.x1 - r.x0) * at + dx
    let top = r.y0 + (r.y1 - r.y0) * at + dy - lh / 2
    if careful {
      push_box(cx - lw / 2, top, cx + lw / 2, top + lh)
    }
    grow(cx - lw / 2, top, cx + lw / 2, top + lh)
    labels_out.write("<g class=\"pele-edge-label\" data-id=\"")
    labels_out.write_esc_text(id)
    labels_out.write("\">")
    if rel.descr is Some(descr) && descr != "" {
      labels_out.write("<title>")
      labels_out.write_esc_text(descr)
      labels_out.write("</title>")
    }
    labels_out.write(
      "<rect x=\"\{@svg.num(cx - lw / 2)}\" y=\"\{@svg.num(top)}\" width=\"\{@svg.num(lw)}\" height=\"\{@svg.num(lh)}\" rx=\"3\" fill=\"var(--_bg)\"/>",
    )
    let text = @svg.Markup::new()
    @svg.write_label_styled(
      text,
      label,
      cx,
      top + label.height / 2,
      "",
      style.text,
    )
    @svg.write_label_styled(
      text,
      techn,
      cx,
      top + label.height + techn.height / 2,
      " class=\"pele-c4-techn\" fill=\"var(--_m)\"",
      style.text,
    )
    write_linked(labels_out, text, rel.link, id, links, options)
    labels_out.write("</g>")
  }
  let clusters = @svg.Markup::new()
  let nodes_out = @svg.Markup::new()
  for i, group in order {
    if i > 0 {
      let boundary = group.boundary
      let g = group.box
      let style = user_style(
        boundary.bg_color,
        boundary.border_color,
        boundary.font_color,
      )
      let x = g.x + group.head_x
      let mut y = g.y + HEAD_TOP
      let text = @svg.Markup::new()
      @common.write_left_label_styled(
        text,
        group.labels[0],
        x,
        y,
        " class=\"pele-cluster-label\" font-weight=\"var(--_hw)\"",
        style.text,
      )
      y += group.labels[0].height
      @common.write_left_label_styled(
        text,
        group.labels[1],
        x,
        y,
        " class=\"pele-c4-type\" font-size=\"\{small}\" fill=\"var(--_m)\"",
        style.text,
      )
      y += group.labels[1].height
      @common.write_left_label_styled(
        text,
        group.labels[2],
        x,
        y,
        " class=\"pele-c4-descr\" font-size=\"\{small}\" fill=\"var(--_m)\"",
        style.text,
      )
      let is_node = boundary.node_type is Some(_)
      clusters.write(
        "<g class=\"pele-cluster pele-c4-\{if is_node { "node" } else { "boundary" }}\" data-id=\"",
      )
      clusters.write_esc_text(boundary.alias_)
      clusters.write(
        "\"><rect x=\"\{@svg.num(g.x)}\" y=\"\{@svg.num(g.y)}\" width=\"\{@svg.num(g.w)}\" height=\"\{@svg.num(g.h)}\" fill=\"none\" stroke=\"var(--_b)\"\{if is_node { "" } else { " stroke-dasharray=\"6 4\"" }}",
      )
      @svg.write_rounded_style(clusters, style.shape)
      clusters.write("/>")
      write_linked(
        clusters,
        text,
        boundary.link,
        boundary.alias_,
        links,
        options,
      )
      clusters.write("</g>")
    }
    for node in group.nodes {
      let shape = node.shape
      let external = shape.kind.has_prefix("external")
      let style = user_style(
        shape.bg_color,
        shape.border_color,
        shape.font_color,
      )
      let stroke = " stroke=\"var(--_b)\"" +
        (if external { " stroke-dasharray=\"4 3\"" } else { "" })
      let { w, h, form, .. } = node.box
      let labels = node.labels
      let dx = if form == "h-cyl" { -queue_rx(h) / 2 } else { 0 }
      let dy = if form == "person" {
        HEAD / 2
      } else if form == "cyl" {
        cyl_ry(w) / 2
      } else {
        0
      }
      let mut y = dy - node.text_h / 2
      let fill = if external { "--_bg" } else { "--_s" }
      let body = @svg.Markup::new()
      let slots = style.slots()
      @svg.write_styled(
        body,
        @svg.draw_shape(
          form,
          w,
          h,
          " fill=\"var(\{fill})\"\{stroke}" + slots.shape,
          stroke + slots.line,
        ),
        style,
      )
      @svg.write_label_styled(
        body,
        labels[0],
        dx,
        y + labels[0].height / 2,
        " class=\"pele-c4-type\" font-size=\"\{small - 1}\" fill=\"var(--_m)\"",
        style.text,
      )
      y += labels[0].height
      @svg.write_label_styled(
        body,
        labels[1],
        dx,
        y + labels[1].height / 2,
        " class=\"pele-label\" font-weight=\"var(--_hw)\"",
        style.text,
      )
      y += labels[1].height
      @svg.write_label_styled(
        body,
        labels[2],
        dx,
        y + labels[2].height / 2,
        " class=\"pele-c4-techn\" font-size=\"\{small}\" fill=\"var(--_m)\"",
        style.text,
      )
      y += labels[2].height + 4
      @svg.write_label_styled(
        body,
        labels[3],
        dx,
        y + labels[3].height / 2,
        " class=\"pele-c4-descr\" font-size=\"\{small}\"",
        style.text,
      )
      nodes_out.write(
        "<g class=\"pele-node pele-shape-\{form} pele-c4-\{shape.kind}\{if external { " pele-c4-external" } else { "" }}\" data-id=\"",
      )
      nodes_out.write_esc_text(shape.alias_)
      nodes_out.write(
        "\" transform=\"translate(\{@svg.num(node.box.x + w / 2)},\{@svg.num(node.box.y + h / 2)})\">",
      )
      write_linked(nodes_out, body, shape.link, shape.alias_, links, options)
      nodes_out.write("</g>")
    }
  }
  let title = @text.layout_label(
    db.title,
    false,
    measurer,
    size,
    if tight {
      @common.title_room(options)
    } else {
      4000
    },
    base=@text.STYLE_BOLD,
  )
  let title_height = if title.height > 0 { title.height + 12 } else { 0 }
  let inner = @util.js_max(max_x - min_x, title.width)
  let width = (inner + 2 * pad).ceil()
  let height = (max_y - min_y + title_height + 2 * pad).ceil()
  let ox = pad - min_x + (inner - (max_x - min_x)) / 2
  let oy = pad + title_height - min_y
  let content = @svg.Markup::new()
  @svg.write_label(
    content,
    title,
    width / 2,
    pad + title.height / 2,
    " class=\"pele-title\" font-weight=\"var(--_tw)\"",
  )
  content.write("<g transform=\"translate(\{@svg.num(ox)},\{@svg.num(oy)})\">")
  if !clusters.is_empty() {
    content.write_group("<g class=\"pele-clusters\">", clusters, "</g>")
  }
  if !edges_out.is_empty() {
    content.write_group(
      "<g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\">",
      edges_out, "</g>",
    )
  }
  if !nodes_out.is_empty() {
    content.write_group("<g class=\"pele-nodes\">", nodes_out, "</g>")
  }
  if !labels_out.is_empty() {
    content.write_group(
      "<g class=\"pele-edge-labels\" font-size=\"\{small}\">",
      labels_out,
      "</g>",
    )
  }
  content.write("</g>")
  let svg = @svg.markup_document(
    "c4",
    width,
    height,
    size,
    options,
    None,
    db.acc_descr,
    content,
  )
  ({ svg, width, height, links, }, lanes.squeezed)
}
