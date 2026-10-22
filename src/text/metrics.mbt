///|
/// Advance widths of printable ASCII in thousandths of an em, two base-36 digits each.
/// Copied from pele, which generates them from Arial.
let regular_packed = "7q7q9vfgfgopij5b9999atg87q997q7qfgfgfgfgfgfgfgfgfgfg7q7qg8g8g8fgs7ijijk2k2ijgzlmk27qdwijfgn5k2lmijlmk2ijgzk2ijq8ijijgz7q7q7qd1fg99fgfgdwfgfg7qfgfg6666dw66n5fgfgfgfg99dw7qfgdwk2dwdwdw9a789ag8"

///|
let bold_packed = "7q99d6fgfgopk26m9999atg87q997q7qfgfgfgfgfgfgfgfgfgfg9999g8g8g8gzr3k2k2k2k2ijgzlmk27qfgk2gzn5k2lmijlmk2ijgzk2ijq8ijijgz997q99g8fg99fggzfggzfg99gzgz7q7qfg7qopgzgzgzgzatfg99gzfglmfgfgdwat7satg8"

///|
fn base36(c : Int32) -> Int32 {
  if c >= 48 && c <= 57 {
    c - 48
  } else {
    c - 97 + 10
  }
}

///|
fn unpack(packed : String) -> FixedArray[Int32] {
  FixedArray::makei(95, i => {
    base36(packed.unsafe_get(i * 2).to_int()) * 36 +
    base36(packed.unsafe_get(i * 2 + 1).to_int())
  })
}

///|
let regular_advances : FixedArray[Int32] = unpack(regular_packed)

///|
let bold_advances : FixedArray[Int32] = unpack(bold_packed)
