///|
/// A field, or the piece of one that lies in a single row.
pub(all) struct PacketBlock {
  mut start : Double
  mut end : Double
  /// As Mermaid counts it: one less than the width for the pieces of a field split across rows.
  mut bits : Double
  label : String
}

///|
/// A packet diagram ready to be drawn.
pub(all) struct PacketModel {
  title : String?
  acc_title : String?
  acc_descr : String?
  bits_per_row : Double
  rows : Array[Array[PacketBlock]]
}

///|
const MAX_ROWS : Int32 = 10000

///|
/// The numeric option `key` of the `packet` config, or `fallback` when it is missing, not a number, or below `min`.
/// A value above `max` is lowered to it.
pub fn packet_option(
  config : @types.Config,
  key : String,
  fallback : Double,
  min : Double,
  max : Double,
) -> Double {
  guard config.get("packet") is Some(Object(packet)) else { return fallback }
  match packet.get(key) {
    Some(Number(value, ..)) if value >= min => @util.js_min(value, max)
    _ => fallback
  }
}

///|
fn invalid(message : String) -> @errors.PeleError {
  @errors.pele_error(message, code=Semantic, kind="packet")
}

///|
fn non_empty(value : String?) -> String? {
  match value {
    Some("") => None
    _ => value
  }
}

///|
/// Does what `text.replace(/\n\s+/g, '\n')` does.
fn join_indented_lines(text : String) -> String {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    @util.write_range(out, text, i, i + 1)
    if @util.code_at(text, i) == '\n'.to_int() &&
      @util.is_space(@util.code_at(text, i + 1)) {
      i += 1
      while @util.is_space(@util.code_at(text, i)) {
        i += 1
      }
    } else {
      i += 1
    }
  }
  out.to_string()
}

///|
/// Checks the fields of a packet diagram and lays them out in rows.
/// `title` is the front matter title, used when the diagram has none.
/// Raises a semantic `PeleError` for a field Mermaid rejects.
pub fn build_packet(
  ast : PacketAst,
  config : @types.Config,
  title : String?,
) -> PacketModel raise @errors.PeleError {
  let bits_per_row = packet_option(config, "bitsPerRow", 32, 1, 4096).floor()
  let rows : Array[Array[PacketBlock]] = []
  let mut last_bit = -1.0
  let mut word : Array[PacketBlock] = []
  let mut row = 1.0
  for block in ast.blocks {
    if block.start is Some(start) && block.end is Some(end) && end < start {
      raise invalid(
        "Packet block \{start} - \{end} is invalid. End must be greater than start.",
      )
    }
    let mut start = block.start.unwrap_or(last_bit + 1)
    if start != last_bit + 1 {
      raise invalid(
        "Packet block \{start} - \{block.end.unwrap_or(start)} is not contiguous. It should start from \{last_bit + 1}.",
      )
    }
    if block.bits == Some(0.0) {
      raise invalid(
        "Packet block \{start} is invalid. Cannot have a zero bit field.",
      )
    }
    let end = block.end.unwrap_or(start + block.bits.unwrap_or(1) - 1)
    let mut bits = block.bits.unwrap_or(end - start + 1)
    last_bit = end
    while word.length().to_double() <= bits_per_row + 1 &&
          rows.length() < MAX_ROWS {
      let row_end = row * bits_per_row - 1
      if end <= row_end {
        word.push({ start, end, bits, label: block.label, })
        if end == row_end {
          rows.push(word)
          word = []
          row += 1
        }
        break
      }
      word.push({
        start,
        end: row_end,
        bits: row_end - start,
        label: block.label,
      })
      rows.push(word)
      word = []
      row += 1
      start = row_end + 1
      bits = end - start
    }
  }
  if word.length() > 0 {
    rows.push(word)
  }
  {
    title: match non_empty(ast.title) {
      Some(_) as own => own
      None => title
    },
    acc_title: non_empty(ast.acc_title).map(@util.trim_start),
    acc_descr: non_empty(ast.acc_descr).map(join_indented_lines),
    bits_per_row,
    rows,
  }
}
