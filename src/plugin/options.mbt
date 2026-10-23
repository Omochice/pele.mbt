///|
fn string_field(json : Map[String, Json], key : String) -> String? {
  match json.get(key) {
    Some(String(value)) => Some(value)
    _ => None
  }
}

///|
fn number_field(json : Map[String, Json], key : String) -> Double? {
  match json.get(key) {
    Some(Number(value, ..)) => Some(value)
    _ => None
  }
}

///|
fn bool_field(json : Map[String, Json], key : String) -> Bool? {
  match json.get(key) {
    Some(True) => Some(true)
    Some(False) => Some(false)
    _ => None
  }
}

///|
fn strings_field(json : Map[String, Json], key : String) -> Array[String]? {
  guard json.get(key) is Some(Array(items)) else { return None }
  Some(
    items.filter_map(item => {
      match item {
        String(value) => Some(value)
        _ => None
      }
    }),
  )
}

///|
fn config_field(json : Map[String, Json], key : String) -> @types.Config? {
  match json.get(key) {
    Some(Object(config)) => Some(config)
    _ => None
  }
}

///|
/// Reads `icons` as a map from icon name to the SVG fragment drawn for it, as golden/README.md describes.
/// Only an object installs a resolver; a name without a string fragment resolves to nothing.
fn icons_field(json : Map[String, Json]) -> @types.IconResolver? {
  guard json.get("icons") is Some(Object(map)) else { return None }
  Some(name => {
    match map.get(name) {
      Some(String(fragment)) => Some(fragment)
      _ => None
    }
  })
}

///|
/// pele's `MathResolver` for a map from TeX, then font size as JavaScript writes it, to markup.
/// The markup is handed on unchecked, as pele checks it itself.
fn math_field(
  json : Map[String, Json],
  key : String,
) -> ((String, Double) -> Json?)? {
  guard json.get(key) is Some(Object(map)) else { return None }
  Some((tex, size) => {
    guard map.get(tex) is Some(Object(sizes)) &&
      sizes.get(@util.js_string(Json::number(size)))
      is Some(Object(_) as markup) else {
      return None
    }
    Some(markup)
  })
}

///|
/// Reads the theme that makes the SVG drawable by typst, or `None` when the options hold no theme object.
fn decode_theme(json : Json) -> Map[String, String]? {
  guard json is Object(fields) && fields.get("theme") is Some(Object(entries)) else {
    return None
  }
  let theme : Map[String, String] = Map([])
  for name, value in entries {
    if value is String(text) {
      theme[name] = text
    }
  }
  Some(theme)
}

///|
/// Reads pele's render options from their JSON form.
/// A key of the wrong type is ignored, so pele's default applies.
fn decode_options(json : Json) -> @types.RenderOptions {
  guard json is Object(fields) else { return @types.RenderOptions::default() }
  {
    font_family: string_field(fields, "fontFamily"),
    font_family_mono: string_field(fields, "fontFamilyMono"),
    font_size: number_field(fields, "fontSize"),
    id_prefix: string_field(fields, "idPrefix"),
    responsive: bool_field(fields, "responsive"),
    max_width: number_field(fields, "maxWidth"),
    auto_direction: bool_field(fields, "autoDirection"),
    direction_breakpoint: number_field(fields, "directionBreakpoint"),
    padding: number_field(fields, "padding"),
    limit: number_field(fields, "limit"),
    output_limit: number_field(fields, "outputLimit"),
    max_edges: number_field(fields, "maxEdges"),
    links: bool_field(fields, "links"),
    images: bool_field(fields, "images"),
    link_rel: string_field(fields, "linkRel"),
    link_schemes: strings_field(fields, "linkSchemes"),
    image_schemes: strings_field(fields, "imageSchemes"),
    config: config_field(fields, "config"),
    now: number_field(fields, "now"),
    measurer: decode_measurer(fields.get("measurer")),
    icons: icons_field(fields),
    math: math_field(fields, "math"),
  }
}
