///|
/// Writes a measured label as `write_label` does under the attributes `attrs` followed by the
/// `style` attribute `resolve_style` makes of `css`, which is escaped a piece at a time.
/// Math under such a label takes its color from the attributes written whole, so a label with
/// math still escapes all of `css` at once.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_label_styled(
  out : Markup,
  label : @text.Label,
  cx : Double,
  cy : Double,
  attrs : String,
  css : String,
  icons? : @types.IconResolver,
) -> Unit raise @errors.PeleError {
  write_label_parts(
    out,
    label,
    cx,
    cy,
    out => {
      out.write(attrs)
      write_style(out, css)
    },
    // An escaped style holds no `"`, so it neither holds nor completes ` font-weight="` or
    // ` font-style="`.
    () => attrs.contains(" font-weight=\""),
    () => attrs.contains(" font-style=\""),
    () => attrs + attribute(css),
    icons?,
  )
}

///|
/// Writes a measured label as `write_label_styled` does under the attributes `before`, the id
/// `esc_text` makes of `id`, and `after`, escaping the id a piece at a time as well.
/// Math under such a label takes its color from the attributes written whole, so a label with
/// math still escapes all of the id at once.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_label_with_id(
  out : Markup,
  label : @text.Label,
  cx : Double,
  cy : Double,
  before : String,
  id : String,
  after : String,
  css : String,
  icons? : @types.IconResolver,
) -> Unit raise @errors.PeleError {
  write_label_parts(
    out,
    label,
    cx,
    cy,
    out => {
      out.write(before)
      out.write_esc_text(id)
      out.write(after)
      write_style(out, css)
    },
    // An escaped style holds no `"`, so only the attributes around the id can give a weight or a
    // style of their own.
    () => holds_around_id(before, id, after, " font-weight=\""),
    () => holds_around_id(before, id, after, " font-style=\""),
    () => before + esc_text(id) + after + attribute(css),
    icons?,
  )
}

///|
/// Whether `before`, the id `esc_text` makes of `id`, and `after`, written one after another, hold
/// `needle`, which ends with its only `"`.
/// An escaped id holds no `"`, so a match that takes in any of the id ends at the first `"` of
/// `after`, and only as much of the id's end as that match could take in is escaped.
fn holds_around_id(
  before : String,
  id : String,
  after : String,
  needle : String,
) -> Bool {
  if before.contains(needle) || after.contains(needle) {
    return true
  }
  let quote = @util.index_of(after, "\"")
  let head = @util.slice(needle, 0, end=-1)
  if quote < 0 || quote >= head.length() {
    return false
  }
  let lead = @util.slice(after, 0, end=quote)
  if !head.has_suffix(lead) {
    return false
  }
  let rest = @util.slice(head, 0, end=head.length() - lead.length())
  let tail = escaped_tail(@text.decode_entities(id), rest.length())
  if tail.length() >= rest.length() {
    tail.has_suffix(rest)
  } else {
    (before + tail).has_suffix(rest)
  }
}

///|
/// The last `count` code units of `text` escaped as `esc` escapes it, or all of it when it is
/// shorter, escaping only as much of its end as that takes, since escaping a code unit never
/// depends on its neighbours.
fn escaped_tail(text : String, count : Int32) -> String {
  let mut taken = count
  while true {
    let tail = esc(@util.slice(text, -taken))
    if tail.length() >= count || taken >= text.length() {
      return @util.slice(tail, -count)
    }
    taken = taken * 2
  }
  ""
}
