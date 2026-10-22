///|
/// A time period with the events that happened in it.
pub(all) struct TimelinePeriod {
  text : String
  events : Array[String]
  /// The name of the section in force when the period was declared, empty before the first one.
  section : String
  /// The index into `sections` of that section, -1 before the first one.
  section_index : Int32
}

///|
/// A timeline as its statements declare it.
pub struct TimelineDb {
  mut title : String?
  mut acc_title : String?
  mut acc_descr : String?
  /// "LR" or "TD".
  mut direction : String
  sections : Array[String]
  periods : Array[TimelinePeriod]
  mut current_section : String
}

///|
pub fn TimelineDb::new() -> TimelineDb {
  {
    title: None,
    acc_title: None,
    acc_descr: None,
    direction: "LR",
    sections: [],
    periods: [],
    current_section: "",
  }
}

///|
/// `direction` is "LR" or "TD".
pub fn TimelineDb::set_direction(self : TimelineDb, direction : String) -> Unit {
  self.direction = direction
}

///|
pub fn TimelineDb::set_acc_title(self : TimelineDb, text : String) -> Unit {
  self.acc_title = Some(text)
  self.title = None
}

///|
pub fn TimelineDb::set_acc_description(
  self : TimelineDb,
  text : String,
) -> Unit {
  self.acc_descr = Some(text)
}

///|
pub fn TimelineDb::add_section(self : TimelineDb, text : String) -> Unit {
  self.current_section = text
}

///|
pub fn TimelineDb::add_task(self : TimelineDb, period : String) -> Unit {
  ignore((self, period))
}

///|
/// Raises a semantic `PeleError` when no period has been declared, as Mermaid fails here too.
pub fn TimelineDb::add_event(
  self : TimelineDb,
  event : String,
) -> Unit raise @errors.PeleError {
  ignore((self, event))
  raise @errors.pele_error("not implemented")
}
