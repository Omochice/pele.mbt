///|
/// A run of text with one emphasis, or an icon or typeset math in place of text.
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
/// Lines of one wrapped label sit closer, so the label reads as one block.
const WRAPPED_LINE_HEIGHT : Double = 1.3

///|
/// The line height of a label of `count` lines, given that of a single line.
fn snug(count : Int32, size : Double, line_height : Double) -> Double {
  if count > 1 {
    (size * WRAPPED_LINE_HEIGHT).round()
  } else {
    line_height
  }
}

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
/// A break hint: a zero-width space, or a soft hyphen, which shows as `-` where a line breaks.
fn is_hint(c : Int32) -> Bool {
  c == 0x200b || c == 0xad
}

///|
fn has_hint(text : String) -> Bool {
  text.contains_code_unit(0x200b) || text.contains_code_unit(0xad)
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
/// `\s*(?:[OPEN]*[CJK][CLOSE]*|[^\s CJK HINT]+[HINT]*[CLOSE]*|[HINT]+)\s*|\s+` matches it, or -1.
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
  if c != -1 && !@util.is_space(c) && !is_cjk(c) && !is_hint(c) {
    let mut e = j
    while e < text.length() &&
          !@util.is_space(@util.code_at(text, e)) &&
          !is_cjk(@util.code_at(text, e)) &&
          !is_hint(@util.code_at(text, e)) {
      e += 1
    }
    while is_hint(@util.code_at(text, e)) {
      e += 1
    }
    while is_close(@util.code_at(text, e)) {
      e += 1
    }
    return skip_space(text, e)
  }
  if is_hint(c) {
    let mut e = j
    while is_hint(@util.code_at(text, e)) {
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
/// The first of the private use characters that stand for TeX while a label's markup is read, so
/// that tags and emphasis markers inside TeX are left alone.
const MARK : Int32 = 0xe000

///|
const MAX_MARKS : Int32 = 0x1900

///|
fn is_mark(c : Int32) -> Bool {
  c >= 0xe000 && c <= 0xf8ff
}

///|
/// The TeX each mark of the label being laid out stands for, and what it was typeset as.
priv struct Marks {
  tex : Array[String]
  math : Array[MathMarkup?]
}

///|
let marks : Ref[Marks?] = { val: None, }

///|
/// Whether the span is text, which a neighbor of the same emphasis can join.
fn plain(span : Span) -> Bool {
  span.icon is None && span.math is None
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
  if text == "" {
    return
  }
  guard marks.val is Some(found) && has_mark(text) else {
    push_plain(line, text, style)
    return
  }
  let mut last = 0
  for i in 0..<text.length() {
    let c = @util.code_at(text, i)
    if !is_mark(c) {
      continue
    }
    if i > last {
      push_plain(line, @util.slice(text, last, end=i), style)
    }
    last = i + 1
    let at = c - MARK
    match found.math[at] {
      Some(math) =>
        line.push({
          text: "",
          style,
          icon: None,
          width: math.width,
          math: Some(math),
        })
      None => push_plain(line, "$$\{found.tex[at]}$$", style)
    }
  }
  if last < text.length() {
    push_plain(line, @util.slice(text, last), style)
  }
}

///|
fn has_mark(text : String) -> Bool {
  for i in 0..<text.length() {
    if is_mark(@util.code_at(text, i)) {
      return true
    }
  }
  false
}

///|
fn is_line_terminator(c : Int32) -> Bool {
  c == '\n'.to_int() || c == '\r'.to_int() || c == 0x2028 || c == 0x2029
}

///|
/// The end of the TeX of `\$\$(.+?)\$\$` matched at `at`, or -1.
fn math_end(text : String, at : Int32) -> Int32 {
  if !@util.starts_with_at(text, "$$", at) {
    return -1
  }
  let mut e = at + 2
  while e < text.length() && !is_line_terminator(@util.code_at(text, e)) {
    if @util.starts_with_at(text, "$$", e + 1) {
      return e + 1
    }
    e += 1
  }
  -1
}

///|
/// Replaces each `$$TeX$$` with a mark, as `raw.replace(/\$\$(.+?)\$\$/g, …)` does, collecting
/// the TeX in `found`.
fn mark_math(raw : String, found : Marks) -> String {
  let out = StringBuilder()
  let mut last = 0
  let mut at = 0
  while at < raw.length() {
    let end = math_end(raw, at)
    if end == -1 {
      at += 1
      continue
    }
    if found.tex.length() < MAX_MARKS {
      @util.write_range(out, raw, last, at)
      found.tex.push(@util.slice(raw, at + 2, end~))
      out.write_char(Int32::unsafe_to_char(MARK + found.tex.length() - 1))
      last = end + 2
    }
    at = end + 2
  }
  @util.write_range(out, raw, last, raw.length())
  out.to_string()
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
/// The HTML tags open at the end of a line, as they can span explicit breaks.
priv struct Open {
  mut style : Int32
  /// Only the innermost `<sub>` or `<sup>` shifts text.
  shifts : Array[Int32]
}

///|
fn tag_style(tag : String) -> Int32 {
  match tag {
    "b" | "strong" => STYLE_BOLD
    "i" | "em" => STYLE_ITALIC
    "code" => STYLE_MONO
    "sub" => STYLE_SUB
    "sup" => STYLE_SUP
    "u" => STYLE_UNDERLINE
    _ => 0
  }
}

///|
/// The HTML elements whose tags a label drops, keeping their text.
let html_tags : Set[String] = Set::from_array(
  ("a abbr address article aside audio b bdi bdo big blockquote body br button caption center cite code col " +
  "colgroup data dd del details dfn dialog div dl dt em embed fieldset figcaption figure font footer form h1 h2 " +
  "h3 h4 h5 h6 head header hr html i iframe img input ins kbd label legend li link main map mark meta meter nav " +
  "noscript object ol optgroup option output p picture pre progress q rp rt ruby s samp script section select " +
  "small source span strike strong style sub summary sup table tbody td template textarea tfoot th thead time " +
  "title tr track tt u ul var video wbr")
  .split(" ")
  .map(name => name.to_owned())
  .to_array(),
)

///|
/// Splits inline HTML and, for markdown labels, emphasis markers into styled spans.
fn inline(
  line : Array[Span],
  source : String,
  markdown : Bool,
  base : Int32,
  open : Open,
) -> Unit {
  let mut style = open.style
  let mut marked = 0
  // The text between tags is taken as slices of the source, joined only across a tag that sets no
  // emphasis, because copying a long line a code unit at a time into a doubling builder outgrows
  // what wasm can allocate.
  let text = StringBuilder()
  let mut joined = false
  let mut run = 0
  let flush = (at : Int32) => {
    let piece = if joined {
      @util.write_range(text, source, run, at)
      let piece = text.to_string()
      text.reset()
      piece
    } else {
      @util.slice(source, run, end=at)
    }
    joined = false
    let shift = match open.shifts.last() {
      Some(bit) => bit
      None => 0
    }
    push_icons(line, piece, style | shift)
  }
  let n = source.length()
  let mut i = 0
  while i < n {
    let ch = @util.code_at(source, i)
    if ch == '<'.to_int() {
      if tag_at(source, i) is Some((end, name)) {
        let tag = name.to_lower()
        let bit = tag_style(tag)
        // Other HTML tags are dropped and their text kept.
        // Anything else shaped like a tag, such as the type in List<T>, is text.
        if bit != 0 || html_tags.contains(tag) {
          let closing = @util.code_at(source, i + 1) == '/'.to_int()
          if (bit & (STYLE_SUB | STYLE_SUP)) != 0 {
            flush(i)
            if !closing {
              open.shifts.push(bit)
            } else {
              for at = open.shifts.length() - 1; at >= 0; at = at - 1 {
                if open.shifts[at] == bit {
                  open.shifts.remove(at) |> ignore
                  break
                }
              }
            }
          } else if bit != 0 {
            flush(i)
            open.style = if closing {
              (open.style & bit.lnot()) | (base & bit)
            } else {
              open.style | bit
            }
            style = if closing {
              (style & bit.lnot()) | (base & bit)
            } else {
              style | bit
            }
          } else {
            @util.write_range(text, source, run, i)
            joined = true
          }
          run = end
          i = end
          continue
        }
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
        flush(i)
        marked = if can_open { marked | bit } else { marked & bit.lnot() }
        style = if can_open {
          style | bit
        } else {
          (style & bit.lnot()) | (base & bit)
        }
        i += length
        run = i
        continue
      }
    }
    i += 1
  }
  flush(n)
}

///|
fn measure_spans(
  line : Array[Span],
  measurer : TextMeasurer,
  size : Double,
) -> Double {
  let mut total = 0.0
  for span in line {
    span.width = match (span.icon, span.math) {
      (Some(_), _) => size * ICON_WIDTH
      (None, Some(math)) => math.width
      (None, None) => measurer.width(span.text, size, span.style)
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
  let commit = (hyphen : Bool) => {
    if current.last() is Some(last) && plain(last) {
      let mut trimmed = @util.trim_end(last.text)
      if hyphen && last.text.has_suffix("\u{ad}") {
        trimmed = @util.slice(trimmed, 0, end=trimmed.length() - 1) + "-"
      }
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
  for at, span in line {
    if !plain(span) {
      let w = match span.math {
        Some(math) => math.width
        None => size * ICON_WIDTH
      }
      if width > 0 && width + w > max {
        commit(false)
      }
      current.push({ ..span, width: w, })
      width += w
      continue
    }
    let pieces = pieces(span.text)
    // A piece ending in a soft hyphen fits if its `-` does, or if the rest of the word does, which
    // hides the hyphen.
    // The line only grows along a word, so no later hyphen in it fits either, and the remaining
    // width of each word makes this one check.
    let soft = span.text.contains_code_unit(0xad)
    let n = if soft { pieces.length() } else { 0 }
    let own = FixedArray::make(n, 0.0)
    let rest = FixedArray::make(n + 1, 0.0)
    for q = n - 1; q >= 0; q = q - 1 {
      // A soft hyphen before a space is no break of its own: the space is.
      let shy = pieces[q].has_suffix("\u{ad}")
      let end = @util.trim_end(pieces[q])
      own[q] = measurer.width(
        if shy {
          @util.slice(end, 0, end=end.length() - 1)
        } else {
          end
        },
        size,
        span.style,
      )
      // Word width beyond this span is unknown.
      rest[q] = if !shy {
        own[q]
      } else if q == n - 1 {
        if at == line.length() - 1 {
          own[q]
        } else {
          @double.infinity
        }
      } else {
        own[q] + rest[q + 1]
      }
    }
    for p, piece in pieces {
      let mut part = piece
      let part_width = if soft {
        own[p]
      } else {
        measurer.width(@util.trim_end(part), size, span.style)
      }
      let fits = if !soft || !part.has_suffix("\u{ad}") {
        width + part_width <= max
      } else {
        width +
        measurer.width(
          @util.slice(part, 0, end=part.length() - 1) + "-",
          size,
          span.style,
        ) <=
        max ||
        width + rest[p] <= max
      }
      if width > 0 && !fits {
        // Breaking at whitespace leaves a preceding soft hyphen hidden.
        commit(@util.trim_start(part) == part)
        part = @util.trim_start(part)
      }
      match current.last() {
        Some(last) if plain(last) && last.style == span.style => {
          last.text = last.text + part
          // Remeasuring for each zero-width piece would take quadratic time.
          if part_width > 0 || @util.trim_end(part) != part {
            let before = last.width
            last.width = measurer.width(last.text, size, last.style)
            width += last.width - before
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
    commit(false)
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
  let open = { style: base, shifts: [], }
  for part in split_breaks(source) {
    let line = []
    inline(line, @util.trim(part), markdown, base, open)
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
  let line_height = snug(lines.length(), size, line_height)
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
  if math_active() && raw.contains("$$") && !has_mark(raw) {
    let found = { tex: [], math: [], }
    let marked = mark_math(raw, found)
    if found.tex.length() > 0 {
      for tex in found.tex {
        found.math.push(typeset(decode_entities(tex), size))
      }
      return layout_markup(
        marked,
        markdown,
        measurer,
        size,
        max_width,
        base,
        line_height,
        Some(found),
      )
    }
  }
  if !has_markup(raw) && !raw.contains("&") && !raw.contains("\u{fb02}") {
    let text = @util.trim(raw)
    let width = measurer.width(text, size, base)
    if width <= max_width ||
      !(text.contains(" ") || has_cjk(text) || has_hint(text)) {
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
    let line_height = snug(lines.length(), size, line_height)
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
  layout_markup(
    raw,
    markdown,
    measurer,
    size,
    max_width,
    base,
    line_height,
    None,
  )
}

///|
/// Lays out markup with `found` as the TeX its marks stand for.
fn layout_markup(
  raw : String,
  markdown : Bool,
  measurer : TextMeasurer,
  size : Double,
  max_width : Double,
  base : Int32,
  line_height : Double,
  found : Marks?,
) -> Label {
  let outer = marks.val
  marks.val = found
  defer {
    marks.val = outer
  }
  let label = layout_lines(
    raw, markdown, measurer, size, max_width, base, line_height,
  )
  if found is Some(_) {
    with_heights(label)
  } else {
    label
  }
}

///|
/// The label with line heights for the math it holds, or without them when no line needs more
/// than `line_height`.
pub fn with_heights(label : Label) -> Label {
  let mut heights : Array[Double]? = None
  for i, line in label.lines {
    let mut h = label.line_height
    for span in line {
      if span.math is Some(math) {
        h = @util.js_max(h, (math.height + label.size / 4).ceil())
      }
    }
    if h != label.line_height && heights is None {
      heights = Some(label.lines.map(_ => label.line_height))
    }
    if heights is Some(heights) {
      heights[i] = h
    }
  }
  guard heights is Some(heights) else {
    return if label.heights is None {
      label
    } else {
      {
        ..label,
        heights: None,
        height: label.lines.length().to_double() * label.line_height,
      }
    }
  }
  let mut height = 0.0
  for h in heights {
    height += h
  }
  { ..label, heights: Some(heights), height, }
}

///|
/// Whether a line holds typeset math.
pub fn has_math(line : Array[Span]) -> Bool {
  line.iter().any(span => span.math is Some(_))
}

///|
/// The middle of line `i`, from the top of the label.
pub fn line_middle(label : Label, i : Int32) -> Double {
  guard label.heights is Some(heights) else {
    return (i.to_double() + 0.5) * label.line_height
  }
  let mut top = 0.0
  for k in 0..<i {
    top += heights[k]
  }
  top + heights[i] / 2
}

///|
/// Line `i` of the label as a label of its own.
pub fn label_line(label : Label, i : Int32) -> Label {
  let width = label.widths[i]
  let height = match label.heights {
    Some(heights) => heights[i]
    None => label.line_height
  }
  {
    lines: [label.lines[i]],
    widths: [width],
    width,
    height,
    size: label.size,
    line_height: label.line_height,
    heights: if height != label.line_height {
      Some([height])
    } else {
      None
    },
  }
}
