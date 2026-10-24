///|
const MIN_TEXT : Double = 124

///|
const MAX_TEXT : Double = 200

///|
const GAP : Double = 12

///|
const BAND_PAD : Double = 6

///|
const GUTTER : Double = 24

///|
const LEVEL : Double = 26

///|
const DOT_STEP : Double = 13

///|
const LEGEND_GAP : Double = 20

///|
priv struct LegendItem {
  name : String
  label : @text.Label
  x : Double
  y : Double
  h : Double
}

///|
/// A run of tasks that share a section.
priv struct Run {
  start : Int32
  count : Int32
  label : @text.Label?
}

///|
/// Draws a journey, from left to right, or from top to bottom when that fits `maxWidth` better.
pub fn render_journey(
  model : JourneyDb,
  _config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  @common.turn_to_fit(options, down => {
    if down {
      vertical_journey(model, options)
    } else {
      horizontal_journey(model, options)
    }
  })
}

///|
fn horizontal_journey(
  model : JourneyDb,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.875).round()
  let tiny = (size * 0.75).round()
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let tasks = model.tasks
  let n = tasks.length()
  let names = named(journey_actors(tasks))
  let actor : Map[String, Int32] = Map([])
  for i, name in names {
    actor[name] = i
  }

  // Cards widen, up to a point, for a word that would not fit; past that the word is cut.
  let mut text_w = MIN_TEXT
  let mut labels = tasks.map(task => {
    @common.plain_label(Some(task.task), measurer, small, text_w)
  })
  let mut widest = 0.0
  for label in labels {
    widest = @util.js_max(widest, label.width)
  }
  if widest > text_w {
    text_w = @util.js_min(widest.ceil(), MAX_TEXT)
    let fit = text_w
    labels = tasks.map(task => {
      @common.fit_label(Some(task.task), measurer, small, fit)
    })
  }
  let card_w = text_w + 2.0 * PAD_X
  let pitch = card_w + GAP
  let plot_w = if n > 0 { n.to_double() * pitch - GAP } else { 0.0 }

  let line_h = (small * 1.5).round()
  let limit = @util.js_max(plot_w, 240)
  let legend : Array[LegendItem] = []
  let mut legend_w = 0.0
  let mut legend_h = 0.0
  let mut lx = 0.0
  for name in names {
    let label = @common.fit_label(
      Some(name),
      measurer,
      small,
      limit - 2.0 * DOT - 6,
    )
    let w = 2.0 * DOT + 6 + label.width
    if lx > 0 && lx + w > limit {
      lx = 0
      legend_h += 4
    }
    let y = if lx > 0 { legend[legend.length() - 1].y } else { legend_h }
    let h = @util.js_max(label.height, line_h)
    legend.push({ name, label, x: lx, y, h, })
    lx += w
    legend_w = @util.js_max(legend_w, lx)
    legend_h = @util.js_max(legend_h, y + h)
    lx += LEGEND_GAP
  }

  let body_w = if n > 0 { GUTTER + plot_w } else { 0.0 }
  let title = @common.fit_label(
    model.title,
    measurer,
    size,
    @util.js_max(body_w, 320),
    base=@text.STYLE_BOLD,
  )
  let title_h = if title.height > 0 { title.height + 16 } else { 0.0 }
  let width = @util.js_max(
    @util.js_max(body_w, title.width),
    if n > 0 {
      GUTTER + legend_w
    } else {
      0.0
    },
  )
  let left = pad + (width - body_w) / 2 + GUTTER
  let top = pad + title_h

  // A band covers a run of tasks that share a section, as in Mermaid; a section with no tasks draws nothing.
  let runs : Array[Run] = []
  let mut band_h = 0.0
  let mut i = 0
  while i < n {
    let mut end = i + 1
    while end < n && tasks[end].section == tasks[i].section {
      end += 1
    }
    let mut label = None
    if tasks[i].section != "" {
      let fitted = @common.fit_label(
        Some(tasks[i].section),
        measurer,
        small,
        (end - i).to_double() * pitch - GAP - 2.0 * PAD_X,
        base=@text.STYLE_BOLD,
      )
      band_h = @util.js_max(
        band_h,
        @util.js_max(fitted.height, line_h) + 2.0 * BAND_PAD,
      )
      label = Some(fitted)
    }
    runs.push({ start: i, count: end - i, label, })
    i = end
  }

  let mut text_h = line_h
  for label in labels {
    text_h = @util.js_max(text_h, label.height)
  }
  let dots_h = if names.length() > 0 { 2.0 * DOT + 6 } else { 0.0 }
  let card_h = text_h + dots_h + 2.0 * PAD_Y
  let cards_y = top + (if band_h > 0 { band_h + BAND_PAD } else { 0.0 })
  let chart_top = cards_y + card_h + FACE + 16
  let chart_bottom = chart_top + 4.0 * LEVEL
  let right = left + plot_w

  let body = @svg.Markup::new()
  let mut bottom = top
  if n > 0 {
    let grid = StringBuilder()
    let scale = StringBuilder()
    for score = 5; score >= 1; score = score - 1 {
      let y = chart_top + (5 - score).to_double() * LEVEL
      grid.write_string(
        "M\{@svg.num(left - 6)},\{@svg.num(y)}H\{@svg.num(right)}",
      )
      scale.write_string(
        "<text x=\"\{@svg.num(left - 12)}\" y=\"\{@svg.num(y + tiny * 0.35)}\">\{score}</text>",
      )
    }
    body.write(
      "<path class=\"pele-grid\" d=\"\{grid}\" fill=\"none\" stroke=\"var(--_a)\"/>" +
      "<g class=\"pele-scale\" font-size=\"\{tiny}\" text-anchor=\"end\" fill=\"var(--_m)\">\{scale}</g>",
    )

    let line = @svg.Markup::new()
    let stems = @svg.Markup::new()
    let faces = @svg.Markup::new()
    let cards : Array[@svg.Markup] = []
    for index, task in tasks {
      let x = left + index.to_double() * pitch
      let cx = x + card_w / 2
      let score = task.score
      let level = if score.is_nan() {
        3.0
      } else {
        @util.js_min(5, @util.js_max(1, score))
      }
      let y = chart_top + (5 - level) * LEVEL
      line.write(
        "\{if index == 0 { "M" } else { "L" }}\{@svg.num(cx)},\{@svg.num(y)}",
      )
      stems.write(
        "M\{@svg.num(cx)},\{@svg.num(cards_y + card_h)}V\{@svg.num(y - FACE)}",
      )
      faces.write(face(cx, y, mood_of(score)))

      let dots = @svg.Markup::new()
      let people = named(task.people)
      let count = people.length()
      let step = @util.js_min(
        DOT_STEP,
        (card_w - 2.0 * PAD_X - 2.0 * DOT) /
        @util.js_max((count - 1).to_double(), 1),
      )
      for k, name in people {
        let dot_x = cx + (k.to_double() - (count - 1).to_double() / 2) * step
        let dot_y = cards_y + card_h - PAD_Y - DOT
        let color = @svg.series_color(actor.get(name).unwrap_or(0))
        dots.write(
          "<circle class=\"pele-actor\" cx=\"\{@svg.num(dot_x)}\" cy=\"\{@svg.num(dot_y)}\" r=\"\{DOT}\" fill=\"\{color}\" stroke=\"var(--_s)\"><title>",
        )
        dots.write_esc_text(name)
        dots.write("</title></circle>")
      }
      let card = @svg.Markup::new()
      card.write("<g class=\"pele-node pele-task\" data-id=\"")
      card.write_esc_text(@util.trim(task.task))
      card.write(
        "\"><rect x=\"\{@svg.num(x)}\" y=\"\{@svg.num(cards_y)}\" width=\"\{@svg.num(card_w)}\" height=\"\{@svg.num(card_h)}\" fill=\"var(--_s)\" stroke=\"var(--_b)\"\{@svg.ROUNDED}/>",
      )
      @svg.write_label(
        card,
        labels[index],
        cx,
        cards_y + PAD_Y + text_h / 2,
        " font-size=\"\{small}\"",
      )
      card.write_markup(dots)
      card.write("</g>")
      cards.push(card)
    }
    body.write_group(
      "<path class=\"pele-stems\" d=\"", stems, "\" fill=\"none\" stroke=\"var(--_b)\" stroke-dasharray=\"2 3\"/>",
    )
    if n > 1 {
      body.write_group(
        "<path class=\"pele-edge\" d=\"", line, "\" fill=\"none\" stroke=\"var(--_l)\" stroke-linejoin=\"round\"/>",
      )
    }
    body.write_markup(faces)

    for run in runs {
      let members = @svg.Markup::new()
      for k in run.start..<(run.start + run.count) {
        members.write_markup(cards[k])
      }
      match run.label {
        None => body.write_markup(members)
        Some(label) => {
          let x = left + run.start.to_double() * pitch
          let w = run.count.to_double() * pitch - GAP
          body.write("<g class=\"pele-cluster pele-section\" data-id=\"")
          body.write_esc_text(@util.trim(tasks[run.start].section))
          body.write(
            "\"><rect x=\"\{@svg.num(x)}\" y=\"\{@svg.num(top)}\" width=\"\{@svg.num(w)}\" height=\"\{@svg.num(band_h)}\" fill=\"var(--_a)\"\{@svg.ROUNDED}/>",
          )
          @svg.write_label(
            body,
            label,
            x + w / 2,
            top + band_h / 2,
            " font-size=\"\{small}\" font-weight=\"var(--_hw)\"",
          )
          body.write_markup(members)
          body.write("</g>")
        }
      }
    }
    bottom = chart_bottom + FACE

    if legend.length() > 0 {
      let x0 = left + (plot_w - legend_w) / 2
      let y0 = bottom + 16
      let items = @svg.Markup::new()
      for item in legend {
        let cy = y0 + item.y + item.h / 2
        let color = @svg.series_color(actor.get(item.name).unwrap_or(0))
        items.write("<g class=\"pele-legend-item\" data-id=\"")
        items.write_esc_text(item.name)
        items.write(
          "\"><circle cx=\"\{@svg.num(x0 + item.x + DOT)}\" cy=\"\{@svg.num(cy)}\" r=\"\{DOT}\" fill=\"\{color}\"/>",
        )
        @svg.write_label(
          items,
          item.label,
          x0 + item.x + 2.0 * DOT + 6 + item.label.width / 2,
          cy,
          "",
        )
        items.write("</g>")
      }
      body.write_group(
        "<g class=\"pele-legend\" font-size=\"\{small}\">",
        items,
        "</g>",
      )
      bottom = y0 + legend_h
    }
  }

  let total_width = (width + 2 * pad).ceil()
  let total_height = (@util.js_max(bottom, pad) + pad).ceil()
  let content = @svg.Markup::new()
  @svg.write_label(
    content,
    title,
    pad + width / 2,
    pad + title.height / 2,
    " class=\"pele-title\" font-weight=\"var(--_tw)\"",
  )
  content.write_markup(body)
  {
    svg: @svg.markup_document(
      "journey",
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
