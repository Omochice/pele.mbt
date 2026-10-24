///|
/// How lexing `src` into quoted strings and line breaks ends: the number of tokens, or the syntax error's place.
fn quoted_outcome(src : String) -> String {
  let tokens = @common.tokenize(src, [@common.string, @common.newline], "test") catch {
    @errors.PeleError(failure) =>
      return "\{failure.code.to_string()}: line \{failure.line} column \{failure.column}"
  }
  "\{tokens.kinds.length() - 1} tokens"
}

///|
test "a quoted string of millions of characters is read to its closing quote" {
  inspect(quoted_outcome("\"\{"a".repeat(5000000)}\"\n"), content="2 tokens")
  inspect(quoted_outcome("'\{"a".repeat(5000000)}'\n"), content="2 tokens")
  inspect(quoted_outcome("\"\{"\\\"".repeat(5000000)}\"\n"), content="2 tokens")
}

///|
test "a quoted string of millions of characters that no quote closes is a syntax error" {
  inspect(
    quoted_outcome("\"\{"a".repeat(5000000)}\n"),
    content="syntax: line 1 column 1",
  )
  inspect(
    quoted_outcome("'\{"a".repeat(5000000)}\\"),
    content="syntax: line 1 column 1",
  )
}
