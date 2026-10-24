// Mermaid asks the browser whether the first word of a box title is a color.
// pele has no browser, so it knows the color keywords and the rgb() and hsl() notations.
// Other functions, such as calc() and var(), are not recognized.

///|
const KEYWORDS : String = "aliceblue antiquewhite aqua aquamarine azure beige bisque black blanchedalmond blue blueviolet brown burlywood cadetblue chartreuse chocolate coral cornflowerblue cornsilk crimson cyan darkblue darkcyan darkgoldenrod darkgray darkgreen darkgrey darkkhaki darkmagenta darkolivegreen darkorange darkorchid darkred darksalmon darkseagreen darkslateblue darkslategray darkslategrey darkturquoise darkviolet deeppink deepskyblue dimgray dimgrey dodgerblue firebrick floralwhite forestgreen fuchsia gainsboro ghostwhite gold goldenrod gray green greenyellow grey honeydew hotpink indianred indigo ivory khaki lavender lavenderblush lawngreen lemonchiffon lightblue lightcoral lightcyan lightgoldenrodyellow lightgray lightgreen lightgrey lightpink lightsalmon lightseagreen lightskyblue lightslategray lightslategrey lightsteelblue lightyellow lime limegreen linen magenta maroon mediumaquamarine mediumblue mediumorchid mediumpurple mediumseagreen mediumslateblue mediumspringgreen mediumturquoise mediumvioletred midnightblue mintcream mistyrose moccasin navajowhite navy oldlace olive olivedrab orange orangered orchid palegoldenrod palegreen paleturquoise palevioletred papayawhip peachpuff peru pink plum powderblue purple rebeccapurple red rosybrown royalblue saddlebrown salmon sandybrown seagreen seashell sienna silver skyblue slateblue slategray slategrey snow springgreen steelblue tan teal thistle tomato turquoise violet wheat white whitesmoke yellow yellowgreen transparent currentcolor inherit initial unset revert accentcolor accentcolortext activetext buttonborder buttonface buttontext canvas canvastext field fieldtext graytext highlight highlighttext linktext mark marktext selecteditem selecteditemtext visitedtext activeborder activecaption appworkspace background buttonhighlight buttonshadow captiontext inactiveborder inactivecaption inactivecaptiontext infobackground infotext menu menutext scrollbar threeddarkshadow threedface threedhighlight threedlightshadow threedshadow window windowframe windowtext"

///|
/// Splits `text` at every `separator`, keeping empty pieces, as `String.prototype.split` does.
fn split_at(text : String, separator : String) -> Array[String] {
  let pieces = []
  let mut from = 0
  while true {
    let at = @util.index_of(text, separator, from~)
    if at == -1 {
      pieces.push(@util.slice(text, from))
      break
    }
    pieces.push(@util.slice(text, from, end=at))
    from = at + separator.length()
  }
  pieces
}

///|
let color_keywords : Set[String] = Set::from_array(split_at(KEYWORDS, " "))

///|
/// Lowercases as `toLowerCase` does for every result that can be a keyword: ASCII letters, and the Kelvin sign that becomes `k`.
fn keyword_lower(text : String) -> String {
  let out = StringBuilder()
  for i in 0..<text.length() {
    let c = @util.code_at(text, i)
    if c >= 65 && c <= 90 {
      out.write_char((c + 32).unsafe_to_char())
    } else if c == 0x212a {
      out.write_char('k')
    } else {
      @util.write_range(out, text, i, i + 1)
    }
  }
  out.to_string()
}

///|
priv enum TermKind {
  Bad
  Number
  Percent
  Angle
  NoneKeyword
}

///|
/// Classifies a term as `/^[+-]?(?:\d+(?:\.\d+)?|\.\d+)(?:e[+-]?\d+)?(%|deg|grad|rad|turn)?$/i` reads it.
fn term_kind(term : String) -> TermKind {
  let code = (q : Int32) => @util.code_at(term, q)
  if term.length() == 4 && keyword_lower(term) == "none" {
    return NoneKeyword
  }
  let mut i = 0
  if code(i) == 43 || code(i) == 45 {
    i += 1
  }
  let digits = i
  while @util.is_digit(code(i)) {
    i += 1
  }
  if i > digits {
    if code(i) == 46 && @util.is_digit(code(i + 1)) {
      i += 1
      while @util.is_digit(code(i)) {
        i += 1
      }
    }
  } else if code(i) == 46 && @util.is_digit(code(i + 1)) {
    i += 1
    while @util.is_digit(code(i)) {
      i += 1
    }
  } else {
    return Bad
  }
  if (code(i) | 32) == 101 {
    let mut j = i + 1
    if code(j) == 43 || code(j) == 45 {
      j += 1
    }
    let exponent = j
    while @util.is_digit(code(j)) {
      j += 1
    }
    if j > exponent {
      i = j
    }
  }
  let unit = @util.slice(term, i)
  if unit == "" {
    return Number
  }
  if unit == "%" {
    return Percent
  }
  // The /i flag folds ASCII letters only, so the Kelvin sign is not a `k` here, nor is any other character.
  let folded = StringBuilder()
  for k in 0..<unit.length() {
    let c = code(i + k)
    folded.write_char(
      (if c >= 65 && c <= 90 { c + 32 } else { c }).unsafe_to_char(),
    )
  }
  match folded.to_string() {
    "deg" | "grad" | "rad" | "turn" => Angle
    _ => Bad
  }
}

///|
fn is_alpha(term : String, modern : Bool) -> Bool {
  match term_kind(term) {
    Number | Percent => true
    NoneKeyword => modern
    _ => false
  }
}

///|
/// Splits trimmed text at runs of whitespace, as `split(/\s+/)` does.
fn split_spaces(text : String) -> Array[String] {
  let pieces = []
  let mut start = 0
  let mut i = 0
  while i < text.length() {
    if @util.is_space(@util.code_at(text, i)) {
      pieces.push(@util.slice(text, start, end=i))
      while i < text.length() && @util.is_space(@util.code_at(text, i)) {
        i += 1
      }
      start = i
    } else {
      i += 1
    }
  }
  pieces.push(@util.slice(text, start))
  pieces
}

///|
fn is_color_function(color : String) -> Bool {
  let hsl = color.has_prefix("hsl")
  let open = @util.index_of(color, "(")
  let name = @util.slice(color, 0, end=open)
  if name != "rgb" && name != "rgba" && name != "hsl" && name != "hsla" {
    return false
  }
  if color.length() > 120 || @util.index_of(color, ")") != color.length() - 1 {
    return false
  }
  let inner = @util.trim(@util.slice(color, open + 1, end=-1))
  let legacy = @util.index_of(inner, ",") != -1
  let mut alpha : String? = None
  let parts = if legacy {
    let parts = split_at(inner, ",").map(@util.trim)
    if parts.length() == 4 {
      alpha = parts.pop()
    }
    parts
  } else {
    let slash = split_at(inner, "/")
    if slash.length() > 2 {
      return false
    }
    if slash.length() == 2 {
      alpha = Some(@util.trim(slash[1]))
    }
    split_spaces(@util.trim(slash[0]))
  }
  if parts.length() != 3 {
    return false
  }
  if alpha is Some(alpha) && !is_alpha(alpha, !legacy) {
    return false
  }
  let kinds = parts.map(term_kind)
  if legacy {
    if hsl {
      return kinds[0] is (Number | Angle) &&
        kinds[1] is Percent &&
        kinds[2] is Percent
    }
    return match (kinds[0], kinds[1], kinds[2]) {
      (Number, Number, Number) | (Percent, Percent, Percent) => true
      _ => false
    }
  }
  for i, kind in kinds {
    let ok = match kind {
      Number | NoneKeyword => true
      Angle => hsl && i == 0
      Percent => !(hsl && i == 0)
      Bad => false
    }
    if !ok {
      return false
    }
  }
  true
}

///|
/// Whether a browser would take `color` as a CSS color.
pub fn is_css_color(color : String) -> Bool {
  if @util.index_of(color, "(") != -1 {
    return is_color_function(color)
  }
  color_keywords.contains(keyword_lower(color))
}
