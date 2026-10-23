///|
/// Diagram configuration from front matter and directives, keyed as in Mermaid's config.
pub type Config = Map[String, Json]

///|
/// The subset of pele's `RenderOptions` that the port takes.
/// `None` selects pele's default.
pub(all) struct RenderOptions {
  font_family : String?
  font_family_mono : String?
  font_size : Double?
  id_prefix : String?
  responsive : Bool?
  max_width : Double?
  auto_direction : Bool?
  direction_breakpoint : Double?
  padding : Double?
  limit : Double?
  output_limit : Double?
  max_edges : Double?
  links : Bool?
  images : Bool?
  link_rel : String?
  link_schemes : Array[String]?
  image_schemes : Array[String]?
  config : Config?
  now : Double?
  measurer : @text.TextMeasurer?
}

///|
/// Options with every field unset.
pub fn RenderOptions::default() -> RenderOptions {
  {
    font_family: None,
    font_family_mono: None,
    font_size: None,
    id_prefix: None,
    responsive: None,
    max_width: None,
    auto_direction: None,
    direction_breakpoint: None,
    padding: None,
    limit: None,
    output_limit: None,
    max_edges: None,
    links: None,
    images: None,
    link_rel: None,
    link_schemes: None,
    image_schemes: None,
    config: None,
    now: None,
    measurer: None,
  }
}

///|
/// The measurer labels are laid out with, as pele's `options.measurer ?? defaultMeasurer(fontFamily)`.
/// pele's default falls back to its Arial table where no canvas exists, as in a plugin, so the font family never changes a width.
pub fn RenderOptions::text_measurer(self : RenderOptions) -> @text.TextMeasurer {
  self.measurer.unwrap_or(@text.metrics_measurer)
}

///|
/// A link a diagram draws, as pele's `LinkInfo`.
pub(all) struct LinkInfo {
  id : String
  href : String
  internal : Bool
}

///|
/// A drawn diagram. Dimensions are in pixels.
pub(all) struct Rendered {
  svg : String
  width : Double
  height : Double
  links : Array[LinkInfo]
}

///|
/// A drawn diagram with the type it was detected as.
pub(all) struct RenderResult {
  kind : String
  mermaid_type : String
  svg : String
  width : Double
  height : Double
  links : Array[LinkInfo]
}
