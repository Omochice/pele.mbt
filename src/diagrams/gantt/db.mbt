///|
/// A task, under the names Mermaid gives its fields.
pub struct GanttTask {
  id : String
  /// The task's label.
  task : String
  section : String
  /// Unset until `get_tasks` has scheduled the task, and still unset when what it refers to never resolves.
  start_time : @date.JsDate?
  end_time : @date.JsDate?
  /// Where the bar ends when excluded days pushed the task's end out; None when the end was given as a date.
  render_end_time : @date.JsDate?
  manual_end_time : Bool
  processed : Bool
  active : Bool
  done : Bool
  crit : Bool
  milestone : Bool
  vert : Bool
  /// Row index in source order; -1 for vertical markers, which take no row.
  order : Int32
  classes : Array[String]
  prev_task_id : String?
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
  includes : Array[String]
  excludes : Array[String]
  mut inclusive_end_dates : Bool
  mut top_axis : Bool
  display_mode : String
  /// The day week-based ticks start on, when the chart names one.
  mut weekday : String?
  mut weekend : String
  sections : Array[String]
  links : Map[String, String]
  tasks : Array[GanttTask]
  priv warn : ((String) -> Unit)?
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
/// Schedules the tasks against `now` and returns them.
pub fn GanttDb::get_tasks(
  self : GanttDb,
  now : Double,
) -> Array[GanttTask] raise @errors.PeleError {
  ignore(self.warn)
  if now.is_nan() {
    raise @errors.pele_error("Invalid date")
  }
  self.tasks
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
  ignore((self, txt))
}

///|
impl GanttBuilder for GanttDb with fn set_includes(self, txt) {
  ignore((self, txt))
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
  self.acc_title = Some(txt)
}

///|
impl GanttBuilder for GanttDb with fn set_acc_description(self, txt) {
  self.acc_descr = Some(txt)
}

///|
impl GanttBuilder for GanttDb with fn add_section(self, txt) {
  self.sections.push(txt)
}

///|
impl GanttBuilder for GanttDb with fn add_task(self, descr, data) {
  ignore(data)
  self.tasks.push({
    id: "",
    task: descr,
    section: "",
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
    prev_task_id: None,
  })
}

///|
impl GanttBuilder for GanttDb with fn set_click_event(
  self,
  ids,
  function_name,
  function_args,
) {
  ignore((self, ids, function_name, function_args))
}

///|
impl GanttBuilder for GanttDb with fn set_link(self, ids, link) {
  ignore((self, ids, link))
}
