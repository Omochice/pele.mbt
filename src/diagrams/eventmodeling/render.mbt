///|
const FONT_MONO : String = "var(--_fm)"

///|
const BOX_PAD_X : Double = 12

///|
const BOX_PAD_Y : Double = 10

///|
const BOX_MIN_WIDTH : Double = 96

///|
const BOX_GAP : Double = 16

///|
const STAGGER : Double = 80

///|
const LANE_PAD : Double = 12

///|
const LANE_GAP : Double = 8

///|
const DATA_COLUMNS : Int32 = 48

///|
const NOTE_COLUMNS : Int32 = 80

///|
const CARD_GAP : Double = 8

///|
/// The series slot of each kind of entity.
/// A UI has none and is drawn plain.
fn series_of(kind : EntityKind) -> Int32? {
  match kind {
    Command => Some(0)
    Event => Some(1)
    ReadModel => Some(2)
    Processor => Some(6)
    Ui => None
  }
}

///|
fn kind_class(kind : EntityKind) -> String {
  match kind {
    Ui => "ui"
    Processor => "processor"
    Command => "command"
    ReadModel => "readmodel"
    Event => "event"
  }
}

///|
priv struct Placed {
  box : EmBox
  name : @text.Label
  data : Array[String]
  mut x : Double
  mut y : Double
  w : Double
  h : Double
}

///|
priv struct Band {
  lane : EmLane
  label : @text.Label
  mut right : Double
  mut y : Double
  mut h : Double
}

///|
/// Splits text into lines of at most `columns` characters, keeping its own line breaks.
fn hard_wrap(text : String, columns : Int32) -> Array[String] {
  let out = []
  for line in split_lines(@text.decode_entities(text)) {
    if line.length() <= columns {
      out.push(line)
      continue
    }
    let mut i = 0
    while i < line.length() {
      out.push(
        @util.slice(line, i, end=@cmp.minimum(i + columns, line.length())),
      )
      i += columns
    }
  }
  out
}

///|
fn lines(
  rows : Array[String],
  x : Double,
  y : Double,
  step : Double,
  attrs : String,
) -> String {
  let body = StringBuilder()
  for i, row in rows {
    if row != "" {
      body.write_string(
        "<tspan x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y + i.to_double() * step)}\">\{@svg.esc(row)}</tspan>",
      )
    }
  }
  let body = body.to_string()
  if body == "" {
    ""
  } else {
    "<text\{attrs} xml:space=\"preserve\">\{body}</text>"
  }
}

///|
fn frame_names(model : EventModelingModel) -> Map[String, String] {
  let names = Map([])
  for box in model.boxes {
    names[box.id] = box.name
  }
  names
}

///|
fn specification_rows(spec : EmSpecification) -> Array[String] {
  let rows = ["Given  \{spec.given.join(", ")}"]
  if spec.when_.length() > 0 {
    rows.push("When  \{spec.when_.join(", ")}")
  }
  rows.push("Then  \{spec.then_.join(", ")}")
  rows
}

///|
/// Draws an event model as SVG, lanes across with time running to the right or, when the host's width asks for it, down.
pub fn render_event_model(
  model : EventModelingModel,
  _config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  @common.turn_to_fit(options, down => {
    if down {
      draw_down(model, options)
    } else {
      draw_across(model, options)
    }
  })
}

///|
fn draw_across(
  model : EventModelingModel,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  let size = options.font_size.unwrap_or(16)
  let name_size = (size * 0.875).round()
  let small = (size * 0.8125).round()
  let mono = (size * 0.75).round()
  let mono_step = (mono * 1.4).round()
  let small_step = (small * 1.5).round()
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let widest = (rows : Array[String], font_size : Double, style : Int32) => {
    let mut width = 0.0
    for row in rows {
      width = @util.js_max(width, measurer.width(row, font_size, style))
    }
    width
  }

  let bands : Array[Band] = []
  let band_of : Map[String, Band] = Map([])
  let mut label_column = 0.0
  for lane in model.lanes {
    let label = @text.layout_label(
      Some(lane.label),
      false,
      measurer,
      small,
      4000,
      base=@text.STYLE_BOLD,
    )
    label_column = @util.js_max(label_column, label.width)
    let band = { lane, label, right: @double.neg_infinity, y: 0, h: 0, }
    bands.push(band)
    band_of[lane.key] = band
  }
  label_column += 2.0 * LANE_PAD

  // Time runs left to right.
  // A frame in a new lane starts under the end of the one before it, so the arrow between them can drop straight down; a frame in the same lane follows on.
  let placed : Array[Placed] = []
  let by_box : Map[String, Placed] = Map([])
  let mut previous : Placed? = None
  for box in model.boxes {
    let band = band_of[box.lane.key]
    let name = @text.layout_label(
      Some(box.name),
      false,
      measurer,
      name_size,
      4000,
      base=@text.STYLE_BOLD,
    )
    let data = match box.data {
      Some(text) if text != "" => hard_wrap(text, DATA_COLUMNS)
      _ => []
    }
    let w = @util.js_max(
      BOX_MIN_WIDTH,
      @util.js_max(name.width, widest(data, mono, @text.STYLE_MONO)) +
      2.0 * BOX_PAD_X,
    )
    let h = 2.0 * BOX_PAD_Y +
      name.height +
      (if data.length() > 0 {
        6 + data.length().to_double() * mono_step
      } else {
        0
      })
    let x = match previous {
      None => 0.0
      Some(previous) => {
        let stagger = previous.x +
          @util.js_max(previous.w / 2, previous.w - STAGGER)
        if previous.box.lane.key == box.lane.key {
          band.right + BOX_GAP
        } else {
          @util.js_max(stagger, band.right + BOX_GAP)
        }
      }
    }
    let item : Placed = { box, name, data, x, y: 0, w, h, }
    band.right = x + w
    band.h = @util.js_max(band.h, h)
    placed.push(item)
    by_box[box.id] = item
    previous = Some(item)
  }

  let mut content_right = 0.0
  for item in placed {
    content_right = @util.js_max(content_right, item.x + item.w)
  }
  let lane_width = label_column + content_right + LANE_PAD

  let title = @text.layout_label(
    model.title,
    false,
    measurer,
    size,
    4000,
    base=@text.STYLE_BOLD,
  )
  let title_height = if title.height > 0 { title.height + 12 } else { 0 }
  let left = pad
  let top = pad + title_height

  let mut y = top
  let lanes = @svg.Markup::new()
  for band in bands {
    band.y = y
    band.h += 2.0 * LANE_PAD
    lanes.write(
      "<g class=\"pele-cluster pele-em-lane\" data-id=\"\{@svg.esc_text(band.lane.label)}\">" +
      "<rect x=\"\{@svg.num(left)}\" y=\"\{@svg.num(y)}\" width=\"\{@svg.num(lane_width)}\" height=\"\{@svg.num(band.h)}\" fill=\"var(--_s)\"\{@svg.ROUNDED}/>" +
      @svg.label_svg(
        band.label,
        left + LANE_PAD + band.label.width / 2,
        y + band.h / 2,
        " class=\"pele-cluster-label\" font-size=\"\{@svg.num(small)}\" font-weight=\"var(--_hw)\" fill=\"var(--_m)\"",
      ) +
      "</g>",
    )
    y += band.h + LANE_GAP
  }
  let mut bottom = if bands.length() > 0 { y - LANE_GAP } else { top }

  let nodes = @svg.Markup::new()
  for item in placed {
    let band = band_of[item.box.lane.key]
    item.x += left + label_column
    item.y = band.y + (band.h - item.h) / 2
    let frame = "x=\"\{@svg.num(item.x)}\" y=\"\{@svg.num(item.y)}\" width=\"\{@svg.num(item.w)}\" height=\"\{@svg.num(item.h)}\""
    let shape = match series_of(item.box.kind) {
      None =>
        "<rect \{frame} fill=\"var(--_bg)\" stroke=\"var(--_b)\"\{@svg.ROUNDED}/>"
      Some(series) =>
        "<rect \{frame} fill=\"var(--_bg)\"\{@svg.ROUNDED}/><rect \{frame} fill=\"\{@svg.series_color(series)}\" fill-opacity=\"0.22\" stroke=\"\{@svg.series_color(series)}\"\{@svg.ROUNDED}/>"
    }
    let name_y = item.y + BOX_PAD_Y + item.name.height / 2
    let text = @svg.label_svg(
        item.name,
        item.x + item.w / 2,
        name_y,
        " class=\"pele-label\" font-size=\"\{@svg.num(name_size)}\" font-weight=\"var(--_hw)\"",
      ) +
      lines(
        item.data,
        item.x + BOX_PAD_X,
        item.y + BOX_PAD_Y + item.name.height + 6 + mono_step / 2 + mono * 0.35,
        mono_step,
        " class=\"pele-em-data\" font-family=\"\{FONT_MONO}\" font-size=\"\{@svg.num(mono)}\"",
      )
    nodes.write(
      "<g class=\"pele-node pele-em-\{kind_class(item.box.kind)}\{if item.box.reset { " pele-em-reset" } else { "" }}\" data-id=\"\{@svg.esc_text(item.box.id)}\">\{shape}\{text}</g>",
    )
  }

  let edges = @svg.Markup::new()
  let trim = @svg.marker_trim("arrow_point")
  for relation in model.relations {
    guard by_box.get(relation.source.id) is Some(s) &&
      by_box.get(relation.target.id) is Some(t) else {
      continue
    }
    if s.box.id == t.box.id {
      continue
    }
    let (d, head) = if s.box.lane.key == t.box.lane.key {
      // Along the lane, from the side of one box to the side of the other.
      let forward = t.x >= s.x
      let sx = if forward { s.x + s.w } else { s.x }
      let tx = if forward { t.x } else { t.x + t.w }
      let sy = s.y + s.h / 2
      let ty = t.y + t.h / 2
      let dir = if tx >= sx { 1.0 } else { -1.0 }
      (
        "M\{@svg.num(sx)},\{@svg.num(sy)}L\{@svg.num(tx - dir * trim)},\{@svg.num(ty)}",
        @svg.marker("arrow_point", tx, ty, dir, 0, "var(--_l)"),
      )
    } else {
      // Between lanes, straight down or up where the boxes overlap, else in an S.
      let down = t.y > s.y
      let from = @util.js_max(s.x, t.x)
      let to = @util.js_min(s.x + s.w, t.x + t.w)
      let inset = (w : Double) => @util.js_min(24, w / 4)
      let overlap = to - from >= 16
      let sx = if overlap {
        (from + to) / 2
      } else if t.x > s.x {
        s.x + s.w - inset(s.w)
      } else {
        s.x + inset(s.w)
      }
      let tx = if overlap {
        sx
      } else if t.x > s.x {
        t.x + inset(t.w)
      } else {
        t.x + t.w - inset(t.w)
      }
      let sy = if down { s.y + s.h } else { s.y }
      let ty = if down { t.y } else { t.y + t.h }
      let dir = if down { 1.0 } else { -1.0 }
      let end = ty - dir * trim
      let mid = (sy + end) / 2
      let d = if sx == tx {
        "M\{@svg.num(sx)},\{@svg.num(sy)}V\{@svg.num(end)}"
      } else {
        "M\{@svg.num(sx)},\{@svg.num(sy)}C\{@svg.num(sx)},\{@svg.num(mid)} \{@svg.num(tx)},\{@svg.num(mid)} \{@svg.num(tx)},\{@svg.num(end)}"
      }
      (d, @svg.marker("arrow_point", tx, ty, 0, dir, "var(--_l)"))
    }
    edges.write(
      "<g class=\"pele-edge\" data-id=\"\{@svg.esc_text(relation.source.id)}-\{@svg.esc_text(relation.target.id)}\"><path d=\"\{d}\" fill=\"none\" stroke=\"var(--_l)\"/>\{head}</g>",
    )
  }

  // Notes and given/when/then specifications are listed under the lanes with the frame they belong to.
  let names = frame_names(model)
  let cards = @svg.Markup::new()
  let mut any_card = false
  let mut cards_right = 0.0
  let card = (
    kind : String,
    heading : String,
    frame : String,
    rows : Array[String],
  ) => {
    let named = match names.get(frame) {
      Some(name) => " " + name
      None => ""
    }
    let head = @text.layout_label(
      Some("\{heading} · \{frame}\{named}"),
      false,
      measurer,
      small,
      4000,
      base=@text.STYLE_BOLD,
    )
    let w = @util.js_max(head.width, widest(rows, small, 0)) + 2.0 * BOX_PAD_X
    let h = 2.0 * BOX_PAD_Y +
      head.height +
      rows.length().to_double() * small_step
    let cy = bottom + (if !any_card && bands.is_empty() { 0 } else { CARD_GAP })
    any_card = true
    cards.write(
      "<g class=\"pele-em-\{kind}\" data-id=\"\{@svg.esc_text(frame)}\">" +
      "<rect x=\"\{@svg.num(left)}\" y=\"\{@svg.num(cy)}\" width=\"\{@svg.num(w)}\" height=\"\{@svg.num(h)}\" fill=\"var(--_bg)\" stroke=\"var(--_b)\"\{@svg.ROUNDED}/>" +
      @svg.label_svg(
        head,
        left + BOX_PAD_X + head.width / 2,
        cy + BOX_PAD_Y + head.height / 2,
        " font-size=\"\{@svg.num(small)}\" font-weight=\"var(--_hw)\"",
      ) +
      lines(
        rows,
        left + BOX_PAD_X,
        cy + BOX_PAD_Y + head.height + small_step / 2 + small * 0.35,
        small_step,
        " font-size=\"\{@svg.num(small)}\"",
      ) +
      "</g>",
    )
    bottom = cy + h
    cards_right = @util.js_max(cards_right, w)
  }
  for note in model.notes {
    card("note", "Note", note.frame, hard_wrap(note.text, NOTE_COLUMNS))
  }
  for spec in model.specifications {
    let rows = []
    for row in specification_rows(spec) {
      rows.append(hard_wrap(row, NOTE_COLUMNS))
    }
    card("specification", "Given / When / Then", spec.frame, rows)
  }

  let width = @util.js_max(
    @util.js_max(if bands.length() > 0 { lane_width } else { 0 }, cards_right),
    title.width,
  )
  let total_width = (width + 2 * pad).ceil()
  let total_height = (bottom + pad).ceil()
  let content = @svg.Markup::new()
  content.write(
    @svg.label_svg(
      title,
      total_width / 2,
      pad + title.height / 2,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
    ),
  )
  content.write_markup(lanes)
  content.write_markup(edges)
  content.write_markup(nodes)
  content.write_markup(cards)
  {
    svg: @svg.markup_document(
      "eventmodeling",
      total_width,
      total_height,
      size,
      options,
      model.acc_title,
      model.acc_descr,
      content,
    ),
    width: total_width,
    height: total_height,
    links: [],
  }
}
