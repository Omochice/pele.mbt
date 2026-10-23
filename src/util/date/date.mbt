///|
/// A JavaScript `Date`: milliseconds since the epoch, NaN when the date is invalid.
pub struct JsDate {
  mut time : Double
}

///|
/// `new Date(time)`.
pub fn JsDate::from_time(time : Double) -> JsDate {
  { time, }
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
  ignore((year, month, day, hours, minutes, seconds, ms))
  { time: 0, }
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
  ignore((year, month, day, hours, minutes, seconds, ms))
  0
}

///|
/// An independent date with the same time.
pub fn JsDate::copy(self : JsDate) -> JsDate {
  { time: self.time, }
}

///|
/// `getFullYear()`.
pub fn JsDate::full_year(self : JsDate) -> Double {
  self.time
}

///|
/// `getMonth()`.
pub fn JsDate::month(self : JsDate) -> Double {
  self.time
}

///|
/// `getDate()`.
pub fn JsDate::date(self : JsDate) -> Double {
  self.time
}

///|
/// `getDay()`.
pub fn JsDate::day(self : JsDate) -> Double {
  self.time
}

///|
/// `getHours()`.
pub fn JsDate::hours(self : JsDate) -> Double {
  self.time
}

///|
/// `getMinutes()`.
pub fn JsDate::minutes(self : JsDate) -> Double {
  self.time
}

///|
/// `getSeconds()`.
pub fn JsDate::seconds(self : JsDate) -> Double {
  self.time
}

///|
/// `getMilliseconds()`.
pub fn JsDate::milliseconds(self : JsDate) -> Double {
  self.time
}

///|
/// `getUTCSeconds()`.
pub fn JsDate::utc_seconds(self : JsDate) -> Double {
  self.time
}

///|
/// `getTimezoneOffset()`.
pub fn JsDate::timezone_offset(self : JsDate) -> Double {
  self.time
}

///|
/// `setTime(time)`.
pub fn JsDate::set_time(self : JsDate, time : Double) -> Unit {
  self.time = time
}

///|
/// `setDate(date)`.
pub fn JsDate::set_date(self : JsDate, date : Double) -> Unit {
  ignore(date)
  self.time = 0
}

///|
/// `setMonth(month, date)`.
pub fn JsDate::set_month(self : JsDate, month : Double, date? : Double) -> Unit {
  ignore((month, date))
  self.time = 0
}

///|
/// `setFullYear(year, month, date)`.
pub fn JsDate::set_full_year(
  self : JsDate,
  year : Double,
  month? : Double,
  date? : Double,
) -> Unit {
  ignore((year, month, date))
  self.time = 0
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
  ignore((hours, minutes, seconds, ms))
  self.time = 0
}
