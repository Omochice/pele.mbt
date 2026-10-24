// The expected models were printed from pele v1.8.0's BlockDb given the same statements.

///|
fn leaf(
  id : String,
  kind~ : String = "na",
  label~ : String = "",
) -> @block.Block {
  @block.Block::new(id, kind, label~, width_in_columns=1)
}

///|
fn link(start : String, end : String, label~ : String = "") -> @block.Block {
  @block.Block::new(
    start + "-" + end,
    "edge",
    label~,
    start~,
    end~,
    arrow_type_end="arrow_point",
    arrow_type_start="arrow_open",
    thickness="normal",
    pattern="solid",
  )
}

///|
fn hierarchy(statements : Array[@block.Statement]) -> String {
  let warnings = []
  let db = @block.BlockDb::new(warn=message => warnings.push("warn " + message))
  try db.set_hierarchy(statements) catch {
    @errors.PeleError(failure) =>
      "error \{failure.code.to_string()} \{failure.message}"
  } noraise {
    _ => [dump_model(db), ..warnings].join("\n")
  }
}

///|
test "tells the line and arrow types from a link" {
  assert_eq(@block.edge_str_to_thickness("-->"), "normal")
  assert_eq(@block.edge_str_to_thickness("-.->"), "normal")
  assert_eq(@block.edge_str_to_thickness("==>"), "thick")
  assert_eq(@block.edge_str_to_pattern("-->"), "solid")
  assert_eq(@block.edge_str_to_pattern("==>"), "solid")
  assert_eq(@block.edge_str_to_pattern("-.->"), "dotted")
  assert_eq(@block.edge_str_to_edge_start_data("<-->"), "arrow_point")
  assert_eq(@block.edge_str_to_edge_data("<-->"), "arrow_point")
  assert_eq(@block.edge_str_to_edge_start_data("<==>"), "arrow_point")
  assert_eq(@block.edge_str_to_edge_data("<==>"), "arrow_point")
  assert_eq(@block.edge_str_to_edge_start_data("-->"), "arrow_open")
  assert_eq(@block.edge_str_to_edge_data("-->"), "arrow_point")
  assert_eq(@block.edge_str_to_edge_data("--x"), "arrow_cross")
  assert_eq(@block.edge_str_to_edge_data("--o"), "arrow_circle")
  assert_eq(@block.edge_str_to_edge_data("---"), "")
  assert_eq(@block.edge_str_to_edge_start_data("x-- "), "arrow_cross")
  assert_eq(@block.edge_str_to_edge_start_data(" o--"), "arrow_circle")
}

///|
test "names the shape of each bracket pair" {
  let pairs = [
    ("[]", "square"),
    ("()", "round"),
    ("(())", "circle"),
    (">]", "rect_left_inv_arrow"),
    ("{}", "diamond"),
    ("{{}}", "hexagon"),
    ("([])", "stadium"),
    ("[[]]", "subroutine"),
    ("[()]", "cylinder"),
    ("((()))", "doublecircle"),
    ("[//]", "lean_right"),
    ("[\\\\]", "lean_left"),
    ("[/\\]", "trapezoid"),
    ("[\\/]", "inv_trapezoid"),
    ("<[]>", "block_arrow"),
    ("(]", "na"),
  ]
  for pair in pairs {
    assert_eq(@block.type_str_to_type(Some(pair.0)), pair.1, msg=pair.0)
  }
  assert_eq(@block.type_str_to_type(None), "na")
}

///|
test "keeps every link of a chain and counts links between the same ends" {
  assert_eq(
    hierarchy([
      Chain([
        @block.Block::new("a", "na"),
        link("a", "b"),
        @block.Block::new("b", "na"),
      ]),
      Chain([
        @block.Block::new("a", "na"),
        link("a", "b", label="x"),
        @block.Block::new("b", "na"),
      ]),
      One(leaf("c")),
    ]),
    (
      #|root columns=-1
      #|  a na "a"
      #|  b na "b"
      #|  c na "c" span=1
      #|edge 1-a-b a->b "" arrow_open arrow_point normal solid
      #|edge 2-a-b a->b "x" arrow_open arrow_point normal solid
    ),
  )
}

///|
test "merges later statements about a block into the first" {
  assert_eq(
    hierarchy([
      One(leaf("a")),
      One(leaf("b")),
      One(leaf("a", kind="square", label="Named")),
      One(leaf("b", kind="circle", label="x")),
      One(leaf("b", label="b")),
    ]),
    (
      #|root columns=-1
      #|  a square "Named" span=1
      #|  b circle "x" span=1
    ),
  )
}

///|
test "applies classes and styles, also when they come before the block" {
  assert_eq(
    hierarchy([
      One(
        @block.Block::new(
          "hot",
          "classDef",
          css="fill:#f96,stroke:#333,color:#400;",
        ),
      ),
      One(@block.Block::new("a", "applyClass", style_class="hot")),
      One(
        @block.Block::new(
          "b",
          "applyStyles",
          styles_str="fill:red;stroke:blue,stroke-width:2px",
        ),
      ),
      One(leaf("a")),
      One(leaf("b")),
      One(leaf("c")),
      One(@block.Block::new("b, c", "applyClass", style_class="hot")),
      One(@block.Block::new("c", "applyStyles", styles_str="")),
    ]),
    (
      #|root columns=-1
      #|  a na "a" span=1 classes=hot
      #|  b na "b" span=1 classes=hot styles=fill:red;stroke:blue|stroke-width:2px
      #|  c na "c" span=1 classes=hot
      #|class hot styles=[fill:#f96|stroke:#333|color:#400] text=[fill:#400]
    ),
  )
}

///|
test "turns color into fill for text and drops the first semicolon of each entry" {
  assert_eq(
    hierarchy([
      One(
        @block.Block::new(
          "black",
          "classDef",
          css="color:#ffffff, fill:#000000;",
        ),
      ),
      One(@block.Block::new("black", "classDef", css="stroke:#fill;x;y")),
      One(@block.Block::new("empty", "classDef", css="")),
    ]),
    (
      #|root columns=-1
      #|class black styles=[color:#ffffff|fill:#000000|stroke:#fillx;y] text=[fill:#ffffff]
      #|class empty styles=[] text=[]
    ),
  )
}

///|
test "expands spaces, nests composites and numbers their colours in declaration order" {
  assert_eq(
    hierarchy([
      One(@block.Block::new("", "column-setting", columns=2)),
      One(@block.Block::new("a", "na", width_in_columns=3)),
      One(@block.Block::new("id-1", "space", width=2)),
      One(
        @block.Block::new("id-3", "composite", children=[
          @block.Block::new("", "column-setting", columns=3),
          leaf("b"),
          @block.Block::new("id-2", "composite", children=[
            @block.Block::new("c", "na"),
          ]),
        ]),
      ),
      One(
        @block.Block::new("", "composite", children=[
          @block.Block::new("d", "na"),
        ]),
      ),
      One(
        @block.Block::new("g", "composite", label="Group", width_in_columns=2, children=[
          @block.Block::new("e", "na"),
        ]),
      ),
    ]),
    (
      #|root columns=2
      #|  a na "a" span=3
      #|  id-1-0 space "id-1" width=2
      #|  id-1-1 space "id-1" width=2
      #|  id-3 composite "" columns=3 color=0
      #|    b na "b" span=1
      #|    id-2 composite "" color=1
      #|      c na "c"
      #|  g composite "Group" span=2 color=2
      #|    e na "e"
      #|warn Block a width 3 exceeds configured column width 2
    ),
  )
}

///|
test "lets a later column statement set the count back to auto" {
  assert_eq(
    hierarchy([
      One(@block.Block::new("", "column-setting", columns=3)),
      One(@block.Block::new("", "column-setting", columns=-1)),
      One(@block.Block::new("a", "na")),
    ]),
    (
      #|root columns=-1
      #|  a na "a"
    ),
  )
}

///|
test "refuses more space blocks than the limit" {
  assert_eq(
    hierarchy([
      One(@block.Block::new("id-1", "space", width=60000)),
      One(@block.Block::new("id-2", "space", width=60000)),
    ]),
    "error limit A block diagram can hold at most 100000 space blocks.",
  )
}

///|
test "lets a block be called root" {
  assert_eq(
    hierarchy([
      One(@block.Block::new("root", "na")),
      One(@block.Block::new("leaf", "na")),
    ]),
    (
      #|root columns=-1
      #|  root na "root"
      #|  leaf na "leaf"
    ),
  )
}

///|
test "loses the children of a composite that reuses an id" {
  assert_eq(
    hierarchy([
      One(leaf("a")),
      One(
        @block.Block::new("a", "composite", children=[
          @block.Block::new("b", "na"),
        ]),
      ),
    ]),
    (
      #|root columns=-1
      #|  a composite "" span=1
    ),
  )
}

///|
test "counts generated ids" {
  let db = @block.BlockDb::new()
  assert_eq(db.generate_id(), "id-1")
  assert_eq(db.generate_id(), "id-2")
}
