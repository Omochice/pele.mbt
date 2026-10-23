// pele also lays out $$math$$ from its typesetter, which cannot reach a typst plugin yet, so
// labels behave as pele's do without one and leave math as text.

///|
/// A run of text with one emphasis, or an icon in place of text.
pub(all) struct Span {
  mut text : String
  style : Int32
  /// The name of the icon the span draws; its `text` is then empty.
  icon : String?
  mut width : Double
  /// Typeset math the span stands for, drawn in place of its text.
  math : MathMarkup?
}

///|
/// Text laid out in lines of spans, measured.
pub(all) struct Label {
  lines : Array[Array[Span]]
  widths : Array[Double]
  width : Double
  height : Double
  size : Double
  line_height : Double
  /// The height of each line, present only when math makes a line taller than `line_height`.
  heights : Array[Double]?
}

///|
const LINE_HEIGHT : Double = 1.5

///|
/// The room an icon takes in a line, in multiples of the font size.
const ICON_WIDTH : Double = 1.25

///|
fn empty_label() -> Label {
  {
    lines: [],
    widths: [],
    width: 0,
    height: 0,
    size: 0,
    line_height: 0,
    heights: None,
  }
}

///|
/// Break between any two Chinese or Japanese characters.
/// Hangul is left out: Korean puts spaces between words.
fn is_cjk(c : Int32) -> Bool {
  (c >= 0x2e80 && c <= 0x9fff) ||
  (c >= 0xf900 && c <= 0xfaff) ||
  (c >= 0xff00 && c <= 0xff60)
}

///|
let close_marks = "、。，．：；！？）］｝」』】〕〉》〙〗ー…‥・ゝゞぁぃぅぇぉっゃゅょゎァィゥェォッャュョヮ,.:;!?)]}"

///|
let open_marks = "（［｛「『【〔〈《〘〖([{"

///|
fn is_close(c : Int32) -> Bool {
  c >= 0 && close_marks.contains_code_unit(c.to_uint16())
}

///|
fn is_open(c : Int32) -> Bool {
  c >= 0 && open_marks.contains_code_unit(c.to_uint16())
}

///|
fn skip_space(text : String, from : Int32) -> Int32 {
  let mut i = from
  while @util.is_space(@util.code_at(text, i)) {
    i += 1
  }
  i
}

///|
/// The end of the wrapping piece at `i`, as
/// `\s*(?:[OPEN]*[CJK][CLOSE]*|[^\s CJK]+[CLOSE]*)\s*|\s+` matches it, or -1.
fn piece_end(text : String, i : Int32) -> Int32 {
  let j = skip_space(text, i)
  let mut k = j
  while is_open(@util.code_at(text, k)) {
    k += 1
  }
  for m = k; m >= j; m = m - 1 {
    if is_cjk(@util.code_at(text, m)) {
      let mut e = m + 1
      while is_close(@util.code_at(text, e)) {
        e += 1
      }
      return skip_space(text, e)
    }
  }
  let c = @util.code_at(text, j)
  if c != -1 && !@util.is_space(c) && !is_cjk(c) {
    let mut e = j
    while e < text.length() &&
          !@util.is_space(@util.code_at(text, e)) &&
          !is_cjk(@util.code_at(text, e)) {
      e += 1
    }
    while is_close(@util.code_at(text, e)) {
      e += 1
    }
    return skip_space(text, e)
  }
  if @util.is_space(@util.code_at(text, i)) {
    return skip_space(text, i)
  }
  -1
}

///|
/// The pieces a line may break between.
fn pieces(text : String) -> Array[String] {
  let out = []
  let mut i = 0
  while i < text.length() {
    let end = piece_end(text, i)
    if end > i {
      out.push(@util.slice(text, i, end~))
      i = end
    } else {
      i += 1
    }
  }
  out
}

///|
fn dedent(text : String) -> String {
  let lines = text.split("\n").map(line => line.to_owned()).to_array()
  let mut least = -1
  for line in lines {
    if @util.trim(line) == "" {
      continue
    }
    let indent = line.length() - @util.trim_start(line).length()
    if least == -1 || indent < least {
      least = indent
    }
  }
  if least <= 0 {
    return text
  }
  lines
  .map(line => {
    let indent = line.length() - @util.trim_start(line).length()
    @util.slice(line, if least < indent { least } else { indent })
  })
  .join("\n")
}

///|
/// Whether the span is text, which a neighbor of the same emphasis can join.
fn plain(span : Span) -> Bool {
  span.icon is None
}

///|
fn push_plain(line : Array[Span], text : String, style : Int32) -> Unit {
  let decoded = decode_entities(text)
  match line.last() {
    Some(last) if plain(last) && last.style == style =>
      last.text = last.text + decoded
    _ => line.push({ text: decoded, style, icon: None, width: 0, math: None, })
  }
}

///|
fn push_text(line : Array[Span], text : String, style : Int32) -> Unit {
  if text != "" {
    push_plain(line, text, style)
  }
}

///|
/// The next `(fa[bklrs]?):fa-([\w-]+)` at or after `from`, as its start and end.
fn find_icon(text : String, from : Int32) -> (Int32, Int32)? {
  let mut p = @util.index_of(text, "fa", from~)
  while p != -1 {
    let q = p + 2
    let variant = @util.code_at(text, q)
    let name = if variant >= 0 &&
      "bklrs".contains_code_unit(variant.to_uint16()) &&
      @util.starts_with_at(text, ":fa-", q + 1) {
      q + 5
    } else if @util.starts_with_at(text, ":fa-", q) {
      q + 4
    } else {
      -1
    }
    if name != -1 {
      let mut end = name
      while @util.is_word(@util.code_at(text, end)) ||
            @util.code_at(text, end) == '-'.to_int() {
        end += 1
      }
      if end > name {
        return Some((p, end))
      }
    }
    p = @util.index_of(text, "fa", from=p + 1)
  }
  None
}

///|
/// An icon the host does not have leaves no gap, nor the space that set it off from the text.
fn push_icons(line : Array[Span], text : String, style : Int32) -> Unit {
  if !text.contains(":fa-") {
    push_text(line, text, style)
    return
  }
  let mut last = 0
  let mut search = 0
  while find_icon(text, search) is Some((start, end)) {
    push_text(line, @util.slice(text, last, end=start), style)
    last = end
    search = end
    let icon = @util.slice(text, start, end~)
    if icon_markup(icon) != "" {
      line.push({ text: "", style, icon: Some(icon), width: 0, math: None, })
    } else if @util.code_at(text, last) == ' '.to_int() {
      last += 1
    } else if last == text.length() {
      if line.last() is Some(before) && plain(before) {
        before.text = @util.trim_end(before.text)
      }
    }
  }
  push_text(line, @util.slice(text, last), style)
}

///|
/// The end of the tag `<\/?([a-zA-Z][\w-]*)(?:\s[^<>]*)?\/?>` at `at`, and its name.
fn tag_at(source : String, at : Int32) -> (Int32, String)? {
  let mut i = at + 1
  if @util.code_at(source, i) == '/'.to_int() {
    i += 1
  }
  if !@util.is_letter(@util.code_at(source, i)) {
    return None
  }
  let name_start = i
  while @util.is_word(@util.code_at(source, i)) ||
        @util.code_at(source, i) == '-'.to_int() {
    i += 1
  }
  let name = @util.slice(source, name_start, end=i)
  let c = @util.code_at(source, i)
  if @util.is_space(c) {
    let mut m = i + 1
    while m < source.length() &&
          @util.code_at(source, m) != '<'.to_int() &&
          @util.code_at(source, m) != '>'.to_int() {
      m += 1
    }
    return if @util.code_at(source, m) == '>'.to_int() {
      Some((m + 1, name))
    } else {
      None
    }
  }
  if c == '/'.to_int() && @util.code_at(source, i + 1) == '>'.to_int() {
    return Some((i + 2, name))
  }
  if c == '>'.to_int() {
    return Some((i + 1, name))
  }
  None
}

///|
/// Splits inline HTML and, for markdown labels, emphasis markers into styled spans.
/// Returns the HTML emphasis open at the end, as tags can span explicit breaks.
fn inline(
  line : Array[Span],
  source : String,
  markdown : Bool,
  base : Int32,
  open_style : Int32,
) -> Int32 {
  let mut html_style = open_style
  let mut style = html_style
  let mut marked = 0
  let text = StringBuilder()
  let flush = () => {
    push_icons(line, text.to_string(), style)
    text.reset()
  }
  let n = source.length()
  let mut i = 0
  while i < n {
    let ch = @util.code_at(source, i)
    if ch == '<'.to_int() {
      if tag_at(source, i) is Some((end, name)) {
        let tag = name.to_lower()
        let closing = @util.code_at(source, i + 1) == '/'.to_int()
        let bit = if tag == "b" || tag == "strong" {
          STYLE_BOLD
        } else if tag == "i" || tag == "em" {
          STYLE_ITALIC
        } else {
          0
        }
        if bit != 0 {
          flush()
          html_style = if closing {
            (html_style & bit.lnot()) | (base & bit)
          } else {
            html_style | bit
          }
          style = if closing {
            (style & bit.lnot()) | (base & bit)
          } else {
            style | bit
          }
        }
        i = end
        continue
      }
    } else if markdown && (ch == '*'.to_int() || ch == '_'.to_int()) {
      let double = @util.code_at(source, i + 1) == ch
      let bit = if double { STYLE_BOLD } else { STYLE_ITALIC }
      let length = if double { 2 } else { 1 }
      let open = (marked & bit) == 0
      let prev = if i > 0 { @util.code_at(source, i - 1) } else { ' '.to_int() }
      let next = if i + length < n {
        @util.code_at(source, i + length)
      } else {
        ' '.to_int()
      }
      let marker = @util.slice(source, i, end=i + length)
      let can_open = open &&
        !@util.is_space(next) &&
        @util.index_of(source, marker, from=i + length) != -1
      let can_close = !open && !@util.is_space(prev)
      let wordy = ch == '_'.to_int() &&
        @util.is_word(prev) &&
        @util.is_word(next)
      if (can_open || can_close) && !wordy {
        flush()
        marked = if can_open { marked | bit } else { marked & bit.lnot() }
        style = if can_open {
          style | bit
        } else {
          (style & bit.lnot()) | (base & bit)
        }
        i += length
        continue
      }
    }
    @util.write_range(text, source, i, i + 1)
    i += 1
  }
  flush()
  html_style
}

///|
fn measure_spans(
  line : Array[Span],
  measurer : TextMeasurer,
  size : Double,
) -> Double {
  let mut total = 0.0
  for span in line {
    span.width = if span.icon is Some(_) {
      size * ICON_WIDTH
    } else {
      measurer.width(span.text, size, span.style)
    }
    total += span.width
  }
  total
}

///|
/// Breaks a line into lines no wider than `max` where it can, appending them to `out`.
fn wrap(
  line : Array[Span],
  measurer : TextMeasurer,
  size : Double,
  max : Double,
  out : Array[Array[Span]],
  widths : Array[Double],
) -> Unit {
  let mut current : Array[Span] = []
  let mut width = 0.0
  let commit = () => {
    if current.last() is Some(last) && plain(last) {
      let trimmed = @util.trim_end(last.text)
      if trimmed != last.text {
        last.text = trimmed
        let w = measurer.width(trimmed, size, last.style)
        width += w - last.width
        last.width = w
      }
    }
    out.push(current)
    widths.push(width)
    current = []
    width = 0
  }
  for span in line {
    if span.icon is Some(_) {
      let w = size * ICON_WIDTH
      if width > 0 && width + w > max {
        commit()
      }
      current.push({ ..span, width: w, })
      width += w
      continue
    }
    for piece in pieces(span.text) {
      let mut part = piece
      if width > 0 &&
        width + measurer.width(@util.trim_end(part), size, span.style) > max {
        commit()
        part = @util.trim_start(part)
      }
      match current.last() {
        Some(last) if plain(last) && last.style == span.style => {
          last.text = last.text + part
          last.width = measurer.width(last.text, size, last.style)
          width = 0
          for s in current {
            width += s.width
          }
        }
        _ => {
          let w = measurer.width(part, size, span.style)
          current.push({
            text: part,
            style: span.style,
            icon: None,
            width: w,
            math: None,
          })
          width += w
        }
      }
    }
  }
  if current.length() > 0 || out.length() == 0 {
    commit()
  }
}

///|
/// Splits at `<br>`, `\n` written out, and line breaks, as `/<br\s*\/?>|\\n|\n/gi` does.
fn split_breaks(text : String) -> Array[String] {
  let parts = []
  let mut last = 0
  let mut i = 0
  while i < text.length() {
    let c = @util.code_at(text, i)
    let mut end = -1
    if c == '\n'.to_int() {
      end = i + 1
    } else if c == '\\'.to_int() &&
      (
        @util.code_at(text, i + 1) == 'n'.to_int() ||
        @util.code_at(text, i + 1) == 'N'.to_int()
      ) {
      end = i + 2
    } else if c == '<'.to_int() &&
      @util.slice(text, i + 1, end=i + 3).to_lower() == "br" {
      let mut k = skip_space(text, i + 3)
      if @util.code_at(text, k) == '/'.to_int() {
        k += 1
      }
      if @util.code_at(text, k) == '>'.to_int() {
        end = k + 1
      }
    }
    if end == -1 {
      i += 1
    } else {
      parts.push(@util.slice(text, last, end=i))
      last = end
      i = end
    }
  }
  parts.push(@util.slice(text, last))
  parts
}

///|
fn layout_lines(
  raw : String,
  markdown : Bool,
  measurer : TextMeasurer,
  size : Double,
  max_width : Double,
  base : Int32,
  line_height : Double,
) -> Label {
  let source = if markdown {
    @util.trim(dedent(@util.normalize_line_breaks(raw)))
  } else {
    @util.trim(raw)
  }
  let lines : Array[Array[Span]] = []
  let widths : Array[Double] = []
  let mut html_style = base
  for part in split_breaks(source) {
    let line = []
    html_style = inline(line, @util.trim(part), markdown, base, html_style)
    let w = measure_spans(line, measurer, size)
    if w > max_width {
      wrap(line, measurer, size, max_width, lines, widths)
    } else {
      lines.push(line)
      widths.push(w)
    }
  }
  let mut width = 0.0
  for w in widths {
    if w > width {
      width = w
    }
  }
  {
    lines,
    widths,
    width,
    height: lines.length().to_double() * line_height,
    size,
    line_height,
    heights: None,
  }
}

///|
fn has_markup(text : String) -> Bool {
  for i in 0..<text.length() {
    let c = @util.code_at(text, i)
    if c == '<'.to_int() ||
      c == '\\'.to_int() ||
      c == '\n'.to_int() ||
      c == '*'.to_int() ||
      c == '_'.to_int() {
      return true
    }
  }
  has_icon_marker(text)
}

///|
/// Whether `fa[bklrs]?:fa-` occurs in the text.
fn has_icon_marker(text : String) -> Bool {
  let mut p = @util.index_of(text, "fa")
  while p != -1 {
    let variant = @util.code_at(text, p + 2)
    if @util.starts_with_at(text, ":fa-", p + 2) ||
      (
        variant >= 0 &&
        "bklrs".contains_code_unit(variant.to_uint16()) &&
        @util.starts_with_at(text, ":fa-", p + 3)
      ) {
      return true
    }
    p = @util.index_of(text, "fa", from=p + 1)
  }
  false
}

///|
fn has_cjk(text : String) -> Bool {
  for i in 0..<text.length() {
    if is_cjk(@util.code_at(text, i)) {
      return true
    }
  }
  false
}

///|
/// Lays out label text with inline HTML emphasis, explicit breaks, and wrapping at `max_width`.
/// `markdown` also reads `*` and `_` emphasis; `base` is the emphasis of the whole label.
pub fn layout_label(
  raw : String?,
  markdown : Bool,
  measurer : TextMeasurer,
  size : Double,
  max_width : Double,
  base~ : Int32 = 0,
) -> Label {
  guard raw is Some(raw) && raw != "" else { return empty_label() }
  let line_height = (size * LINE_HEIGHT).round()
  if !has_markup(raw) && !raw.contains("&") && !raw.contains("\u{fb02}") {
    let text = @util.trim(raw)
    let width = measurer.width(text, size, base)
    if width <= max_width || !(text.contains(" ") || has_cjk(text)) {
      return {
        lines: [[{ text, style: base, icon: None, width, math: None, }]],
        widths: [width],
        width,
        height: line_height,
        size,
        line_height,
        heights: None,
      }
    }
    let lines : Array[Array[Span]] = []
    let widths : Array[Double] = []
    wrap(
      [{ text, style: base, icon: None, width, math: None, }],
      measurer,
      size,
      max_width,
      lines,
      widths,
    )
    let mut widest = 0.0
    for w in widths {
      if w > widest {
        widest = w
      }
    }
    return {
      lines,
      widths,
      width: widest,
      height: lines.length().to_double() * line_height,
      size,
      line_height,
      heights: None,
    }
  }
  layout_lines(raw, markdown, measurer, size, max_width, base, line_height)
}
