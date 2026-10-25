// Ported from Mermaid's gantt.spec.js as pele runs it (tests/compat/gantt/gantt.spec.js).

///|
fn parses(source : String) -> Bool {
  try {
    @gantt.GanttDb::from_source(source) |> ignore
    true
  } catch {
    _ => false
  }
}

///|
fn model(source : String) -> @gantt.GanttDb {
  @gantt.GanttDb::from_source(source) catch {
    _ => abort("the chart does not parse")
  }
}

///|
fn scheduled_tasks(source : String) -> Array[@gantt.GanttTask] {
  model(source).get_tasks(0) catch {
    _ => abort("the chart does not schedule")
  }
}

///|
fn at_day(year : Double, month : Double, day : Double) -> String {
  @date.JsDate::from_local(year, month, day~).time.to_string()
}

///|
fn span_of(task : @gantt.GanttTask) -> String {
  time_of(task.start_time) + " " + time_of(task.end_time)
}

///|
test "handles settings, titles, excludes and sections" {
  let head = "gantt\ndateFormat yyyy-mm-dd\n"
  let title = "title Adding gantt diagram functionality to mermaid\n"
  for
    source in [
      head,
      head + "inclusiveEndDates",
      head + title,
      head + "title ;Gantt diagram titles support semicolons",
      head + "title #Gantt diagram titles support hashtags",
      head + title + "excludes weekdays 2019-02-01",
      head + title + "excludes weekdays 2019-02-01\nsection Documentation",
      head + title + "excludes weekdays 2019-02-01\nsection ;Documentation",
      head + title + "excludes weekdays 2019-02-01\nsection #Documentation",
      head +
      title +
      "excludes weekdays 2019-02-01\nsection Line1<br>Line2<br/>Line3</br />Line4<br\t/>Line5",
    ] {
    assert_true(parses(source))
  }
}

///|
test "concatenates tokens across multiple excludes lines (issue #6270)" {
  let db = model(
    [
      "gantt", "dateFormat DD-MM-YYYY", "excludes weekends", "%% week 7 is winter break",
      "excludes 10-02-2025 11-02-2025 12-02-2025", "%% workers holiday 1 maj", "excludes 01-05-2025",
    ].join("\n"),
  )
  inspect(
    db.excludes.join(" "),
    content="weekends 10-02-2025 11-02-2025 12-02-2025 01-05-2025",
  )
}

///|
test "handles a todayMarker definition" {
  let db = model(
    "gantt\ndateFormat yyyy-mm-dd\ntitle Adding gantt diagram functionality to mermaid\nexcludes weekdays 2019-02-01\ntodayMarker off",
  )
  inspect(db.today_marker, content="off")
}

///|
test "handles a task definition, after a semicolon or a hash too" {
  let head = "gantt\ndateFormat YYYY-MM-DD\ntitle Adding gantt diagram functionality to mermaid\nsection Documentation\n"
  let task = "Design jison grammar:des1, 2014-01-01, 2014-01-04"
  assert_true(parses(head + ";" + task))
  assert_true(parses(head + "#" + task))
  let tasks = scheduled_tasks(head + task)
  inspect(
    span_of(tasks[0]) == at_day(2014, 0, 1) + " " + at_day(2014, 0, 4),
    content="true",
  )
  inspect(tasks[0].id, content="des1")
  inspect(tasks[0].task, content="Design jison grammar")
}

///|
test "handles a task with start and end relative to other tasks" {
  let tasks = scheduled_tasks(
    "gantt\ndateFormat YYYY-MM-DD\ntitle Adding gantt diagram functionality to mermaid\nsection Documentation\n" +
    "task A: a, 2024-01-27, 2024-01-28\ntask B: b, after a, 2024-01-30\ntask C: c, 2024-01-20, until a\ntask D: d, after c, until b",
  )
  let expected = [
    ("a", "task A", at_day(2024, 0, 27), at_day(2024, 0, 28)),
    ("b", "task B", at_day(2024, 0, 28), at_day(2024, 0, 30)),
    ("c", "task C", at_day(2024, 0, 20), at_day(2024, 0, 27)),
    ("d", "task D", at_day(2024, 0, 27), at_day(2024, 0, 28)),
  ]
  for i, entry in expected {
    let (id, name, start, end) = entry
    assert_eq(tasks[i].id, id)
    assert_eq(tasks[i].task, name)
    assert_eq(span_of(tasks[i]), start + " " + end)
  }
}

///|
test "handles a task with tags" {
  let cases = [
    ("milestone", "milestone"),
    ("done", "done"),
    ("crit", "crit"),
    ("active", "active"),
    ("crit,milestone,done", "milestone done crit"),
  ]
  for case in cases {
    let task = scheduled_tasks(
        "gantt\ndateFormat YYYY-MM-DD\ntitle Adding gantt diagram functionality to mermaid\nsection Documentation\ntest task:" +
        case.0 +
        ", 2014-01-01, 2014-01-04",
      )[0]
    let set = []
    if task.milestone {
      set.push("milestone")
    }
    if task.done {
      set.push("done")
    }
    if task.crit {
      set.push("crit")
    }
    if task.active {
      set.push("active")
    }
    assert_eq(set.join(" "), case.1)
  }
}

///|
test "parses callback specifiers with no args and with any number of args" {
  let head = "gantt\ndateFormat  YYYY-MM-DD\nsection Clickable\nVisit mermaidjs           :active, cl1, 2014-01-07, 3d\nCalling a callback        :cl2, after cl1, 3d\n\nclick cl1 href \"https://mermaidjs.github.io/\"\n"
  inspect(
    calls(head + "click cl2 call ganttTestClick()\n").contains(
      "setClickEvent(\"cl2\", \"ganttTestClick\", null)",
    ),
    content="true",
  )
  inspect(
    calls(head + "click cl2 call ganttTestClick(\"test0\", test1, test2)\n").contains(
      "setClickEvent(\"cl2\", \"ganttTestClick\", \"\\\"test0\\\", test1, test2\")",
    ),
    content="true",
  )
}

///|
test "allows an accessibility title and description" {
  let db = model(
    "gantt\n       accTitle: Gantt Diagram\n       accDescr: Tasks for Q4\n       dateFormat  YYYY-MM-DD\n       section Section\n       A task :a1, 2014-01-01, 30d\n",
  )
  inspect(db.acc_title.unwrap_or(""), content="Gantt Diagram")
  inspect(db.acc_descr.unwrap_or(""), content="Tasks for Q4")
}

///|
test "allows an accessibility title and a multiline description" {
  let db = model(
    "gantt\n       accTitle: Gantt Diagram\n       accDescr {\n         Tasks for Q4 row1\nrow2\n       }\n       dateFormat  YYYY-MM-DD\n       section Section\n       A task :a1, 2014-01-01, 30d\n",
  )
  inspect(db.acc_title.unwrap_or(""), content="Gantt Diagram")
  inspect(
    db.acc_descr.unwrap_or(""),
    content=(
      #|Tasks for Q4 row1
      #|row2
    ),
  )
}

///|
test "sets the weekday ticks start on" {
  for
    day in [
      "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
    ] {
    assert_eq(model("gantt\nweekday \{day}").weekday, Some(day))
  }
}

///|
test "allows a link to an id that is an object key in JavaScript" {
  for prop in ["__proto__", "constructor"] {
    assert_true(
      parses(
        "gantt\n    dateFormat YYYY-MM-DD\n    section Section\n    A task :\{prop}, 2024-10-01, 3d\n    click \{prop} href \"https://mermaid.js.org/\"\n    ",
      ),
    )
  }
}

///|
test "a task whose name runs into %% keeps it" {
  let tasks = scheduled_tasks(
    "gantt\ndateFormat YYYY-MM-DD\nA%% label : 2026-10-24, 1d",
  )
  inspect(tasks.map(task => task.task).join("|"), content="A%% label ")
}
