///|
pub(all) struct RadarAxis {
  name : String
  label : String
}

///|
pub(all) struct RadarCurve {
  name : String
  label : String
  /// One value per axis, in the order of the axes.
  entries : Array[Double]
}

///|
pub(all) struct RadarOptions {
  show_legend : Bool
  ticks : Double
  /// `None` until a `max` option is given; the chart then scales to its largest value.
  max : Double?
  min : Double
  /// `"circle"` or `"polygon"`.
  graticule : String
}

///|
/// A radar chart ready to be drawn.
pub(all) struct RadarModel {
  title : String?
  acc_title : String?
  acc_descr : String?
  axes : Array[RadarAxis]
  curves : Array[RadarCurve]
  options : RadarOptions
}

///|
/// Caps the number of graticule rings, so that a huge `ticks` cannot make the output unbounded.
const MAX_TICKS : Double = 32

///|
fn invalid(message : String) -> @errors.PeleError {
  @errors.pele_error(message, code=Semantic, kind="radar")
}

///|
fn non_empty(value : String?) -> String? {
  match value {
    Some("") => None
    _ => value
  }
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
fn entries_of(
  curve : CurveAst,
  axes : Array[RadarAxis],
) -> Array[Double] raise @errors.PeleError {
  if curve.entries[0].axis is None {
    return curve.entries.map(entry => entry.value)
  }
  if axes.is_empty() {
    raise invalid("Axes must be populated before curves for reference entries")
  }
  let by_axis : Map[String, Double] = {}
  for entry in curve.entries {
    if entry.axis is Some(axis) && !by_axis.contains(axis) {
      by_axis[axis] = entry.value
    }
  }
  let entries = []
  for axis in axes {
    match by_axis.get(axis.name) {
      Some(value) => entries.push(value)
      None => raise invalid("Missing entry for axis \{axis.label}")
    }
  }
  entries
}

///|
/// Resolves the axes and curves of a radar chart and applies its options.
/// `title` is the front matter title, used when the chart has none.
/// Raises a semantic `PeleError` for a named entry that cannot be placed on the axes.
pub fn build_radar(
  ast : RadarAst,
  title : String?,
) -> RadarModel raise @errors.PeleError {
  let axes : Array[RadarAxis] = ast.axes.map(axis => {
    name: axis.name,
    label: axis.label.unwrap_or(axis.name),
  })
  let curves : Array[RadarCurve] = []
  for curve in ast.curves {
    let entries = entries_of(curve, axes)
    curves.push({
      name: curve.name,
      label: curve.label.unwrap_or(curve.name),
      entries,
    })
  }
  let mut show_legend = true
  let mut ticks = 5.0
  let mut max = None
  let mut min = 0.0
  let mut graticule = "circle"
  for option in ast.options {
    match (option.name, option.value) {
      ("showLegend", Flag(flag)) => show_legend = flag
      ("graticule", Name(name)) => graticule = name
      ("ticks", Number(value)) => ticks = value
      ("max", Number(value)) => max = Some(value)
      ("min", Number(value)) => min = value
      _ => ()
    }
  }
  if ticks > MAX_TICKS {
    ticks = MAX_TICKS
  }
  {
    title: match non_empty(ast.title) {
      Some(_) as own => own
      None => title
    },
    acc_title: non_empty(ast.acc_title).map(@util.trim_start),
    acc_descr: non_empty(ast.acc_descr).map(join_indented_lines),
    axes,
    curves,
    options: { show_legend, ticks, max, min, graticule, },
  }
}
