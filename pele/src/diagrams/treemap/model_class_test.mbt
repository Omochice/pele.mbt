///|
fn classes_of(source : String) -> String {
  let ast = @treemap.parse_treemap(source + "\n") catch {
    @errors.PeleError(failure) => return "error: \{failure.message}"
  }
  let classes = @treemap.build_treemap(ast, None).classes
  classes
  .iter()
  .map(entry => "\{entry.0}=[\{entry.1.map(s => s.escape()).join("|")}]")
  .collect()
  .join(" ")
}

///|
test "a class gives its declarations to the rows that use it" {
  inspect(
    built(
      "treemap\n\"S\":::frame\n  \"a\": 1:::hot\n  \"b\": 2\nclassDef hot fill:red,color:blue,stroke:#FFD600;\nclassDef frame fill:#eee,stroke-width:2px",
    ),
    content="S{a=1:::hot [\"fill:red\"|\"color:blue\"|\"stroke:#FFD600\"], b=2}:::frame [\"fill:#eee\"|\"stroke-width:2px\"]",
  )
}

///|
test "a class may be defined before the rows that use it" {
  inspect(
    built("treemap\nclassDef cc fill:red\n\"a\": 1:::cc"),
    content="a=1:::cc [\"fill:red\"]",
  )
}

///|
test "a row that names a class nobody defined keeps its name and no declarations" {
  inspect(built("treemap\n\"a\": 1:::missing"), content="a=1:::missing")
}

///|
test "an escaped comma stays in a declaration and the others separate declarations" {
  inspect(
    classes_of("treemap\nclassDef cc fill:red,font-family:a\\,b,color:blue"),
    content="cc=[\"fill:red\"|\"font-family:a,b\"|\"color:blue\"]",
  )
}

///|
test "a class defined twice collects the declarations of both" {
  inspect(
    classes_of(
      "treemap\nclassDef cc fill:red\nclassDef dd x:1\nclassDef cc stroke:blue",
    ),
    content="cc=[\"fill:red\"|\"stroke:blue\"] dd=[\"x:1\"]",
  )
}

///|
test "a class with no declarations has one empty declaration" {
  inspect(
    built("treemap\n\"a\": 1:::cc\nclassDef cc"),
    content="a=1:::cc [\"\"]",
  )
}

///|
test "the section signs that stand for an escaped comma are also turned into a comma" {
  inspect(
    classes_of("treemap\nclassDef cc content:a§§§b"),
    content="cc=[\"content:a,b\"]",
  )
}
