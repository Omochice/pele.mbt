///|
test "a node is created once and numbered in order of appearance" {
  let db = @sankey.SankeyDb::new()
  let a = db.find_or_create_node("a")
  let b = db.find_or_create_node("b")
  let again = db.find_or_create_node("a")
  inspect(a.index, content="0")
  inspect(b.index, content="1")
  inspect(again.index, content="0")
  inspect(db.nodes.map(node => node.id).join(","), content="a,b")
}

///|
test "links keep their order and may repeat" {
  let db = @sankey.SankeyDb::new()
  let a = db.find_or_create_node("a")
  let b = db.find_or_create_node("b")
  db.add_link(a, b, 1)
  db.add_link(a, b, 2)
  db.add_link(b, a, 3)
  inspect(
    db.links
    .map(link => "\{link.source.id}>\{link.target.id}=\{link.value}")
    .join(" "),
    content="a>b=1 a>b=2 b>a=3",
  )
}

///|
test "names that are properties of Object are ordinary" {
  let db = @sankey.SankeyDb::new()
  inspect(db.find_or_create_node("__proto__").index, content="0")
  inspect(db.find_or_create_node("constructor").index, content="1")
  inspect(db.find_or_create_node("__proto__").index, content="0")
}
