///|
fn dump_tokens(src : String) -> String {
  let tokens = @block.tokenize(src)
  let lines = []
  for i, kind in tokens.types {
    lines.push("\{kind.name()}@\{tokens.starts[i]} \{tokens.texts[i]}")
  }
  lines.join("\n")
}

///|
test "tokenizes as pele does" {
  for item in lexer_cases {
    let (src, expected) = item
    assert_eq(dump_tokens(src), expected, msg=src)
  }
}

///|
test "keeps the spaces around an arrow direction for the model to trim" {
  assert_eq(
    dump_tokens("block\n a<[\"x\"]>( up , down)"),
    [
      "BLOCK_DIAGRAM_KEY@0 block", "NODE_ID@7 a", "BLOCK_ARROW_START@8 <[", "STR@11 x",
      "DIR@16  up ", "DIR@20 down", "BLOCK_ARROW_END@26 ]>", "EOF@27 ", "$end@27 ",
    ].join("\n"),
  )
}

///|
test "reads columns auto as -1" {
  assert_eq(
    dump_tokens("block\ncolumns auto"),
    ["BLOCK_DIAGRAM_KEY@0 block", "COLUMNS@6 -1", "EOF@18 ", "$end@18 "].join(
      "\n",
    ),
  )
}

///|
test "stops at the first character no rule takes" {
  assert_eq(
    dump_tokens("block\n a - b"),
    ["BLOCK_DIAGRAM_KEY@0 block", "NODE_ID@7 a", "INVALID@9 "].join("\n"),
  )
}
