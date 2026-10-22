// The host of an http URL as the WHATWG host parser writes it.
// UTS #46 mapping is reduced to what a diagram's link plausibly holds: ASCII and the common Latin, Greek and Cyrillic capitals are lowercased, fullwidth forms and ideographic full stops are folded, and a soft hyphen is dropped.
// Other mappings and NFC are not applied, so a host that relies on them is written differently from a browser.

///|
/// The bytes of `text` in UTF-8 with each `%XY` escape decoded, as the URL parser's percent-decode does.
fn percent_decoded(cps : Array[Int32]) -> Array[Int32] {
  let bytes = []
  for cp in cps {
    for byte in utf8_bytes(cp) {
      bytes.push(byte)
    }
  }
  let out = []
  let n = bytes.length()
  let mut i = 0
  while i < n {
    let byte = bytes[i]
    if byte == '%'.to_int() &&
      i + 2 < n &&
      @util.is_hex(bytes[i + 1]) &&
      @util.is_hex(bytes[i + 2]) {
      out.push(hex_value(bytes[i + 1]) * 16 + hex_value(bytes[i + 2]))
      i += 3
    } else {
      out.push(byte)
      i += 1
    }
  }
  out
}

///|
/// UTF-8 decoding that writes U+FFFD for each invalid sequence, as the WHATWG decoder does.
fn utf8_decoded(bytes : Array[Int32]) -> Array[Int32] {
  let out = []
  let n = bytes.length()
  let mut i = 0
  while i < n {
    let b = bytes[i]
    if b < 0x80 {
      out.push(b)
      i += 1
      continue
    }
    let (count, initial, lower, upper) = if b >= 0xc2 && b <= 0xdf {
      (1, b & 0x1f, 0x80, 0xbf)
    } else if b >= 0xe0 && b <= 0xef {
      (
        2,
        b & 0x0f,
        if b == 0xe0 {
          0xa0
        } else {
          0x80
        },
        if b == 0xed {
          0x9f
        } else {
          0xbf
        },
      )
    } else if b >= 0xf0 && b <= 0xf4 {
      (
        3,
        b & 0x07,
        if b == 0xf0 {
          0x90
        } else {
          0x80
        },
        if b == 0xf4 {
          0x8f
        } else {
          0xbf
        },
      )
    } else {
      out.push(0xfffd)
      i += 1
      continue
    }
    let mut cp = initial
    let mut j = i + 1
    let mut ok = true
    for k in 0..<count {
      let lo = if k == 0 { lower } else { 0x80 }
      let hi = if k == 0 { upper } else { 0xbf }
      if j >= n || bytes[j] < lo || bytes[j] > hi {
        ok = false
        break
      }
      cp = (cp << 6) | (bytes[j] & 0x3f)
      j += 1
    }
    if ok {
      out.push(cp)
    } else {
      out.push(0xfffd)
    }
    i = j
  }
  out
}

///|
/// The lowercase form of a capital in the scripts a host name is likely to use, else the code point itself.
fn lower_code_point(cp : Int32) -> Int32 {
  if cp >= 'A'.to_int() && cp <= 'Z'.to_int() {
    cp + 32
  } else if cp >= 0xc0 && cp <= 0xde && cp != 0xd7 {
    cp + 32
  } else if cp >= 0x100 && cp <= 0x137 && cp % 2 == 0 {
    cp + 1
  } else if cp >= 0x139 && cp <= 0x148 && cp % 2 == 1 {
    cp + 1
  } else if cp >= 0x14a && cp <= 0x177 && cp % 2 == 0 {
    cp + 1
  } else if cp == 0x178 {
    0xff
  } else if cp == 0x179 || cp == 0x17b || cp == 0x17d {
    cp + 1
  } else if cp >= 0x391 && cp <= 0x3a9 && cp != 0x3a2 {
    cp + 32
  } else if cp >= 0x410 && cp <= 0x42f {
    cp + 32
  } else if cp >= 0x400 && cp <= 0x40f {
    cp + 80
  } else {
    cp
  }
}

///|
/// The code point as the reduced UTS #46 mapping reads it: -1 to drop it, -2 for a disallowed one.
fn mapped_code_point(cp : Int32) -> Int32 {
  if cp == 0x3002 || cp == 0xff0e || cp == 0xff61 {
    '.'.to_int()
  } else if cp == 0xad {
    -1
  } else if cp >= 0xff01 && cp <= 0xff5e {
    lower_code_point(cp - 0xfee0)
  } else if cp == 0xfffd || (cp >= 0x80 && @util.is_space(cp)) {
    -2
  } else {
    lower_code_point(cp)
  }
}

///|
/// The Punycode encoding of a label, as RFC 3492 defines it.
fn punycode(label : Array[Int32]) -> String {
  let base = 36
  let tmin = 1
  let tmax = 26
  let out = StringBuilder()
  let digit = (d : Int32) => {
    if d < 26 {
      ('a'.to_int() + d).unsafe_to_char()
    } else {
      ('0'.to_int() + d - 26).unsafe_to_char()
    }
  }
  let adapt = (delta : Int32, points : Int32, first : Bool) => {
    let mut delta = if first { delta / 700 } else { delta / 2 }
    delta += delta / points
    let mut k = 0
    while delta > (base - tmin) * tmax / 2 {
      delta = delta / (base - tmin)
      k += base
    }
    k + (base - tmin + 1) * delta / (delta + 38)
  }
  let mut handled = 0
  for cp in label {
    if cp < 0x80 {
      out.write_char(cp.unsafe_to_char())
      handled += 1
    }
  }
  let basic = handled
  if basic > 0 {
    out.write_char('-')
  }
  let mut n = 0x80
  let mut delta = 0
  let mut bias = 72
  while handled < label.length() {
    let mut m = 0x7fffffff
    for cp in label {
      if cp >= n && cp < m {
        m = cp
      }
    }
    delta += (m - n) * (handled + 1)
    n = m
    for cp in label {
      if cp < n {
        delta += 1
      }
      if cp == n {
        let mut q = delta
        let mut k = base
        while true {
          let t = if k <= bias {
            tmin
          } else if k >= bias + tmax {
            tmax
          } else {
            k - bias
          }
          if q < t {
            break
          }
          out.write_char(digit(t + (q - t) % (base - t)))
          q = (q - t) / (base - t)
          k += base
        }
        out.write_char(digit(q))
        bias = adapt(delta, handled + 1, handled == basic)
        delta = 0
        handled += 1
      }
    }
    delta += 1
    n += 1
  }
  out.to_string()
}

///|
/// The domain in ASCII, or `None` for one the URL parser rejects.
fn domain_to_ascii(domain : Array[Int32]) -> String? {
  let out = StringBuilder()
  let label = []
  let flush = () => {
    if label.iter().any(cp => cp >= 0x80) {
      out.write_string("xn--")
      out.write_string(punycode(label))
    } else {
      for cp in label {
        out.write_char(cp.unsafe_to_char())
      }
    }
    label.clear()
  }
  for cp in domain {
    let mapped = mapped_code_point(cp)
    if mapped == -2 {
      return None
    }
    if mapped == -1 {
      continue
    }
    if mapped == '.'.to_int() {
      flush()
      out.write_char('.')
    } else {
      label.push(mapped)
    }
  }
  flush()
  let ascii = out.to_string()
  if ascii == "" {
    None
  } else {
    Some(ascii)
  }
}

///|
fn is_forbidden_domain_code_point(c : Int32) -> Bool {
  c <= 0x20 ||
  c == 0x7f ||
  c == '#'.to_int() ||
  c == '%'.to_int() ||
  c == '/'.to_int() ||
  c == ':'.to_int() ||
  c == '<'.to_int() ||
  c == '>'.to_int() ||
  c == '?'.to_int() ||
  c == '@'.to_int() ||
  c == '['.to_int() ||
  c == '\\'.to_int() ||
  c == ']'.to_int() ||
  c == '^'.to_int() ||
  c == '|'.to_int()
}

///|
/// Values beyond this are rejected wherever an IPv4 part appears, so larger ones need not be told apart.
const IPV4_CAP : Int64 = 0x200000000L

///|
/// An IPv4 number as the URL parser reads it: decimal, `0x` hexadecimal or leading-zero octal.
fn ipv4_number(part : String) -> Int64? {
  if part == "" {
    return None
  }
  let mut text = part
  let mut radix = 10
  if text.length() >= 2 && (text.has_prefix("0x") || text.has_prefix("0X")) {
    text = @util.slice(text, 2)
    radix = 16
  } else if text.length() >= 2 && text.has_prefix("0") {
    text = @util.slice(text, 1)
    radix = 8
  }
  let mut value = 0L
  for i in 0..<text.length() {
    let c = @util.code_at(text, i)
    let d = if @util.is_digit(c) {
      c - '0'.to_int()
    } else if @util.is_hex(c) {
      hex_value(c)
    } else {
      return None
    }
    if d >= radix {
      return None
    }
    value = value * radix.to_int64() + d.to_int64()
    if value > IPV4_CAP {
      value = IPV4_CAP
    }
  }
  Some(value)
}

///|
fn ends_in_number(host : String) -> Bool {
  let parts = host.split(".").map(p => p.to_owned()).collect()
  if parts.length() > 1 && parts[parts.length() - 1] == "" {
    ignore(parts.pop())
  }
  let last = parts[parts.length() - 1]
  if last != "" && last.iter().all(c => c >= '0' && c <= '9') {
    return true
  }
  ipv4_number(last) is Some(_)
}

///|
fn parse_ipv4(host : String) -> String? {
  let parts = host.split(".").map(p => p.to_owned()).collect()
  if parts.length() > 1 && parts[parts.length() - 1] == "" {
    ignore(parts.pop())
  }
  if parts.length() > 4 {
    return None
  }
  let numbers = []
  for part in parts {
    guard ipv4_number(part) is Some(number) else { return None }
    numbers.push(number)
  }
  let count = numbers.length()
  for i in 0..<(count - 1) {
    if numbers[i] > 255L {
      return None
    }
  }
  let limit = 1L << (8 * (5 - count))
  if numbers[count - 1] >= limit {
    return None
  }
  let mut address = numbers[count - 1]
  for i in 0..<(count - 1) {
    address += numbers[i] << (8 * (3 - i))
  }
  let octets = []
  for shift in [24, 16, 8, 0] {
    octets.push(((address >> shift) & 255L).to_string())
  }
  Some(octets.join("."))
}

///|
/// The serialized host of a special URL, or `None` for one the URL parser rejects.
/// An IPv6 literal is rejected too: its colons cannot reach here through sanitizeUrl.
fn parse_host(text : String) -> String? {
  if text.has_prefix("[") {
    return None
  }
  let domain = utf8_decoded(percent_decoded(code_points(text)))
  guard domain_to_ascii(domain) is Some(ascii) else { return None }
  for i in 0..<ascii.length() {
    if is_forbidden_domain_code_point(@util.code_at(ascii, i)) {
      return None
    }
  }
  if ends_in_number(ascii) {
    parse_ipv4(ascii)
  } else {
    Some(ascii)
  }
}
