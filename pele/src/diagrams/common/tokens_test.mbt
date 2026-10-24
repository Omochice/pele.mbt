///|
/// How lexing `src` into quoted strings and line breaks ends: the number of tokens, or the error with the limit's message or the syntax error's place.
fn quoted_outcome(src : String) -> String {
  let tokens = @common.tokenize(src, [@common.string, @common.newline], "test") catch {
    @errors.PeleError(failure) => {
      let detail = if failure.code is Limit {
        failure.message
      } else {
        "line \{failure.line} column \{failure.column}"
      }
      return "\{failure.code.to_string()}: \{detail}"
    }
  }
  "\{tokens.kinds.length() - 1} tokens"
}

///|
test "a double-quoted string fails as nested too deeply where pele's pattern runs out of V8's backtracking stack" {
  inspect(quoted_outcome("\"\{"a".repeat(4194294)}\"\n"), content="2 tokens")
  inspect(
    quoted_outcome("\"\{"a".repeat(4194295)}\"\n"),
    content="limit: Diagram is nested too deeply.",
  )
}

///|
test "an escape pair is one step of the quoted string pattern" {
  inspect(quoted_outcome("\"\{"\\\"".repeat(4194294)}\"\n"), content="2 tokens")
  inspect(
    quoted_outcome("\"\{"\\a".repeat(4194295)}\"\n"),
    content="limit: Diagram is nested too deeply.",
  )
}

///|
test "a single-quoted string runs one step further before it fails as nested too deeply" {
  inspect(quoted_outcome("'\{"a".repeat(4194295)}'\n"), content="2 tokens")
  inspect(
    quoted_outcome("'\{"a".repeat(4194296)}'\n"),
    content="limit: Diagram is nested too deeply.",
  )
}

///|
test "an unclosed string runs one step further before it fails as nested too deeply" {
  inspect(
    quoted_outcome("\"\{"a".repeat(4194294)}\n"),
    content="syntax: line 1 column 1",
  )
  inspect(
    quoted_outcome("\"\{"a".repeat(4194295)}\\\n\"\n"),
    content="syntax: line 1 column 1",
  )
  inspect(
    quoted_outcome("\"\{"a".repeat(4194295)}\n"),
    content="limit: Diagram is nested too deeply.",
  )
  inspect(
    quoted_outcome("'\{"a".repeat(4194296)}\\"),
    content="limit: Diagram is nested too deeply.",
  )
}
