// The parts of dayjs 1.11 that Mermaid's gantt code relies on, with the plugins it loads (custom parse format,
// advanced format, ISO week) and the English locale.
// Quirks are kept, because a date is accepted only when formatting the parsed result gives back the input.

///|
let months : Array[String] = [
  "January", "February", "March", "April", "May", "June", "July", "August", "September",
  "October", "November", "December",
]

///|
let weekdays : Array[String] = [
  "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday",
]

///|
const WEEK : Double = 604800000

///|
const DEFAULT_FORMAT : String = "YYYY-MM-DDTHH:mm:ssZ"

///|
fn valid(date : @date.JsDate) -> Bool {
  !date.time.is_nan()
}

///|
/// JavaScript's `a || b` for numbers.
fn or_else(value : Double, fallback : Double) -> Double {
  if value == 0 || value.is_nan() {
    fallback
  } else {
    value
  }
}

///|
fn truthy(value : Double?) -> Bool {
  match value {
    Some(v) => v != 0 && !v.is_nan()
    None => false
  }
}

///|
fn pad(value : Double, length : Int32) -> String {
  let s = value.to_string()
  if s.length() >= length {
    s
  } else {
    "0".repeat(length - s.length()) + s
  }
}

///|
fn suffix(index : Double) -> String? {
  if index == 0 {
    Some("th")
  } else if index == 1 {
    Some("st")
  } else if index == 2 {
    Some("nd")
  } else if index == 3 {
    Some("rd")
  } else {
    None
  }
}

///|
fn ordinal(n : Double) -> String {
  let v = n % 100
  let tail = match suffix((v - 20) % 10) {
    Some(s) => s
    None => suffix(v).unwrap_or("th")
  }
  n.to_string() + tail
}

///|
fn utc_offset(date : @date.JsDate) -> Double {
  let offset = -(date.timezone_offset() / 15).round() * 15
  if offset == 0 {
    0
  } else {
    offset
  }
}

///|
fn zone(date : @date.JsDate) -> String {
  let offset = utc_offset(date)
  let minutes = offset.abs()
  (if offset >= 0 { "+" } else { "-" }) +
  pad((minutes / 60).floor(), 2) +
  ":" +
  pad(minutes % 60, 2)
}

///|
fn iso_weekday(date : @date.JsDate) -> Double {
  or_else(date.day(), 7)
}

///|
/// A copy of the date moved by whole calendar days.
fn add_days(date : @date.JsDate, days : Double) -> @date.JsDate {
  let next = date.copy()
  next.set_date(next.date() + days)
  next
}

///|
fn days_in_month(date : @date.JsDate) -> Double {
  let last = @date.JsDate::from_local(date.full_year(), date.month() + 1, day=0)
  last.set_hours(23, minutes=59, seconds=59, ms=999)
  last.date()
}

///|
/// Sets the month or the year, keeping the day of the month unless the new month is shorter.
fn set_calendar(
  date : @date.JsDate,
  apply : (@date.JsDate) -> Unit,
) -> @date.JsDate {
  let next = date.copy()
  next.set_date(1)
  apply(next)
  next.set_date(@util.js_min(date.date(), days_in_month(next)))
  next
}

///|
/// Adds an amount of a dayjs unit (`ms`, `s`, `m`, `h`, `d`, `w`, `M` or `y`) to a date.
pub fn add_time(
  date : @date.JsDate,
  amount : Double,
  unit : String,
) -> @date.JsDate {
  match unit {
    "M" => set_calendar(date, d => d.set_month(date.month() + amount))
    "y" => set_calendar(date, d => d.set_full_year(date.full_year() + amount))
    "d" => add_days(date, amount.round())
    "w" => add_days(date, (7.0 * amount).round())
    "h" => @date.JsDate::from_time(date.time + amount * 3600000)
    "m" => @date.JsDate::from_time(date.time + amount * 60000)
    "s" => @date.JsDate::from_time(date.time + amount * 1000)
    _ => @date.JsDate::from_time(date.time + amount)
  }
}

///|
fn week_thursday(date : @date.JsDate) -> @date.JsDate {
  add_days(date, 4 - iso_weekday(date))
}

///|
fn iso_week(date : @date.JsDate) -> Double {
  let thursday = week_thursday(date)
  let jan1 = @date.JsDate::from_local(thursday.full_year(), 0, day=1)
  let weekday = iso_weekday(jan1)
  let first = add_days(jan1, 4 - weekday + (if weekday > 4 { 7 } else { 0 }))
  let zone_delta = (utc_offset(first) - utc_offset(thursday)) * 60000
  let weeks = (thursday.time - first.time - zone_delta) / WEEK
  (if weeks < 0 { or_else(weeks.ceil(), 0) } else { weeks.floor() }) + 1
}

///|
/// The end of `[literal]` at `i`, past the closing bracket, as `\[([^\]]+)]` matches it.
fn bracket_end(text : String, i : Int32) -> Int32? {
  if @util.code_at(text, i) != 91 {
    return None
  }
  let close = @util.index_of(text, "]", from=i + 1)
  if close > i + 1 {
    Some(close + 1)
  } else {
    None
  }
}

///|
/// The length of the longest run of `c` at `i`, up to `most`.
fn run_of(text : String, i : Int32, c : Int32, most : Int32) -> Int32 {
  let mut n = 0
  while n < most && @util.code_at(text, i + n) == c {
    n += 1
  }
  n
}

///|
/// The first of `words` found at `i`.
fn word_at(text : String, i : Int32, words : Array[String]) -> String? {
  for word in words {
    if @util.starts_with_at(text, word, i) {
      return Some(word)
    }
  }
  None
}

///|
let advanced_words : Array[String] = [
  "Q", "wo", "ww", "w", "WW", "W", "zzz", "z", "gggg", "GGGG", "Do", "X", "x", "kk",
  "k", "S",
]

///|
/// The first pass of dayjs's advanced format plugin, or None when it meets a token Mermaid cannot format.
fn format_advanced(date : @date.JsDate, text : String) -> String? {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    if bracket_end(text, i) is Some(end) {
      @util.write_range(out, text, i, end)
      i = end
      continue
    }
    guard word_at(text, i, advanced_words) is Some(word) else {
      out.write_char(text.unsafe_get(i).to_int().unsafe_to_char())
      i += 1
      continue
    }
    let replaced = match word {
      "Q" => ((date.month() + 1) / 3).ceil().to_string()
      "Do" => "[" + ordinal(date.date()) + "]"
      "GGGG" => week_thursday(date).full_year().to_string()
      "W" => iso_week(date).to_string()
      "WW" => pad(iso_week(date), 2)
      "k" => or_else(date.hours(), 24).to_string()
      "kk" => pad(or_else(date.hours(), 24), 2)
      "X" => (date.time / 1000).floor().to_string()
      "x" => date.time.to_string()
      "gggg" | "wo" | "w" | "ww" | "z" | "zzz" => return None
      _ => word
    }
    out.write_string(replaced)
    i += word.length()
  }
  Some(out.to_string())
}

///|
/// The length of the dayjs format token at `i`, as `YYYY|YY|M{1,4}|D{1,2}|d{1,4}|H{1,2}|h{1,2}|a|A|m{1,2}|s{1,2}|Z{1,2}|SSS` matches it.
fn format_token(text : String, i : Int32) -> Int32 {
  let c = @util.code_at(text, i)
  match c {
    89 =>
      if @util.starts_with_at(text, "YYYY", i) {
        4
      } else if @util.starts_with_at(text, "YY", i) {
        2
      } else {
        0
      }
    77 => run_of(text, i, c, 4)
    68 | 72 | 104 | 109 | 115 | 90 => run_of(text, i, c, 2)
    100 => run_of(text, i, c, 4)
    97 | 65 => 1
    83 => if @util.starts_with_at(text, "SSS", i) { 3 } else { 0 }
    _ => 0
  }
}

///|
fn format_field(date : @date.JsDate, token : String) -> String {
  let hours = date.hours()
  match token {
    "YY" => @util.slice(date.full_year().to_string(), -2)
    "YYYY" => pad(date.full_year(), 4)
    "M" => (date.month() + 1).to_string()
    "MM" => pad(date.month() + 1, 2)
    "MMM" => @util.slice(months[date.month().to_int()], 0, end=3)
    "MMMM" => months[date.month().to_int()]
    "D" => date.date().to_string()
    "DD" => pad(date.date(), 2)
    "d" => date.day().to_string()
    "dd" => @util.slice(weekdays[date.day().to_int()], 0, end=2)
    "ddd" => @util.slice(weekdays[date.day().to_int()], 0, end=3)
    "dddd" => weekdays[date.day().to_int()]
    "H" => hours.to_string()
    "HH" => pad(hours, 2)
    "h" => or_else(hours % 12, 12).to_string()
    "hh" => pad(or_else(hours % 12, 12), 2)
    "a" => if hours < 12 { "am" } else { "pm" }
    "A" => if hours < 12 { "AM" } else { "PM" }
    "m" => date.minutes().to_string()
    "mm" => pad(date.minutes(), 2)
    "s" => date.seconds().to_string()
    "ss" => pad(date.seconds(), 2)
    "SSS" => pad(date.milliseconds(), 3)
    "Z" => zone(date)
    _ => {
      let z = zone(date)
      @util.slice(z, 0, end=3) + @util.slice(z, 4)
    }
  }
}

///|
/// Formats a date with a dayjs format, or gives None for tokens that need dayjs plugins Mermaid does not load.
pub fn format_date(date : @date.JsDate, template : String) -> String? {
  if !valid(date) {
    return Some("Invalid Date")
  }
  let text = if template == "" { DEFAULT_FORMAT } else { template }
  if text == "YYYY-MM-DD" {
    return Some(iso_date(date))
  }
  guard format_advanced(date, text) is Some(advanced) else { return None }
  let out = StringBuilder()
  let mut i = 0
  while i < advanced.length() {
    if bracket_end(advanced, i) is Some(end) {
      @util.write_range(out, advanced, i + 1, end - 1)
      i = end
      continue
    }
    let length = format_token(advanced, i)
    if length == 0 {
      out.write_char(advanced.unsafe_get(i).to_int().unsafe_to_char())
      i += 1
      continue
    }
    out.write_string(
      format_field(date, @util.slice(advanced, i, end=i + length)),
    )
    i += length
  }
  Some(out.to_string())
}

///|
/// The date as `YYYY-MM-DD` in local time, the way dayjs writes it.
fn iso_date(date : @date.JsDate) -> String {
  let year = date.full_year()
  let month = date.month() + 1
  let day = date.date()
  (if year >= 1000 && year <= 9999 { year.to_string() } else { pad(year, 4) }) +
  (if month < 10 { "-0" } else { "-" }) +
  month.to_string() +
  (if day < 10 { "-0" } else { "-" }) +
  day.to_string()
}

///|
priv struct Fields {
  mut year : Double?
  mut month : Double?
  mut day : Double?
  mut day_given : Bool
  mut hours : Double?
  mut minutes : Double?
  mut seconds : Double?
  mut milliseconds : Double?
  mut week : Double?
  mut offset : Double?
  mut afternoon : Bool?
}

///|
/// The shapes dayjs reads a token's text with.
priv enum Shape {
  One
  Two
  Three
  Four
  OneOrTwo
  Signed
  Offset
  Word
}

///|
priv enum Step {
  Literal(String)
  Read(String, Shape)
}

///|
fn shape_of(token : String) -> Shape? {
  match token {
    "A" | "a" | "Do" | "MMM" | "MMMM" => Some(Word)
    "Q" | "S" => Some(One)
    "SS" | "DD" | "ww" | "MM" | "YY" => Some(Two)
    "SSS" => Some(Three)
    "YYYY" => Some(Four)
    "s" | "ss" | "m" | "mm" | "H" | "h" | "HH" | "hh" | "D" | "w" | "M" =>
      Some(OneOrTwo)
    "Y" => Some(Signed)
    "Z" | "ZZ" => Some(Offset)
    _ => None
  }
}

///|
fn is_separator(c : Int32) -> Bool {
  match c {
    45 | 95 | 58 | 47 | 46 | 44 | 40 | 41 => true
    _ => @util.is_space(c)
  }
}

///|
/// The length of the parse token at `i`, as dayjs's `(\[[^[]*\])|([-_:/.,()\s]+)|(A|a|Q|YYYY|YY?|ww?|MM?M?M?|Do|DD?|hh?|HH?|mm?|ss?|S{1,3}|z|ZZ?)` matches it.
fn parse_token(text : String, i : Int32) -> Int32 {
  let c = @util.code_at(text, i)
  if c == 91 {
    let mut stop = i + 1
    while stop < text.length() && @util.code_at(text, stop) != 91 {
      stop += 1
    }
    let mut close = stop - 1
    while close > i && @util.code_at(text, close) != 93 {
      close -= 1
    }
    if close > i {
      return close - i + 1
    }
  }
  if is_separator(c) {
    let mut end = i + 1
    while end < text.length() && is_separator(@util.code_at(text, end)) {
      end += 1
    }
    return end - i
  }
  match c {
    65 | 97 | 81 | 122 => 1
    89 =>
      if @util.starts_with_at(text, "YYYY", i) {
        4
      } else {
        run_of(text, i, c, 2)
      }
    119 | 104 | 72 | 109 | 115 | 90 => run_of(text, i, c, 2)
    77 => run_of(text, i, c, 4)
    68 =>
      if @util.code_at(text, i + 1) == 111 {
        2
      } else {
        run_of(text, i, c, 2)
      }
    83 => run_of(text, i, c, 3)
    _ => 0
  }
}

///|
/// Whether the format holds `L` or `l` outside `[literal]` text, which dayjs reads through a locale table
/// the English locale does not have.
fn has_localized(template : String) -> Bool {
  let mut i = 0
  while i < template.length() {
    if bracket_end(template, i) is Some(end) {
      i = end
      continue
    }
    let c = @util.code_at(template, i)
    if c == 76 || c == 108 {
      return true
    }
    i += 1
  }
  false
}

///|
fn compile(template : String) -> Array[Step]? {
  if has_localized(template) {
    return None
  }
  let steps = []
  let mut i = 0
  while i < template.length() {
    let length = parse_token(template, i)
    if length == 0 {
      i += 1
      continue
    }
    let token = @util.slice(template, i, end=i + length)
    i += length
    match shape_of(token) {
      Some(shape) => steps.push(Read(token, shape))
      None => {
        let mut text = token
        if text.has_prefix("[") {
          text = @util.slice(text, 1)
        }
        if text.has_suffix("]") {
          text = @util.slice(text, 0, end=text.length() - 1)
        }
        steps.push(Literal(text))
      }
    }
  }
  if steps.is_empty() {
    None
  } else {
    Some(steps)
  }
}

///|
fn digits_at(text : String, i : Int32, count : Int32) -> Bool {
  for k in 0..<count {
    if !@util.is_digit(@util.code_at(text, i + k)) {
      return false
    }
  }
  true
}

///|
fn is_word_char(c : Int32) -> Bool {
  c >= 0 && (c == 46 || !is_separator(c)) && !@util.is_digit(c)
}

///|
/// The leftmost match of a shape in `text`, as its start and end.
fn find_shape(text : String, shape : Shape) -> (Int32, Int32)? {
  let n = text.length()
  for i in 0..<n {
    let c = @util.code_at(text, i)
    match shape {
      One => if @util.is_digit(c) { return Some((i, i + 1)) }
      Two => if digits_at(text, i, 2) { return Some((i, i + 2)) }
      Three => if digits_at(text, i, 3) { return Some((i, i + 3)) }
      Four => if digits_at(text, i, 4) { return Some((i, i + 4)) }
      OneOrTwo =>
        if @util.is_digit(c) {
          let end = if digits_at(text, i + 1, 1) { i + 2 } else { i + 1 }
          return Some((i, end))
        }
      Signed => {
        let from = if (c == 43 || c == 45) && digits_at(text, i + 1, 1) {
          i + 1
        } else if @util.is_digit(c) {
          i
        } else {
          continue
        }
        let mut end = from
        while digits_at(text, end, 1) {
          end += 1
        }
        return Some((i, end))
      }
      Offset =>
        if (c == 43 || c == 45) && digits_at(text, i + 1, 2) {
          let mut end = i + 3
          if @util.code_at(text, end) == 58 {
            end += 1
          }
          if digits_at(text, end, 2) {
            end += 2
          }
          return Some((i, end))
        } else if c == 90 {
          return Some((i, i + 1))
        }
      Word => {
        let mut end = i
        while digits_at(text, end, 1) {
          end += 1
        }
        if end < n && is_word_char(@util.code_at(text, end)) {
          while end < n && is_word_char(@util.code_at(text, end)) {
            end += 1
          }
          return Some((i, end))
        }
      }
    }
  }
  None
}

///|
fn first_digits(text : String) -> String? {
  for i in 0..<text.length() {
    if @util.is_digit(@util.code_at(text, i)) {
      let mut end = i
      while digits_at(text, end, 1) {
        end += 1
      }
      return Some(@util.slice(text, i, end~))
    }
  }
  None
}

///|
fn read_offset(fields : Fields, input : String) -> Unit {
  if input == "Z" {
    fields.offset = Some(0)
    return
  }
  let parts = []
  let mut i = 0
  while i < input.length() {
    let c = @util.code_at(input, i)
    if c == 43 || c == 45 {
      parts.push(@util.slice(input, i, end=i + 1))
      i += 1
    } else if digits_at(input, i, 2) {
      parts.push(@util.slice(input, i, end=i + 2))
      i += 2
    } else {
      i += 1
    }
  }
  let rest = if parts.length() > 2 {
    or_else(@util.to_number(parts[2]), 0)
  } else {
    0
  }
  let minutes = @util.to_number(parts[1]) * 60 + rest
  fields.offset = Some(
    if minutes == 0 {
      0
    } else if parts[0] == "+" {
      -minutes
    } else {
      minutes
    },
  )
}

///|
fn month_name(fields : Fields, input : String, length : Int32) -> Bool {
  let mut index = 0
  for i, name in months {
    if @util.slice(name, 0, end=length) == input {
      index = i + 1
      break
    }
  }
  if index < 1 {
    return false
  }
  fields.month = Some(or_else((index % 12).to_double(), index.to_double()))
  true
}

///|
fn read_field(fields : Fields, token : String, input : String) -> Bool {
  let value = @util.to_number(input)
  match token {
    "A" => fields.afternoon = Some(input == "PM")
    "a" => fields.afternoon = Some(input == "pm")
    "Q" => fields.month = Some((value - 1) * 3 + 1)
    "S" => fields.milliseconds = Some(value * 100)
    "SS" => fields.milliseconds = Some(value * 10)
    "SSS" => fields.milliseconds = Some(value)
    "s" | "ss" => fields.seconds = Some(value)
    "m" | "mm" => fields.minutes = Some(value)
    "H" | "h" | "HH" | "hh" => fields.hours = Some(value)
    "D" | "DD" => fields.day = Some(value)
    "Do" => {
      guard first_digits(input) is Some(digits) else { return false }
      // dayjs keeps the digits as a string here, so even "0" counts as a day having been given.
      fields.day = Some(@util.to_number(digits))
      fields.day_given = true
      for i in 1..<=31 {
        if ordinal(i.to_double()) == input {
          fields.day = Some(i.to_double())
        }
      }
    }
    "w" | "ww" => fields.week = Some(value)
    "M" | "MM" => fields.month = Some(value)
    "MMM" => return month_name(fields, input, 3)
    "MMMM" => return month_name(fields, input, 100)
    "YY" => fields.year = Some(value + (if value > 68 { 1900 } else { 2000 }))
    "Z" | "ZZ" => read_offset(fields, input)
    _ => fields.year = Some(value)
  }
  true
}

///|
fn replace_first(text : String, needle : String) -> String {
  let at = @util.index_of(text, needle)
  if at < 0 {
    text
  } else {
    @util.slice(text, 0, end=at) + @util.slice(text, at + needle.length())
  }
}

///|
fn parse_loose(
  input : String,
  template : String,
  now : @date.JsDate,
) -> @date.JsDate? {
  if template == "x" || template == "X" {
    let scale = if template == "X" { 1000.0 } else { 1.0 }
    return Some(@date.JsDate::from_time(scale * @util.to_number(input)))
  }
  guard compile(template) is Some(steps) else { return None }
  let f : Fields = {
    year: None,
    month: None,
    day: None,
    day_given: false,
    hours: None,
    minutes: None,
    seconds: None,
    milliseconds: None,
    week: None,
    offset: None,
    afternoon: None,
  }
  let mut rest = input
  let mut start = 0
  for step in steps {
    match step {
      Literal(text) => start += text.length()
      Read(token, shape) => {
        guard find_shape(@util.slice(rest, start), shape) is Some((from, to)) else {
          return None
        }
        let found = @util.slice(@util.slice(rest, start), from, end=to)
        if !read_field(f, token, found) {
          return None
        }
        // dayjs drops the first occurrence of the matched text, wherever it is, and does not move `start`.
        rest = replace_first(rest, found)
      }
    }
  }
  if f.afternoon is Some(afternoon) && f.hours is Some(hours) {
    if afternoon {
      if hours < 12 {
        f.hours = Some(hours + 12)
      }
    } else if hours == 12 {
      f.hours = Some(0)
    }
  }
  let day = if f.day_given || truthy(f.day) {
    f.day.unwrap()
  } else if !truthy(f.year) && !truthy(f.month) {
    now.date()
  } else {
    1
  }
  let year = if truthy(f.year) { f.year.unwrap() } else { now.full_year() }
  let mut month = 0.0
  if !(truthy(f.year) && !truthy(f.month)) {
    month = match f.month {
      Some(m) if m > 0 => m - 1
      _ => now.month()
    }
  }
  let hours = if truthy(f.hours) { f.hours.unwrap() } else { 0 }
  let minutes = if truthy(f.minutes) { f.minutes.unwrap() } else { 0 }
  let seconds = if truthy(f.seconds) { f.seconds.unwrap() } else { 0 }
  let ms = if truthy(f.milliseconds) { f.milliseconds.unwrap() } else { 0 }
  if f.offset is Some(offset) {
    return Some(
      @date.JsDate::from_time(
        @date.utc_time(
          year,
          month,
          day,
          hours,
          minutes,
          seconds,
          ms + offset * 60000,
        ),
      ),
    )
  }
  // Applying a week number needs a dayjs plugin Mermaid does not load.
  if truthy(f.week) {
    return None
  }
  Some(
    @date.JsDate::from_local(year, month, day~, hours~, minutes~, seconds~, ms~),
  )
}

///|
/// Parses the way `dayjs(input, format, true)` does, taking the fields the format leaves out from `now`.
pub fn parse_strict(
  input : String,
  template : String,
  now : @date.JsDate,
) -> @date.JsDate? {
  guard parse_loose(input, template, now) is Some(date) else { return None }
  if valid(date) && format_date(date, template) == Some(input) {
    Some(date)
  } else {
    None
  }
}

///|
/// Reads a duration such as `3d` as its amount and unit, or NaN and `ms` when it is not one.
pub fn parse_duration(text : String) -> (Double, String) {
  let s = @util.trim(text)
  let mut i = 0
  while digits_at(s, i, 1) {
    i += 1
  }
  if i == 0 {
    return (@double.not_a_number, "ms")
  }
  if @util.code_at(s, i) == 46 && digits_at(s, i + 1, 1) {
    i += 1
    while digits_at(s, i, 1) {
      i += 1
    }
  }
  let unit = @util.slice(s, i)
  match unit {
    "M" | "d" | "h" | "m" | "s" | "w" | "y" | "ms" =>
      (@util.parse_float(@util.slice(s, 0, end=i)), unit)
    _ => (@double.not_a_number, "ms")
  }
}
