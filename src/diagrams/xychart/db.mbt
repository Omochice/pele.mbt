///|
/// A value of a series with the label written beside it, empty when there is none.
pub(all) struct DataPoint {
  value : Double
  label : String
}

///|
/// What the x axis is read along.
pub(all) enum XAxisKind {
  Band(Array[String])
  Linear(Double, Double)
}

///|
pub(all) struct XAxis {
  mut title : String
  mut kind : XAxisKind
}

///|
pub(all) struct YAxis {
  mut title : String
  mut min : Double
  mut max : Double
}

///|
pub(all) enum PlotKind {
  Line
  Bar
}

///|
/// A series.
/// Each value comes with its place on the x axis, a category or a number written as text.
/// A category with no value has `None`.
pub(all) struct Plot {
  kind : PlotKind
  title : String
  data : Array[(String, Double?)]
  point_labels : Array[String]?
}

///|
pub(all) enum Orientation {
  Vertical
  Horizontal
}

///|
/// An XY chart as the statements of its source have built it.
pub(all) struct XyChartDb {
  mut title : String?
  mut acc_title : String?
  mut acc_descr : String?
  mut orientation : Orientation?
  mut x_axis : XAxis
  y_axis : YAxis
  /// False while the y range comes from the data and not from a `y-axis` statement.
  mut has_set_y_axis : Bool
  mut has_set_x_axis : Bool
  plots : Array[Plot]
}

///|
/// A chart with no statements read: a band axis with no categories, and a value range that is empty.
pub fn XyChartDb::new() -> XyChartDb {
  {
    title: None,
    acc_title: None,
    acc_descr: None,
    orientation: None,
    x_axis: { title: "", kind: Band([]), },
    y_axis: { title: "", min: @double.infinity, max: @double.neg_infinity, },
    has_set_y_axis: false,
    has_set_x_axis: false,
    plots: [],
  }
}

///|
/// Any word other than exactly `horizontal` means vertical, whatever case the source spelled it in.
pub fn XyChartDb::set_orientation(
  self : XyChartDb,
  orientation : String,
) -> Unit {
  self.orientation = Some(
    if orientation == "horizontal" {
      Horizontal
    } else {
      Vertical
    },
  )
}

///|
pub fn XyChartDb::set_x_axis_title(self : XyChartDb, title : String) -> Unit {
  self.x_axis.title = @util.trim(title)
}

///|
pub fn XyChartDb::set_x_axis_range_data(
  self : XyChartDb,
  min : Double,
  max : Double,
) -> Unit {
  self.x_axis = { title: self.x_axis.title, kind: Linear(min, max), }
  self.has_set_x_axis = true
}

///|
pub fn XyChartDb::set_x_axis_band(
  self : XyChartDb,
  categories : Array[String],
) -> Unit {
  self.x_axis = {
    title: self.x_axis.title,
    kind: Band(categories.map(@util.trim)),
  }
  self.has_set_x_axis = true
}

///|
pub fn XyChartDb::set_y_axis_title(self : XyChartDb, title : String) -> Unit {
  self.y_axis.title = @util.trim(title)
}

///|
pub fn XyChartDb::set_y_axis_range_data(
  self : XyChartDb,
  min : Double,
  max : Double,
) -> Unit {
  self.y_axis.min = min
  self.y_axis.max = max
  self.has_set_y_axis = true
}

///|
/// What `${number}` writes, which has no negative zero.
fn number_text(value : Double) -> String {
  if value == 0 {
    "0"
  } else {
    value.to_string()
  }
}

///|
fn XyChartDb::plot_data(
  self : XyChartDb,
  values : Array[Double],
) -> Array[(String, Double?)] {
  if values.length() == 0 {
    return []
  }
  // The first series fixes the x range when no x-axis statement did.
  if !self.has_set_x_axis {
    self.set_x_axis_range_data(1, values.length().to_double())
  }
  let kind = self.x_axis.kind
  let kept = match kind {
    Band(categories) if values.length() > categories.length() =>
      values[:categories.length()].to_owned()
    _ => values
  }
  if !self.has_set_y_axis {
    for value in kept {
      if value < self.y_axis.min {
        self.y_axis.min = value
      }
      if value > self.y_axis.max {
        self.y_axis.max = value
      }
    }
  }
  match kind {
    Band(categories) =>
      categories.mapi((i, category) => (category, kept.get(i)))
    Linear(min, max) =>
      if kept.length() == 1 {
        [(number_text(min), Some(kept[0]))]
      } else {
        let step = (max - min) / (kept.length() - 1).to_double()
        kept.mapi((i, value) => {
          (number_text(min + i.to_double() * step), Some(value))
        })
      }
  }
}

///|
fn XyChartDb::add_plot(
  self : XyChartDb,
  kind : PlotKind,
  title : String,
  data : Array[DataPoint],
) -> Unit {
  let plot_data = self.plot_data(data.map(point => point.value))
  // Mermaid accepts labels on the points of a bar series and ignores them.
  let point_labels = if kind is Line &&
    data.any(point => @util.trim(point.label) != "") {
    Some(data.map(point => @util.trim(point.label)))
  } else {
    None
  }
  self.plots.push({
    kind,
    title: @util.trim(title),
    data: plot_data,
    point_labels,
  })
}

///|
pub fn XyChartDb::set_line_data(
  self : XyChartDb,
  title : String,
  data : Array[DataPoint],
) -> Unit {
  self.add_plot(Line, title, data)
}

///|
pub fn XyChartDb::set_bar_data(
  self : XyChartDb,
  title : String,
  data : Array[DataPoint],
) -> Unit {
  self.add_plot(Bar, title, data)
}

///|
pub fn XyChartDb::set_diagram_title(self : XyChartDb, text : String) -> Unit {
  self.title = Some(text)
}

///|
pub fn XyChartDb::set_acc_title(self : XyChartDb, text : String) -> Unit {
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
pub fn XyChartDb::set_acc_description(self : XyChartDb, text : String) -> Unit {
  self.acc_descr = Some(join_indented_lines(text))
}
