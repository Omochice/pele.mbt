///|
/// Whether Mermaid accepts `name` as a shape in node data.
pub fn is_valid_shape(name : String) -> Bool {
  ignore(name)
  false
}

///|
/// The documented short name of a shape, `rect` for none or an unknown one.
pub fn canonical_shape(name : String?) -> String {
  ignore(name)
  ""
}
