// Ported from pele v1.8.0, tests/compat/block (Mermaid's block.spec.ts and blockColorIndex.spec.ts) and the model checks of tests/render/block.test.ts.

///|
fn parsed_db(src : String, warn? : (String) -> Unit) -> @block.BlockDb raise {
  let db = @block.BlockDb::new(warn?)
  @block.parse_block(src, db) catch {
    @errors.PeleError(failure) => fail(failure.message)
  }
  db
}

///|
fn parse_outcome(src : String) -> String {
  let db = @block.BlockDb::new()
  try @block.parse_block(src, db) catch {
    @errors.PeleError(failure) =>
      "error \{failure.code.to_string()} \{failure.line}:\{failure.column}\n\{failure.message}"
  } noraise {
    _ => "ok\n" + dump_model(db)
  }
}

///|
fn ids(blocks : Array[@block.Block]) -> String {
  blocks.map(b => b.id).join(" ")
}

///|
test "parses as pele does" {
  for item in parser_cases {
    let (src, expected) = item
    assert_eq(parse_outcome(src), expected, msg=src)
  }
}

///|
test "a diagram with a node" {
  let blocks = parsed_db("block-beta\n          id\n      ").blocks
  assert_eq(blocks.length(), 1)
  assert_eq(blocks[0].id, "id")
  assert_eq(blocks[0].label, "id")
}

///|
test "a node with a square shape and a label" {
  let blocks = parsed_db("block\n          id[\"A label\"]\n          id2").blocks
  assert_eq(blocks.length(), 2)
  assert_eq(blocks[0].id, "id")
  assert_eq(blocks[0].label, "A label")
  assert_eq(blocks[0].kind, "square")
  assert_eq(blocks[1].id, "id2")
  assert_eq(blocks[1].label, "id2")
  assert_eq(blocks[1].kind, "na")
}

///|
test "a diagram with multiple nodes" {
  let blocks = parsed_db(
      "block\n          id1\n          id2\n          id3\n      ",
    ).blocks
  assert_eq(ids(blocks), "id1 id2 id3")
  for b in blocks {
    assert_eq(b.label, b.id)
    assert_eq(b.kind, "na")
  }
}

///|
test "a diagram with multiple nodes with edges" {
  let db = parsed_db(
    "block\n          id1[\"first\"]  -- \"a label\" -->   id2[\"second\"]\n      ",
  )
  assert_eq(db.blocks.length(), 2)
  assert_eq(db.edges.length(), 1)
  assert_eq(db.edges[0].start, "id1")
  assert_eq(db.edges[0].end, "id2")
  assert_eq(db.edges[0].arrow_type_end, "arrow_point")
  assert_eq(db.edges[0].label, "a label")
}

///|
test "a diagram with column statements" {
  assert_eq(
    parsed_db("block\n          columns 2\n          block1[\"Block 1\"]\n").root.columns,
    2,
  )
  assert_eq(
    parsed_db("block\n          block1[\"Block 1\"]\n").root.columns,
    -1,
  )
  assert_eq(
    parsed_db("block\n          columns auto\n          block1[\"Block 1\"]\n").root.columns,
    -1,
  )
}

///|
test "compound blocks of compound blocks" {
  let blocks = parsed_db(
      "block\n  block\n    aBlock[\"ABlock\"]\n    block\n      bBlock[\"BBlock\"]\n    end\n  end\n",
    ).blocks
  assert_eq(blocks.length(), 1)
  let outer = blocks[0]
  assert_eq(outer.children.length(), 2)
  assert_eq(outer.label, "")
  assert_eq(outer.kind, "composite")
  assert_eq(outer.children[0].label, "ABlock")
  assert_eq(outer.children[0].kind, "square")
  let inner = outer.children[1]
  assert_eq(inner.kind, "composite")
  assert_eq(inner.label, "")
  assert_eq(inner.children[0].label, "BBlock")
}

///|
test "compound blocks with title" {
  let blocks = parsed_db(
      "block\n  block:compoundBlock[\"Compound block\"]\n    columns 1\n    block2[\"Block 2\"]\n  end\n",
    ).blocks
  assert_eq(blocks.length(), 1)
  assert_eq(blocks[0].id, "compoundBlock")
  assert_eq(blocks[0].label, "Compound block")
  assert_eq(blocks[0].kind, "composite")
  assert_eq(blocks[0].columns, 1)
  assert_eq(ids(blocks[0].children), "block2")
}

///|
test "arrow blocks keep their directions" {
  let blocks = parsed_db(
      "block\n  columns 1\n  A\n  blockArrow<[\"&nbsp;&nbsp;&nbsp;\"]>(up, down)\n  block\n    columns 3\n    B\n    C\n    D\n  end",
    ).blocks
  assert_eq(blocks.length(), 3)
  assert_eq(blocks[1].kind, "block_arrow")
  assert_eq(blocks[1].directions, ["up", "down"])
}

///|
test "blocks with different widths and empty blocks" {
  let wide = parsed_db(
      "block\n  columns 3\n  one[\"One Slot\"]\n  two[\"Two slots\"]:2\n",
    ).blocks
  assert_eq(wide[1].width_in_columns, Some(2))
  let spaced = parsed_db(
      "block\n  columns 3\n  space\n  middle[\"In the middle\"]\n  space\n",
    ).blocks
  assert_eq(spaced.map(b => b.kind), ["space", "square", "space"])
  assert_eq(spaced[1].label, "In the middle")
}

///|
test "classDef and style statements applied to a block" {
  let db = parsed_db(
    "block\n  classDef black color:#ffffff, fill:#000000;\n\n  mc[\"Memcache\"]\n  class mc black\n",
  )
  assert_eq(db.blocks[0].classes, ["black"])
  assert_eq(
    db.classes.get("black").map(c => c.styles[0]),
    Some("color:#ffffff"),
  )
  let styled = parsed_db(
    "block\ncolumns 1\n    B[\"A wide one in the middle\"]\n  style B fill:#f9F,stroke:#333,stroke-width:4px\n",
  )
  assert_eq(styled.blocks[0].styles, [
    "fill:#f9F", "stroke:#333", "stroke-width:4px",
  ])
}

///|
test "warns when a block is wider than its grid" {
  let warnings = []
  parsed_db(
    "block-beta\n  columns 1\n  A:1\n  B:2\n  C:3\n  D:4\n  E:3\n  F:2\n  G:1",
    warn=message => warnings.push(message),
  )
  |> ignore
  assert_eq(warnings[0], "Block B width 2 exceeds configured column width 1")
  assert_eq(warnings.length(), 5)
}

///|
test "takes prototype property names as plain ids" {
  for name in ["__proto__", "constructor"] {
    parsed_db("block\n\{name}") |> ignore
    parsed_db(
      "block\nA; classDef \{name} color:#ffffff,fill:#000000; class A \{name}",
    )
    |> ignore
  }
}

///|
test "numbers composites in declaration order, outer before inner, across the whole diagram" {
  let color = (db : @block.BlockDb, id : String) => {
    db.by_id.get(id).bind(b => b.color_index)
  }
  let db = parsed_db(
    "block-beta\n  block:outer\n    block:inner\n      a\n    end\n  end\n  block:sibling\n    b\n  end\n  c\n",
  )
  assert_eq(color(db, "outer"), Some(0))
  assert_eq(color(db, "inner"), Some(1))
  assert_eq(color(db, "sibling"), Some(2))
  assert_eq(color(db, "a"), None)
  assert_eq(color(db, "c"), None)
  let nested = parsed_db(
    "block-beta\n  block:a1\n    block:a2\n      x\n    end\n  end\n  block:b1\n    block:b2\n      y\n    end\n  end\n",
  )
  assert_eq(["a1", "a2", "b1", "b2"].map(id => color(nested, id)), [
    Some(0),
    Some(1),
    Some(2),
    Some(3),
  ])
}

///|
test "keeps every link of a statement with several" {
  let db = parsed_db("block\n  a --> b --> c -- \"x\" --> d")
  assert_eq(ids(db.blocks), "a b c d")
  assert_eq(db.edges.map(e => "\{e.id} \{e.start} \{e.end} \{e.label}"), [
    "1-a-b a b ", "1-b-c b c ", "1-c-d c d x",
  ])
}

///|
test "uses the id as the label and merges later statements into the first" {
  let db = parsed_db("block\n  a b\n  a[\"Named\"]\n  b((\"x\")) --> a")
  assert_eq(db.blocks.map(b => "\{b.id} \{b.label} \{b.kind}"), [
    "a Named square", "b x circle",
  ])
}

///|
test "gives generated ids that do not change between runs" {
  assert_eq(
    ids(parsed_db("block\n  a space:2\n  block\n    b\n  end").blocks),
    "a id-1-0 id-1-1 id-2",
  )
}

///|
test "rejects what the grammar rejects" {
  for
    src in [
      "block", "block\n", "block\n  a - b", "block\n  a[label]", "block\n  block\n  a",
      "block\n  a\n  end", "block\n  default", "block\n  accTitle: t\n  a",
    ] {
    guard parse_outcome(src) is [.. "error syntax ", ..] else {
      fail("accepted \{src}")
    }
  }
  inspect(
    parse_outcome("block\n  a - b"),
    content=(
      #|error syntax 2:5
      #|Lexical error on line 2. Unrecognized text.
      #|  a - b
      #|----^
    ),
  )
  inspect(
    parse_outcome("block\n  a\n  end"),
    content=(
      #|error syntax 3:3
      #|Parse error on line 3:
      #|  end
      #|--^
      #|Expecting 'NODE_ID', 'COLUMNS', 'SPACE_BLOCK', 'BLOCK_DIAGRAM_KEY', 'id-block', 'classDef', 'class', 'style', got 'end'
    ),
  )
}
