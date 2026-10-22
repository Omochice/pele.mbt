///|
/// Replaces each run of at least two code units accepted by `inside` with `with`.
fn collapse_runs(
  text : String,
  inside : (Int32) -> Bool,
  replacement : String,
) -> String {
  let out = StringBuilder()
  let mut i = 0
  let mut last = 0
  while i < text.length() {
    if !inside(@util.code_at(text, i)) {
      i += 1
      continue
    }
    let start = i
    while inside(@util.code_at(text, i)) {
      i += 1
    }
    if i - start >= 2 {
      @util.write_range(out, text, last, start)
      out.write_string(replacement)
      last = i
    }
  }
  @util.write_range(out, text, last, text.length())
  out.to_string()
}

///|
fn single(text : String) -> String {
  collapse_runs(@util.trim(text), @util.is_blank, " ")
}

///|
/// The rest of the line after `keyword` and the blanks and colon that may follow it.
fn after_keyword(text : String, keyword : String, colon : Bool) -> String {
  let at = @util.index_of(text, keyword)
  let mut i = at + keyword.length()
  if colon {
    while @util.is_blank(@util.code_at(text, i)) {
      i += 1
    }
    i += 1
  } else if !@util.is_blank(@util.code_at(text, i)) {
    return ""
  }
  let mut end = i
  while end < text.length() && !is_line_break(@util.code_at(text, end)) {
    end += 1
  }
  @util.slice(text, i, end~)
}

///|
fn is_line_break(c : Int32) -> Bool {
  c == '\n'.to_int() || c == '\r'.to_int()
}

///|
/// The title a `TITLE` token gives.
pub fn title_value(text : String) -> String {
  single(after_keyword(text, "title", false))
}

///|
/// The title an `ACC_TITLE` token gives.
pub fn acc_title_value(text : String) -> String {
  single(after_keyword(text, "accTitle", true))
}

///|
/// Does what `text.replace(/^\s*/gm, '')` does.
fn strip_line_starts(text : String) -> String {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    if i == 0 || @util.is_line_end(@util.code_at(text, i - 1)) {
      let start = i
      while @util.is_space(@util.code_at(text, i)) {
        i += 1
      }
      if i > start {
        continue
      }
    }
    @util.write_range(out, text, i, i + 1)
    i += 1
  }
  out.to_string()
}

///|
/// Does what `text.replace(/\s+$/gm, '')` does: in each run of whitespace, everything up to the
/// last line end in the run, or to the end of the text, goes.
fn strip_line_ends(text : String) -> String {
  let out = StringBuilder()
  let n = text.length()
  let mut i = 0
  while i < n {
    if !@util.is_space(@util.code_at(text, i)) {
      @util.write_range(out, text, i, i + 1)
      i += 1
      continue
    }
    let start = i
    while @util.is_space(@util.code_at(text, i)) {
      i += 1
    }
    let mut cut = -1
    for k in (start + 1)..<=i {
      if k == n || @util.is_line_end(@util.code_at(text, k)) {
        cut = k
      }
    }
    @util.write_range(out, text, if cut == -1 { start } else { cut }, i)
  }
  out.to_string()
}

///|
/// The description an `ACC_DESCR` token gives, on one line or in braces.
pub fn acc_descr_value(text : String) -> String {
  let at = @util.index_of(text, "accDescr") + "accDescr".length()
  let colon = {
    let mut i = at
    while @util.is_blank(@util.code_at(text, i)) {
      i += 1
    }
    i
  }
  if @util.code_at(text, colon) == ':'.to_int() {
    return single(after_keyword(text, "accDescr", true))
  }
  let open = @util.index_of(text, "{", from=at)
  let close = @util.index_of(text, "}", from=open + 1)
  let body = @util.slice(text, open + 1, end=close)
  collapse_runs(
    collapse_runs(strip_line_ends(strip_line_starts(body)), @util.is_blank, " "),
    is_line_break,
    "\n",
  )
}

///|
fn escape_of(c : Int32) -> String? {
  match c {
    0x62 => Some("\u{8}")
    0x66 => Some("\u{c}")
    0x6e => Some("\n")
    0x72 => Some("\r")
    0x74 => Some("\t")
    0x76 => Some("\u{b}")
    0x30 => Some("\u{0}")
    _ => None
  }
}

///|
/// The text a `STRING` token holds, with backslash escapes resolved.
pub fn string_value(text : String) -> String {
  if !text.contains("\\") {
    return @util.slice(text, 1, end=-1)
  }
  let out = StringBuilder()
  let mut i = 1
  while i < text.length() - 1 {
    if @util.code_at(text, i) == '\\'.to_int() {
      i += 1
      match escape_of(@util.code_at(text, i)) {
        Some(escaped) => out.write_string(escaped)
        None => @util.write_range(out, text, i, i + 1)
      }
    } else {
      @util.write_range(out, text, i, i + 1)
    }
    i += 1
  }
  out.to_string()
}
