///|
/// Named entities that labels may use, as `name:code point` pairs.
let named_packed = "amp:38,lt:60,gt:62,quot:34,apos:39,nbsp:160,shy:173,iexcl:161,cent:162,pound:163,curren:164,yen:165,sect:167,copy:169,laquo:171,not:172,reg:174,deg:176,plusmn:177,sup2:178,sup3:179,micro:181,para:182,middot:183,sup1:185,raquo:187,frac14:188,frac12:189,frac34:190,iquest:191,times:215,divide:247,ndash:8211,mdash:8212,lsquo:8216,rsquo:8217,sbquo:8218,ldquo:8220,rdquo:8221,bdquo:8222,dagger:8224,Dagger:8225,bull:8226,hellip:8230,permil:8240,prime:8242,Prime:8243,lsaquo:8249,rsaquo:8250,euro:8364,trade:8482,larr:8592,uarr:8593,rarr:8594,darr:8595,harr:8596,lArr:8656,uArr:8657,rArr:8658,dArr:8659,hArr:8660,forall:8704,part:8706,exist:8707,empty:8709,nabla:8711,isin:8712,notin:8713,ni:8715,prod:8719,sum:8721,minus:8722,radic:8730,infin:8734,and:8743,or:8744,cap:8745,cup:8746,int:8747,there4:8756,sim:8764,cong:8773,asymp:8776,ne:8800,equiv:8801,le:8804,ge:8805,sub:8834,sup:8835,sube:8838,supe:8839,oplus:8853,otimes:8855,perp:8869,sdot:8901,loz:9674,spades:9824,clubs:9827,hearts:9829,diams:9830,check:10003,cross:10007,AMP:38,LT:60,GT:62,QUOT:34,lsqb:91,rsqb:93,lcub:123,rcub:125,verbar:124,VerticalLine:124,midast:42,DiacriticalGrave:96,Hat:94,UnderBar:95,equals:61,colon:58,semi:59,num:35,percnt:37,lpar:40,rpar:41,lbrack:91,rbrack:93,lbrace:123,rbrace:125,vert:124,sol:47,bsol:92,quest:63,excl:33,ast:42,plus:43,comma:44,period:46,dollar:36,commat:64,grave:96,hat:94,lowbar:95,tilde:126,Alpha:913,Beta:914,Gamma:915,Delta:916,Epsilon:917,Zeta:918,Eta:919,Theta:920,Iota:921,Kappa:922,Lambda:923,Mu:924,Nu:925,Xi:926,Omicron:927,Pi:928,Rho:929,Sigma:931,Tau:932,Upsilon:933,Phi:934,Chi:935,Psi:936,Omega:937,alpha:945,beta:946,gamma:947,delta:948,epsilon:949,zeta:950,eta:951,theta:952,iota:953,kappa:954,lambda:955,mu:956,nu:957,xi:958,omicron:959,pi:960,rho:961,sigmaf:962,sigma:963,tau:964,upsilon:965,phi:966,chi:967,psi:968,omega:969"

///|
let named : Map[String, Int32] = {
  let out = Map([])
  for pair in named_packed.split(",") {
    guard pair.split_once(":") is Some((name, code)) else { continue }
    out[name.to_owned()] = @string.parse_int(code) catch { _ => 0 }
  }
  out
}

///|
fn from_code_point(n : Int32) -> String {
  let out = StringBuilder()
  out.write_char(Int32::unsafe_to_char(n))
  out.to_string()
}

///|
/// The character of a numeric entity, or `None` for one that names no character.
fn code_point(digits : String, base : Int32) -> String? {
  let mut value = 0
  for i in 0..<digits.length() {
    let c = @util.code_at(digits, i)
    let d = if c <= '9'.to_int() {
      c - '0'.to_int()
    } else if c >= 'a'.to_int() {
      c - 'a'.to_int() + 10
    } else {
      c - 'A'.to_int() + 10
    }
    value = value * base + d
    if value > 0x10ffff {
      return None
    }
  }
  if value > 0 && (value < 0xd800 || value > 0xdfff) {
    Some(from_code_point(value))
  } else {
    None
  }
}

///|
/// The entity starting with `&` at `at`: where it ends and its characters, or `None`.
/// Answers as `&(?:#(\d+)|#[xX]([0-9a-fA-F]+)|(\w+));` does.
fn entity_at(text : String, at : Int32) -> (Int32, String)? {
  let end_of = (from : Int32, accept : (Int32) -> Bool) => {
    let mut i = from
    while accept(@util.code_at(text, i)) {
      i += 1
    }
    i
  }
  let terminated = (from : Int32, to : Int32) => {
    to > from && @util.code_at(text, to) == ';'.to_int()
  }
  let whole = (to : Int32, value : String?) => {
    match value {
      Some(chars) => Some((to + 1, chars))
      None => Some((to + 1, @util.slice(text, at, end=to + 1)))
    }
  }
  if @util.code_at(text, at + 1) == '#'.to_int() {
    let dec_end = end_of(at + 2, @util.is_digit)
    if terminated(at + 2, dec_end) {
      return whole(
        dec_end,
        code_point(@util.slice(text, at + 2, end=dec_end), 10),
      )
    }
    let x = @util.code_at(text, at + 2)
    if x == 'x'.to_int() || x == 'X'.to_int() {
      let hex_end = end_of(at + 3, @util.is_hex)
      if terminated(at + 3, hex_end) {
        return whole(
          hex_end,
          code_point(@util.slice(text, at + 3, end=hex_end), 16),
        )
      }
    }
    return None
  }
  let name_end = end_of(at + 1, @util.is_word)
  if !terminated(at + 1, name_end) {
    return None
  }
  whole(
    name_end,
    named.get(@util.slice(text, at + 1, end=name_end)).map(from_code_point),
  )
}

///|
/// Mermaid's placeholders run from `ﬂ°` to `¶ß`, with a second `°` marking a numeric code.
/// Like Mermaid, they are turned back into entities, so that each code is decoded once.
fn restore_placeholders(text : String) -> String {
  let out = StringBuilder()
  let mut last = 0
  let mut from = @util.index_of(text, "\u{fb02}\u{b0}")
  while from != -1 {
    let stop = @util.index_of(text, "\u{b6}", from=from + 2)
    if stop == -1 {
      break
    }
    if @util.code_at(text, stop + 1) == 0xdf {
      let numeric = @util.code_at(text, from + 2) == 0xb0
      @util.write_range(out, text, last, from)
      out.write_string(if numeric { "&#" } else { "&" })
      @util.write_range(out, text, from + (if numeric { 3 } else { 2 }), stop)
      out.write_string(";")
      last = stop + 2
    }
    from = @util.index_of(text, "\u{fb02}\u{b0}", from=stop + 1)
  }
  if last == 0 {
    return text
  }
  @util.write_range(out, text, last, text.length())
  out.to_string()
}

///|
/// The end of `ﬂ°°?\w+¶ß` at `i`, or -1.
pub fn marker_end(text : String, i : Int32) -> Int32 {
  if @util.code_at(text, i) != 0xfb02 || @util.code_at(text, i + 1) != '°' {
    return -1
  }
  let mut k = i + 2
  if @util.code_at(text, k) == '°' {
    k += 1
  }
  let word = k
  while @util.is_word(@util.code_at(text, k)) {
    k += 1
  }
  if k > word && @util.starts_with_at(text, "¶ß", k) {
    k + 2
  } else {
    -1
  }
}

///|
/// `text` with each of Mermaid's placeholders written back as the `#name;` or `#123;` code it hides,
/// as `/ﬂ°°?(\w+)¶ß/g` finds them.
pub fn written_codes(text : String) -> String {
  if !text.contains("\u{b6}\u{df}") {
    return text
  }
  let out = StringBuilder()
  let mut last = 0
  let mut from = @util.index_of(text, "\u{fb02}\u{b0}")
  while from != -1 {
    let end = marker_end(text, from)
    if end != -1 {
      let start = if @util.code_at(text, from + 2) == 0xb0 {
        from + 3
      } else {
        from + 2
      }
      @util.write_range(out, text, last, from)
      out.write_string("#")
      @util.write_range(out, text, start, end - 2)
      out.write_string(";")
      last = end
      from = @util.index_of(text, "\u{fb02}\u{b0}", from=last)
    } else {
      from = @util.index_of(text, "\u{fb02}\u{b0}", from=from + 1)
    }
  }
  if last == 0 {
    return text
  }
  @util.write_range(out, text, last, text.length())
  out.to_string()
}

///|
/// Turns Mermaid's hidden `#name;` codes and HTML entities into characters.
pub fn decode_entities(text : String) -> String {
  let restored = if text.contains("\u{b6}\u{df}") {
    restore_placeholders(text)
  } else {
    text
  }
  if !restored.contains("&") {
    return restored
  }
  let out = StringBuilder()
  let mut last = 0
  let mut at = @util.index_of(restored, "&")
  while at != -1 {
    match entity_at(restored, at) {
      Some((end, chars)) => {
        @util.write_range(out, restored, last, at)
        out.write_string(chars)
        last = end
        at = @util.index_of(restored, "&", from=end)
      }
      None => at = @util.index_of(restored, "&", from=at + 1)
    }
  }
  if last == 0 {
    return restored
  }
  @util.write_range(out, restored, last, restored.length())
  out.to_string()
}
