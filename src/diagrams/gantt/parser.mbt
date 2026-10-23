///|
/// The calls the grammar's actions make, under Mermaid's names.
pub(open) trait GanttBuilder {
  fn set_date_format(Self, String) -> Unit
  fn enable_inclusive_end_dates(Self) -> Unit
  fn top_axis(Self) -> Unit
  fn set_axis_format(Self, String) -> Unit
  fn set_tick_interval(Self, String) -> Unit
  fn set_excludes(Self, String) -> Unit
  fn set_includes(Self, String) -> Unit
  fn set_today_marker(Self, String) -> Unit
  fn set_weekday(Self, String) -> Unit
  fn set_weekend(Self, String) -> Unit
  fn set_diagram_title(Self, String) -> Unit
  fn set_acc_title(Self, String) -> Unit
  fn set_acc_description(Self, String) -> Unit
  fn add_section(Self, String) -> Unit
  fn add_task(Self, String, String) -> Unit raise @errors.PeleError
  fn set_click_event(Self, String, String, String?) -> Unit
  fn set_link(Self, String, String) -> Unit
}

///|
/// Parses a gantt chart into the builder, as Mermaid's grammar does.
pub fn[B : GanttBuilder] parse_gantt(
  src : String,
  db : B,
) -> Unit raise @errors.PeleError {
  db.add_task(src, "")
}
