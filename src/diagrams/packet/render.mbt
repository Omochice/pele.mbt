///|
/// Draws a packet diagram.
/// When the host's width is too narrow for the rows at their natural width, the packet is turned to fit it: shorter rows, narrower bits, and labels that wrap instead of shrinking.
pub fn render_packet(
  model : PacketModel,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered {
  @common.turn_to_fit(options, down => draw(model, config, options, down))
}

///|
fn packet_config(config : @types.Config, key : String) -> Json? {
  guard config.get("packet") is Some(Object(packet)) else { return None }
  packet.get(key)
}

///|
/// The largest power of two that does not exceed `count`, which is at least one.
fn power_of_two_within(count : Double) -> Double {
  let mut power = 1.0
  while power * 2 <= count {
    power *= 2
  }
  power
}

///|
/// Joins the pieces the model has split at its own rows back into the fields they came from.
/// A piece counts one bit short, which tells it from a field that happens to end at a row's end.
fn rejoin(model : PacketModel) -> Array[PacketBlock] {
  let piece = (block : PacketBlock) => block.bits == block.end - block.start
  let whole : Array[PacketBlock] = []
  for row in model.rows {
    for block in row {
      let joins = match whole.last() {
        Some(prev) =>
          piece(prev) &&
          piece(block) &&
          prev.label == block.label &&
          block.start == prev.end + 1 &&
          block.start % model.bits_per_row == 0
        None => false
      }
      if joins {
        let prev = whole[whole.length() - 1]
        prev.end = block.end
        prev.bits = prev.end - prev.start
      } else {
        whole.push({ ..block, })
      }
    }
  }
  whole
}

///|
/// Splits each field only where a row of `bits_per_row` ends.
fn split_into_rows(
  whole : Array[PacketBlock],
  bits_per_row : Double,
) -> Array[Array[PacketBlock]] {
  let rows : Array[Array[PacketBlock]] = []
  for block in whole {
    let mut start = block.start
    while start <= block.end {
      let end = @util.js_min(
        block.end,
        ((start / bits_per_row).floor() + 1) * bits_per_row - 1,
      )
      let index = (start / bits_per_row).floor().to_int()
      while rows.length() <= index {
        rows.push([])
      }
      rows[index].push({ ..block, start, end, })
      start = end + 1
    }
  }
  rows
}

///|
fn draw(
  model : PacketModel,
  config : @types.Config,
  options : @types.RenderOptions,
  down : Bool,
) -> @types.Rendered {
  let size = options.font_size.unwrap_or(16)
  let label_size = (size * 0.875).round()
  let bit_size = (size * 0.625).round()
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let row_height = packet_option(config, "rowHeight", 32, 1, 400)
  let mut bit_width = packet_option(config, "bitWidth", 32, 1, 400)
  let padding_x = packet_option(config, "paddingX", 5, 0, 400)
  let padding_y = packet_option(config, "paddingY", 5, 0, 400)
  let show_bits = !(packet_config(config, "showBits") is Some(False))
  let descending = packet_config(config, "bitOrder")
    is Some(String("descending"))
  let mut bits_per_row = model.bits_per_row
  let mut rows = model.rows
  let available = options.max_width.unwrap_or(320)
  if down {
    let count = @util.js_max(
      1,
      ((available - 2 * pad) / @util.js_min(bit_width, 18)).floor(),
    )
    // A byte is the shortest row.
    // Below that every label is one character to a line, and a long packet is a row to a bit.
    bits_per_row = @util.js_min(
      bits_per_row,
      @util.js_max(8, power_of_two_within(count)),
    )
    let last = match model.rows.last() {
      Some(row) =>
        match row.last() {
          Some(block) => block.end
          None => 0
        }
      None => 0
    }
    if ((last + 1) / bits_per_row).ceil() > 10000 {
      bits_per_row = model.bits_per_row
    }
    bit_width = @util.js_min(
      bit_width,
      @util.js_max(18, (available - 2 * pad) / bits_per_row),
    )
    rows = split_into_rows(rejoin(model), bits_per_row)
  }
  let gap = @util.js_min(padding_x, bit_width - 1)
  let labels : Array[Array[@text.Label]] = if down {
    rows.map(row => {
      row.map(block => {
        let room = @util.js_max(
          1,
          (block.end - block.start + 1) * bit_width - gap - 6,
        )
        @common.literal_label(
          @util.trim(@text.decode_entities(block.label)),
          measurer,
          label_size,
          room,
        )
      })
    })
  } else {
    []
  }
  // Bit numbers sit above each row and need room of their own.
  let numbers = if show_bits { bit_size + 4 } else { 0 }
  let row_heights = rows.mapi((index, _) => {
    let mut height = row_height
    if down {
      for label in labels[index] {
        height = @util.js_max(height, label.height + 10)
      }
    }
    height
  })
  let tops = []
  let mut rows_height = 0.0
  for height in row_heights {
    tops.push(rows_height)
    rows_height += numbers + height + padding_y
  }
  if rows.length() > 0 {
    rows_height -= padding_y
  }
  let width = if rows.length() > 0 { bits_per_row * bit_width - gap } else { 0 }
  let title = @text.layout_label(
    model.title,
    false,
    measurer,
    size,
    if down {
      @common.title_room(options)
    } else {
      4000
    },
    base=@text.STYLE_BOLD,
  )
  let title_height = if title.height > 0 {
    title.height + (if rows_height > 0 { 12 } else { 0 })
  } else {
    0
  }
  // The pieces of a field split across rows share its label, so each width is fitted once.
  let fits : Map[String, @common.Fitted?] = Map([])
  let fit = (label : String, max : Double) => {
    let key = "\{max}:\{label}"
    match fits.get(key) {
      Some(fitted) => fitted
      None => {
        let fitted = @common.fit_text(
          @util.trim(@text.decode_entities(label)),
          max,
          label_size,
          (size * 0.5).round(),
          measurer,
        )
        fits[key] = fitted
        fitted
      }
    }
  }
  let left = pad + @util.js_max(0, (title.width - width) / 2)
  let fields = StringBuilder()
  let bits = StringBuilder()
  for index, row in rows {
    let y = pad + tops[index] + numbers
    let height = row_heights[index]
    for position, block in row {
      let count = block.end - block.start + 1
      let first = block.start % bits_per_row
      let x = left +
        (if descending { bits_per_row - first - count } else { first }) *
        bit_width
      let w = count * bit_width - gap
      fields.write_string(
        "<g class=\"pele-node\" data-id=\"\{block.start}-\{block.end}\"><rect x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y)}\" width=\"\{@svg.num(w)}\" height=\"\{@svg.num(height)}\" fill=\"var(--_s)\" stroke=\"var(--_b)\"\{@svg.ROUNDED}/>",
      )
      if down {
        fields.write_string(
          @svg.label_svg(labels[index][position], x + w / 2, y + height / 2, ""),
        )
      } else if fit(block.label, w - 6) is Some(text) && text.size <= height {
        let font_size = if text.size == label_size {
          ""
        } else {
          " font-size=\"\{@svg.num(text.size)}\""
        }
        fields.write_string(
          "<text x=\"\{@svg.num(x + w / 2)}\" y=\"\{@svg.num(y + height / 2 + text.size * 0.35)}\"\{font_size}>\{@svg.esc(text.text)}</text>",
        )
      }
      fields.write_string("</g>")
      if !show_bits {
        continue
      }
      let leading = if descending { block.end } else { block.start }
      let trailing = if descending { block.start } else { block.end }
      if count == 1 {
        bits.write_string(
          "<text x=\"\{@svg.num(x + w / 2)}\" y=\"\{@svg.num(y - 4)}\" text-anchor=\"middle\">\{leading}</text>",
        )
      } else {
        bits.write_string(
          "<text x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y - 4)}\">\{leading}</text><text x=\"\{@svg.num(x + w)}\" y=\"\{@svg.num(y - 4)}\" text-anchor=\"end\">\{trailing}</text>",
        )
      }
    }
  }
  let total_width = (@util.js_max(width, title.width) + 2 * pad).ceil()
  let total_height = (rows_height + title_height + 2 * pad).ceil()
  let content = StringBuilder()
  if fields.to_string() != "" {
    content.write_string(
      "<g class=\"pele-packet-fields\" font-size=\"\{@svg.num(label_size)}\" text-anchor=\"middle\">\{fields.to_string()}</g>",
    )
  }
  if bits.to_string() != "" {
    content.write_string(
      "<g class=\"pele-packet-bits\" font-size=\"\{@svg.num(bit_size)}\" fill=\"var(--_m)\">\{bits.to_string()}</g>",
    )
  }
  // Mermaid puts a packet's title under it.
  content.write_string(
    @svg.label_svg(
      title,
      total_width / 2,
      total_height - pad - title.height / 2,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
    ),
  )
  {
    svg: @svg.svg_document(
      "packet",
      total_width,
      total_height,
      size,
      options,
      model.acc_title,
      model.acc_descr,
      content.to_string(),
    ),
    width: total_width,
    height: total_height,
    links: [],
  }
}
