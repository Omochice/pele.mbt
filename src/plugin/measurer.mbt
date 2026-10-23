///|
/// Reads the advance table of one style.
/// An advance keyed by more or less than one code unit could never match one, so it is dropped here.
fn decode_advance_table(face : Map[String, Json]) -> @text.AdvanceTable {
  let advances : Map[Int32, Double] = Map([])
  if face.get("advances") is Some(Object(entries)) {
    for key, advance in entries {
      if key.length() == 1 && advance is Number(units, ..) {
        advances[key.unsafe_get(0).to_int()] = units
      }
    }
  }
  let narrow = number_field(face, "default").unwrap_or(0)
  let wide = number_field(face, "wide").unwrap_or(narrow)
  { advances, narrow, wide, }
}

///|
/// Reads the measurer that stands in for pele's `TextMeasurer`, or `None` when the options hold no measurer object.
/// golden/README.md describes the table, and scripts/plugin-options.mjs is its reference.
fn decode_measurer(json : Json?) -> @text.TextMeasurer? {
  guard json is Some(Object(spec)) else { return None }
  let units_per_em = match spec.get("unitsPerEm") {
    Some(Number(units, ..)) if units > 0 => units
    _ => 1000
  }
  let tables : Map[String, @text.AdvanceTable] = Map([])
  if spec.get("styles") is Some(Object(styles)) {
    for style, face in styles {
      if face is Object(face) {
        tables[style] = decode_advance_table(face)
      }
    }
  }
  let regular = tables
    .get("0")
    .unwrap_or({ advances: Map([]), narrow: 0, wide: 0, })
  Some(
    @text.table_measurer(
      style => tables.get(style.to_string()).unwrap_or(regular),
      units_per_em,
    ),
  )
}
