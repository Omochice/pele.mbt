///|
const NODE_SEP : Double = 40

///|
const EDGE_SEP : Double = 16

///|
const RANK_SEP : Double = 44

///|
const GROUP_PAD : Double = 16

///|
const REGION_PAD : Double = 10

///|
const PAD_X : Double = 16

///|
const PAD_Y : Double = 10

///|
const LOOP : Double = 26

///|
const FOLD : Double = 8

///|
const NOTE_WRAP : Double = 320

///|
const CORNER : Double = 10

///|
const BAR : Double = 8

///|
const SURFACE : String = " fill=\"var(--_s)\" stroke=\"var(--_b)\""

///|
const RULE : String = " fill=\"none\" stroke=\"var(--_b)\""

// What a node is drawn as; the order matters, as kinds from K_REGION on are not drawn as nodes.

///|
const K_STATE : Int32 = 0

///|
const K_DESCRIBED : Int32 = 1

///|
const K_START : Int32 = 2

///|
const K_END : Int32 = 3

///|
const K_CHOICE : Int32 = 4

///|
const K_FORK : Int32 = 5

///|
const K_JOIN : Int32 = 6

///|
const K_NOTE : Int32 = 7

///|
const K_COMPOSITE : Int32 = 8

///|
const K_REGION : Int32 = 9

///|
const K_HIDDEN : Int32 = 10

///|
let kind_classes : Array[String] = [
  "pele-node pele-state", "pele-node pele-state", "pele-node pele-state-start", "pele-node pele-state-end",
  "pele-node pele-state-choice", "pele-node pele-state-fork", "pele-node pele-state-join",
  "pele-note", "pele-cluster pele-state-composite",
]

///|
/// The kind a node that is not a group is drawn as, from its shape.
fn kind_of_shape(shape : String?) -> Int32 {
  match shape {
    Some("rectWithTitle") => K_DESCRIBED
    Some("stateStart") => K_START
    Some("stateEnd") => K_END
    Some("choice") => K_CHOICE
    Some("fork") => K_FORK
    Some("join") => K_JOIN
    Some("note") => K_NOTE
    Some("divider") => K_HIDDEN
    _ => K_STATE
  }
}

///|
priv struct View {
  /// Absent for the unseen helpers the layout needs.
  node : StateNode?
  kind : Int32
  mut style : @svg.RawStyle?
  mut label : @text.Label
  lines : Array[@text.Label]
  mut w : Double
  mut h : Double
  mut title_h : Double
}

///|
fn vertical(dir : @layout.Dir?) -> Bool {
  dir is Some(TB | BT)
}

///|
fn number_option(
  config : @types.Config,
  key : String,
  fallback : Double,
) -> Double {
  match config.get("state") {
    Some(Object(section)) =>
      match section.get(key) {
        Some(Number(value, ..)) if value > 0 => @util.js_min(value, 2000)
        _ => fallback
      }
    _ => fallback
  }
}

///|
/// Mermaid keeps the quotes of a click statement's strings and strips them when it draws.
fn unquote(text : String) -> String {
  let mut from = 0
  let mut to = text.length()
  while from < to && @util.code_at(text, from) == 34 {
    from += 1
  }
  while to > from && @util.code_at(text, to - 1) == 34 {
    to -= 1
  }
  @util.slice(text, from, end=to)
}

///|
fn clamp(value : Double, min : Double, max : Double) -> Double {
  if value < min {
    min
  } else if value > max {
    max
  } else {
    value
  }
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
fn rect(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  rest : String,
) -> String {
  "<rect x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y)}\" width=\"\{@svg.num(w)}\" height=\"\{@svg.num(h)}\"\{rest}/>"
}

///|
/// Writes the rectangle `rect` draws with the `style` attribute of `css` after `rest`.
fn write_rect(
  out : @svg.Markup,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  rest : String,
  css : String,
) -> Unit {
  out.write(
    "<rect x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y)}\" width=\"\{@svg.num(w)}\" height=\"\{@svg.num(h)}\"\{rest}",
  )
  @svg.write_style(out, css)
  out.write("/>")
}

///|
fn group(
  dir : @layout.Dir,
  pad_x : Double,
  pad_top : Double,
  pad_bottom : Double,
) -> @layout.CNode {
  let c = @layout.cnode(0, 0)
  c.is_group = true
  c.dir = Some(dir)
  c.pad_x = pad_x
  c.pad_top = pad_top
  c.pad_bottom = pad_bottom
  c
}

///|
/// The class list without the classes Mermaid gives every state, cluster and note, as `/(?:^| )statediagram-(?:state|cluster-alt|cluster|note)(?= |$)/g` removes them.
fn strip_mermaid_classes(classes : String) -> String {
  let n = classes.length()
  let match_at = (p : Int32) => {
    let start = if p == 0 && @util.starts_with_at(classes, "statediagram-", 0) {
      13
    } else if @util.code_at(classes, p) == 32 &&
      @util.starts_with_at(classes, "statediagram-", p + 1) {
      p + 14
    } else {
      return -1
    }
    for name in ["state", "cluster-alt", "cluster", "note"] {
      let end = start + name.length()
      if @util.starts_with_at(classes, name, start) &&
        (end == n || @util.code_at(classes, end) == 32) {
        return end
      }
    }
    -1
  }
  let out = StringBuilder()
  let mut copied = 0
  let mut i = 0
  while i < n {
    let end = match_at(i)
    if end != -1 {
      @util.write_range(out, classes, copied, i)
      i = end
      copied = end
    } else {
      i += 1
    }
  }
  @util.write_range(out, classes, copied, n)
  out.to_string()
}

///|
/// Draws a state diagram, turned to run down when a narrow host needs it.
pub fn render_state(
  db : StateDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  if !@common.runs_across(Some(db.direction())) {
    return draw(db, config, options, false)
  }
  @common.turn_to_fit(options, down => draw(db, config, options, down))
}

///|
/// Draws the diagram; `turned` draws one that runs across as one that runs down.
fn draw(
  db : StateDb,
  config : @types.Config,
  options : @types.RenderOptions,
  turned : Bool,
) -> @types.Rendered raise @errors.PeleError {
  let graph = db.graph
  // State diagrams follow the flowchart curve.
  let curve = match config.get("flowchart") {
    Some(Object(flowchart)) =>
      match flowchart.get("curve") {
        Some(String(name)) => Some(name)
        _ => None
      }
    _ => None
  }
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.875).round()
  let measurer = options.text_measurer()
  let wrap_width = number_option(config, "wrappingWidth", 200)
  let pad = options.padding.unwrap_or(8)
  let root_dir : @layout.Dir = if turned {
    TB
  } else {
    @layout.direction(Some(db.direction()))
  }
  let no_label = @text.layout_label(None, false, measurer, size, 0)
  let text = (raw : String?, font_size : Double, wrap : Double, style : Int32) => {
    @text.layout_label(raw, true, measurer, font_size, wrap, base=style)
  }
  let index : Map[String, Int32] = Map([])
  let views : Array[View] = []
  let cnodes : Array[@layout.CNode] = []
  let add = (node : StateNode?, kind : Int32, c : @layout.CNode?) => {
    views.push({
      node,
      kind,
      style: None,
      label: no_label,
      lines: [],
      w: 0,
      h: 0,
      title_h: 0,
    })
    if c is Some(c) {
      cnodes.push(c)
    }
    views.length() - 1
  }
  for node in graph.nodes {
    if node.shape == Some("noteGroup") {
      continue
    }
    let kind = if node.is_group {
      if node.shape == Some("divider") {
        K_REGION
      } else {
        K_COMPOSITE
      }
    } else {
      kind_of_shape(node.shape)
    }
    index.set(node.id, add(Some(node), kind, None))
  }
  let states = views.length()
  let node_of = (i : Int32) => views[i].node.unwrap()
  let logical : Array[Int32] = []
  for i in 0..<states {
    let parent = match node_of(i).parent_id {
      Some(parent_id) => index.get(parent_id)
      None => None
    }
    logical.push(
      match parent {
        Some(parent) if parent != i && node_of(parent).is_group => parent
        _ => -1
      },
    )
  }
  // Composites that are redeclared inside each other form a ring with no way in from the root.
  // One member of each ring moves to the root, which leaves a tree.
  {
    let kids : Array[Array[Int32]] = Array::makei(states, _ => [])
    let queue : Array[Int32] = []
    let placed = FixedArray::make(states, false)
    for i in 0..<states {
      if logical[i] == -1 {
        placed[i] = true
        queue.push(i)
      } else {
        kids[logical[i]].push(i)
      }
    }
    let done = Ref(0)
    let settle = () => {
      while done.val < queue.length() {
        for kid in kids[queue[done.val]] {
          if placed[kid] {
            continue
          }
          placed[kid] = true
          queue.push(kid)
        }
        done.val += 1
      }
    }
    settle()
    let seen = FixedArray::make(states, -1)
    for i in 0..<states {
      if placed[i] {
        continue
      }
      let mut ring = i
      while seen[ring] != i {
        seen[ring] = i
        ring = logical[ring]
      }
      logical[ring] = -1
      placed[ring] = true
      queue.push(ring)
      settle()
    }
  }
  let owners = FixedArray::make(states, -1)
  for i in 0..<states {
    let owner = match node_of(i).note_for {
      Some(note_for) => index.get(note_for)
      None => None
    }
    guard owner is Some(owner) else { continue }
    owners[i] = owner
    logical[i] = logical[owner]
  }

  // As in Mermaid, a composite that sets no direction runs top to bottom whatever surrounds it.
  let inner_dir = (composite : Int32) => {
    @layout.direction(node_of(composite).dir)
  }
  // Whether the flow around a state runs top to bottom or bottom to top.
  let across = (i : Int32) => {
    vertical(
      Some(if logical[i] == -1 { root_dir } else { inner_dir(logical[i]) }),
    )
  }
  let degree = FixedArray::make(states, 0)
  let noted = FixedArray::make(states, false)
  // When each state first takes part in a transition.
  // Layout follows this order rather than the order of declaration, so a state declared up front does not become the top of the flow.
  let appear : Array[Double] = Array::make(states, @double.infinity)
  let mut appeared = 0.0
  let counts = FixedArray::make(2 * states, 0)
  for edge in graph.edges {
    guard index.get(edge.start) is Some(src) && index.get(edge.end) is Some(dst) else {
      continue
    }
    if edge.dashed {
      noted[if views[src].kind == K_NOTE { dst } else { src }] = true
      continue
    }
    counts[2 * src] += 1
    if counts[2 * src] > degree[src] {
      degree[src] = counts[2 * src]
    }
    counts[2 * dst + 1] += 1
    if counts[2 * dst + 1] > degree[dst] {
      degree[dst] = counts[2 * dst + 1]
    }
    if appear[src] == @double.infinity {
      appear[src] = appeared
      appeared += 1
    }
    if appear[dst] == @double.infinity {
      appear[dst] = appeared
      appeared += 1
    }
  }
  for i in 0..<states {
    let view = views[i]
    let node = node_of(i)
    let style = @svg.resolve_raw_style(
      if node.css_styles.length() > 0 {
        node.css_compiled_styles + node.css_styles
      } else {
        node.css_compiled_styles
      },
    )
    let text_style = (if style.bold { @text.STYLE_BOLD } else { 0 }) |
      (if style.italic { @text.STYLE_ITALIC } else { 0 })
    let font_size = style.font_size.unwrap_or(size)
    view.style = Some(style)
    let mut c : @layout.CNode? = None
    match view.kind {
      K_COMPOSITE => {
        view.label = text(node.label, font_size, 4000, text_style)
        view.title_h = if view.label.height > 0 {
          view.label.height + 12
        } else {
          0
        }
        let g = group(
          inner_dir(i),
          GROUP_PAD,
          view.title_h + GROUP_PAD,
          GROUP_PAD,
        )
        g.min_w = view.label.width + 2 * GROUP_PAD
        c = Some(g)
      }
      K_REGION =>
        c = Some(group(inner_dir(i), REGION_PAD, REGION_PAD, REGION_PAD))
      K_START => {
        view.w = 14
        view.h = 14
      }
      K_END => {
        view.w = 18
        view.h = 18
      }
      K_CHOICE => {
        view.w = 30
        view.h = 30
      }
      K_FORK | K_JOIN => {
        let length = clamp(40 * degree[i].to_double() + 16, 72, 320)
        view.w = if across(i) { length } else { BAR }
        view.h = if across(i) { BAR } else { length }
      }
      K_HIDDEN => ()
      K_NOTE => {
        view.label = text(
          node.label,
          small,
          @util.js_max(wrap_width, NOTE_WRAP),
          0,
        )
        view.w = view.label.width + 24
        view.h = view.label.height + 16
      }
      _ => {
        view.label = text(node.label, font_size, wrap_width, text_style)
        let mut width = view.label.width
        let mut height = view.label.height + 2 * PAD_Y
        if view.kind == K_DESCRIBED {
          height += 14
          for line in node.description {
            let label = text(
              Some(if line == "" { " " } else { line }),
              small,
              wrap_width,
              text_style,
            )
            view.lines.push(label)
            if label.width > width {
              width = label.width
            }
            height += label.height
          }
        }
        view.w = @util.js_max(width + 2 * PAD_X, 56)
        view.h = height
      }
    }
    let c = match c {
      Some(c) => c
      None => @layout.cnode(view.w, view.h)
    }
    // The transitions on one side of a state's box spread along it, clear of its corners.
    if view.kind == K_STATE || view.kind == K_DESCRIBED {
      c.span = (if across(i) { view.w } else { view.h }) - 24
    }
    cnodes.push(c)
  }
  let cedges : Array[@layout.CEdge] = []
  let edge_labels : Array[@text.Label] = []
  let drawn : Array[StateEdge] = []
  // The transitions each state makes to itself: how many, their widest label, and their labels' height.
  let loop_count = FixedArray::make(states, 0)
  let loop_width = FixedArray::make(states, 0.0)
  let loop_height = FixedArray::make(states, 0.0)
  // A transition between a composite and a state inside it runs between that state and a point just inside the composite, and is then drawn on to the composite's border.
  let anchors : Map[Int32, Int32] = Map([])
  let encloses = (composite : Int32, item : Int32) => {
    if !cnodes[composite].is_group {
      return false
    }
    let mut p = logical[item]
    while p != -1 {
      if p == composite {
        return true
      }
      p = logical[p]
    }
    false
  }
  let anchor = (composite : Int32, first : Bool) => {
    anchors.set(cedges.length(), composite)
    appear.push(if first { -1 } else { @double.infinity })
    add(None, K_HIDDEN, Some(@layout.cnode(0, 0, parent=composite)))
  }
  for edge in graph.edges {
    guard index.get(edge.start) is Some(src0) &&
      index.get(edge.end) is Some(dst0) else {
      continue
    }
    let mut src = src0
    let mut dst = dst0
    let label = text(Some(edge.label), small, wrap_width, 0)
    let label_w = if label.width > 0 { label.width + 12 } else { 0 }
    if src == dst {
      loop_count[src] += 1
      loop_width[src] = @util.js_max(loop_width[src], label_w)
      loop_height[src] += label.height
    } else if encloses(src, dst) {
      src = anchor(src, true)
    } else if encloses(dst, src) {
      dst = anchor(dst, false)
    }
    drawn.push(edge)
    edge_labels.push(label)
    cedges.push({
      src,
      dst,
      minlen: 1,
      label_w,
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

  // A state with notes, or a composite with self-transitions, sits in an unseen group of its own: the notes go beside the state, across the flow, without disturbing its transitions.
  for i in 0..<states {
    if owners[i] != -1 {
      continue
    }
    let item = cnodes[i]
    // Loops hang off the right, or below when the flow is horizontal, with their labels beyond them.
    let mut room = 0.0
    if loop_count[i] > 0 {
      let reach = LOOP + (loop_count[i] - 1).to_double() * 8
      room = if across(i) {
        reach + loop_width[i]
      } else {
        reach * 0.75 + 4 + loop_height[i]
      }
      if !item.is_group {
        if across(i) {
          item.w += 2 * room
          item.h = @util.js_max(item.h, loop_height[i])
        } else {
          item.h += 2 * room
          item.w = @util.js_max(item.w, loop_width[i])
        }
        room = 0
      }
    }
    if !noted[i] && room == 0 {
      item.parent = logical[i]
      continue
    }
    let c = if across(i) {
      group(LR, room, 0, 0)
    } else {
      group(TB, 0, room, room)
    }
    c.parent = logical[i]
    appear.push(appear[i])
    cnodes[i].parent = add(None, K_HIDDEN, Some(c))
  }
  for i in 0..<states {
    if owners[i] != -1 {
      cnodes[i].parent = cnodes[owners[i]].parent
    }
  }
  // Numbers the tree so that, at every level, initial states come first and the rest follow in the order the transitions introduce them.
  {
    let members : Array[Array[Int32]] = Array::makei(cnodes.length(), _ => [])
    let top : Array[Int32] = []
    for i, c in cnodes {
      if c.parent >= 0 {
        members[c.parent].push(i)
      } else {
        top.push(i)
      }
    }
    let initial = (i : Int32) => if views[i].kind == K_START { 0 } else { 1 }
    let by_flow = (a : Int32, b : Int32) => {
      let first = initial(a) - initial(b)
      if first != 0 {
        return first
      }
      if appear[a] != appear[b] {
        return if appear[a] < appear[b] { -1 } else { 1 }
      }
      a - b
    }
    let mut seq = 0.0
    top.sort_by(by_flow)
    top.rev_in_place()
    let pending = top
    while pending.pop() is Some(i) {
      cnodes[i].seq = seq
      seq += 1
      let inside = members[i]
      inside.sort_by(by_flow)
      for k = inside.length() - 1; k >= 0; k = k - 1 {
        pending.push(inside[k])
      }
    }
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
      tracks=curve is Some("step" | "stepBefore" | "stepAfter"),
      straight=curve is Some("linear"),
      head_room=@svg.marker_trim("arrow_point"),
    ),
  )
  let width = (layout.width + 2 * pad).ceil()
  let height = (layout.height + 2 * pad).ceil()
  let links : Array[@types.LinkInfo] = []

  // Route points by rounded y, to find the edges that cross a composite's title bar.
  let crossings : Map[Int32, Array[Double]] = Map([])
  for e in cedges {
    let route = e.route
    for k = 3; k < route.length() - 3; k = k + 3 {
      let key = route[k + 1].round().to_int()
      match crossings.get(key) {
        Some(list) => list.push(route[k])
        None => crossings.set(key, [route[k]])
      }
    }
  }
  let children : Array[Array[Int32]] = Array::makei(cnodes.length(), _ => [])
  let order : Array[Int32] = []
  for i, c in cnodes {
    if c.parent >= 0 {
      children[c.parent].push(i)
    } else {
      order.push(i)
    }
  }
  let roots = order.copy()
  for q = 0; q < order.length(); q = q + 1 {
    for child in children[order[q]] {
      order.push(child)
    }
  }
  let clusters = @svg.Markup::new()
  let fills : Array[@svg.Fill] = []
  let dividers = @svg.Markup::new()
  let nodes_out = @svg.Markup::new()
  let notes_out = @svg.Markup::new()
  // Draws the dashed lines between the regions among a composite's members.
  let divide = (
    items : Array[Int32],
    left : Double,
    top : Double,
    right : Double,
    bottom : Double,
  ) => {
    let regions = items.filter(i => views[i].kind == K_REGION)
    if regions.length() < 2 {
      return
    }
    let lo = (i : Int32, x : Bool) => {
      if x {
        cnodes[i].x - cnodes[i].w / 2
      } else {
        cnodes[i].y - cnodes[i].h / 2
      }
    }
    let hi = (i : Int32, x : Bool) => {
      if x {
        cnodes[i].x + cnodes[i].w / 2
      } else {
        cnodes[i].y + cnodes[i].h / 2
      }
    }
    for x in [true, false] {
      let sorted = regions.copy()
      sorted.sort_by((a, b) => {
        let d = lo(a, x) - lo(b, x)
        if d < 0 {
          -1
        } else if d > 0 {
          1
        } else {
          a - b
        }
      })
      let mut apart = true
      for k in 1..<sorted.length() {
        if hi(sorted[k - 1], x) > lo(sorted[k], x) + 0.5 {
          apart = false
        }
      }
      if !apart {
        continue
      }
      for k in 1..<sorted.length() {
        let at = @svg.num((hi(sorted[k - 1], x) + lo(sorted[k], x)) / 2 + pad)
        let d = if x {
          "\{at},\{@svg.num(top)}V\{@svg.num(bottom)}"
        } else {
          "\{@svg.num(left)},\{at}H\{@svg.num(right)}"
        }
        dividers.write("<path class=\"pele-divider\" d=\"M\{d}\"/>")
      }
      return
    }
    // Regions that sit neither side by side nor in a stack each get an outline.
    for i in regions {
      let c = cnodes[i]
      dividers.write(
        rect(
          c.x - c.w / 2 + pad,
          c.y - c.h / 2 + pad,
          c.w,
          c.h,
          " class=\"pele-divider\" rx=\"\{CORNER}\"",
        ),
      )
    }
  }
  divide(roots, pad / 2, pad / 2, width - pad / 2, height - pad / 2)
  for i in order {
    let view = views[i]
    guard view.node is Some(node) &&
      view.style is Some(style) &&
      view.kind < K_REGION else {
      continue
    }
    let c = cnodes[i]
    let x = c.x + pad
    let y = c.y + pad
    let w = view.w
    let h = view.h
    let body = @svg.Markup::new()
    let ink = @svg.raw_ink_fill(style)
    match view.kind {
      K_COMPOSITE => {
        let left = x - c.w / 2
        let top = y - c.h / 2
        if @svg.raw_paints(style.shape) {
          fills.push(
            @svg.Fill::raw([left, top, left + c.w, top + c.h], style.shape),
          )
        }
        let wash = if @svg.sets_raw_fill(style.shape) {
          ""
        } else {
          " fill-opacity=\"0.5\""
        }
        write_rect(
          body,
          left,
          top,
          c.w,
          c.h,
          " rx=\"\{CORNER}\" fill=\"var(--_a)\"\{wash} stroke=\"var(--_b)\"",
          style.shape,
        )
        if view.title_h > 0 {
          body.write(
            "<path d=\"M\{@svg.num(left)},\{@svg.num(top + view.title_h)}H\{@svg.num(left + c.w)}\"\{RULE}",
          )
          @svg.write_style(body, style.line)
          body.write("/>")
          @svg.write_label_styled(
            body,
            view.label,
            title_x(c, view.label.width, crossings) + pad,
            top + view.title_h / 2,
            " class=\"pele-cluster-label\"\{ink}",
            style.text,
            icons?=options.icons,
          )
        }
        divide(children[i], left, top + view.title_h, left + c.w, top + c.h)
      }
      K_START => {
        body.write("<circle r=\"7\" fill=\"var(--_l)\"")
        @svg.write_style(body, style.shape)
        body.write("/>")
      }
      K_END => {
        body.write("<circle r=\"8.5\" fill=\"var(--_bg)\" stroke=\"var(--_l)\"")
        @svg.write_style(body, style.line)
        body.write("/><circle r=\"5\" fill=\"var(--_l)\"")
        @svg.write_style(body, style.shape)
        body.write("/>")
      }
      K_CHOICE => {
        body.write(
          "<polygon points=\"0,\{@svg.num(-h / 2)} \{@svg.num(w / 2)},0 0,\{@svg.num(h / 2)} \{@svg.num(-w / 2)},0\"\{SURFACE}",
        )
        @svg.write_style(body, style.shape)
        body.write("/>")
      }
      K_FORK | K_JOIN =>
        write_rect(
          body,
          -w / 2,
          -h / 2,
          w,
          h,
          " rx=\"2\" fill=\"var(--_l)\"",
          style.shape,
        )
      K_NOTE => {
        let r = @svg.num(w / 2)
        let b = @svg.num(h / 2)
        let fold = @svg.num(w / 2 - FOLD)
        let corner = @svg.num(FOLD - h / 2)
        body.write(
          "<path d=\"M-\{r},-\{b}H\{fold}L\{r},\{corner}V\{b}H-\{r}Z\" fill=\"var(--_bg)\" stroke=\"var(--_b)\"/>" +
          "<path d=\"M\{fold},-\{b}V\{corner}H\{r}\"\{RULE}/>",
        )
        @svg.write_label(
          body,
          view.label,
          0,
          0,
          " class=\"pele-label\" font-size=\"\{small}\" fill=\"var(--_m)\"",
          icons?=options.icons,
        )
      }
      _ => {
        write_rect(
          body,
          -w / 2,
          -h / 2,
          w,
          h,
          " rx=\"\{@svg.num(@util.js_min(CORNER, h / 2))}\"\{SURFACE}",
          style.shape,
        )
        if view.kind == K_STATE {
          @svg.write_label_styled(
            body,
            view.label,
            0,
            0,
            " class=\"pele-label\"\{ink}",
            style.text,
            icons?=options.icons,
          )
        } else {
          let mut at = PAD_Y - h / 2 + view.label.height
          body.write(
            "<path d=\"M\{@svg.num(-w / 2)},\{@svg.num(at + 6)}H\{@svg.num(w / 2)}\"\{RULE}",
          )
          @svg.write_style(body, style.line)
          body.write("/>")
          @svg.write_label_styled(
            body,
            view.label,
            0,
            at - view.label.height / 2,
            " class=\"pele-label\"\{ink}",
            style.text,
            icons?=options.icons,
          )
          at += 14
          for line in view.lines {
            @svg.write_label_styled(
              body,
              line,
              0,
              at + line.height / 2,
              " class=\"pele-state-description\" font-size=\"\{small}\"\{ink}",
              style.text,
              icons?=options.icons,
            )
            at += line.height
          }
        }
      }
    }
    let out = if view.kind == K_COMPOSITE {
      clusters
    } else if view.kind == K_NOTE {
      notes_out
    } else {
      nodes_out
    }
    out.write(
      "<g class=\"\{kind_classes[view.kind]}\{@svg.class_names(strip_mermaid_classes(node.css_classes))}\" data-id=\"",
    )
    out.write_esc_text(node.id)
    out.write(
      if view.kind == K_COMPOSITE {
        "\">"
      } else {
        "\" transform=\"translate(\{@svg.num(x)},\{@svg.num(y)})\">"
      },
    )
    let mut tooltip = ""
    let linked = match db.links.get(node.id) {
      Some(link) => {
        // Entity codes are resolved first, so the URL is checked in the form a browser would follow.
        tooltip = @text.decode_entities(unquote(link.tooltip))
        @url.write_link_start(
          out,
          @url.safe_url(unquote(link.url)),
          node.id,
          links,
          options,
          attrs=" target=\"_blank\"",
        )
      }
      None => false
    }
    if tooltip != "" {
      out.write("<title>")
      out.write_esc(tooltip)
      out.write("</title>")
    }
    out.write_markup(body)
    if linked {
      out.write("</a>")
    }
    out.write("</g>")
  }

  // Moves a route end from the layout box onto the drawn shape, and spreads the ends along a bar.
  let attach = (route : Array[Double], at : Int32, i : Int32) => {
    let c = cnodes[i]
    if c.is_group {
      return
    }
    let view = views[i]
    let bar = view.kind == K_FORK || view.kind == K_JOIN
    let other = if at == 0 { 3 } else { at - 3 }
    // 0 is the x axis and 1 the y axis; the end sits on a side that faces along `axis`.
    for axis in [1, 0] {
      let extent = if axis == 1 { c.h } else { c.w }
      let drawn_extent = if axis == 1 { view.h } else { view.w }
      let breadth = if axis == 1 { view.w } else { view.h }
      let center = (if axis == 1 { c.y } else { c.x }) + pad
      let cross = (if axis == 1 { c.x } else { c.y }) + pad
      let delta = route[at + axis] - center
      if (delta.abs() - extent / 2).abs() >= 0.5 {
        continue
      }
      route[at + axis] -= js_sign(delta) * (extent - drawn_extent) / 2
      if bar && breadth > drawn_extent {
        route[at + 1 - axis] = clamp(
          route[other + 1 - axis],
          cross - breadth / 2 + 6,
          cross + breadth / 2 - 6,
        )
      }
      return
    }
  }
  let reach = @svg.SideReach::new()
  for i, ce in cedges {
    if ce.src == ce.dst || ce.route.length() < 6 || drawn[i].dashed {
      continue
    }
    reach.add(
      ce.dst,
      @svg.end_side(ce.route, ce.route.length() - 3, cnodes[ce.dst]),
      "arrow_point",
    )
  }
  let casings = @svg.Markup::new()
  let edges_out = @svg.Markup::new()
  let labels_out = @svg.Markup::new()
  let loop_seen = FixedArray::make(states, 0)
  let loop_text = FixedArray::make(states, 0.0)
  for i, ce in cedges {
    let edge = drawn[i]
    let label = edge_labels[i]
    let note = edge.dashed
    let end_type = if note { "none" } else { "arrow_point" }
    let mut d = ""
    let mut tokens : Array[Double]? = None
    let mut ex = 0.0
    let mut ey = 0.0
    let mut edx = 0.0
    let mut edy = 0.0
    if ce.src == ce.dst {
      let a = cnodes[ce.src]
      let view = views[ce.src]
      let k = loop_seen[ce.src]
      loop_seen[ce.src] += 1
      // The loop hangs off a side the flow does not use: the right, or below when the flow is horizontal.
      let side = across(ce.src)
      let w = if a.is_group { a.w } else { view.w }
      let h = if a.is_group { a.h } else { view.h }
      let out = (if side { w } else { h }) / 2
      let spread = @util.js_max(
        @util.js_min((if side { h } else { w }) / 2 - 4, 8 + k.to_double() * 6),
        2,
      )
      let loop_reach = LOOP + k.to_double() * 8
      let hyp = @util.js_hypot(loop_reach, spread)
      let trim = @svg.marker_trim(end_type) /
        (if hyp == 0 || hyp.is_nan() { 1 } else { hyp })
      // Offsets are given for a loop on the right and turned a quarter for one below.
      let px = (dx : Double, dy : Double) => {
        a.x + pad + (if side { out + dx } else { -dy })
      }
      let py = (dx : Double, dy : Double) => {
        a.y + pad + (if side { dy } else { out + dx })
      }
      let at = (dx : Double, dy : Double) => {
        "\{@svg.num(px(dx, dy))},\{@svg.num(py(dx, dy))}"
      }
      d = "M\{at(0, -spread)}C\{at(loop_reach, -2 * spread)} \{at(loop_reach, 2 * spread)} \{at(loop_reach * trim, spread + spread * trim)}"
      ex = px(0, spread)
      ey = py(0, spread)
      edx = px(-loop_reach, -spread) - px(0, 0)
      edy = py(-loop_reach, -spread) - py(0, 0)
      let length = @util.js_hypot(edx, edy)
      let length = if length == 0 || length.is_nan() { 1.0 } else { length }
      edx /= length
      edy /= length
      // Labels stack beyond the outermost loop, in the order of their transitions.
      let furthest = LOOP + (loop_count[ce.src] - 1).to_double() * 8
      let below = loop_text[ce.src] + label.height / 2
      loop_text[ce.src] += label.height
      ce.label_x = if side {
        a.x + out + furthest + 4 + ce.label_w / 2
      } else {
        a.x
      }
      ce.label_y = if side {
        a.y - loop_height[ce.src] / 2 + below
      } else {
        a.y + out + furthest * 0.75 + 4 + below
      }
    } else {
      let mut route = ce.route.copy()
      let leaves = reach.of(ce.src, @svg.end_side(route, 0, cnodes[ce.src]))
      let arrives = reach.of(
        ce.dst,
        @svg.end_side(route, route.length() - 3, cnodes[ce.dst]),
      )
      for k = 0; k < route.length(); k = k + 3 {
        route[k] += pad
        route[k + 1] += pad
      }
      attach(route, 0, ce.src)
      attach(route, route.length() - 3, ce.dst)
      if anchors.get(i) is Some(composite) && route.length() >= 6 {
        let g = cnodes[composite]
        let inward = views[ce.src].kind == K_HIDDEN
        let at = if inward { 0 } else { route.length() - 3 }
        let near = (g.dir is Some(TB | LR)) == inward
        let point = if vertical(g.dir) {
          [
            route[at],
            g.y +
            pad +
            (if near { views[composite].title_h - g.h / 2 } else { g.h / 2 }),
            0,
          ]
        } else {
          [
            g.x + pad + (if near { -g.w / 2 } else { g.w / 2 }),
            route[at + 1],
            1,
          ]
        }
        route = if inward { point + route } else { route + point }
      }
      let path = @svg.route_path(
        route,
        curve,
        0,
        @svg.marker_trim(end_type),
        start_reach=leaves,
        end_reach=arrives,
      )
      d = path.d
      tokens = path.tokens
      ex = path.ex
      ey = path.ey
      edx = path.edx
      edy = path.edy
    }
    let ink = match @svg.over_fills(d, [ex, ey], fills, tokens?) {
      Some("") => {
        casings.write(
          @svg.edge_casing(
            { d, tokens, sx: 0, sy: 0, sdx: 0, sdy: 0, ex, ey, edx, edy, },
            "none",
            end_type,
          ),
        )
        None
      }
      Some(ink) => Some(ink)
      None => None
    }
    let kind = match (note, ink) {
      (true, _) =>
        "pele-note-edge\" stroke=\"\{ink.unwrap_or("var(--_b)")}\" stroke-dasharray=\"3 4"
      (false, Some(ink)) => "pele-transition\" stroke=\"\{ink}"
      (false, None) => "pele-transition"
    }
    edges_out.write("<g class=\"pele-edge \{kind}\" data-id=\"")
    edges_out.write_esc_text(edge.id)
    edges_out.write(
      "\"><path d=\"\{d}\"/>" +
      @svg.marker(end_type, ex, ey, edx, edy, ink.unwrap_or("var(--_l)")) +
      "</g>",
    )
    if label.width > 0 {
      @svg.write_edge_label(
        labels_out,
        edge.id,
        label,
        ce.label_x + pad,
        ce.label_y + pad,
        "",
        icons?=options.icons,
      )
    }
  }
  let content = @svg.Markup::new()
  if !clusters.is_empty() {
    content.write_group("<g class=\"pele-clusters\">", clusters, "</g>")
  }
  if !dividers.is_empty() {
    content.write_group(
      "<g class=\"pele-dividers\" stroke-dasharray=\"4 4\"\{RULE}>",
      dividers,
      "</g>",
    )
  }
  @svg.write_casings(content, casings)
  if !edges_out.is_empty() {
    content.write_group(
      "<g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\">",
      edges_out, "</g>",
    )
  }
  if !labels_out.is_empty() {
    content.write_group(
      "<g class=\"pele-edge-labels\" font-size=\"\{small}\">",
      labels_out,
      "</g>",
    )
  }
  content.write("<g class=\"pele-nodes\">")
  content.write_markup(nodes_out)
  content.write_markup(notes_out)
  content.write("</g>")
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
    "state",
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
/// Picks where a composite's title sits in its title bar so that edges entering from above do not cross it.
fn title_x(
  c : @layout.CNode,
  width : Double,
  crossings : Map[Int32, Array[Double]],
) -> Double {
  guard crossings.get((c.y - c.h / 2).round().to_int()) is Some(xs) &&
    width != 0 else {
    return c.x
  }
  let left = c.x - c.w / 2
  let half = width / 2
  let mut best = c.x
  let mut best_gap = -1.0
  for x in [c.x, left + GROUP_PAD + half, left + c.w - GROUP_PAD - half] {
    let mut gap = @double.infinity
    for cx in xs {
      if cx > left && cx < left + c.w {
        gap = @util.js_min(gap, (cx - x).abs() - half)
      }
    }
    if gap >= 6 {
      return x
    }
    if gap > best_gap + 0.5 {
      best_gap = gap
      best = x
    }
  }
  best
}
