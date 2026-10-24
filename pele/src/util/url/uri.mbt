///|
fn hex_value(c : Int32) -> Int32 {
  if c >= '0'.to_int() && c <= '9'.to_int() {
    c - '0'.to_int()
  } else if c >= 'a'.to_int() && c <= 'f'.to_int() {
    c - 'a'.to_int() + 10
  } else {
    c - 'A'.to_int() + 10
  }
}

///|
/// The byte that `%XY` at `at` spells, or -1 when there is no such escape there.
fn escaped_byte(text : String, at : Int32) -> Int32 {
  if @util.code_at(text, at) != '%'.to_int() {
    return -1
  }
  let hi = @util.code_at(text, at + 1)
  let lo = @util.code_at(text, at + 2)
  if !@util.is_hex(hi) || !@util.is_hex(lo) {
    return -1
  }
  hex_value(hi) * 16 + hex_value(lo)
}

///|
/// `decodeURIComponent`, or `None` where it throws a URIError.
fn decode_uri_component(text : String) -> String? {
  let out = StringBuilder()
  let n = text.length()
  let mut k = 0
  while k < n {
    if @util.code_at(text, k) != '%'.to_int() {
      @util.write_range(out, text, k, k + 1)
      k += 1
      continue
    }
    let lead = escaped_byte(text, k)
    if lead < 0 {
      return None
    }
    k += 3
    if lead < 0x80 {
      out.write_char(lead.unsafe_to_char())
      continue
    }
    let (count, initial) = if (lead & 0xe0) == 0xc0 {
      (2, lead & 0x1f)
    } else if (lead & 0xf0) == 0xe0 {
      (3, lead & 0x0f)
    } else if (lead & 0xf8) == 0xf0 {
      (4, lead & 0x07)
    } else {
      return None
    }
    let mut cp = initial
    for _ in 1..<count {
      let byte = escaped_byte(text, k)
      if byte < 0 || (byte & 0xc0) != 0x80 {
        return None
      }
      cp = (cp << 6) | (byte & 0x3f)
      k += 3
    }
    let least = match count {
      2 => 0x80
      3 => 0x800
      _ => 0x10000
    }
    if cp < least || cp > 0x10ffff || (cp >= 0xd800 && cp <= 0xdfff) {
      return None
    }
    out.write_char(cp.unsafe_to_char())
  }
  Some(out.to_string())
}
