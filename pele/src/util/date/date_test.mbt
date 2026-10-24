// The expected values were taken from node with TZ=UTC.

///|
fn fields(date : @date.JsDate) -> String {
  [
    date.time,
    date.full_year(),
    date.month(),
    date.date(),
    date.day(),
    date.hours(),
    date.minutes(),
    date.seconds(),
    date.milliseconds(),
  ]
  .map(value => value.to_string())
  .join(" ")
}

///|
test "builds local dates from calendar fields" {
  inspect(
    fields(@date.JsDate::from_local(2024, 1, day=29)),
    content="1709164800000 2024 1 29 4 0 0 0 0",
  )
  inspect(
    fields(
      @date.JsDate::from_local(
        2024,
        0,
        day=10,
        hours=15,
        minutes=4,
        seconds=5,
        ms=67,
      ),
    ),
    content="1704899045067 2024 0 10 3 15 4 5 67",
  )
}

///|
test "reads years 0 to 99 as 1900 to 1999" {
  inspect(
    fields(@date.JsDate::from_local(99, 0)),
    content="915148800000 1999 0 1 5 0 0 0 0",
  )
  inspect(
    fields(@date.JsDate::from_local(0, 0, day=1)),
    content="-2208988800000 1900 0 1 1 0 0 0 0",
  )
}

///|
test "reads times before 1970 and before year one" {
  inspect(
    fields(@date.JsDate::from_time(-1)),
    content="-1 1969 11 31 3 23 59 59 999",
  )
  inspect(
    fields(@date.JsDate::from_time(-62198755200000)),
    content="-62198755200000 -1 0 1 5 0 0 0 0",
  )
}

///|
test "keeps times within 8.64e15 milliseconds of the epoch" {
  inspect(
    fields(@date.JsDate::from_time(8.64e15)),
    content="8640000000000000 275760 8 13 6 0 0 0 0",
  )
  inspect(
    fields(@date.JsDate::from_time(-8.64e15)),
    content="-8640000000000000 -271821 3 20 2 0 0 0 0",
  )
  inspect(
    fields(@date.JsDate::from_time(8.64e15 + 1)),
    content="NaN NaN NaN NaN NaN NaN NaN NaN NaN",
  )
  inspect(@date.JsDate::from_time(1.5).time, content="1")
  inspect(@date.JsDate::from_time(-1.5).time, content="-1")
}

///|
test "truncates fractional fields and carries overflowing ones" {
  inspect(
    fields(@date.JsDate::from_local(2024, 0.9, day=1.7, hours=3.2)),
    content="1704078000000 2024 0 1 1 3 0 0 0",
  )
  inspect(
    fields(@date.JsDate::from_local(2024, 25, day=31)),
    content="1772496000000 2026 2 3 2 0 0 0 0",
  )
  inspect(
    fields(@date.JsDate::from_local(2024, -1, day=0)),
    content="1701302400000 2023 10 30 4 0 0 0 0",
  )
  inspect(
    fields(@date.JsDate::from_local(2024, @double.not_a_number)),
    content="NaN NaN NaN NaN NaN NaN NaN NaN NaN",
  )
}

///|
test "builds UTC times" {
  inspect(@date.utc_time(2024, 0, 1, 12, 30, 15, 500), content="1704112215500")
  inspect(@date.utc_time(70, 0, 1, 0, 0, 0, 0), content="0")
}

///|
test "sets calendar fields as JavaScript does" {
  let d = @date.JsDate::from_local(2024, 0, day=31)
  d.set_month(1)
  inspect(fields(d), content="1709337600000 2024 2 2 6 0 0 0 0")
  let e = @date.JsDate::from_time(@double.not_a_number)
  e.set_full_year(2020)
  inspect(fields(e), content="1577836800000 2020 0 1 3 0 0 0 0")
  let f = @date.JsDate::from_time(@double.not_a_number)
  f.set_date(3)
  inspect(fields(f), content="NaN NaN NaN NaN NaN NaN NaN NaN NaN")
  let g = @date.JsDate::from_time(8.64e15)
  g.set_date(g.date() + 1)
  inspect(fields(g), content="NaN NaN NaN NaN NaN NaN NaN NaN NaN")
  let h = @date.JsDate::from_local(
    2024,
    0,
    day=10,
    hours=15,
    minutes=4,
    seconds=5,
    ms=67,
  )
  h.set_hours(0, minutes=0, seconds=0, ms=0)
  inspect(fields(h), content="1704844800000 2024 0 10 3 0 0 0 0")
  let i = @date.JsDate::from_local(
    2024,
    0,
    day=10,
    hours=15,
    minutes=4,
    seconds=5,
    ms=67,
  )
  i.set_hours(25)
  inspect(fields(i), content="1704935045067 2024 0 11 4 1 4 5 67")
  let j = @date.JsDate::from_local(2024, 0, day=10)
  j.set_month(0, date=1)
  inspect(fields(j), content="1704067200000 2024 0 1 1 0 0 0 0")
  let k = @date.JsDate::from_local(2024, 5, day=10)
  k.set_full_year(275760, month=8, date=13)
  inspect(fields(k), content="8640000000000000 275760 8 13 6 0 0 0 0")
  k.set_date(14)
  inspect(fields(k), content="NaN NaN NaN NaN NaN NaN NaN NaN NaN")
  let m = @date.JsDate::from_time(0)
  m.set_time(1.0e20)
  inspect(m.time, content="NaN")
}

///|
test "copies are independent" {
  let a = @date.JsDate::from_time(0)
  let b = a.copy()
  b.set_date(5)
  inspect(a.time, content="0")
  inspect(b.time, content="345600000")
}

///|
test "reads the UTC seconds" {
  inspect(@date.JsDate::from_time(61500).utc_seconds(), content="1")
}

///|
test "has no offset from UTC" {
  inspect(@date.JsDate::from_time(0).timezone_offset(), content="0")
}
