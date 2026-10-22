///|
fn optional(value : String?) -> String {
  match value {
    Some(text) => text.escape()
    None => "-"
  }
}

///|
fn dump_x_axis(axis : @xychart.XAxis) -> String {
  match axis.kind {
    Band(categories) =>
      "band(\{axis.title.escape()} [\{categories.map(c => c.escape()).join(",")}])"
    Linear(min, max) => "linear(\{axis.title.escape()} \{min}..\{max})"
  }
}

///|
fn dump_plot(plot : @xychart.Plot) -> String {
  let kind = match plot.kind {
    Line => "line"
    Bar => "bar"
  }
  let points = plot.data.map(point => {
    let (place, value) = point
    match value {
      Some(value) => "\{place.escape()}=\{value}"
      None => "\{place.escape()}=-"
    }
  })
  let labels = match plot.point_labels {
    Some(labels) => "[\{labels.map(l => l.escape()).join(",")}]"
    None => "-"
  }
  "\{kind} \{plot.title.escape()} [\{points.join(",")}] labels=\{labels}"
}

///|
/// Everything an XY chart database holds, on one line per field.
fn dump(db : @xychart.XyChartDb) -> String {
  let orientation = match db.orientation {
    Some(Vertical) => "vertical"
    Some(Horizontal) => "horizontal"
    None => "-"
  }
  let lines = [
    "title=\{optional(db.title)} accTitle=\{optional(db.acc_title)} accDescr=\{optional(db.acc_descr)}",
    "orientation=\{orientation}",
    "x=\{dump_x_axis(db.x_axis)} set=\{db.has_set_x_axis}",
    "y=\{db.y_axis.title.escape()} \{db.y_axis.min}..\{db.y_axis.max} set=\{db.has_set_y_axis}",
  ]
  for plot in db.plots {
    lines.push(dump_plot(plot))
  }
  lines.join("\n")
}

///|
fn lines_of(db : @xychart.XyChartDb) -> Array[String] {
  dump(db).split("\n").map(line => line.to_owned()).collect()
}

///|
fn last_line(db : @xychart.XyChartDb) -> String {
  lines_of(db).last().unwrap()
}

///|
fn points(values : Array[Double]) -> Array[@xychart.DataPoint] {
  values.map(value => { value, label: "", })
}
