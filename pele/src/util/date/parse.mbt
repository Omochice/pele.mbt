// A port of V8's date parser (src/date/dateparser*), which reads ES5 ISO dates and falls back to
// legacy formats compatible with Safari.

///|
/// V8's marker for a missing value.
const NONE : Int32 = 2147483647

///|
const MAX_SIGNIFICANT_DIGITS : Int32 = 9

///|
const TAG_INVALID : Int32 = -6

///|
const TAG_UNKNOWN : Int32 = -5

///|
const TAG_WHITE_SPACE : Int32 = -4

///|
const TAG_NUMBER : Int32 = -3

///|
const TAG_SYMBOL : Int32 = -2

///|
const TAG_END : Int32 = -1

///|
const KEYWORD_INVALID : Int32 = 0

///|
const MONTH_NAME : Int32 = 1

///|
const TIME_ZONE_NAME : Int32 = 2

///|
const TIME_SEPARATOR : Int32 = 3

///|
const AM_PM : Int32 = 4

///|
fn between(x : Int32, lo : Int32, hi : Int32) -> Bool {
  (x - lo).reinterpret_as_uint() <= (hi - lo).reinterpret_as_uint()
}

///|
fn is_minute(x : Int32) -> Bool {
  between(x, 0, 59)
}

///|
fn is_hour(x : Int32) -> Bool {
  between(x, 0, 23)
}

///|
fn is_month(x : Int32) -> Bool {
  between(x, 1, 12)
}

///|
fn is_day(x : Int32) -> Bool {
  between(x, 1, 31)
}

///|
/// ECMAScript white space, without the line terminators.
fn is_white_space(c : Int32) -> Bool {
  @util.is_space(c) && c != 10 && c != 13 && c != 0x2028 && c != 0x2029
}

///|
priv struct Reader {
  text : String
  mut index : Int32
  mut ch : Int32
}

///|
fn Reader::new(text : String) -> Reader {
  let reader = { text, index: 0, ch: 0, }
  reader.next()
  reader
}

///|
fn Reader::next(self : Reader) -> Unit {
  self.ch = if self.index < self.text.length() {
    self.text.code_unit_at(self.index).to_int()
  } else {
    0
  }
  self.index += 1
}

///|
fn Reader::is_digit(self : Reader) -> Bool {
  self.ch >= 48 && self.ch <= 57
}

///|
fn Reader::is_word_char(self : Reader) -> Bool {
  self.ch >= 65 && !is_white_space(self.ch)
}

///|
fn Reader::skip(self : Reader, c : Int32) -> Bool {
  if self.ch == c {
    self.next()
    true
  } else {
    false
  }
}

///|
fn Reader::read_unsigned_numeral(self : Reader) -> Int32 {
  let mut n = 0
  let mut i = 0
  while self.ch == 48 {
    self.next()
  }
  while self.is_digit() {
    if i < MAX_SIGNIFICANT_DIGITS {
      n = n * 10 + self.ch - 48
    }
    i += 1
    self.next()
  }
  n
}

///|
priv struct Token {
  tag : Int32
  length : Int32
  value : Int32
}

///|
fn Token::is_number(self : Token) -> Bool {
  self.tag == TAG_NUMBER
}

///|
fn Token::is_fixed_number(self : Token, length : Int32) -> Bool {
  self.tag == TAG_NUMBER && self.length == length
}

///|
fn Token::is_symbol(self : Token, symbol : Int32) -> Bool {
  self.tag == TAG_SYMBOL && self.value == symbol
}

///|
fn Token::is_sign(self : Token) -> Bool {
  self.tag == TAG_SYMBOL && (self.value == 45 || self.value == 43)
}

///|
fn Token::sign(self : Token) -> Int32 {
  44 - self.value
}

///|
fn Token::is_keyword(self : Token) -> Bool {
  self.tag >= 0
}

///|
fn Token::is_keyword_z(self : Token) -> Bool {
  self.tag == TIME_ZONE_NAME && self.length == 1 && self.value == 0
}

///|
fn symbol(c : Int32) -> Token {
  { tag: TAG_SYMBOL, length: 1, value: c, }
}

///|
let end_of_input : Token = { tag: TAG_END, length: 0, value: -1, }

///|
let invalid : Token = { tag: TAG_INVALID, length: 0, value: -1, }

///|
/// Keyword prefixes with their type and value, in V8's lookup order.
let keywords : Array[(String, Int32, Int32)] = [
  ("jan", MONTH_NAME, 1),
  ("feb", MONTH_NAME, 2),
  ("mar", MONTH_NAME, 3),
  ("apr", MONTH_NAME, 4),
  ("may", MONTH_NAME, 5),
  ("jun", MONTH_NAME, 6),
  ("jul", MONTH_NAME, 7),
  ("aug", MONTH_NAME, 8),
  ("sep", MONTH_NAME, 9),
  ("oct", MONTH_NAME, 10),
  ("nov", MONTH_NAME, 11),
  ("dec", MONTH_NAME, 12),
  ("am", AM_PM, 0),
  ("pm", AM_PM, 12),
  ("ut", TIME_ZONE_NAME, 0),
  ("utc", TIME_ZONE_NAME, 0),
  ("z", TIME_ZONE_NAME, 0),
  ("gmt", TIME_ZONE_NAME, 0),
  ("cdt", TIME_ZONE_NAME, -5),
  ("cst", TIME_ZONE_NAME, -6),
  ("edt", TIME_ZONE_NAME, -4),
  ("est", TIME_ZONE_NAME, -5),
  ("mdt", TIME_ZONE_NAME, -6),
  ("mst", TIME_ZONE_NAME, -7),
  ("pdt", TIME_ZONE_NAME, -7),
  ("pst", TIME_ZONE_NAME, -8),
  ("t", TIME_SEPARATOR, 0),
]

///|
/// A word longer than its keyword matches only a month name.
fn lookup_keyword(prefix : Array[Int32], length : Int32) -> (Int32, Int32) {
  for entry in keywords {
    let (name, kind, value) = entry
    let mut matched = true
    for j in 0..<3 {
      let expected = if j < name.length() {
        name.code_unit_at(j).to_int()
      } else {
        0
      }
      if prefix[j] != expected {
        matched = false
        break
      }
    }
    if matched && (length <= 3 || kind == MONTH_NAME) {
      return (kind, value)
    }
  }
  (KEYWORD_INVALID, 0)
}

///|
priv struct Scanner {
  reader : Reader
  mut peeked : Token
}

///|
fn Scanner::new(text : String) -> Scanner {
  let reader = Reader::new(text)
  { reader, peeked: scan(reader), }
}

///|
fn Scanner::next(self : Scanner) -> Token {
  let result = self.peeked
  self.peeked = scan(self.reader)
  result
}

///|
fn Scanner::skip_symbol(self : Scanner, c : Int32) -> Bool {
  if self.peeked.is_symbol(c) {
    self.peeked = scan(self.reader)
    true
  } else {
    false
  }
}

///|
fn scan(in_ : Reader) -> Token {
  let start = in_.index
  if in_.ch == 0 {
    return end_of_input
  }
  if in_.is_digit() {
    let n = in_.read_unsigned_numeral()
    return { tag: TAG_NUMBER, length: in_.index - start, value: n, }
  }
  for c in [58, 45, 43, 46, 41] {
    if in_.skip(c) {
      return symbol(c)
    }
  }
  if in_.is_word_char() {
    let prefix = [0, 0, 0]
    let mut length = 0
    while in_.is_word_char() {
      if length < 3 {
        prefix[length] = in_.ch | 0x20
      }
      in_.next()
      length += 1
    }
    let (kind, value) = lookup_keyword(prefix, length)
    return { tag: kind, length, value, }
  }
  if @util.is_space(in_.ch) {
    in_.next()
    return { tag: TAG_WHITE_SPACE, length: in_.index - start, value: -1, }
  }
  if in_.ch == 40 {
    let mut balance = 0
    while true {
      if in_.ch == 41 {
        balance -= 1
      } else if in_.ch == 40 {
        balance += 1
      }
      in_.next()
      if !(balance > 0 && in_.ch != 0) {
        break
      }
    }
    return { tag: TAG_UNKNOWN, length: 1, value: -1, }
  }
  in_.next()
  { tag: TAG_UNKNOWN, length: 1, value: -1, }
}

///|
fn read_milliseconds(token : Token) -> Int32 {
  let mut number = token.value
  let mut length = token.length
  if length == 1 {
    number *= 100
  } else if length == 2 {
    number *= 10
  } else if length > 3 {
    if length > MAX_SIGNIFICANT_DIGITS {
      length = MAX_SIGNIFICANT_DIGITS
    }
    let mut factor = 1
    while length > 3 {
      factor *= 10
      length -= 1
    }
    number /= factor
  }
  number
}

///|
priv struct Zone {
  mut sign : Int32
  mut hour : Int32
  mut minute : Int32
}

///|
fn Zone::set(self : Zone, offset_in_hours : Int32) -> Unit {
  self.sign = if offset_in_hours < 0 { -1 } else { 1 }
  self.hour = offset_in_hours * self.sign
  self.minute = 0
}

///|
fn Zone::set_sign(self : Zone, sign : Int32) -> Unit {
  self.sign = if sign < 0 { -1 } else { 1 }
}

///|
fn Zone::is_expecting(self : Zone, n : Int32) -> Bool {
  self.hour != NONE && self.minute == NONE && is_minute(n)
}

///|
fn Zone::is_utc(self : Zone) -> Bool {
  self.hour == 0 && self.minute == 0
}

///|
fn Zone::is_empty(self : Zone) -> Bool {
  self.hour == NONE
}

///|
/// The offset in seconds, NaN when none was given, or None when it is out of range.
fn Zone::write(self : Zone) -> Double? {
  if self.sign == NONE {
    return Some(@double.not_a_number)
  }
  let hour = if self.hour == NONE { 0 } else { self.hour }
  let minute = if self.minute == NONE { 0 } else { self.minute }
  // V8 computes this in unsigned 32-bit arithmetic and compares it with its largest small integer.
  let total = hour.reinterpret_as_uint() * 3600U +
    minute.reinterpret_as_uint() * 60U
  if total > 2147483647U {
    return None
  }
  let seconds = total.reinterpret_as_int()
  Some((if self.sign < 0 { -seconds } else { seconds }).to_double())
}

///|
priv struct Clock {
  parts : Array[Int32]
  mut index : Int32
  mut hour_offset : Int32
}

///|
fn Clock::is_empty(self : Clock) -> Bool {
  self.index == 0
}

///|
fn Clock::is_expecting(self : Clock, n : Int32) -> Bool {
  (self.index == 1 && is_minute(n)) ||
  (self.index == 2 && is_minute(n)) ||
  (self.index == 3 && between(n, 0, 999))
}

///|
fn Clock::add(self : Clock, n : Int32) -> Bool {
  if self.index < 4 {
    self.parts[self.index] = n
    self.index += 1
    true
  } else {
    false
  }
}

///|
fn Clock::add_final(self : Clock, n : Int32) -> Bool {
  if !self.add(n) {
    return false
  }
  while self.index < 4 {
    self.parts[self.index] = 0
    self.index += 1
  }
  true
}

///|
fn Clock::write(self : Clock) -> (Int32, Int32, Int32, Int32)? {
  while self.index < 4 {
    self.parts[self.index] = 0
    self.index += 1
  }
  let mut hour = self.parts[0]
  let minute = self.parts[1]
  let second = self.parts[2]
  let ms = self.parts[3]
  if self.hour_offset != NONE {
    if !between(hour, 0, 12) {
      return None
    }
    hour = hour % 12 + self.hour_offset
  }
  if !is_hour(hour) ||
    !is_minute(minute) ||
    !is_minute(second) ||
    !between(ms, 0, 999) {
    if hour != 24 || minute != 0 || second != 0 || ms != 0 {
      return None
    }
  }
  Some((hour, minute, second, ms))
}

///|
priv struct Calendar {
  parts : Array[Int32]
  mut index : Int32
  mut named_month : Int32
  mut iso : Bool
}

///|
fn Calendar::add(self : Calendar, n : Int32) -> Bool {
  if self.index < 3 {
    self.parts[self.index] = n
    self.index += 1
    true
  } else {
    false
  }
}

///|
fn Calendar::write(self : Calendar) -> (Int32, Int32, Int32)? {
  if self.index < 1 {
    return None
  }
  while self.index < 3 {
    self.parts[self.index] = 1
    self.index += 1
  }
  let comp = self.parts
  let mut year = 0
  let mut month = NONE
  let mut day = NONE
  if self.named_month == NONE {
    if self.iso || !is_day(comp[0]) {
      year = comp[0]
      month = comp[1]
      day = comp[2]
    } else {
      month = comp[0]
      day = comp[1]
      year = comp[2]
    }
  } else {
    month = self.named_month
    if !is_day(comp[0]) {
      year = comp[0]
      day = comp[1]
    } else {
      day = comp[0]
      year = comp[1]
    }
  }
  if !self.iso {
    if between(year, 0, 49) {
      year += 2000
    } else if between(year, 50, 99) {
      year += 1900
    }
  }
  if !is_month(month) || !is_day(day) {
    return None
  }
  Some((year, month - 1, day))
}

///|
/// Reads as much as it can as an ES5 date-time string, and returns the token the legacy parser goes on with.
fn parse_iso(
  scanner : Scanner,
  day : Calendar,
  time : Clock,
  tz : Zone,
) -> Token {
  if scanner.peeked.is_sign() {
    let sign_token = scanner.next()
    if !scanner.peeked.is_fixed_number(6) {
      return sign_token
    }
    let sign = sign_token.sign()
    let year = scanner.next().value
    if sign < 0 && year == 0 {
      return sign_token
    }
    day.add(sign * year) |> ignore
  } else if scanner.peeked.is_fixed_number(4) {
    day.add(scanner.next().value) |> ignore
  } else {
    return scanner.next()
  }
  if scanner.skip_symbol(45) {
    if !scanner.peeked.is_fixed_number(2) || !is_month(scanner.peeked.value) {
      return scanner.next()
    }
    day.add(scanner.next().value) |> ignore
    if scanner.skip_symbol(45) {
      if !scanner.peeked.is_fixed_number(2) || !is_day(scanner.peeked.value) {
        return scanner.next()
      }
      day.add(scanner.next().value) |> ignore
    }
  }
  if scanner.peeked.tag != TIME_SEPARATOR {
    if scanner.peeked.tag != TAG_END {
      return scanner.next()
    }
  } else {
    scanner.next() |> ignore
    if !scanner.peeked.is_fixed_number(2) ||
      !between(scanner.peeked.value, 0, 24) {
      return invalid
    }
    let hour_is_24 = scanner.peeked.value == 24
    time.add(scanner.next().value) |> ignore
    if !scanner.skip_symbol(58) {
      return invalid
    }
    if !scanner.peeked.is_fixed_number(2) ||
      !is_minute(scanner.peeked.value) ||
      (hour_is_24 && scanner.peeked.value > 0) {
      return invalid
    }
    time.add(scanner.next().value) |> ignore
    if scanner.skip_symbol(58) {
      if !scanner.peeked.is_fixed_number(2) ||
        !is_minute(scanner.peeked.value) ||
        (hour_is_24 && scanner.peeked.value > 0) {
        return invalid
      }
      time.add(scanner.next().value) |> ignore
      if scanner.skip_symbol(46) {
        if !scanner.peeked.is_number() ||
          (hour_is_24 && scanner.peeked.value > 0) {
          return invalid
        }
        time.add(read_milliseconds(scanner.next())) |> ignore
      }
    }
    if scanner.peeked.is_keyword_z() {
      scanner.next() |> ignore
      tz.set(0)
    } else if scanner.peeked.is_symbol(43) || scanner.peeked.is_symbol(45) {
      tz.set_sign(if scanner.next().value == 43 { 1 } else { -1 })
      if scanner.peeked.is_fixed_number(4) {
        let hourmin = scanner.next().value
        let hour = hourmin / 100
        let min = hourmin % 100
        if !is_hour(hour) || !is_minute(min) {
          return invalid
        }
        tz.hour = hour
        tz.minute = min
      } else {
        if !scanner.peeked.is_fixed_number(2) || !is_hour(scanner.peeked.value) {
          return invalid
        }
        tz.hour = scanner.next().value
        if !scanner.skip_symbol(58) {
          return invalid
        }
        if !scanner.peeked.is_fixed_number(2) ||
          !is_minute(scanner.peeked.value) {
          return invalid
        }
        tz.minute = scanner.next().value
      }
    }
    if scanner.peeked.tag != TAG_END {
      return invalid
    }
  }
  if tz.is_empty() && time.is_empty() {
    tz.set(0)
  }
  day.iso = true
  end_of_input
}

///|
/// The calendar fields and UTC offset in seconds of a date string, or None when V8 rejects it.
fn parse_fields(
  text : String,
) -> (Int32, Int32, Int32, Int32, Int32, Int32, Int32, Double)? {
  let scanner = Scanner::new(text)
  let tz = { sign: NONE, hour: NONE, minute: NONE, }
  let time = { parts: [0, 0, 0, 0], index: 0, hour_offset: NONE, }
  let day = { parts: [0, 0, 0], index: 0, named_month: NONE, iso: false, }
  let mut token = parse_iso(scanner, day, time, tz)
  if token.tag == TAG_INVALID {
    return None
  }
  let mut has_read_number = day.index != 0
  while token.tag != TAG_END {
    if token.is_number() {
      has_read_number = true
      let n = token.value
      if scanner.skip_symbol(58) {
        if scanner.skip_symbol(58) {
          if !time.is_empty() {
            return None
          }
          time.add(n) |> ignore
          time.add(0) |> ignore
        } else {
          if !time.add(n) {
            return None
          }
          if scanner.peeked.is_symbol(46) {
            scanner.next() |> ignore
          }
        }
      } else if scanner.skip_symbol(46) && time.is_expecting(n) {
        time.add(n) |> ignore
        if !scanner.peeked.is_number() {
          return None
        }
        let ms = read_milliseconds(scanner.next())
        if ms < 0 {
          return None
        }
        time.add_final(ms) |> ignore
      } else if tz.is_expecting(n) {
        tz.minute = n
      } else if time.is_expecting(n) {
        time.add_final(n) |> ignore
        let peek = scanner.peeked
        if peek.tag != TAG_END &&
          peek.tag != TAG_WHITE_SPACE &&
          !peek.is_keyword_z() &&
          !peek.is_sign() {
          return None
        }
      } else {
        if !day.add(n) {
          return None
        }
        scanner.skip_symbol(45) |> ignore
      }
    } else if token.is_keyword() {
      let kind = token.tag
      let value = token.value
      if kind == AM_PM && !time.is_empty() {
        time.hour_offset = value
      } else if kind == MONTH_NAME {
        day.named_month = value
        scanner.skip_symbol(45) |> ignore
      } else if kind == TIME_ZONE_NAME && has_read_number {
        tz.set(value)
      } else {
        if has_read_number {
          return None
        }
        if scanner.peeked.is_number() {
          return None
        }
      }
    } else if token.is_sign() && (tz.is_utc() || !time.is_empty()) {
      tz.set_sign(token.sign())
      let mut n = 0
      let mut length = 0
      if scanner.peeked.is_number() {
        let next = scanner.next()
        length = next.length
        n = next.value
      }
      has_read_number = true
      if scanner.peeked.is_symbol(58) {
        tz.hour = n
        tz.minute = NONE
      } else if length == 2 || length == 1 {
        tz.hour = n
        tz.minute = 0
      } else if length == 4 || length == 3 {
        tz.hour = n / 100
        tz.minute = n % 100
      } else {
        return None
      }
    } else if (token.is_sign() || token.is_symbol(41)) && has_read_number {
      return None
    }
    token = scanner.next()
  }
  guard day.write() is Some((year, month, date)) else { return None }
  guard time.write() is Some((hour, minute, second, ms)) else { return None }
  guard tz.write() is Some(offset) else { return None }
  Some((year, month, date, hour, minute, second, ms, offset))
}

///|
/// The time `new Date(text)` gives for a string, NaN when V8 cannot read it.
pub fn parse_date(text : String) -> Double {
  guard parse_fields(text)
    is Some((year, month, day, hour, minute, second, ms, offset)) else {
    return @double.not_a_number
  }
  let date = make_date(
    make_day(year.to_double(), month.to_double(), day.to_double()),
    make_time(
      hour.to_double(),
      minute.to_double(),
      second.to_double(),
      ms.to_double(),
    ),
  )
  if offset.is_nan() {
    return time_clip(utc(date))
  }
  let shifted = date - offset * 1000
  if shifted < -8.64e15 || shifted > 8.64e15 {
    return @double.not_a_number
  }
  time_clip(shifted)
}
