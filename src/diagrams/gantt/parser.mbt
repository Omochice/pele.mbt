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
const LINE : String = "'EOF', 'SPACE', 'NL', 'weekday_monday', 'weekday_tuesday', 'weekday_wednesday', 'weekday_thursday', 'weekday_friday', 'weekday_saturday', 'weekday_sunday', 'weekend_friday', 'weekend_saturday', 'dateFormat', 'inclusiveEndDates', 'topAxis', 'axisFormat', 'tickInterval', 'excludes', 'includes', 'todayMarker', 'title', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'section', 'taskTxt', 'click'"

///|
/// Tokens that can start a line, which are also the only ones that can follow a complete statement.
fn starts_line(t : Tok) -> Bool {
  match t {
    WeekdayMonday
    | WeekdayTuesday
    | WeekdayWednesday
    | WeekdayThursday
    | WeekdayFriday
    | WeekdaySaturday
    | WeekdaySunday
    | WeekendFriday
    | WeekendSaturday
    | Eof
    | Nl
    | DateFormat
    | InclusiveEndDates
    | TopAxis
    | AxisFormat
    | TickInterval
    | Excludes
    | Includes
    | TodayMarker
    | Title
    | AccTitle
    | AccDescr
    | AccDescrMultilineValue
    | Section
    | TaskTxt
    | Click => true
    _ => false
  }
}

///|
fn weekday_name(t : Tok) -> String {
  match t {
    WeekdayMonday => "monday"
    WeekdayTuesday => "tuesday"
    WeekdayWednesday => "wednesday"
    WeekdayThursday => "thursday"
    WeekdayFriday => "friday"
    WeekdaySaturday => "saturday"
    _ => "sunday"
  }
}

///|
/// Parses a gantt chart into the builder, as Mermaid's grammar does.
pub fn[B : GanttBuilder] parse_gantt(
  src : String,
  db : B,
) -> Unit raise @errors.PeleError {
  let { types, texts, starts, } = tokenize(src)
  let mut i = 0
  let fail = (expected : String) => {
    let t = types[i]
    let name = if t is End { "1" } else { t.name() }
    @errors.syntax_error(
      "gantt",
      src,
      starts[i],
      "Expecting \{expected}, got '\{name}'",
    )
  }
  // Mermaid's parser runs a statement's action only after seeing that the next token can follow it.
  let end = (also : String) => {
    if starts_line(types[i]) {
      None
    } else {
      Some(fail(LINE + also))
    }
  }
  if !(types[i] is Gantt) {
    raise fail("'gantt'")
  }
  i += 1
  while true {
    let t = types[i]
    let text = texts[i]
    if !starts_line(t) {
      raise fail(LINE)
    }
    i += 1
    match t {
      Eof => {
        if types[i] is End {
          return
        }
        if end("") is Some(error) {
          raise error
        }
      }
      Nl => ()
      AccTitle => {
        if !(types[i] is AccTitleValue) {
          raise fail("'acc_title_value'")
        }
        let value = texts[i]
        i += 1
        if end("") is Some(error) {
          raise error
        }
        db.set_acc_title(@util.trim(value))
      }
      AccDescr => {
        if !(types[i] is AccDescrValue) {
          raise fail("'acc_descr_value'")
        }
        let value = texts[i]
        i += 1
        if end("") is Some(error) {
          raise error
        }
        db.set_acc_description(@util.trim(value))
      }
      TaskTxt => {
        if !(types[i] is TaskData) {
          raise fail("'taskData'")
        }
        let data = texts[i]
        i += 1
        if end("") is Some(error) {
          raise error
        }
        db.add_task(text, data)
      }
      Click => {
        let mut name = None
        let mut args = None
        let mut href = None
        if types[i] is CallbackName {
          name = Some(texts[i])
          i += 1
          if types[i] is CallbackArgs {
            args = Some(texts[i])
            i += 1
          }
          if types[i] is Href {
            href = Some(texts[i])
            i += 1
            if end("") is Some(error) {
              raise error
            }
          } else {
            let also = if args is None {
              ", 'callbackargs', 'href'"
            } else {
              ", 'href'"
            }
            if end(also) is Some(error) {
              raise error
            }
          }
        } else if types[i] is Href {
          href = Some(texts[i])
          i += 1
          if types[i] is CallbackName {
            name = Some(texts[i])
            i += 1
            if types[i] is CallbackArgs {
              args = Some(texts[i])
              i += 1
              if end("") is Some(error) {
                raise error
              }
            } else if end(", 'callbackargs'") is Some(error) {
              raise error
            }
          } else if end(", 'callbackname'") is Some(error) {
            raise error
          }
        } else {
          raise fail("'callbackname', 'href'")
        }
        if name is Some(function_name) {
          db.set_click_event(text, function_name, args)
        }
        if href is Some(link) {
          db.set_link(text, link)
        }
      }
      _ => {
        if end("") is Some(error) {
          raise error
        }
        match t {
          DateFormat => db.set_date_format(@util.slice(text, 11))
          InclusiveEndDates => db.enable_inclusive_end_dates()
          TopAxis => db.top_axis()
          AxisFormat => db.set_axis_format(@util.slice(text, 11))
          TickInterval => db.set_tick_interval(@util.slice(text, 13))
          Excludes => db.set_excludes(@util.slice(text, 9))
          Includes => db.set_includes(@util.slice(text, 9))
          TodayMarker => db.set_today_marker(@util.slice(text, 12))
          WeekendFriday => db.set_weekend("friday")
          WeekendSaturday => db.set_weekend("saturday")
          Title => db.set_diagram_title(@util.slice(text, 6))
          AccDescrMultilineValue => db.set_acc_description(@util.trim(text))
          Section => db.add_section(@util.slice(text, 8))
          _ => db.set_weekday(weekday_name(t))
        }
      }
    }
  }
}
