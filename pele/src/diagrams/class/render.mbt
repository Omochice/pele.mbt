///|
const NODE_SEP : Double = 40

///|
const EDGE_SEP : Double = 16

///|
const RANK_SEP : Double = 56

///|
const GROUP_PAD : Double = 20

///|
const LOOP : Double = 26

///|
const PAD_X : Double = 12

///|
const TITLE_PAD : Double = 8

///|
const FONT_MONO : String = "var(--_fm)"

///|
const SECTION_PAD : Double = 6

///|
const EMPTY_SECTION : Double = 10

///|
const MIN_WIDTH : Double = 64

///|
const FOLD : Double = 8

///|
const LINE_COLOR : String = "var(--_l)"

///|
fn number_option(
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
/// A member as it is written in its class box.
priv struct Line {
  text : String
  width : Double
  classifier : String
}

///|
priv struct View {
  node : GraphNode
  style : @svg.RawStyle
  label : @text.Label
  mut w : Double
  mut h : Double
  annotations : Array[Annotation]
  attributes : Array[Line]
  methods : Array[Line]
  title_h : Double
  attributes_h : Double
  font_size : Double
}

///|
/// Where an edge meets the side of a class.
priv struct End {
  route : Array[Double]
  at : Int32
  toward : Double
  order : Int32
  room : Double
  side : Int32
  /// Whether the text of this end goes on the right of, or below, its line.
  after : Bool
}

///|
priv struct Card {
  text : String
  math : @text.Label?
  mut x : Double
  mut y : Double
  w : Double
  h : Double
  /// The node the card belongs to, which it stays beside when disconnected parts are moved.
  parent : Int32
}

///|
/// An annotation as it is written above a class name: literal text, or a label holding math.
priv enum Annotation {
  Literal(String)
  Typeset(@text.Label)
}

///|
fn member_line(
  item : ClassMember,
  measurer : @text.TextMeasurer,
  size : Double,
  mono : Bool,
) -> Line {
  let text = @util.trim(
    @text.decode_entities(item.display_details().display_text),
  )
  {
    text,
    width: measurer.width(
      text,
      size,
      (if item.classifier == "*" { @text.STYLE_ITALIC } else { 0 }) |
      (if mono { @text.STYLE_MONO } else { 0 }),
    ),
    classifier: item.classifier,
  }
}

///|
/// Whether the members of a class with `style` are measured and drawn in the monospace font.
fn mono_members(options : @types.RenderOptions, style : @svg.RawStyle) -> Bool {
  // A font the author names in a style or classDef is a choice about this class, so it outranks a diagram-wide option.
  options.monospaces("members") &&
  !@svg.sets_font_family(@svg.style_attribute(style.text))
}

///|
/// Draws a class diagram, turned to run down when a narrow host needs it and drawn tightly when it does not fit.
pub fn render_class(
  db : ClassDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  let fitted = (down : Bool) => {
    @common.tighten(options, tight => draw(db, config, options, down, tight))
  }
  if @common.runs_across(Some(db.direction)) {
    @common.turn_to_fit(options, fitted)
  } else {
    fitted(false)
  }
}

///|
/// Draws the diagram; `turned` draws one that runs across as one that runs down.
/// `tight` gives up the room that keeps a namespace's name clear of an edge coming in beside it.
fn draw(
  db : ClassDb,
  config : @types.Config,
  options : @types.RenderOptions,
  turned : Bool,
  tight : Bool,
) -> @types.Rendered raise @errors.PeleError {
  let conf : Map[String, Json] = match config.get("class") {
    Some(Object(section)) => section
    _ => {}
  }
  let graph = build_class_graph(
    db,
    hierarchical=!(conf.get("hierarchicalNamespaces") is Some(False)),
  )
  let hide_empty = conf.get("hideEmptyMembersBox") is Some(True)
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.875).round()
  let tiny = (size * 0.8).round()
  let tiny_height = (tiny * 1.4).round()
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  // Keep annotations and cardinalities literal unless math is typeset.
  let math_text = (raw : String, font_size : Double) => {
    guard raw.contains("$$") else { return None }
    let label = @text.layout_label(Some(raw), false, measurer, font_size, 4000)
    if label.lines.iter().any(@text.has_math) {
      Some(label)
    } else {
      None
    }
  }
  let card_width = (raw : String) => {
    if raw == "" {
      0.0
    } else {
      match math_text(raw, tiny) {
        Some(math) => math.width
        None => measurer.width(@text.decode_entities(raw), tiny, 0)
      }
    }
  }
  let root_dir : @layout.Dir = if turned {
    TB
  } else {
    @layout.direction(Some(db.direction))
  }
  let vertical = root_dir is (TB | BT)

  // A class may carry the declarations of many classDefs many times over.
  // Each distinct declaration is checked once, and only the last value of each property that has an effect is resolved.
  let effect : Map[String, String] = Map([])
  let from_defs : Map[String, Array[(String, String)]] = Map([])
  let kept : Map[String, String] = Map([])
  let keep = (decl : String) => {
    let prop = match effect.get(decl) {
      Some(known) => known
      None => {
        let one = @svg.resolve_raw_style([decl])
        let found = if one.shape == "" && one.text == "" {
          ""
        } else {
          @util.trim(@util.slice(decl, 0, end=@util.index_of(decl, ":"))).to_lower()
        }
        effect.set(decl, found)
        found
      }
    }
    if prop != "" {
      kept.set(prop, decl)
    }
  }
  let class_style = (cls : ClassNode) => {
    kept.clear()
    match from_defs.get(cls.css_classes) {
      Some(base) =>
        for entry in base {
          kept.set(entry.0, entry.1)
        }
      None => {
        for name in split_on(cls.css_classes, ' ') {
          if db.style_classes.get(name) is Some(def) {
            for s in def.styles {
              for part in split_on(s, ',') {
                keep(part)
              }
            }
          }
        }
        from_defs.set(cls.css_classes, kept.iter().collect())
      }
    }
    for s in cls.styles {
      keep(s)
    }
    @svg.resolve_raw_style(kept.values().collect())
  }
  let children = FixedArray::make(graph.nodes.length(), 0)
  for node in graph.nodes {
    if node.parent >= 0 {
      children[node.parent] += 1
    }
  }

  // Namespaces that an edge may cross into are made wide enough for the title to sit beside it.
  let crossed = FixedArray::make(graph.nodes.length(), false)
  for edge in graph.edges {
    if edge.source < 0 || edge.target < 0 {
      continue
    }
    let a = graph.nodes[edge.source].parent
    let b = graph.nodes[edge.target].parent
    if a == b {
      continue
    }
    for g = a; g >= 0 && !crossed[g]; g = graph.nodes[g].parent {
      crossed[g] = true
    }
    for g = b; g >= 0 && !crossed[g]; g = graph.nodes[g].parent {
      crossed[g] = true
    }
  }
  let base = (
    node : GraphNode,
    label : @text.Label,
    w : Double,
    h : Double,
    font_size : Double,
  ) => {
    node,
    style: @svg.resolve_raw_style([]),
    label,
    w,
    h,
    annotations: [],
    attributes: [],
    methods: [],
    title_h: 0,
    attributes_h: 0,
    font_size,
  }
  let class_view = (node : GraphNode, cls : ClassNode) => {
    let style = class_style(cls)
    let font_size = style.font_size.unwrap_or(size)
    let member_size = (font_size * 0.875).round()
    let line_height = (member_size * 1.5).round()
    // The generic type is escaped so that `<T>` is not read as a tag.
    let generic = if cls.generic_type != "" {
      "&lt;" +
      @common.parse_generic_types(cls.generic_type)
      .replace_all(old="<", new="&lt;")
      .replace_all(old=">", new="&gt;") +
      "&gt;"
    } else {
      ""
    }
    let label = @text.layout_label(
      Some(cls.label + generic),
      false,
      measurer,
      font_size,
      4000,
      base=@text.STYLE_BOLD |
        (if style.italic { @text.STYLE_ITALIC } else { 0 }),
    )
    let annotations = cls.annotations.map(a => {
      match math_text("«" + @util.trim(a) + "»", tiny) {
        Some(math) => Typeset(math)
        None => Literal("«" + @util.trim(@text.decode_entities(a)) + "»")
      }
    })
    let mono = mono_members(options, style)
    let attributes = cls.members.map(m => {
      member_line(m, measurer, member_size, mono)
    })
    let methods = cls.methods.map(m => {
      member_line(m, measurer, member_size, mono)
    })
    let mut inner = label.width
    let mut annotations_h = 0.0
    for a in annotations {
      match a {
        Literal(text) => {
          inner = @util.js_max(inner, measurer.width(text, tiny, 0))
          annotations_h += tiny_height
        }
        Typeset(math) => {
          inner = @util.js_max(inner, math.width)
          annotations_h += @util.js_max(tiny_height, math.height)
        }
      }
    }
    for line in attributes {
      inner = @util.js_max(inner, line.width)
    }
    for line in methods {
      inner = @util.js_max(inner, line.width)
    }
    let sections = !(hide_empty &&
      attributes.length() == 0 &&
      methods.length() == 0)
    let section = (count : Int32) => {
      if !sections {
        0.0
      } else if count > 0 {
        2.0 * SECTION_PAD + count.to_double() * line_height
      } else {
        EMPTY_SECTION
      }
    }
    let title_h = 2.0 * TITLE_PAD +
      annotations_h +
      @util.js_max(label.height, (font_size * 1.5).round())
    let attributes_h = section(attributes.length())
    {
      node,
      style,
      label,
      w: @util.js_max(inner + 2 * PAD_X, MIN_WIDTH),
      h: title_h + attributes_h + section(methods.length()),
      annotations,
      attributes,
      methods,
      title_h,
      attributes_h,
      font_size,
    }
  }
  let views : Array[View] = []
  let cnodes : Array[@layout.CNode] = []
  for i, node in graph.nodes {
    let (view, c) = if node.is_group {
      let label = @text.layout_label(
        Some(node.label),
        false,
        measurer,
        size,
        4000,
      )
      let view = base(node, label, 0, 0, size)
      if children[i] > 0 {
        let c = @layout.cnode(0, 0)
        c.is_group = true
        c.pad_x = GROUP_PAD
        c.pad_top = if label.height > 0 { label.height + 16 } else { GROUP_PAD }
        c.pad_bottom = GROUP_PAD
        c.min_w = label.width +
          2 * GROUP_PAD -
          12 +
          (if crossed[i] && !tight {
            @util.js_min(label.width + 24, 240)
          } else {
            0
          })
        (view, c)
      } else {
        view.w = @util.js_max(label.width + 2 * GROUP_PAD, 80)
        view.h = label.height + 2 * GROUP_PAD
        (view, @layout.cnode(view.w, view.h))
      }
    } else if node.class_node is Some(cls) {
      let view = class_view(node, cls)
      (view, @layout.cnode(view.w, view.h))
    } else if node.shape is NoteBox {
      let label = @text.layout_label(
        Some(node.label),
        true,
        measurer,
        small,
        260,
      )
      let view = base(
        node,
        label,
        @util.js_max(label.width + 2 * PAD_X, 40),
        label.height + 2 * TITLE_PAD,
        small,
      )
      (view, @layout.cnode(view.w, view.h))
    } else {
      let label = @text.layout_label(
        Some(node.label),
        false,
        measurer,
        small,
        200,
      )
      let view = base(
        node,
        label,
        @util.js_max(label.width, 12) + 4,
        @util.js_max(label.height, 12),
        small,
      )
      (view, @layout.cnode(view.w, view.h))
    }
    c.parent = node.parent
    c.seq = i.to_double()
    views.push(view)
    cnodes.push(c)
  }
  let cedges : Array[@layout.CEdge] = []
  let drawn : Array[GraphEdge] = []
  let edge_labels : Array[@text.Label] = []
  let start_room : Array[Double] = []
  let end_room : Array[Double] = []
  // Edges leave one side of a class and arrive at the other, so a class with many of them is widened until they, and the text at their ends, fit side by side.
  let crowd = FixedArray::make(views.length() * 4, 0.0)
  let meet = (item : Int32, slot : Int32, room : Double) => {
    crowd[item * 4 + slot] += 1
    if room > crowd[item * 4 + slot + 1] {
      crowd[item * 4 + slot + 1] = room
    }
  }
  for edge in graph.edges {
    if edge.source < 0 || edge.target < 0 {
      continue
    }
    let label = @text.layout_label(edge.label, true, measurer, small, 200)
    let start_w = card_width(edge.start_label_right)
    let end_w = card_width(edge.end_label_left)
    if edge.source == edge.target {
      cnodes[edge.source].w += 2 *
        (LOOP + (if label.width > 0 { label.width + 12 } else { 0 }))
    } else {
      meet(edge.source, 0, start_w)
      meet(edge.target, 2, end_w)
    }
    start_room.push(start_w)
    end_room.push(end_w)
    drawn.push(edge)
    edge_labels.push(label)
    cedges.push({
      src: edge.source,
      dst: edge.target,
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
  if vertical {
    for i, view in views {
      if view.node.class_node is None {
        continue
      }
      let mut need = 0.0
      for slot in [0, 2] {
        let count = crowd[i * 4 + slot]
        let room = crowd[i * 4 + slot + 1]
        if count > 1 {
          need = @util.js_max(
            need,
            (count - 1) * (if room > 0 { room + 24 } else { 14 }) + 24,
          )
        }
      }
      need = @util.js_min(need, 480)
      if need > view.w {
        cnodes[i].w += need - view.w
        view.w = need
      }
    }
  }
  let lettered = start_room.iter().any(w => w > 0) ||
    end_room.iter().any(w => w > 0)
  // Cardinalities at both ends of a vertical edge need room for their height between the ranks.
  let mut tall_cards = 0.0
  if vertical {
    let card_height = (raw : String) => {
      if raw == "" {
        0.0
      } else {
        @util.js_max(
          tiny_height,
          match math_text(raw, tiny) {
            Some(math) => math.height
            None => 0
          },
        )
      }
    }
    for edge in drawn {
      tall_cards = @util.js_max(
        tall_cards,
        card_height(edge.start_label_right) +
        card_height(edge.end_label_left) -
        2 * tiny_height,
      )
    }
  }
  let layout = @layout.compound_layout(
    cnodes,
    cedges,
    root_dir,
    @layout.LayeredOptions::new(
      node_sep=number_option(conf, "nodeSpacing", NODE_SEP),
      edge_sep=EDGE_SEP,
      rank_sep=number_option(
          conf,
          "rankSpacing",
          if lettered {
            RANK_SEP + 16
          } else {
            RANK_SEP
          },
        ) +
        tall_cards,
      port_sep=20,
      apart=true,
    ),
  )

  // Every edge reaches the middle of a side.
  // Where several share a side they are spread along it, in the order of where they come from.
  // An end with text runs straight for the length of the text, which sits beside it on the side the line then bends toward, away from the neighbors that bend the other way.
  // Neighbors are set apart far enough for the text between them.
  let sides : Map[Int32, Array[End]] = Map([])
  let attach = (
    ce : @layout.CEdge,
    at : Int32,
    item : Int32,
    room : Double,
    order : Int32,
  ) => {
    let route = ce.route
    let c = cnodes[item]
    let side = @svg.end_side(route, at, c)
    if side < 0 {
      return None
    }
    let slack = (c.w - views[item].w) / 2
    if side == 1 {
      route[at] -= slack
    } else if side == 3 {
      route[at] += slack
    }
    let across = side & 1
    let toward = route[(if at == 0 { 3 } else { at - 3 }) + across]
    let bend = toward - route[at + across]
    let end = {
      route,
      at,
      toward,
      order,
      room,
      side,
      after: if across == 1 {
        bend > 0
      } else {
        bend >= 0
      },
    }
    let key = item * 4 + side
    match sides.get(key) {
      Some(list) => list.push(end)
      None => sides.set(key, [end])
    }
    Some(end)
  }
  let starts : Array[End?] = []
  let ends : Array[End?] = []
  for i, ce in cedges {
    let routed = ce.src != ce.dst && ce.route.length() >= 6
    starts.push(
      if routed {
        attach(ce, 0, ce.src, start_room[i], i)
      } else {
        None
      },
    )
    ends.push(
      if routed {
        attach(ce, ce.route.length() - 3, ce.dst, end_room[i], i)
      } else {
        None
      },
    )
  }
  // Whether a point lies on the border of one of the namespaces around a class.
  let on_border = (item : Int32, x : Double, y : Double) => {
    let mut g = cnodes[item].parent
    let mut hops = 0
    while g >= 0 && hops < 10000 {
      let c = cnodes[g]
      let dx = (x - c.x).abs()
      let dy = (y - c.y).abs()
      if ((dy - c.h / 2).abs() < 0.5 && dx <= c.w / 2 + 0.5) ||
        ((dx - c.w / 2).abs() < 0.5 && dy <= c.h / 2 + 0.5) {
        return true
      }
      g = cnodes[g].parent
      hops += 1
    }
    false
  }
  let gaps : Array[Double] = []
  for key, list in sides {
    if list.length() < 2 {
      continue
    }
    let item = key >> 2
    let across = key & 1
    let length = if across == 1 { views[item].h } else { views[item].w }
    list.sort_by((a, b) => {
      let by_toward = a.toward.compare(b.toward)
      if by_toward != 0 {
        by_toward
      } else {
        a.order.compare(b.order)
      }
    })
    let mut total = 0.0
    for j = 0; j + 1 < list.length(); j = j + 1 {
      let a = list[j]
      let b = list[j + 1]
      let mut gap = if across == 1 { 20.0 } else { 24.0 }
      if a.room > 0 && a.after {
        gap += if across == 1 { tiny_height + 6 } else { a.room }
      }
      if b.room > 0 && !b.after {
        gap += if across == 1 { tiny_height + 6 } else { b.room }
      }
      if j < gaps.length() {
        gaps[j] = gap
      } else {
        gaps.push(gap)
      }
      total += gap
    }
    let scale = @util.js_min(1, (length - 24) / total)
    if scale <= 0 {
      continue
    }
    let mut pos = (if across == 1 { cnodes[item].y } else { cnodes[item].x }) -
      total * scale / 2
    for j, end in list {
      let route = end.route
      let at = end.at
      // An edge that crosses the border of the class's namespace close by runs straight to it: the point where it crosses moves into line with its end.
      let step = if at == 0 { 3 } else { -3 }
      let first = at + step
      let mut border = -1
      let mut k = first
      while k >= 0 &&
            k < route.length() &&
            (route[k + across] - route[first + across]).abs() < 0.5 {
        if on_border(item, route[k], route[k + 1]) {
          border = k
          break
        }
        k += step
      }
      if border >= 0 && (route[first + across] - pos).abs() <= 24 {
        let mut m = first
        while m != border + step {
          route[m + across] = pos
          m += step
        }
      }
      route[at + across] = pos
      if j + 1 < list.length() {
        pos += gaps[j] * scale
      }
    }
  }
  let straighten = (
    route : Array[Double],
    end : End?,
    room : Double,
    first : Bool,
  ) => {
    guard end is Some(end) && room > 0 else { return }
    let across = end.side & 1
    let at = if first { 0 } else { route.length() - 3 }
    let along = at + 1 - across
    let reach = (route[(if first { 3 } else { at - 3 }) + 1 - across] -
    route[along]).abs()
    let length = @util.js_min(
      if across == 1 {
        room + 10
      } else {
        tiny_height + 6
      },
      reach * 0.35,
    )
    if length < 4 {
      return
    }
    let point = [route[at], route[at + 1], route[at + 2]]
    point[1 - across] += (if end.side == 0 || end.side == 3 {
        -1.0
      } else {
        1.0
      }) *
      length
    let into = if first { 3 } else { at }
    route.insert(into, point[2])
    route.insert(into, point[1])
    route.insert(into, point[0])
  }
  for i, ce in cedges {
    straighten(ce.route, starts[i], start_room[i], true)
    straighten(ce.route, ends[i], end_room[i], false)
  }
  let mut min_x = 0.0
  let mut min_y = 0.0
  let mut max_x = layout.width
  let mut max_y = layout.height
  let cards : Array[Card] = []
  let card = (
    parent : Int32,
    raw : String,
    width : Double,
    x : Double,
    y : Double,
    side : Int32,
    after : Bool,
  ) => {
    if raw == "" {
      return
    }
    let math = math_text(raw, tiny)
    let h = match math {
      Some(math) => @util.js_max(tiny_height, math.height)
      None => tiny_height
    }
    let mut cx = x
    let mut cy = y
    if (side & 1) == 1 {
      cx += (if side == 3 { -1.0 } else { 1.0 }) * (5 + width / 2)
      cy += (if after { 1.0 } else { -1.0 }) * (7 + h / 2)
    } else {
      cx += (if after { 1.0 } else { -1.0 }) * (9 + width / 2)
      cy += (if side == 0 { -1.0 } else { 1.0 }) * (3 + h / 2)
    }
    cards.push({
      text: @text.decode_entities(raw),
      math,
      x: cx,
      y: cy,
      w: width,
      h,
      parent,
    })
    min_x = @util.js_min(min_x, cx - width / 2)
    max_x = @util.js_max(max_x, cx + width / 2)
    min_y = @util.js_min(min_y, cy - h / 2)
    max_y = @util.js_max(max_y, cy + h / 2)
  }
  let loop_seen : Map[Int32, Int32] = Map([])
  let loop_at = FixedArray::make(cedges.length(), 0)
  for i, ce in cedges {
    let edge = drawn[i]
    let route = ce.route
    if ce.src == ce.dst {
      let k = loop_seen.get(ce.src).unwrap_or(0)
      loop_seen.set(ce.src, k + 1)
      loop_at[i] = k
      let c = cnodes[ce.src]
      let view = views[ce.src]
      let x = c.x + view.w / 2
      let spread = @util.js_min(view.h / 2 - 4, 8 + k.to_double() * 6)
      card(
        ce.src,
        edge.start_label_right,
        start_room[i],
        x,
        c.y - spread,
        1,
        false,
      )
      card(ce.dst, edge.end_label_left, end_room[i], x, c.y + spread, 1, true)
      ce.label_x = c.x +
        view.w / 2 +
        LOOP +
        k.to_double() * 8 +
        4 +
        ce.label_w / 2
      ce.label_y = c.y
    } else if route.length() >= 6 {
      let last = route.length() - 3
      let (from_side, from_after) = match starts[i] {
        Some(from) => (from.side, from.after)
        None => (2, true)
      }
      let (to_side, to_after) = match ends[i] {
        Some(to) => (to.side, to.after)
        None => (0, true)
      }
      card(
        ce.src,
        edge.start_label_right,
        start_room[i],
        route[0],
        route[1],
        from_side,
        from_after,
      )
      card(
        ce.dst,
        edge.end_label_left,
        end_room[i],
        route[last],
        route[last + 1],
        to_side,
        to_after,
      )
    }
  }
  if options.max_width is Some(available) &&
    available > 0 &&
    max_x - min_x + 2 * pad > available {
    let card_nodes = cards.map(item => {
      ..@layout.cnode(item.w, item.h, parent=item.parent),
      x: item.x,
      y: item.y,
    })
    let wrapped = @layout.wrap_components(
      cnodes + card_nodes,
      cedges,
      @util.js_max(1, available - 2 * pad),
      number_option(conf, "nodeSpacing", NODE_SEP),
    )
    if wrapped is Some(size) {
      for i, item in cards {
        item.x = card_nodes[i].x
        item.y = card_nodes[i].y
      }
      min_x = 0
      min_y = 0
      max_x = size.width
      max_y = size.height
    }
  }
  let ox = pad - min_x
  let oy = pad - min_y
  let width = (max_x - min_x + 2 * pad).ceil()
  let height = (max_y - min_y + 2 * pad).ceil()
  let links : Array[@types.LinkInfo] = []
  let crossings = @svg.Crossings::new()
  if graph.nodes.length() > 0 && graph.nodes[0].is_group {
    for e in cedges {
      @svg.mark_crossings(crossings, e.route)
    }
  }
  let num = @svg.num
  let clusters = @svg.Markup::new()
  let struck_titles = @svg.Markup::new()
  let nodes_out = @svg.Markup::new()
  for i, view in views {
    let c = cnodes[i]
    let node = view.node
    let x = c.x + ox
    let y = c.y + oy
    let w = if c.is_group { c.w } else { view.w }
    let h = if c.is_group { c.h } else { view.h }
    if node.is_group {
      let title_x = if c.is_group {
        @svg.cluster_title_x(c, view.label.width, crossings, GROUP_PAD)
      } else {
        c.x
      }
      let title_y = y - h / 2 + 8 + view.label.height / 2
      let title_attrs = " class=\"pele-cluster-label\" fill=\"var(--_m)\""
      let struck = c.is_group &&
        @svg.title_crossed(c, view.label.width, title_x, crossings)
      if struck {
        @svg.write_struck_title(
          struck_titles,
          view.label,
          title_x + ox,
          title_y,
          title_attrs,
          node.id,
          cnodes,
          i,
        )
      }
      clusters.write("<g class=\"pele-cluster pele-namespace\" data-id=\"")
      clusters.write_esc_text(node.id)
      clusters.write(
        "\"><rect x=\"\{num(x - w / 2)}\" y=\"\{num(y - h / 2)}\" width=\"\{num(w)}\" height=\"\{num(h)}\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\"\{@svg.ROUNDED}/>",
      )
      if !struck {
        @svg.write_label(
          clusters,
          view.label,
          title_x + ox,
          title_y,
          title_attrs,
        )
      }
      clusters.write("</g>")
      continue
    }
    let at = " transform=\"translate(\{num(x)},\{num(y)})\""
    if node.class_node is Some(cls) {
      write_class(
        nodes_out,
        view,
        cls,
        node.id,
        at,
        size,
        tiny,
        tiny_height,
        links,
        options,
      )
    } else if node.shape is NoteBox {
      let r = w / 2
      let t = -h / 2
      nodes_out.write("<g class=\"pele-node pele-note\" data-id=\"")
      nodes_out.write_esc_text(node.id)
      nodes_out.write(
        "\"\{at}><path d=\"M\{num(-r)},\{num(t)}H\{num(r - FOLD)}L\{num(r)},\{num(t + FOLD)}V\{num(-t)}H\{num(-r)}Z\" fill=\"var(--_a)\" stroke=\"var(--_b)\" stroke-linejoin=\"round\"/>" +
        "<path d=\"M\{num(r - FOLD)},\{num(t)}V\{num(t + FOLD)}H\{num(r)}\" fill=\"none\" stroke=\"var(--_b)\" stroke-linejoin=\"round\"/>",
      )
      @svg.write_label(
        nodes_out,
        view.label,
        0,
        0,
        " class=\"pele-label\" font-size=\"\{small}\"",
        icons?=options.icons,
      )
      nodes_out.write("</g>")
    } else {
      nodes_out.write("<g class=\"pele-node pele-interface\" data-id=\"")
      nodes_out.write_esc_text(node.id)
      nodes_out.write("\"\{at}>")
      @svg.write_label(
        nodes_out,
        view.label,
        0,
        0,
        " class=\"pele-label\" font-size=\"\{small}\"",
        icons?=options.icons,
      )
      nodes_out.write("</g>")
    }
  }
  let edges_out = @svg.Markup::new()
  let labels_out = @svg.Markup::new()
  for i, ce in cedges {
    let edge = drawn[i]
    let label = edge_labels[i]
    let start_type = edge.arrow_type_start
    let end_type = edge.arrow_type_end
    let start_trim = class_marker_trim(start_type)
    let end_trim = class_marker_trim(end_type)
    let path : @svg.EdgePath = if ce.src == ce.dst {
      let c = cnodes[ce.src]
      let view = views[ce.src]
      let k = loop_at[i].to_double()
      let x = c.x + ox + view.w / 2
      let y = c.y + oy
      let spread = @util.js_min(view.h / 2 - 4, 8 + k * 6)
      let reach = LOOP + k * 8
      {
        d: "M\{num(x + start_trim)},\{num(y - spread)}C\{num(x + reach + start_trim)},\{num(y - spread)} \{num(x + reach + end_trim)},\{num(y + spread)} \{num(x + end_trim)},\{num(y + spread)}",
        sx: x,
        sy: y - spread,
        sdx: -1,
        sdy: 0,
        ex: x,
        ey: y + spread,
        edx: -1,
        edy: 0,
      }
    } else {
      let route = ce.route
      for k = 0; k < route.length(); k = k + 3 {
        route[k] += ox
        route[k + 1] += oy
      }
      @svg.route_path(route, None, start_trim, end_trim)
    }
    let attrs = match edge.pattern {
      "dashed" => " stroke-dasharray=\"6 4\""
      "dotted" => " stroke-dasharray=\"2 4\""
      _ => ""
    }
    let kind = if edge.pattern == "dotted" {
      " pele-note-edge"
    } else {
      " pele-relation"
    }
    edges_out.write("<g class=\"pele-edge\{kind}\" data-id=\"")
    edges_out.write_esc_text(edge.id)
    edges_out.write(
      "\"><path d=\"\{path.d}\"\{attrs}/>" +
      class_marker(start_type, path.sx, path.sy, path.sdx, path.sdy, LINE_COLOR) +
      class_marker(end_type, path.ex, path.ey, path.edx, path.edy, LINE_COLOR) +
      "</g>",
    )
    if label.width > 0 {
      @svg.write_edge_label_with_id(
        labels_out,
        edge.id,
        label,
        ce.label_x + ox,
        ce.label_y + oy,
        "",
        icons?=options.icons,
      )
    }
  }
  let cards_out = @svg.Markup::new()
  for item in cards {
    match item.math {
      Some(math) =>
        @svg.write_label(
          cards_out,
          math,
          item.x + ox,
          item.y + oy,
          " class=\"pele-cardinality\"",
          icons?=options.icons,
        )
      None => {
        cards_out.write(
          "<text class=\"pele-cardinality\" x=\"\{num(item.x + ox)}\" y=\"\{num(item.y + oy + tiny * 0.35)}\" text-anchor=\"middle\">",
        )
        cards_out.write_esc(item.text)
        cards_out.write("</text>")
      }
    }
  }
  let content = @svg.Markup::new()
  if !clusters.is_empty() {
    content.write_group("<g class=\"pele-clusters\">", clusters, "</g>")
  }
  if !edges_out.is_empty() {
    content.write_group(
      "<g class=\"pele-edges\" fill=\"none\" stroke=\"\{LINE_COLOR}\" stroke-linecap=\"round\">",
      edges_out,
      "</g>",
    )
  }
  if !struck_titles.is_empty() {
    content.write_group(
      "<g class=\"pele-cluster-titles\">", struck_titles, "</g>",
    )
  }
  if !labels_out.is_empty() {
    content.write_group(
      "<g class=\"pele-edge-labels\" font-size=\"\{small}\">",
      labels_out,
      "</g>",
    )
  }
  if !cards_out.is_empty() {
    content.write_group(
      "<g class=\"pele-cardinalities\" font-size=\"\{tiny}\" fill=\"var(--_m)\">",
      cards_out,
      "</g>",
    )
  }
  content.write_group("<g class=\"pele-nodes\">", nodes_out, "</g>")
  let titled = @svg.with_title(
    db.title,
    measurer,
    size,
    pad,
    width,
    height,
    content,
  )
  let svg = @svg.markup_document(
    "class",
    titled.width,
    titled.height,
    size,
    options,
    db.acc_title,
    db.acc_descr,
    titled.content,
  )
  { svg, width: titled.width, height: titled.height, links, }
}

///|
/// The link targets a class may open its link in.
fn is_target(target : String) -> Bool {
  target is ("_self" | "_blank" | "_parent" | "_top")
}

///|
fn write_class(
  out : @svg.Markup,
  view : View,
  cls : ClassNode,
  node_id : String,
  at : String,
  size : Double,
  tiny : Double,
  tiny_height : Double,
  links : Array[@types.LinkInfo],
  options : @types.RenderOptions,
) -> Unit raise @errors.PeleError {
  let num = @svg.num
  let w = view.w
  let h = view.h
  let style = view.style
  let left = -w / 2
  let top = -h / 2
  let member_size = (view.font_size * 0.875).round()
  let line_height = (member_size * 1.5).round()
  let body = @svg.Markup::new()
  body.write(
    "<rect x=\"\{num(left)}\" y=\"\{num(top)}\" width=\"\{num(w)}\" height=\"\{num(h)}\" fill=\"var(--_s)\" stroke=\"var(--_b)\"",
  )
  @svg.write_rounded_style(body, style.shape)
  body.write("/>")
  let first = top + view.title_h
  let second = first + view.attributes_h
  if h > view.title_h {
    body.write(
      "<path class=\"pele-divider\" d=\"M\{num(left)},\{num(first)}H\{num(-left)}M\{num(left)},\{num(second)}H\{num(-left)}\" fill=\"none\" stroke=\"var(--_b)\"",
    )
    if style.stroke is Some(value) && value != "" {
      body.write(" style=\"stroke:")
      body.write_esc(value)
      body.write("\"")
    }
    body.write("/>")
  }
  let mut y = top + TITLE_PAD
  for annotation in view.annotations {
    match annotation {
      Literal(text) => {
        body.write(
          "<text class=\"pele-annotation\" x=\"0\" y=\"\{num(y + tiny_height / 2 + tiny * 0.35)}\" text-anchor=\"middle\" font-size=\"\{tiny}\" fill=\"var(--_m)\">",
        )
        body.write_esc(text)
        body.write("</text>")
        y += tiny_height
      }
      Typeset(math) => {
        let h = @util.js_max(tiny_height, math.height)
        @svg.write_label(
          body,
          math,
          0,
          y + h / 2,
          " class=\"pele-annotation\" font-size=\"\{tiny}\" fill=\"var(--_m)\"",
          icons?=options.icons,
        )
        y += h
      }
    }
  }
  let title_size = if view.font_size == size {
    ""
  } else {
    " font-size=\"\{num(view.font_size)}\""
  }
  @svg.write_label_styled(
    body,
    view.label,
    0,
    (y + first - TITLE_PAD) / 2,
    " class=\"pele-label\"\{title_size} font-weight=\"var(--_hw)\"",
    style.text,
    icons?=options.icons,
  )
  let lines = (list : Array[Line], kind : String, from : Double) => {
    let mut baseline = from + SECTION_PAD + line_height / 2 + member_size * 0.35
    for line in list {
      body.write("<text class=\"pele-member pele-\{kind}")
      match line.classifier {
        "$" =>
          if style.text != "" {
            body.write(" pele-static\" style=\"")
            body.write_esc(style.text)
            body.write("text-decoration:underline\"")
          } else {
            body.write(" pele-static\" style=\"text-decoration:underline\"")
          }
        "*" => {
          body.write(" pele-abstract\" font-style=\"italic\"")
          @svg.write_style(body, style.text)
        }
        _ => {
          body.write("\"")
          @svg.write_style(body, style.text)
        }
      }
      body.write(" x=\"\{num(left + PAD_X)}\" y=\"\{num(baseline)}\">")
      body.write_esc(line.text)
      body.write("</text>")
      baseline += line_height
    }
  }
  if view.attributes.length() > 0 || view.methods.length() > 0 {
    body.write("<g class=\"pele-members\" font-size=\"\{member_size}\"")
    if mono_members(options, style) {
      body.write(" font-family=\"\{FONT_MONO}\"")
    }
    body.write(">")
    lines(view.attributes, "attribute", first)
    lines(view.methods, "method", second)
    body.write("</g>")
  }
  out.write(
    "<g class=\"pele-node pele-class\{@svg.node_class_names(cls.css_classes)}\" data-id=\"",
  )
  out.write_esc_text(node_id)
  out.write("\"\{at}>")
  let linked = match cls.link {
    Some(href) if href != "" => {
      let target = match cls.link_target {
        Some(target) if is_target(target) => " target=\"\{target}\""
        _ => ""
      }
      @url.write_link_start(out, href, cls.id, links, options, attrs=target)
    }
    _ => false
  }
  if cls.tooltip is Some(tip) && tip != "" {
    out.write("<title>")
    out.write_esc_text(tip)
    out.write("</title>")
  }
  out.write_markup(body)
  if linked {
    out.write("</a>")
  }
  out.write("</g>")
}
