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
fn invalid(style : String, value : String, kind : String) -> @errors.PeleError {
  @errors.pele_error(
    "value for \{style} \{value} is invalid, please use a valid \{kind}",
    code=Semantic,
    kind="quadrantChart",
  )
}

///|
/// Does what `/^\d+$/` does.
fn is_number(value : String) -> Bool {
  if value == "" {
    return false
  }
  for i in 0..<value.length() {
    if !@util.is_digit(@util.code_at(value, i)) {
      return false
    }
  }
  true
}

///|
/// Does what `/^#?([\dA-Fa-f]{6}|[\dA-Fa-f]{3})$/` does.
fn is_hex_code(value : String) -> Bool {
  let from = if @util.code_at(value, 0) == '#'.to_int() { 1 } else { 0 }
  let digits = value.length() - from
  if digits != 3 && digits != 6 {
    return false
  }
  for i in from..<value.length() {
    if !@util.is_hex(@util.code_at(value, i)) {
      return false
    }
  }
  true
}

///|
/// Does what `/^\d+px$/` does.
fn is_pixels(value : String) -> Bool {
  value.length() > 2 &&
  value.has_suffix("px") &&
  is_number(@util.slice(value, 0, end=value.length() - 2))
}

///|
/// The first two parts of Mermaid's `style.trim().split(/\s*:\s*/)`, found in one pass.
/// Without a colon the value is the text of `undefined`, as it is when Mermaid goes on with the missing part.
fn key_value(style : String) -> (String, String) {
  let trimmed = @util.trim(style)
  let colon = @util.index_of(trimmed, ":")
  if colon == -1 {
    return (trimmed, "undefined")
  }
  let rest = @util.trim_start(@util.slice(trimmed, colon + 1))
  let next = @util.index_of(rest, ":")
  let value = if next == -1 {
    rest
  } else {
    @util.trim_end(@util.slice(rest, 0, end=next))
  }
  (@util.trim_end(@util.slice(trimmed, 0, end=colon)), value)
}

///|
/// Reads the styles of a point or a class.
/// Raises a semantic `PeleError` with Mermaid's wording for a style it does not support or a value it rejects.
pub fn parse_styles(
  styles : Array[String],
) -> PointStyle raise @errors.PeleError {
  let mut radius = None
  let mut color = None
  let mut stroke_color = None
  let mut stroke_width = None
  for style in styles {
    let (key, value) = key_value(style)
    match key {
      "radius" => {
        if !is_number(value) {
          raise invalid(key, value, "number")
        }
        radius = Some(@util.parse_float(value))
      }
      "color" => {
        if !is_hex_code(value) {
          raise invalid(key, value, "hex code")
        }
        color = Some(value)
      }
      "stroke-color" => {
        if !is_hex_code(value) {
          raise invalid(key, value, "hex code")
        }
        stroke_color = Some(value)
      }
      "stroke-width" => {
        if !is_pixels(value) {
          raise invalid(key, value, "number of pixels (eg. 10px)")
        }
        stroke_width = Some(value)
      }
      _ =>
        raise @errors.pele_error(
          "style named \{key} is not supported.",
          code=Semantic,
          kind="quadrantChart",
        )
    }
  }
  { radius, color, stroke_color, stroke_width, }
}

///|
fn trimmed(label : QuadrantText) -> QuadrantText {
  { text: @util.trim(label.text), markdown: label.markdown, }
}

///|
/// Sets quadrant `number`, from 1 to 4.
pub fn QuadrantDb::set_quadrant_text(
  self : QuadrantDb,
  number : Int32,
  label : QuadrantText,
) -> Unit {
  self.quadrants[number - 1] = Some(trimmed(label))
}

///|
pub fn QuadrantDb::set_x_axis_left_text(
  self : QuadrantDb,
  label : QuadrantText,
) -> Unit {
  self.x_axis_left = Some(trimmed(label))
}

///|
pub fn QuadrantDb::set_x_axis_right_text(
  self : QuadrantDb,
  label : QuadrantText,
) -> Unit {
  self.x_axis_right = Some(trimmed(label))
}

///|
pub fn QuadrantDb::set_y_axis_bottom_text(
  self : QuadrantDb,
  label : QuadrantText,
) -> Unit {
  self.y_axis_bottom = Some(trimmed(label))
}

///|
pub fn QuadrantDb::set_y_axis_top_text(
  self : QuadrantDb,
  label : QuadrantText,
) -> Unit {
  self.y_axis_top = Some(trimmed(label))
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
  self.points.push({
    x: @util.to_number(x),
    y: @util.to_number(y),
    text: trimmed(label),
    class_name,
    style: parse_styles(styles),
  })
}

///|
/// Defines or redefines a class. Raises what `parse_styles` raises.
pub fn QuadrantDb::add_class(
  self : QuadrantDb,
  class_name : String,
  styles : Array[String],
) -> Unit raise @errors.PeleError {
  self.classes[class_name] = parse_styles(styles)
}

///|
pub fn QuadrantDb::set_diagram_title(self : QuadrantDb, text : String) -> Unit {
  self.title = Some(text)
}

///|
pub fn QuadrantDb::set_acc_title(self : QuadrantDb, text : String) -> Unit {
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
pub fn QuadrantDb::set_acc_description(
  self : QuadrantDb,
  text : String,
) -> Unit {
  self.acc_descr = Some(join_indented_lines(text))
}
