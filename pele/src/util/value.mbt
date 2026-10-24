///|
/// The value as JavaScript's `String()` writes it.
/// Arrays are written however deeply they nest, although pele's `String()` fails where V8 runs out of stack, because that depth varies with the platform and the process and is not a limit pele chose.
pub fn js_string(value : Json) -> String {
  match value {
    Null => "null"
    True => "true"
    False => "false"
    Number(number, ..) => number.to_string()
    String(text) => text
    Array(items) => join_nested(items)
    Object(_) => "[object Object]"
  }
}

///|
/// The items joined by commas, with nested arrays joined in place and null written as nothing.
/// The arrays being joined wait on a stack of their own, so nesting is limited by memory and not by the call stack.
fn join_nested(items : Array[Json]) -> String {
  let out = StringBuilder()
  let lists = [items]
  let next = [0]
  while lists.last() is Some(list) {
    let top = lists.length() - 1
    let i = next[top]
    if i >= list.length() {
      lists.pop() |> ignore
      next.pop() |> ignore
      continue
    }
    next[top] = i + 1
    if i > 0 {
      out.write_string(",")
    }
    match list[i] {
      Null => ()
      Array(inner) => {
        lists.push(inner)
        next.push(0)
      }
      item => out.write_string(js_string(item))
    }
  }
  out.to_string()
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

///|
/// The value as JavaScript's `Number()` converts it.
pub fn js_number(value : Json) -> Double {
  match value {
    Null | False => 0
    True => 1
    Number(number, ..) => number
    String(text) => to_number(text)
    Array(_) => to_number(js_string(value))
    Object(_) => @double.not_a_number
  }
}
