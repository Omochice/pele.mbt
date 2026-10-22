///|
fn optional(text : String?) -> String {
  match text {
    Some(text) => text.escape()
    None => "-"
  }
}

///|
fn quoted(texts : Array[String]) -> String {
  "[" + texts.map(text => text.escape()).join(", ") + "]"
}

///|
fn describe(task : @journey.JourneyTask) -> String {
  "\{task.task.escape()} score=\{task.score} people=\{quoted(task.people)} section=\{task.section.escape()}"
}

///|
test "tasks and actors are added in order, with actors sorted" {
  let db = @journey.JourneyDb::new(None)
  db.set_acc_title("Shopping")
  db.set_acc_description("A user journey for family shopping")
  db.add_section("Journey to the shops")
  db.add_task("Get car keys", ":5:Dad")
  db.add_task("Go to car", ":3:Dad, Mum, Child#1, Child#2")
  db.add_task("Drive to supermarket", ":4:Dad")
  db.add_section("Do shopping")
  db.add_task("Go shopping", ":5:Mum")
  inspect(optional(db.acc_title), content="\"Shopping\"")
  inspect(
    optional(db.acc_descr),
    content="\"A user journey for family shopping\"",
  )
  inspect(
    db.tasks.map(describe).join("\n"),
    content=(
      #|"Get car keys" score=5 people=["Dad"] section="Journey to the shops"
      #|"Go to car" score=3 people=["Dad", "Mum", "Child#1", "Child#2"] section="Journey to the shops"
      #|"Drive to supermarket" score=4 people=["Dad"] section="Journey to the shops"
      #|"Go shopping" score=5 people=["Mum"] section="Do shopping"
    ),
  )
  inspect(
    quoted(@journey.journey_actors(db.tasks)),
    content="[\"Child#1\", \"Child#2\", \"Dad\", \"Mum\"]",
  )
  inspect(
    quoted(db.sections),
    content="[\"Journey to the shops\", \"Do shopping\"]",
  )
}

///|
test "a task without actors, with an empty actor, and with a score that is not a number" {
  let db = @journey.JourneyDb::new(None)
  db.add_task("a", ":5")
  db.add_task("b", ":5:")
  db.add_task("c", ":x:")
  db.add_task("d", ": 3: , Real,")
  db.add_task("e", ":1:A:ignored")
  inspect(
    db.tasks.map(describe).join("\n"),
    content=(
      #|"a" score=5 people=[] section=""
      #|"b" score=5 people=[""] section=""
      #|"c" score=NaN people=[""] section=""
      #|"d" score=3 people=["", "Real", ""] section=""
      #|"e" score=1 people=["A"] section=""
    ),
  )
}

///|
test "an accessible title loses its leading blanks and a description its indentation" {
  let db = @journey.JourneyDb::new(None)
  db.set_acc_title("  \t The title ")
  db.set_acc_description("A longer\n    description\n\n  end")
  inspect(optional(db.acc_title), content="\"The title \"")
  inspect(optional(db.acc_descr), content="\"A longer\\ndescription\\nend\"")
}

///|
test "the actors of a journey are sorted by code unit" {
  let db = @journey.JourneyDb::new(None)
  db.add_task("t", ":3:b,B,a,\u{e9},\u{1f600},\u{ff5e},A")
  inspect(
    quoted(@journey.journey_actors(db.tasks)),
    content="[\"A\", \"B\", \"a\", \"b\", \"\u{e9}\", \"\u{1f600}\", \"\u{ff5e}\"]",
  )
}
