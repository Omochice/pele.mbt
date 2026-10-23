///|
const COLUMN_GAP : Double = 12

///|
const COLUMN_PAD : Double = 8

///|
const CARD_PAD : Double = 10

///|
const CARD_GAP : Double = 8

///|
const META_GAP : Double = 4

///|
/// Between an icon and the count or text beside it.
const ICON_GAP : Double = 6

///|
const CRITICAL : String = "var(--pele-critical,#e45756)"

///|
/// The stroke of a card's priority edge.
/// Mermaid names five priorities and gives Medium no color, and matching ignores case.
/// The high ones are marked in the critical color and the low ones in the muted one, the nearer to Medium the fainter.
/// They are not series colors, as a theme may put those in any order.
fn priority_stroke(priority : String) -> String? {
  match priority {
    "very high" => Some("stroke=\"\{CRITICAL}\"")
    "high" => Some("stroke=\"\{CRITICAL}\" opacity=\"0.5\"")
    "low" => Some("stroke=\"var(--_m)\" opacity=\"0.5\"")
    "very low" => Some("stroke=\"var(--_m)\"")
    _ => None
  }
}

///|
/// Lays out text for a fixed width.
/// A word too long for a line is broken between characters, because a card cannot grow sideways to hold it.
/// pele's kanban breaks only once a line has some width, unlike the `breakLabel` other diagrams share, so a zero-width character stays with the next one and `@common.break_label` does not fit here.
fn fit_label(
  raw : String?,
  markdown : Bool,
  measurer : @text.TextMeasurer,
  size : Double,
  max : Double,
  base~ : Int32 = 0,
) -> @text.Label {
  let label = @text.layout_label(raw, markdown, measurer, size, max, base~)
  if label.width <= max {
    return label
  }
  let lines : Array[Array[@text.Span]] = []
  let widths : Array[Double] = []
  let mut widest = 0.0
  let mut line : Array[@text.Span] = []
  let mut width = 0.0
  let commit = () => {
    lines.push(line)
    widths.push(width)
    widest = @util.js_max(widest, width)
    line = []
    width = 0
  }
  for i, spans in label.lines {
    if label.widths[i] <= max {
      line = spans
      width = label.widths[i]
      commit()
      continue
    }
    for span in spans {
      if span.icon is Some(_) || span.math is Some(_) {
        if width > 0 && width + span.width > max {
          commit()
        }
        line.push(span)
        width += span.width
        continue
      }
      let mut text = ""
      let mut from = width
      let push_text = () => {
        if text != "" {
          line.push({
            text,
            style: span.style,
            icon: None,
            width: width - from,
            math: None,
          })
        }
      }
      for ch in span.text {
        let char = ch.to_string()
        let w = measurer.width(char, size, span.style)
        if width > 0 && width + w > max {
          push_text()
          commit()
          text = ""
          from = 0
        }
        text = text + char
        width += w
      }
      push_text()
    }
    commit()
  }
  let fitted = {
    ..label,
    lines,
    widths,
    width: widest,
    height: lines.length().to_double() * label.line_height,
  }
  if label.heights is Some(_) {
    @text.with_heights(fitted)
  } else {
    fitted
  }
}

///|
/// Writes a label with every line starting at `x`, or ending there when `end` is set, and the first line's box starting at `y`.
fn text_block(
  label : @text.Label,
  x : Double,
  y : Double,
  attrs : String,
  icons : @types.IconResolver?,
  end~ : Bool = false,
) -> String {
  let out = StringBuilder()
  for i, line in label.lines {
    let cy = y + @text.line_middle(label, i)
    if line.length() == 1 && line[0].icon is None && line[0].math is None {
      let anchor = if end { " text-anchor=\"end\"" } else { "" }
      out.write_string(
        "<text\{@svg.text_style(attrs, line[0].style)} x=\"\{@svg.num(x)}\" y=\"\{@svg.num(cy + label.size * 0.35)}\"\{anchor}>\{@svg.esc(line[0].text)}</text>",
      )
    } else {
      let width = label.widths[i]
      let cx = x + (if end { -width } else { width }) / 2
      out.write_string(
        @svg.label_svg(@text.label_line(label, i), cx, cy, attrs, icons?),
      )
    }
  }
  out.to_string()
}

///|
priv struct Card {
  item : KanbanNode
  label : @text.Label
  ticket : @text.Label
  assigned : @text.Label
  /// Height of the rows under the text that hold the ticket and the assignee.
  meta : Double
  height : Double
}

///|
/// `url` with its first `#TICKET#` replaced by `ticket`, as the text is, without reading `$` in it.
fn with_ticket(url : String, ticket : String) -> String {
  let at = @util.index_of(url, "#TICKET#")
  if at == -1 {
    return url
  }
  @util.slice(url, 0, end=at) + ticket + @util.slice(url, at + 8)
}

///|
fn replace_first_space(text : String) -> String {
  let at = @util.index_of(text, " ")
  if at == -1 {
    text
  } else {
    @util.slice(text, 0, end=at) + "-" + @util.slice(text, at + 1)
  }
}

///|
/// Draws a board: a column for each section and a card for each item in it.
pub fn render_kanban(
  model : KanbanModel,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered {
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.875).round()
  let line = (size * 1.5).round()
  let small_line = (small * 1.5).round()
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let glyph = small * 1.25
  // Whether the host has the icon; one it does not have takes no room.
  let has = (name : String?) => {
    name is Some(name) && name != "" && @text.icon_markup(name) != ""
  }
  let icon_room = (name : String?) => {
    if has(name) {
      glyph + ICON_GAP
    } else {
      0
    }
  }
  let conf = match config.get("kanban") {
    Some(Object(conf)) => conf
    _ => {}
  }
  // Math cannot break across lines, so columns widen to hold the widest expression.
  let mut math_width = 0.0
  let holds = (raw : String?, font_size : Double, reserved : Double) => {
    guard raw is Some(raw) && raw.contains("$$") else { return }
    let label = @text.layout_label(
      Some(raw),
      true,
      measurer,
      font_size,
      @double.infinity,
    )
    for spans in label.lines {
      for span in spans {
        if span.math is Some(math) {
          math_width = @util.js_max(math_width, math.width + reserved)
        }
      }
    }
  }
  for section in model.sections {
    let count = measurer.width(section.items.length().to_string(), small, 0)
    holds(
      Some(section.label),
      size,
      2 * COLUMN_PAD + 8 + count + 12 + icon_room(section.icon),
    )
    for item in section.items {
      let reserved = 2.0 * (COLUMN_PAD + CARD_PAD)
      holds(Some(item.label), small, reserved + icon_room(item.icon))
      holds(item.ticket, small, reserved)
      holds(item.assigned, small, reserved)
    }
  }
  let own_width = @util.js_max(
    match conf.get("sectionWidth") {
      Some(Number(value, ..)) if value > 0 =>
        @util.js_min(@util.js_max(value, 80), 2000)
      _ => 200
    },
    math_width.ceil(),
  )
  // A board wider than the width the host has is folded into rows of columns, which then share the row between them.
  let room = match options.max_width {
    Some(max_width) if max_width > 0 => max_width - 2 * pad
    _ => @double.infinity
  }
  let sections = model.sections
  let count = sections.length().to_double()
  let fits = count * (own_width + COLUMN_GAP) - COLUMN_GAP <= room
  let per_row = if fits {
    @util.js_max(count, 1)
  } else {
    @util.js_max(1, ((room + COLUMN_GAP) / (own_width + COLUMN_GAP)).floor())
  }
  let column_width = if fits {
    own_width
  } else {
    @util.js_max(
      @util.js_max(
        @util.js_min(own_width, room),
        @util.js_min(
          ((room + COLUMN_GAP) / per_row).floor() - COLUMN_GAP,
          own_width * 2,
        ),
      ),
      math_width.ceil(),
    )
  }
  let base_url = match conf.get("ticketBaseUrl") {
    Some(String(url)) => url
    _ => ""
  }
  let card_width = column_width - 2 * COLUMN_PAD
  let text_width = card_width - 2 * CARD_PAD
  let links : Array[@types.LinkInfo] = []
  let titles : Array[@text.Label] = []
  let count_widths : Array[Double] = []
  let cards : Array[Array[Card]] = []
  let mut head_height = line
  let body_heights : Array[Double] = []
  for section in sections {
    let count_width = measurer.width(
      section.items.length().to_string(),
      small,
      0,
    )
    let title = fit_label(
      Some(section.label),
      true,
      measurer,
      size,
      card_width - 8 - (count_width + 12 + icon_room(section.icon)),
      base=@text.STYLE_BOLD,
    )
    head_height = @util.js_max(head_height, title.height)
    count_widths.push(count_width)
    titles.push(title)
    let list : Array[Card] = []
    let mut height = 0.0
    for item in section.items {
      let label = fit_label(
        Some(item.label),
        true,
        measurer,
        small,
        text_width - icon_room(item.icon),
      )
      let ticket = fit_label(item.ticket, false, measurer, small, text_width)
      let assigned = fit_label(
        item.assigned,
        false,
        measurer,
        small,
        text_width,
      )
      let meta = if ticket.width + assigned.width + 8 > text_width {
        ticket.height + assigned.height
      } else {
        @util.js_max(ticket.height, assigned.height)
      }
      let card_height : Double = 2.0 * CARD_PAD +
        @util.js_max(label.height, small_line) +
        (if meta != 0.0 { META_GAP + meta } else { 0.0 })
      list.push({ item, label, ticket, assigned, meta, height: card_height, })
      height += card_height + CARD_GAP
    }
    cards.push(list)
    body_heights.push(height)
  }
  head_height += 2 * COLUMN_PAD
  let row_heights : Array[Double] = []
  let row_tops : Array[Double] = []
  let mut first = 0
  let mut y = 0.0
  while first < sections.length() {
    let mut tallest = CARD_GAP
    let last = @util.js_min(
      first.to_double() + per_row,
      sections.length().to_double(),
    ).to_int()
    for index in first..<last {
      tallest = @util.js_max(tallest, body_heights[index])
    }
    row_tops.push(y)
    row_heights.push(head_height + tallest)
    y += head_height + tallest + COLUMN_GAP
    first += per_row.to_int()
  }
  let board_height = if row_heights.is_empty() {
    0.0
  } else {
    row_tops[row_tops.length() - 1] + row_heights[row_heights.length() - 1]
  }
  let title = @svg.title_label(
    model.title,
    measurer,
    size,
    @common.title_room(options),
  )
  let title_height = if title.height > 0 { title.height + 16 } else { 0 }
  let board_width = @util.js_max(
    @util.js_min(count, per_row) * (column_width + COLUMN_GAP) - COLUMN_GAP,
    0,
  )
  let width = @util.js_max(board_width, title.width)
  let left = pad + (width - board_width) / 2
  let edge = column_width - COLUMN_PAD - 4
  let out = StringBuilder()
  for index, section in sections {
    let row = (index.to_double() / per_row).floor().to_int()
    let body = StringBuilder()
    body.write_string(
      "<rect width=\"\{column_width}\" height=\"\{@svg.num(row_heights[row])}\" fill=\"var(--_s)\"\{@svg.ROUNDED}/>",
    )
    body.write_string(
      text_block(
        titles[index],
        COLUMN_PAD + 4,
        COLUMN_PAD,
        " class=\"pele-cluster-label\" font-weight=\"var(--_hw)\"",
        options.icons,
      ),
    )
    body.write_string(
      "<text class=\"pele-count\" x=\"\{edge}\" y=\"\{@svg.num(COLUMN_PAD + line / 2 + small * 0.35)}\" text-anchor=\"end\" font-size=\"\{small}\" fill=\"var(--_m)\">\{section.items.length()}</text>",
    )
    if section.icon is Some(icon) && has(section.icon) {
      body.write_string(
        @common.icon_svg(
          icon,
          edge - count_widths[index] - ICON_GAP - glyph,
          COLUMN_PAD + (line - glyph) / 2,
          glyph,
          icons?=options.icons,
        ),
      )
    }
    let mut y = head_height
    for card in cards[index] {
      let item = card.item
      let priority = @util.trim(item.priority.unwrap_or("")).to_lower()
      let color = priority_stroke(priority)
      let inner = StringBuilder()
      inner.write_string(
        "<rect width=\"\{card_width}\" height=\"\{@svg.num(card.height)}\" fill=\"var(--_bg)\" stroke=\"var(--_b)\"\{@svg.ROUNDED}/>",
      )
      if color is Some(color) {
        inner.write_string(
          "<path class=\"pele-priority\" d=\"M2.5,5V\{@svg.num(card.height - 5)}\" fill=\"none\" \{color} stroke-width=\"3\" stroke-linecap=\"round\"/>",
        )
      }
      inner.write_string(
        text_block(
          card.label,
          CARD_PAD,
          CARD_PAD,
          " class=\"pele-label\"",
          options.icons,
        ),
      )
      if item.icon is Some(icon) && has(item.icon) {
        inner.write_string(
          @common.icon_svg(
            icon,
            card_width - CARD_PAD - glyph,
            CARD_PAD + (small_line - glyph) / 2,
            glyph,
            icons?=options.icons,
          ),
        )
      }
      let bottom = card.height - CARD_PAD
      if item.ticket is Some(ticket) && ticket != "" {
        let top = bottom - card.meta
        let href = if base_url == "" {
          None
        } else {
          @url.link_url(@url.safe_url(with_ticket(base_url, ticket)), options)
        }
        match href {
          None =>
            inner.write_string(
              text_block(
                card.ticket,
                CARD_PAD,
                top,
                " class=\"pele-ticket\" fill=\"var(--_m)\"",
                options.icons,
              ),
            )
          Some(href) => {
            inner.write_string(
              "<a href=\"\{@svg.esc(href)}\" target=\"_blank\"\{@url.rel_attr(options)}>",
            )
            inner.write_string(
              text_block(
                card.ticket,
                CARD_PAD,
                top,
                " class=\"pele-ticket\" fill=\"var(--_c)\"",
                options.icons,
              ),
            )
            inner.write_string("</a>")
            links.push({ id: item.id, href, internal: false, })
          }
        }
      }
      if item.assigned is Some(assigned) && assigned != "" {
        inner.write_string(
          text_block(
            card.assigned,
            card_width - CARD_PAD,
            bottom - card.assigned.height,
            " class=\"pele-assigned\" fill=\"var(--_m)\"",
            options.icons,
            end=true,
          ),
        )
      }
      let priority_class = if color is Some(_) {
        " pele-priority-" + replace_first_space(priority)
      } else {
        ""
      }
      body.write_string(
        "<g class=\"pele-node pele-card\{priority_class}\{@svg.class_names(item.css_classes.unwrap_or(""))}\" data-id=\"\{@svg.esc_text(item.id)}\" transform=\"translate(\{COLUMN_PAD},\{@svg.num(y)})\" font-size=\"\{small}\">\{inner.to_string()}</g>",
      )
      y += card.height + CARD_GAP
    }
    let x = left + index.to_double() % per_row * (column_width + COLUMN_GAP)
    out.write_string(
      "<g class=\"pele-cluster pele-column\{@svg.class_names(section.css_classes.unwrap_or(""))}\" data-id=\"\{@svg.esc_text(section.id)}\" transform=\"translate(\{@svg.num(x)},\{@svg.num(pad + title_height + row_tops[row])})\">\{body.to_string()}</g>",
    )
  }
  let total_width = (width + 2 * pad).ceil()
  let total_height = (board_height + title_height + 2 * pad).ceil()
  let content = @svg.label_svg(
      title,
      total_width / 2,
      pad + title.height / 2,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
    ) +
    out.to_string()
  {
    svg: @svg.svg_document(
      "kanban",
      total_width,
      total_height,
      size,
      options,
      None,
      None,
      content,
    ),
    width: total_width,
    height: total_height,
    links,
  }
}
