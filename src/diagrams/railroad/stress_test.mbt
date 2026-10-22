///|
const N : Int = 50000

///|
/// Draws `source` without a source length limit and tells whether it was accepted.
/// Any outcome but a trap is fine: pele only promises that hostile input ends in a `PeleError`.
/// Output past the output limit is such an error, and these inputs reach it as they do in pele.
fn survives(source : String) -> String {
  let options = {
    ..@types.RenderOptions::default(),
    limit: Some(@double.infinity),
  }
  let _ = @core.render([@railroad.railroad], source, options) catch {
    @errors.PeleError(_) => return "error"
  }
  "drawn"
}

///|
test "groups nested deeply collapse to their content" {
  inspect(
    survives(
      "railroad-ebnf-beta\nr = " +
      "(".repeat(N / 2) +
      "a" +
      ")".repeat(N / 2) +
      " ;",
    ),
    content="drawn",
  )
}

///|
test "optionals and repetitions nested deeply are laid out without recursion" {
  inspect(
    survives(
      "railroad-ebnf-beta\nr = " +
      "[".repeat(12000) +
      "a" +
      "]".repeat(12000) +
      " ;",
    ),
    content="drawn",
  )
  inspect(
    survives(
      "railroad-ebnf-beta\nr = " +
      "{".repeat(12000) +
      "a" +
      "}".repeat(12000) +
      " ;",
    ),
    content="drawn",
  )
}

///|
test "a very long run of postfix operators" {
  inspect(
    survives("railroad-ebnf-beta\nr = a" + "*+?".repeat(N / 3) + " ;"),
    content="error",
  )
}

///|
test "a long chain of exceptions" {
  inspect(
    survives("railroad-ebnf-beta\nr = a" + " - b".repeat(12000) + " ;"),
    content="error",
  )
}

///|
test "unclosed brackets and calls end in an error" {
  inspect(
    survives("railroad-ebnf-beta\nr = " + "([{".repeat(N / 3)),
    content="error",
  )
  inspect(
    survives("railroad-beta\nr = " + "choice(".repeat(N / 7)),
    content="error",
  )
}

///|
test "wide choices, sequences, and many rules" {
  let alternatives = StringBuilder()
  for i in 0..<12000 {
    alternatives.write_string("a\{i} | ")
  }
  inspect(
    survives("railroad-ebnf-beta\nr = \{alternatives.to_string()}z ;"),
    content="drawn",
  )
  inspect(
    survives("railroad-ebnf-beta\nr = " + "a ".repeat(12000) + ";"),
    content="drawn",
  )
  inspect(
    survives("railroad-ebnf-beta\n" + "r = a | b ;\n".repeat(5000)),
    content="error",
  )
}

///|
test "constructor calls nested deeply" {
  inspect(
    survives(
      "railroad-beta\nr = " +
      "optional(oneOrMore(".repeat(2500) +
      "terminal(\"a\")" +
      "))".repeat(2500) +
      " ;",
    ),
    content="drawn",
  )
  inspect(
    survives(
      "railroad-beta\nr = " +
      "sequence(".repeat(6000) +
      "terminal(\"a\")" +
      ")".repeat(6000) +
      " ;",
    ),
    content="drawn",
  )
}

///|
test "ABNF and PEG groups nested deeply" {
  inspect(
    survives(
      "railroad-abnf-beta\nr = " +
      "2*3( ".repeat(10000) +
      "a" +
      " )".repeat(10000) +
      " ;",
    ),
    content="drawn",
  )
  inspect(
    survives(
      "railroad-peg-beta\nR <- " +
      "!( &( ".repeat(5000) +
      "a" +
      " ) )".repeat(5000) +
      " ;",
    ),
    content="drawn",
  )
  inspect(
    survives(
      "railroad-peg-beta\nR <- " +
      "( ".repeat(10000) +
      "a" +
      " )*".repeat(10000) +
      " ;",
    ),
    content="drawn",
  )
}

///|
test "lexer worst cases do not rescan" {
  inspect(
    survives("railroad-ebnf-beta\nr = ?" + " a".repeat(N / 2)),
    content="error",
  )
  inspect(
    survives("railroad-ebnf-beta\nr = " + "(* a ".repeat(N / 5)),
    content="error",
  )
  inspect(
    survives("railroad-ebnf-beta\nr = " + "(*)".repeat(N / 3)),
    content="error",
  )
  inspect(
    survives("railroad-ebnf-beta\n" + "accDescr { ".repeat(N / 11)),
    content="error",
  )
  inspect(survives("railroad-beta\n" + "/* a ".repeat(N / 5)), content="error")
  inspect(
    survives("railroad-ebnf-beta\nr = a " + "-".repeat(N)),
    content="error",
  )
  inspect(
    survives("railroad-abnf-beta\nr = " + "1".repeat(N) + "a ;"),
    content="drawn",
  )
}

///|
test "one very long name and terminal" {
  inspect(
    survives(
      "railroad-ebnf-beta\n" + "a".repeat(N) + " = " + "b".repeat(N) + " ;",
    ),
    content="drawn",
  )
  inspect(
    survives("railroad-ebnf-beta\nr = \"" + "word ".repeat(N / 5) + "\" ;"),
    content="drawn",
  )
}
