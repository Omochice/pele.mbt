///|
const RAIL_GAP : Double = 8

///|
const CARD_MIN : Double = 120

///|
const ARROW_ROOM : Double = 20

///|
priv struct Card {
  y : Double
  h : Double
  w : Double
  index : Int32
  lane : Double
}

///|
fn label_rows(label : @text.Label) -> Array[String] {
  label.lines.map(line => line.map(span => span.text).join(""))
}

///|
/// The run of cards a relation skips, which decides the rail it takes.
priv struct Run {
  target : String
  mut from : Int32
  mut to : Int32
}

///|
/// Draws an event model down, one card per frame under the heading of its lane, in the width the host has.
fn draw_down(
  model : EventModelingModel,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.875).round()
  let mono = (size * 0.75).round()
  let pad = options.padding.unwrap_or(8)
  let measurer = options.text_measurer()
  let room = @util.js_max(160, options.max_width.unwrap_or(320) - 2.0 * pad)
  // A relation that skips a card runs down a rail beside the cards.
  // Relations into one card share a rail; others whose runs overlap take the next rail out, so that no two follow the same line.
  let order : Map[String, Int32] = Map([])
  for index, box in model.boxes {
    order[box.id] = index
  }
  let run_of : Map[String, Run] = Map([])
  let runs : Array[Run] = []
  // A relation between neighbouring cards passes the lower card's lane heading.
  let passed : Map[String, Unit] = Map([])
  for relation in model.relations {
    guard order.get(relation.source.id) is Some(s) &&
      order.get(relation.target.id) is Some(t) else {
      continue
    }
    if s == t {
      continue
    }
    if (s - t).abs() < 2 {
      passed[model.boxes[@cmp.maximum(s, t)].id] = ()
      continue
    }
    match run_of.get(relation.target.id) {
      Some(run) => {
        run.from = @cmp.minimum(run.from, s)
        run.to = @cmp.maximum(run.to, s)
      }
      None => {
        let run = {
          target: relation.target.id,
          from: @cmp.minimum(s, t),
          to: @cmp.maximum(s, t),
        }
        run_of[relation.target.id] = run
        runs.push(run)
      }
    }
  }
  let sorted = Array::makei(runs.length(), i => i)
  sorted.sort_by((a, b) => {
    let by_from = runs[a].from.compare(runs[b].from)
    if by_from != 0 {
      by_from
    } else {
      a.compare(b)
    }
  })
  let rail_of : Map[String, Int32] = Map([])
  let rail_ends : Array[Int32] = []
  for i in sorted {
    let run = runs[i]
    let mut rail = -1
    for k, end in rail_ends {
      if end < run.from {
        rail = k
        break
      }
    }
    if rail < 0 {
      rail = rail_ends.length()
      rail_ends.push(run.to)
    } else {
      rail_ends[rail] = run.to
    }
    rail_of[run.target] = rail
  }
  let gutter = 24.0 +
    RAIL_GAP * @cmp.maximum(0, rail_ends.length() - 1).to_double()
  // Rails are never shared to save room: past what the width allows, the drawing is wider.
  let card_width = @util.js_max(CARD_MIN, room - gutter)
  let text_room = card_width - 2.0 * BOX_PAD_X
  let title = @text.layout_label(
    model.title,
    false,
    measurer,
    size,
    room,
    base=@text.STYLE_BOLD,
  )
  let mut y = pad + (if title.height > 0 { title.height + 12 } else { 0 })
  let mut bottom = pad + title.height
  let mut width = @util.js_max(title.width, card_width + gutter)
  let nodes = @svg.Markup::new()
  let edges = @svg.Markup::new()
  let cards = @svg.Markup::new()
  let placed : Map[String, Card] = Map([])
  let text = (raw : String, font_size : Double, style : Int32) => {
    @common.literal_label(
      @text.decode_entities(raw),
      measurer,
      font_size,
      text_room,
      style~,
    )
  }
  for index, box in model.boxes {
    let lane_room = if passed.contains(box.id) {
      text_room - ARROW_ROOM
    } else {
      text_room
    }
    let lane = @common.break_label(
      @text.layout_label(
        Some(box.lane.label),
        false,
        measurer,
        small,
        lane_room,
        base=@text.STYLE_BOLD,
      ),
      measurer,
      lane_room,
    )
    let name = @text.layout_label(
      Some(box.name),
      false,
      measurer,
      small,
      text_room - 36,
      base=@text.STYLE_BOLD,
    )
    let data = match box.data {
      Some(raw) if raw != "" => Some(text(raw, mono, @text.STYLE_MONO))
      _ => None
    }
    let data_width = match data {
      Some(data) => data.width
      None => 0.0
    }
    let w = @util.js_max(
      @util.js_max(card_width, lane.width + 2.0 * BOX_PAD_X),
      @util.js_max(
        name.width + 2.0 * BOX_PAD_X + 36,
        data_width + 2.0 * BOX_PAD_X,
      ),
    )
    let head_h = lane.height + 12
    let h = 2.0 * BOX_PAD_Y +
      name.height +
      (match data {
        Some(data) => data.height + 6
        None => 0
      })
    let cy = y + head_h
    let frame = "x=\"\{@svg.num(pad)}\" y=\"\{@svg.num(cy)}\" width=\"\{@svg.num(w)}\" height=\"\{@svg.num(h)}\""
    let overlay = match series_of(box.kind) {
      None => ""
      Some(series) =>
        "<rect \{frame} fill=\"\{@svg.series_color(series)}\" fill-opacity=\"0.22\" stroke=\"\{@svg.series_color(series)}\"\{@svg.ROUNDED}/>"
    }
    nodes.write("<g class=\"pele-cluster pele-em-lane\" data-id=\"")
    @svg.write_esc_text(nodes, box.lane.label)
    nodes.write("\">")
    @common.write_left_label(
      nodes,
      lane,
      pad + BOX_PAD_X,
      y,
      " class=\"pele-cluster-label\" font-size=\"\{@svg.num(small)}\" font-weight=\"var(--_hw)\" fill=\"var(--_m)\"",
    )
    nodes.write(
      "<g class=\"pele-node pele-em-\{kind_class(box.kind)}\{if box.reset { " pele-em-reset" } else { "" }}\" data-id=\"\{@svg.esc_text(box.id)}\"><rect \{frame} fill=\"var(--_bg)\" stroke=\"var(--_b)\"\{@svg.ROUNDED}/>" +
      overlay,
    )
    @svg.write_label(
      nodes,
      name,
      pad + BOX_PAD_X + name.width / 2,
      cy + BOX_PAD_Y + name.height / 2,
      " class=\"pele-label\" font-size=\"\{@svg.num(small)}\" font-weight=\"var(--_hw)\"",
    )
    nodes.write(
      "<text class=\"pele-em-frame\" x=\"\{@svg.num(pad + w - BOX_PAD_X)}\" y=\"\{@svg.num(cy + BOX_PAD_Y + small)}\" text-anchor=\"end\" font-size=\"\{@svg.num(mono)}\" fill=\"var(--_m)\">\{@svg.esc(box.id)}</text>",
    )
    if data is Some(data) {
      write_lines(
        nodes,
        label_rows(data),
        pad + BOX_PAD_X,
        cy + BOX_PAD_Y + name.height + 6 + data.line_height / 2 + mono * 0.35,
        data.line_height,
        " class=\"pele-em-data\" font-family=\"\{FONT_MONO}\" font-size=\"\{@svg.num(mono)}\"",
      )
    }
    nodes.write("</g></g>")
    placed[box.id] = { y: cy, h, w, index, lane: lane.width, }
    width = @util.js_max(width, w + gutter)
    bottom = cy + h
    y = bottom + 28
  }
  let trim = @svg.marker_trim("arrow_point")
  for relation in model.relations {
    guard placed.get(relation.source.id) is Some(s) &&
      placed.get(relation.target.id) is Some(t) else {
      continue
    }
    if relation.source.id == relation.target.id {
      continue
    }
    let down = t.y > s.y
    let dir = if down { 1.0 } else { -1.0 }
    let sy = if down { s.y + s.h } else { s.y }
    let ty = if down { t.y } else { t.y + t.h }
    let (d, head) = if (s.index - t.index).abs() == 1 {
      // The lower card's lane heading sits in the gap, and wraps to leave the arrow room beside it.
      let lower = if down { t } else { s }
      let cx = pad +
        @util.js_max(@util.js_min(s.w, t.w) / 2, BOX_PAD_X + lower.lane + 16)
      (
        "M\{@svg.num(cx)},\{@svg.num(sy)}V\{@svg.num(ty - dir * trim)}",
        @svg.marker("arrow_point", cx, ty, 0, dir, "var(--_l)"),
      )
    } else {
      let rail = pad +
        width -
        gutter +
        12 +
        RAIL_GAP * rail_of.get(relation.target.id).unwrap_or(0).to_double()
      // A card can send one relation and receive another: they leave above and arrive below its middle.
      let from = s.y + s.h / 2 - 5
      let to = t.y + t.h / 2 + 5
      (
        "M\{@svg.num(pad + s.w)},\{@svg.num(from)}H\{@svg.num(rail)}V\{@svg.num(to)}H\{@svg.num(pad + t.w + trim)}",
        @svg.marker("arrow_point", pad + t.w, to, -1, 0, "var(--_l)"),
      )
    }
    edges.write(
      "<g class=\"pele-edge\" data-id=\"\{@svg.esc_text(relation.source.id)}-\{@svg.esc_text(relation.target.id)}\"><path d=\"\{d}\" fill=\"none\" stroke=\"var(--_l)\"/>\{head}</g>",
    )
  }
  let names = frame_names(model)
  fn card(
    kind : String,
    heading : String,
    frame : String,
    raw : String,
  ) -> Unit raise @errors.PeleError {
    let named = match names.get(frame) {
      Some(name) => " " + name
      None => ""
    }
    let head = @text.layout_label(
      Some("\{heading} · \{frame}\{named}"),
      false,
      measurer,
      small,
      text_room,
      base=@text.STYLE_BOLD,
    )
    let body = text(raw, small, 0)
    let w = @util.js_max(
      card_width,
      @util.js_max(head.width + 2.0 * BOX_PAD_X, body.width + 2.0 * BOX_PAD_X),
    )
    let h = 2.0 * BOX_PAD_Y + head.height + body.height
    cards.write(
      "<g class=\"pele-em-\{kind}\" data-id=\"\{@svg.esc_text(frame)}\"><rect x=\"\{@svg.num(pad)}\" y=\"\{@svg.num(y)}\" width=\"\{@svg.num(w)}\" height=\"\{@svg.num(h)}\" fill=\"var(--_bg)\" stroke=\"var(--_b)\"\{@svg.ROUNDED}/>",
    )
    @svg.write_label(
      cards,
      head,
      pad + BOX_PAD_X + head.width / 2,
      y + BOX_PAD_Y + head.height / 2,
      " font-size=\"\{@svg.num(small)}\" font-weight=\"var(--_hw)\"",
    )
    write_lines(
      cards,
      label_rows(body),
      pad + BOX_PAD_X,
      y + BOX_PAD_Y + head.height + body.line_height / 2 + small * 0.35,
      body.line_height,
      " font-size=\"\{@svg.num(small)}\"",
    )
    cards.write("</g>")
    bottom = y + h
    y = bottom + CARD_GAP
    width = @util.js_max(width, w)
  }
  for note in model.notes {
    card("note", "Note", note.frame, note.text)
  }
  for spec in model.specifications {
    card(
      "specification",
      "Given / When / Then",
      spec.frame,
      specification_rows(spec).join("\n"),
    )
  }
  let total_width = (width + 2.0 * pad).ceil()
  let height = (bottom + pad).ceil()
  let content = @svg.Markup::new()
  content.write(
    @svg.label_svg(
      title,
      total_width / 2,
      pad + title.height / 2,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
    ),
  )
  content.write_markup(edges)
  content.write_markup(nodes)
  content.write_markup(cards)
  {
    svg: @svg.markup_document(
      "eventmodeling",
      total_width,
      height,
      size,
      options,
      model.acc_title,
      model.acc_descr,
      content,
    ),
    width: total_width,
    height,
    links: [],
  }
}
