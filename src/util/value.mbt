///|
/// The value as JavaScript's `String()` writes it.
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
/// How deeply arrays may nest for pele's `String()` to write them.
/// V8 joins nested arrays by recursion, so in pele a deeper value runs out of stack and fails as nested too deeply.
/// The depth it reaches is the engine's: node 24 with its default stack writes 2,816 levels and fails at 2,818, against about 850 with a 300 KB stack and 11,500 with 4 MB.
/// The bound is a round number just under node's default, so whatever is written here pele writes there too, and nothing short of hostile input nests arrays this deep.
pub const JS_STRING_MAX_DEPTH : Int32 = 2800

///|
/// Whether `value` nests arrays deeper than pele's `String()` can write, see `JS_STRING_MAX_DEPTH`.
pub fn js_string_too_deep(value : Json) -> Bool {
  guard value is Array(items) else { return false }
  let lists = [items]
  let depths = [1]
  while lists.pop() is Some(list) {
    let depth = depths.pop().unwrap()
    if depth > JS_STRING_MAX_DEPTH {
      return true
    }
    for item in list {
      if item is Array(inner) {
        lists.push(inner)
        depths.push(depth + 1)
      }
    }
  }
  false
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
