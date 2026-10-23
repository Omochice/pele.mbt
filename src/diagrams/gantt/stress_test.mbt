// Ported from pele v1.8.0, tests/gantt/stress.test.ts and tests/render/gantt-security.test.ts.
// pele also bounds each worst case to three seconds; here each only has to finish.

///|
const N : Int32 = 50000

///|
const HEAD : String = "gantt\ndateFormat YYYY-MM-DD\n"

///|
/// 2024-01-15, the time pele's worst cases are scheduled against.
const BIG_NOW : Double = 1705276800000

///|
fn drawn(
  source : String,
  now~ : Double = BIG_NOW,
  limit~ : Double = 1.0 / 0.0,
) -> Result[@types.RenderResult, @errors.Failure] {
  let options = {
    ..@types.RenderOptions::default(),
    limit: Some(limit),
    now: Some(now),
  }
  Ok(@core.render([@gantt.gantt], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn repeat_lines(count : Int32, line : (Int32) -> String) -> String {
  let out = StringBuilder()
  for i in 0..<count {
    out.write_string(line(i))
  }
  out.to_string()
}

///|
fn finishes(outcome : Result[@types.RenderResult, @errors.Failure]) -> Bool {
  match outcome {
    Ok(result) => result.svg.length() > 0
    Err(_) => true
  }
}

///|
test "inputs that make a naive lexer rescan the text are read in one pass" {
  let sources = [
    "gantt\nweekday" + " ".repeat(N) + "x",
    "gantt\n" + "weekday\n\n\n".repeat(N / 10),
    "gantt\n" +
    "accTitle   ".repeat(N / 11) +
    "\n" +
    "accDescr \n ".repeat(2000),
    "gantt\naccDescr {" + " x\n".repeat(N / 3),
    "gantt\n" + "a%".repeat(N / 4) + "\n" + "%\n".repeat(N / 4),
    "gantt\n" + ":".repeat(N) + "\n" + ":;".repeat(N / 2),
    "gantt\n" +
    "click a call f(" +
    " ".repeat(N) +
    "\n" +
    "click a call ((".repeat(1000),
    "gantt\nclick a href \"" + "x ".repeat(N / 2),
    "gantt\n" + "dateFormat \ntitle \nsection \nexcludes \n".repeat(N / 40),
  ]
  for source in sources {
    inspect(@gantt.tokenize(source).types.length() > 0, content="true")
  }
}

///|
test "worst-case charts finish or fail with a pele error" {
  let sources = [
    HEAD + repeat_lines(8000, i => "T\{i} :2024-01-01, \{1 + i % 30}d\n"),
    HEAD +
    "A :t0, 2024-01-01, 1d\n" +
    repeat_lines(5000, i => "T :t\{i + 1}, after t\{i}, 1d\n"),
    HEAD +
    repeat_lines(3000, i => "T :t\{i}, after t\{i + 1}, 1d\n") +
    "Z :t3000, 2024-01-01, 1d\n",
    HEAD + "A :a, 2024-01-01, 1d\nB :b, after" + " a zz".repeat(6000) + ", 1d\n",
    HEAD + repeat_lines(500, _ => "T :after" + " q".repeat(30) + ", 1d\n"),
    HEAD + repeat_lines(5000, i => "section S\{i}\nT :2024-01-01, 2d\n"),
    "---\ndisplayMode: compact\n---\n" +
    HEAD +
    repeat_lines(6000, i => "T :2024-01-01, \{i + 1}d\n"),
    HEAD + "word ".repeat(N / 5) + ":2024-01-01, 2d\n",
    HEAD + "section " + "word ".repeat(N / 5) + "\nT :2024-01-01, 2d\n",
    HEAD + "title " + "#35;&amp;<br>".repeat(N / 13) + "\nT :2024-01-01, 2d\n",
    HEAD +
    "excludes weekends monday tuesday wednesday thursday friday\n" +
    repeat_lines(2000, _ => "T :2024-01-01, 7d\n"),
    HEAD +
    "excludes " +
    repeat_lines(4000, i => "2024-01-\{10 + i % 20} ") +
    "\n" +
    repeat_lines(300, _ => "T :2024-01-01, 3000d\n"),
    "gantt\ndateFormat DD.MM.YYYY [" +
    "x".repeat(2000) +
    "]\nexcludes 01.01.2024\n" +
    repeat_lines(500, _ => "T :2024-01-01, 20000d\n"),
    "gantt\ndateFormat " +
    "D ".repeat(12500) +
    "\n" +
    "T :" +
    "1 ".repeat(8000) +
    ", " +
    "2 ".repeat(4000) +
    "\n",
    "gantt\ndateFormat " +
    "D-".repeat(6000) +
    "\n" +
    repeat_lines(3, _ => "T :" + "x".repeat(8000) + "1, 3d\n"),
    HEAD +
    repeat_lines(2000, i => "T :t\{i}, after t\{i + 1}, \{"9".repeat(18)}\n"),
    HEAD + "excludes weekends\nT :2024-01-01, 99999999d\n",
    HEAD + "A :0001-01-01, 1d\nB :2024-01-01, 99990000d\n",
    HEAD + "tickInterval 1millisecond\nA :1950-01-01, 36500d\n",
    HEAD + "tickInterval 99999999second\nA :1950-01-01, 36500d\n",
    HEAD + "tickInterval 100000week\nA :0100-01-01, 99000000d\n",
    HEAD + "axisFormat " + "%c%j%U%V".repeat(3000) + "\nA :2024-01-01, 30d\n",
    HEAD +
    "todayMarker " +
    "stroke:red,".repeat(4500) +
    "\nA :2024-01-01, 30d\n",
    HEAD +
    repeat_lines(2000, i => "T :t\{i}, 2024-01-01, 2d\n") +
    repeat_lines(2000, i => "click t\{i} href \"https://example.com/\{i}\"\n"),
    HEAD + "T :t, 2024-01-01, 2d\nclick " + "t,".repeat(12000) + "t call f()\n",
  ]
  for source in sources {
    inspect(finishes(drawn(source)), content="true")
  }
}

///|
test "timestamps too large for a date fail as a pele error" {
  let outcome = try {
    let db = @gantt.GanttDb::from_source(
      "gantt\ndateFormat x\nA :" + "9".repeat(N) + ", 1d\n",
    )
    db.get_tasks(BIG_NOW) |> ignore
    "scheduled"
  } catch {
    @errors.PeleError(failure) => failure.message.length().to_string()
  }
  inspect(outcome, content="50013")
}

///|
test "refuses a schedule that would take too long, as a limit" {
  let source = HEAD +
    "excludes weekends\n" +
    repeat_lines(400, _ => "T :2024-01-01, 10950d\n")
  let code = match drawn(source) {
    Ok(_) => "drawn"
    Err(failure) => failure.code.to_string()
  }
  inspect(code, content="limit")
}

///|
/// FNV-1a over UTF-16 code units, the hash under which `hostile_outcomes` were taken from pele.
fn fnv1a(text : String) -> String {
  let mut h : UInt32 = 0x811c9dc5U
  for i in 0..<text.length() {
    h = (h ^ text.unsafe_get(i).to_int().reinterpret_as_uint()) * 0x01000193U
  }
  let digits = "0123456789abcdef"
  let out = StringBuilder()
  for shift in [28, 24, 20, 16, 12, 8, 4, 0] {
    let d = ((h >> shift) & 0xfU).reinterpret_as_int()
    out.write_char(digits.get_char(d).unwrap())
  }
  out.to_string()
}

///|
/// What rendering gives, written as the generator of `hostile_outcomes` writes pele's.
fn render_outcome(source : String) -> String {
  match drawn(source, now=1389873600000, limit=50000) {
    Ok(r) => {
      let links = r.links.map(l => "\{l.id}|\{l.href}|\{l.internal}").join(";")
      "ok \{r.width} \{r.height} \{links}\n\{r.svg}"
    }
    Err(failure) => "error \{failure.code.to_string()}\n\{failure.message}"
  }
}

///|
test "hostile text in every position is drawn as pele draws it" {
  let wrong = []
  let mut k = 0
  for t, pieces in hostile_templates {
    for p, payload in hostile_payloads {
      let source = pieces.join(payload)
      let actual = fnv1a(render_outcome(source))
      if actual != hostile_outcomes[k] {
        wrong.push("template \{t} payload \{p}")
      }
      k += 1
    }
  }
  inspect(k == hostile_outcomes.length(), content="true")
  inspect(wrong.join("\n"), content="")
}

///|
test "hostile times give no NaN or Infinity" {
  let tasks = "  section S\n  A task :a1, 2014-01-01, 30d\n  Another :after a1, 20d\n"
  let sources = [
    "gantt\n  dateFormat YYYY-MM-DD\n" + tasks,
    "gantt\n  dateFormat HH:mm\n  A :a, 17:49, 2m\n  B :after nothing, 3m\n  C :until nothing\n",
    "gantt\n  A :3d\n",
  ]
  for
    now in [
      @double.not_a_number, @double.infinity, @double.neg_infinity, 8.64e15, -8.64e15,
      0,
    ] {
    for source in sources {
      match drawn(source, now~) {
        Ok(r) => {
          inspect(r.svg.contains("NaN"), content="false")
          inspect(r.svg.contains("Infinity"), content="false")
        }
        Err(failure) =>
          inspect(failure.code is (Semantic | Limit), content="true")
      }
    }
  }
}

///|
test "never links to a script URL" {
  let tasks = "  section S\n  A task :a1, 2014-01-01, 30d\n  Another :after a1, 20d\n"
  for
    url in [
      "javascript:alert(1)", "JaVaScRiPt:alert(1)", " javascript:alert(1)", "data:text/html,x",
      "vbscript:x",
    ] {
    let result = drawn(
      "gantt\n  dateFormat YYYY-MM-DD\n" +
      tasks +
      "  click a1 href \"\{url}\"\n",
      now=1389873600000,
    ).unwrap()
    inspect(result.svg.contains("<a"), content="false")
    inspect(result.links.length(), content="0")
  }
}
