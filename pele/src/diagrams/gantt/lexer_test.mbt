// The expected streams were taken from pele's gantt lexer.

///|
/// The token stream one per line, as `NAME@start "text"` with the text escaped.
fn lex(source : String) -> String {
  let tokens = @gantt.tokenize(source)
  let lines = []
  for i, kind in tokens.types {
    lines.push("\{kind.name()}@\{tokens.starts[i]} \{quote(tokens.texts[i])}")
  }
  lines.join("\n")
}

///|
fn quote(text : String) -> String {
  let out = StringBuilder()
  out.write_char('"')
  for c in text {
    match c {
      '\\' => out.write_string("\\\\")
      '"' => out.write_string("\\\"")
      '\n' => out.write_string("\\n")
      '\r' => out.write_string("\\r")
      '\t' => out.write_string("\\t")
      _ => out.write_char(c)
    }
  }
  out.write_char('"')
  out.to_string()
}

///|
test "reads settings, sections and tasks" {
  inspect(
    lex(
      "gantt\n  dateFormat YYYY-MM-DD\n  title A %% x\n  section S\n  A task :a1, 2014-01-01, 30d\n",
    ),
    content=(
      #|gantt@0 "gantt"
      #|NL@5 "\n"
      #|dateFormat@8 "dateFormat YYYY-MM-DD"
      #|NL@29 "\n"
      #|title@32 "title A %% x"
      #|NL@44 "\n"
      #|section@47 "section S"
      #|NL@56 "\n"
      #|taskTxt@59 "A task "
      #|taskData@66 ":a1, 2014-01-01, 30d"
      #|NL@86 "\n"
      #|EOF@87 ""
      #|$end@87 ""
    ),
  )
}

///|
test "reads accessible titles and descriptions" {
  inspect(
    lex(
      "gantt\naccTitle: My title\naccDescr : desc\naccDescr {\n multi\n line\n}\nx",
    ),
    content=(
      #|gantt@0 "gantt"
      #|NL@5 "\n"
      #|acc_title@6 "accTitle: "
      #|acc_title_value@16 "My title"
      #|NL@24 "\n"
      #|acc_descr@25 "accDescr : "
      #|acc_descr_value@36 "desc"
      #|NL@40 "\n"
      #|acc_descr_multiline_value@53 "multi\n line\n"
      #|NL@66 "\n"
      #|taskTxt@67 "x"
      #|EOF@68 ""
      #|$end@68 ""
    ),
  )
}

///|
test "reads links and callbacks" {
  inspect(
    lex(
      "gantt\nclick a href \"https://x\"\nclick a call f(1, 2)\nclick b,c call g()\nclick d call h( )\n",
    ),
    content=(
      #|gantt@0 "gantt"
      #|NL@5 "\n"
      #|click@12 "a"
      #|href@20 "https://x"
      #|NL@30 "\n"
      #|click@37 "a"
      #|callbackname@44 "f"
      #|callbackargs@46 "1, 2"
      #|NL@51 "\n"
      #|click@58 "b,c"
      #|callbackname@67 "g"
      #|NL@70 "\n"
      #|click@77 "d"
      #|callbackname@84 "h"
      #|NL@88 "\n"
      #|EOF@89 ""
      #|$end@89 ""
    ),
  )
}

///|
test "reads weekdays and weekends in any case" {
  inspect(
    lex(
      "gantt\nweekday monday\nWeekday SUNDAY\nweekend friday\nweekend saturday\nweekday mondays\nweekend sunday\n",
    ),
    content=(
      #|gantt@0 "gantt"
      #|NL@5 "\n"
      #|weekday_monday@6 "weekday monday"
      #|NL@20 "\n"
      #|weekday_sunday@21 "Weekday SUNDAY"
      #|NL@35 "\n"
      #|weekend_friday@36 "weekend friday"
      #|NL@50 "\n"
      #|weekend_saturday@51 "weekend saturday"
      #|NL@67 "\n"
      #|taskTxt@68 "weekday mondays"
      #|NL@83 "\n"
      #|taskTxt@84 "weekend sunday"
      #|NL@98 "\n"
      #|EOF@99 ""
      #|$end@99 ""
    ),
  )
}

///|
test "stops at a directive it cannot enter" {
  inspect(
    lex("gantt\n%%{init: {}}%%\nx"),
    content=(
      #|gantt@0 "gantt"
      #|NL@5 "\n"
      #|open_directive@6 "%%{"
      #|INVALID@9 ""
    ),
  )
}

///|
test "skips comments that start with a percent sign" {
  inspect(
    lex("gantt\n% comment\n%%  c\nA%B :x\n}%y\n%\n\n\nq"),
    content=(
      #|gantt@0 "gantt"
      #|NL@5 "\n"
      #|NL@21 "\n"
      #|taskTxt@22 "A%B "
      #|taskData@26 ":x"
      #|NL@28 "\n"
      #|taskTxt@29 "}%y"
      #|NL@32 "\n"
      #|taskTxt@37 "q"
      #|EOF@38 ""
      #|$end@38 ""
    ),
  )
}

///|
test "ends settings at a comment or semicolon" {
  inspect(
    lex(
      "gantt\ninclusiveEndDates\ntopAxis\naxisFormat %Y-%m;x\ntickInterval 1day#c\nincludes 2024-01-01\nexcludes weekends\ntodayMarker stroke:red;x\naccDescription some text\n",
    ),
    content=(
      #|gantt@0 "gantt"
      #|NL@5 "\n"
      #|inclusiveEndDates@6 "inclusiveEndDates"
      #|NL@23 "\n"
      #|topAxis@24 "topAxis"
      #|NL@31 "\n"
      #|axisFormat@32 "axisFormat %Y-%m"
      #|taskTxt@48 ";x"
      #|NL@50 "\n"
      #|tickInterval@51 "tickInterval 1day"
      #|taskTxt@68 "#c"
      #|NL@70 "\n"
      #|includes@71 "includes 2024-01-01"
      #|NL@90 "\n"
      #|excludes@91 "excludes weekends"
      #|NL@108 "\n"
      #|todayMarker@109 "todayMarker stroke:red"
      #|taskTxt@131 ";x"
      #|NL@133 "\n"
      #|accDescription@134 "accDescription some text"
      #|NL@158 "\n"
      #|EOF@159 ""
      #|$end@159 ""
    ),
  )
}

///|
test "reads dates, colons and task data" {
  inspect(
    lex("gantt\n2024-01-01x :a\n2024-01-01 :b\n2024-01-011\n:\n::\n:a;b\n:#\n"),
    content=(
      #|gantt@0 "gantt"
      #|NL@5 "\n"
      #|taskTxt@6 "2024-01-01x "
      #|taskData@18 ":a"
      #|NL@20 "\n"
      #|date@21 "2024-01-01"
      #|taskData@32 ":b"
      #|NL@34 "\n"
      #|taskTxt@35 "2024-01-011"
      #|NL@46 "\n"
      #|:@47 ":"
      #|NL@48 "\n"
      #|taskData@49 "::"
      #|NL@51 "\n"
      #|taskData@52 ":a"
      #|taskTxt@54 ";b"
      #|NL@56 "\n"
      #|:@57 ":"
      #|taskTxt@58 "#"
      #|NL@59 "\n"
      #|EOF@60 ""
      #|$end@60 ""
    ),
  )
}

///|
test "reads keywords whose value starts on the next line" {
  inspect(
    lex("gantt\ntitle\nsection\ndateFormat\nx"),
    content=(
      #|gantt@0 "gantt"
      #|NL@5 "\n"
      #|title@6 "title\nsection"
      #|NL@19 "\n"
      #|dateFormat@20 "dateFormat\nx"
      #|EOF@32 ""
      #|$end@32 ""
    ),
  )
}

///|
test "reads keywords in any case" {
  inspect(
    lex("GANTT\nDateFormat x\nTITLE y\n"),
    content=(
      #|gantt@0 "GANTT"
      #|NL@5 "\n"
      #|dateFormat@6 "DateFormat x"
      #|NL@18 "\n"
      #|title@19 "TITLE y"
      #|NL@26 "\n"
      #|EOF@27 ""
      #|$end@27 ""
    ),
  )
}

///|
test "takes accTitle without a colon as task text" {
  inspect(
    lex("gantt\naccTitle   no colon\n"),
    content=(
      #|gantt@0 "gantt"
      #|NL@5 "\n"
      #|taskTxt@6 "accTitle   no colon"
      #|NL@25 "\n"
      #|EOF@26 ""
      #|$end@26 ""
    ),
  )
}

///|
test "ends an unterminated link at the end" {
  inspect(
    lex("gantt\nclick a href \"unterminated"),
    content=(
      #|gantt@0 "gantt"
      #|NL@5 "\n"
      #|click@12 "a"
      #|href@20 "unterminated"
      #|href@32 ""
      #|$end@32 ""
    ),
  )
}

///|
test "ends unterminated callback arguments at the end" {
  inspect(
    lex("gantt\nclick a call f(unterminated"),
    content=(
      #|gantt@0 "gantt"
      #|NL@5 "\n"
      #|click@12 "a"
      #|callbackname@19 "f"
      #|callbackargs@21 "unterminated"
      #|callbackargs@33 ""
      #|$end@33 ""
    ),
  )
}

///|
test "keeps carriage returns in task data" {
  inspect(
    lex("gantt\r\nA :1d\r\n"),
    content=(
      #|gantt@0 "gantt"
      #|taskTxt@7 "A "
      #|taskData@9 ":1d\r"
      #|NL@13 "\n"
      #|EOF@14 ""
      #|$end@14 ""
    ),
  )
}

///|
test "reads a section after a tab" {
  inspect(
    lex("gantt\n\tsection\tTab\n"),
    content=(
      #|gantt@0 "gantt"
      #|NL@5 "\n"
      #|section@7 "section\tTab"
      #|NL@18 "\n"
      #|EOF@19 ""
      #|$end@19 ""
    ),
  )
}

///|
test "needs a word boundary after bare keywords" {
  inspect(
    lex(
      "gantt\nax :1\nganttX :1\ndateformatx :1\ninclusiveEndDatesX\ntopAxisy\n",
    ),
    content=(
      #|gantt@0 "gantt"
      #|NL@5 "\n"
      #|taskTxt@6 "ax "
      #|taskData@9 ":1"
      #|NL@11 "\n"
      #|taskTxt@12 "ganttX "
      #|taskData@19 ":1"
      #|NL@21 "\n"
      #|taskTxt@22 "dateformatx "
      #|taskData@34 ":1"
      #|NL@36 "\n"
      #|taskTxt@37 "inclusiveEndDatesX"
      #|NL@55 "\n"
      #|taskTxt@56 "topAxisy"
      #|NL@64 "\n"
      #|EOF@65 ""
      #|$end@65 ""
    ),
  )
}

///|
test "reads a weekday across lines" {
  inspect(
    lex("gantt\nweekday  tuesday\nweekday\nwednesday\nweekday"),
    content=(
      #|gantt@0 "gantt"
      #|NL@5 "\n"
      #|weekday_tuesday@6 "weekday  tuesday"
      #|NL@22 "\n"
      #|weekday_wednesday@23 "weekday\nwednesday"
      #|NL@40 "\n"
      #|taskTxt@41 "weekday"
      #|EOF@48 ""
      #|$end@48 ""
    ),
  )
}

///|
test "takes click without a space as task text" {
  inspect(
    lex("gantt\nclick"),
    content=(
      #|gantt@0 "gantt"
      #|NL@5 "\n"
      #|taskTxt@6 "click"
      #|EOF@11 ""
      #|$end@11 ""
    ),
  )
}

///|
test "enters link and callback states outside click" {
  inspect(
    lex("gantt\ncall x\nhref \"y\"\nclick  a  href\n"),
    content=(
      #|gantt@0 "gantt"
      #|NL@5 "\n"
      #|callbackname@11 "x\nhref \"y\"\nclick  a  href\n"
      #|callbackname@37 ""
      #|$end@37 ""
    ),
  )
}

///|
test "folds only ASCII letters" {
  inspect(
    lex("gantt\nſection x\nTITLE x\n"),
    content=(
      #|gantt@0 "gantt"
      #|NL@5 "\n"
      #|taskTxt@6 "ſection x"
      #|NL@15 "\n"
      #|title@16 "TITLE x"
      #|NL@23 "\n"
      #|EOF@24 ""
      #|$end@24 ""
    ),
  )
}

///|
test "ends an unterminated description block at the end" {
  inspect(
    lex("gantt\naccDescr {\n x"),
    content=(
      #|gantt@0 "gantt"
      #|NL@5 "\n"
      #|acc_descr_multiline_value@18 "x"
      #|acc_descr_multiline_value@19 ""
      #|$end@19 ""
    ),
  )
}
