///|
const PAD_X : Double = 12

///|
const PAD_Y : Double = 8

///|
const MIN_TEXT : Double = 152

///|
const MAX_TEXT : Double = 216

///|
const EVENT_TEXT_TD : Double = 264

///|
const GAP : Double = 20

///|
const AXIS : Double = 20

///|
const SPINE : Double = 14

///|
const EVENT_GAP : Double = 8

///|
const SECTION_GAP : Double = 8

///|
const TAIL : Double = 12

///|
const ON_COLOR : String = " fill=\"var(--_bg)\""

///|
const LINE : String = " fill=\"none\" stroke=\"var(--_b)\""

///|
priv struct Group {
  /// -1 for the periods that come before the first section.
  section : Int32
  periods : Array[Int32]
}

///|
fn box(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  attrs : String,
) -> String {
  "<rect x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y)}\" width=\"\{@svg.num(w)}\" height=\"\{@svg.num(h)}\"\{@svg.rounded(attrs)}/>"
}

///|
fn multicolor(config : @types.Config) -> Bool {
  guard config.get("timeline") is Some(Object(options)) else { return true }
  !(options.get("disableMulticolor") is Some(True))
}

///|
/// Draws a timeline as SVG, across or, when the host's width asks for it, down.
pub fn render_timeline(
  model : TimelineDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  if model.direction == "TD" {
    return draw(model, config, options, true)
  }
  @common.turn_to_fit(options, down => draw(model, config, options, down))
}

///|
fn draw(
  model : TimelineDb,
  config : @types.Config,
  options : @types.RenderOptions,
  vertical : Bool,
) -> @types.Rendered raise @errors.PeleError {
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.875).round()
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let multicolor = multicolor(config)
  let periods = model.periods
  let has_sections = !model.sections.is_empty()

  // Mermaid draws nothing for periods that come before the first section; here they lead, in a neutral color.
  let groups : Array[Group] = model.sections.mapi((section, _) => {
    section,
    periods: [],
  })
  let leading : Group = { section: -1, periods: [], }
  for i, period in periods {
    if period.section_index >= 0 {
      groups[period.section_index].periods.push(i)
    } else {
      leading.periods.push(i)
    }
  }
  if !leading.periods.is_empty() {
    groups.insert(0, leading)
  }

  // Columns widen, up to a point, for a word that would not fit; past that the word is cut.
  // Running down, the two columns share the width the host has.
  let bounded = vertical && options.max_width is Some(w) && w > 0
  let room = match options.max_width {
    Some(w) if bounded => w - 2 * pad
    _ => @double.infinity
  }
  let taken = AXIS + SPINE * 2 + 4 * PAD_X
  let period_text = if bounded {
    @util.js_min(MIN_TEXT, @util.js_max(80, ((room - taken) * 0.38).round()))
  } else {
    MIN_TEXT
  }
  let event_text = if bounded {
    @util.js_min(EVENT_TEXT_TD, @util.js_max(110, room - taken - period_text))
  } else {
    EVENT_TEXT_TD
  }
  let mut text_w = period_text
  let event_text_w = () => if vertical { event_text } else { text_w }
  let mut period_labels = periods.map(p => {
    @common.plain_label(Some(p.text), measurer, size, text_w)
  })
  let mut event_labels = periods.map(p => {
    p.events.map(e => {
      @common.plain_label(Some(e), measurer, small, event_text_w())
    })
  })
  let mut widest = 0.0
  for label in period_labels {
    widest = @util.js_max(widest, label.width)
  }
  if !vertical {
    for labels in event_labels {
      for label in labels {
        widest = @util.js_max(widest, label.width)
      }
    }
  }
  let mut overflow = widest > text_w
  if vertical {
    for labels in event_labels {
      for label in labels {
        overflow = overflow || label.width > event_text
      }
    }
  }
  if overflow {
    text_w = @util.js_min(
      @util.js_max(widest.ceil(), period_text),
      if bounded {
        period_text
      } else {
        MAX_TEXT
      },
    )
    period_labels = periods.map(p => {
      @common.fit_label(Some(p.text), measurer, size, text_w)
    })
    event_labels = periods.map(p => {
      p.events.map(e => {
        @common.fit_label(Some(e), measurer, small, event_text_w())
      })
    })
  }

  let line_height = (size * 1.5).round()
  let col_w = text_w + 2 * PAD_X
  let event_w = event_text_w() + 2 * PAD_X
  let chip_height = (label : @text.Label) => {
    @util.js_max(label.height, line_height) + 2 * PAD_Y
  }
  let event_height = (label : @text.Label) => {
    @util.js_max(label.height, (small * 1.5).round()) + 2 * PAD_Y
  }
  let color_of = (group : Group, period : Int32) => {
    if group.section >= 0 {
      @svg.series_color(group.section)
    } else if has_sections {
      "var(--_m)"
    } else {
      @svg.series_color(if multicolor { period } else { 0 })
    }
  }

  let mut has_events = false
  for labels in event_labels {
    if !labels.is_empty() {
      has_events = true
    }
  }
  let mut slots = 0
  for group in groups {
    slots += @cmp.maximum(group.periods.length(), 1)
  }

  let pitch = col_w + GAP
  let drawn = !periods.is_empty()
  let body_w = if vertical {
    col_w +
    (if has_events {
      AXIS + SPINE * 2 + event_w
    } else if drawn {
      AXIS + TAIL
    } else {
      0
    })
  } else if slots > 0 {
    slots.to_double() * pitch -
    GAP +
    (if drawn { TAIL + @svg.ARROW } else { 0 })
  } else {
    0
  }
  let title = @common.fit_label(
    model.title,
    measurer,
    size,
    @util.js_max(body_w, 320),
    base=@text.STYLE_BOLD,
  )
  let title_h = if title.height > 0 { title.height + 16 } else { 0 }
  let width = @util.js_max(body_w, title.width)
  let left = pad + (width - body_w) / 2
  let top = pad + title_h

  let section_label = (group : Group, w : Double) => {
    @common.fit_label(
      Some(model.sections[group.section]),
      measurer,
      size,
      w - 2 * PAD_X,
      base=@text.STYLE_BOLD,
    )
  }
  fn header(
    out : @svg.Markup,
    group : Group,
    label : @text.Label,
    x : Double,
    y : Double,
    w : Double,
    h : Double,
  ) -> Unit raise @errors.PeleError {
    out.write(box(x, y, w, h, " fill=\"\{@svg.series_color(group.section)}\""))
    @svg.write_label(
      out,
      label,
      x + w / 2,
      y + h / 2,
      " font-weight=\"var(--_hw)\"" + ON_COLOR,
    )
  }
  fn period(
    out : @svg.Markup,
    i : Int32,
    color : String,
    x : Double,
    y : Double,
    h : Double,
  ) -> Unit raise @errors.PeleError {
    out.write(box(x, y, col_w, h, " fill=\"\{color}\""))
    @svg.write_label(out, period_labels[i], x + col_w / 2, y + h / 2, ON_COLOR)
  }
  fn event(
    out : @svg.Markup,
    label : @text.Label,
    color : String,
    x : Double,
    y : Double,
    h : Double,
  ) -> Unit raise @errors.PeleError {
    out.write(
      "<g class=\"pele-node pele-event\">" +
      box(x, y, event_w, h, " fill=\"\{color}\" fill-opacity=\"0.16\""),
    )
    @svg.write_label(
      out,
      label,
      x + event_w / 2,
      y + h / 2,
      " font-size=\"\{small}\"",
    )
    out.write("</g>")
  }
  let dot = (x : Double, y : Double, color : String) => {
    "<circle class=\"pele-dot\" cx=\"\{@svg.num(x)}\" cy=\"\{@svg.num(y)}\" r=\"4\" fill=\"\{color}\" stroke=\"var(--_bg)\" stroke-width=\"2\"/>"
  }
  fn open(out : @svg.Markup, group : Group) -> Unit raise @errors.PeleError {
    if group.section >= 0 {
      out.write("<g class=\"pele-cluster pele-section\" data-id=\"")
      @svg.write_esc_text(out, @util.trim(model.sections[group.section]))
      out.write("\">")
    }
  }
  fn open_period(out : @svg.Markup, i : Int32) -> Unit raise @errors.PeleError {
    out.write("<g class=\"pele-node pele-period\" data-id=\"")
    @svg.write_esc_text(out, @util.trim(periods[i].text))
    out.write("\">")
  }

  let mut body = @svg.Markup::new()
  let mut height = 0.0
  if vertical {
    let axis_x = left + col_w + AXIS
    let spine_x = axis_x + SPINE
    let events_x = spine_x + SPINE
    let mut y = top
    for group in groups {
      open(body, group)
      if group.section >= 0 {
        let label = section_label(group, body_w)
        let h = chip_height(label)
        header(body, group, label, left, y, body_w, h)
        y += h + SECTION_GAP + 4
      }
      for i in group.periods {
        let color = color_of(group, i)
        let h = chip_height(period_labels[i])
        // A period and its first event share one center line, so the line between them runs straight.
        let first = if event_labels[i].is_empty() {
          h
        } else {
          event_height(event_labels[i][0])
        }
        let cy = y + @util.js_max(h, first) / 2
        let d = @svg.Markup::new()
        d.write(
          "M\{@svg.num(left + col_w)},\{@svg.num(cy)}H\{@svg.num(axis_x)}",
        )
        let cards = @svg.Markup::new()
        let mut ey = cy - first / 2
        let mut last = cy
        for label in event_labels[i] {
          let eh = event_height(label)
          last = ey + eh / 2
          d.write(
            "M\{@svg.num(spine_x)},\{@svg.num(last)}H\{@svg.num(events_x)}",
          )
          event(cards, label, color, events_x, ey, eh)
          ey += eh + EVENT_GAP
        }
        if !cards.is_empty() {
          d.write(
            "M\{@svg.num(axis_x)},\{@svg.num(cy)}H\{@svg.num(spine_x)}V\{@svg.num(last)}",
          )
        }
        open_period(body, i)
        period(body, i, color, left, cy - h / 2, h)
        body.write_group("<path class=\"pele-edge\" d=\"", d, "\"\{LINE}/>")
        body.write(dot(axis_x, cy, color))
        body.write_markup(cards)
        body.write("</g>")
        y = @util.js_max(cy + h / 2, ey - EVENT_GAP) + GAP
      }
      if group.periods.is_empty() {
        y += GAP - SECTION_GAP - 4
      }
      if group.section >= 0 {
        body.write("</g>")
      }
    }
    if !groups.is_empty() {
      y -= GAP
    }
    if drawn {
      let tip = y + TAIL + @svg.ARROW
      let axis = @svg.Markup::new()
      axis.write(
        "<path class=\"pele-axis\" d=\"M\{@svg.num(axis_x)},\{@svg.num(top)}V\{@svg.num(tip - @svg.ARROW + 1)}\" fill=\"none\" stroke=\"var(--_l)\"/>" +
        @svg.marker("arrow_point", axis_x, tip, 0, 1, "var(--_l)"),
      )
      axis.write_markup(body)
      body = axis
      y = tip
    }
    height = y + pad
  } else {
    let mut header_h = 0.0
    let section_labels : Array[@text.Label?] = groups.map(group => {
      if group.section < 0 {
        return None
      }
      let label = section_label(
        group,
        @cmp.maximum(group.periods.length(), 1).to_double() * pitch - GAP,
      )
      header_h = @util.js_max(header_h, chip_height(label))
      Some(label)
    })
    let mut chip_h = 0.0
    for label in period_labels {
      chip_h = @util.js_max(chip_h, chip_height(label))
    }
    let periods_y = top +
      (if has_sections { header_h + SECTION_GAP } else { 0 })
    let axis_y = periods_y + chip_h + (if chip_h > 0 { AXIS } else { 0 })
    let events_y = axis_y + AXIS
    let mut bottom = if drawn { axis_y + TAIL } else { top + header_h }
    let mut slot = 0
    for g, group in groups {
      let span = @cmp.maximum(group.periods.length(), 1)
      let gx = left + slot.to_double() * pitch
      open(body, group)
      if section_labels[g] is Some(label) {
        header(
          body,
          group,
          label,
          gx,
          top,
          span.to_double() * pitch - GAP,
          header_h,
        )
      }
      for k, i in group.periods {
        let color = color_of(group, i)
        let x = gx + k.to_double() * pitch
        let cx = x + col_w / 2
        let d = @svg.Markup::new()
        d.write(
          "M\{@svg.num(cx)},\{@svg.num(periods_y + chip_h)}V\{@svg.num(if event_labels[i].is_empty() { axis_y } else { events_y })}",
        )
        let cards = @svg.Markup::new()
        let mut ey = events_y
        for event_label in event_labels[i] {
          let eh = event_height(event_label)
          if ey > events_y {
            d.write(
              "M\{@svg.num(cx)},\{@svg.num(ey - EVENT_GAP)}V\{@svg.num(ey)}",
            )
          }
          event(cards, event_label, color, x, ey, eh)
          ey += eh + EVENT_GAP
        }
        bottom = @util.js_max(bottom, ey - EVENT_GAP)
        open_period(body, i)
        period(body, i, color, x, periods_y, chip_h)
        body.write_group("<path class=\"pele-edge\" d=\"", d, "\"\{LINE}/>")
        body.write(dot(cx, axis_y, color))
        body.write_markup(cards)
        body.write("</g>")
      }
      if group.section >= 0 {
        body.write("</g>")
      }
      slot += span
    }
    if drawn {
      let tip = left + body_w
      let axis = @svg.Markup::new()
      axis.write(
        "<path class=\"pele-axis\" d=\"M\{@svg.num(left)},\{@svg.num(axis_y)}H\{@svg.num(tip - @svg.ARROW + 1)}\" fill=\"none\" stroke=\"var(--_l)\"/>" +
        @svg.marker("arrow_point", tip, axis_y, 1, 0, "var(--_l)"),
      )
      axis.write_markup(body)
      body = axis
    }
    height = bottom + pad
  }

  let total_width = (width + 2 * pad).ceil()
  let total_height = @util.js_max(height, pad * 2).ceil()
  let content = @svg.Markup::new()
  content.write(
    @svg.label_svg(
      title,
      total_width / 2,
      pad + title.height / 2,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
    ),
  )
  content.write_markup(body)
  {
    svg: @svg.markup_document(
      "timeline",
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
