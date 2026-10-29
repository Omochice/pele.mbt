// The expected calls and errors were taken from pele's gantt parser.

///|
/// Records the calls the parser makes, one per line.
struct Recorder {
  calls : Array[String]
}

///|
fn Recorder::log(self : Recorder, name : String, args : Array[String?]) -> Unit {
  let shown = args.map(arg => {
    match arg {
      Some(text) => quote(text)
      None => "null"
    }
  })
  self.calls.push("\{name}(\{shown.join(", ")})")
}

///|
impl @gantt.GanttBuilder for Recorder with fn set_date_format(self, txt) {
  self.log("setDateFormat", [Some(txt)])
}

///|
impl @gantt.GanttBuilder for Recorder with fn enable_inclusive_end_dates(self) {
  self.log("enableInclusiveEndDates", [])
}

///|
impl @gantt.GanttBuilder for Recorder with fn top_axis(self) {
  self.log("TopAxis", [])
}

///|
impl @gantt.GanttBuilder for Recorder with fn set_axis_format(self, txt) {
  self.log("setAxisFormat", [Some(txt)])
}

///|
impl @gantt.GanttBuilder for Recorder with fn set_tick_interval(self, txt) {
  self.log("setTickInterval", [Some(txt)])
}

///|
impl @gantt.GanttBuilder for Recorder with fn set_excludes(self, txt) {
  self.log("setExcludes", [Some(txt)])
}

///|
impl @gantt.GanttBuilder for Recorder with fn set_includes(self, txt) {
  self.log("setIncludes", [Some(txt)])
}

///|
impl @gantt.GanttBuilder for Recorder with fn set_today_marker(self, txt) {
  self.log("setTodayMarker", [Some(txt)])
}

///|
impl @gantt.GanttBuilder for Recorder with fn set_weekday(self, txt) {
  self.log("setWeekday", [Some(txt)])
}

///|
impl @gantt.GanttBuilder for Recorder with fn set_weekend(self, txt) {
  self.log("setWeekend", [Some(txt)])
}

///|
impl @gantt.GanttBuilder for Recorder with fn set_diagram_title(self, txt) {
  self.log("setDiagramTitle", [Some(txt)])
}

///|
impl @gantt.GanttBuilder for Recorder with fn set_acc_title(self, txt) {
  self.log("setAccTitle", [Some(txt)])
}

///|
impl @gantt.GanttBuilder for Recorder with fn set_acc_description(self, txt) {
  self.log("setAccDescription", [Some(txt)])
}

///|
impl @gantt.GanttBuilder for Recorder with fn add_section(self, txt) {
  self.log("addSection", [Some(txt)])
}

///|
impl @gantt.GanttBuilder for Recorder with fn add_task(self, descr, data) {
  self.log("addTask", [Some(descr), Some(data)])
}

///|
impl @gantt.GanttBuilder for Recorder with fn set_click_event(
  self,
  ids,
  name,
  args,
) {
  self.log("setClickEvent", [Some(ids), Some(name), args])
}

///|
impl @gantt.GanttBuilder for Recorder with fn set_link(self, ids, link) {
  self.log("setLink", [Some(ids), Some(link)])
}

///|
fn calls(source : String) -> String {
  let recorder = { calls: [], }
  @gantt.parse_gantt(source, recorder) catch {
    @errors.PeleError(failure) =>
      recorder.calls.push(
        "error: " +
        failure.message.split("\n").map(line => line.to_owned()).join(" / "),
      )
  }
  recorder.calls.join("\n")
}

///|
test "reads settings in any order" {
  inspect(
    calls(
      "gantt\ndateFormat yyyy-mm-dd\ninclusiveEndDates\ntopAxis\naxisFormat %Y-%m\ntickInterval 1week\nincludes 2024-01-01\nexcludes weekends 2019-02-01\ntodayMarker off\nweekday monday\nweekend friday\nweekend saturday\n",
    ),
    content=(
      #|setDateFormat("yyyy-mm-dd")
      #|enableInclusiveEndDates()
      #|TopAxis()
      #|setAxisFormat("%Y-%m")
      #|setTickInterval("1week")
      #|setIncludes("2024-01-01")
      #|setExcludes("weekends 2019-02-01")
      #|setTodayMarker("off")
      #|setWeekday("monday")
      #|setWeekend("friday")
      #|setWeekend("saturday")
    ),
  )
}

///|
test "reads titles, sections and tasks" {
  inspect(
    calls(
      "gantt\ntitle Adding gantt diagram functionality to mermaid\nsection Documentation\nDesign jison grammar:des1, 2014-01-01, 2014-01-04\nsection ;Semi\ntitle #Hash\n",
    ),
    content=(
      #|setDiagramTitle("Adding gantt diagram functionality to mermaid")
      #|addSection("Documentation")
      #|addTask("Design jison grammar", ":des1, 2014-01-01, 2014-01-04")
      #|addSection(";Semi")
      #|setDiagramTitle("#Hash")
    ),
  )
}

///|
test "reads accessibility text" {
  inspect(
    calls(
      "gantt\naccTitle: Plan  \naccDescr:  Tasks for Q4 \naccDescr {\n  multi\n  line\n}\n",
    ),
    content=(
      #|setAccTitle("Plan")
      #|setAccDescription("Tasks for Q4")
      #|setAccDescription("multi\n  line")
    ),
  )
}

///|
test "reads links and callbacks in either order" {
  inspect(
    calls(
      "gantt\nclick cl1 href \"https://example.com\"\nclick cl2 call printArguments(\"test1\", test3)\nclick cl3 call f()\nclick cl4 href \"x\" call g(1)\nclick cl5 call h(2) href \"y\"\nclick cl6 call k\n",
    ),
    content=(
      #|setLink("cl1", "https://example.com")
      #|setClickEvent("cl2", "printArguments", "\"test1\", test3")
      #|setClickEvent("cl3", "f", null)
      #|setClickEvent("cl4", "g", "1")
      #|setLink("cl4", "x")
      #|setClickEvent("cl5", "h", "2")
      #|setLink("cl5", "y")
      #|error: Parse error on line 7: / click cl6 call k / ----------------^ / Expecting 'EOF', 'SPACE', 'NL', 'weekday_monday', 'weekday_tuesday', 'weekday_wednesday', 'weekday_thursday', 'weekday_friday', 'weekday_saturday', 'weekday_sunday', 'weekend_friday', 'weekend_saturday', 'dateFormat', 'inclusiveEndDates', 'topAxis', 'axisFormat', 'tickInterval', 'excludes', 'includes', 'todayMarker', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'section', 'taskTxt', 'click', 'callbackargs', 'href', got 'callbackname'
    ),
  )
}

///|
test "needs gantt first" {
  inspect(
    calls("ganttTestClick\n"),
    content=(
      #|error: Parse error on line 1: / ganttTestClick / ^ / Expecting 'gantt', got 'taskTxt'
    ),
  )
}

///|
test "needs task data after a task" {
  inspect(
    calls("gantt\nweekday ${day}\n"),
    content=(
      #|error: Parse error on line 2: / weekday ${day} / --------------^ / Expecting 'taskData', got 'NL'
    ),
  )
}

///|
test "needs a newline between statements" {
  inspect(
    calls("gantt\ntitle A\n2024-01-01"),
    content=(
      #|setDiagramTitle("A")
      #|error: Parse error on line 3: / 2024-01-01 / ^ / Expecting 'EOF', 'SPACE', 'NL', 'weekday_monday', 'weekday_tuesday', 'weekday_wednesday', 'weekday_thursday', 'weekday_friday', 'weekday_saturday', 'weekday_sunday', 'weekend_friday', 'weekend_saturday', 'dateFormat', 'inclusiveEndDates', 'topAxis', 'axisFormat', 'tickInterval', 'excludes', 'includes', 'todayMarker', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'section', 'taskTxt', 'click', got 'date'
    ),
  )
}

///|
test "needs a link or callback after click" {
  inspect(
    calls("gantt\nclick a\n"),
    content=(
      #|error: Parse error on line 2: / click a / -------^ / Expecting 'callbackname', 'href', got 'EOF'
    ),
  )
}

///|
test "needs callback arguments or a link after a callback" {
  inspect(
    calls("gantt\nclick a call f\nB :1d"),
    content=(
      #|error: Parse error on line 3: / B :1d / -----^ / Expecting 'EOF', 'SPACE', 'NL', 'weekday_monday', 'weekday_tuesday', 'weekday_wednesday', 'weekday_thursday', 'weekday_friday', 'weekday_saturday', 'weekday_sunday', 'weekend_friday', 'weekend_saturday', 'dateFormat', 'inclusiveEndDates', 'topAxis', 'axisFormat', 'tickInterval', 'excludes', 'includes', 'todayMarker', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'section', 'taskTxt', 'click', 'callbackargs', 'href', got 'callbackname'
    ),
  )
}

///|
test "needs a callback after a link" {
  inspect(
    calls("gantt\nclick a href \"x\" B :1d"),
    content=(
      #|setLink("a", "x")
      #|addTask("B ", ":1d")
    ),
  )
}

///|
test "reports the end of input as 1" {
  inspect(
    calls("gantt\nA"),
    content=(
      #|error: Parse error on line 2: / A / -^ / Expecting 'taskData', got 'EOF'
    ),
  )
}

///|
test "stops at a directive" {
  inspect(
    calls("gantt\n%%{init: {}}%%\n"),
    content=(
      #|error: Parse error on line 2: / %%{init: {}}%% / ^ / Expecting 'EOF', 'SPACE', 'NL', 'weekday_monday', 'weekday_tuesday', 'weekday_wednesday', 'weekday_thursday', 'weekday_friday', 'weekday_saturday', 'weekday_sunday', 'weekend_friday', 'weekend_saturday', 'dateFormat', 'inclusiveEndDates', 'topAxis', 'axisFormat', 'tickInterval', 'excludes', 'includes', 'todayMarker', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'section', 'taskTxt', 'click', got 'open_directive'
    ),
  )
}

///|
test "rejects a task data colon alone" {
  inspect(
    calls("gantt\nA :\n"),
    content=(
      #|error: Parse error on line 2: / A : / --^ / Expecting 'taskData', got ':'
    ),
  )
}

///|
test "accepts an empty chart" {
  inspect(calls("gantt"), content="")
}

///|
test "accepts trailing input after EOF only at the end" {
  inspect(calls("gantt\n\n"), content="")
}

///|
test "reads a date at the start of a line as an error" {
  inspect(
    calls("gantt\n2024-01-01 :a\n"),
    content=(
      #|error: Parse error on line 2: / 2024-01-01 :a / ^ / Expecting 'EOF', 'SPACE', 'NL', 'weekday_monday', 'weekday_tuesday', 'weekday_wednesday', 'weekday_thursday', 'weekday_friday', 'weekday_saturday', 'weekday_sunday', 'weekend_friday', 'weekend_saturday', 'dateFormat', 'inclusiveEndDates', 'topAxis', 'axisFormat', 'tickInterval', 'excludes', 'includes', 'todayMarker', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'section', 'taskTxt', 'click', got 'date'
    ),
  )
}
