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
/// An empty journey whose title is `title`, the front matter title, until the source sets one.
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
  self.title = Some(text)
}

///|
pub fn JourneyDb::set_acc_title(self : JourneyDb, text : String) -> Unit {
  self.acc_title = Some(@util.trim_start(text))
}

///|
/// Does what `text.replace(/\n\s+/g, '\n')` does.
fn join_indented_lines(text : String) -> String {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    @util.write_range(out, text, i, i + 1)
    if @util.code_at(text, i) == '\n'.to_int() &&
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
pub fn JourneyDb::set_acc_description(self : JourneyDb, text : String) -> Unit {
  self.acc_descr = Some(join_indented_lines(text))
}

///|
pub fn JourneyDb::add_section(self : JourneyDb, text : String) -> Unit {
  self.current_section = text
  self.sections.push(text)
}

///|
/// Does what `names.split(',').map((name) => name.trim())` does, an empty text included, which gives one empty name.
fn split_names(names : String) -> Array[String] {
  let out = []
  let mut from = 0
  while true {
    let at = @util.index_of(names, ",", from~)
    if at == -1 {
      out.push(@util.trim(@util.slice(names, from)))
      break
    }
    out.push(@util.trim(@util.slice(names, from, end=at)))
    from = at + 1
  }
  out
}

///|
/// Adds a task.`data` is the rest of the line from its first colon: `:score` or `:score:actor, actor`.
/// Anything after a second colon is dropped, as Mermaid does.
pub fn JourneyDb::add_task(
  self : JourneyDb,
  task : String,
  data : String,
) -> Unit {
  let rest = @util.slice(data, 1)
  let first = @util.index_of(rest, ":")
  let people = if first == -1 {
    []
  } else {
    let after = @util.slice(rest, first + 1)
    let second = @util.index_of(after, ":")
    let names = if second == -1 {
      after
    } else {
      @util.slice(after, 0, end=second)
    }
    split_names(names)
  }
  let score = @util.to_number(
    if first == -1 {
      rest
    } else {
      @util.slice(rest, 0, end=first)
    },
  )
  self.tasks.push({ task, score, people, section: self.current_section, })
}

///|
fn compare_code_units(a : String, b : String) -> Int32 {
  let n = if a.length() < b.length() { a.length() } else { b.length() }
  for i in 0..<n {
    let x = @util.code_at(a, i)
    let y = @util.code_at(b, i)
    if x != y {
      return x - y
    }
  }
  a.length() - b.length()
}

///|
/// Everyone named on a task, once each, in code unit order.
pub fn journey_actors(tasks : Array[JourneyTask]) -> Array[String] {
  let seen : Set[String] = Set([])
  let names = []
  for task in tasks {
    for name in task.people {
      if !seen.contains(name) {
        seen.add(name)
        names.push(name)
      }
    }
  }
  names.sort_by(compare_code_units)
  names
}
