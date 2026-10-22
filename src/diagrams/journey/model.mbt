///|
/// A task as written in the source.
pub(all) struct JourneyTask {
  task : String
  /// As written: any number, or NaN when the score is not one.
  score : Double
  people : Array[String]
  /// Name of the section in force when the task was declared, "" before the first one.
  section : String
}

///|
/// The statements of a journey, collected as the parser reads them.
pub(all) struct JourneyDb {
  mut title : String?
  mut acc_title : String?
  mut acc_descr : String?
  sections : Array[String]
  tasks : Array[JourneyTask]
  mut current_section : String
}

///|
pub fn JourneyDb::new(title : String?) -> JourneyDb {
  {
    title,
    acc_title: None,
    acc_descr: None,
    sections: [],
    tasks: [],
    current_section: "",
  }
}

///|
pub fn JourneyDb::set_diagram_title(self : JourneyDb, text : String) -> Unit {
  ignore(self)
  ignore(text)
}

///|
pub fn JourneyDb::set_acc_title(self : JourneyDb, text : String) -> Unit {
  ignore(self)
  ignore(text)
}

///|
pub fn JourneyDb::set_acc_description(self : JourneyDb, text : String) -> Unit {
  ignore(self)
  ignore(text)
}

///|
pub fn JourneyDb::add_section(self : JourneyDb, text : String) -> Unit {
  ignore(self)
  ignore(text)
}

///|
pub fn JourneyDb::add_task(
  self : JourneyDb,
  task : String,
  data : String,
) -> Unit {
  ignore(self)
  ignore(task)
  ignore(data)
}

///|
/// Everyone named on a task, once each, in code unit order.
pub fn journey_actors(tasks : Array[JourneyTask]) -> Array[String] {
  ignore(tasks)
  []
}
