///|
fn dump_model(db : @timeline.TimelineDb) -> String {
  let periods = db.periods.map(p => {
    let events = p.events.map(e => e.escape()).join(",")
    "\{p.text.escape()}/\{events}/\{p.section.escape()}/\{p.section_index}"
  })
  let sections = db.sections.map(s => s.escape()).join(",")
  "sections=\{sections} periods=\{periods.join(";")}"
}

///|
test "a period belongs to the section declared before it" {
  let db = @timeline.TimelineDb::new()
  db.add_task("First")
  db.add_section("S")
  db.add_task("2001 ")
  db.add_section("T")
  db.add_task("2002")
  inspect(
    dump_model(db),
    content="sections=\"S\",\"T\" periods=\"First\"//\"\"/-1;\"2001 \"//\"S\"/0;\"2002\"//\"T\"/1",
  )
}

///|
test "a section declared twice is listed twice" {
  let db = @timeline.TimelineDb::new()
  db.add_section("Same")
  db.add_section("Same")
  db.add_task("B")
  inspect(
    dump_model(db),
    content="sections=\"Same\",\"Same\" periods=\"B\"//\"Same\"/1",
  )
}

///|
test "an event is added to the last period, even after a section header" {
  let db = @timeline.TimelineDb::new()
  db.add_task("2001 ")
  db.add_event("a ")
  db.add_section("S")
  db.add_event("b")
  inspect(
    dump_model(db),
    content="sections=\"S\" periods=\"2001 \"/\"a \",\"b\"/\"\"/-1",
  )
}

///|
test "an event with no period before it is a semantic error" {
  let db = @timeline.TimelineDb::new()
  let failure = try db.add_event("orphan") catch {
    @errors.PeleError(failure) => failure
  } noraise {
    _ => fail("no error")
  }
  inspect(failure.message, content="An event needs a time period before it.")
  assert_eq(failure.code.to_string(), "semantic")
  assert_eq(failure.kind, Some("timeline"))
}

///|
test "the accessible title loses leading whitespace and the description its indentation" {
  let db = @timeline.TimelineDb::new()
  db.set_acc_title("  \n Name")
  db.set_acc_description("A longer\n   description\n\t\n x")
  assert_eq(db.acc_title, Some("Name"))
  assert_eq(db.acc_descr, Some("A longer\ndescription\nx"))
}

///|
test "the direction defaults to LR and can be set" {
  let db = @timeline.TimelineDb::new()
  inspect(db.direction, content="LR")
  db.set_direction("TD")
  inspect(db.direction, content="TD")
}

///|
test "the character before a comment is kept" {
  let db = @timeline.TimelineDb::new()
  @timeline.parse_timeline("timeline\nA%% label : event\nB : e2", db) catch {
    _ => abort("the timeline does not parse")
  }
  inspect(
    dump_model(db),
    content=(
      #|sections= periods="A%% label "/"event"/""/-1;"B "/"e2"/""/-1
    ),
  )
  let failed = try {
    @core.render(
      [@timeline.timeline],
      "timeline\n  2024 :%% c\n",
      @types.RenderOptions::default(),
    )
    |> ignore
    ""
  } catch {
    @errors.PeleError(failure) => failure.message
  }
  assert_true(failed.contains("got 'INVALID'"))
}

///|
test "a bare title is no title" {
  let db = @timeline.TimelineDb::new()
  @timeline.parse_timeline("timeline\ntitle\n2024 : Event\n2025 : Next", db) catch {
    _ => abort("the timeline does not parse")
  }
  inspect(db.title.unwrap_or("-"), content="-")
  inspect(
    dump_model(db),
    content=(
      #|sections= periods="2024 "/"Event"/""/-1;"2025 "/"Next"/""/-1
    ),
  )
  let kept = @timeline.TimelineDb::new()
  @timeline.parse_timeline("timeline\n  title\u{a0}Kept\n  2024 : Event", kept) catch {
    _ => abort("the timeline does not parse")
  }
  inspect(kept.title.unwrap_or("-"), content="Kept")
}
