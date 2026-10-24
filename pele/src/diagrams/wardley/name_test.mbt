///|
/// Where the name starting `src` ends, or the error's code when lexing `src` fails.
fn name_outcome(src : String) -> String {
  let tokens = @common.tokenize(src, @wardley.wardley_tokens, "wardley") catch {
    @errors.PeleError(failure) => return failure.code.to_string()
  }
  "ends at \{tokens.ends[0]}"
}

///|
test "a name of millions of characters is read whole" {
  inspect(name_outcome("a".repeat(9000000)), content="ends at 9000000")
  inspect(name_outcome("a".repeat(9000000) + "->"), content="ends at 9000000")
  inspect(name_outcome("a".repeat(9000000) + " ["), content="ends at 9000000")
  inspect(name_outcome("a" + " a".repeat(4000000)), content="ends at 8000001")
}
