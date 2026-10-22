///|
fn optional(value : String?) -> String {
  match value {
    Some(text) => text.escape()
    None => "-"
  }
}

///|
fn ast(source : String) -> String {
  let ast = @cynefin.parse_cynefin(source) catch {
    @errors.PeleError(failure) => return failure.message.escape()
  }
  let domains = ast.domains.map(block => {
    let items = block.items.map(item => item.escape())
    "\{block.domain}[\{items.join(",")}]"
  })
  let transitions = ast.transitions.map(t => {
    "\{t.from}>\{t.to}:\{optional(t.label)}"
  })
  "title=\{optional(ast.title)} accTitle=\{optional(ast.acc_title)} accDescr=\{optional(ast.acc_descr)} domains=\{domains.join(";")} transitions=\{transitions.join(",")}"
}

///|
test "a bare header is a diagram" {
  inspect(
    ast("cynefin-beta"),
    content="title=- accTitle=- accDescr=- domains= transitions=",
  )
  inspect(
    ast("cynefin-beta:"),
    content="title=- accTitle=- accDescr=- domains= transitions=",
  )
}

///|
test "domain blocks collect the quoted items below them" {
  inspect(
    ast("cynefin-beta:\ncomplex\n \"a\"\n 'b'\n\nclear\n\"c\\\"d\""),
    content="title=- accTitle=- accDescr=- domains=complex[\"a\",\"b\"];clear[\"c\\\"d\"] transitions=",
  )
  inspect(
    ast("cynefin-beta\ncomplex \"a\""),
    content="title=- accTitle=- accDescr=- domains=complex[\"a\"] transitions=",
  )
}

///|
test "a domain declared twice is read twice" {
  inspect(
    ast("cynefin-beta\ncomplex\n\"a\"\ncomplex\n\"b\""),
    content="title=- accTitle=- accDescr=- domains=complex[\"a\"];complex[\"b\"] transitions=",
  )
}

///|
test "transitions carry an optional label and self loops are kept" {
  inspect(
    ast(
      "cynefin-beta\ncomplex --> clear : \"x\"\nchaotic --> complex\nclear --> clear : \"\"",
    ),
    content="title=- accTitle=- accDescr=- domains= transitions=complex>clear:\"x\",chaotic>complex:-,clear>clear:\"\"",
  )
}

///|
test "titles and accessibility statements are read" {
  inspect(
    ast(
      "cynefin-beta\n title T\n accTitle:   at\n accDescr { multi\n   line }\n complex",
    ),
    content="title=\"T\" accTitle=\"at\" accDescr=\"multi\\nline\" domains=complex[] transitions=",
  )
  inspect(
    ast("cynefin-beta\ntitle\ncomplex"),
    content="title=\"\" accTitle=- accDescr=- domains=complex[] transitions=",
  )
}

///|
test "comments and blank lines are skipped" {
  inspect(
    ast("%% c\n\ncynefin-beta %% x\ncomplex %% y\n\"a\" %% z"),
    content="title=- accTitle=- accDescr=- domains=complex[\"a\"] transitions=",
  )
}

///|
test "the header must come first" {
  inspect(
    ast("\"orphan\""),
    content="\"Parse error on line 1:\\n\\\"orphan\\\"\\n^\\nExpecting 'cynefin-beta' but found `\\\"orphan\\\"`.\"",
  )
  inspect(
    ast(""),
    content="\"Parse error on line 1:\\n\\n^\\nExpecting 'cynefin-beta' but found end of input.\"",
  )
  inspect(
    ast("complex"),
    content="\"Parse error on line 1:\\ncomplex\\n^\\nExpecting 'cynefin-beta' but found `complex`.\"",
  )
  inspect(
    ast("cynefin-betax"),
    content="\"Lexical error on line 1. Unrecognized text.\\ncynefin-betax\\n^\"",
  )
}

///|
test "an item needs a domain above it" {
  inspect(
    ast("cynefin-beta\n\"orphan\""),
    content="\"Parse error on line 2:\\n\\\"orphan\\\"\\n^\\nExpecting a domain, a transition, a title, or a line break but found `\\\"orphan\\\"`.\"",
  )
}

///|
test "a domain name is matched as a prefix, so a longer word fails to lex" {
  inspect(
    ast("cynefin-beta\ncomplexity"),
    content="\"Lexical error on line 2. Unrecognized text.\\ncomplexity\\n-------^\"",
  )
  inspect(
    ast("cynefin-beta\ncomplex --> nowhere"),
    content="\"Lexical error on line 2. Unrecognized text.\\ncomplex --> nowhere\\n------------^\"",
  )
}

///|
test "a transition ends its line" {
  inspect(
    ast("cynefin-beta\ncomplex --> clear clear"),
    content="\"Parse error on line 2:\\ncomplex --> clear clear\\n------------------^\\nExpecting a line break or the end of input but found `clear`.\"",
  )
  inspect(
    ast("cynefin-beta\ncomplex -->"),
    content="\"Parse error on line 2:\\ncomplex -->\\n-----------^\\nExpecting token of type 'DOMAIN_NAME' but found end of input.\"",
  )
  inspect(
    ast("cynefin-beta\ncomplex --> clear :"),
    content="\"Parse error on line 2:\\ncomplex --> clear :\\n-------------------^\\nExpecting token of type 'STRING' but found end of input.\"",
  )
}

///|
test "an unclosed string does not lex" {
  inspect(
    ast("cynefin-beta\ncomplex\n\"unclosed"),
    content="\"Lexical error on line 3. Unrecognized text.\\n\\\"unclosed\\n^\"",
  )
}
