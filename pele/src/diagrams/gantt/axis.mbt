// Time axis support, following d3-time and d3-time-format (English locale, local time), which Mermaid uses:
// the `axisFormat` specifiers, tick intervals with d3's `every` rule, and its choice of automatic ticks.

///|
const SECOND : Double = 1000

///|
const MINUTE : Double = 60000

///|
const HOUR : Double = 3600000

///|
const DAY : Double = 86400000

///|
const MONTH : Double = 2592000000

///|
const YEAR : Double = 31536000000

///|
priv struct Calendar {
  floor : (@date.JsDate) -> Unit
  offset : (@date.JsDate, Double) -> Unit
  /// The value d3 tests against a step: a tick falls where it is a multiple of the step.
  field : ((@date.JsDate) -> Double)?
  /// How many values `field` cycles through, which bounds how far apart filtered ticks can be.
  cycle : Double
  ms : Double
}

///|
fn start_of_day(d : @date.JsDate) -> Unit {
  d.set_hours(0, minutes=0, seconds=0, ms=0)
}

///|
fn week_calendar(week_start : Double) -> Calendar {
  {
    floor: d => {
      d.set_date(d.date() - (d.day() + 7 - week_start) % 7)
      start_of_day(d)
    },
    offset: (d, step) => d.set_date(d.date() + step * 7),
    field: None,
    cycle: @double.infinity,
    ms: 7 * DAY,
  }
}

///|
fn calendar_of(unit : String) -> Calendar {
  match unit {
    "millisecond" =>
      {
        floor: _ => (),
        offset: (d, step) => d.set_time(d.time + step),
        field: None,
        cycle: @double.infinity,
        ms: 1,
      }
    "second" =>
      {
        floor: d => d.set_time(d.time - d.milliseconds()),
        offset: (d, step) => d.set_time(d.time + step * SECOND),
        field: Some(d => d.utc_seconds()),
        cycle: 60,
        ms: SECOND,
      }
    "minute" =>
      {
        floor: d => d.set_time(d.time - d.milliseconds() - d.seconds() * SECOND),
        offset: (d, step) => d.set_time(d.time + step * MINUTE),
        field: Some(d => d.minutes()),
        cycle: 60,
        ms: MINUTE,
      }
    "hour" =>
      {
        floor: d => {
          d.set_time(
            d.time -
            d.milliseconds() -
            d.seconds() * SECOND -
            d.minutes() * MINUTE,
          )
        },
        offset: (d, step) => d.set_time(d.time + step * HOUR),
        field: Some(d => d.hours()),
        cycle: 24,
        ms: HOUR,
      }
    "day" =>
      {
        floor: start_of_day,
        offset: (d, step) => d.set_date(d.date() + step),
        field: Some(d => d.date() - 1),
        cycle: 31,
        ms: DAY,
      }
    "month" =>
      {
        floor: d => {
          d.set_date(1)
          start_of_day(d)
        },
        offset: (d, step) => d.set_month(d.month() + step),
        field: Some(d => d.month()),
        cycle: 12,
        ms: MONTH,
      }
    _ =>
      {
        floor: d => {
          d.set_month(0, date=1)
          start_of_day(d)
        },
        offset: (d, step) => d.set_full_year(d.full_year() + step),
        field: None,
        cycle: @double.infinity,
        ms: YEAR,
      }
  }
}

///|
/// Whole units between two floored dates, discounting a change of UTC offset between them.
fn span(start : @date.JsDate, end : @date.JsDate, unit : Double) -> Double {
  ((
    end.time -
    start.time -
    (end.timezone_offset() - start.timezone_offset()) * MINUTE
  ) /
  unit).floor()
}

///|
fn modulo(a : Double, b : Double) -> Double {
  (a % b + b) % b
}

///|
/// The interval d3's `unit.every(step)` gives.
fn every(unit : String, step : Double, week_start : Double) -> Calendar {
  let base = if unit == "week" {
    week_calendar(week_start)
  } else {
    calendar_of(unit)
  }
  if step <= 1 {
    return base
  }
  match unit {
    "millisecond" =>
      {
        ..base,
        floor: d => d.set_time((d.time / step).floor() * step),
        offset: (d, n) => d.set_time(d.time + n * step),
      }
    "year" =>
      {
        ..base,
        floor: d => {
          d.set_full_year((d.full_year() / step).floor() * step)
          (base.floor)(d)
        },
        offset: (d, n) => d.set_full_year(d.full_year() + n * step),
      }
    "week" => {
      let epoch = @date.JsDate::from_time(0)
      (base.floor)(epoch)
      {
        ..base,
        floor: d => {
          (base.floor)(d)
          (base.offset)(d, -modulo(span(epoch, d, 7 * DAY), step))
        },
        offset: (d, n) => (base.offset)(d, n * step),
      }
    }
    _ => {
      let field = base.field.unwrap()
      let matches = (d : @date.JsDate) => field(d) % step == 0
      {
        ..base,
        floor: d => {
          (base.floor)(d)
          // Date overflow makes the field NaN, which can never match the interval.
          while !d.time.is_nan() && !matches(d) {
            d.set_time(d.time - 1)
            (base.floor)(d)
          }
        },
        offset: (d, n) => {
          let mut i = 0.0
          while i < n && !d.time.is_nan() {
            (base.offset)(d, 1)
            while !d.time.is_nan() && !matches(d) {
              (base.offset)(d, 1)
            }
            i += 1
          }
        },
      }
    }
  }
}

///|
/// Ticks from start to stop inclusive, or None when there would be more than `limit`.
fn range(
  calendar : Calendar,
  start : Double,
  stop : Double,
  limit : Double,
) -> Array[Double]? {
  let d = @date.JsDate::from_time(start - 1)
  (calendar.floor)(d)
  (calendar.offset)(d, 1)
  (calendar.floor)(d)
  let out = []
  let mut previous = -@double.infinity
  while d.time <= stop && d.time > previous {
    if out.length().to_double() >= limit {
      return None
    }
    previous = d.time
    out.push(previous)
    (calendar.offset)(d, 1)
    (calendar.floor)(d)
  }
  Some(out)
}

///|
/// `10 ** power`, which V8 gives as the nearest double for a whole power.
fn pow10(power : Double) -> Double {
  if power.is_nan() || power.is_inf() || power.abs() > 400 {
    @math.pow(10, power)
  } else {
    @util.to_number("1e" + power.to_int().to_string())
  }
}

///|
fn tick_step(start : Double, stop : Double, count : Double) -> Double {
  let step = (stop - start) / @util.js_max(0, count)
  let power = @math.log10(step).floor()
  let error = step / pow10(power)
  let factor = if error >= 50.0.sqrt() {
    10.0
  } else if error >= 10.0.sqrt() {
    5
  } else if error >= 2.0.sqrt() {
    2
  } else {
    1
  }
  pow10(power) * factor
}

///|
let auto_steps : Array[(String, Double, Double)] = [
  ("second", 1, SECOND),
  ("second", 5, 5 * SECOND),
  ("second", 15, 15 * SECOND),
  ("second", 30, 30 * SECOND),
  ("minute", 1, MINUTE),
  ("minute", 5, 5 * MINUTE),
  ("minute", 15, 15 * MINUTE),
  ("minute", 30, 30 * MINUTE),
  ("hour", 1, HOUR),
  ("hour", 3, 3 * HOUR),
  ("hour", 6, 6 * HOUR),
  ("hour", 12, 12 * HOUR),
  ("day", 1, DAY),
  ("day", 2, 2 * DAY),
  ("week", 1, 7 * DAY),
  ("month", 1, MONTH),
  ("month", 3, 3 * MONTH),
  ("year", 1, YEAR),
]

///|
/// About `count` ticks at round times, chosen the way d3's time scale chooses them.
pub fn auto_ticks(
  start : Double,
  stop : Double,
  count : Double,
) -> Array[Double] {
  let target = (stop - start) / count
  let mut i = 0
  while i < auto_steps.length() && auto_steps[i].2 <= target {
    i += 1
  }
  let calendar = if i == auto_steps.length() {
    every(
      "year",
      @util.js_max(1, tick_step(start / YEAR, stop / YEAR, count)),
      0,
    )
  } else if i == 0 {
    every("millisecond", @util.js_max(tick_step(start, stop, count), 1), 0)
  } else {
    let chosen = if target / auto_steps[i - 1].2 < auto_steps[i].2 / target {
      auto_steps[i - 1]
    } else {
      auto_steps[i]
    }
    every(chosen.0, chosen.1, 0)
  }
  range(calendar, start, stop, 4 * count + 8).unwrap_or([])
}

///|
let interval_units : Array[String] = [
  "millisecond", "second", "minute", "hour", "day", "week", "month",
]

///|
let week_starts : Array[String] = [
  "sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday",
]

///|
/// Ticks for a `tickInterval` such as `1week`, or None when it is not one or asks for more than `limit`.
pub fn interval_ticks(
  interval : String,
  weekday : String,
  start : Double,
  stop : Double,
  limit : Double,
) -> Array[Double]? {
  let first = @util.code_at(interval, 0)
  if first < 49 || first > 57 {
    return None
  }
  let mut digits = 1
  while @util.is_digit(@util.code_at(interval, digits)) {
    digits += 1
  }
  let unit = @util.slice(interval, digits)
  if !interval_units.contains(unit) {
    return None
  }
  let step = @util.to_number(@util.slice(interval, 0, end=digits))
  let week_start = match week_starts.search(weekday) {
    Some(index) => index.to_double()
    None => 0
  }
  let calendar = every(unit, step, week_start)
  if (stop - start) / (@util.js_min(step, calendar.cycle) * calendar.ms) > limit {
    return None
  }
  range(calendar, start, stop, limit)
}

///|
fn pad_with(value : Double, fill : String, width : Int32) -> String {
  let negative = value < 0
  let digits = (if negative { -value } else { value }).to_string()
  (if negative { "-" } else { "" }) +
  (if digits.length() < width {
    fill.repeat(width - digits.length()) + digits
  } else {
    digits
  })
}

///|
fn floored(date : @date.JsDate, calendar : Calendar) -> @date.JsDate {
  let d = date.copy()
  (calendar.floor)(d)
  d
}

///|
/// Weeks since the last `week_start` day before the year began, which is d3's %U and %W.
fn week_of_year(date : @date.JsDate, week_start : Double) -> Double {
  let week = week_calendar(week_start)
  let year_start = floored(date, calendar_of("year"))
  span(
    floored(@date.JsDate::from_time(year_start.time - 1), week),
    floored(date, week),
    7 * DAY,
  )
}

///|
/// The Thursday that decides which ISO week and ISO year a date belongs to.
fn iso_thursday(date : @date.JsDate) -> @date.JsDate {
  let thursday = week_calendar(4)
  let day = date.day()
  let on_or_after = day >= 4 || day == 0
  let d = floored(
    if on_or_after {
      date
    } else {
      @date.JsDate::from_time(date.time - 1)
    },
    thursday,
  )
  if !on_or_after {
    (thursday.offset)(d, 1)
    (thursday.floor)(d)
  }
  d
}

///|
/// Formats a date with a d3 time format specifier such as `%Y-%m-%d`.
/// Raises the port's `limit` error where the text would be longer than the port holds, since a
/// drawing that writes it would be too.
pub fn time_format(
  specifier : String,
  date : @date.JsDate,
) -> String raise @errors.PeleError {
  let mut length = 0
  let grow = (count : Int32) => {
    if count > @svg.HOLD_LIMIT - length {
      raise @svg.too_large_to_hold()
    }
    length += count
  }
  let known : Map[String, String] = Map([])
  each_part(specifier, date, known, (from, to) => grow(to - from), piece => {
    grow(piece.length())
  })
  // Sized to the text, because a doubling builder past 2^28 code units asks wasm for a block of
  // 1 GiB that it refuses, and a format of millions of `%c` makes a text past that.
  let out = StringBuilder(size_hint=length * 2)
  each_part(
    specifier,
    date,
    known,
    (from, to) => @util.write_range(out, specifier, from, to),
    piece => out.write_string(piece),
  )
  out.to_string()
}

///|
/// Hands the parts of `specifier` formatted for `date` in order to `literal`, as a range of the
/// specifier written as it is, or to `formatted`, as a directive's text, which `known` keeps by
/// directive and fill.
fn each_part(
  specifier : String,
  date : @date.JsDate,
  known : Map[String, String],
  literal : (Int32, Int32) -> Unit raise @errors.PeleError,
  formatted : (String) -> Unit raise @errors.PeleError,
) -> Unit raise @errors.PeleError {
  let mut from = 0
  let n = specifier.length()
  let mut i = 0
  while i < n {
    if @util.code_at(specifier, i) != 37 {
      i += 1
      continue
    }
    literal(from, i)
    i += 1
    let mut c = @util.slice(specifier, i, end=i + 1)
    let fill = match c {
      "-" => Some("")
      "_" => Some(" ")
      "0" => Some("0")
      _ => None
    }
    let p = match fill {
      Some(f) => {
        i += 1
        c = @util.slice(specifier, i, end=i + 1)
        f
      }
      None => if c == "e" { " " } else { "0" }
    }
    // Every directive formats the same date, so each is worked out once however often it recurs.
    let key = c + p
    let text = match known.get(key) {
      Some(text) => text
      None => {
        let text = directive(c, date, p)
        known[key] = text
        text
      }
    }
    formatted(text)
    from = i + 1
    i += 1
  }
  if from < n {
    literal(from, n)
  }
}

///|
fn directive(
  c : String,
  d : @date.JsDate,
  p : String,
) -> String raise @errors.PeleError {
  match c {
    "a" => @util.slice(weekdays[d.day().to_int()], 0, end=3)
    "A" => weekdays[d.day().to_int()]
    "b" => @util.slice(months[d.month().to_int()], 0, end=3)
    "B" => months[d.month().to_int()]
    "c" => time_format("%x, %X", d)
    "d" | "e" => pad_with(d.date(), p, 2)
    "f" => pad_with(d.milliseconds(), p, 3) + "000"
    "g" => pad_with(iso_thursday(d).full_year() % 100, p, 2)
    "G" => pad_with(iso_thursday(d).full_year() % 10000, p, 4)
    "H" => pad_with(d.hours(), p, 2)
    "I" => pad_with(or_else(d.hours() % 12, 12), p, 2)
    "j" =>
      pad_with(
        1 +
        span(
          floored(d, calendar_of("year")),
          floored(d, calendar_of("day")),
          DAY,
        ),
        p,
        3,
      )
    "L" => pad_with(d.milliseconds(), p, 3)
    "m" => pad_with(d.month() + 1, p, 2)
    "M" => pad_with(d.minutes(), p, 2)
    "p" => if d.hours() >= 12 { "PM" } else { "AM" }
    "q" => (1.0 + (d.month() / 3).floor()).to_string()
    "Q" => d.time.to_string()
    "s" => (d.time / 1000).floor().to_string()
    "S" => pad_with(d.seconds(), p, 2)
    "u" => or_else(d.day(), 7).to_string()
    "U" => pad_with(week_of_year(d, 0), p, 2)
    "V" => {
      let thursday = iso_thursday(d)
      let year_start = floored(thursday, calendar_of("year"))
      let first = floored(year_start, week_calendar(4))
      pad_with(
        span(first, thursday, 7 * DAY) +
        (if year_start.day() == 4 { 1 } else { 0 }),
        p,
        2,
      )
    }
    "w" => d.day().to_string()
    "W" => pad_with(week_of_year(d, 1), p, 2)
    "x" => time_format("%-m/%-d/%Y", d)
    "X" => time_format("%-I:%M:%S %p", d)
    "y" => pad_with(d.full_year() % 100, p, 2)
    "Y" => pad_with(d.full_year() % 10000, p, 4)
    "Z" => {
      let z = d.timezone_offset()
      let abs = z.abs()
      (if z > 0 { "-" } else { "+" }) +
      pad_with((abs / 60).floor(), "0", 2) +
      pad_with(abs % 60, "0", 2)
    }
    "%" => "%"
    _ => c
  }
}
