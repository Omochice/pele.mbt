///|
priv enum T {
  End
  Eof
  Spaceline
  Nl
  Ishikawa
  Spacelist
  Text
}

///|
fn T::name(self : T) -> String {
  match self {
    End => "$end"
    Eof => "EOF"
    Spaceline => "SPACELINE"
    Nl => "NL"
    Ishikawa => "ISHIKAWA"
    Spacelist => "SPACELIST"
    Text => "TEXT"
  }
}

///|
priv struct Tokens {
  types : Array[T]
  starts : Array[Int32]
  ends : Array[Int32]
}

///|
/// The length of `ishikawa-beta`, or failing that `ishikawa`, matched without regard to case and
/// ending at a word boundary; 0 when neither matches.
fn keyword(src : String, at : Int32) -> Int32 {
  let word = "ishikawa-beta"
  let mut k = 0
  while k < 13 {
    let c = @util.code_at(src, at + k)
    let w = word[k].to_int()
    if c != w && (c + 32 != w || c < 65 || c > 90) {
      break
    }
    k += 1
  }
  if k == 13 && !@util.is_word(@util.code_at(src, at + 13)) {
    return 13
  }
  if k >= 8 && !@util.is_word(@util.code_at(src, at + 8)) {
    8
  } else {
    0
  }
}

///|
fn is_line_terminator(c : Int32) -> Bool {
  c == 10 || c == 13 || c == 0x2028 || c == 0x2029
}

///|
/// Produces the tokens of Mermaid's Jison lexer for Ishikawa diagrams, where the first rule that
/// matches wins.
/// White space up to a comment or up to the last line break in it is a blank line, a single line
/// break before text is a new line, other white space is indentation, and the rest of a line is text.
fn tokenize(src : String) -> Tokens {
  let types = []
  let starts = []
  let ends = []
  let n = src.length()
  let mut i = 0
  while i < n {
    let mut j = i
    let mut last_break = -1
    while j < n && @util.is_space(@util.code_at(src, j)) {
      if @util.code_at(src, j) == 10 {
        last_break = j
      }
      j += 1
    }
    let mut type_ = T::Text
    let mut end = 0
    if @util.code_at(src, j) == 37 && @util.code_at(src, j + 1) == 37 {
      type_ = Spaceline
      end = j + 2
      while end < n && !is_line_terminator(@util.code_at(src, end)) {
        end += 1
      }
    } else if j == i {
      let length = keyword(src, i)
      if length > 0 {
        type_ = Ishikawa
        end = i + length
      } else {
        type_ = Text
        end = @util.index_of(src, "\n", from=i)
        if end == -1 {
          end = n
        }
      }
    } else if last_break > i {
      type_ = Spaceline
      end = last_break + 1
    } else if last_break == i {
      type_ = Nl
      end = i + 1
    } else {
      type_ = Spacelist
      end = j
    }
    types.push(type_)
    starts.push(i)
    ends.push(end)
    i = end
  }
  types.push(Eof)
  types.push(End)
  starts.push(n)
  starts.push(n)
  ends.push(n)
  ends.push(n)
  { types, starts, ends, }
}
