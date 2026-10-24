// Ported from pele's tests/gantt/dates.test.ts, with local time fixed to UTC.

///|
fn when(
  year : Double,
  month : Double,
  day : Double,
  hours~ : Double = 0,
  minutes~ : Double = 0,
) -> Double {
  @date.JsDate::from_local(year, month, day~, hours~, minutes~).time
}

///|
fn axis_format(specifier : String) -> String raise @errors.PeleError {
  let date = @date.JsDate::from_local(
    2024,
    1,
    day=3,
    hours=15,
    minutes=4,
    seconds=5,
    ms=67,
  )
  @gantt.time_format(specifier, date)
}

///|
test "axis formats write each directive" {
  let cases : Array[(String, String)] = [
    ("%Y-%m-%d", "2024-02-03"),
    ("%a %A %b %B", "Sat Saturday Feb February"),
    ("%H:%M:%S.%L", "15:04:05.067"),
    ("%I %p", "03 PM"),
    ("%e|%-d|%_d|%0e", " 3|3| 3|03"),
    ("%j", "034"),
    ("%U %W %V", "04 05 05"),
    ("%u %w", "6 6"),
    ("%y %G %g", "24 2024 24"),
    ("%q", "1"),
    ("%x", "2/3/2024"),
    ("%X", "3:04:05 PM"),
    ("%c", "2/3/2024, 3:04:05 PM"),
    ("%f", "067000"),
    ("%%Y %k %", "%Y k "),
    ("%s", "1706972645"),
    ("%Q", "1706972645067"),
  ]
  let wrong = cases.filter(case => axis_format(case.0) != case.1)
  inspect(
    wrong.map(case => case.0 + " => " + axis_format(case.0)).join("|"),
    content="",
  )
}

///|
test "axis formats number weeks from the first Sunday, the first Monday, and by ISO rules" {
  let at = (y : Double, m : Double, d : Double, specifier : String) => {
    @gantt.time_format(specifier, @date.JsDate::from_local(y, m, day=d))
  }
  inspect(at(2023, 0, 1, "%U %W %V %G"), content="01 00 52 2022")
  inspect(at(2024, 11, 30, "%U %W %V %G"), content="52 53 01 2025")
  inspect(at(2024, 0, 1, "%U %W %V"), content="00 01 01")
}

///|
fn same(actual : Array[Double]?, expected : Array[Double]) -> Bool {
  match actual {
    Some(ticks) => ticks == expected
    None => false
  }
}

///|
test "axis ticks pick round steps for the span" {
  assert_true(
    @gantt.auto_ticks(when(2014, 0, 1), when(2014, 1, 20), 10) ==
    [0.0, 1, 2, 3, 4, 5, 6].map(k => when(2014, 0, 5 + 7 * k)),
  )
  assert_true(
    @gantt.auto_ticks(
      when(2024, 0, 10, hours=9),
      when(2024, 0, 10, hours=18),
      10,
    ) ==
    [9.0, 10, 11, 12, 13, 14, 15, 16, 17, 18].map(h => {
      when(2024, 0, 10, hours=h)
    }),
  )
  assert_true(
    @gantt.auto_ticks(when(1900, 0, 1), when(2020, 0, 1), 10) ==
    Array::makei(13, k => when(1900 + 10 * k.to_double(), 0, 1)),
  )
  assert_true(
    @gantt.auto_ticks(when(2024, 0, 1), when(2024, 6, 31), 7) ==
    [0.0, 1, 2, 3, 4, 5, 6].map(m => when(2024, m, 1)),
  )
  assert_true(
    @gantt.auto_ticks(0, 71000, 10) ==
    Array::makei(15, k => k.to_double() * 5000),
  )
  assert_true(
    @gantt.auto_ticks(0, 30, 10) ==
    [0.0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30],
  )
}

///|
test "axis ticks follow a tick interval and the weekday that weeks start on" {
  let start = when(2024, 0, 1)
  let stop = when(2024, 0, 31)
  assert_true(
    same(
      @gantt.interval_ticks("1week", "monday", start, stop, 100),
      [1.0, 8, 15, 22, 29].map(d => when(2024, 0, d)),
    ),
  )
  assert_true(
    same(
      @gantt.interval_ticks("1week", "sunday", start, stop, 100),
      [7.0, 14, 21, 28].map(d => when(2024, 0, d)),
    ),
  )
  assert_true(
    same(
      @gantt.interval_ticks("1week", "thursday", start, stop, 100),
      [4.0, 11, 18, 25].map(d => when(2024, 0, d)),
    ),
  )
  assert_true(
    same(
      @gantt.interval_ticks("10day", "sunday", start, stop, 100),
      [1.0, 11, 21, 31].map(d => when(2024, 0, d)),
    ),
  )
  assert_true(
    same(
      @gantt.interval_ticks("1month", "sunday", start, when(2024, 3, 2), 100),
      [0.0, 1, 2, 3].map(m => when(2024, m, 1)),
    ),
  )
  assert_true(
    same(
      @gantt.interval_ticks("6hour", "sunday", start, when(2024, 0, 2), 100),
      [0.0, 6, 12, 18, 24].map(h => when(2024, 0, 1, hours=h)),
    ),
  )
  assert_true(
    same(
      @gantt.interval_ticks(
        "15minute",
        "sunday",
        when(2024, 0, 1, hours=9, minutes=5),
        when(2024, 0, 1, hours=10),
        100,
      ),
      [15.0, 30, 45, 60].map(m => when(2024, 0, 1, hours=9, minutes=m)),
    ),
  )
  assert_true(
    @gantt.interval_ticks("2week", "monday", start, stop, 100).unwrap().length() <=
    3,
  )
}

///|
test "axis ticks decline intervals they do not know and ones that ask for too many ticks" {
  let start = when(2024, 0, 1)
  let stop = when(2024, 0, 31)
  for
    interval in [
      "", "1decade", "1year", "0day", "01day", "1 day", "1days", "day", "1.5day",
      "-1day",
    ] {
    assert_true(
      @gantt.interval_ticks(interval, "sunday", start, stop, 100) is None,
    )
  }
  assert_true(
    @gantt.interval_ticks("1second", "sunday", start, stop, 1000) is None,
  )
  assert_true(
    @gantt.interval_ticks("99999999second", "sunday", start, stop, 1000) is None,
  )
  inspect(
    @gantt.interval_ticks("1day", "nonsense", start, stop, 100)
    .unwrap()
    .length(),
    content="31",
  )
}

///|
test "axis ticks stop filtered tick searches when dates overflow" {
  let limit = 8.64e15
  assert_true(@gantt.auto_ticks(-limit, -limit + 120000, 4) == [])
  assert_true(
    same(@gantt.interval_ticks("2second", "sunday", limit - 1000, limit, 10), [
      limit,
    ]),
  )
}
