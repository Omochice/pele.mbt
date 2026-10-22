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
pub fn TimelineDb::set_diagram_title(self : TimelineDb, text : String) -> Unit {
  self.title = Some(text)
}

///|
pub fn TimelineDb::set_acc_title(self : TimelineDb, text : String) -> Unit {
  self.acc_title = Some(@util.trim_start(text))
}

///|
/// Does what `text.replace(/\n\s+/g, '\n')` does.
fn join_indented_lines(text : String) -> String {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    @util.write_range(out, text, i, i + 1)
    if @util.code_at(text, i) == '\n' &&
      @util.is_space(@util.code_at(text, i + 1)) {
      i += 1
      while @util.is_space(@util.code_at(text, i)) {
        i += 1
      }
    } else {
      i += 1
    }
  }
  out.to_string()
}

///|
pub fn TimelineDb::set_acc_description(
  self : TimelineDb,
  text : String,
) -> Unit {
  self.acc_descr = Some(join_indented_lines(text))
}

///|
pub fn TimelineDb::add_section(self : TimelineDb, text : String) -> Unit {
  self.current_section = text
  self.sections.push(text)
}

///|
pub fn TimelineDb::add_task(self : TimelineDb, period : String) -> Unit {
  self.periods.push({
    text: period,
    events: [],
    section: self.current_section,
    section_index: self.sections.length() - 1,
  })
}

///|
/// Raises a semantic `PeleError` when no period has been declared, as Mermaid fails here too.
pub fn TimelineDb::add_event(
  self : TimelineDb,
  event : String,
) -> Unit raise @errors.PeleError {
  guard self.periods.last() is Some(period) else {
    raise @errors.pele_error(
      "An event needs a time period before it.",
      code=Semantic,
      kind="timeline",
    )
  }
  period.events.push(event)
}
