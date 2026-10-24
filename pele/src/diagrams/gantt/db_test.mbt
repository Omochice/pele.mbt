// Ported from Mermaid's ganttDb.spec.ts and pele's gantt scheduling tests.
// The expected schedules were taken from pele's model with local time fixed to UTC.

///|
fn time_of(date : @date.JsDate?) -> String {
  match date {
    Some(d) => d.time.to_string()
    None => "-"
  }
}

///|
fn list(items : Array[String], separator~ : String = ",") -> String {
  "[" + items.join(separator) + "]"
}

///|
fn settings(db : @gantt.GanttDb) -> String {
  let links = db.links.iter().map(entry => entry.0 + "=" + entry.1).collect()
  "settings: dateFormat=\{quote(db.date_format)} axisFormat=\{quote(db.axis_format)} " +
  "tickInterval=\{db.tick_interval.unwrap_or("-")} todayMarker=\{quote(db.today_marker)} " +
  "includes=\{list(db.includes)} excludes=\{list(db.excludes)} inclusive=\{db.inclusive_end_dates} " +
  "topAxis=\{db.top_axis} weekday=\{db.weekday.unwrap_or("-")} weekend=\{db.weekend} " +
  "sections=\{list(db.sections, separator="|")} links=\{list(links)}"
}

///|
fn task_line(t : @gantt.GanttTask) -> String {
  let flags = []
  if t.active {
    flags.push("active")
  }
  if t.done {
    flags.push("done")
  }
  if t.crit {
    flags.push("crit")
  }
  if t.milestone {
    flags.push("milestone")
  }
  if t.vert {
    flags.push("vert")
  }
  let render_end = match t.render_end_time {
    Some(d) => d.time.to_string()
    None => "null"
  }
  "\{t.id} \{quote(t.task)} [\{t.section}] \{time_of(t.start_time)} \{time_of(t.end_time)} \{render_end} " +
  "order=\{t.order} manual=\{t.manual_end_time} processed=\{t.processed} flags=\{list(flags)} " +
  "classes=\{list(t.classes)} prev=\{t.prev_task_id.unwrap_or("-")}"
}

///|
/// Parses a chart, schedules it against `now` and lists the settings, warnings and tasks.
fn schedule(source : String, now : Double, repeat~ : Int32 = 1) -> String {
  let lines = []
  try {
    let db = @gantt.GanttDb::from_source(source, warn=message => {
      lines.push("warn: " + message)
    })
    lines.push(settings(db))
    for _ in 0..<repeat {
      for t in db.get_tasks(now) {
        lines.push(task_line(t))
      }
    }
  } catch {
    @errors.PeleError(failure) =>
      lines.push("error: \{failure.code.to_string()}: \{failure.message}")
  }
  lines.join("\n")
}

///|
test "handles fixed dates" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\nsection testa1\ntest1 :id1,2013-01-01,2013-01-12\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[testa1] links=[]
      #|id1 "test1 " [testa1] 1356998400000 1357948800000 null order=0 manual=true processed=true flags=[] classes=[] prev=-
    ),
  )
}

///|
test "handles durations instead of end dates" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\nsection testa1\nd :id1,2013-01-01,2d\nh :id2,2013-01-01,2h\nm :id3,2013-01-01,2m\ns :id4,2013-01-01,2s\nw :id5,2013-01-01,2w\nM :id6,2013-01-31,1M\ny :id7,2012-02-29,1y\nms :id8,2013-01-01,500ms\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[testa1] links=[]
      #|id1 "d " [testa1] 1356998400000 1357171200000 null order=0 manual=false processed=true flags=[] classes=[] prev=-
      #|id2 "h " [testa1] 1356998400000 1357005600000 null order=1 manual=false processed=true flags=[] classes=[] prev=id1
      #|id3 "m " [testa1] 1356998400000 1356998520000 null order=2 manual=false processed=true flags=[] classes=[] prev=id2
      #|id4 "s " [testa1] 1356998400000 1356998402000 null order=3 manual=false processed=true flags=[] classes=[] prev=id3
      #|id5 "w " [testa1] 1356998400000 1358208000000 null order=4 manual=false processed=true flags=[] classes=[] prev=id4
      #|id6 "M " [testa1] 1359590400000 1362009600000 null order=5 manual=false processed=true flags=[] classes=[] prev=id5
      #|id7 "y " [testa1] 1330473600000 1362009600000 null order=6 manual=false processed=true flags=[] classes=[] prev=id6
      #|id8 "ms " [testa1] 1356998400000 1356998400500 null order=7 manual=false processed=true flags=[] classes=[] prev=id7
    ),
  )
}

///|
test "numbers tasks without an id" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\nsection testa1\ntest1 :2013-01-01,2013-01-12\ntest2 :2013-01-01,4d\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[testa1] links=[]
      #|task1 "test1 " [testa1] 1356998400000 1357948800000 null order=0 manual=true processed=true flags=[] classes=[] prev=-
      #|task2 "test2 " [testa1] 1356998400000 1357344000000 null order=1 manual=false processed=true flags=[] classes=[] prev=task1
    ),
  )
}

///|
test "starts tasks after others, the previous one or today" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\nsection testa1\ntest1 :id1,2013-01-01,2w\ntest2 :id2,after id1,1d\ntest3 :id3,after id9,1d\ntest4 :after id1,1d\ntest5 :2013-01-26\ntest6 :2d\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[testa1] links=[]
      #|warn: Gantt: "after" refers to task ids that do not exist: id9.
      #|id1 "test1 " [testa1] 1356998400000 1358208000000 null order=0 manual=false processed=true flags=[] classes=[] prev=-
      #|id2 "test2 " [testa1] 1358208000000 1358294400000 null order=1 manual=false processed=true flags=[] classes=[] prev=id1
      #|id3 "test3 " [testa1] 1389830400000 1389916800000 null order=2 manual=false processed=true flags=[] classes=[] prev=id2
      #|task1 "test4 " [testa1] 1358208000000 1358294400000 null order=3 manual=false processed=true flags=[] classes=[] prev=id3
      #|task2 "test5 " [testa1] 1358294400000 1359158400000 null order=4 manual=true processed=true flags=[] classes=[] prev=task1
      #|task3 "test6 " [testa1] 1359158400000 1359331200000 null order=5 manual=false processed=true flags=[] classes=[] prev=task2
    ),
  )
}

///|
test "handles milliseconds" {
  inspect(
    schedule(
      "gantt\ndateFormat x\nsection testa1\ntest1 :id1,0,20ms\ntest2 :id2,after id1,5ms\nsection testa2\ntest3 :id3,20,10ms\ntest4 :id4,after id3,0.005s\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="x" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[testa1|testa2] links=[]
      #|id1 "test1 " [testa1] 0 20 null order=0 manual=false processed=true flags=[] classes=[] prev=-
      #|id2 "test2 " [testa1] 20 25 null order=1 manual=false processed=true flags=[] classes=[] prev=id1
      #|id3 "test3 " [testa2] 20 30 null order=2 manual=false processed=true flags=[] classes=[] prev=id2
      #|id4 "test4 " [testa2] 30 35 null order=3 manual=false processed=true flags=[] classes=[] prev=id3
    ),
  )
}

///|
test "resolves references regardless of sections" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\nsection sec1\ntest1 :id1,2013-01-01,2w\ntest2 :id2,after id3,1d\nsection sec2\ntest3 :id3,after id1,2d\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[sec1|sec2] links=[]
      #|id1 "test1 " [sec1] 1356998400000 1358208000000 null order=0 manual=false processed=true flags=[] classes=[] prev=-
      #|id2 "test2 " [sec1] 1358380800000 1358467200000 null order=1 manual=false processed=true flags=[] classes=[] prev=id1
      #|id3 "test3 " [sec2] 1358208000000 1358380800000 null order=2 manual=false processed=true flags=[] classes=[] prev=id2
    ),
  )
}

///|
test "ends tasks until others" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\nsection sec1\ntask1 :id1,2013-01-01,until id3\nsection sec2\ntask2 :id2,2013-01-10,until id3\ntask3 :id3,2013-02-01,2d\ntask4 :id4,2013-01-01,until nothing\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[sec1|sec2] links=[]
      #|warn: Gantt: "until" refers to task ids that do not exist: nothing.
      #|warn: Gantt: "until" refers to task ids that do not exist: nothing.
      #|id1 "task1 " [sec1] 1356998400000 1359676800000 null order=0 manual=false processed=true flags=[] classes=[] prev=-
      #|id2 "task2 " [sec2] 1357776000000 1359676800000 null order=1 manual=false processed=true flags=[] classes=[] prev=id1
      #|id3 "task3 " [sec2] 1359676800000 1359849600000 null order=2 manual=false processed=true flags=[] classes=[] prev=id2
      #|id4 "task4 " [sec2] 1356998400000 1389830400000 null order=3 manual=false processed=true flags=[] classes=[] prev=id3
    ),
  )
}

///|
test "follows the latest of several ids and ends at the earliest" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\nsection sec1\ntask1 :id1,after id2 id3 id4,1d\ntask2 :id2,2013-01-01,1d\ntask3 :id3,2013-02-01,3d\ntask4 :id4,2013-02-01,2d\ntask5 :id5,2013-01-01,until id2 id3 id4\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[sec1] links=[]
      #|id1 "task1 " [sec1] 1359936000000 1360022400000 null order=0 manual=false processed=true flags=[] classes=[] prev=-
      #|id2 "task2 " [sec1] 1356998400000 1357084800000 null order=1 manual=false processed=true flags=[] classes=[] prev=id1
      #|id3 "task3 " [sec1] 1359676800000 1359936000000 null order=2 manual=false processed=true flags=[] classes=[] prev=id2
      #|id4 "task4 " [sec1] 1359676800000 1359849600000 null order=3 manual=false processed=true flags=[] classes=[] prev=id3
      #|id5 "task5 " [sec1] 1356998400000 1356998400000 null order=4 manual=false processed=true flags=[] classes=[] prev=id4
    ),
  )
}

///|
test "skips excluded weekends and dates" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\nexcludes weekends 2019-02-06,friday\nsection weekends skip test\ntest1 :id1,2019-02-01,1d\ntest2 :id2,after id1,2d\ntest3 :id3,after id2,7d\ntest4 :id4,2019-02-01,2019-02-20\ntest5 :id5,after id4,1d\nsection full ending task on last day\ntest6 :id6,2019-02-13,2d\ntest7 :id7,after id6,1d\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[weekends,2019-02-06,friday] inclusive=false topAxis=false weekday=- weekend=saturday sections=[weekends skip test|full ending task on last day] links=[]
      #|id1 "test1 " [weekends skip test] 1548979200000 1549238400000 1549065600000 order=0 manual=false processed=true flags=[] classes=[] prev=-
      #|id2 "test2 " [weekends skip test] 1549238400000 1549497600000 1549411200000 order=1 manual=false processed=true flags=[] classes=[] prev=id1
      #|id3 "test3 " [weekends skip test] 1549497600000 1550620800000 1550620800000 order=2 manual=false processed=true flags=[] classes=[] prev=id2
      #|id4 "test4 " [weekends skip test] 1548979200000 1550620800000 null order=3 manual=true processed=true flags=[] classes=[] prev=id3
      #|id5 "test5 " [weekends skip test] 1550620800000 1550707200000 1550707200000 order=4 manual=false processed=true flags=[] classes=[] prev=id4
      #|id6 "test6 " [full ending task on last day] 1550016000000 1550448000000 1550188800000 order=5 manual=false processed=true flags=[] classes=[] prev=id5
      #|id7 "test7 " [full ending task on last day] 1550448000000 1550534400000 1550534400000 order=6 manual=false processed=true flags=[] classes=[] prev=id6
    ),
  )
}

///|
test "starts weekends on friday" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\nexcludes weekends\nweekend friday\nsection friday-saturday weekends skip test\ntest1 :id1,2024-02-28, 3d\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[weekends] inclusive=false topAxis=false weekday=- weekend=friday sections=[friday-saturday weekends skip test] links=[]
      #|id1 "test1 " [friday-saturday weekends skip test] 1709078400000 1709510400000 1709510400000 order=0 manual=false processed=true flags=[] classes=[] prev=-
    ),
  )
}

///|
test "fails when every day is excluded" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\nexcludes weekends,monday,tuesday,wednesday,thursday,friday\nweekend saturday\nsection weekends skip test\ntest1 :id1,2019-02-01,7d\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[weekends,monday,tuesday,wednesday,thursday,friday] inclusive=false topAxis=false weekday=- weekend=saturday sections=[weekends skip test] links=[]
      #|error: semantic: Failed to find a valid date that was not excluded by `excludes` after 10,000 iterations.
    ),
  )
}

///|
test "finds a day when fridays are allowed" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\nexcludes weekends,monday,tuesday,wednesday,thursday\nweekend saturday\nsection weekends skip test\ntest1 :id1,2019-02-01,7d\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[weekends,monday,tuesday,wednesday,thursday] inclusive=false topAxis=false weekday=- weekend=saturday sections=[weekends skip test] links=[]
      #|id1 "test1 " [weekends skip test] 1548979200000 1553212800000 1552694400000 order=0 manual=false processed=true flags=[] classes=[] prev=-
    ),
  )
}

///|
test "merges and dedupes excluded and included tokens" {
  inspect(
    schedule(
      "gantt\nexcludes weekends,2019-02-06\nexcludes weekends 2019-02-07\nexcludes Friday, MONDAY\nincludes 2019-02-06\nincludes 2019-02-07,2019-02-08\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="" axisFormat="" tickInterval=- todayMarker="" includes=[2019-02-06,2019-02-07,2019-02-08] excludes=[weekends,2019-02-06,2019-02-07,friday,monday] inclusive=false topAxis=false weekday=- weekend=saturday sections=[] links=[]
    ),
  )
}

///|
test "excludes dates written in the chart's format and keeps included ones" {
  inspect(
    schedule(
      "gantt\ndateFormat DD-MM-YYYY\nexcludes weekends 10-02-2025 2025-02-11\nincludes 15-02-2025\nA :a, 07-02-2025, 6d\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="DD-MM-YYYY" axisFormat="" tickInterval=- todayMarker="" includes=[15-02-2025] excludes=[weekends,10-02-2025,2025-02-11] inclusive=false topAxis=false weekday=- weekend=saturday sections=[] links=[]
      #|a "A " [] 1738886400000 1739836800000 1739836800000 order=0 manual=false processed=true flags=[] classes=[] prev=-
    ),
  )
}

///|
test "works when the end date is the 31st" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\nsection Task endTime is on the 31st day of the month\ntest1 :id1,2019-09-30,11d\ntest2 :id2,after id1,20d\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[Task endTime is on the 31st day of the month] links=[]
      #|id1 "test1 " [Task endTime is on the 31st day of the month] 1569801600000 1570752000000 null order=0 manual=false processed=true flags=[] classes=[] prev=-
      #|id2 "test2 " [Task endTime is on the 31st day of the month] 1570752000000 1572480000000 null order=1 manual=false processed=true flags=[] classes=[] prev=id1
    ),
  )
}

///|
test "adds a day to end dates when they are inclusive" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\ninclusiveEndDates\ntest1 :id1,2019-02-01,1d\ntest2 :id2,2019-02-01,2019-02-03\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=true topAxis=false weekday=- weekend=saturday sections=[] links=[]
      #|id1 "test1 " [] 1548979200000 1549065600000 null order=0 manual=false processed=true flags=[] classes=[] prev=-
      #|id2 "test2 " [] 1548979200000 1549238400000 null order=1 manual=true processed=true flags=[] classes=[] prev=id1
    ),
  )
}

///|
test "rejects dates with ridiculous years" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYYMMDD\ntest1 :id1,202304,1d\n", 1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYYMMDD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[] links=[]
      #|error: semantic: Invalid date:202304
    ),
  )
}

///|
test "reads a seconds-only format" {
  inspect(
    schedule(
      "gantt\ndateFormat ss\nsection Network Request\nRTT :rtt, 0, 20\n", 1389873600000,
    ),
    content=(
      #|settings: dateFormat="ss" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[Network Request] links=[]
      #|rtt "RTT " [Network Request] 946684800000 1389830420000 null order=0 manual=false processed=true flags=[] classes=[] prev=-
    ),
  )
}

///|
test "falls back to the JavaScript date parser" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\nsection Vacation\nLondon Trip 1 :2024-12-01, 7d\nLondon Trip 2 :202-12-01, 7d\nTrip 3 :Jan 5 2024, 1d\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[Vacation] links=[]
      #|task1 "London Trip 1 " [Vacation] 1733011200000 1733616000000 null order=0 manual=false processed=true flags=[] classes=[] prev=-
      #|task2 "London Trip 2 " [Vacation] -55763856000000 -55763251200000 null order=1 manual=false processed=true flags=[] classes=[] prev=task1
      #|task3 "Trip 3 " [Vacation] 1704412800000 1704499200000 null order=2 manual=false processed=true flags=[] classes=[] prev=task2
    ),
  )
}

///|
test "warns about unknown ids and durations" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\ntask1 :id1,2013-01-01,2d\ntask2 :id2,after m1,1d\ntask3 :id3,2013-01-01,until m2 m3\nM1 :milestone, 2023-01-01, m1\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[] links=[]
      #|warn: Gantt: "after" refers to task ids that do not exist: m1.
      #|warn: Gantt: "until" refers to task ids that do not exist: m2, m3.
      #|warn: Gantt: "m1" is neither a date in the "YYYY-MM-DD" format nor a duration such as "3d", so the task gets no duration.
      #|id1 "task1 " [] 1356998400000 1357171200000 null order=0 manual=false processed=true flags=[] classes=[] prev=-
      #|id2 "task2 " [] 1389830400000 1389916800000 null order=1 manual=false processed=true flags=[] classes=[] prev=id1
      #|id3 "task3 " [] 1356998400000 1389830400000 null order=2 manual=false processed=true flags=[] classes=[] prev=id2
      #|task1 "M1 " [] 1672531200000 1672531200000 null order=3 manual=false processed=true flags=[milestone] classes=[] prev=id3
    ),
  )
}

///|
test "starts a first task with no start today" {
  inspect(
    schedule("gantt\ndateFormat YYYY-MM-DD\nA :3d\n", 1389873600000),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[] links=[]
      #|task1 "A " [] 1389830400000 1390089600000 null order=0 manual=false processed=true flags=[] classes=[] prev=-
    ),
  )
}

///|
test "takes the fields a format leaves out from now" {
  inspect(
    schedule(
      "gantt\ndateFormat HH:mm\nA :a, 17:49, 2m\nB :b, after nothing, 1h\n", 1967535000000,
    ),
    content=(
      #|settings: dateFormat="HH:mm" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[] links=[]
      #|warn: Gantt: "after" refers to task ids that do not exist: nothing.
      #|a "A " [] 1967564940000 1967565060000 null order=0 manual=false processed=true flags=[] classes=[] prev=-
      #|b "B " [] 1967500800000 1967504400000 null order=1 manual=false processed=true flags=[] classes=[] prev=a
    ),
  )
}

///|
test "gives the same result each time it is asked" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\nB :b, 2024-01-01, 2d\nX :x, after b a, 1d\nA :a, 2024-01-10, 5d\n",
      1389873600000,
      repeat=2,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[] links=[]
      #|b "B " [] 1704067200000 1704240000000 null order=0 manual=false processed=true flags=[] classes=[] prev=-
      #|x "X " [] 1704240000000 1704326400000 null order=1 manual=false processed=true flags=[] classes=[] prev=b
      #|a "A " [] 1704844800000 1705276800000 null order=2 manual=false processed=true flags=[] classes=[] prev=x
      #|b "B " [] 1704067200000 1704240000000 null order=0 manual=false processed=true flags=[] classes=[] prev=-
      #|x "X " [] 1704240000000 1704326400000 null order=1 manual=false processed=true flags=[] classes=[] prev=b
      #|a "A " [] 1704844800000 1705276800000 null order=2 manual=false processed=true flags=[] classes=[] prev=x
    ),
  )
}

///|
test "leaves tasks that refer to each other unscheduled" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\nA :a, after b, 1d\nB :b, after a, 1d\nC :c, 2024-01-01, 3d\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[] links=[]
      #|a "A " [] - - null order=0 manual=false processed=false flags=[] classes=[] prev=-
      #|b "B " [] - - null order=1 manual=false processed=false flags=[] classes=[] prev=a
      #|c "C " [] 1704067200000 1704326400000 null order=2 manual=false processed=true flags=[] classes=[] prev=b
    ),
  )
}

///|
test "rejects a start that is not a date" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\nA :a, not a date, 7d\n", 1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[] links=[]
      #|error: semantic: Invalid date:not a date
    ),
  )
}

///|
test "rejects a task with no duration" {
  inspect(
    schedule("gantt\nA :crit\n", 1389873600000),
    content=(
      #|error: semantic: Task "A" needs a duration or an end date.
    ),
  )
}

///|
test "rejects a task with too many fields" {
  inspect(
    schedule("gantt\nA :a, 2024-01-01, 3d, extra\n", 1389873600000),
    content=(
      #|error: semantic: Task "A" has too many fields. A task takes an id, a start, and an end or duration.
    ),
  )
}

///|
test "reads tags, ids, sections and settings into the model" {
  inspect(
    schedule(
      "gantt\n dateFormat DD-MM-YYYY\n axisFormat %d\n tickInterval 1day\n excludes weekends 10-02-2025\n includes 15-02-2025\n weekend friday\n weekday tuesday\n inclusiveEndDates\n todayMarker off\n topAxis\n section S\n A :crit, done, a, 03-02-2025, 2d\n B :milestone, 0d\n V :vert, v, 04-02-2025, 0d\n C :active,crit , c, 03-02-2025, 1d\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="DD-MM-YYYY" axisFormat="%d" tickInterval=1day todayMarker="off" includes=[15-02-2025] excludes=[weekends,10-02-2025] inclusive=true topAxis=true weekday=tuesday weekend=friday sections=[S] links=[]
      #|a "A " [S] 1738540800000 1738713600000 1738713600000 order=0 manual=false processed=true flags=[done,crit] classes=[] prev=-
      #|task1 "B " [S] 1738713600000 1738713600000 null order=1 manual=false processed=true flags=[milestone] classes=[] prev=a
      #|v "V " [S] 1738627200000 1738627200000 null order=-1 manual=false processed=true flags=[vert] classes=[] prev=task1
      #|c "C " [S] 1738540800000 1738627200000 1738627200000 order=2 manual=false processed=true flags=[active,crit] classes=[] prev=v
    ),
  )
}

///|
test "treats Object.prototype names as ordinary ids" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\nA :__proto__, 2024-10-01, 3d\nB :constructor, after __proto__, 2d\nclick __proto__ href \"https://mermaid.js.org/\"\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[] links=[__proto__=https://mermaid.js.org/]
      #|__proto__ "A " [] 1727740800000 1728000000000 null order=0 manual=false processed=true flags=[] classes=[clickable] prev=-
      #|constructor "B " [] 1728000000000 1728172800000 null order=1 manual=false processed=true flags=[] classes=[] prev=__proto__
    ),
  )
}

///|
test "links and marks clickable tasks" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\nclick a href \"https://example.com\"\nA :a, 2014-01-07, 3d\nB :b, 2014-01-07, 3d\nclick a,b,zz href \"javascript:alert(1)\"\nclick b call f()\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[] links=[a=about:blank,b=about:blank]
      #|a "A " [] 1389052800000 1389312000000 null order=0 manual=false processed=true flags=[] classes=[clickable] prev=-
      #|b "B " [] 1389052800000 1389312000000 null order=1 manual=false processed=true flags=[] classes=[clickable,clickable] prev=a
    ),
  )
}

///|
test "reads timestamps in seconds and milliseconds" {
  inspect(
    schedule("gantt\ndateFormat X\nA :0, 71\nB :1000, 2000\n", 1389873600000),
    content=(
      #|settings: dateFormat="X" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[] links=[]
      #|task1 "A " [] 0 71000 null order=0 manual=false processed=true flags=[] classes=[] prev=-
      #|task2 "B " [] 1000 2000000 null order=1 manual=false processed=true flags=[] classes=[] prev=task1
    ),
  )
}

///|
test "reads a timestamp start as milliseconds" {
  inspect(
    schedule(
      "gantt\ndateFormat x\nA :1700000000000, 1d\nB :99999999999999999999, 1d\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="x" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[] links=[]
      #|error: semantic: Invalid date:99999999999999999999
    ),
  )
}

///|
test "schedules an empty date format with the JavaScript parser" {
  inspect(
    schedule(
      "gantt\napple :a, 2017-07-20, 1w\nbanana :crit, b, 2017-07-23, 1d\ncherry :active, c, after b a, 1d\nkiwi :d, 2017-07-20, until b c\n",
      1767225600000,
    ),
    content=(
      #|settings: dateFormat="" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[] links=[]
      #|a "apple " [] 1500508800000 1501113600000 null order=0 manual=false processed=true flags=[] classes=[] prev=-
      #|b "banana " [] 1500768000000 1500854400000 null order=1 manual=false processed=true flags=[crit] classes=[] prev=a
      #|c "cherry " [] 1501113600000 1501200000000 null order=2 manual=false processed=true flags=[active] classes=[] prev=b
      #|d "kiwi " [] 1500508800000 1500768000000 null order=3 manual=false processed=true flags=[] classes=[] prev=c
    ),
  )
}

///|
test "schedules hours and minutes on the current day" {
  inspect(
    schedule(
      "gantt\n    dateFormat HH:mm\n    axisFormat %H:%M\n    Initial milestone : milestone, m1, 17:49, 2m\n    Task A : 10m\n    Task B : 5m\n    Final milestone : milestone, m2, 18:08, 4m\n",
      1767225600000,
    ),
    content=(
      #|settings: dateFormat="HH:mm" axisFormat="%H:%M" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[] links=[]
      #|m1 "Initial milestone " [] 1767289740000 1767289860000 null order=0 manual=false processed=true flags=[milestone] classes=[] prev=-
      #|task1 "Task A " [] 1767289860000 1767290460000 null order=1 manual=false processed=true flags=[] classes=[] prev=m1
      #|task2 "Task B " [] 1767290460000 1767290760000 null order=2 manual=false processed=true flags=[] classes=[] prev=task1
      #|m2 "Final milestone " [] 1767290880000 1767291120000 null order=3 manual=false processed=true flags=[milestone] classes=[] prev=task2
    ),
  )
}

///|
test "keeps a zero-length span when the duration is invalid" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\nA :a, 2014-01-07, 0d\nB :b, 2014-01-07, bogus\nC :c, 2014-01-07, 1.5w\nD :d, 2014-01-07, 99999999y\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[] inclusive=false topAxis=false weekday=- weekend=saturday sections=[] links=[]
      #|warn: Gantt: "bogus" is neither a date in the "YYYY-MM-DD" format nor a duration such as "3d", so the task gets no duration.
      #|a "A " [] 1389052800000 1389052800000 null order=0 manual=false processed=true flags=[] classes=[] prev=-
      #|b "B " [] 1389052800000 1389052800000 null order=1 manual=false processed=true flags=[] classes=[] prev=a
      #|c "C " [] 1389052800000 1390003200000 null order=2 manual=false processed=true flags=[] classes=[] prev=b
      #|d "D " [] 1389052800000 1389052800000 null order=3 manual=false processed=true flags=[] classes=[] prev=c
    ),
  )
}

///|
test "stretches over excluded days of the week by name" {
  inspect(
    schedule(
      "gantt\ndateFormat YYYY-MM-DD\nexcludes sunday\nA :a, 2024-01-05, 3d\nB :b, 2024-01-05, 2024-01-10\n",
      1389873600000,
    ),
    content=(
      #|settings: dateFormat="YYYY-MM-DD" axisFormat="" tickInterval=- todayMarker="" includes=[] excludes=[sunday] inclusive=false topAxis=false weekday=- weekend=saturday sections=[] links=[]
      #|a "A " [] 1704412800000 1704758400000 1704758400000 order=0 manual=false processed=true flags=[] classes=[] prev=-
      #|b "B " [] 1704412800000 1704844800000 null order=1 manual=true processed=true flags=[] classes=[] prev=a
    ),
  )
}
