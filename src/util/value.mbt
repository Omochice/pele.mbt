///|
/// The value as JavaScript's `String()` writes it.
pub fn js_string(value : Json) -> String {
  match value {
    Null => "null"
    True => "true"
    False => "false"
    Number(number, ..) => number.to_string()
    String(text) => text
    Array(items) => {
      let out = StringBuilder()
      for i, item in items {
        if i > 0 {
          out.write_string(",")
        }
        if !(item is Null) {
          out.write_string(js_string(item))
        }
      }
      out.to_string()
    }
    Object(_) => "[object Object]"
  }
}

///|
/// Whether JavaScript treats the value as true in a condition.
pub fn js_truthy(value : Json) -> Bool {
  match value {
    Null | False => false
    Number(number, ..) => !(number == 0 || number.is_nan())
    String(text) => text != ""
    _ => true
  }
}
