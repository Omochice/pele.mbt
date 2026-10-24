///|
fn optional(value : String?) -> String {
  match value {
    Some(text) => text.escape()
    None => "undefined"
  }
}

///|
/// The model a text parses to, or its error, as one line.
fn parse_dump(src : String) -> String {
  let db = @timeline.TimelineDb::new()
  @timeline.parse_timeline(src, db) catch {
    @errors.PeleError(failure) =>
      return "ERROR \{failure.code.to_string()} \{failure.message.escape()}"
  }
  let periods = db.periods.map(p => {
    let events = p.events.map(e => e.escape()).join(",")
    "\{p.text.escape()}/\{events}/\{p.section.escape()}/\{p.section_index}"
  })
  let sections = db.sections.map(s => s.escape()).join(",")
  "dir=\{db.direction} title=\{optional(db.title)} accTitle=\{optional(db.acc_title)} accDescr=\{optional(db.acc_descr)} sections=\{sections} periods=\{periods.join(";")}"
}

///|
test "the direction defaults to LR and takes TD or LR" {
  inspect(
    parse_dump("timeline\n    section abc-123"),
    content="dir=LR title=undefined accTitle=undefined accDescr=undefined sections=\"abc-123\" periods=",
  )
  inspect(
    parse_dump("timeline TD\n    section abc-123"),
    content="dir=TD title=undefined accTitle=undefined accDescr=undefined sections=\"abc-123\" periods=",
  )
  inspect(
    parse_dump("timeline LR\n    section abc-123"),
    content="dir=LR title=undefined accTitle=undefined accDescr=undefined sections=\"abc-123\" periods=",
  )
}

///|
test "periods belong to the section declared before them" {
  inspect(
    parse_dump(
      "timeline\n    section abc-123\n    task1\n    task2\n    section abc-456\n    task3\n    task4",
    ),
    content="dir=LR title=undefined accTitle=undefined accDescr=undefined sections=\"abc-123\",\"abc-456\" periods=\"task1\"//\"abc-123\"/0;\"task2\"//\"abc-123\"/0;\"task3\"//\"abc-456\"/1;\"task4\"//\"abc-456\"/1",
  )
}

///|
test "events follow their period after colons, on one line or continued on the next" {
  inspect(
    parse_dump(
      "timeline\n    section abc-123\n      task1: event1\n      task2: event2: event3\n   ",
    ),
    content="dir=LR title=undefined accTitle=undefined accDescr=undefined sections=\"abc-123\" periods=\"task1\"/\"event1\"/\"abc-123\"/0;\"task2\"/\"event2\",\"event3\"/\"abc-123\"/0",
  )
  inspect(
    parse_dump(
      "timeline\n    section abc-123\n      task1: [event1](http://example.com)\n      task2: event2: event3\n   ",
    ),
    content="dir=LR title=undefined accTitle=undefined accDescr=undefined sections=\"abc-123\" periods=\"task1\"/\"[event1](http://example.com)\"/\"abc-123\"/0;\"task2\"/\"event2\",\"event3\"/\"abc-123\"/0",
  )
  inspect(
    parse_dump(
      "timeline\n    section abc-123\n      task1: event1\n      task2: event2: event3\n           : event4: event5\n   ",
    ),
    content="dir=LR title=undefined accTitle=undefined accDescr=undefined sections=\"abc-123\" periods=\"task1\"/\"event1\"/\"abc-123\"/0;\"task2\"/\"event2\",\"event3\",\"event4\",\"event5\"/\"abc-123\"/0",
  )
}

///|
test "semicolons and hashes in text, and trailing spaces, are kept as Mermaid keeps them" {
  inspect(
    parse_dump(
      "timeline\n      title ;my;title;\n      section ;a;bc-123;\n      ;ta;sk1;: ;ev;ent1; : ;ev;ent2; : ;ev;ent3;\n   ",
    ),
    content="dir=LR title=\";my;title;\" accTitle=undefined accDescr=undefined sections=\";a;bc-123;\" periods=\";ta;sk1;\"/\";ev;ent1; \",\";ev;ent2; \",\";ev;ent3;\"/\";a;bc-123;\"/0",
  )
  inspect(
    parse_dump(
      "timeline\n      title #my#title#\n      section #a#bc-123#\n      task1: #ev#ent1# : #ev#ent2# : #ev#ent3#\n   ",
    ),
    content="dir=LR title=\"#my#title#\" accTitle=undefined accDescr=undefined sections=\"#a#bc-123#\" periods=\"task1\"/\"#ev#ent1# \",\"#ev#ent2# \",\"#ev#ent3#\"/\"#a#bc-123#\"/0",
  )
}

///|
test "accessible names are trimmed, and a description block loses its indentation" {
  inspect(
    parse_dump(
      "timeline\n  accTitle: Short name\n  accDescr {\n    A longer\n    description\n  }\n  2001\n",
    ),
    content="dir=LR title=undefined accTitle=\"Short name\" accDescr=\"A longer\\ndescription\" sections= periods=\"2001\"//\"\"/-1",
  )
  inspect(
    parse_dump("timeline\n  accTitle:   x  \n  accDescr:   y  \n"),
    content="dir=LR title=undefined accTitle=\"x\" accDescr=\"y\" sections= periods=",
  )
}

///|
test "an event after a section header attaches to the last period, and a title may be on the next line" {
  inspect(
    parse_dump("timeline\n  2001 : a\n  section S\n  : b\n"),
    content="dir=LR title=undefined accTitle=undefined accDescr=undefined sections=\"S\" periods=\"2001 \"/\"a\",\"b\"/\"\"/-1",
  )
  inspect(
    parse_dump(
      "timeline TD\n  title T\n  First\n  section S\n    2001 : a : b\n    2002\n",
    ),
    content="dir=TD title=\"T\" accTitle=undefined accDescr=undefined sections=\"S\" periods=\"First\"//\"\"/-1;\"2001 \"/\"a \",\"b\"/\"S\"/0;\"2002\"//\"S\"/0",
  )
  inspect(
    parse_dump("timeline\ntitle\nx"),
    content="dir=LR title=\"x\" accTitle=undefined accDescr=undefined sections= periods=",
  )
  inspect(
    parse_dump("timeline\ntitle"),
    content="dir=LR title=undefined accTitle=undefined accDescr=undefined sections= periods=\"title\"//\"\"/-1",
  )
}

///|
test "text after the keyword is a period, and the keyword must be followed by a word boundary" {
  inspect(
    parse_dump("timeline x"),
    content="dir=LR title=undefined accTitle=undefined accDescr=undefined sections= periods=\"x\"//\"\"/-1",
  )
  inspect(
    parse_dump("timeline TD x"),
    content="dir=TD title=undefined accTitle=undefined accDescr=undefined sections= periods=\"x\"//\"\"/-1",
  )
  inspect(
    parse_dump("timelinex"),
    content="ERROR syntax \"Parse error on line 1:\\ntimelinex\\n^\\nExpecting 'timeline', 'timeline_lr', 'timeline_td', got 'period'\"",
  )
}

///|
test "what Mermaid rejects is rejected with its message" {
  inspect(
    parse_dump("timeline\n  : orphan event\n"),
    content="ERROR semantic \"An event needs a time period before it.\"",
  )
  inspect(
    parse_dump("timeline\n  2001 :no space\n"),
    content="ERROR syntax \"Parse error on line 2:\\n  2001 :no space\\n-------^\\nExpecting 'EOF', 'SPACE', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'section', 'period', 'event', got 'INVALID'\"",
  )
  inspect(
    parse_dump("timeline\n  Timeline of things : x\n"),
    content="ERROR syntax \"Parse error on line 2:\\n  Timeline of things : x\\n--^\\nExpecting 'EOF', 'SPACE', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'section', 'period', 'event', got 'timeline'\"",
  )
  inspect(
    parse_dump("timeline\n  accDescr {\n  never closed\n"),
    content="ERROR syntax \"Parse error on line 4:\\n\\n^\\nExpecting 'EOF', 'SPACE', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'section', 'period', 'event', got '1'\"",
  )
  inspect(
    parse_dump("timeline\n  section\n  section :\n"),
    content="ERROR syntax \"Parse error on line 3:\\n  section :\\n----------^\\nExpecting 'EOF', 'SPACE', 'NEWLINE', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'section', 'period', 'event', got 'INVALID'\"",
  )
}

///|
test "a text that does not start with the keyword names what it expected" {
  inspect(
    parse_dump("gantt"),
    content="ERROR syntax \"Parse error on line 1:\\ngantt\\n^\\nExpecting 'timeline', 'timeline_lr', 'timeline_td', got 'period'\"",
  )
  inspect(
    parse_dump(""),
    content="ERROR syntax \"Parse error on line 1:\\n\\n^\\nExpecting 'timeline', 'timeline_lr', 'timeline_td', got 'EOF'\"",
  )
  inspect(
    parse_dump("\n"),
    content="ERROR syntax \"Parse error on line 1:\\n\\n^\\nExpecting 'timeline', 'timeline_lr', 'timeline_td', got 'NEWLINE'\"",
  )
}

///|
test "models and errors match pele for every text of up to four statement pieces" {
  let pieces = [
    "timeline", " ", "\n", ":", "a", "title", "section", " TD", "#", "accTitle:",
    "accDescr {", "}", "\t",
  ]
  let expected = ["f24886eb", "e1cbf153", "b218a01d", "634d15f6", "768a0aa5"]
  for length in 0..<=4 {
    let outputs = strings_over(pieces, length).map(piece => {
      parse_dump("timeline" + piece)
    })
    assert_eq(
      fnv1a(outputs.join("\n")),
      expected[length],
      msg="length \{length}",
    )
  }
}
