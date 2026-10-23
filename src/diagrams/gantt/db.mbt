///|
/// A task, under the names Mermaid gives its fields.
pub struct GanttTask {
  mut id : String
  /// The task's label.
  task : String
  section : String
  /// Unset until `get_tasks` has scheduled the task, and still unset when what it refers to never resolves.
  mut start_time : @date.JsDate?
  mut end_time : @date.JsDate?
  /// Where the bar ends when excluded days pushed the task's end out; None when the end was given as a date.
  mut render_end_time : @date.JsDate?
  mut manual_end_time : Bool
  mut processed : Bool
  mut active : Bool
  mut done : Bool
  mut crit : Bool
  mut milestone : Bool
  mut vert : Bool
  /// Row index in source order; -1 for vertical markers, which take no row.
  mut order : Int32
  classes : Array[String]
  prev_task_id : String?
  priv mut raw_start : String?
  priv mut raw_end : String
}

///|
/// A gantt chart's model, which schedules its tasks on request.
pub struct GanttDb {
  mut title : String?
  mut acc_title : String?
  mut acc_descr : String?
  mut date_format : String
  mut axis_format : String
  mut tick_interval : String?
  mut today_marker : String
  mut includes : Array[String]
  mut excludes : Array[String]
  mut inclusive_end_dates : Bool
  mut top_axis : Bool
  mut display_mode : String
  /// The day week-based ticks start on, when the chart names one.
  mut weekday : String?
  mut weekend : String
  sections : Array[String]
  links : Map[String, String]
  tasks : Array[GanttTask]
  priv warn : ((String) -> Unit)?
  priv by_id : Map[String, GanttTask]
  priv mut current_section : String
  priv mut task_count : Int32
  priv mut last_order : Int32
  priv mut last_task_id : String?
  priv mut now : Double
  priv mut work : Double
  priv mut include_set : Set[String]
  priv mut exclude_set : Set[String]
  priv mut excluded_days : Array[Bool]
  priv mut dated_tokens : Bool
}

///|
// Scheduling walks tasks day by day and parses dates with a format the diagram supplies.
// This bounds the total, in rough character operations, so a hostile diagram fails instead of hanging.
const WORK_LIMIT : Double = 4.0e8

///|
const DAY_STEP : Double = 400

///|
const DATED_STEP : Double = 200

///|
const FORMAT_STEP : Double = 400

///|
/// The time a chart is scheduled against: `now` when it is a finite number.
// pele falls back to the current time, which a plugin cannot read, so the epoch stands in for it.
pub fn clock(now : Double?) -> Double {
  match now {
    Some(time) if !time.is_nan() && !time.is_inf() => time
    _ => 0
  }
}

///|
/// An empty model; `warn` hears about references and durations that do not resolve.
pub fn GanttDb::new(warn? : (String) -> Unit) -> GanttDb {
  {
    title: None,
    acc_title: None,
    acc_descr: None,
    date_format: "",
    axis_format: "",
    tick_interval: None,
    today_marker: "",
    includes: [],
    excludes: [],
    inclusive_end_dates: false,
    top_axis: false,
    display_mode: "",
    weekday: None,
    weekend: "saturday",
    sections: [],
    links: {},
    tasks: [],
    warn,
    by_id: {},
    current_section: "",
    task_count: 0,
    last_order: 0,
    last_task_id: None,
    now: 0,
    work: 0,
    include_set: Set([]),
    exclude_set: Set([]),
    excluded_days: [],
    dated_tokens: false,
  }
}

///|
/// Parses a gantt chart into a new model.
pub fn GanttDb::from_source(
  source : String,
  warn? : (String) -> Unit,
) -> GanttDb raise @errors.PeleError {
  let db = GanttDb::new(warn?)
  parse_gantt(source, db)
  db
}

///|
fn semantic(message : String) -> @errors.PeleError {
  @errors.pele_error(message, code=Semantic, kind="gantt")
}

///|
fn is_token_separator(c : Int32) -> Bool {
  c == 44 || @util.is_space(c)
}

///|
/// Adds the tokens of `txt`, split at whitespace and commas, to `existing` without repeating any.
// JavaScript lowercases every script here; only ASCII letters are lowercased, which differs only for
// tokens that hold capitals of other scripts.
fn merge_tokens(existing : Array[String], txt : String) -> Array[String] {
  let merged = existing.copy()
  let seen = Set::from_array(existing)
  let lower = txt.to_lower()
  let mut i = 0
  let n = lower.length()
  while i < n {
    while i < n && is_token_separator(@util.code_at(lower, i)) {
      i += 1
    }
    let start = i
    while i < n && !is_token_separator(@util.code_at(lower, i)) {
      i += 1
    }
    if i > start {
      let token = @util.slice(lower, start, end=i)
      if !seen.contains(token) {
        seen.add(token)
        merged.push(token)
      }
    }
  }
  merged
}

///|
fn tag_of(field : String) -> String? {
  match @util.trim(field) {
    "active" | "done" | "crit" | "milestone" | "vert" as tag => Some(tag)
    _ => None
  }
}

///|
fn is_reference_char(c : Int32) -> Bool {
  is_word(c) || c == 45 || c == 32
}

///|
/// The ids after `keyword`, as `^keyword\s+([\d\w- ]+)` captures them, or None when it does not match.
fn reference_list(text : String, keyword : String) -> String? {
  if !text.has_prefix(keyword) {
    return None
  }
  let from = keyword.length()
  let spaces_end = skip_spaces(text, from)
  // The regular expression backtracks into the whitespace when what follows it is no id, which only
  // a space can then start.
  let mut start = spaces_end
  while start > from {
    if is_reference_char(@util.code_at(text, start)) {
      let mut end = start
      while is_reference_char(@util.code_at(text, end)) {
        end += 1
      }
      return Some(@util.slice(text, start, end~))
    }
    start -= 1
  }
  None
}

///|
fn is_digits(text : String) -> Bool {
  if text.length() == 0 {
    return false
  }
  for i in 0..<text.length() {
    if !@util.is_digit(@util.code_at(text, i)) {
      return false
    }
  }
  true
}

///|
fn time_or_nan(date : @date.JsDate?) -> Double {
  match date {
    Some(d) => d.time
    None => @double.not_a_number
  }
}

///|
/// Schedules the tasks against `now` and returns them.
/// Every call starts from scratch.
/// A task may refer to tasks defined after it, so, like Mermaid, this makes up to eleven passes, each of
/// which schedules every task again.
pub fn GanttDb::get_tasks(
  self : GanttDb,
  now : Double,
) -> Array[GanttTask] raise @errors.PeleError {
  self.now = clock(Some(now))
  self.work = 0
  self.include_set = Set::from_array(self.includes)
  self.exclude_set = Set::from_array(self.excludes)
  let weekend_start : Double = match self.weekend {
    "friday" => 5
    "saturday" => 6
    _ => @double.not_a_number
  }
  let weekends = self.exclude_set.contains("weekends")
  self.excluded_days = sunday_first.mapi((day, name) => {
    let iso = if day == 0 { 7.0 } else { day.to_double() }
    (weekends && (iso == weekend_start || iso == weekend_start + 1)) ||
    self.exclude_set.contains(name)
  })
  // A date written with only these tokens and separators can never read as a weekday name, so when
  // nothing else is excluded or included there is no need to format each day.
  self.dated_tokens = self.includes.length() > 0 ||
    !is_numeric_format(@util.trim(self.date_format))
  for token in self.excludes {
    if token != "weekends" && !sunday_first.contains(token) {
      self.dated_tokens = true
    }
  }
  for task in self.tasks {
    task.start_time = None
    task.end_time = None
    task.render_end_time = None
    task.processed = false
    task.manual_end_time = false
  }
  let mut all_processed = self.compile_tasks()
  let mut i = 0
  while !all_processed && i < 10 {
    all_processed = self.compile_tasks()
    i += 1
  }
  self.tasks
}

///|
/// Whether the format holds only `[YMDHhmsSZXx\-/.:, T]`.
fn is_numeric_format(template : String) -> Bool {
  for i in 0..<template.length() {
    match @util.code_at(template, i) {
      89
      | 77
      | 68
      | 72
      | 104
      | 109
      | 115
      | 83
      | 90
      | 88
      | 120
      | 45
      | 47
      | 46
      | 58
      | 44
      | 32
      | 84 => ()
      _ => return false
    }
  }
  true
}

///|
let sunday_first : Array[String] = [
  "sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday",
]

///|
/// Whether a day is excluded.
/// A day matches a token by its weekday name, by its date as YYYY-MM-DD, or by its date written in
/// the chart's own format.
pub fn GanttDb::is_invalid_date(
  self : GanttDb,
  date : @date.JsDate,
) -> Bool raise @errors.PeleError {
  let day = date.day()
  let weekday = !day.is_nan() && self.excluded_days[day.to_int()]
  if !self.dated_tokens {
    return weekday
  }
  let template = @util.trim(self.date_format)
  let date_only = iso_date(date)
  let mut formatted : String? = Some(date_only)
  self.spend(DATED_STEP)
  if template != "YYYY-MM-DD" {
    self.spend(FORMAT_STEP + template.length().to_double() * 8)
    formatted = format_date(date, template)
  }
  let listed = (set : Set[String]) => {
    set.contains(date_only) ||
    (match formatted {
      Some(text) => set.contains(text)
      None => false
    })
  }
  if listed(self.include_set) {
    return false
  }
  weekday || listed(self.exclude_set)
}

///|
fn GanttDb::spend(
  self : GanttDb,
  units : Double,
) -> Unit raise @errors.PeleError {
  self.work += units
  if self.work > WORK_LIMIT {
    raise @errors.pele_error(
      "The gantt chart takes too much work to schedule.",
      code=Limit,
      kind="gantt",
    )
  }
}

///|
fn GanttDb::parse(
  self : GanttDb,
  str : String,
  template : String,
) -> @date.JsDate? raise @errors.PeleError {
  self.spend(
    (template.length().to_double() + 1) * (str.length().to_double() + 1),
  )
  parse_strict(str, template, @date.JsDate::from_time(self.now))
}

///|
fn GanttDb::today(self : GanttDb) -> @date.JsDate {
  let today = @date.JsDate::from_time(self.now)
  today.set_hours(0, minutes=0, seconds=0, ms=0)
  today
}

///|
fn GanttDb::compile_tasks(self : GanttDb) -> Bool raise @errors.PeleError {
  let mut all_processed = true
  for task in self.tasks {
    self.compile_task(task)
    all_processed = all_processed && task.processed
  }
  all_processed
}

///|
fn GanttDb::compile_task(
  self : GanttDb,
  task : GanttTask,
) -> Unit raise @errors.PeleError {
  match task.raw_start {
    None => {
      // Mermaid fails with a TypeError when the first task has no start. It starts today here.
      let previous = match task.prev_task_id {
        Some(id) => self.by_id.get(id)
        None => None
      }
      task.start_time = match previous {
        Some(previous) => previous.end_time
        None => Some(self.today())
      }
    }
    Some(start) =>
      if self.get_start_date(start) is Some(start_time) {
        task.start_time = Some(start_time)
      }
  }
  guard task.start_time is Some(start_time) else { return }
  task.end_time = self.get_end_date(start_time, task.raw_end)
  if task.end_time is None {
    return
  }
  task.processed = true
  task.manual_end_time = self.parse(task.raw_end, "YYYY-MM-DD") is Some(_)
  self.check_task_dates(task)
}

///|
fn GanttDb::references(
  self : GanttDb,
  keyword : String,
  list : String,
) -> Array[GanttTask] {
  let found = []
  let unknown = []
  for part in list.split(" ") {
    let id = part.to_owned()
    if id == "" {
      continue
    }
    match self.by_id.get(id) {
      Some(task) => found.push(task)
      None => unknown.push(id)
    }
  }
  if unknown.length() > 0 && self.warn is Some(warn) {
    warn(
      "Gantt: \"\{keyword}\" refers to task ids that do not exist: \{unknown.join(", ")}.",
    )
  }
  found
}

///|
fn invalid_date(str : String) -> @errors.PeleError {
  semantic("Invalid date:" + str)
}

///|
fn GanttDb::get_start_date(
  self : GanttDb,
  raw : String,
) -> @date.JsDate? raise @errors.PeleError {
  let str = @util.trim(raw)
  let template = @util.trim(self.date_format)
  if (template == "x" || template == "X") && is_digits(str) {
    let date = @date.JsDate::from_time(@util.to_number(str))
    if date.time.is_nan() {
      raise invalid_date(str)
    }
    return Some(date)
  }
  if reference_list(str, "after") is Some(list) {
    let mut latest : GanttTask? = None
    for task in self.references("after", list) {
      match latest {
        None => latest = Some(task)
        Some(current) =>
          if time_or_nan(task.end_time) > time_or_nan(current.end_time) {
            latest = Some(task)
          }
      }
    }
    return match latest {
      Some(task) => task.end_time
      None => Some(self.today())
    }
  }
  if self.parse(str, template) is Some(parsed) {
    return Some(parsed)
  }
  // What does not fit the format gets a second chance with the JavaScript date parser, as in Mermaid.
  let date = @date.JsDate::from_time(@date.parse_date(str))
  let year = date.full_year()
  if date.time.is_nan() || year < -10000 || year > 10000 {
    raise invalid_date(str)
  }
  Some(date)
}

///|
fn GanttDb::get_end_date(
  self : GanttDb,
  start_time : @date.JsDate,
  raw : String,
) -> @date.JsDate? raise @errors.PeleError {
  let str = @util.trim(raw)
  if reference_list(str, "until") is Some(list) {
    let mut earliest : GanttTask? = None
    for task in self.references("until", list) {
      match earliest {
        None => earliest = Some(task)
        Some(current) =>
          if time_or_nan(task.start_time) < time_or_nan(current.start_time) {
            earliest = Some(task)
          }
      }
    }
    return match earliest {
      Some(task) => task.start_time
      None => Some(self.today())
    }
  }
  let template = @util.trim(self.date_format)
  if self.parse(str, template) is Some(parsed) {
    return Some(
      if self.inclusive_end_dates {
        add_days(parsed, 1)
      } else {
        parsed
      },
    )
  }
  let (value, unit) = parse_duration(str)
  if value.is_nan() {
    if self.warn is Some(warn) {
      warn(
        "Gantt: \"\{str}\" is neither a date in the \"\{template}\" format nor a duration such as \"3d\", so the task gets no duration.",
      )
    }
    return Some(start_time.copy())
  }
  let end = add_time(start_time, value, unit)
  Some(if end.time.is_nan() { start_time.copy() } else { end })
}

///|
/// Pushes the end of a task out by one day for every excluded day it covers.
fn GanttDb::check_task_dates(
  self : GanttDb,
  task : GanttTask,
) -> Unit raise @errors.PeleError {
  if self.excludes.length() == 0 || task.manual_end_time {
    return
  }
  guard task.start_time is Some(start_time) && task.end_time is Some(end) else {
    return
  }
  let cursor = add_days(start_time, 1)
  let end_time = end.copy()
  let max_end_time = add_days(end_time, 10000).time
  let mut invalid = false
  let mut render_end_time : Double? = None
  while cursor.time <= end_time.time {
    self.spend(DAY_STEP)
    if !invalid {
      render_end_time = Some(end_time.time)
    }
    invalid = self.is_invalid_date(cursor)
    if invalid {
      end_time.set_date(end_time.date() + 1)
      if end_time.time > max_end_time {
        raise semantic(
          "Failed to find a valid date that was not excluded by `excludes` after 10,000 iterations.",
        )
      }
    }
    cursor.set_date(cursor.date() + 1)
  }
  task.end_time = Some(end_time)
  task.render_end_time = render_end_time.map(@date.JsDate::from_time)
}

///|
fn GanttDb::set_class(
  self : GanttDb,
  ids : String,
  class_name : String,
) -> Unit {
  for id in ids.split(",") {
    if self.by_id.get(id.to_owned()) is Some(task) {
      task.classes.push(class_name)
    }
  }
}

///|
/// Drops the whitespace after each line break, as `replace(/\n\s+/g, '\n')`.
fn tighten_lines(text : String) -> String {
  let out = StringBuilder()
  let n = text.length()
  let mut i = 0
  while i < n {
    let c = @util.code_at(text, i)
    @util.write_range(out, text, i, i + 1)
    i += 1
    if c == 10 {
      i = skip_spaces(text, i)
    }
  }
  out.to_string()
}

///|
impl GanttBuilder for GanttDb with fn set_date_format(self, txt) {
  self.date_format = txt
}

///|
impl GanttBuilder for GanttDb with fn enable_inclusive_end_dates(self) {
  self.inclusive_end_dates = true
}

///|
/// Mermaid's grammar calls a method its database does not define, so `topAxis` crashes there.
impl GanttBuilder for GanttDb with fn top_axis(self) {
  self.top_axis = true
}

///|
impl GanttBuilder for GanttDb with fn set_axis_format(self, txt) {
  self.axis_format = txt
}

///|
impl GanttBuilder for GanttDb with fn set_tick_interval(self, txt) {
  self.tick_interval = Some(txt)
}

///|
impl GanttBuilder for GanttDb with fn set_excludes(self, txt) {
  self.excludes = merge_tokens(self.excludes, txt)
}

///|
impl GanttBuilder for GanttDb with fn set_includes(self, txt) {
  self.includes = merge_tokens(self.includes, txt)
}

///|
impl GanttBuilder for GanttDb with fn set_today_marker(self, txt) {
  self.today_marker = txt
}

///|
impl GanttBuilder for GanttDb with fn set_weekday(self, txt) {
  self.weekday = Some(txt)
}

///|
impl GanttBuilder for GanttDb with fn set_weekend(self, txt) {
  self.weekend = txt
}

///|
impl GanttBuilder for GanttDb with fn set_diagram_title(self, txt) {
  self.title = Some(txt)
}

///|
impl GanttBuilder for GanttDb with fn set_acc_title(self, txt) {
  self.acc_title = Some(@util.trim_start(txt))
}

///|
impl GanttBuilder for GanttDb with fn set_acc_description(self, txt) {
  self.acc_descr = Some(tighten_lines(txt))
}

///|
impl GanttBuilder for GanttDb with fn add_section(self, txt) {
  self.current_section = txt
  self.sections.push(txt)
}

///|
impl GanttBuilder for GanttDb with fn add_task(self, descr, data_str) {
  let body = if data_str.has_prefix(":") {
    @util.slice(data_str, 1)
  } else {
    data_str
  }
  let data = body.split(",").map(part => part.to_owned()).collect()
  let task : GanttTask = {
    id: "",
    task: descr,
    section: self.current_section,
    start_time: None,
    end_time: None,
    render_end_time: None,
    manual_end_time: false,
    processed: false,
    active: false,
    done: false,
    crit: false,
    milestone: false,
    vert: false,
    order: -1,
    classes: [],
    prev_task_id: self.last_task_id,
    raw_start: None,
    raw_end: "",
  }
  while data.length() > 0 && tag_of(data[0]) is Some(tag) {
    match tag {
      "active" => task.active = true
      "done" => task.done = true
      "crit" => task.crit = true
      "milestone" => task.milestone = true
      _ => task.vert = true
    }
    data.remove(0) |> ignore
  }
  // Mermaid fails with a TypeError on both of these.
  if data.length() == 0 {
    raise semantic(
      "Task \"\{@util.trim(descr)}\" needs a duration or an end date.",
    )
  }
  if data.length() > 3 {
    raise semantic(
      "Task \"\{@util.trim(descr)}\" has too many fields. A task takes an id, a start, and an end or duration.",
    )
  }
  let fields = data.map(@util.trim)
  if fields.length() == 3 {
    task.id = fields[0]
  } else {
    self.task_count += 1
    task.id = "task" + self.task_count.to_string()
  }
  if fields.length() > 1 {
    task.raw_start = Some(fields[fields.length() - 2])
  }
  task.raw_end = fields[fields.length() - 1]
  if !task.vert {
    task.order = self.last_order
    self.last_order += 1
  }
  self.tasks.push(task)
  self.last_task_id = Some(task.id)
  self.by_id[task.id] = task
}

///|
/// Callbacks are recognized and never run; the task is only marked clickable, as in Mermaid.
impl GanttBuilder for GanttDb with fn set_click_event(
  self,
  ids,
  function_name,
  function_args,
) {
  ignore((function_name, function_args))
  self.set_class(ids, "clickable")
}

///|
impl GanttBuilder for GanttDb with fn set_link(self, ids, link) {
  let href = @url.safe_url(link)
  for part in ids.split(",") {
    let id = part.to_owned()
    if self.by_id.contains(id) {
      self.links[id] = href
    }
  }
  self.set_class(ids, "clickable")
}
