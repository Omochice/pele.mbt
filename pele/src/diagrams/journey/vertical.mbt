///|
/// The layout for a narrow drawing: one card per task, one below the other, joined by short edges.
fn vertical_journey(
  model : JourneyDb,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.875).round()
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let room = @util.js_max(140, options.max_width.unwrap_or(320) - 2 * pad)
  let title = @common.fit_label(
    model.title,
    measurer,
    size,
    room,
    base=@text.STYLE_BOLD,
  )
  let names = named(journey_actors(model.tasks))
  let actors : Map[String, Int32] = Map([])
  for i, name in names {
    actors[name] = i
  }
  let mut y = pad + (if title.height != 0 { title.height + 16 } else { 0.0 })
  let mut section : String? = None
  let body = @svg.Markup::new()
  let mut width = title.width
  let count = model.tasks.length()
  for index, task in model.tasks {
    if section != Some(task.section) {
      section = Some(task.section)
      let head = @common.fit_label(
        Some(task.section),
        measurer,
        size,
        room - 16,
        base=@text.STYLE_BOLD,
      )
      if head.height != 0 {
        @svg.write_label(
          body,
          head,
          pad + 8 + head.width / 2,
          y + head.height / 2,
          " class=\"pele-cluster-label\" font-weight=\"var(--_hw)\"",
        )
        width = @util.js_max(width, head.width + 16)
        y += head.height + 8
      }
    }
    let label = @common.fit_label(Some(task.task), measurer, small, room - 72)
    let people = named(task.people).map(name => {
      (name, @common.fit_label(Some(name), measurer, small, room - 44))
    })
    let text_h = @util.js_max(label.height, 42)
    let mut h = 2.0 * PAD_Y + text_h
    for person in people {
      h += @util.js_max(16, person.1.height) + 4
    }
    let w = @util.js_max(room, label.width + 72)
    body.write(
      "<g class=\"pele-node pele-journey-step\" data-id=\"\{index}\"><rect x=\"\{@svg.num(pad)}\" y=\"\{@svg.num(y)}\" width=\"\{@svg.num(w)}\" height=\"\{@svg.num(h)}\" fill=\"var(--_s)\" stroke=\"var(--_b)\"\{@svg.ROUNDED}/>",
    )
    @svg.write_label(
      body,
      label,
      pad + PAD_X + label.width / 2,
      y + PAD_Y + label.height / 2,
      " class=\"pele-label\"",
    )
    let cx = pad + w - 28
    body.write(face(cx, y + PAD_Y + FACE, mood_of(task.score)))
    if !task.score.is_nan() {
      let shown = @util.js_min(5, @util.js_max(1, task.score))
      body.write(
        "<text class=\"pele-journey-score\" x=\"\{@svg.num(cx)}\" y=\"\{@svg.num(y + PAD_Y + 2.0 * FACE + small)}\" font-size=\"\{small}\" text-anchor=\"middle\">\{@svg.num(shown)}</text>",
      )
    }
    let mut py = y + PAD_Y + text_h + 4
    for person in people {
      let ph = @util.js_max(16, person.1.height)
      let color = @svg.series_color(actors.get(person.0).unwrap_or(0))
      body.write(
        "<circle class=\"pele-actor\" cx=\"\{@svg.num(pad + 16)}\" cy=\"\{@svg.num(py + ph / 2)}\" r=\"\{DOT}\" fill=\"\{color}\"/>",
      )
      @svg.write_label(
        body,
        person.1,
        pad + 28 + person.1.width / 2,
        py + ph / 2,
        " class=\"pele-journey-actor\" font-size=\"\{small}\"",
      )
      py += ph + 4
    }
    body.write("</g>")
    y += h
    if index + 1 < count {
      body.write(
        "<path class=\"pele-edge\" d=\"M\{@svg.num(pad + w / 2)},\{@svg.num(y)}v16\" fill=\"none\" stroke=\"var(--_l)\"/>",
      )
    }
    y += 16
    width = @util.js_max(width, w)
  }
  let total_width = (width + 2 * pad).ceil()
  let height = (@util.js_max(
    pad + title.height,
    y - (if count > 0 { 16.0 } else { 0.0 }),
  ) +
  pad).ceil()
  let content = @svg.Markup::new()
  @svg.write_label(
    content,
    title,
    total_width / 2,
    pad + title.height / 2,
    " class=\"pele-title\" font-weight=\"var(--_tw)\"",
  )
  content.write_markup(body)
  {
    svg: @svg.markup_document(
      "journey",
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
