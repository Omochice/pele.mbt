///|
/// A value of a `json` node, with the keys of each object in the order they were first written.
pub(all) enum JsonValue {
  JsonNull
  JsonBool(Bool)
  JsonNumber(Double)
  JsonString(String)
  JsonArray(Array[JsonValue])
  /// A key written more than once keeps its first place and takes its last value, as `JSON.parse` does.
  JsonObject(Array[(String, JsonValue)])
}

///|
/// Reads the body of a `json` node, which has to be an object.
/// `origin` gives the line and column the text starts at in the diagram, for the error.
pub fn parse_ordered_json(
  _text : String,
  _origin : () -> (Int32, Int32),
) -> Array[(String, JsonValue)] raise @errors.PeleError {
  raise @errors.pele_error("not implemented")
}
