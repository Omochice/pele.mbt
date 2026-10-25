///|
const N : Int32 = 50000

///|
/// Draws `source` without a source length limit and tells what came out, in the form the expected values were taken from pele in.
fn outcome(source : String) -> String {
  let options = {
    ..@types.RenderOptions::default(),
    limit: Some(@double.infinity),
  }
  let result = @core.render([@architecture.architecture], source, options) catch {
    @errors.PeleError(failure) => return "error \{failure.code.to_string()}"
  }
  let out = result.svg
  "drawn nodes=\{count(out, "class=\"pele-node ")} groups=\{count(out, "class=\"pele-cluster\"")} edges=\{count(out, "class=\"pele-edge\"")} \{result.width}x\{result.height}"
}

///|
fn repeat(count : Int32, line : (Int32) -> String) -> String {
  let out = StringBuilder()
  for i in 0..<count {
    out.write_string(line(i))
  }
  out.to_string()
}

///|
fn services(count : Int32) -> String {
  repeat(count, i => "service n\{i}\n")
}

///|
fn diagonal_group(g : Int32, side : String) -> String {
  "group g\{g}\n" +
  repeat(12, i => "service m\{g}x\{i} in g\{g}\n") +
  repeat(11, i => "m\{g}x\{i}:\{side}:m\{g}x\{i + 1}\n")
}

///|
test "large layouts are drawn as pele draws them" {
  inspect(
    outcome(HEAD + services(4500)),
    content="drawn nodes=4500 groups=0 edges=0 8336x4200",
  )
  inspect(
    outcome(
      HEAD + services(2000) + repeat(1999, i => "n\{i}:R -- L:n\{i + 1}\n"),
    ),
    content="drawn nodes=2000 groups=0 edges=1999 175976x64",
  )
  inspect(
    outcome(
      HEAD + services(2000) + repeat(1999, i => "n\{i}:R -- T:n\{i + 1}\n"),
    ),
    content="drawn nodes=2000 groups=0 edges=1999 175976x175976",
  )
  inspect(
    outcome(HEAD + services(2000) + repeat(1999, i => "n0:R -- L:n\{i + 1}\n")),
    content="drawn nodes=2000 groups=0 edges=1999 152x175888",
  )
  inspect(
    outcome(HEAD + services(2000) + repeat(1999, i => "n0:B -- L:n\{i + 1}\n")),
    content="drawn nodes=2000 groups=0 edges=1999 152x175976",
  )
  inspect(
    outcome(HEAD + services(2000) + repeat(1999, i => "n0:R -- R:n\{i + 1}\n")),
    content="drawn nodes=2000 groups=0 edges=1999 80x175976",
  )
  inspect(
    outcome(
      HEAD +
      services(1800) +
      repeat(599, i => {
        "n\{i * 3}:B -- T:n\{i * 3 + 3}\nn\{i * 3}:R -- L:n\{i * 3 + 1}\nn\{i * 3}:R -- L:n\{i * 3 + 2}\n"
      }),
    ),
    content="drawn nodes=1800 groups=0 edges=1797 328x105400",
  )
  inspect(
    outcome(HEAD + "service a\nservice b\n" + "a:R <-[x]-> L:b\n".repeat(3000)),
    content="drawn nodes=2 groups=0 edges=3000 152x64",
  )
  inspect(
    outcome(HEAD + "service a\n" + "a:R --> L:a\n".repeat(2500)),
    content="drawn nodes=1 groups=0 edges=2500 96x80",
  )
  let complete = StringBuilder()
  complete.write_string(HEAD + services(70))
  for i in 0..<70 {
    for j in (i + 1)..<70 {
      complete.write_string("n\{i}:R -- L:n\{j}\n")
    }
  }
  inspect(
    outcome(complete.to_string()),
    content="drawn nodes=70 groups=0 edges=2415 168x6048",
  )
  inspect(
    outcome(
      HEAD +
      services(2000) +
      "align row " +
      repeat(1000, i => "n\{i} ") +
      "\n" +
      repeat(1000, i => "align column n\{i} n\{i + 1000}\n"),
    ),
    content="drawn nodes=2000 groups=0 edges=0 87976x152",
  )
}

///|
test "deep, many, and large groups are drawn as pele draws them" {
  inspect(
    outcome(
      HEAD +
      "group g0\n" +
      repeat(1999, i => "group g\{i + 1} in g\{i}\n") +
      "service a in g1999\n",
    ),
    content="drawn nodes=1 groups=2000 edges=0 80064x80064",
  )
  inspect(
    outcome(
      HEAD +
      "group g0[T]\n" +
      repeat(999, i => "group g\{i + 1}[T] in g\{i}\n") +
      "service a in g999\nservice b\n" +
      "a:R -- L:b\n".repeat(500),
    ),
    content="drawn nodes=2 groups=1000 edges=500 40152x56064",
  )
  inspect(
    outcome(
      HEAD +
      repeat(1200, i => "group g\{i}\nservice n\{i} in g\{i}\n") +
      repeat(1199, i => "n\{i}:R -- L:n\{i + 1}\n"),
    ),
    content="drawn nodes=1200 groups=1200 edges=1199 153576x104",
  )
  inspect(
    outcome(
      HEAD +
      "service hub\n" +
      repeat(1000, i => {
        "group g\{i}\nservice n\{i} in g\{i}\nhub:R -- L:n\{i}\n"
      }),
    ),
    content="drawn nodes=1001 groups=1000 edges=1000 192x127976",
  )
  inspect(
    outcome(
      HEAD +
      "service hub\n" +
      repeat(40, g => diagonal_group(g, "R -- T") + "hub:R -- L:m\{g}x0\n"),
    ),
    content="drawn nodes=481 groups=40 edges=480 1160x43816",
  )
  inspect(
    outcome(
      HEAD +
      services(1500) +
      repeat(1499, i => "n\{i}:B -- T:n\{i + 1}\n") +
      repeat(20, g => diagonal_group(g, "B -- R") + "n0:R -- L:m\{g}x0\n"),
    ),
    content="drawn nodes=1740 groups=20 edges=1739 1160x142280",
  )
  inspect(
    outcome(
      HEAD +
      "group g0[A title]\n" +
      repeat(300, i => "group g\{i + 1}[A title] in g\{i}\n") +
      repeat(1500, i => "service n\{i} in g\{i % 301}\n") +
      repeat(1499, i => "n\{i}:R -- L:n\{i + 1}\n"),
    ),
    content="drawn nodes=1500 groups=301 edges=1499 38856x17272",
  )
  inspect(
    outcome(
      HEAD +
      repeat(600, i => "group g\{i}[Title]\nservice n\{i} in g\{i}\n") +
      repeat(599, i => "n\{i}:B --> T:n\{i + 1}\n") +
      "n0:B -- T:n599\n".repeat(800),
    ),
    content="drawn nodes=600 groups=600 edges=1399 232x86088",
  )
}

///|
test "long text is drawn as pele draws it" {
  inspect(
    outcome(HEAD + "service a[" + "word ".repeat(N / 5) + "]"),
    content=(
      #|drawn nodes=1 groups=0 edges=0 90x105068
    ),
  )
  inspect(
    outcome(HEAD + "service a[" + "w".repeat(N) + "]"),
    content="drawn nodes=1 groups=0 edges=0 577616x92",
  )
  inspect(
    outcome(HEAD + "service a \"" + "word ".repeat(N / 5) + "\""),
    content="drawn nodes=1 groups=0 edges=0 64x64",
  )
  inspect(
    outcome(HEAD + "service a \"" + "\u{1F600}".repeat(N / 2) + "\""),
    content="drawn nodes=1 groups=0 edges=0 64x64",
  )
  inspect(
    outcome(
      HEAD +
      "group g[" +
      "word ".repeat(N / 10) +
      "]\nservice a in g\nservice b\na:R -[" +
      "*a _b ".repeat(N / 12) +
      "]- L:b",
    ),
    content=(
      #|drawn nodes=2 groups=1 edges=1 576x22555
    ),
  )
  inspect(
    outcome(HEAD + "service a[\"" + "#35;&amp;<br>".repeat(N / 13) + "\"]"),
    content=(
      #|drawn nodes=1 groups=0 edges=0 64x80855
    ),
  )
}

///|
test "inputs that make a naive scanner rescan the text are read in one pass" {
  inspect(
    outcome(HEAD + repeat(N / 20, i => "service n\{i}[\"a]\n")),
    content="drawn nodes=2500 groups=0 edges=0 6224x4152",
  )
  inspect(
    outcome(HEAD + repeat(N / 20, i => "service n\{i}['a]\n")),
    content="drawn nodes=2500 groups=0 edges=0 6224x4152",
  )
  inspect(
    outcome(
      HEAD +
      "service a[\"x]\n" +
      repeat(N / 20, i => "service n\{i}[\\\"\\']\n"),
    ),
    content="drawn nodes=2501 groups=0 edges=0 6224x4152",
  )
  inspect(
    outcome(HEAD + "title a %% b\n".repeat(N / 13)),
    content="drawn nodes=0 groups=0 edges=0 25x52",
  )
  inspect(
    outcome(HEAD + " ".repeat(N) + "service a"),
    content="drawn nodes=1 groups=0 edges=0 64x64",
  )
  inspect(
    outcome(HEAD + "service " + "a-".repeat(N / 2) + "a"),
    content="drawn nodes=1 groups=0 edges=0 64x64",
  )
  inspect(
    outcome(
      HEAD + repeat(N / 20, i => "service service\{i}\n") + "service in-in-in\n",
    ),
    content="drawn nodes=2501 groups=0 edges=0 6224x3144",
  )
  inspect(
    outcome("\n".repeat(3000) + HEAD + "\n".repeat(N) + "service a"),
    content="drawn nodes=1 groups=0 edges=0 64x64",
  )
}

///|
test "malformed inputs end in the error pele gives" {
  inspect(outcome(HEAD + "service a" + "[".repeat(N)), content="error syntax")
  inspect(
    outcome(HEAD + "service a(" + "a:-".repeat(N / 3)),
    content="error syntax",
  )
  inspect(
    outcome(HEAD + "service a \"" + "a\\\"".repeat(N / 3)),
    content="error syntax",
  )
  inspect(
    outcome(HEAD + repeat(N / 14, i => "service n\{i} \"a\n")),
    content="error syntax",
  )
  inspect(
    outcome(HEAD + "service a\nservice b\na:R " + "-".repeat(N) + " L:b"),
    content="error syntax",
  )
  inspect(
    outcome(HEAD + "service a\nservice b\n" + "a:R ---\n".repeat(N / 8)),
    content="error syntax",
  )
  inspect(
    outcome(HEAD + "%%{\n".repeat(N / 4)),
    content="drawn nodes=0 groups=0 edges=0 16x16",
  )
  inspect(
    outcome(
      HEAD + "accDescr\n".repeat(N / 12) + "accDescr {" + " a\n".repeat(1000),
    ),
    content="error syntax",
  )
  inspect(outcome(HEAD + "L".repeat(N)), content="error syntax")
  inspect(
    outcome(HEAD + repeat(N / 20, i => "service n\{i} ---\n")),
    content="error syntax",
  )
  inspect(
    outcome(HEAD + "accDescr\n".repeat(N / 12) + "accDescr { a }\n"),
    content="error syntax",
  )
  inspect(
    outcome(HEAD + "service a\nservice b\na:R " + "<>".repeat(N / 2)),
    content="error syntax",
  )
  inspect(
    outcome(HEAD + "service a\na" + "{group}".repeat(N / 7)),
    content="error syntax",
  )
}

///|
test "refuses source over the default limit" {
  match drawn(HEAD + services(6000)) {
    Ok(_) => fail("expected the source to be refused")
    Err(failure) =>
      inspect(failure.message.contains("limit of 50000"), content="true")
  }
}
