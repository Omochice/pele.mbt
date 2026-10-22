///|
/// The domain, its column and row among the four quadrants, and its series color.
priv struct Quadrant {
  name : String
  column : Int32
  row : Int32
  color : Int32
}

///|
let quadrants : Array[Quadrant] = [
  { name: "complex", column: 0, row: 0, color: 0, },
  { name: "complicated", column: 1, row: 0, color: 1, },
  { name: "chaotic", column: 0, row: 1, color: 3, },
  { name: "clear", column: 1, row: 1, color: 2, },
]

///|
const CONFUSION_COLOR : Int32 = 4

///|
/// The heading, the decision model and the kind of practice of a domain.
fn meta(name : String) -> (String, String, String) {
  match name {
    "complex" =>
      ("Complex", "Probe → Sense → Respond", "Emergent Practices")
    "complicated" =>
      ("Complicated", "Sense → Analyse → Respond", "Good Practices")
    "clear" => ("Clear", "Sense → Categorise → Respond", "Best Practices")
    "chaotic" => ("Chaotic", "Act → Sense → Respond", "Novel Practices")
    _ => ("Confusion", "", "Disorder")
  }
}

///|
const MAX_CONFUSION_ITEMS : Int32 = 3

///|
const ITEM_MAX_WIDTH : Double = 200

///|
const ITEM_PAD_X : Double = 10

///|
const ITEM_PAD_Y : Double = 4

///|
const ITEM_GAP : Double = 6

///|
const HEAD_GAP : Double = 10

///|
const MARGIN : Double = 20

///|
const CLEARANCE : Double = 10

///|
priv struct Badge {
  text : String
  label : @text.Label
  w : Double
  h : Double
  overflow : Bool
}

///|
priv struct Block {
  name : String
  title : @text.Label
  subtitles : Array[@text.Label]
  badges : Array[Badge]
  w : Double
  h : Double
  mut cx : Double
  mut cy : Double
}

///|
fn section(config : @types.Config) -> Map[String, Json]? {
  match config.get("cynefin") {
    Some(Object(section)) => Some(section)
    _ => None
  }
}

///|
fn setting(
  config : @types.Config,
  key : String,
  fallback : Double,
  min : Double,
  max : Double,
) -> Double {
  guard section(config) is Some(values) else { return fallback }
  match values.get(key) {
    Some(Number(value, ..)) if value >= min && value <= max => value
    _ => fallback
  }
}

///|
fn or_one(length : Double) -> Double {
  if length == 0 || length.is_nan() {
    1
  } else {
    length
  }
}

///|
fn render_cynefin(
  model : CynefinModel,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered {
  let num = @svg.num
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.8125).round()
  let item_size = (size * 0.875).round()
  let measurer = @text.metrics_measurer
  let pad = options.padding.unwrap_or(8)
  let show_descriptions = match section(config) {
    Some(values) =>
      match values.get("showDomainDescriptions") {
        Some(False) => false
        _ => true
      }
    None => true
  }
  let amplitude = setting(config, "boundaryAmplitude", 8, 0, 50)
  let seed = resolve_seed(
    Some(setting(config, "seed", 0, -1.0e15, 1.0e15)),
    options.id_prefix.unwrap_or("pele"),
  )
  let item_line = (item_size * 1.5).round()
  let badge = (text : String, overflow : Bool) => {
    let label = @text.layout_label(
      Some(text),
      false,
      measurer,
      item_size,
      ITEM_MAX_WIDTH,
    )
    {
      text,
      label,
      w: label.width + 2.0 * ITEM_PAD_X,
      h: @util.js_max(label.height, item_line) + 2.0 * ITEM_PAD_Y,
      overflow,
    }
  }
  let block = (name : String) => {
    let (heading, decision, practice) = meta(name)
    let title = @text.layout_label(
      Some(heading),
      false,
      measurer,
      size,
      4000,
      base=@text.STYLE_BOLD,
    )
    let subtitles = []
    if show_descriptions {
      for text in [decision, practice] {
        if text != "" {
          subtitles.push(
            @text.layout_label(
              Some(text),
              false,
              measurer,
              small,
              4000,
              base=@text.STYLE_ITALIC,
            ),
          )
        }
      }
    }
    let items = model.domains.get(name).unwrap_or([])
    let shown = if name == "confusion" && items.length() > MAX_CONFUSION_ITEMS {
      MAX_CONFUSION_ITEMS
    } else {
      items.length()
    }
    let badges = []
    for i in 0..<shown {
      badges.push(badge(items[i], false))
    }
    if shown < items.length() {
      badges.push(badge("+\{items.length() - shown} more", true))
    }
    let mut w = title.width
    let mut h = title.height
    for s in subtitles {
      w = @util.js_max(w, s.width)
      h += s.height
    }
    if badges.length() > 0 {
      h += HEAD_GAP - ITEM_GAP
    }
    for b in badges {
      w = @util.js_max(w, b.w)
      h += ITEM_GAP + b.h
    }
    { name, title, subtitles, badges, w, h, cx: 0, cy: 0, }
  }
  let blocks = quadrants.map(q => block(q.name))
  let confusion = block("confusion")
  let rx = @util.js_max(88, confusion.w * 0.71 + 8)
  let ry = @util.js_max(64, confusion.h * 0.71 + 6)
  let mut quad_w = setting(config, "width", 640, 100, 10000) / 2
  let mut quad_h = setting(config, "height", 440, 100, 10000) / 2
  for b in blocks {
    quad_w = @util.js_max(quad_w, b.w + 2.0 * MARGIN)
    quad_h = @util.js_max(quad_h, b.h + 2.0 * MARGIN)
  }
  // A block sits in the middle of its quadrant, so its inner corner must stay clear of the ellipse.
  for b in blocks {
    let dx = (quad_w - b.w) / 2
    let dy = (quad_h - b.h) / 2
    let ex = dx / (rx + CLEARANCE)
    let ey = dy / (ry + CLEARANCE)
    if ex * ex + ey * ey >= 1 {
      continue
    }
    let wider = b.w + 2.0 * (rx + CLEARANCE)
    let taller = b.h + 2.0 * (ry + CLEARANCE)
    if wider * quad_h <= quad_w * taller {
      quad_w = @util.js_max(quad_w, wider)
    } else {
      quad_h = @util.js_max(quad_h, taller)
    }
  }
  let title = @text.layout_label(
    model.title,
    false,
    measurer,
    size,
    4000,
    base=@text.STYLE_BOLD,
  )
  let title_height = if title.height > 0 { title.height + 12 } else { 0 }
  let width = 2.0 * quad_w
  let height = 2.0 * quad_h
  let x0 = pad
  let y0 = pad + title_height
  let cx = x0 + quad_w
  let cy = y0 + quad_h
  let right = x0 + width
  let bottom = y0 + height
  let north = wave(y0, cy, cx, seed, amplitude, {
    ..fold,
    segments: 4,
    pin_end: true,
  })
  let west = wave(x0, cx, cy, seed + 100, amplitude, {
    ..horizon,
    segments: 4,
    pin_end: true,
  })
  let east = wave(cx, right, cy, seed + 200, amplitude, {
    ..horizon,
    segments: 4,
    pin_start: true,
  })
  let drop = cliff(cx, cy, bottom, width * 0.03)
  let at = (curve : Array[Double], end : Bool) => {
    if end {
      "\{num(curve[curve.length() - 2])},\{num(curve[curve.length() - 1])}"
    } else {
      "\{num(curve[0])},\{num(curve[1])}"
    }
  }
  let regions = {
    "complex": "M\{num(x0)},\{num(y0)}L\{at(north, false)}\{forward(north)}\{backward(west)}Z",
    "complicated": "M\{at(north, false)}L\{num(right)},\{num(y0)}L\{at(east, true)}\{backward(east)}\{backward(north)}Z",
    "chaotic": "M\{at(west, false)}\{forward(west)}\{forward(drop)}L\{num(x0)},\{num(bottom)}Z",
    "clear": "M\{at(east, false)}\{forward(east)}L\{num(right)},\{num(bottom)}L\{at(drop, true)}\{backward(drop)}Z",
  }
  let fills = StringBuilder()
  for q in quadrants {
    fills.write_string(
      "<path class=\"pele-cynefin-region\" data-id=\"\{q.name}\" d=\"\{regions[q.name]}\" fill=\"\{@svg.series_color(q.color)}\" fill-opacity=\"0.14\"/>",
    )
  }
  let boundaries = "<g class=\"pele-cynefin-boundaries\" fill=\"none\" stroke=\"var(--_b)\" stroke-dasharray=\"6 3\">" +
    "<path d=\"\{curve_path(north)}\"/><path d=\"\{curve_path(west)}\"/><path d=\"\{curve_path(east)}\"/>" +
    "<path class=\"pele-cynefin-cliff\" d=\"\{curve_path(drop)}\" stroke=\"var(--_l)\" stroke-width=\"2\" stroke-dasharray=\"none\" stroke-linecap=\"round\"/></g>"
  let oval = ellipse_path(cx, cy, rx, ry)
  let ellipse = "<path d=\"\{oval}\" fill=\"var(--_bg)\"/>" +
    "<path class=\"pele-cynefin-region\" data-id=\"confusion\" d=\"\{oval}\" fill=\"\{@svg.series_color(CONFUSION_COLOR)}\" fill-opacity=\"0.18\" stroke=\"var(--_b)\" stroke-dasharray=\"4 2\"/>"
  let draw_block = (b : Block) => {
    let out = StringBuilder()
    let mut y = b.cy - b.h / 2
    out.write_string(
      @svg.label_svg(
        b.title,
        b.cx,
        y + b.title.height / 2,
        " class=\"pele-label\" font-weight=\"var(--_hw)\"",
      ),
    )
    y += b.title.height
    for s in b.subtitles {
      out.write_string(
        @svg.label_svg(
          s,
          b.cx,
          y + s.height / 2,
          " class=\"pele-cynefin-subtitle\" font-size=\"\{small}\" font-style=\"italic\" fill=\"var(--_m)\"",
        ),
      )
      y += s.height
    }
    y += HEAD_GAP - ITEM_GAP
    for item in b.badges {
      y += ITEM_GAP
      let overflow_class = if item.overflow {
        " pele-cynefin-overflow"
      } else {
        ""
      }
      let data_id = if item.overflow {
        ""
      } else {
        " data-id=\"\{@svg.esc_text(item.text)}\""
      }
      let dashes = if item.overflow { " stroke-dasharray=\"3 2\"" } else { "" }
      let muted = if item.overflow { " fill=\"var(--_m)\"" } else { "" }
      out.write_string(
        "<g class=\"pele-node\{overflow_class}\"\{data_id}>" +
        "<rect x=\"\{num(b.cx - item.w / 2)}\" y=\"\{num(y)}\" width=\"\{num(item.w)}\" height=\"\{num(item.h)}\" fill=\"var(--_bg)\" stroke=\"var(--_b)\"\{dashes}\{@svg.ROUNDED}/>" +
        @svg.label_svg(
          item.label,
          b.cx,
          y + item.h / 2,
          " class=\"pele-label\" font-size=\"\{item_size}\"\{muted}",
        ) +
        "</g>",
      )
      y += item.h
    }
    "<g class=\"pele-cynefin-domain\" data-id=\"\{b.name}\">\{out.to_string()}</g>"
  }
  let placed : Map[String, Block] = Map([])
  let domains = StringBuilder()
  for index, q in quadrants {
    let b = blocks[index]
    b.cx = x0 + quad_w * (q.column.to_double() + 0.5)
    b.cy = y0 + quad_h * (q.row.to_double() + 0.5)
    placed[q.name] = b
    domains.write_string(draw_block(b))
  }
  confusion.cx = cx
  confusion.cy = cy
  placed["confusion"] = confusion
  domains.write_string(draw_block(confusion))
  let inside = (b : Block, x : Double, y : Double) => {
    if b.name == "confusion" {
      let u = (x - cx) / (rx + 4)
      let v = (y - cy) / (ry + 4)
      u * u + v * v <= 1
    } else {
      (x - b.cx).abs() <= b.w / 2 + 8 && (y - b.cy).abs() <= b.h / 2 + 8
    }
  }
  let edges = StringBuilder()
  let seen : Map[String, Int32] = Map([])
  for transition in model.transitions {
    guard (placed.get(transition.from), placed.get(transition.to))
      is (Some(from), Some(to)) else {
      continue
    }
    if from.name == to.name {
      continue
    }
    let key = if transition.from < transition.to {
      "\{transition.from} \{transition.to}"
    } else {
      "\{transition.to} \{transition.from}"
    }
    let repeat = seen.get(key).unwrap_or(0)
    seen[key] = repeat + 1
    let dx = to.cx - from.cx
    let dy = to.cy - from.cy
    let len = or_one(@util.js_hypot(dx, dy))
    let mx = (from.cx + to.cx) / 2
    let my = (from.cy + to.cy) / 2
    // Curves bow away from the middle of the diagram, which keeps them off the ellipse.
    let outward = if -dy * (mx - cx) + dx * (my - cy) >= 0 { 1.0 } else { -1.0 }
    let nx = -dy / len * outward
    let ny = dx / len * outward
    // A diagonal runs through the middle, so it bows far enough to pass the ellipse.
    let diagonal = from.name != "confusion" &&
      to.name != "confusion" &&
      dx.abs() > 1 &&
      dy.abs() > 1
    let bow = (if diagonal {
        2.0 * (@util.js_hypot(rx * nx, ry * ny) + 16)
      } else {
        len * 0.15
      }) +
      repeat.to_double() * 56
    let px = mx + nx * bow
    let py = my + ny * bow
    let point = (t : Double) => {
      let u = 1.0 - t
      (
        u * u * from.cx + 2.0 * u * t * px + t * t * to.cx,
        u * u * from.cy + 2.0 * u * t * py + t * t * to.cy,
      )
    }
    let crossing = (b : Block, lo : Double, hi : Double, leaving : Bool) => {
      let mut lo = lo
      let mut hi = hi
      for _ in 0..<16 {
        let mid = (lo + hi) / 2
        let (x, y) = point(mid)
        if inside(b, x, y) == leaving {
          lo = mid
        } else {
          hi = mid
        }
      }
      (lo + hi) / 2
    }
    let steps = 48
    let mut i = 1
    while i <= steps {
      let (x, y) = point(i.to_double() / steps.to_double())
      if !inside(from, x, y) {
        break
      }
      i += 1
    }
    if i > steps {
      continue
    }
    let t0 = crossing(
      from,
      (i - 1).to_double() / steps.to_double(),
      i.to_double() / steps.to_double(),
      true,
    )
    while i <= steps {
      let (x, y) = point(i.to_double() / steps.to_double())
      if inside(to, x, y) {
        break
      }
      i += 1
    }
    let t1 = if i > steps {
      1.0
    } else {
      crossing(
        to,
        (i - 1).to_double() / steps.to_double(),
        i.to_double() / steps.to_double(),
        false,
      )
    }
    let (sx, sy) = point(t0)
    let (end_x, end_y) = point(t1)
    let blossom = (a : Double, b : Double, c : Double) => {
      (1.0 - t0) * (1.0 - t1) * a +
      ((1.0 - t0) * t1 + t0 * (1.0 - t1)) * b +
      t0 * t1 * c
    }
    let qx = blossom(from.cx, px, to.cx)
    let qy = blossom(from.cy, py, to.cy)
    let el = or_one(@util.js_hypot(end_x - qx, end_y - qy))
    let ux = (end_x - qx) / el
    let uy = (end_y - qy) / el
    let head = @svg.marker("arrow_point", end_x, end_y, ux, uy, "var(--_l)")
    let trim = @svg.marker_trim("arrow_point")
    let ex = end_x - ux * trim
    let ey = end_y - uy * trim
    let text = match transition.label {
      Some(words) => {
        let label = @text.layout_label(
          Some(words),
          false,
          measurer,
          small,
          ITEM_MAX_WIDTH,
        )
        let (lx, ly) = point((t0 + t1) / 2)
        let away = nx.abs() * label.width / 2 + ny.abs() * label.height / 2 + 6
        let half = label.width / 2 + 4
        let tx = @util.js_min(
          @util.js_max(lx + nx * away, x0 + half),
          @util.js_max(right - half, x0 + half),
        )
        @svg.label_svg(
          label,
          tx,
          ly + ny * away,
          " class=\"pele-edge-label\" font-size=\"\{small}\"",
        )
      }
      None => ""
    }
    edges.write_string(
      "<g class=\"pele-edge\" data-id=\"\{transition.from}-\{transition.to}\">" +
      "<path d=\"M\{num(sx)},\{num(sy)}Q\{num(qx)},\{num(qy)} \{num(ex)},\{num(ey)}\" fill=\"none\" stroke=\"var(--_l)\"/>" +
      head +
      text +
      "</g>",
    )
  }
  let total_width = @util.js_max(width, title.width) + 2.0 * pad
  let total_width = total_width.ceil()
  let total_height = (height + title_height + 2.0 * pad).ceil()
  let edge_group = if edges.is_empty() {
    ""
  } else {
    "<g class=\"pele-edges\">\{edges.to_string()}</g>"
  }
  let content = @svg.label_svg(
      title,
      x0 + width / 2,
      pad + title.height / 2,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
    ) +
    "<g class=\"pele-cynefin-regions\">\{fills.to_string()}</g>" +
    boundaries +
    ellipse +
    domains.to_string() +
    edge_group
  {
    svg: @svg.svg_document(
      "cynefin",
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
