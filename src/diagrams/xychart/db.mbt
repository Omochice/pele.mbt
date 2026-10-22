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
pub fn XyChartDb::set_orientation(
  self : XyChartDb,
  orientation : String,
) -> Unit {
  ignore(self)
  ignore(orientation)
}

///|
pub fn XyChartDb::set_x_axis_title(self : XyChartDb, title : String) -> Unit {
  ignore(self)
  ignore(title)
}

///|
pub fn XyChartDb::set_x_axis_range_data(
  self : XyChartDb,
  min : Double,
  max : Double,
) -> Unit {
  ignore(self)
  ignore(min)
  ignore(max)
}

///|
pub fn XyChartDb::set_x_axis_band(
  self : XyChartDb,
  categories : Array[String],
) -> Unit {
  ignore(self)
  ignore(categories)
}

///|
pub fn XyChartDb::set_y_axis_title(self : XyChartDb, title : String) -> Unit {
  ignore(self)
  ignore(title)
}

///|
pub fn XyChartDb::set_y_axis_range_data(
  self : XyChartDb,
  min : Double,
  max : Double,
) -> Unit {
  ignore(self)
  ignore(min)
  ignore(max)
}

///|
pub fn XyChartDb::set_line_data(
  self : XyChartDb,
  title : String,
  data : Array[DataPoint],
) -> Unit {
  ignore(self)
  ignore(title)
  ignore(data)
}

///|
pub fn XyChartDb::set_bar_data(
  self : XyChartDb,
  title : String,
  data : Array[DataPoint],
) -> Unit {
  ignore(self)
  ignore(title)
  ignore(data)
}

///|
pub fn XyChartDb::set_diagram_title(self : XyChartDb, text : String) -> Unit {
  ignore(self)
  ignore(text)
}

///|
pub fn XyChartDb::set_acc_title(self : XyChartDb, text : String) -> Unit {
  ignore(self)
  ignore(text)
}

///|
pub fn XyChartDb::set_acc_description(self : XyChartDb, text : String) -> Unit {
  ignore(self)
  ignore(text)
}
