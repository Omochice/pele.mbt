///|
/// Where the name starting `src` ends, or the error's code when lexing `src` fails.
fn name_outcome(src : String) -> String {
  let tokens = @common.tokenize(src, @wardley.wardley_tokens, "wardley") catch {
    @errors.PeleError(failure) => return failure.code.to_string()
  }
  "ends at \{tokens.ends[0]}"
}

///|
test "a one-word name fails as nested too deeply where pele's pattern runs out of V8's backtracking stack" {
  inspect(name_outcome("a".repeat(8388591)), content="ends at 8388591")
  inspect(name_outcome("a".repeat(8388592)), content="limit")
}

///|
test "a name ended by an arrow runs out of V8's backtracking stack one character sooner" {
  inspect(name_outcome("a".repeat(8388590) + "->"), content="ends at 8388590")
  inspect(name_outcome("a".repeat(8388591) + "->"), content="limit")
}

///|
test "a name ended by blanks that start no word runs out of V8's backtracking stack one character sooner" {
  inspect(name_outcome("a".repeat(8388590) + " ["), content="ends at 8388590")
  inspect(name_outcome("a".repeat(8388591) + " ["), content="limit")
}

///|
test "each further word of a name takes more of V8's backtracking stack than a character" {
  inspect(name_outcome("a".repeat(8388588) + " a"), content="ends at 8388590")
  inspect(name_outcome("a".repeat(8388589) + " a"), content="limit")
  inspect(name_outcome("a" + " a".repeat(3355436)), content="ends at 6710873")
  inspect(name_outcome("a" + " a".repeat(3355437)), content="limit")
  inspect(name_outcome("a".repeat(8388587) + " a "), content="ends at 8388589")
  inspect(name_outcome("a".repeat(8388588) + " a "), content="limit")
}
