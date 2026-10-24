///|
/// JavaScript's `a || b` on numbers: `b` when `a` is 0 or NaN.
/// Pele chains comparisons this way to break ties.
fn or_else(a : Double, b : Double) -> Double {
  if a == 0.0 || a.is_nan() {
    b
  } else {
    a
  }
}

///|
/// Sorts `list[from:to]` stably, as V8 sorts with a comparator: `b` goes before `a` only when `compare(b, a) < 0`.
/// With a consistent comparator this gives the one order that V8's stable sort gives, whatever algorithm does it.
fn[T] sort_range(
  list : FixedArray[T],
  from : Int32,
  to : Int32,
  compare : (T, T) -> Double,
) -> Unit {
  let count = to - from
  if count < 2 {
    return
  }
  let mut src = Array::makei(count, i => list[from + i])
  let mut dst = src.copy()
  let mut width = 1
  while width < count {
    let mut s = 0
    while s < count {
      let mid = if s + width < count { s + width } else { count }
      let end = if s + 2 * width < count { s + 2 * width } else { count }
      let mut i = s
      let mut j = mid
      let mut k = s
      while i < mid && j < end {
        if compare(src[j], src[i]) < 0.0 {
          dst[k] = src[j]
          j += 1
        } else {
          dst[k] = src[i]
          i += 1
        }
        k += 1
      }
      while i < mid {
        dst[k] = src[i]
        i += 1
        k += 1
      }
      while j < end {
        dst[k] = src[j]
        j += 1
        k += 1
      }
      s += 2 * width
    }
    let t = src
    src = dst
    dst = t
    width *= 2
  }
  for i in 0..<count {
    list[from + i] = src[i]
  }
}

///|
/// Sorts an array stably, as `sort_range` does.
fn[T] sort_array(list : Array[T], compare : (T, T) -> Double) -> Unit {
  let count = list.length()
  if count < 2 {
    return
  }
  let items = FixedArray::makei(count, i => list[i])
  sort_range(items, 0, count, compare)
  for i in 0..<count {
    list[i] = items[i]
  }
}
