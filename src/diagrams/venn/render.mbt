///|
const RADIUS : Double = 100

///|
const MAX_GROWTH : Double = 1.6

///|
/// One piece of text in a region: its label, or one of its texts.
priv struct Line {
  /// The id of a text, or `None` for the label of the region.
  id : String?
  raw : String
  size : Double
  base : Int32
  mut label : @text.Label
}

///|
priv struct Region {
  sets : Array[String]
  inside : Array[Int32]
  spot : Spot
  lines : Array[Line]
  style : @svg.ResolvedStyle
}

///|
fn unique(ids : Array[String]) -> Array[String] {
  let seen : Set[String] = Set([])
  let out = []
  for id in ids {
    if !seen.contains(id) {
      seen.add(id)
      out.push(id)
    }
  }
  out
}

///|
fn text_size(lines : Array[Line]) -> (Double, Double) {
  let mut width = 0.0
  let mut height = 0.0
  for line in lines {
    width = @cmp.maximum(width, line.label.width)
    height += line.label.height
  }
  (width, height)
}

///|
fn render_venn(
  model : VennDb,
  options : @types.RenderOptions,
) -> @types.Rendered {
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.875).round()
  let tiny = (size * 0.8125).round()
  let measurer = @text.metrics_measurer
  let pad = options.padding.unwrap_or(8)
  let circles = layout_circles(model.subsets)
  let index : Map[String, Int32] = Map([])
  for i, c in circles {
    index[c.id] = i
  }
  // Styles for the same targets add up, later declarations winning.
  let styles : Map[String, Map[String, String]] = Map([])
  for declared in model.styles {
    let key = key_of(declared.targets)
    let merged = match styles.get(key) {
      Some(merged) => merged
      None => {
        let merged : Map[String, String] = Map([])
        styles[key] = merged
        merged
      }
    }
    for property, value in declared.styles {
      merged[property] = value
    }
  }
  let style_of = (key : String) => {
    match styles.get(key) {
      None => @svg.resolve_style([])
      Some(declared) => {
        let list = []
        for property, value in declared {
          list.push("\{property}:\{value}")
        }
        @svg.resolve_style(list)
      }
    }
  }
  // Circles that touch each circle; only those can cut into a region of it.
  let neighbors : Array[Array[Int32]] = circles.map(_ => [])
  for a in 0..<circles.length() {
    for b in (a + 1)..<circles.length() {
      if @util.js_hypot(
          circles[a].x - circles[b].x,
          circles[a].y - circles[b].y,
        ) <
        circles[a].r + circles[b].r {
        neighbors[a].push(b)
        neighbors[b].push(a)
      }
    }
  }
  // One region for each set and each stated overlap; a later statement about the same sets
  // replaces an earlier one.
  let stated : Map[String, VennSubset] = Map([])
  for subset in model.subsets {
    stated[key_of(subset.sets)] = subset
  }
  let regions : Map[String, Region] = Map([])
  for key, subset in stated {
    let sets = unique(subset.sets)
    let inside = sets.map(id => index[id])
    let within : Set[Int32] = Set([])
    for i in inside {
      within.add(i)
    }
    let mut smallest = inside[0]
    for i in inside {
      if circles[i].r < circles[smallest].r {
        smallest = i
      }
    }
    let style = style_of(key)
    let text = match subset.label {
      Some(label) => Some(label)
      None =>
        if subset.sets.length() == 1 {
          Some(subset.sets[0])
        } else {
          None
        }
    }
    let base = (if style.bold { @text.STYLE_BOLD } else { 0 }) |
      (if style.italic { @text.STYLE_ITALIC } else { 0 })
    let mut spot = find_spot(
      circles,
      inside,
      neighbors[smallest].filter(i => !within.contains(i)),
    )
    // A region that other circles cover, or all but cover, is written across them instead.
    if spot.margin < circles[smallest].r * 0.2 {
      spot = find_spot(circles, inside, [])
    }
    let region : Region = { sets, inside, spot, lines: [], style, }
    if text is Some(text) && text != "" {
      let font_size = if sets.length() == 1 { size } else { small }
      region.lines.push({
        id: None,
        raw: text,
        size: font_size,
        base,
        label: @text.layout_label(
          Some(text),
          false,
          measurer,
          font_size,
          4000,
          base~,
        ),
      })
    }
    regions[key] = region
  }
  for node in model.text_nodes {
    let raw = node.label.unwrap_or(node.id)
    if regions.get(key_of(node.sets)) is Some(region) {
      region.lines.push({
        id: Some(node.id),
        raw,
        size: tiny,
        base: 0,
        label: @text.layout_label(Some(raw), false, measurer, tiny, 4000),
      })
    }
  }
  // Lengths so far are in units of the layout. The scale gives the largest circle a set radius,
  // and grows, within limits, until every region holds what is written in it.
  let mut largest = 0.0
  for c in circles {
    if c.r > largest {
      largest = c.r
    }
  }
  let mut scale = if largest > 0 { RADIUS / largest } else { 1.0 }
  let mut growth = 1.0
  for _, region in regions {
    if region.spot.margin <= 0 {
      continue
    }
    let (width, height) = text_size(region.lines)
    let need = @util.js_hypot(width, height) / 2 + 4
    growth = @cmp.maximum(
      growth,
      @cmp.minimum(need / (region.spot.margin * scale), MAX_GROWTH),
    )
  }
  scale *= growth
  // What is still too wide for its region is wrapped to it.
  for _, region in regions {
    let room = @cmp.maximum(region.spot.margin * scale * 1.8, 72)
    for line in region.lines {
      if line.label.width > room {
        line.label = @text.layout_label(
          Some(line.raw),
          false,
          measurer,
          line.size,
          room,
          base=line.base,
        )
      }
    }
  }
  let mut min_x = @double.infinity
  let mut min_y = @double.infinity
  let mut max_x = @double.neg_infinity
  let mut max_y = @double.neg_infinity
  for c in circles {
    min_x = @cmp.minimum(min_x, (c.x - c.r) * scale)
    min_y = @cmp.minimum(min_y, (c.y - c.r) * scale)
    max_x = @cmp.maximum(max_x, (c.x + c.r) * scale)
    max_y = @cmp.maximum(max_y, (c.y + c.r) * scale)
  }
  for _, region in regions {
    let (wide, tall) = text_size(region.lines)
    min_x = @cmp.minimum(min_x, region.spot.x * scale - wide / 2)
    max_x = @cmp.maximum(max_x, region.spot.x * scale + wide / 2)
    min_y = @cmp.minimum(min_y, region.spot.y * scale - tall / 2)
    max_y = @cmp.maximum(max_y, region.spot.y * scale + tall / 2)
  }
  if circles.is_empty() {
    min_x = 0
    min_y = 0
    max_x = 0
    max_y = 0
  }
  let title = @text.layout_label(
    match model.title {
      Some(text) if text != "" => Some(normalize_text(text))
      other => other
    },
    false,
    measurer,
    size,
    4000,
    base=@text.STYLE_BOLD,
  )
  let title_height = if title.height > 0 { title.height + 12 } else { 0.0 }
  let inner = @cmp.maximum(max_x - min_x, title.width)
  let ox = pad + (inner - (max_x - min_x)) / 2 - min_x
  let oy = pad + title_height - min_y
  let width = (inner + 2 * pad).ceil()
  let height = (max_y - min_y + title_height + 2 * pad).ceil()
  let placed : Array[Circle] = circles.map(c => {
    id: c.id,
    x: c.x * scale + ox,
    y: c.y * scale + oy,
    r: c.r * scale,
  })
  let sets = StringBuilder()
  for i, c in placed {
    let color = @svg.series_color(i)
    let style = match regions.get(c.id) {
      Some(region) => region.style
      None => @svg.resolve_style([])
    }
    sets.write_string(
      "<circle class=\"pele-venn-set\" data-id=\"\{@svg.esc_text(c.id)}\" cx=\"\{@svg.num(c.x)}\" cy=\"\{@svg.num(c.y)}\" r=\"\{@svg.num(c.r)}\" fill=\"\{color}\" fill-opacity=\"0.2\" stroke=\"\{color}\"\{style.shape}/>",
    )
  }
  let overlaps = StringBuilder()
  let labels = StringBuilder()
  for _, region in regions {
    let id = @svg.esc_text(region.sets.join("|"))
    // An overlap is only drawn when a style gives it a look of its own; otherwise the circles show it.
    if region.sets.length() > 1 && region.style.shape != "" {
      let d = region_path(region.inside.map(i => placed[i]), @svg.num)
      if d != "" {
        overlaps.write_string(
          "<path class=\"pele-venn-overlap\" data-id=\"\{id}\" d=\"\{d}\" fill=\"none\"\{region.style.shape}/>",
        )
      }
    }
    let (_, total) = text_size(region.lines)
    if total == 0 {
      continue
    }
    let x = region.spot.x * scale + ox
    let mut y = region.spot.y * scale + oy - total / 2
    let content = StringBuilder()
    for line in region.lines {
      let attrs = match line.id {
        None =>
          " class=\"pele-label\"" +
          (if line.size == size { "" } else { " font-size=\"\{line.size}\"" }) +
          region.style.text
        Some(text) =>
          " class=\"pele-venn-text\" data-id=\"\{@svg.esc_text(text)}\" font-size=\"\{tiny}\" fill=\"var(--_m)\"" +
          style_of(text).text
      }
      content.write_string(
        @svg.label_svg(line.label, x, y + line.label.height / 2, attrs),
      )
      y += line.label.height
    }
    labels.write_string(
      "<g class=\"pele-venn-region\" data-id=\"\{id}\">\{content.to_string()}</g>",
    )
  }
  let body = @svg.label_svg(
      title,
      width / 2,
      pad + title.height / 2,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
    ) +
    "<g class=\"pele-venn-sets\">\{sets.to_string()}</g>" +
    (if overlaps.is_empty() {
      ""
    } else {
      "<g class=\"pele-venn-overlaps\">\{overlaps.to_string()}</g>"
    }) +
    (if labels.is_empty() {
      ""
    } else {
      "<g class=\"pele-venn-labels\">\{labels.to_string()}</g>"
    })
  {
    svg: @svg.svg_document(
      "venn",
      width,
      height,
      size,
      options,
      None,
      None,
      body,
    ),
    width,
    height,
    links: [],
  }
}
