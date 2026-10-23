///|
const LEAD : Double = 12

///|
const HEAD_GAP : Double = 6

///|
const RULE_GAP : Double = 18

///|
const FONT_MONO : String = "var(--_fm)"

///|
const ROUNDED : String = " style=\"rx:var(--_r)\""

///|
fn railroad_option(config : @types.Config, key : String) -> Json? {
  guard config.get("railroad") is Some(Object(railroad)) else { return None }
  railroad.get(key)
}

///|
fn option(
  config : @types.Config,
  key : String,
  fallback : Double,
  max : Double,
) -> Double {
  match railroad_option(config, key) {
    Some(Number(value, ..)) if value >= 0 =>
      if value < max {
        value
      } else {
        max
      }
    _ => fallback
  }
}

///|
fn minimum(a : Double, b : Double) -> Double {
  if b < a {
    b
  } else {
    a
  }
}

///|
fn[T] reverse(list : Array[T], from : Int32) -> Unit {
  let mut i = from
  let mut j = list.length() - 1
  while i < j {
    let held = list[i]
    list[i] = list[j]
    list[j] = held
    i += 1
    j -= 1
  }
}

///|
/// What the elements of one rule add to the drawing.
priv struct Ink {
  track : @svg.Markup
  arrows : @svg.Markup
  nodes : @svg.Markup
}

///|
/// The arcs of a track, written for one radius.
priv struct Turns {
  east_to_south : String
  south_to_east : String
  east_to_north : String
  north_to_east : String
  loop_down : String
  loop_up : String
}

///|
fn turns(arc : Double) -> Turns {
  let a = @svg.num(arc)
  let turn = (sweep : Int32, dx : String, dy : String) => {
    "a\{a},\{a} 0 0 \{sweep} \{dx}\{a},\{dy}\{a}"
  }
  {
    east_to_south: turn(1, "", ""),
    south_to_east: turn(0, "", ""),
    east_to_north: turn(0, "", "-"),
    north_to_east: turn(1, "", "-"),
    loop_down: turn(0, "-", ""),
    loop_up: turn(0, "-", "-"),
  }
}

///|
/// How a drawing is styled, apart from its layout.
priv struct Look {
  stroke : String
  box_top : Double
  text_shift : Double
}

///|
fn line(
  ink : Ink,
  x1 : Double,
  y : Double,
  x2 : Double,
) -> Unit raise @errors.PeleError {
  if x2 > x1 {
    ink.track.write("M\{@svg.num(x1)},\{@svg.num(y)}H\{@svg.num(x2)}")
  }
}

///|
/// Writes a terminal, nonterminal or special sequence to `out`, its text a piece at a time.
fn write_leaf(
  out : @svg.Markup,
  box : Box,
  x : Double,
  y : Double,
  m : Metrics,
  look : Look,
) -> Unit raise @errors.PeleError {
  let text = box.text
  let space = if text.has_prefix(" ") ||
    text.has_suffix(" ") ||
    @util.index_of(text, "  ") != -1 {
    " xml:space=\"preserve\""
  } else {
    ""
  }
  let shape = "<rect x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y - look.box_top)}\" width=\"\{@svg.num(box.width)}\" height=\"\{@svg.num(m.height)}\""
  let label = "<text x=\"\{@svg.num(x + box.width / 2)}\" y=\"\{@svg.num(y + look.text_shift)}\"\{space}"
  match box.kind {
    TerminalBox => {
      out.write(
        "<g class=\"pele-node pele-terminal\">\{shape} rx=\"\{@svg.num(look.box_top)}\" fill=\"var(--_s)\" stroke=\"var(--_b)\"\{look.stroke}/>\{label} font-family=\"\{FONT_MONO}\">",
      )
      @svg.write_esc(out, text)
      out.write("</text></g>")
    }
    NonTerminalBox => {
      out.write("<g class=\"pele-node pele-nonterminal\" data-id=\"")
      @svg.write_esc_text(out, box.id)
      out.write(
        "\">\{shape} fill=\"var(--_bg)\" stroke=\"var(--_b)\"\{look.stroke}\{ROUNDED}/>\{label}>",
      )
      @svg.write_esc(out, text)
      out.write("</text></g>")
    }
    _ => {
      out.write(
        "<g class=\"pele-node pele-special\">\{shape} fill=\"var(--_bg)\" stroke=\"var(--_b)\" stroke-dasharray=\"4 3\"\{look.stroke}\{ROUNDED}/>" +
        "\{label} font-style=\"italic\"><tspan fill=\"var(--_m)\">? </tspan>",
      )
      @svg.write_esc(out, @util.slice(text, 2, end=-2))
      out.write("<tspan fill=\"var(--_m)\"> ?</tspan></text></g>")
    }
  }
}

///|
/// Places a box and its parts with an explicit stack, so that nesting depth is bounded by memory, not by the stack.
/// `at` holds an x and a y for each box, pushed so that a reversal puts each pair in the order it is popped.
fn place(
  ink : Ink,
  root : Box,
  left : Double,
  baseline : Double,
  m : Metrics,
  look : Look,
) -> Unit raise @errors.PeleError {
  let arc = m.arc
  let t = turns(arc)
  let boxes : Array[Box] = [root]
  let at : Array[Double] = [left, baseline]
  while boxes.length() > 0 {
    let box = boxes.pop().unwrap()
    let y = at.pop().unwrap()
    let x = at.pop().unwrap()
    let kids = box.kids
    let right = x + box.width
    match box.kind {
      SequenceBox => {
        let mut kx = right
        for i = kids.length() - 1; i >= 0; i = i - 1 {
          kx -= kids[i].width
          boxes.push(kids[i])
          at.push(kx)
          at.push(y)
          if i > 0 {
            line(ink, kx - m.gap, y, kx)
          }
          kx -= m.gap
        }
      }
      FoldedBox => {
        let start = x + 2 * arc
        let from = boxes.length()
        let mut offset = 0.0
        line(ink, x, y, start)
        for i, kid in kids {
          let ky = y + offset
          boxes.push(kid)
          at.push(ky)
          at.push(start)
          if i + 1 < kids.length() {
            let next = kids[i + 1]
            let next_offset = offset +
              kid.down +
              maximum(m.sep, 2 * arc) +
              next.up
            let mid = y + offset + kid.down + maximum(m.sep, 2 * arc) / 2
            ink.track.write(
              "M\{@svg.num(start + kid.width)},\{@svg.num(ky)}H\{@svg.num(right - 2 * arc)}V\{@svg.num(mid)}H\{@svg.num(x + arc)}V\{@svg.num(y + next_offset)}H\{@svg.num(start)}",
            )
            ink.arrows.write(
              "M\{@svg.num(start - ARROW)},\{@svg.num(y + next_offset - ARROW / 2)}l\{ARROW},\{ARROW / 2}l\{-ARROW},\{ARROW / 2}z",
            )
            offset = next_offset
          } else {
            ink.track.write(
              "M\{@svg.num(start + kid.width)},\{@svg.num(ky)}H\{@svg.num(right - arc)}V\{@svg.num(y)}H\{@svg.num(right)}",
            )
          }
        }
        reverse(boxes, from)
        reverse(at, 2 * from)
      }
      ChoiceBox => {
        let inner = box.width - 4 * arc
        let rail_in = x + arc
        let rail_out = right - arc
        let from = boxes.length()
        let mut offset = 0.0
        for i, kid in kids {
          if i > 0 {
            offset = below(offset, kids[i - 1], kid, m)
          }
          let ky = y + offset
          let kx = x + 2 * arc + (inner - kid.width) / 2
          let last = i == kids.length() - 1
          if i == 0 {
            line(ink, x, y, kx)
            line(ink, kx + kid.width, y, right)
          } else {
            let wide = kx > rail_in + arc
            ink.track.write(
              (if last {
                "M\{@svg.num(x)},\{@svg.num(y)}\{t.east_to_south}V\{@svg.num(ky - arc)}"
              } else {
                "M\{@svg.num(rail_in)},\{@svg.num(ky - arc)}"
              }) +
              t.south_to_east +
              (if wide { "H\{@svg.num(kx)}" } else { "" }) +
              "M\{@svg.num(kx + kid.width)},\{@svg.num(ky)}" +
              (if wide { "H\{@svg.num(rail_out - arc)}" } else { "" }) +
              t.east_to_north +
              (if last {
                "V\{@svg.num(y + arc)}\{t.north_to_east}"
              } else {
                ""
              }),
            )
          }
          boxes.push(kid)
          at.push(ky)
          at.push(kx)
        }
        reverse(boxes, from)
        reverse(at, 2 * from)
      }
      BypassBox => {
        let kid = kids[0]
        let kx = x + 2 * arc
        line(ink, x, y, kx)
        line(ink, kx + kid.width, y, right)
        ink.track.write(
          "M\{@svg.num(x)},\{@svg.num(y)}\{t.east_to_north}V\{@svg.num(y - box.reach + arc)}\{t.north_to_east}H\{@svg.num(right - 2 * arc)}" +
          "\{t.east_to_south}V\{@svg.num(y - arc)}\{t.south_to_east}",
        )
        boxes.push(kid)
        at.push(kx)
        at.push(y)
      }
      LoopBox => {
        let kid = kids[0]
        let kx = x + (box.width - kid.width) / 2
        let loop_y = y + box.reach
        let middle = x + box.width / 2
        line(ink, x, y, kx)
        line(ink, kx + kid.width, y, right)
        ink.track.write(
          "M\{@svg.num(x + arc)},\{@svg.num(y)}\{t.loop_down}V\{@svg.num(loop_y - arc)}\{t.south_to_east}H\{@svg.num(right - arc)}" +
          "\{t.east_to_north}V\{@svg.num(y + arc)}\{t.loop_up}",
        )
        ink.arrows.write(
          "M\{@svg.num(middle - ARROW / 2)},\{@svg.num(loop_y)}l\{ARROW},\{-ARROW / 2}v\{ARROW}z",
        )
        if box.text != "" {
          ink.nodes.write(
            "<text class=\"pele-edge-label pele-count\" x=\"\{@svg.num(middle)}\" y=\"\{@svg.num(loop_y + COUNT_SIZE + 3)}\" font-size=\"\{COUNT_SIZE}\" fill=\"var(--_m)\">",
          )
          @svg.write_esc(ink.nodes, box.text)
          ink.nodes.write("</text>")
        }
        boxes.push(kid)
        at.push(kx)
        at.push(y)
      }
      _ => write_leaf(ink.nodes, box, x, y, m, look)
    }
  }
}

///|
fn draw(
  model : RailroadModel,
  config : @types.Config,
  options : @types.RenderOptions,
  tight : Bool,
) -> @types.Rendered raise @errors.PeleError {
  let base = options.font_size.unwrap_or(16)
  let font_size = option(config, "fontSize", 0, 200)
  let size = if font_size != 0 { font_size } else { (base * 0.875).round() }
  let head_size = if font_size != 0 { font_size } else { base }
  let padding = option(config, "padding", -1, 200)
  let line_height = (size * 1.5).round()
  let m : Metrics = {
    measurer: options.text_measurer(),
    size,
    padding: if padding < 0 {
      12
    } else {
      padding
    },
    height: even(line_height + (if padding < 0 { 9 } else { 2 * padding })),
    gap: minimum(
      option(config, "horizontalSeparation", 16, 500),
      if tight {
        12
      } else {
        @double.infinity
      },
    ),
    sep: option(config, "verticalSeparation", 10, 500),
    arc: minimum(
      option(config, "arcRadius", 10, 200),
      if tight {
        6
      } else {
        @double.infinity
      },
    ),
  }
  let radius = match railroad_option(config, "showMarkers") {
    Some(False) => 0.0
    _ => option(config, "markerRadius", 4, 50)
  }
  let stroke_width = option(config, "strokeWidth", 0, 20)
  let look : Look = {
    stroke: if stroke_width > 0 {
      " stroke-width=\"\{@svg.num(stroke_width)}\""
    } else {
      ""
    },
    box_top: m.height / 2,
    text_shift: size * 0.35,
  }
  let pad = options.padding.unwrap_or(8)
  let title = @text.layout_label(
    model.title,
    false,
    m.measurer,
    base,
    if tight {
      @common.title_room(options)
    } else {
      4000
    },
    base=@text.STYLE_BOLD,
  )
  let title_height = if title.height > 0 { title.height + 16 } else { 0 }
  let head_height = (head_size * 1.5).round()
  let rules = @svg.Markup::new()
  let mut width = title.width
  let mut top = pad + title_height
  let mut bottom = pad + title.height
  for rule in model.rules {
    let room = if tight {
      maximum(
        80,
        options.max_width.unwrap_or(320) - 2 * pad - 4 * radius - 2 * LEAD - 1,
      )
    } else {
      @double.infinity
    }
    let box = measure(rule.definition, m, room)
    let name = shown(rule.name)
    let baseline = top + head_height + HEAD_GAP + box.up
    let start = pad + 2 * radius
    let left = start + LEAD
    let end = left + box.width + LEAD
    let ink : Ink = {
      track: @svg.Markup::new(),
      arrows: @svg.Markup::new(),
      nodes: @svg.Markup::new(),
    }
    line(ink, start, baseline, left)
    line(ink, left + box.width, baseline, end)
    place(ink, box, left, baseline, m, look)
    let markers = if radius > 0 {
      "<circle class=\"pele-marker pele-start\" cx=\"\{@svg.num(pad + radius)}\" cy=\"\{@svg.num(baseline)}\" r=\"\{@svg.num(radius)}\" fill=\"var(--_l)\"/>" +
      "<circle class=\"pele-marker pele-end\" cx=\"\{@svg.num(end + radius)}\" cy=\"\{@svg.num(baseline)}\" r=\"\{@svg.num(radius)}\" fill=\"var(--_l)\"/>"
    } else {
      ""
    }
    rules.write("<g class=\"pele-rule\" data-id=\"")
    @svg.write_esc_text(rules, rule.name)
    rules.write(
      "\"><text class=\"pele-rule-name\" x=\"\{@svg.num(pad)}\" y=\"\{@svg.num(top + head_height / 2 + head_size * 0.35)}\" font-size=\"\{@svg.num(head_size)}\" font-weight=\"var(--_hw)\" text-anchor=\"start\">",
    )
    @svg.write_esc(rules, name)
    rules.write("</text>")
    rules.write_group(
      "<path class=\"pele-edge pele-track\" d=\"",
      ink.track,
      "\" fill=\"none\" stroke=\"var(--_l)\"\{look.stroke}/>",
    )
    if !ink.arrows.is_empty() {
      rules.write_group(
        "<path class=\"pele-marker\" d=\"",
        ink.arrows,
        "\" fill=\"var(--_l)\"/>",
      )
    }
    rules.write(markers)
    rules.write_markup(ink.nodes)
    rules.write("</g>")
    width = maximum(
      maximum(width, end + 2 * radius - pad),
      m.measurer.width(name, head_size, @text.STYLE_BOLD),
    )
    bottom = baseline + box.down
    top = bottom + m.sep + RULE_GAP
  }
  let total_width = (width + 2 * pad).ceil()
  let total_height = (bottom + pad).ceil()
  let content = @svg.Markup::new()
  @svg.write_label(
    content,
    title,
    total_width / 2,
    pad + title.height / 2,
    " class=\"pele-title\" font-weight=\"var(--_tw)\"",
  )
  if !rules.is_empty() {
    content.write_group(
      "<g class=\"pele-rules\" transform=\"translate(0.5,0.5)\" font-size=\"\{@svg.num(size)}\" text-anchor=\"middle\">",
      rules,
      "</g>",
    )
  }
  {
    svg: @svg.markup_document(
      "railroad",
      total_width,
      total_height,
      base,
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

///|
fn render_railroad(
  model : RailroadModel,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  @common.tighten(options, tight => draw(model, config, options, tight))
}
