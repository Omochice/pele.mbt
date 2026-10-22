///|
/// Decodes a packed table of code ranges into sorted start and end pairs laid out flat.
/// The table holds base-36 gaps from the previous range's end and range lengths, alternating, separated by spaces or line breaks.
fn unpack_ranges(packed : String) -> Array[Int32] {
  let out = []
  let mut prev = 0
  let parts = packed.replace_all(old="\n", new=" ").split(" ").to_array()
  for i = 0; i + 1 < parts.length(); i = i + 2 {
    let start = prev + base36_value(parts[i])
    prev = start + base36_value(parts[i + 1])
    out.push(start)
    out.push(prev)
  }
  out
}

///|
fn base36_value(digits : StringView) -> Int32 {
  let mut value = 0
  for c in digits {
    let d = if c >= '0' && c <= '9' {
      c.to_int() - '0'.to_int()
    } else {
      c.to_int() - 'a'.to_int() + 10
    }
    value = value * 36 + d
  }
  value
}

///|
/// Whether `code` lies in one of the ranges that `unpack_ranges` decoded.
fn in_ranges(ranges : Array[Int32], code : Int32) -> Bool {
  let mut lo = 0
  let mut hi = ranges.length() / 2 - 1
  while lo <= hi {
    let mid = (lo + hi) / 2
    if code < ranges[mid * 2] {
      hi = mid - 1
    } else if code > ranges[mid * 2 + 1] {
      lo = mid + 1
    } else {
      return true
    }
  }
  false
}
