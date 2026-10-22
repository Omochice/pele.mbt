///|
/// FNV-1a over UTF-16 code units, the hash under which the expected outputs in this package's tests were taken from pele.
fn fnv1a(text : String) -> String {
  let mut h : UInt32 = 0x811c9dc5U
  for i in 0..<text.length() {
    h = (h ^ text.unsafe_get(i).to_int().reinterpret_as_uint()) * 0x01000193U
  }
  let digits = "0123456789abcdef"
  let out = StringBuilder()
  for shift in [28, 24, 20, 16, 12, 8, 4, 0] {
    let d = ((h >> shift) & 0xfU).reinterpret_as_int()
    out.write_char(digits.get_char(d).unwrap())
  }
  out.to_string()
}

///|
/// Every string of exactly `length` pieces drawn from `pieces`, in lexicographic order of piece indices.
fn strings_over(pieces : Array[String], length : Int32) -> Array[String] {
  let mut out = [""]
  for _ in 0..<length {
    let next = []
    for prefix in out {
      for piece in pieces {
        next.push(prefix + piece)
      }
    }
    out = next
  }
  out
}
