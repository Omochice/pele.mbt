///|
fn tildes(text : String) -> Int32 {
  let mut count = 0
  for i in 0..<text.length() {
    if text.unsafe_get(i) == '~' {
      count += 1
    }
  }
  count
}

///|
/// Pairs tildes from the outside in: the first with the last, the second with the one before it.
fn pair_tildes(text : String) -> String {
  let count = tildes(text)
  if count <= 1 {
    return text
  }
  let lead = count % 2 != 0 && text.has_prefix("~")
  let at = []
  for i in (if lead { 1 } else { 0 })..<text.length() {
    if text.unsafe_get(i) == '~' {
      at.push(i)
    }
  }
  let pairs = at.length() / 2
  let out = StringBuilder()
  let mut last = 0
  for k, i in at {
    if k < pairs {
      @util.write_range(out, text, last, i)
      out.write_char('<')
      last = i + 1
    } else if k >= at.length() - pairs {
      @util.write_range(out, text, last, i)
      out.write_char('>')
      last = i + 1
    }
  }
  @util.write_range(out, text, last, text.length())
  out.to_string()
}

///|
/// The text split at commas with each comma kept as a piece of its own, as `split(/(,)/)`.
fn split_commas(input : String) -> Array[String] {
  let sets = []
  let mut last = 0
  for i in 0..<input.length() {
    if input.unsafe_get(i) == ',' {
      sets.push(@util.slice(input, last, end=i))
      sets.push(",")
      last = i + 1
    }
  }
  sets.push(@util.slice(input, last))
  sets
}

///|
/// Turns `List~int~` into `List<int>`, with the quirks of Mermaid's parseGenericTypes around commas.
pub fn parse_generic_types(input : String) -> String {
  if !input.contains("~") {
    return input
  }
  let sets = split_commas(input)
  let output : Array[String] = []
  let mut i = 0
  while i < sets.length() {
    let mut set = sets[i]
    if set == "," &&
      i > 0 &&
      i + 1 < sets.length() &&
      tildes(sets[i - 1]) == 1 &&
      tildes(sets[i + 1]) == 1 {
      set = sets[i - 1] + "," + sets[i + 1]
      i += 1
      output.pop() |> ignore
    }
    output.push(pair_tildes(set))
    i += 1
  }
  output.join("")
}
