///|
/// Label text as the chart gives it, and whether it was written as a markdown string.
pub(all) struct QuadrantText {
  text : String
  markdown : Bool
}

///|
/// The look of a point that its own styles or its class set; a field stays `None` when none did.
pub(all) struct PointStyle {
  radius : Double?
  color : String?
  stroke_color : String?
  stroke_width : String?
}

///|
pub(all) struct QuadrantPoint {
  /// As written: NaN when the coordinate is not a number.
  x : Double
  y : Double
  text : QuadrantText
  class_name : String
  style : PointStyle
}

///|
/// The statements of a quadrant chart, collected as the parser reads them.
pub(all) struct QuadrantDb {
  mut title : String?
  mut acc_title : String?
  mut acc_descr : String?
  /// Quadrants 1 to 4: top right, top left, bottom left, bottom right.
  quadrants : Array[QuadrantText?]
  mut x_axis_left : QuadrantText?
  mut x_axis_right : QuadrantText?
  mut y_axis_bottom : QuadrantText?
  mut y_axis_top : QuadrantText?
  points : Array[QuadrantPoint]
  classes : Map[String, PointStyle]
}

///|
/// An empty chart whose title is `title`, the front matter title, until the source sets one.
pub fn QuadrantDb::new(title : String?) -> QuadrantDb {
  {
    title,
    acc_title: None,
    acc_descr: None,
    quadrants: [None, None, None, None],
    x_axis_left: None,
    x_axis_right: None,
    y_axis_bottom: None,
    y_axis_top: None,
    points: [],
    classes: {},
  }
}

///|
/// Reads the styles of a point or a class.
/// Raises a semantic `PeleError` with Mermaid's wording for a style it does not support or a value it rejects.
pub fn parse_styles(
  styles : Array[String],
) -> PointStyle raise @errors.PeleError {
  raise @errors.pele_error("not implemented \{styles.length()}")
}

///|
/// Sets quadrant `number`, from 1 to 4.
pub fn QuadrantDb::set_quadrant_text(
  self : QuadrantDb,
  number : Int32,
  label : QuadrantText,
) -> Unit {
  ignore((self, number, label))
}

///|
pub fn QuadrantDb::set_x_axis_left_text(
  self : QuadrantDb,
  label : QuadrantText,
) -> Unit {
  ignore((self, label))
}

///|
pub fn QuadrantDb::set_x_axis_right_text(
  self : QuadrantDb,
  label : QuadrantText,
) -> Unit {
  ignore((self, label))
}

///|
pub fn QuadrantDb::set_y_axis_bottom_text(
  self : QuadrantDb,
  label : QuadrantText,
) -> Unit {
  ignore((self, label))
}

///|
pub fn QuadrantDb::set_y_axis_top_text(
  self : QuadrantDb,
  label : QuadrantText,
) -> Unit {
  ignore((self, label))
}

///|
/// Adds a point whose coordinates are the text the lexer read.
/// Raises what `parse_styles` raises.
pub fn QuadrantDb::add_point(
  self : QuadrantDb,
  label : QuadrantText,
  class_name : String,
  x : String,
  y : String,
  styles : Array[String],
) -> Unit raise @errors.PeleError {
  ignore((self, label, class_name, x, y))
  ignore(parse_styles(styles))
}

///|
/// Defines or redefines a class. Raises what `parse_styles` raises.
pub fn QuadrantDb::add_class(
  self : QuadrantDb,
  class_name : String,
  styles : Array[String],
) -> Unit raise @errors.PeleError {
  ignore((self, class_name))
  ignore(parse_styles(styles))
}

///|
pub fn QuadrantDb::set_diagram_title(self : QuadrantDb, text : String) -> Unit {
  ignore((self, text))
}

///|
pub fn QuadrantDb::set_acc_title(self : QuadrantDb, text : String) -> Unit {
  ignore((self, text))
}

///|
pub fn QuadrantDb::set_acc_description(
  self : QuadrantDb,
  text : String,
) -> Unit {
  ignore((self, text))
}
