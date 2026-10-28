///|
/// Whether a message kind is drawn as a line between lifelines.
fn is_line_message(kind : Int32) -> Bool {
  match kind {
    0 | 1 | 3 | 4 | 5 | 6 | 24 | 25 | 33 | 34 => true
    _ => (kind >= 41 && kind <= 48) || (kind >= 51 && kind <= 58)
  }
}

///|
/// The numbers of the message lines.
/// `index` holds the number each message line carries, whether or not it is shown, and NaN for every other entry.
/// `visible` says whether numbers are on after the last statement.
pub(all) struct Numbering {
  index : Array[Double]
  shown : Array[Bool]
  visible : Bool
}

///|
/// A number as `||` takes it: zero and NaN fall back to `fallback`.
fn or_else(value : Double?, fallback : Double) -> Double {
  match value {
    Some(value) if !(value == 0 || value.is_nan()) => value
    _ => fallback
  }
}

///|
/// Counts message lines the way Mermaid's renderer does while it draws.
/// `always` numbers every line, as the `showSequenceNumbers` setting does.
pub fn number_messages(
  messages : Array[SeqMessage],
  always : Bool,
) -> Numbering {
  let index = []
  let shown = []
  let mut current = 1.0
  let mut step = 1.0
  let mut visible = false
  for m in messages {
    let mut number = @double.not_a_number
    let mut show = false
    if m.kind == AUTONUMBER {
      if m.numbering is Some(spec) {
        current = or_else(spec.start, current)
        step = or_else(spec.step, step)
        visible = spec.visible
      }
    } else if is_line_message(m.kind) {
      number = current
      show = visible || always
      current = ((current + step) * 100).round() / 100
    }
    index.push(number)
    shown.push(show)
  }
  { index, shown, visible, }
}

///|
priv enum Head {
  NoHead
  Arrow
  Cross
  Open
  HalfSolid
  HalfStick
}

///|
/// How a message line is drawn.
/// The heads are at the receiver, at the sender only (the reverse arrows), or at both.
priv struct LineStyle {
  dotted : Bool
  head : Head
  at_start : Bool
  at_end : Bool
  bottom : Bool
}

///|
/// The style of a message kind that is drawn as a line.
fn line_style(kind : Int32) -> LineStyle {
  // `ends` is 1 for a head at the receiver, 0 for one at the sender, and 2 for both.
  let make = (dotted : Bool, head : Head, ends : Int32, bottom : Bool) => {
    dotted,
    head,
    at_start: ends != 1,
    at_end: ends != 0,
    bottom,
  }
  match kind {
    0 => make(false, Arrow, 1, false)
    1 => make(true, Arrow, 1, false)
    3 => make(false, Cross, 1, false)
    4 => make(true, Cross, 1, false)
    5 => make(false, NoHead, 1, false)
    6 => make(true, NoHead, 1, false)
    24 => make(false, Open, 1, false)
    25 => make(true, Open, 1, false)
    33 => make(false, Arrow, 2, false)
    34 => make(true, Arrow, 2, false)
    _ => {
      let dotted = kind > 50
      let base = if dotted { kind - 10 } else { kind }
      match base {
        41 => make(dotted, HalfSolid, 1, false)
        42 => make(dotted, HalfSolid, 1, true)
        43 => make(dotted, HalfStick, 1, false)
        44 => make(dotted, HalfStick, 1, true)
        45 => make(dotted, HalfSolid, 0, false)
        46 => make(dotted, HalfSolid, 0, true)
        47 => make(dotted, HalfStick, 0, false)
        _ => make(dotted, HalfStick, 0, true)
      }
    }
  }
}

///|
/// The name of the block a message kind starts, or `None`.
fn frame_kind(kind : Int32) -> String? {
  match kind {
    10 => Some("loop")
    12 => Some("alt")
    15 => Some("opt")
    19 | 32 => Some("par")
    27 => Some("critical")
    30 => Some("break")
    22 => Some("rect")
    _ => None
  }
}

///|
fn is_divider(kind : Int32) -> Bool {
  kind == ALT_ELSE || kind == PAR_AND || kind == CRITICAL_OPTION
}

///|
fn is_frame_end(kind : Int32) -> Bool {
  kind == LOOP_END ||
  kind == ALT_END ||
  kind == OPT_END ||
  kind == PAR_END ||
  kind == CRITICAL_END ||
  kind == BREAK_END ||
  kind == RECT_END
}

///|
const MSG_PAD : Double = 12

///|
const SELF_W : Double = 28

///|
const SELF_H : Double = 22

///|
const ACT_W : Double = 10

///|
const ACT_STEP : Double = 4

///|
const ACT_MIN : Double = 14

///|
const NOTE_GAP : Double = 10

///|
const NOTE_OVER : Double = 16

///|
const FRAME_PAD : Double = 20

///|
const FRAME_NEST : Double = 10

///|
const TAB_H : Double = 20

///|
const FRAME_TEXT : Double = 240

///|
const BADGE_H : Double = 16

///|
const CENTRAL_R : Double = 4

///|
const FONT_MONO : String = "var(--_fm)"

///|
const DASH : String = " stroke-dasharray=\"4 4\""

///|
const FRAME_LABEL : String = " class=\"pele-frame-label\" fill=\"var(--_m)\" stroke=\"none\""

///|
priv struct Column {
  id : String
  actor : SeqActor
  kind : String
  label : @text.Label
  size : ActorSize
  mut x : Double
  create_at : Int32
  destroy_at : Int32
  mut top : Double
  mut life_start : Double
  mut life_end : Double
  activations : Array[Double]
}

///|
priv enum ViewKind {
  LineView
  SelfView
  NoteView
}

///|
priv struct View {
  kind : ViewKind
  a : Int32
  b : Int32
  mut label : @text.Label
  mut x : Double
  mut w : Double
}

///|
priv struct Frame {
  kind : String
  mut x0 : Double
  mut x1 : Double
  mut top : Double
  mut title : @text.Label
  mut tab_w : Double
  fill : String
  dividers : Array[Int32]
  divider_y : Array[Double]
  divider_labels : Array[@text.Label]
}

///|
priv struct BoxRun {
  box : SeqBox
  first : Int32
  mut last : Int32
  title : @text.Label
  mut grow : Double
}

///|
fn no_label() -> @text.Label {
  {
    lines: [],
    widths: [],
    width: 0,
    height: 0,
    size: 0,
    line_height: 0,
    heights: None,
  }
}

///|
/// A numeric setting that pele accepts between 0 and 2000.
fn option(conf : Map[String, Json], key : String, fallback : Double) -> Double {
  match conf.get(key) {
    Some(Number(value, ..)) if value >= 0 && value <= 2000 => value
    _ => fallback
  }
}

///|
fn half(
  x : Double,
  y : Double,
  dir : Double,
  up : Double,
  stick : Bool,
) -> String {
  let n = @svg.num
  let bx = n(x - dir * @svg.ARROW)
  if stick {
    return "<path class=\"pele-marker\" d=\"M\{n(x)},\{n(y)}L\{bx},\{n(y + up * 5)}\"/>"
  }
  "<path class=\"pele-marker\" d=\"M\{n(x)},\{n(y)}L\{bx},\{n(y + up * 4.5)}V\{n(y)}Z\" fill=\"var(--_l)\" stroke=\"none\"/>"
}

///|
/// Draws the head whose tip is at (`x`, `y`) and points along `dir`.
/// `up` is the side a half head sits on.
fn head(
  kind : Head,
  x : Double,
  y : Double,
  dir : Double,
  up : Double,
) -> String {
  let n = @svg.num
  match kind {
    Arrow => @svg.marker("arrow_point", x, y, dir, 0, "var(--_l)")
    Cross => @svg.marker("arrow_cross", x, y, dir, 0, "var(--_l)")
    Open =>
      "<path class=\"pele-marker\" d=\"M\{n(x - dir * @svg.ARROW)},\{n(y - 4.5)}L\{n(x)},\{n(y)}L\{n(x - dir * @svg.ARROW)},\{n(y + 4.5)}\" stroke-linejoin=\"round\"/>"
    HalfSolid => half(x, y, dir, up, false)
    HalfStick => half(x, y, dir, up, true)
    NoHead => ""
  }
}

///|
fn trim(kind : Head) -> Double {
  match kind {
    Arrow => @svg.ARROW - 1
    Cross => 4
    _ => 0
  }
}

///|
/// Draws a sequence diagram.
pub fn render_sequence(
  db : SeqDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  @common.tighten(options, tight => draw(db, config, options, tight))
}

///|
fn draw(
  db : SeqDb,
  config : @types.Config,
  options : @types.RenderOptions,
  tight : Bool,
  hold~ : Double = 0,
) -> @types.Rendered raise @errors.PeleError {
  let n = @svg.num
  let infinity = @double.infinity
  let conf : Map[String, Json] = match config.get("sequence") {
    Some(Object(section)) => section
    _ => Map([])
  }
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.875).round()
  let tiny = (size * 0.75).round()
  let measurer = options.text_measurer()
  let monospaced = options.monospaces("messages")
  let message_measurer : @text.TextMeasurer = if monospaced {
    {
      width_of: (t, s, style) => measurer.width(t, s, style | @text.STYLE_MONO),
    }
  } else {
    measurer
  }
  let pad = options.padding.unwrap_or(8)
  let mirror = !(conf.get("mirrorActors") is Some(False))
  let right_angles = conf.get("rightAngles") is Some(True)
  let actor_margin = @util.js_min(
    option(conf, "actorMargin", 40),
    if tight {
      8
    } else {
      infinity
    },
  )
  let min_w = @util.js_min(
    option(conf, "width", 64),
    if tight {
      48
    } else {
      infinity
    },
  )
  let min_h = option(conf, "height", (size * 1.5).round() + 20)
  let wrap_w = @util.js_min(
    option(conf, "width", 160),
    if tight {
      @util.js_max(
        32,
        (options.max_width.unwrap_or(320) - 2 * pad) /
        @util.js_max(1, db.actors.length().to_double()) -
        actor_margin -
        24,
      )
    } else {
      infinity
    },
  )
  // Mermaid's default of 35 corresponds to pele's default gap.
  // Other values move it by the difference.
  let msg_gap = @util.js_max(4, 14 + option(conf, "messageMargin", 35) - 35)
  let note_pad = @util.js_min(
    option(conf, "noteMargin", 10),
    if tight {
      6
    } else {
      infinity
    },
  )
  let box_pad = @util.js_min(
    option(conf, "boxMargin", 10),
    if tight {
      6
    } else {
      infinity
    },
  )
  let align = match conf.get("messageAlign") {
    Some(String("left")) => -1.0
    Some(String("right")) => 1.0
    _ => 0.0
  }
  let msg_pad = if tight { 6.0 } else { MSG_PAD }
  let note_over = if tight { 8.0 } else { NOTE_OVER }
  let frame_pad = if tight { 12.0 } else { FRAME_PAD }
  let frame_nest = if tight { 6.0 } else { FRAME_NEST }
  let messages = db.messages
  let count = messages.length()
  let numbering = number_messages(
    messages,
    conf.get("showSequenceNumbers") is Some(True),
  )
  let text_by = (
    by : @text.TextMeasurer,
    raw : String?,
    font_size : Double,
    wrap : Bool,
    width : Double,
  ) => {
    let label = @text.layout_label(
      raw,
      false,
      by,
      font_size,
      if tight || wrap {
        width
      } else {
        infinity
      },
    )
    if tight {
      @common.break_label(label, by, @util.js_max(120, width))
    } else {
      label
    }
  }
  let text = (raw : String?, font_size : Double, wrap : Bool, width : Double) => {
    text_by(measurer, raw, font_size, wrap, width)
  }
  let message_text = (raw : String, wrap : Bool, width : Double) => {
    text_by(message_measurer, Some(raw), small, wrap, width)
  }
  let used : Set[String?]? = if conf.get("hideUnusedParticipants") is Some(True) {
    let used = Set([])
    for m in messages {
      used.add(m.from)
      used.add(m.to)
    }
    Some(used)
  } else {
    None
  }
  let next_line = FixedArray::make(count + 1, -1)
  for i = count - 1; i >= 0; i = i - 1 {
    next_line[i] = if is_line_message(messages[i].kind) {
      i
    } else {
      next_line[i + 1]
    }
  }
  let cols : Array[Column] = []
  let col_of : Map[String, Int32] = Map([])
  for id, actor in db.actors {
    if used is Some(used) && !used.contains(Some(id)) {
      continue
    }
    let kind = actor_kind(actor.kind)
    let label = text(Some(actor.description), size, actor.wrap, wrap_w)
    let mut create_at = match db.created_actors.get(id) {
      Some(at) => next_line[if at < count { at } else { count }]
      None => -1
    }
    if create_at >= 0 && messages[create_at].to != Some(id) {
      create_at = -1
    }
    let mut destroy_at = match db.destroyed_actors.get(id) {
      Some(at) => next_line[if at < count { at } else { count }]
      None => -1
    }
    if destroy_at >= 0 &&
      messages[destroy_at].to != Some(id) &&
      messages[destroy_at].from != Some(id) {
      destroy_at = -1
    }
    col_of.set(id, cols.length())
    cols.push({
      id,
      actor,
      kind,
      label,
      size: actor_size(
        kind,
        label,
        min_w,
        min_h,
        padding_x=if tight { 8 } else { 16 },
      ),
      x: 0,
      create_at,
      destroy_at,
      top: 0,
      life_start: 0,
      life_end: -1,
      activations: [],
    })
  }
  let last = cols.length() - 1
  let col_count = cols.length()

  // Widths between lifelines.
  // Every message and note says how far apart the lifelines it touches must be.
  let needs : Map[Int32, Double] = Map([])
  let need = (lo : Int32, hi : Int32, width : Double) => {
    if lo < 0 || hi > last {
      return
    }
    let key = lo * col_count + hi
    if needs.get(key).unwrap_or(0) < width {
      needs.set(key, width)
    }
  }
  let badge_width = (i : Int32) => {
    if numbering.shown[i] {
      @util.js_max(
        BADGE_H,
        measurer.width(numbering.index[i].to_string(), tiny, 0) + 8,
      )
    } else {
      0
    }
  }
  let views : Array[View?] = Array::make(count, None)
  for i in 0..<count {
    let m = messages[i]
    let a = m.from.bind(id => col_of.get(id))
    let b = m.to.bind(id => col_of.get(id))
    guard a is Some(a) && b is Some(b) && m.numbering is None else { continue }
    let lo = if a < b { a } else { b }
    let hi = if a < b { b } else { a }
    if m.kind == NOTE {
      let label = text(Some(m.message), small, m.wrap, wrap_w)
      let w = label.width + 2 * note_pad
      if m.placement == Some(LEFTOF) {
        need(a - 1, a, w + 2 * NOTE_GAP + ACT_W)
      } else if m.placement == Some(RIGHTOF) {
        need(a, a + 1, w + 2 * NOTE_GAP + ACT_W)
      } else if a == b {
        need(a - 1, a, w / 2 + NOTE_GAP)
        need(a, a + 1, w / 2 + NOTE_GAP)
      } else {
        need(lo, hi, w - 2 * note_over)
      }
      views[i] = Some({ kind: NoteView, a, b, label, x: 0, w, })
    } else if is_line_message(m.kind) {
      let label = message_text(m.message, m.wrap, wrap_w)
      let badge = badge_width(i)
      if a == b {
        need(a, a + 1, SELF_W + 8 + label.width + 16 + ACT_W + badge)
        views[i] = Some({ kind: SelfView, a, b, label, x: 0, w: 0, })
      } else {
        let created = if cols[b].create_at == i {
          cols[b].size.w / 2
        } else {
          0
        }
        let central : Double = if m.central_connection != 0 {
          4 * CENTRAL_R
        } else {
          0
        }
        let shown = if tight {
          @util.js_min(label.width, @util.js_max(16, wrap_w - 16))
        } else {
          label.width
        }
        need(lo, hi, shown + 2 * msg_pad + ACT_W + badge + created + central)
        views[i] = Some({ kind: LineView, a, b, label, x: 0, w: 0, })
      }
    }
  }
  let runs : Array[BoxRun] = []
  for i in 0..<=last {
    guard cols[i].actor.box is Some(box) else { continue }
    match runs.last() {
      Some(run) if physical_equal(run.box, box) && run.last == i - 1 =>
        run.last = i
      _ =>
        runs.push({
          box,
          first: i,
          last: i,
          title: text(box.name, small, box.wrap, wrap_w),
          grow: 0,
        })
    }
  }
  let same_box = (left : SeqBox?, right : SeqBox?) => {
    match (left, right) {
      (None, None) => true
      (Some(left), Some(right)) => physical_equal(left, right)
      _ => false
    }
  }
  let gaps : Array[Double] = Array::make(if last > 0 { last } else { 0 }, 0)
  for i in 0..<last {
    let left = cols[i]
    let right = cols[i + 1]
    let boxed = if same_box(left.actor.box, right.actor.box) {
      0.0
    } else {
      (if left.actor.box is Some(_) { box_pad } else { 0 }) +
      (if right.actor.box is Some(_) { box_pad } else { 0 })
    }
    gaps[i] = @util.js_max(
      left.size.w / 2 + right.size.w / 2 + actor_margin + boxed,
      needs.get(i * col_count + i + 1).unwrap_or(0),
    )
  }
  // A message across several lifelines widens each gap it crosses by an equal share of what is missing.
  let spans : Array[(Int32, Int32, Double)] = []
  for key, width in needs {
    let lo = key / col_count
    let hi = key % col_count
    if hi - lo > 1 {
      spans.push((lo, hi, width))
    }
  }
  spans.sort_by((p, q) => {
    let by_length = (p.1 - p.0).compare(q.1 - q.0)
    if by_length != 0 {
      by_length
    } else {
      p.0.compare(q.0)
    }
  })
  for span in spans {
    let (lo, hi, width) = span
    let mut total = 0.0
    for i in lo..<hi {
      total += gaps[i]
    }
    if total >= width {
      continue
    }
    let share = (width - total) / (hi - lo).to_double()
    for i in lo..<hi {
      gaps[i] += share
    }
  }
  let place = () => {
    for i in 1..<=last {
      cols[i].x = cols[i - 1].x + gaps[i - 1]
    }
  }
  place()
  for run in runs {
    let first = cols[run.first]
    let end = cols[run.last]
    let inner = end.x + end.size.w / 2 - (first.x - first.size.w / 2)
    run.grow = @util.js_max(0, (run.title.width - inner) / 2)
    if run.grow == 0 {
      continue
    }
    if run.first > 0 {
      gaps[run.first - 1] += run.grow
    }
    if run.last < last {
      gaps[run.last] += run.grow
    }
  }
  let mut min_x = infinity
  let mut max_x = -infinity
  let widen = (x0 : Double, x1 : Double) => {
    if x0 < min_x {
      min_x = x0
    }
    if x1 > max_x {
      max_x = x1
    }
  }
  let run_left = (run : BoxRun) => {
    let first = cols[run.first]
    first.x - first.size.w / 2 - box_pad - run.grow
  }
  let run_right = (run : BoxRun) => {
    let end = cols[run.last]
    end.x + end.size.w / 2 + box_pad + run.grow
  }
  let frames : Array[Frame?] = Array::make(count, None)
  let layout = () => {
    place()
    min_x = infinity
    max_x = -infinity
    for col in cols {
      widen(col.x - col.size.w / 2, col.x + col.size.w / 2)
    }
    for run in runs {
      widen(run_left(run), run_right(run))
    }

    // Horizontal extents of every block, from what it holds.
    let open : Array[Frame] = []
    let span_all = () => {
      if last < 0 {
        (0.0, 120.0)
      } else {
        (cols[0].x - frame_pad, cols[last].x + frame_pad)
      }
    }
    for i in 0..<count {
      let m = messages[i]
      let kind = m.kind
      if frame_kind(kind) is Some(name) {
        let frame = {
          kind: name,
          x0: infinity,
          x1: -infinity,
          top: 0,
          title: no_label(),
          tab_w: 0,
          fill: if name == "rect" {
            m.message
          } else {
            ""
          },
          dividers: [i],
          divider_y: [],
          divider_labels: [],
        }
        frames[i] = Some(frame)
        open.push(frame)
      } else if is_divider(kind) {
        if open.last() is Some(frame) {
          frame.dividers.push(i)
        }
      } else if is_frame_end(kind) {
        guard open.pop() is Some(frame) else { continue }
        frames[i] = Some(frame)
        if frame.x0 > frame.x1 {
          let (x0, x1) = span_all()
          frame.x0 = x0
          frame.x1 = x1
        }
        if frame.kind != "rect" {
          frame.tab_w = measurer.width(frame.kind, tiny, @text.STYLE_BOLD) + 14
          // A block grows to the right to give its texts up to FRAME_TEXT of width before they wrap.
          for k, divider in frame.dividers {
            let raw = messages[divider].message
            let tab = if k == 0 { frame.tab_w + 8 } else { 0 }
            let room = frame.x1 - frame.x0 - 16 - tab
            let label = if raw != "" {
              text(
                Some("[" + raw + "]"),
                small,
                true,
                @util.js_max(
                  room,
                  if tight {
                    @util.js_min(FRAME_TEXT, wrap_w)
                  } else {
                    FRAME_TEXT
                  },
                ),
              )
            } else {
              no_label()
            }
            if label.width > room {
              frame.x1 += label.width - room
            }
            if k == 0 {
              frame.title = label
            } else {
              frame.divider_labels.push(label)
            }
          }
        }
        widen(frame.x0, frame.x1)
        if open.last() is Some(parent) {
          parent.x0 = @util.js_min(parent.x0, frame.x0 - frame_nest)
          parent.x1 = @util.js_max(parent.x1, frame.x1 + frame_nest)
        }
      } else if views[i] is Some(view) {
        let a = cols[view.a]
        let b = cols[view.b]
        let mut x0 = 0.0
        let mut x1 = 0.0
        match view.kind {
          NoteView => {
            if m.placement == Some(LEFTOF) {
              view.x = a.x - NOTE_GAP - view.w
            } else if m.placement == Some(RIGHTOF) {
              view.x = a.x + NOTE_GAP
            } else if view.a == view.b {
              view.x = a.x - view.w / 2
            } else {
              let lo = @util.js_min(a.x, b.x) - note_over
              let hi = @util.js_max(a.x, b.x) + note_over
              if tight || m.wrap {
                view.label = text(
                  Some(m.message),
                  small,
                  true,
                  @util.js_max(wrap_w, hi - lo - 2 * note_pad),
                )
              }
              view.w = @util.js_max(hi - lo, view.label.width + 2 * note_pad)
              view.x = (lo + hi - view.w) / 2
            }
            x0 = view.x
            x1 = view.x + view.w
          }
          SelfView => {
            x0 = a.x
            x1 = a.x + ACT_W + SELF_W + 8 + view.label.width + badge_width(i)
          }
          LineView => {
            x0 = @util.js_min(a.x, b.x)
            x1 = @util.js_max(a.x, b.x)
            if tight || m.wrap {
              view.label = message_text(
                m.message,
                true,
                @util.js_max(wrap_w, x1 - x0 - 2 * msg_pad - ACT_W),
              )
            }
            if b.create_at == i {
              if b.x > a.x {
                x1 += b.size.w / 2
              } else {
                x0 -= b.size.w / 2
              }
            }
          }
        }
        widen(x0, x1)
        if open.last() is Some(frame) {
          frame.x0 = @util.js_min(frame.x0, x0 - frame_pad)
          frame.x1 = @util.js_max(frame.x1, x1 + frame_pad)
        }
      }
    }
  }
  layout()

  // Widen gaps only if it reduces message wrapping.
  let mut grown = false
  if tight && options.max_width is Some(max_width) {
    let spare = max_width.floor() - (max_x - min_x + 2 * pad).ceil() - hold
    let stretch = FixedArray::make(col_count, 0)
    let wrapped : Array[Int32] = []
    let mut lines = 0
    for i = 0; spare > 0 && i < views.length(); i = i + 1 {
      guard views[i] is Some(view) &&
        view.kind is LineView &&
        view.label.lines.length() >
        message_text(messages[i].message, false, infinity).lines.length() else {
        continue
      }
      wrapped.push(i)
      lines += view.label.lines.length()
      let lo = if view.a < view.b { view.a } else { view.b }
      let hi = if view.a < view.b { view.b } else { view.a }
      stretch[lo] += 1
      stretch[hi] -= 1
    }
    let mut active = 0
    let mut crossed = 0
    for i in 0..<gaps.length() {
      active += stretch[i]
      stretch[i] = if active > 0 { 1 } else { 0 }
      crossed += stretch[i]
    }
    if crossed > 0 {
      let before = gaps.copy()
      for i in 0..<gaps.length() {
        gaps[i] += stretch[i].to_double() * spare / crossed.to_double()
      }
      layout()
      for i in wrapped {
        if views[i] is Some(view) {
          lines -= view.label.lines.length()
        }
      }
      grown = lines > 0
      if !grown {
        for i, gap in before {
          gaps[i] = gap
        }
        layout()
      }
    }
  }

  // Vertical placement, top to bottom, drawing as it goes.
  let mut box_title_h = 0.0
  for run in runs {
    box_title_h = @util.js_max(box_title_h, run.title.height)
  }
  let box_top = if runs.length() > 0 {
    box_pad + (if box_title_h > 0 { box_title_h + 4 } else { 0 })
  } else {
    0
  }
  let mut row_h = 0.0
  for col in cols {
    if col.create_at < 0 {
      row_h = @util.js_max(row_h, col.size.h)
    }
  }
  let head_bottom = box_top + row_h
  for col in cols {
    col.top = head_bottom - col.size.h
    col.life_start = head_bottom
  }
  let xs = cols.map(col => col.x)
  // Whether a lifeline runs between two x positions, where text would be struck through.
  let crosses = (x0 : Double, x1 : Double) => {
    let mut lo = 0
    let mut hi = xs.length()
    while lo < hi {
      let mid = (lo + hi) >> 1
      if xs[mid] <= x0 {
        lo = mid + 1
      } else {
        hi = mid
      }
    }
    lo < xs.length() && xs[lo] < x1
  }
  fn write_backed(
    out : @svg.Markup,
    label : @text.Label,
    cx : Double,
    cy : Double,
    attrs : String,
  ) -> Unit raise @errors.PeleError {
    if label.width == 0 {
      return
    }
    let l = cx - label.width / 2
    if crosses(l, l + label.width) {
      out.write(
        "<rect x=\"\{n(l - 3)}\" y=\"\{n(cy - label.height / 2 + 2)}\" width=\"\{n(label.width + 6)}\" height=\"\{n(label.height - 4)}\" rx=\"3\" fill=\"var(--_bg)\" stroke=\"none\"/>",
      )
    }
    @svg.write_label(out, label, cx, cy, attrs, icons?=options.icons)
  }
  let left_edge = (col : Column, extra : Int32) => {
    if col.activations.length() + extra > 0 {
      col.x - ACT_W / 2
    } else {
      col.x
    }
  }
  let right_edge = (col : Column, extra : Int32) => {
    let depth = col.activations.length() + extra
    if depth > 0 {
      col.x + ACT_W / 2 + (depth - 1).to_double() * ACT_STEP
    } else {
      col.x
    }
  }

  // Shaded blocks and activations close from the inside out.
  // They are written in reverse, so that the inner ones end up on top.
  let rects_out : Array[@svg.Markup] = []
  let activations_out : Array[@svg.Markup] = []
  let frames_out = @svg.Markup::new()
  let edges_out = @svg.Markup::new()
  let labels_out = @svg.Markup::new()
  let notes_out = @svg.Markup::new()
  let actors_out = @svg.Markup::new()
  let crosses_out = @svg.Markup::new()
  fn end_activation(col : Column, end : Double) -> Double {
    let start = col.activations.unsafe_pop()
    let bottom = @util.js_max(end, start + ACT_MIN)
    let x = col.x - ACT_W / 2 + col.activations.length().to_double() * ACT_STEP
    widen(x, x + ACT_W)
    let rect = @svg.Markup::new()
    rect.write("<rect class=\"pele-activation\" data-id=\"")
    rect.write_esc_text(col.id)
    rect.write(
      "\" x=\"\{n(x)}\" y=\"\{n(start)}\" width=\"\{ACT_W}\" height=\"\{n(bottom - start)}\" rx=\"2\"/>",
    )
    activations_out.push(rect)
    bottom
  }
  // The lifeline of a destroyed participant ends in a cross a little below the message that ends it.
  fn destroy(col : Column, line_y : Double) -> Double {
    let cx = col.x
    let cy = line_y + 16
    col.life_end = cy
    crosses_out.write("<path class=\"pele-destroy\" data-id=\"")
    crosses_out.write_esc_text(col.id)
    crosses_out.write(
      "\" d=\"M\{n(cx - 6)},\{n(cy - 6)}L\{n(cx + 6)},\{n(cy + 6)}M\{n(cx + 6)},\{n(cy - 6)}L\{n(cx - 6)},\{n(cy + 6)}\"/>",
    )
    cy + 6
  }
  fn write_actor_node(
    col : Column,
    top : Double,
    footer : Bool,
  ) -> Unit raise @errors.PeleError {
    let classes = match col.actor.properties.get("class") {
      Some(String(cls)) => @svg.class_names(cls)
      _ => ""
    }
    let foot = if footer { " pele-actor-footer" } else { "" }
    actors_out.write(
      "<g class=\"pele-node pele-actor pele-actor-\{col.kind}\{foot}\{classes}\" data-id=\"",
    )
    actors_out.write_esc_text(col.id)
    actors_out.write("\">")
    write_actor(
      actors_out,
      col.kind,
      col.x,
      top,
      col.size,
      col.label,
      icons?=options.icons,
    )
    actors_out.write("</g>")
  }
  let badge = (i : Int32, cx : Double, cy : Double, w : Double) => {
    "<g class=\"pele-sequence-number\"><rect x=\"\{n(cx - w / 2)}\" y=\"\{n(cy - BADGE_H / 2)}\" width=\"\{n(w)}\" height=\"\{BADGE_H}\" rx=\"\{BADGE_H / 2}\" fill=\"var(--_l)\" stroke=\"none\"/><text x=\"\{n(cx)}\" y=\"\{n(cy + tiny * 0.35)}\" text-anchor=\"middle\" font-size=\"\{tiny}\" fill=\"var(--_bg)\" stroke=\"none\">\{@svg.esc(numbering.index[i].to_string())}</text></g>"
  }
  let mut y = head_bottom + 6
  let stack : Array[Frame] = []
  for i in 0..<count {
    let m = messages[i]
    let kind = m.kind
    if kind == ACTIVE_START {
      if m.from.bind(id => col_of.get(id)) is Some(col) {
        cols[col].activations.push(y)
      }
    } else if kind == ACTIVE_END {
      if m.from.bind(id => col_of.get(id)) is Some(col) &&
        cols[col].activations.length() > 0 {
        y = @util.js_max(y, end_activation(cols[col], y))
      }
    } else if frames[i] is Some(frame) && frame.dividers[0] == i {
      stack.push(frame)
      if frame.kind == "rect" {
        frame.top = y + 8
        y = frame.top
      } else {
        frame.top = y + 12
        y = frame.top + @util.js_max(TAB_H, frame.title.height + 2)
      }
    } else if frames[i] is Some(frame) {
      stack.pop() |> ignore
      let bottom = y + 12
      let x = n(frame.x0)
      let w = n(frame.x1 - frame.x0)
      if frame.kind == "rect" {
        let css = @svg.resolve_raw_style(
          if frame.fill != "" {
            ["fill:" + frame.fill]
          } else {
            []
          },
        )
        let fill = css.slots().shape
        let opacity = if fill != "" { "" } else { " fill-opacity=\"0.5\"" }
        let rect = @svg.Markup::new()
        @svg.write_styled(
          rect,
          "<rect class=\"pele-rect\" x=\"\{x}\" y=\"\{n(frame.top)}\" width=\"\{w}\" height=\"\{n(bottom - frame.top)}\"\{@svg.rounded(opacity + fill)}/>",
          css,
        )
        rects_out.push(rect)
      } else {
        let inner = @svg.Markup::new()
        inner.write(
          "<rect x=\"\{x}\" y=\"\{n(frame.top)}\" width=\"\{w}\" height=\"\{n(bottom - frame.top)}\" fill=\"none\"\{@svg.ROUNDED}/>",
        )
        for k, dy in frame.divider_y {
          let label = frame.divider_labels[k]
          inner.write("<path d=\"M\{x},\{n(dy)}H\{n(frame.x1)}\"\{DASH}/>")
          write_backed(
            inner,
            label,
            frame.x0 + 8 + label.width / 2,
            dy + 2 + label.height / 2,
            FRAME_LABEL,
          )
        }
        inner.write(
          "<rect x=\"\{x}\" y=\"\{n(frame.top)}\" width=\"\{n(frame.tab_w)}\" height=\"\{TAB_H}\" fill=\"var(--_s)\"\{@svg.ROUNDED}/>",
        )
        inner.write(
          "<text class=\"pele-frame-kind\" x=\"\{n(frame.x0 + frame.tab_w / 2)}\" y=\"\{n(frame.top + TAB_H / 2 + tiny * 0.35)}\" text-anchor=\"middle\" font-size=\"\{tiny}\" font-weight=\"var(--_hw)\" fill=\"var(--_m)\" stroke=\"none\">\{frame.kind}</text>",
        )
        write_backed(
          inner,
          frame.title,
          frame.x0 + frame.tab_w + 8 + frame.title.width / 2,
          frame.top + @util.js_max(TAB_H, frame.title.height) / 2,
          FRAME_LABEL,
        )
        frames_out.write_group(
          "<g class=\"pele-frame pele-frame-\{frame.kind}\">",
          inner,
          "</g>",
        )
      }
      y = bottom
    } else if is_divider(kind) {
      if stack.last() is Some(current) {
        let label = current.divider_labels[current.divider_y.length()]
        current.divider_y.push(y + 12)
        y += 12 + (if label.height > 0 { label.height } else { 0 })
      }
    } else if views[i] is Some(view) && view.kind is NoteView {
      let a = cols[view.a]
      let h = view.label.height + 2 * @util.js_max(4, note_pad - 4)
      let top = y + 10
      let mut x = view.x
      if m.placement == Some(RIGHTOF) {
        x += right_edge(a, 0) - a.x
      } else if m.placement == Some(LEFTOF) {
        x += left_edge(a, 0) - a.x
      }
      widen(x, x + view.w)
      notes_out.write(
        "<g class=\"pele-note\" data-id=\"i\{@svg.esc_text(m.id)}\"><rect x=\"\{n(x)}\" y=\"\{n(top)}\" width=\"\{n(view.w)}\" height=\"\{n(h)}\"\{@svg.ROUNDED}/>",
      )
      @svg.write_label(
        notes_out,
        view.label,
        x + view.w / 2,
        top + h / 2,
        " class=\"pele-label\" stroke=\"none\" fill=\"var(--_fg)\"",
        icons?=options.icons,
      )
      notes_out.write("</g>")
      y = top + h
    } else if views[i] is Some(view) {
      let st = line_style(kind)
      let a = cols[view.a]
      let b = cols[view.b]
      let label = view.label
      let bw = badge_width(i)
      // The activation a `+` starts belongs to this message, so the arrow stops at its edge.
      let mut starting = 0
      for k in (i + 1)..<count {
        let t = messages[k].kind
        if t == ACTIVE_START {
          if messages[k].from == m.to {
            starting += 1
          }
        } else if t != ACTIVE_END &&
          t != CENTRAL_CONNECTION &&
          t != CENTRAL_CONNECTION_REVERSE {
          break
        }
      }
      let up = if st.bottom { 1.0 } else { -1.0 }
      let attrs = if st.dotted { DASH } else { "" }
      let cc = m.central_connection
      let circle_to = cc == CENTRAL_CONNECTION || cc == CENTRAL_CONNECTION_DUAL
      let circle_from = cc == CENTRAL_CONNECTION_REVERSE ||
        cc == CENTRAL_CONNECTION_DUAL
      let circle = (cx : Double, cy : Double) => {
        "<circle class=\"pele-central\" cx=\"\{n(cx)}\" cy=\"\{n(cy)}\" r=\"\{CENTRAL_R}\" fill=\"var(--_l)\" stroke=\"none\"/>"
      }
      let tail_at_end = st.at_start && !st.at_end
      let head_trim = trim(st.head)
      let inner = StringBuilder()
      let mut line_y = 0.0
      if view.kind is SelfView {
        let top = y + msg_gap + @util.js_max(0, (label.height - SELF_H) / 2)
        let bottom = top + SELF_H
        let mut x0 = if circle_from {
          a.x + CENTRAL_R
        } else {
          right_edge(a, 0)
        }
        let mut x1 = if circle_to {
          a.x + CENTRAL_R
        } else {
          right_edge(a, starting)
        }
        let out = @util.js_max(x0, x1) + SELF_W + bw / 2
        if circle_from {
          inner.write_string(circle(a.x, top))
        }
        if circle_to {
          inner.write_string(circle(a.x, bottom))
        }
        if bw > 0 {
          inner.write_string(
            badge(
              i,
              if tail_at_end {
                x1
              } else {
                x0
              },
              if tail_at_end {
                bottom
              } else {
                top
              },
              bw,
            ),
          )
          if tail_at_end {
            x1 += bw / 2
          } else {
            x0 += bw / 2
          }
        }
        // The loop leaves to the right and comes back heading left, which turns a half head over.
        let heads = (if st.at_start {
            head(st.head, x0, top, -1, up)
          } else {
            ""
          }) +
          (if st.at_end { head(st.head, x1, bottom, -1, -up) } else { "" })
        let from = n(x0 + (if st.at_start { head_trim } else { 0 }))
        let to = n(x1 + (if st.at_end { head_trim } else { 0 }))
        let d = if right_angles {
          "M\{from},\{n(top)}H\{n(out)}V\{n(bottom)}H\{to}"
        } else {
          "M\{from},\{n(top)}H\{n(out - 6)}A6,6 0 0 1 \{n(out)},\{n(top + 6)}V\{n(bottom - 6)}A6,6 0 0 1 \{n(out - 6)},\{n(bottom)}H\{to}"
        }
        let drawn = inner.to_string()
        inner.reset()
        inner.write_string("<path d=\"\{d}\"\{attrs}/>" + heads + drawn)
        widen(a.x, out + 8 + label.width)
        if label.width > 0 {
          labels_out.write(
            "<g class=\"pele-edge-label\" data-id=\"i\{@svg.esc_text(m.id)}\">",
          )
          @svg.write_label(
            labels_out,
            label,
            out + 8 + label.width / 2,
            (top + bottom) / 2,
            "",
            icons?=options.icons,
          )
          labels_out.write("</g>")
        }
        // A label taller than the loop reaches below it, so the next row starts under the label.
        line_y = @util.js_max(bottom, (top + bottom) / 2 + label.height / 2)
      } else {
        let dir = if b.x > a.x { 1.0 } else { -1.0 }
        let creating = b.create_at == i
        line_y = y +
          msg_gap +
          @util.js_max(
            if label.height > 0 {
              label.height + 2
            } else {
              6
            },
            if creating {
              b.size.h / 2 - msg_gap + 6
            } else {
              0
            },
          )
        let mut x0 = if dir > 0 { right_edge(a, 0) } else { left_edge(a, 0) }
        let mut x1 = if dir > 0 {
          left_edge(b, starting)
        } else {
          right_edge(b, starting)
        }
        if creating {
          b.top = line_y - b.size.h / 2
          b.life_start = b.top + b.size.h
          x1 = b.x -
            dir * (if is_figure(b.kind) { 18 } else { b.size.w / 2 + 1 })
        }
        if circle_from {
          inner.write_string(circle(a.x, line_y))
          x0 = a.x + dir * CENTRAL_R
        }
        if circle_to {
          inner.write_string(circle(b.x, line_y))
          x1 = b.x - dir * CENTRAL_R
        }
        if bw > 0 {
          // The number sits on the lifeline at the tail of the arrow, past a connection circle if there is one.
          if tail_at_end {
            let cx = if circle_to { x1 - dir * (bw / 2 + 2) } else { x1 }
            inner.write_string(badge(i, cx, line_y, bw))
            x1 = cx - dir * bw / 2
          } else {
            let cx = if circle_from { x0 + dir * (bw / 2 + 2) } else { x0 }
            inner.write_string(badge(i, cx, line_y, bw))
            x0 = cx + dir * bw / 2
          }
        }
        let heads = (if st.at_start {
            head(st.head, x0, line_y, -dir, up * dir)
          } else {
            ""
          }) +
          (if st.at_end {
            head(st.head, x1, line_y, dir, up * dir)
          } else {
            ""
          })
        let from = x0 + (if st.at_start { dir * head_trim } else { 0 })
        let to = x1 - (if st.at_end { dir * head_trim } else { 0 })
        let drawn = inner.to_string()
        inner.reset()
        inner.write_string(
          "<path d=\"M\{n(from)},\{n(line_y)}H\{n(to)}\"\{attrs}/>" +
          heads +
          drawn,
        )
        if label.width > 0 {
          let l = @util.js_min(x0, x1)
          let r = @util.js_max(x0, x1)
          let cx = if align < 0 {
            l + msg_pad + label.width / 2
          } else if align > 0 {
            r - msg_pad - label.width / 2
          } else {
            (l + r) / 2
          }
          widen(cx - label.width / 2, cx + label.width / 2)
          labels_out.write(
            "<g class=\"pele-edge-label\" data-id=\"i\{@svg.esc_text(m.id)}\">",
          )
          write_backed(labels_out, label, cx, line_y - 4 - label.height / 2, "")
          labels_out.write("</g>")
        }
        if creating {
          y = line_y + b.size.h / 2 - 6
        }
      }
      edges_out.write(
        "<g class=\"pele-edge pele-message\" data-id=\"i\{@svg.esc_text(m.id)}\">\{inner}</g>",
      )
      y = @util.js_max(y, line_y)
      if a.destroy_at == i {
        y = @util.js_max(y, destroy(a, line_y))
      }
      if b.destroy_at == i && view.a != view.b {
        y = @util.js_max(y, destroy(b, line_y))
      }
    }
  }
  y += 20
  for col in cols {
    while col.activations.length() > 0 {
      end_activation(col, y) |> ignore
    }
  }
  let mut bottom = y
  if mirror {
    let mut foot_h = 0.0
    for col in cols {
      if col.life_end >= 0 {
        continue
      }
      foot_h = @util.js_max(foot_h, col.size.h)
      write_actor_node(col, y, true)
    }
    bottom = y + foot_h
  }
  let lifelines = @svg.Markup::new()
  for col in cols {
    write_actor_node(col, col.top, false)
    let end = if col.life_end >= 0 { col.life_end } else { y }
    if end > col.life_start {
      lifelines.write("<path class=\"pele-lifeline\" data-id=\"")
      lifelines.write_esc_text(col.id)
      lifelines.write("\" d=\"M\{n(col.x)},\{n(col.life_start)}V\{n(end)}\"/>")
    }
  }
  let boxes_out = @svg.Markup::new()
  for run in runs {
    let x0 = run_left(run)
    let x1 = run_right(run)
    let fill = if run.box.fill == "transparent" {
      ""
    } else {
      @svg.resolve_style(["fill:" + run.box.fill]).shape
    }
    let opacity = if fill != "" { "" } else { " fill-opacity=\"0.5\"" }
    boxes_out.write("<g class=\"pele-cluster pele-box\"")
    if run.box.name is Some(name) && name != "" {
      boxes_out.write(" data-id=\"")
      boxes_out.write_esc_text(name)
      boxes_out.write("\"")
    }
    boxes_out.write(
      "><rect x=\"\{n(x0)}\" y=\"0\" width=\"\{n(x1 - x0)}\" height=\"\{n(bottom + box_pad)}\" fill=\"var(--_a)\" stroke=\"var(--_b)\"\{@svg.rounded(opacity + fill)}/>",
    )
    @svg.write_label(
      boxes_out,
      run.title,
      (x0 + x1) / 2,
      box_pad / 2 + 2 + run.title.height / 2,
      " class=\"pele-cluster-label\" fill=\"var(--_m)\"",
      icons?=options.icons,
    )
    boxes_out.write("</g>")
  }
  if runs.length() > 0 {
    bottom += box_pad
  }
  let mut min_y = 0.0
  let title_out = @svg.Markup::new()
  let room = @common.title_room(options)
  let plain_title = @svg.title_label(
    db.title,
    measurer,
    size,
    if tight {
      room
    } else {
      infinity
    },
  )
  let title = if tight {
    @common.break_label(plain_title, measurer, @util.js_max(120, room))
  } else {
    plain_title
  }
  if min_x > max_x {
    widen(0, @util.js_max(title.width, 40))
  }
  if title.width > 0 {
    let cx = (min_x + max_x) / 2
    widen(cx - title.width / 2, cx + title.width / 2)
    min_y = -title.height - 12
    @svg.write_label(
      title_out,
      title,
      cx,
      min_y + title.height / 2,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
      icons?=options.icons,
    )
  }
  let width = (max_x - min_x + 2 * pad).ceil()
  if grown && options.max_width is Some(max_width) && width > max_width {
    // Retry with space for activation notes and rounding.
    return draw(
      db,
      config,
      options,
      tight,
      hold=if hold > 0 { infinity } else { width - max_width.floor() },
    )
  }
  let height = (bottom - min_y + 2 * pad).ceil()
  let content = @svg.Markup::new()
  content.write(
    "<g transform=\"translate(\{n(pad - min_x)},\{n(pad - min_y)})\">",
  )
  content.write_markup(title_out)
  fn group(open : String, body : @svg.Markup) -> Unit {
    if !body.is_empty() {
      content.write_group(open, body, "</g>")
    }
  }

  fn reversed_markup(pieces : Array[@svg.Markup]) -> @svg.Markup {
    let out = @svg.Markup::new()
    for piece in pieces.rev_iter() {
      out.write_markup(piece)
    }
    out
  }

  group("<g class=\"pele-boxes\" font-size=\"\{small}\">", boxes_out)
  group(
    "<g class=\"pele-rects\" fill=\"var(--_a)\">",
    reversed_markup(rects_out),
  )
  group(
    "<g class=\"pele-lifelines\" fill=\"none\" stroke=\"var(--_b)\">", lifelines,
  )
  group(
    "<g class=\"pele-activations\" fill=\"var(--_s)\" stroke=\"var(--_b)\">",
    reversed_markup(activations_out),
  )
  group(
    "<g class=\"pele-frames\" font-size=\"\{small}\" stroke=\"var(--_b)\">",
    frames_out,
  )
  group(
    "<g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\">",
    edges_out,
  )
  group(
    "<g class=\"pele-destroys\" fill=\"none\" stroke=\"var(--_l)\" stroke-width=\"1.5\" stroke-linecap=\"round\">",
    crosses_out,
  )
  let labels_family = if monospaced {
    " font-family=\"\{FONT_MONO}\""
  } else {
    ""
  }
  group(
    "<g class=\"pele-edge-labels\" font-size=\"\{small}\"\{labels_family}>",
    labels_out,
  )
  group(
    "<g class=\"pele-notes\" font-size=\"\{small}\" fill=\"var(--_a)\" stroke=\"var(--_b)\">",
    notes_out,
  )
  group("<g class=\"pele-nodes\">", actors_out)
  content.write("</g>")
  let svg = @svg.markup_document(
    "sequence",
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
