///|
/// The tokens of Mermaid's gantt grammar.
pub(all) enum Tok {
  End
  Error
  OpenDirective
  AccTitle
  AccTitleValue
  AccDescr
  AccDescrValue
  AccDescrMultilineValue
  Nl
  Href
  CallbackName
  CallbackArgs
  Click
  Gantt
  DateFormat
  InclusiveEndDates
  TopAxis
  AxisFormat
  TickInterval
  Includes
  Excludes
  TodayMarker
  WeekdayMonday
  WeekdayTuesday
  WeekdayWednesday
  WeekdayThursday
  WeekdayFriday
  WeekdaySaturday
  WeekdaySunday
  WeekendFriday
  WeekendSaturday
  Date
  Title
  AccDescription
  Section
  TaskTxt
  TaskData
  Colon
  Eof
}

///|
/// The name Mermaid's parser gives the token in its error messages.
pub fn Tok::name(self : Tok) -> String {
  match self {
    End => "$end"
    Error => "INVALID"
    OpenDirective => "open_directive"
    AccTitle => "acc_title"
    AccTitleValue => "acc_title_value"
    AccDescr => "acc_descr"
    AccDescrValue => "acc_descr_value"
    AccDescrMultilineValue => "acc_descr_multiline_value"
    Nl => "NL"
    Href => "href"
    CallbackName => "callbackname"
    CallbackArgs => "callbackargs"
    Click => "click"
    Gantt => "gantt"
    DateFormat => "dateFormat"
    InclusiveEndDates => "inclusiveEndDates"
    TopAxis => "topAxis"
    AxisFormat => "axisFormat"
    TickInterval => "tickInterval"
    Includes => "includes"
    Excludes => "excludes"
    TodayMarker => "todayMarker"
    WeekdayMonday => "weekday_monday"
    WeekdayTuesday => "weekday_tuesday"
    WeekdayWednesday => "weekday_wednesday"
    WeekdayThursday => "weekday_thursday"
    WeekdayFriday => "weekday_friday"
    WeekdaySaturday => "weekday_saturday"
    WeekdaySunday => "weekday_sunday"
    WeekendFriday => "weekend_friday"
    WeekendSaturday => "weekend_saturday"
    Date => "date"
    Title => "title"
    AccDescription => "accDescription"
    Section => "section"
    TaskTxt => "taskTxt"
    TaskData => "taskData"
    Colon => ":"
    Eof => "EOF"
  }
}
