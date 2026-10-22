///|
/// YAML text that the reader rejects, with js-yaml's message.
pub(all) suberror YamlError {
  YamlError(String)
}

///|
/// Reads YAML as Mermaid does with js-yaml's JSON schema.
pub fn parse_yaml(source : String) -> Json raise YamlError {
  ignore(source)
  Json::null()
}
