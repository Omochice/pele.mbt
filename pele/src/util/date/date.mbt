///|
const MS_PER_DAY : Double = 86400000

///|
const MS_PER_HOUR : Double = 3600000

///|
const MS_PER_MINUTE : Double = 60000

///|
const MS_PER_SECOND : Double = 1000

///|
/// How far local time is ahead of UTC.
// pele reads the host's time zone through JavaScript's Date, and a plugin has no time zone to read,
// so local time is UTC.
// The goldens were rendered in Asia/Tokyo, which 9 hours here reproduces.
const LOCAL_OFFSET : Double = 0

///|
/// V8 turns local times further than this from the epoch into an invalid date before converting them to UTC.
const MAX_LOCAL : Double = 8.64e15 + 864000000

///|
/// A JavaScript `Date`: milliseconds since the epoch, NaN when the date is invalid.
pub struct JsDate {
  mut time : Double
}

///|
fn finite(x : Double) -> Bool {
  !x.is_nan() && !x.is_inf()
}

///|
fn to_integer(x : Double) -> Double {
  if x.is_nan() {
    0
  } else {
    x.trunc() + 0
  }
}

///|
fn modulo(a : Double, b : Double) -> Double {
  let r = a % b
  if r < 0 {
    r + b
  } else {
    r + 0
  }
}

///|
fn time_clip(time : Double) -> Double {
  if !finite(time) || time.abs() > 8.64e15 {
    @double.not_a_number
  } else {
    to_integer(time)
  }
}

///|
fn local_time(time : Double) -> Double {
  time + LOCAL_OFFSET
}

///|
fn utc(wall : Double) -> Double {
  if wall.is_nan() || wall < -MAX_LOCAL || wall > MAX_LOCAL {
    @double.not_a_number
  } else {
    wall - LOCAL_OFFSET
  }
}

///|
fn day_number(t : Double) -> Double {
  (t / MS_PER_DAY).floor()
}

///|
fn time_within_day(t : Double) -> Double {
  modulo(t, MS_PER_DAY)
}

///|
fn day_from_year(y : Double) -> Double {
  365.0 * (y - 1970) +
  ((y - 1969) / 4).floor() -
  ((y - 1901) / 100).floor() +
  ((y - 1601) / 400).floor()
}

///|
fn time_from_year(y : Double) -> Double {
  MS_PER_DAY * day_from_year(y)
}

///|
fn year_from_time(t : Double) -> Double {
  let mut y = (t / (MS_PER_DAY * 365.2425)).floor() + 1970
  while time_from_year(y) > t {
    y -= 1
  }
  while time_from_year(y + 1) <= t {
    y += 1
  }
  y
}

///|
fn is_leap(y : Double) -> Bool {
  modulo(y, 4) == 0 && (modulo(y, 100) != 0 || modulo(y, 400) == 0)
}

///|
let month_starts : Array[Double] = [
  0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334,
]

///|
/// Days from the start of a year to the start of a month.
fn month_start(month : Int32, leap : Bool) -> Double {
  month_starts[month] + (if leap && month > 1 { 1 } else { 0 })
}

///|
/// The month and the day of the month of a time value.
fn month_and_date(t : Double) -> (Double, Double) {
  let year = year_from_time(t)
  let within = day_number(t) - day_from_year(year)
  let leap = is_leap(year)
  let mut month = 11
  while month > 0 && month_start(month, leap) > within {
    month -= 1
  }
  (month.to_double(), within - month_start(month, leap) + 1)
}

///|
// V8 refuses years and months outside these bounds before it carries months into years.
fn make_day(year : Double, month : Double, date : Double) -> Double {
  if !finite(year) || !finite(month) || !finite(date) {
    return @double.not_a_number
  }
  let y = to_integer(year)
  let m = to_integer(month)
  if y < -1000000 || y > 1000000 || m < -10000000 || m > 10000000 {
    return @double.not_a_number
  }
  let ym = y + (m / 12).floor()
  let mn = modulo(m, 12).to_int()
  day_from_year(ym) + month_start(mn, is_leap(ym)) + to_integer(date) - 1
}

///|
fn make_time(h : Double, m : Double, s : Double, ms : Double) -> Double {
  if !finite(h) || !finite(m) || !finite(s) || !finite(ms) {
    return @double.not_a_number
  }
  to_integer(h) * MS_PER_HOUR +
  to_integer(m) * MS_PER_MINUTE +
  to_integer(s) * MS_PER_SECOND +
  to_integer(ms)
}

///|
fn make_date(day : Double, time : Double) -> Double {
  if !finite(day) || !finite(time) {
    return @double.not_a_number
  }
  let t = day * MS_PER_DAY + time
  if finite(t) {
    t
  } else {
    @double.not_a_number
  }
}

///|
fn full_year_of(year : Double) -> Double {
  if year.is_nan() {
    return year
  }
  let y = to_integer(year)
  if y >= 0 && y <= 99 {
    1900 + y
  } else {
    year
  }
}

///|
/// `new Date(time)`.
pub fn JsDate::from_time(time : Double) -> JsDate {
  { time: time_clip(time), }
}

///|
/// `new Date(year, month, day, hours, minutes, seconds, ms)`, read in local time.
pub fn JsDate::from_local(
  year : Double,
  month : Double,
  day~ : Double = 1,
  hours~ : Double = 0,
  minutes~ : Double = 0,
  seconds~ : Double = 0,
  ms~ : Double = 0,
) -> JsDate {
  let wall = make_date(
    make_day(full_year_of(year), month, day),
    make_time(hours, minutes, seconds, ms),
  )
  { time: time_clip(utc(wall)), }
}

///|
/// `Date.UTC(year, month, day, hours, minutes, seconds, ms)`.
pub fn utc_time(
  year : Double,
  month : Double,
  day : Double,
  hours : Double,
  minutes : Double,
  seconds : Double,
  ms : Double,
) -> Double {
  time_clip(
    make_date(
      make_day(full_year_of(year), month, day),
      make_time(hours, minutes, seconds, ms),
    ),
  )
}

///|
/// An independent date with the same time.
pub fn JsDate::copy(self : JsDate) -> JsDate {
  { time: self.time, }
}

///|
fn JsDate::wall(self : JsDate) -> Double {
  local_time(self.time)
}

///|
/// `getFullYear()`.
pub fn JsDate::full_year(self : JsDate) -> Double {
  let t = self.wall()
  if t.is_nan() {
    t
  } else {
    year_from_time(t)
  }
}

///|
/// `getMonth()`.
pub fn JsDate::month(self : JsDate) -> Double {
  let t = self.wall()
  if t.is_nan() {
    t
  } else {
    month_and_date(t).0
  }
}

///|
/// `getDate()`.
pub fn JsDate::date(self : JsDate) -> Double {
  let t = self.wall()
  if t.is_nan() {
    t
  } else {
    month_and_date(t).1
  }
}

///|
/// `getDay()`.
pub fn JsDate::day(self : JsDate) -> Double {
  let t = self.wall()
  if t.is_nan() {
    t
  } else {
    modulo(day_number(t) + 4, 7)
  }
}

///|
/// `getHours()`.
pub fn JsDate::hours(self : JsDate) -> Double {
  (time_within_day(self.wall()) / MS_PER_HOUR).floor()
}

///|
/// `getMinutes()`.
pub fn JsDate::minutes(self : JsDate) -> Double {
  modulo((self.wall() / MS_PER_MINUTE).floor(), 60)
}

///|
/// `getSeconds()`.
pub fn JsDate::seconds(self : JsDate) -> Double {
  modulo((self.wall() / MS_PER_SECOND).floor(), 60)
}

///|
/// `getMilliseconds()`.
pub fn JsDate::milliseconds(self : JsDate) -> Double {
  modulo(self.wall(), MS_PER_SECOND)
}

///|
/// `getUTCSeconds()`.
pub fn JsDate::utc_seconds(self : JsDate) -> Double {
  modulo((self.time / MS_PER_SECOND).floor(), 60)
}

///|
/// `getTimezoneOffset()`.
pub fn JsDate::timezone_offset(self : JsDate) -> Double {
  (self.time - self.wall()) / MS_PER_MINUTE + 0
}

///|
/// `setTime(time)`.
pub fn JsDate::set_time(self : JsDate, time : Double) -> Unit {
  self.time = time_clip(time)
}

///|
fn JsDate::set_local(self : JsDate, wall : Double) -> Unit {
  self.time = time_clip(utc(wall))
}

///|
/// `setDate(date)`.
pub fn JsDate::set_date(self : JsDate, date : Double) -> Unit {
  let t = self.wall()
  if t.is_nan() {
    return
  }
  let (month, _) = month_and_date(t)
  self.set_local(
    make_date(make_day(year_from_time(t), month, date), time_within_day(t)),
  )
}

///|
/// `setMonth(month, date)`.
pub fn JsDate::set_month(self : JsDate, month : Double, date? : Double) -> Unit {
  let t = self.wall()
  if t.is_nan() {
    return
  }
  let day = match date {
    Some(day) => day
    None => month_and_date(t).1
  }
  self.set_local(
    make_date(make_day(year_from_time(t), month, day), time_within_day(t)),
  )
}

///|
/// `setFullYear(year, month, date)`.
pub fn JsDate::set_full_year(
  self : JsDate,
  year : Double,
  month? : Double,
  date? : Double,
) -> Unit {
  let t : Double = if self.time.is_nan() { 0 } else { self.wall() }
  let (own_month, own_date) = month_and_date(t)
  self.set_local(
    make_date(
      make_day(year, month.unwrap_or(own_month), date.unwrap_or(own_date)),
      time_within_day(t),
    ),
  )
}

///|
/// `setHours(hours, minutes, seconds, ms)`.
pub fn JsDate::set_hours(
  self : JsDate,
  hours : Double,
  minutes? : Double,
  seconds? : Double,
  ms? : Double,
) -> Unit {
  let t = self.wall()
  if t.is_nan() {
    return
  }
  let time = make_time(
    hours,
    minutes.unwrap_or(self.minutes()),
    seconds.unwrap_or(self.seconds()),
    ms.unwrap_or(self.milliseconds()),
  )
  self.set_local(make_date(day_number(t), time))
}
