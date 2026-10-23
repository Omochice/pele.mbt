// Ported from pele's tests/gantt/dates.test.ts.
// Local time is UTC here, so the zone pele's tests compute is always +00:00.

///|
fn at_local(
  year : Double,
  month : Double,
  day : Double,
  hours~ : Double = 0,
  minutes~ : Double = 0,
  seconds~ : Double = 0,
  ms~ : Double = 0,
) -> Double {
  @date.JsDate::from_local(year, month, day~, hours~, minutes~, seconds~, ms~).time
}

///|
let now : @date.JsDate = @date.JsDate::from_local(
  2031,
  4,
  day=6,
  hours=9,
  minutes=30,
  seconds=15,
  ms=250,
)

///|
fn parse(input : String, template : String) -> Double? {
  @gantt.parse_strict(input, template, now).map(date => date.time)
}

///|
fn shown(input : String, template : String) -> String {
  match parse(input, template) {
    Some(time) => time.to_string()
    None => "None"
  }
}

///|
test "strict date parsing reads what fits the format" {
  let cases : Array[(String, String, Double)] = [
    ("2014-01-06", "YYYY-MM-DD", at_local(2014, 0, 6)),
    ("06-01-2014", "DD-MM-YYYY", at_local(2014, 0, 6)),
    ("14/1/6", "YY/M/D", at_local(2014, 0, 6)),
    ("70/12/31", "YY/M/D", at_local(1970, 11, 31)),
    (
      "2014-01-06 17:49",
      "YYYY-MM-DD HH:mm",
      at_local(2014, 0, 6, hours=17, minutes=49),
    ),
    (
      "2014-01-06 7:5:9",
      "YYYY-MM-DD H:m:s",
      at_local(2014, 0, 6, hours=7, minutes=5, seconds=9),
    ),
    (
      "2014-01-06T07:05:09.123",
      "YYYY-MM-DDTHH:mm:ss.SSS",
      at_local(2014, 0, 6, hours=7, minutes=5, seconds=9, ms=123),
    ),
    ("9:30 PM", "h:mm A", at_local(2031, 4, 6, hours=21, minutes=30)),
    ("12:05 am", "hh:mm a", at_local(2031, 4, 6, hours=0, minutes=5)),
    ("12:05 pm", "hh:mm a", at_local(2031, 4, 6, hours=12, minutes=5)),
    ("Jan 5, 2024", "MMM D, YYYY", at_local(2024, 0, 5)),
    ("5th January 2024", "Do MMMM YYYY", at_local(2024, 0, 5)),
    ("22nd December 2024", "Do MMMM YYYY", at_local(2024, 11, 22)),
    ("on 2024-03-01", "[on] YYYY-MM-DD", at_local(2024, 2, 1)),
    ("17:49", "HH:mm", at_local(2031, 4, 6, hours=17, minutes=49)),
    ("2024", "YYYY", at_local(2024, 0, 1)),
    ("03", "MM", at_local(2031, 2, 1)),
    ("7", "D", at_local(2031, 4, 7)),
    ("20", "ss", at_local(2031, 4, 6, seconds=20)),
    ("2 2024", "Q YYYY", at_local(2024, 3, 1)),
    ("Monday 2024", "dddd YYYY", at_local(2024, 0, 1)),
  ]
  let wrong = cases.filter(case => parse(case.0, case.1) != Some(case.2))
  inspect(wrong.map(case => case.0).join("|"), content="")
}

///|
test "strict date parsing rejects what does not fit" {
  let cases : Array[(String, String)] = [
    ("2014-1-6", "YYYY-MM-DD"),
    ("2014-01-06 7:05:09", "YYYY-MM-DD H:m:s"),
    ("2014-13-01", "YYYY-MM-DD"),
    ("2014-02-30", "YYYY-MM-DD"),
    ("202-12-01", "YYYY-MM-DD"),
    ("202304", "YYYYMMDD"),
    ("2014-01-06 ", "YYYY-MM-DD"),
    (" 2014-01-06", "YYYY-MM-DD"),
    ("2014-01-06x", "YYYY-MM-DD"),
    ("0", "ss"),
    ("25:00", "HH:mm"),
    ("5 January 2024", "Do MMMM YYYY"),
    ("5th january 2024", "Do MMMM YYYY"),
    ("Tuesday 2024", "dddd YYYY"),
    ("2014-01-06", ""),
    ("2014-01-06", "q"),
    ("12/25/2020", "L"),
    ("2020-01", "YYYY-ww"),
    ("Invalid Date", ""),
    ("", "YYYY-MM-DD"),
  ]
  let wrong = cases.filter(case => parse(case.0, case.1) is Some(_))
  inspect(wrong.map(case => case.0).join("|"), content="")
}

///|
test "strict date parsing reads Unix timestamps in seconds and in milliseconds" {
  inspect(shown("1410715640", "X"), content="1410715640000")
  inspect(shown("1410715640579", "x"), content="1410715640579")
  inspect(shown("-5", "x"), content="-5")
  inspect(shown("1410715640.579", "X"), content="None")
  inspect(shown("1e3", "x"), content="None")
  inspect(shown("", "x"), content="None")
}

///|
test "strict date parsing accepts a UTC offset only when it is the local one" {
  let expected = Some(at_local(2024, 0, 5, hours=10))
  assert_eq(
    parse("2024-01-05T10:00:00+00:00", "YYYY-MM-DDTHH:mm:ssZ"),
    expected,
  )
  assert_eq(
    parse("2024-01-05T10:00:00+0000", "YYYY-MM-DDTHH:mm:ssZZ"),
    expected,
  )
  inspect(
    shown("2024-01-05T10:00:00+05:45", "YYYY-MM-DDTHH:mm:ssZ"),
    content="None",
  )
}

///|
fn format(template : String) -> String {
  let date = @date.JsDate::from_local(
    2024,
    1,
    day=3,
    hours=15,
    minutes=4,
    seconds=5,
    ms=67,
  )
  @gantt.format_date(date, template).unwrap_or("<none>")
}

///|
test "date formatting writes each token" {
  let cases : Array[(String, String)] = [
    ("YYYY-MM-DD", "2024-02-03"),
    ("YY M D", "24 2 3"),
    ("MMM MMMM", "Feb February"),
    ("d dd ddd dddd", "6 Sa Sat Saturday"),
    ("H HH h hh", "15 15 3 03"),
    ("m mm s ss SSS", "4 04 5 05 067"),
    ("a A", "pm PM"),
    ("Do [of] MMMM", "3rd of February"),
    ("Q", "1"),
    ("k kk", "15 15"),
    ("W WW GGGG", "5 05 2024"),
    ("[YYYY] YYYY", "YYYY 2024"),
    ("x", "1706972645067"),
    ("X", "1706972645"),
    ("Y YYY", "Y 24Y"),
    ("S SS", "S SS"),
  ]
  let wrong = cases.filter(case => format(case.0) != case.1)
  inspect(
    wrong.map(case => case.0 + " => " + format(case.0)).join("|"),
    content="",
  )
}

///|
test "date formatting writes the UTC offset" {
  inspect(format("Z"), content="+00:00")
  inspect(format("ZZ"), content="+0000")
  inspect(format(""), content="2024-02-03T15:04:05+00:00")
}

///|
test "date formatting writes ordinals, midnight, and ISO weeks at the edges of a year" {
  let ordinals = [1, 2, 3, 4, 11, 12, 13, 21, 22, 23, 31].map(d => {
    @gantt.format_date(
      @date.JsDate::from_local(2024, 0, day=d.to_double()),
      "Do",
    ).unwrap_or("")
  })
  inspect(
    ordinals.join(" "),
    content="1st 2nd 3rd 4th 11th 12th 13th 21st 22nd 23rd 31st",
  )
  let at = (
    y : Double,
    m : Double,
    d : Double,
    h : Double,
    min : Double,
    t : String,
  ) => {
    @gantt.format_date(
      @date.JsDate::from_local(y, m, day=d, hours=h, minutes=min),
      t,
    ).unwrap_or("")
  }
  inspect(at(2024, 0, 1, 0, 30, "k h a"), content="24 12 am")
  inspect(at(2021, 0, 3, 0, 0, "GGGG-[W]WW"), content="2020-W53")
  inspect(at(2024, 11, 30, 0, 0, "GGGG-[W]WW"), content="2025-W01")
  inspect(at(2026, 0, 1, 0, 0, "W"), content="1")
}

///|
test "date formatting has no output for tokens that need dayjs plugins Mermaid does not load" {
  for template in ["w", "ww", "wo", "gggg", "z", "zzz", "YYYY-ww"] {
    assert_eq(format(template), "<none>")
  }
  inspect(format("[w] YYYY"), content="w 2024")
}

///|
test "date formatting reports an invalid date" {
  inspect(
    @gantt.format_date(@date.JsDate::from_time(@double.not_a_number), "YYYY").unwrap_or(
      "",
    ),
    content="Invalid Date",
  )
}

///|
fn add(start : Double, amount : Double, unit : String) -> Double {
  @gantt.add_time(@date.JsDate::from_time(start), amount, unit).time
}

///|
test "date arithmetic adds calendar days and weeks" {
  assert_eq(add(at_local(2020, 10, 1), 1, "d"), at_local(2020, 10, 2))
  assert_eq(add(at_local(2024, 2, 9), 2, "d"), at_local(2024, 2, 11))
  assert_eq(add(at_local(2013, 0, 1), 2, "w"), at_local(2013, 0, 15))
  assert_eq(add(at_local(2013, 0, 1), 1.5, "d"), at_local(2013, 0, 3))
  assert_eq(add(at_local(2013, 0, 1), 0.4, "d"), at_local(2013, 0, 1))
  assert_eq(add(at_local(2013, 0, 1), 0.5, "w"), at_local(2013, 0, 5))
}

///|
test "date arithmetic adds exact hours, minutes, seconds, and milliseconds" {
  let start = at_local(2013, 0, 1)
  assert_eq(add(start, 2, "h") - start, 7200000)
  assert_eq(add(start, 2, "m") - start, 120000)
  assert_eq(add(start, 0.005, "s") - start, 5)
  assert_eq(add(start, 20, "ms") - start, 20)
}

///|
test "date arithmetic adds months and years, keeping to the end of a shorter month" {
  assert_eq(add(at_local(2024, 0, 31), 1, "M"), at_local(2024, 1, 29))
  assert_eq(add(at_local(2023, 11, 31), 2, "M"), at_local(2024, 1, 29))
  assert_eq(add(at_local(2024, 2, 30), 11, "M"), at_local(2025, 1, 28))
  assert_eq(add(at_local(2024, 1, 29), 1, "y"), at_local(2025, 1, 28))
  assert_eq(add(at_local(2024, 0, 15), 1.5, "M"), at_local(2024, 1, 15))
}

///|
test "date arithmetic gives an invalid date beyond the range of dates" {
  assert_true(add(at_local(2024, 0, 1), 99999999, "y").is_nan())
}

///|
fn duration(text : String) -> String {
  let (amount, unit) = @gantt.parse_duration(text)
  "\{amount} \{unit}"
}

///|
test "durations are read with their unit" {
  inspect(duration("1.5d"), content="1.5 d")
  inspect(duration(" 3M "), content="3 M")
  inspect(duration("500ms"), content="500 ms")
  inspect(duration("3dX"), content="NaN ms")
  inspect(duration("-1d"), content="NaN ms")
  inspect(duration("1d"), content="1 d")
  inspect(duration("2w"), content="2 w")
  inspect(duration("1ms"), content="1 ms")
  inspect(duration("0.1s"), content="0.1 s")
  inspect(duration("1f"), content="NaN ms")
}
