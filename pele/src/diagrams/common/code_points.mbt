///|
/// Where each code point of `text` starts, followed by the length of the text, as `Array.from` splits it:
/// a surrogate pair is one code point and a lone surrogate is one of its own.
pub fn code_point_starts(text : String) -> Array[Int32] {
  let starts = []
  let n = text.length()
  let mut i = 0
  while i < n {
    starts.push(i)
    let c = text.unsafe_get(i).to_int()
    if c >= 0xd800 && c <= 0xdbff && i + 1 < n {
      let d = text.unsafe_get(i + 1).to_int()
      i += if d >= 0xdc00 && d <= 0xdfff { 2 } else { 1 }
    } else {
      i += 1
    }
  }
  starts.push(n)
  starts
}

///|
/// How many code points `text` holds, a surrogate pair counting as one.
fn code_point_count(text : String) -> Int32 {
  let n = text.length()
  let mut count = n
  for i in 0..<(n - 1) {
    let c = text.unsafe_get(i).to_int()
    if c >= 0xd800 && c <= 0xdbff {
      let d = text.unsafe_get(i + 1).to_int()
      if d >= 0xdc00 && d <= 0xdfff {
        count -= 1
      }
    }
  }
  count
}
