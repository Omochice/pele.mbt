///|
const NODE_SEP : Double = 32

///|
const EDGE_SEP : Double = 16

///|
const RANK_SEP : Double = 72

///|
const GROUP_PAD : Double = 20

///|
const LOOP : Double = 26

///|
const FIGURE_W : Double = 40

///|
const FIGURE_H : Double = 60

///|
const FIGURE_GAP : Double = 6

///|
const TAB_PAD : Double = 6

///|
const CELL_PAD : Double = 10

///|
const ROW_PAD : Double = 8

///|
const FOLD : Double = 9

///|
const EXTENSION : Double = 12

///|
const PORT_GAP : Double = 14

///|
const SHAPE_ATTRS : String = " fill=\"var(--_s)\" stroke=\"var(--_b)\""

///|
priv enum Kind {
  Actor
  Ellipse
  Box
  Json
  Boundary
} derive(Eq)

///|
priv struct View {
  node : UsecaseGraphNode
  mut kind : Kind
  style : @svg.ResolvedStyle
  mut label : @text.Label
  stereotype : @text.Label
  /// The size of what is drawn; the layout box is larger when the node carries a self-relationship.
  mut w : Double
  mut h : Double
  rows : Array[(@text.Label, @text.Label)]
  mut key_w : Double
  mut head_h : Double
}

///|
fn number_option(
  config : @types.Config,
  key : String,
  fallback : Double,
) -> Double {
  match config.get("usecase") {
    Some(Object(section)) =>
      match section.get(key) {
        Some(Number(value, ..)) if value > 0 => @util.js_min(value, 2000)
        _ => fallback
      }
    _ => fallback
  }
}

///|
/// A plain label is shown as written: no tags, no markdown, no `\n` breaks.
/// Its markup characters are handed to the label parser as character references, which it turns back into characters.
fn literal(text : String) -> String {
  let out = StringBuilder()
  for i in 0..<text.length() {
    let c = @util.code_at(text, i)
    if c == 38 || c == 60 || c == 62 || c == 92 {
      out.write_string("&#\{c};")
    } else {
      @util.write_range(out, text, i, i + 1)
    }
  }
  out.to_string()
}

///|
fn text(
  raw : String?,
  markdown : Bool,
  measurer : @text.TextMeasurer,
  size : Double,
  wrap : Double,
  base~ : Int32 = 0,
) -> @text.Label {
  let shown = match raw {
    Some(text) if !markdown => Some(literal(text))
    _ => raw
  }
  @text.layout_label(shown, markdown, measurer, size, wrap, base~)
}

///|
/// The point of a node's outline on one of its four sides (0 top, 1 right, 2 bottom, 3 left), `along` away from the middle of that side.
/// Lines meet an actor at its figure, not at its label.
fn anchor(
  view : View,
  c : @layout.CNode,
  side : Int32,
  along : Double,
) -> (Double, Double) {
  let sign : Double = if side == 1 || side == 2 { 1 } else { -1 }
  let upright = side == 1 || side == 3
  let mut reach = (if upright { view.w } else { view.h }) / 2
  let mut middle = 0.0
  if view.kind == Actor {
    if upright {
      reach = FIGURE_W / 2 + 3
      middle = (FIGURE_H - view.h) / 2
    } else {
      reach += 2
    }
  } else if view.kind == Ellipse {
    let span = (if upright { view.h } else { view.w }) / 2
    let ratio = along / span
    reach *= @util.js_max(1 - ratio * ratio, 0).sqrt()
  }
  if upright {
    (c.x + sign * reach, c.y + middle + along)
  } else {
    (c.x + along, c.y + sign * reach)
  }
}

///|
/// How much of a side edges may spread over.
fn side_length(view : View, side : Int32) -> Double {
  let upright = side == 1 || side == 3
  if view.kind == Actor {
    return if upright { FIGURE_H * 0.5 } else { FIGURE_W * 0.6 }
  }
  let length = if upright { view.h } else { view.w }
  if view.kind == Ellipse {
    length * 0.6
  } else {
    length - 16
  }
}

///|
/// An end of an edge on a side of a node: where in its route it is, and how far along the side the
/// next point lies.
priv struct End {
  route : Array[Double]
  at : Int32
  toward : Double
}

///|
/// The layout brings every edge that ends on one side of a node to the middle of that side.
/// This spaces them along the side in the order they fan out, and puts each on the node's outline.
fn attach_ends(
  cedges : Array[@layout.CEdge],
  cnodes : Array[@layout.CNode],
  views : Array[View],
) -> Unit {
  let sides : Map[Int32, Array[End]] = Map([])
  let add = (index : Int32, route : Array[Double], at : Int32, next : Int32) => {
    let c = cnodes[index]
    if c.is_group {
      return
    }
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
    let end = {
      route,
      at,
      toward: route[next + (if (side & 1) != 0 { 1 } else { 0 })],
    }
    match sides.get(index * 4 + side) {
      Some(list) => list.push(end)
      None => sides.set(index * 4 + side, [end])
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
  for key, found in sides {
    let index = key >> 2
    let side = key & 3
    let view = views[index]
    let count = found.length()
    let step = if count > 1 {
      @util.js_min(PORT_GAP, side_length(view, side) / (count - 1).to_double())
    } else {
      0
    }
    let ends = stable_sorted(found, end => end.toward)
    for i, end in ends {
      let (x, y) = anchor(
        view,
        cnodes[index],
        side,
        (i.to_double() - (count - 1).to_double() / 2) * step,
      )
      end.route[end.at] = x
      end.route[end.at + 1] = y
    }
  }
}

///|
/// The hollow triangle of a generalization, with its tip at (x, y).
fn extension(
  x : Double,
  y : Double,
  dx : Double,
  dy : Double,
  color : String,
) -> String {
  let bx = x - dx * EXTENSION
  let by = y - dy * EXTENSION
  let half = EXTENSION * 0.5
  "<path class=\"pele-marker\" d=\"M\{@svg.num(x)},\{@svg.num(y)}L\{@svg.num(bx - dy * half)},\{@svg.num(by + dx * half)}L\{@svg.num(bx + dy * half)},\{@svg.num(by - dx * half)}Z\" fill=\"var(--_bg)\" stroke=\"\{color}\" stroke-linejoin=\"round\"/>"
}

///|
fn trim(kind : String) -> Double {
  if kind == "extension" {
    EXTENSION
  } else {
    @svg.marker_trim(kind)
  }
}

///|
fn mark(
  kind : String,
  x : Double,
  y : Double,
  dx : Double,
  dy : Double,
  color : String,
) -> String {
  if kind == "extension" {
    extension(x, y, dx, dy, color)
  } else {
    @svg.marker(kind, x, y, dx, dy, color)
  }
}

///|
/// The drawing of an actor, centered on its figure.
fn figure(view : View, icons : @types.IconResolver?) -> String {
  let node = view.node
  let shape = view.style.shape
  let line = " fill=\"none\" stroke=\"var(--_b)\"\{view.style.line}"
  let mut head = -21.0
  let mut radius = 9.0
  let out = match node.actor_type {
    Some("hollow") => {
      radius = 8
      "<circle cy=\"-21\" r=\"8\" fill=\"var(--_bg)\" stroke=\"var(--_b)\"\{shape}/>" +
      "<path d=\"M-20,-9H20V0H5.5L20,15.5L12,25.5L0,12L-12,25.5L-20,15.5L-5.5,0H-20Z\" fill=\"var(--_bg)\" stroke=\"var(--_b)\" stroke-linejoin=\"round\"\{shape}/>"
    }
    Some("awesome") =>
      "<path d=\"M0,-30A11,11 0 1 1 0,-8A11,11 0 1 1 0,-30ZM-20,25C-20,9 -12,-3 0,-3C12,-3 20,9 20,25C20,28 18,30 15,30H-15C-18,30 -20,28 -20,25Z\" fill=\"var(--_b)\"\{shape}/>"
    Some("icon") => {
      head = -14
      radius = 12
      "<rect x=\"-22\" y=\"-26\" width=\"44\" height=\"44\"\{@svg.rounded(SHAPE_ATTRS + shape)}/>" +
      @common.icon_svg(node.icon.unwrap_or(""), -14, -18, 28, icons?)
    }
    _ =>
      "<circle cy=\"-21\" r=\"9\"\{SHAPE_ATTRS}\{shape}/><path d=\"M0,-12V10M-14,-3H14M0,10L-12,30M0,10L12,30\"\{line}/>"
  }
  if node.business is Some(true) {
    // The slash of a business actor: a chord across the lower right of the head.
    return out +
      "<path class=\"pele-business\" d=\"M\{@svg.num(0.12 * radius)},\{@svg.num(head + 0.99 * radius)}L\{@svg.num(0.92 * radius)},\{@svg.num(head - 0.39 * radius)}\"\{line}/>"
  }
  out
}

///|
/// Draws a use case diagram, turned to run down when a narrow host needs it.
pub fn render_usecase(
  model : UsecaseModel,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered {
  if !@common.runs_across(Some(model.direction)) {
    return draw(model, config, options, false)
  }
  @common.turn_to_fit(options, down => draw(model, config, options, down))
}

///|
/// The class list after the leading `prefix` and the run of non-blank characters and the one blank
/// that follow it, as the patterns `^default\s?` and `^default relationship relationship-\S+\s?` strip.
fn strip_prefix(classes : String, prefix : String, word : Bool) -> String {
  if !@util.starts_with_at(classes, prefix, 0) {
    return classes
  }
  let mut at = prefix.length()
  if word {
    let start = at
    while at < classes.length() && !@util.is_space(@util.code_at(classes, at)) {
      at += 1
    }
    if at == start {
      return classes
    }
  }
  if @util.is_space(@util.code_at(classes, at)) {
    at += 1
  }
  @util.slice(classes, at)
}

///|
fn label_line(label : @text.Label, i : Int32) -> @text.Label {
  let width = label.widths[i]
  {
    lines: [label.lines[i]],
    widths: [width],
    width,
    height: label.line_height,
    size: label.size,
    line_height: label.line_height,
  }
}

///|
/// A label whose lines start at `x`, centered on `cy` as a whole.
fn left_label(
  label : @text.Label,
  x : Double,
  cy : Double,
  attrs : String,
  icons? : @types.IconResolver,
) -> String {
  if label.lines.length() < 2 {
    return @svg.label_svg(label, x + label.width / 2, cy, attrs, icons?)
  }
  let out = StringBuilder()
  for i in 0..<label.lines.length() {
    out.write_string(
      @svg.label_svg(
        label_line(label, i),
        x + label.widths[i] / 2,
        cy - label.height / 2 + (i.to_double() + 0.5) * label.line_height,
        attrs,
        icons?,
      ),
    )
  }
  out.to_string()
}

///|
/// A boundary's title sits in the middle of its top edge.
/// Where edges enter through that edge it moves into the stretch between them that is nearest the middle, or the widest if none has room.
fn title_x(
  c : @layout.CNode,
  width : Double,
  crossings : @svg.Crossings,
) -> Double {
  guard width != 0 && crossings.at(c.y - c.h / 2) is Some(xs) else {
    return c.x
  }
  let left = c.x - c.w / 2 + 6
  let right = c.x + c.w / 2 - 6
  let cuts = xs.filter(x => x > left && x < right)
  cuts.sort()
  cuts.push(right)
  let need = width / 2 + 6
  let mut best = c.x
  let mut best_off = @double.infinity
  let mut widest = 0.0
  let mut from = left
  for cut in cuts {
    if cut - from >= 2 * need {
      let x = @util.js_min(@util.js_max(c.x, from + need), cut - need)
      if (x - c.x).abs() < best_off {
        best_off = (x - c.x).abs()
        best = x
      }
    } else if best_off == @double.infinity && cut - from > widest {
      widest = cut - from
      best = (from + cut) / 2
    }
    from = cut
  }
  best
}

///|
/// Draws the diagram; `turned` draws one that runs across as one that runs down.
fn draw(
  model : UsecaseModel,
  config : @types.Config,
  options : @types.RenderOptions,
  turned : Bool,
) -> @types.Rendered {
  let graph = build_usecase_graph(model)
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.875).round()
  let tiny = (size * 0.8125).round()
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let root_dir = if turned {
    @layout.Dir::TB
  } else {
    @layout.direction(Some(model.direction))
  }
  let sideways = root_dir is (LR | RL)
  let index : Map[String, Int32] = Map([])
  for i, node in graph.nodes {
    index.set(node.id, i)
  }
  let views : Array[View] = []
  let cnodes : Array[@layout.CNode] = []
  for node in graph.nodes {
    let style = @svg.resolve_style(
      if node.css_styles.length() > 0 {
        node.css_compiled_styles + node.css_styles
      } else {
        node.css_compiled_styles
      },
    )
    let base = (if style.bold { @text.STYLE_BOLD } else { 0 }) |
      (if style.italic { @text.STYLE_ITALIC } else { 0 })
    let font_size = style.font_size.unwrap_or(size)
    let markdown = node.label_type == "markdown"
    let stereotype = text(
      node.stereotype.map(s => "«\{s}»"),
      false,
      measurer,
      tiny,
      200,
      base~,
    )
    let view = {
      node,
      kind: Box,
      style,
      label: stereotype,
      stereotype,
      w: 0,
      h: 0,
      rows: [],
      key_w: 0,
      head_h: 0,
    }
    let c = if node.is_group {
      view.kind = Boundary
      view.label = text(
        Some(node.label),
        markdown,
        measurer,
        font_size,
        4000,
        base~,
      )
      let title_h = view.label.height
      let c = @layout.cnode(0, 0)
      c.is_group = true
      c.pad_x = GROUP_PAD
      c.pad_bottom = GROUP_PAD
      c.pad_top = if node.boundary_type is Some("package") {
        title_h + 2 * TAB_PAD + 16
      } else if title_h > 0 {
        title_h + 16
      } else {
        GROUP_PAD
      }
      c.min_w = view.label.width + 2 * GROUP_PAD
      c
    } else {
      if node.json_rows is Some(rows) {
        view.kind = Json
        view.label = text(
          Some(node.label),
          false,
          measurer,
          font_size,
          4000,
          base=base | @text.STYLE_BOLD,
        )
        let mut value_w = 0.0
        for row in rows {
          let key = text(Some(row.key), false, measurer, small, 4000, base~)
          let value = text(Some(row.value), false, measurer, small, 260, base~)
          view.rows.push((key, value))
          view.key_w = @util.js_max(view.key_w, key.width)
          value_w = @util.js_max(value_w, value.width)
          view.h += @util.js_max(
              @util.js_max(key.height, value.height),
              (small * 1.5).round(),
            ) +
            ROW_PAD
        }
        // The root of an empty object has a value and no key, and then there is no key column.
        if view.key_w > 0 {
          view.key_w += 2 * CELL_PAD
        }
        view.head_h = @util.js_max(view.label.height, (font_size * 1.5).round()) +
          ROW_PAD
        view.w = @util.js_max(
          @util.js_max(
            view.label.width + 2 * CELL_PAD,
            if view.rows.length() > 0 {
              view.key_w + value_w + 2 * CELL_PAD
            } else {
              0
            },
          ),
          72,
        )
        view.h += view.head_h
      } else if node.actor_type is Some(_) {
        view.kind = Actor
        view.label = text(
          Some(node.label),
          markdown,
          measurer,
          font_size,
          140,
          base~,
        )
        view.w = @util.js_max(
          @util.js_max(FIGURE_W, view.label.width),
          stereotype.width,
        )
        view.h = FIGURE_H + FIGURE_GAP + stereotype.height + view.label.height
      } else {
        view.label = text(
          Some(node.label),
          markdown,
          measurer,
          if node.shape == "note" {
            small
          } else {
            font_size
          },
          180,
          base~,
        )
        let tw = @util.js_max(view.label.width, stereotype.width)
        let th = view.label.height + stereotype.height
        if node.shape == "usecaseEllipse" || node.shape == "usecaseBusiness" {
          view.kind = Ellipse
          // An oval needs more room around its text than a box, and a business oval room for its slash.
          view.w = @util.js_max(
            tw +
            2 * node.padding +
            (if node.business is Some(true) { 16 } else { 4 }),
            88,
          )
          view.h = @util.js_max(th + 28, 48)
        } else if node.shape == "note" {
          view.w = tw + 2 * node.padding + 6
          view.h = th + 18
        } else {
          view.w = @util.js_max(tw + 2 * node.padding + 12, 80)
          view.h = @util.js_max(th + 24, 44)
        }
      }
      @layout.cnode(view.w, view.h)
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
  let cedges : Array[@layout.CEdge] = []
  let edge_labels : Array[@text.Label] = []
  let drawn : Array[UsecaseGraphEdge] = []
  for edge in graph.edges {
    guard index.get(edge.start) is Some(src) && index.get(edge.end) is Some(dst) else {
      continue
    }
    let semantic = edge.relationship_type == "include" ||
      edge.relationship_type == "extend"
    let label = text(
      if semantic {
        edge.label.map(name => "«\{name}»")
      } else {
        edge.label
      },
      edge.label_type is Some("markdown"),
      measurer,
      small,
      200,
    )
    if src == dst {
      // A self-relationship loops out across the flow, and the node's box grows to hold it.
      if sideways {
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
      minlen: edge.minlen,
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
      node_sep=number_option(config, "nodeSpacing", NODE_SEP),
      edge_sep=EDGE_SEP,
      rank_sep=number_option(config, "rankSpacing", RANK_SEP),
      port_sep=20,
    ),
  )
  let title = @svg.title_label(model.title, measurer, size, 4000)
  let title_height = if title.height > 0 { title.height + 12 } else { 0 }
  let inner = @util.js_max(layout.width, title.width)
  let ox = pad + (inner - layout.width) / 2
  let oy = pad + title_height
  @layout.shift_layout(cnodes, cedges, ox, oy)
  let width = (inner + 2 * pad).ceil()
  let height = (layout.height + title_height + 2 * pad).ceil()

  // Where edges cross each boundary's top border, so that a title can keep out of their way.
  let crossings = @svg.Crossings::new()
  for e in cedges {
    @svg.mark_crossings(crossings, e.route)
  }
  attach_ends(cedges, cnodes, views)
  let clusters = StringBuilder()
  let nodes_out = StringBuilder()
  for i, view in views {
    let c = cnodes[i]
    let node = view.node
    let classes = @svg.class_names(
      strip_prefix(node.css_classes, "default", false),
    )
    let id = @svg.esc_text(node.id)
    let text_attrs = view.style.text
    let shape = view.style.shape
    let w = view.w
    let h = view.h
    if view.kind == Boundary {
      let x = c.x - c.w / 2
      let y = c.y - c.h / 2
      let box = " fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\"\{shape}"
      let title_attrs = " class=\"pele-cluster-label\" fill=\"var(--_m)\"\{text_attrs}"
      let body = if node.boundary_type is Some("package") {
        let tab_w = @util.js_min(view.label.width + 2 * TAB_PAD + 8, c.w)
        let tab_h = view.label.height + 2 * TAB_PAD
        "<rect class=\"pele-boundary-tab\" x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y)}\" width=\"\{@svg.num(tab_w)}\" height=\"\{@svg.num(tab_h)}\"\{box}/>" +
        "<rect x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y + tab_h)}\" width=\"\{@svg.num(c.w)}\" height=\"\{@svg.num(c.h - tab_h)}\"\{box}/>" +
        @svg.label_svg(
          view.label,
          x + tab_w / 2,
          y + tab_h / 2,
          title_attrs,
          icons?=options.icons,
        )
      } else {
        "<rect x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y)}\" width=\"\{@svg.num(c.w)}\" height=\"\{@svg.num(c.h)}\"\{@svg.rounded(box)}/>" +
        @svg.label_svg(
          view.label,
          title_x(c, view.label.width, crossings),
          y + 8 + view.label.height / 2,
          title_attrs,
          icons?=options.icons,
        )
      }
      clusters.write_string(
        "<g class=\"pele-cluster pele-boundary\{classes}\" data-id=\"\{id}\">\{body}</g>",
      )
      continue
    }
    let (kind, body) = match view.kind {
      Actor => {
        let top = -h / 2
        let stereotype_y = top +
          FIGURE_H +
          FIGURE_GAP +
          view.stereotype.height / 2
        (
          "pele-actor",
          "<g class=\"pele-actor-figure\" transform=\"translate(0,\{@svg.num(top + FIGURE_H / 2)})\">\{figure(view, options.icons)}</g>" +
          @svg.label_svg(
            view.stereotype,
            0,
            stereotype_y,
            " class=\"pele-stereotype\" font-size=\"\{tiny}\" fill=\"var(--_m)\"",
            icons?=options.icons,
          ) +
          @svg.label_svg(
            view.label,
            0,
            h / 2 - view.label.height / 2,
            " class=\"pele-label\"\{text_attrs}",
            icons?=options.icons,
          ),
        )
      }
      Json => {
        let x0 = -w / 2
        let mut y = -h / 2 + view.head_h
        let cells = StringBuilder()
        let mut lines = "M\{@svg.num(x0)},\{@svg.num(y)}H\{@svg.num(x0 + w)}"
        if view.key_w > 0 {
          lines += "M\{@svg.num(x0 + view.key_w)},\{@svg.num(y)}V\{@svg.num(h / 2)}"
        }
        for row in view.rows {
          let (key, value) = row
          let row_h = @util.js_max(
              @util.js_max(key.height, value.height),
              (small * 1.5).round(),
            ) +
            ROW_PAD
          cells.write_string(
            @svg.label_svg(
              key,
              x0 + CELL_PAD + key.width / 2,
              y + row_h / 2,
              " class=\"pele-json-key\" fill=\"var(--_m)\"",
              icons?=options.icons,
            ),
          )
          cells.write_string(
            left_label(
              value,
              x0 + view.key_w + CELL_PAD,
              y + row_h / 2,
              " class=\"pele-json-value\"\{text_attrs}",
              icons?=options.icons,
            ),
          )
          y += row_h
        }
        (
          "pele-json",
          "<rect x=\"\{@svg.num(x0)}\" y=\"\{@svg.num(-h / 2)}\" width=\"\{@svg.num(w)}\" height=\"\{@svg.num(h)}\"\{@svg.rounded(SHAPE_ATTRS + shape)}/>" +
          "<path class=\"pele-json-lines\" d=\"\{lines}\" fill=\"none\" stroke=\"var(--_b)\"\{view.style.line}/>" +
          @svg.label_svg(
            view.label,
            0,
            -h / 2 + view.head_h / 2,
            " class=\"pele-label\" font-weight=\"var(--_hw)\"\{text_attrs}",
            icons?=options.icons,
          ) +
          "<g font-size=\"\{small}\">\{cells.to_string()}</g>",
        )
      }
      _ => {
        let note = node.shape == "note"
        let (kind, outline) = if view.kind == Ellipse {
          let mut outline = "<ellipse rx=\"\{@svg.num(w / 2)}\" ry=\"\{@svg.num(h / 2)}\"\{SHAPE_ATTRS}\{shape}/>"
          if node.business is Some(true) {
            // The slash of a business use case, cutting off the right end of the oval beside the text.
            let from = w / 2 - 15
            let to = w / 2 - 5
            let arc = (at : Double) => {
              let ratio = at / (w / 2)
              h / 2 * (1.0 - ratio * ratio).sqrt()
            }
            outline += "<path class=\"pele-business\" d=\"M\{@svg.num(from)},\{@svg.num(arc(from))}L\{@svg.num(to)},\{@svg.num(-arc(to))}\" fill=\"none\" stroke=\"var(--_b)\"\{view.style.line}/>"
          }
          ("pele-usecase", outline)
        } else if note {
          let r = w / 2
          let b = h / 2
          (
            "pele-note",
            "<path d=\"M\{@svg.num(-r)},\{@svg.num(-b)}H\{@svg.num(r - FOLD)}L\{@svg.num(r)},\{@svg.num(FOLD - b)}V\{@svg.num(b)}H\{@svg.num(-r)}Z\" fill=\"var(--_a)\" stroke=\"var(--_b)\" stroke-linejoin=\"round\"\{shape}/>" +
            "<path d=\"M\{@svg.num(r - FOLD)},\{@svg.num(-b)}V\{@svg.num(FOLD - b)}H\{@svg.num(r)}\" fill=\"none\" stroke=\"var(--_b)\" stroke-linejoin=\"round\"\{view.style.line}/>",
          )
        } else {
          (
            "pele-usecase",
            "<rect x=\"\{@svg.num(-w / 2)}\" y=\"\{@svg.num(-h / 2)}\" width=\"\{@svg.num(w)}\" height=\"\{@svg.num(h)}\"\{@svg.rounded(SHAPE_ATTRS + shape)}/>",
          )
        }
        let note_size = if note { " font-size=\"\{small}\"" } else { "" }
        (
          kind,
          outline +
          @svg.label_svg(
            view.stereotype,
            0,
            -view.label.height / 2,
            " class=\"pele-stereotype\" font-size=\"\{tiny}\" fill=\"var(--_m)\"",
            icons?=options.icons,
          ) +
          @svg.label_svg(
            view.label,
            0,
            view.stereotype.height / 2,
            " class=\"pele-label\"\{note_size}\{text_attrs}",
            icons?=options.icons,
          ),
        )
      }
    }
    nodes_out.write_string(
      "<g class=\"pele-node \{kind}\{classes}\" data-id=\"\{id}\" transform=\"translate(\{@svg.num(c.x)},\{@svg.num(c.y)})\">\{body}</g>",
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
    let start_type = edge.arrow_type_start
    let end_type = edge.arrow_type_end
    let path : @svg.EdgePath = if ce.src == ce.dst {
      let c = cnodes[ce.src]
      let view = views[ce.src]
      let k = loop_seen.get(ce.src).unwrap_or(0)
      loop_seen.set(ce.src, k + 1)
      let side = if sideways { 2 } else { 1 }
      let spread = @util.js_min(
        side_length(view, side) / 2,
        8 + k.to_double() * 6,
      )
      let reach = LOOP + k.to_double() * 8
      let (ax, ay) = anchor(view, c, side, -spread)
      let (bx, by) = anchor(view, c, side, spread)
      let hypot = @util.js_hypot(reach, spread)
      let len = if hypot == 0 || hypot.is_nan() { 1.0 } else { hypot }
      let ux = (if sideways { spread } else { reach }) / len
      let uy = (if sideways { reach } else { spread }) / len
      let st = trim(start_type)
      let et = trim(end_type)
      // Both ends leave the node leaning away from each other, and the curve joins them outside it.
      let out = (x : Double, y : Double, sign : Double, far : Double) => {
        let lean = sign * spread * (if far != 0 { 1 } else { 0 })
        if sideways {
          "\{@svg.num(x + lean)},\{@svg.num(y + far)}"
        } else {
          "\{@svg.num(x + far)},\{@svg.num(y + lean)}"
        }
      }
      let sx = if sideways { ax - ux * st } else { ax + ux * st }
      let sy = if sideways { ay + uy * st } else { ay - uy * st }
      let ex = bx + ux * et
      let ey = by + uy * et
      if sideways {
        ce.label_x = c.x
        ce.label_y = @util.js_max(ay, by) + reach * 0.75 + 6 + label.height / 2
      } else {
        ce.label_x = @util.js_max(ax, bx) + reach * 0.75 + 8 + label.width / 2
        ce.label_y = c.y
      }
      {
        d: "M\{@svg.num(sx)},\{@svg.num(sy)}C\{out(ax, ay, -1, reach)} \{out(bx, by, 1, reach)} \{@svg.num(ex)},\{@svg.num(ey)}",
        sx: ax,
        sy: ay,
        sdx: if sideways {
          ux
        } else {
          -ux
        },
        sdy: if sideways {
          -uy
        } else {
          uy
        },
        ex: bx,
        ey: by,
        edx: -ux,
        edy: -uy,
      }
    } else {
      if ce.route.length() < 6 {
        continue
      }
      @svg.route_path(ce.route, None, trim(start_type), trim(end_type))
    }
    let color = match style {
      Some({ stroke: Some(stroke), .. }) if stroke != "" => @svg.esc(stroke)
      _ => "var(--_l)"
    }
    // Mermaid animates these dashes.
    // A still picture keeps the dashes.
    let dashes = if edge.internal {
      " stroke-dasharray=\"2 3\""
    } else if edge.pattern == "dotted" {
      " stroke-dasharray=\"5 4\""
    } else if edge.animate {
      " stroke-dasharray=\"9 5\""
    } else {
      ""
    }
    let edge_classes = @svg.class_names(
      strip_prefix(edge.classes, "default relationship relationship-", true),
    )
    let line = match style {
      Some(resolved) => resolved.line
      None => ""
    }
    edges_out.write_string(
      "<g class=\"pele-edge pele-\{edge.relationship_type}\{edge_classes}\" data-id=\"\{@svg.esc_text(edge.id)}\"\{line}>" +
      "<path d=\"\{path.d}\"\{dashes}/>" +
      mark(start_type, path.sx, path.sy, path.sdx, path.sdy, color) +
      mark(end_type, path.ex, path.ey, path.edx, path.edy, color) +
      "</g>",
    )
    if label.width > 0 {
      let semantic = edge.relationship_type == "include" ||
        edge.relationship_type == "extend"
      let text_attrs = match style {
        Some(resolved) => resolved.text
        None => ""
      }
      labels_out.write_string(
        @svg.edge_label_svg(
          edge.id,
          label,
          ce.label_x,
          ce.label_y,
          (if semantic { " fill=\"var(--_m)\"" } else { "" }) + text_attrs,
          icons?=options.icons,
        ),
      )
    }
  }
  let clusters = clusters.to_string()
  let edges_out = edges_out.to_string()
  let labels_out = labels_out.to_string()
  let svg = @svg.svg_document(
    "usecase",
    width,
    height,
    size,
    options,
    Some(model.acc_title),
    Some(model.acc_descr),
    @svg.label_svg(
      title,
      width / 2,
      pad + title.height / 2,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
    ) +
    (if clusters != "" {
      "<g class=\"pele-clusters\">\{clusters}</g>"
    } else {
      ""
    }) +
    (if edges_out != "" {
      "<g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\">\{edges_out}</g>"
    } else {
      ""
    }) +
    (if labels_out != "" {
      "<g class=\"pele-edge-labels\" font-size=\"\{small}\">\{labels_out}</g>"
    } else {
      ""
    }) +
    "<g class=\"pele-nodes\">\{nodes_out.to_string()}</g>",
  )
  { svg, width, height, links: [], }
}
