///|
fn draws(source : String) -> String {
  let options = {
    ..@types.RenderOptions::default(),
    limit: Some(@double.infinity),
  }
  let result = @core.render([@venn.venn], "venn-beta\n" + source, options) catch {
    @errors.PeleError(failure) => return "error: " + failure.message
  }
  if result.svg.contains("NaN") || result.svg.contains("Infinity") {
    return "not finite"
  }
  "ok"
}

///|
fn lines(count : Int32, line : (Int32) -> String) -> String {
  let out = StringBuilder()
  for i in 0..<count {
    out.write_string(line(i))
  }
  out.to_string()
}

///|
test "thousands of sets" {
  inspect(draws(lines(2000, i => "set s\{i}\n")), content="ok")
  inspect(draws(lines(5000, i => "set s\{i}\n")), content="ok")
}

///|
test "a chain of unions" {
  inspect(
    draws(
      lines(300, i => "set s\{i}\n") +
      lines(299, i => "union s\{i},s\{i + 1}\n"),
    ),
    content="ok",
  )
}

///|
test "every pair of 60 sets is a union" {
  let pairs = StringBuilder()
  for i in 0..<60 {
    for j in (i + 1)..<60 {
      pairs.write_string("union s\{i},s\{j}\n")
    }
  }
  inspect(
    draws(lines(60, i => "set s\{i}\n") + pairs.to_string()),
    content="ok",
  )
}

///|
test "one union of 300 sets" {
  inspect(
    draws(
      lines(300, i => "set s\{i}\n") +
      "union " +
      lines(299, i => "s\{i},") +
      "s299[\"all\"]\n",
    ),
    content="ok",
  )
}

///|
test "the same statement over and over" {
  inspect(draws("set A[\"x\"]:5\n".repeat(8000)), content="ok")
  inspect(
    draws("set A\nset B\n" + "union A,B[\"x\"]:1\n".repeat(5000)),
    content="ok",
  )
  inspect(draws("set A\n" + "  text t\n".repeat(8000)), content="ok")
  inspect(
    draws(
      "set A\nset B\nset C\nunion A,B,C\n" +
      "  text \"t t\"[\"l\"]\n".repeat(5000),
    ),
    content="ok",
  )
  inspect(
    draws("set A\n" + "style A fill:red, color:blue\n".repeat(5000)),
    content="ok",
  )
  inspect(
    draws(
      "set A\nset B\nset C\nunion A,B,C[\"x\"]\n" +
      "style A,B,C fill:gold\n".repeat(5000),
    ),
    content="ok",
  )
  inspect(draws("set A\nunion A,A,A,A[\"x\"]\n".repeat(3000)), content="ok")
}

///|
test "very long text" {
  inspect(draws("title " + "word ".repeat(10000) + "\nset A"), content="ok")
  inspect(draws("set A[\"" + "word ".repeat(10000) + "\"]"), content="ok")
  inspect(draws("set A[" + "a".repeat(50000) + "]"), content="ok")
  inspect(
    draws("set A[\"" + "#35;&amp;<br>".repeat(3800) + "\"]"),
    content="ok",
  )
  inspect(
    draws(
      "set A:" + "9".repeat(50000) + "\nset B\nunion A,B:" + "9".repeat(400),
    ),
    content="ok",
  )
}

///|
test "malformed input terminates" {
  let sources = [
    "set A[\"x".repeat(6000),
    "set A[\"x\" ".repeat(5000),
    "set \"a ".repeat(7000),
    "style A fill:" + "rgb(1,2,".repeat(6000),
    "style A fill:rgba(" + "1 ".repeat(25000),
    "a%%\n".repeat(12000),
    "%%{\n".repeat(12000),
    "setunionstyletextvenn-beta".repeat(2000),
    "style A fill:" + "#123456789abcdef ".repeat(3000),
    "set A:" + "+1.5-.5 ".repeat(6000),
  ]
  for source in sources {
    draws(source) |> ignore
  }
}
