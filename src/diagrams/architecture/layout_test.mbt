///|
fn at(values : Array[Int32], i : Int32) -> String {
  match values.get(i) {
    Some(value) => value.to_string()
    None => "?"
  }
}

///|
fn grid(source : String) -> String {
  let db = @architecture.ArchitectureDb::new()
  @architecture.populate(@architecture.parse_architecture(source), db) catch {
    @errors.PeleError(failure) => return failure.message
  }
  let nodes = db.nodes.values().collect()
  let groups = db.groups.values().collect()
  let g = @architecture.place_on_grid(nodes, groups, db.edges, db.layout_hints)
  let lines = []
  for i, node in nodes {
    lines.push(
      "\{node.id} \{at(g.col, i)},\{at(g.row, i)} parent=\{at(g.node_parent, i)}",
    )
  }
  for i, group in groups {
    let empty = if g.group_empty.get(i) is Some(true) { 1 } else { 0 }
    lines.push(
      "\{group.id} \{at(g.group_col, i)},\{at(g.group_row, i)} \{at(g.group_cols, i)}x\{at(g.group_rows, i)} parent=\{at(g.group_parent, i)} empty=\{empty}",
    )
  }
  lines.join("\n")
}

///|
test "a node goes to the side its edge names" {
  inspect(
    grid(
      "architecture-beta\nservice a\nservice b\nservice c\nservice d\nservice e\na:R -- L:b\na:L -- R:c\na:T -- B:d\na:B -- T:e",
    ),
    content="a 1,1 parent=-1\nb 2,1 parent=-1\nc 0,1 parent=-1\nd 1,0 parent=-1\ne 1,2 parent=-1",
  )
}

///|
test "perpendicular sides place a node diagonally" {
  inspect(
    grid(
      "architecture-beta\nservice a\nservice b\nservice c\na:R -- T:b\na:T -- R:c",
    ),
    content="a 1,1 parent=-1\nb 2,2 parent=-1\nc 0,0 parent=-1",
  )
  inspect(
    grid("architecture-beta\nservice a\nservice b\nb:T -- R:a"),
    content="a 0,0 parent=-1\nb 1,1 parent=-1",
  )
}

///|
test "like sides stack the nodes across the side" {
  inspect(
    grid(
      "architecture-beta\nservice a\nservice b\nservice c\na:R -- R:b\na:T -- T:c",
    ),
    content="a 0,0 parent=-1\nb 0,1 parent=-1\nc 1,0 parent=-1",
  )
  inspect(
    grid(
      "architecture-beta\nservice a\nservice b\nservice c\na:R -- L:b\na:B -- B:c\nb:B -- B:c",
    ),
    content="a 0,0 parent=-1\nb 1,0 parent=-1\nc 2,0 parent=-1",
  )
}

///|
test "every node gets its own cell" {
  inspect(
    grid(
      "architecture-beta\nservice hub\nservice n0\nhub:R -- L:n0\nservice n1\nhub:R -- L:n1\nservice n2\nhub:R -- L:n2\nservice n3\nhub:R -- L:n3\nservice n4\nhub:R -- L:n4\nservice n5\nhub:R -- L:n5\nservice n6\nhub:R -- L:n6\nservice n7\nhub:R -- L:n7\nservice n8\nhub:R -- L:n8",
    ),
    content="hub 0,4 parent=-1\nn0 1,4 parent=-1\nn1 1,5 parent=-1\nn2 1,3 parent=-1\nn3 1,6 parent=-1\nn4 1,2 parent=-1\nn5 1,7 parent=-1\nn6 1,1 parent=-1\nn7 1,8 parent=-1\nn8 1,0 parent=-1",
  )
  inspect(
    grid(
      "architecture-beta\nservice hub\nservice n0\nhub:B -- L:n0\nservice n1\nhub:B -- L:n1\nservice n2\nhub:B -- L:n2\nservice n3\nhub:B -- L:n3\nservice n4\nhub:B -- L:n4",
    ),
    content="hub 0,0 parent=-1\nn0 1,1 parent=-1\nn1 1,2 parent=-1\nn2 1,3 parent=-1\nn3 1,4 parent=-1\nn4 1,5 parent=-1",
  )
  inspect(
    grid(
      "architecture-beta\nservice a\nservice b\nservice c\nservice d\na:R -- L:c\nb:R -- L:c\nd:L -- R:c",
    ),
    content="a 0,0 parent=-1\nb 0,1 parent=-1\nc 1,0 parent=-1\nd 2,0 parent=-1",
  )
}

///|
test "unconnected parts wrap into rows" {
  inspect(
    grid(
      "architecture-beta\nservice a\nservice b\nservice c\nservice d\nservice e\njunction j\na:R -- L:b",
    ),
    content="a 0,0 parent=-1\nb 1,0 parent=-1\nc 2,0 parent=-1\nd 3,0 parent=-1\ne 0,1 parent=-1\nj 1,1 parent=-1",
  )
  inspect(
    grid(
      "architecture-beta\nservice n0\nservice n1\nservice n2\nservice n3\nservice n4\nservice n5\nservice n6\nservice n7\nservice n8\nservice n9\nservice n10\nservice n11\n",
    ),
    content="n0 0,0 parent=-1\nn1 1,0 parent=-1\nn2 2,0 parent=-1\nn3 3,0 parent=-1\nn4 4,0 parent=-1\nn5 0,1 parent=-1\nn6 1,1 parent=-1\nn7 2,1 parent=-1\nn8 3,1 parent=-1\nn9 4,1 parent=-1\nn10 0,2 parent=-1\nn11 1,2 parent=-1",
  )
}

///|
test "a group is a block of cells around its members" {
  inspect(
    grid(
      "architecture-beta\ngroup fe[Frontend]\ngroup be[Backend]\ngroup inner[Inner] in be\nservice web in fe\nservice gw in be\nservice auth in inner\nservice out\nservice mid\nweb:R -- L:mid\nmid:R -- L:gw\ngw:B -- T:auth\nauth:R -- L:out\nweb:B -- T:out",
    ),
    content="web 2,0 parent=0\ngw 1,0 parent=1\nauth 1,1 parent=2\nout 2,1 parent=-1\nmid 0,0 parent=-1\nfe 2,0 1x1 parent=-1 empty=0\nbe 1,0 1x2 parent=-1 empty=0\ninner 1,1 1x1 parent=1 empty=0",
  )
  inspect(
    grid("architecture-beta\ngroup g[Nothing here]\ngroup h in g"),
    content="g 0,0 1x1 parent=-1 empty=0\nh 0,0 1x1 parent=0 empty=1",
  )
  inspect(
    grid(
      "architecture-beta\ngroup one\ngroup two\nservice a in one\nservice b in two\na{group}:B --> T:b{group}",
    ),
    content="a 0,0 parent=0\nb 0,1 parent=1\none 0,0 1x1 parent=-1 empty=0\ntwo 0,1 1x1 parent=-1 empty=0",
  )
  inspect(
    grid(
      "architecture-beta\nservice hub\ngroup g0\nservice n0 in g0\nhub:R -- L:n0\ngroup g1\nservice n1 in g1\nhub:R -- L:n1\ngroup g2\nservice n2 in g2\nhub:R -- L:n2\ngroup g3\nservice n3 in g3\nhub:R -- L:n3\ngroup g4\nservice n4 in g4\nhub:R -- L:n4\ngroup g5\nservice n5 in g5\nhub:R -- L:n5\n",
    ),
    content="hub 0,2 parent=-1\nn0 1,2 parent=0\nn1 1,3 parent=1\nn2 1,1 parent=2\nn3 1,4 parent=3\nn4 1,0 parent=4\nn5 1,5 parent=5\ng0 1,2 1x1 parent=-1 empty=0\ng1 1,3 1x1 parent=-1 empty=0\ng2 1,1 1x1 parent=-1 empty=0\ng3 1,4 1x1 parent=-1 empty=0\ng4 1,0 1x1 parent=-1 empty=0\ng5 1,5 1x1 parent=-1 empty=0",
  )
}

///|
test "alignments are followed ahead of edges" {
  inspect(
    grid(
      "architecture-beta\nservice a\nservice b\nservice c\nservice p\na:B -- T:p\nb:B -- T:p\nc:B -- T:p\nalign row a b c",
    ),
    content="a 0,0 parent=-1\nb 1,0 parent=-1\nc 2,0 parent=-1\np 1,1 parent=-1",
  )
  inspect(
    grid(
      "architecture-beta\nservice a\nservice b\nservice c\nalign column c a b",
    ),
    content="a 0,1 parent=-1\nb 0,2 parent=-1\nc 0,0 parent=-1",
  )
}

///|
test "blocks larger than the cell map are compared one by one" {
  inspect(
    grid(
      "architecture-beta\nservice hub\ngroup g0\nservice m0x0 in g0\nservice m0x1 in g0\nservice m0x2 in g0\nservice m0x3 in g0\nservice m0x4 in g0\nservice m0x5 in g0\nservice m0x6 in g0\nservice m0x7 in g0\nservice m0x8 in g0\nservice m0x9 in g0\nservice m0x10 in g0\nservice m0x11 in g0\nm0x0:R -- T:m0x1\nm0x1:R -- T:m0x2\nm0x2:R -- T:m0x3\nm0x3:R -- T:m0x4\nm0x4:R -- T:m0x5\nm0x5:R -- T:m0x6\nm0x6:R -- T:m0x7\nm0x7:R -- T:m0x8\nm0x8:R -- T:m0x9\nm0x9:R -- T:m0x10\nm0x10:R -- T:m0x11\nhub:R -- L:m0x0\ngroup g1\nservice m1x0 in g1\nservice m1x1 in g1\nservice m1x2 in g1\nservice m1x3 in g1\nservice m1x4 in g1\nservice m1x5 in g1\nservice m1x6 in g1\nservice m1x7 in g1\nservice m1x8 in g1\nservice m1x9 in g1\nservice m1x10 in g1\nservice m1x11 in g1\nm1x0:R -- T:m1x1\nm1x1:R -- T:m1x2\nm1x2:R -- T:m1x3\nm1x3:R -- T:m1x4\nm1x4:R -- T:m1x5\nm1x5:R -- T:m1x6\nm1x6:R -- T:m1x7\nm1x7:R -- T:m1x8\nm1x8:R -- T:m1x9\nm1x9:R -- T:m1x10\nm1x10:R -- T:m1x11\nhub:R -- L:m1x0\ngroup g2\nservice m2x0 in g2\nservice m2x1 in g2\nservice m2x2 in g2\nservice m2x3 in g2\nservice m2x4 in g2\nservice m2x5 in g2\nservice m2x6 in g2\nservice m2x7 in g2\nservice m2x8 in g2\nservice m2x9 in g2\nservice m2x10 in g2\nservice m2x11 in g2\nm2x0:R -- T:m2x1\nm2x1:R -- T:m2x2\nm2x2:R -- T:m2x3\nm2x3:R -- T:m2x4\nm2x4:R -- T:m2x5\nm2x5:R -- T:m2x6\nm2x6:R -- T:m2x7\nm2x7:R -- T:m2x8\nm2x8:R -- T:m2x9\nm2x9:R -- T:m2x10\nm2x10:R -- T:m2x11\nhub:R -- L:m2x0\n",
    ),
    content="hub 0,12 parent=-1\nm0x0 1,12 parent=0\nm0x1 2,13 parent=0\nm0x2 3,14 parent=0\nm0x3 4,15 parent=0\nm0x4 5,16 parent=0\nm0x5 6,17 parent=0\nm0x6 7,18 parent=0\nm0x7 8,19 parent=0\nm0x8 9,20 parent=0\nm0x9 10,21 parent=0\nm0x10 11,22 parent=0\nm0x11 12,23 parent=0\nm1x0 1,24 parent=1\nm1x1 2,25 parent=1\nm1x2 3,26 parent=1\nm1x3 4,27 parent=1\nm1x4 5,28 parent=1\nm1x5 6,29 parent=1\nm1x6 7,30 parent=1\nm1x7 8,31 parent=1\nm1x8 9,32 parent=1\nm1x9 10,33 parent=1\nm1x10 11,34 parent=1\nm1x11 12,35 parent=1\nm2x0 1,0 parent=2\nm2x1 2,1 parent=2\nm2x2 3,2 parent=2\nm2x3 4,3 parent=2\nm2x4 5,4 parent=2\nm2x5 6,5 parent=2\nm2x6 7,6 parent=2\nm2x7 8,7 parent=2\nm2x8 9,8 parent=2\nm2x9 10,9 parent=2\nm2x10 11,10 parent=2\nm2x11 12,11 parent=2\ng0 1,12 12x12 parent=-1 empty=0\ng1 1,24 12x12 parent=-1 empty=0\ng2 1,0 12x12 parent=-1 empty=0",
  )
  inspect(
    grid(
      "architecture-beta\nservice n0\nservice n1\nservice n2\nservice n3\nservice n4\nservice n5\nservice n6\nservice n7\nservice n8\nservice n9\nservice n10\nservice n11\nservice n12\nservice n13\nservice n14\nservice n15\nservice n16\nservice n17\nservice n18\nservice n19\nn0:B -- T:n1\nn1:B -- T:n2\nn2:B -- T:n3\nn3:B -- T:n4\nn4:B -- T:n5\nn5:B -- T:n6\nn6:B -- T:n7\nn7:B -- T:n8\nn8:B -- T:n9\nn9:B -- T:n10\nn10:B -- T:n11\nn11:B -- T:n12\nn12:B -- T:n13\nn13:B -- T:n14\nn14:B -- T:n15\nn15:B -- T:n16\nn16:B -- T:n17\nn17:B -- T:n18\nn18:B -- T:n19\ngroup g0\nservice m0x0 in g0\nservice m0x1 in g0\nservice m0x2 in g0\nservice m0x3 in g0\nservice m0x4 in g0\nservice m0x5 in g0\nservice m0x6 in g0\nservice m0x7 in g0\nservice m0x8 in g0\nservice m0x9 in g0\nservice m0x10 in g0\nservice m0x11 in g0\nm0x0:B -- R:m0x1\nm0x1:B -- R:m0x2\nm0x2:B -- R:m0x3\nm0x3:B -- R:m0x4\nm0x4:B -- R:m0x5\nm0x5:B -- R:m0x6\nm0x6:B -- R:m0x7\nm0x7:B -- R:m0x8\nm0x8:B -- R:m0x9\nm0x9:B -- R:m0x10\nm0x10:B -- R:m0x11\nn0:R -- L:m0x0\ngroup g1\nservice m1x0 in g1\nservice m1x1 in g1\nservice m1x2 in g1\nservice m1x3 in g1\nservice m1x4 in g1\nservice m1x5 in g1\nservice m1x6 in g1\nservice m1x7 in g1\nservice m1x8 in g1\nservice m1x9 in g1\nservice m1x10 in g1\nservice m1x11 in g1\nm1x0:B -- R:m1x1\nm1x1:B -- R:m1x2\nm1x2:B -- R:m1x3\nm1x3:B -- R:m1x4\nm1x4:B -- R:m1x5\nm1x5:B -- R:m1x6\nm1x6:B -- R:m1x7\nm1x7:B -- R:m1x8\nm1x8:B -- R:m1x9\nm1x9:B -- R:m1x10\nm1x10:B -- R:m1x11\nn0:R -- L:m1x0\n",
    ),
    content="n0 0,0 parent=-1\nn1 0,1 parent=-1\nn2 0,2 parent=-1\nn3 0,3 parent=-1\nn4 0,4 parent=-1\nn5 0,5 parent=-1\nn6 0,6 parent=-1\nn7 0,7 parent=-1\nn8 0,8 parent=-1\nn9 0,9 parent=-1\nn10 0,10 parent=-1\nn11 0,11 parent=-1\nn12 0,12 parent=-1\nn13 0,13 parent=-1\nn14 0,14 parent=-1\nn15 0,15 parent=-1\nn16 0,16 parent=-1\nn17 0,17 parent=-1\nn18 0,18 parent=-1\nn19 0,19 parent=-1\nm0x0 12,0 parent=0\nm0x1 11,1 parent=0\nm0x2 10,2 parent=0\nm0x3 9,3 parent=0\nm0x4 8,4 parent=0\nm0x5 7,5 parent=0\nm0x6 6,6 parent=0\nm0x7 5,7 parent=0\nm0x8 4,8 parent=0\nm0x9 3,9 parent=0\nm0x10 2,10 parent=0\nm0x11 1,11 parent=0\nm1x0 12,12 parent=1\nm1x1 11,13 parent=1\nm1x2 10,14 parent=1\nm1x3 9,15 parent=1\nm1x4 8,16 parent=1\nm1x5 7,17 parent=1\nm1x6 6,18 parent=1\nm1x7 5,19 parent=1\nm1x8 4,20 parent=1\nm1x9 3,21 parent=1\nm1x10 2,22 parent=1\nm1x11 1,23 parent=1\ng0 1,0 12x12 parent=-1 empty=0\ng1 1,12 12x12 parent=-1 empty=0",
  )
}

///|
test "a node reached from several placed nodes lines up with the middle one" {
  inspect(
    grid(
      "architecture-beta\nservice a\nservice b\nservice c\nservice t\na:B -- T:b\nb:B -- T:c\na:R -- L:t\nb:R -- L:t\nc:R -- L:t",
    ),
    content="a 0,0 parent=-1\nb 0,1 parent=-1\nc 0,2 parent=-1\nt 1,0 parent=-1",
  )
}
