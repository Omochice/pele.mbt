///|
fn quote(text : String) -> String {
  Json(text).stringify()
}

///|
fn shown(text : String?) -> String {
  match text {
    Some(text) => quote(text)
    None => "none"
  }
}
