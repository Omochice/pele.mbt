///|
fn read(source : String) -> String {
  let db = @journey.JourneyDb::new(None)
  // The renderer hands the parser its text with one more line break.
  @journey.parse_journey(source + "\n", db) catch {
    @errors.PeleError(failure) =>
      return "\{failure.code.to_string()}: \{failure.message}"
  }
  let tasks = db.tasks.map(t => {
    "\{t.task.escape()}:\{t.score}:\{t.people.map(p => p.escape()).join("|")}@\{t.section.escape()}"
  })
  "title=\{optional(db.title)} accTitle=\{optional(db.acc_title)} accDescr=\{optional(db.acc_descr)} sections=\{db.sections.map(s => s.escape()).join(",")} tasks=\{tasks.join(",")}"
}

///|
test "a title and a section are read" {
  inspect(
    read(
      "journey\ntitle Adding journey diagram functionality to mermaid\nsection Order from website",
    ),
    content="title=\"Adding journey diagram functionality to mermaid\" accTitle=- accDescr=- sections=\"Order from website\" tasks=",
  )
}

///|
test "accessibility statements are read" {
  inspect(
    read(
      "journey\naccDescr: A user journey for family shopping\ntitle T\nsection S",
    ),
    content="title=\"T\" accTitle=- accDescr=\"A user journey for family shopping\" sections=\"S\" tasks=",
  )
  inspect(
    read(
      "journey\naccDescr {\n        A user journey for\n        family shopping\n      }title T\naccTitle: Adding acc journey\nsection S",
    ),
    content="title=\"T\" accTitle=\"Adding acc journey\" accDescr=\"A user journey for\\nfamily shopping\" sections=\"S\" tasks=",
  )
  inspect(
    read("journey\n    accTitle: The title\n    section Order from website"),
    content="title=- accTitle=\"The title\" accDescr=- sections=\"Order from website\" tasks=",
  )
}

///|
test "a section name may hold line breaks written as tags" {
  inspect(
    read("journey\nsection Line1<br>Line2<br/>Line3</br />Line4<br\t/>Line5"),
    content="title=- accTitle=- accDescr=- sections=\"Line1<br>Line2<br/>Line3</br />Line4<br\\t/>Line5\" tasks=",
  )
}

///|
test "tasks keep their score, actors and section" {
  inspect(
    read(
      "journey\ntitle T\nsection Documentation\nA task: 5: Alice, Bob, Charlie\nB task: 3:Bob, Charlie\nC task: 5\nD task: 5: Charlie, Alice\nE task: 5:\nsection Another section\nP task: 5:\nR task: 5:",
    ),
    content="title=\"T\" accTitle=- accDescr=- sections=\"Documentation\",\"Another section\" tasks=\"A task\":5:\"Alice\"|\"Bob\"|\"Charlie\"@\"Documentation\",\"B task\":3:\"Bob\"|\"Charlie\"@\"Documentation\",\"C task\":5:@\"Documentation\",\"D task\":5:\"Charlie\"|\"Alice\"@\"Documentation\",\"E task\":5:\"\"@\"Documentation\",\"P task\":5:\"\"@\"Another section\",\"R task\":5:\"\"@\"Another section\"",
  )
}

///|
test "comments, blank lines and a task before any section" {
  inspect(
    read("journey\n%% a comment\n\n  First: 2 # trailing\n# note\n"),
    content="title=- accTitle=- accDescr=- sections= tasks=\"First\":2:@\"\"",
  )
}

///|
test "a keyword needs a space after it, and a bare one is a task name" {
  inspect(
    read("journey\ntitle\nsection\n"),
    content="title=\"section\" accTitle=- accDescr=- sections= tasks=",
  )
  inspect(
    read("journey\ntitles: 3\n"),
    content="title=- accTitle=- accDescr=- sections= tasks=\"titles\":3:@\"\"",
  )
}

///|
test "Mermaid's errors are reproduced" {
  inspect(
    read("journey\n  A task\n"),
    content="syntax: Parse error on line 2:\n  A task\n--------^\nExpecting 'taskData', got 'NEWLINE'",
  )
  inspect(
    read("journey\n  A task:\n"),
    content="syntax: Parse error on line 2:\n  A task:\n--------^\nExpecting 'taskData', got ':'",
  )
  inspect(
    read("journey\n  A; B: 3\n"),
    content="syntax: Parse error on line 2:\n  A; B: 3\n---^\nExpecting 'taskData', got 'INVALID'",
  )
  inspect(
    read("journey\n  : 5\n"),
    content="syntax: Parse error on line 2:\n  : 5\n--^\nExpecting 'EOF', 'SPACE', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'section', 'taskName', got 'taskData'",
  )
}

///|
test "a text that does not start with journey is rejected" {
  inspect(
    read("pie\n"),
    content="syntax: Parse error on line 1:\npie\n^\nExpecting 'journey', got 'taskName'",
  )
}

///|
test "an accDescr block that is never closed ends the input early" {
  inspect(
    read("journey\n  accDescr {\n  never closed\n"),
    content="syntax: Parse error on line 5:\n\n^\nExpecting 'EOF', 'SPACE', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'section', 'taskName', got '1'",
  )
}

///|
test "the character before a comment is kept" {
  inspect(
    read("journey\nA%% label: 5: Me"),
    content=(
      #|title=- accTitle=- accDescr=- sections= tasks="A%% label":5:"Me"@""
    ),
  )
}
