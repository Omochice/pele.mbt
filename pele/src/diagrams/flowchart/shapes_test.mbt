///|
test "documented shape names and their aliases are valid" {
  let names = [
    "rect", "squareRect", "cyl", "database", "lean_right", "inv_trapezoid", "doc",
    "lin-doc", "stateStart", "forkJoin",
  ]
  inspect(names.all(@flowchart.is_valid_shape), content="true")
}

///|
test "Mermaid's undocumented internal shapes are valid" {
  let names = ["state", "choice", "icon", "imageSquare", "usecaseJsonTable"]
  inspect(names.all(@flowchart.is_valid_shape), content="true")
}

///|
test "bracket syntax shape names and unknown names are not valid by name" {
  let names = ["square", "round", "ellipse", "Rect", "nope", ""]
  inspect(names.any(@flowchart.is_valid_shape), content="false")
}

///|
test "shapes resolve to their documented short name" {
  let names : Array[String?] = [
    None,
    Some("square"),
    Some("round"),
    Some("ellipse"),
    Some("hexagon"),
    Some("diamond"),
    Some("database"),
    Some("lean_left"),
    Some("doublecircle"),
    Some("choice"),
    Some("nope"),
  ]
  inspect(
    names.map(@flowchart.canonical_shape).join(" "),
    content="rect rect rounded ellipse hex diam cyl lean-l dbl-circ choice rect",
  )
}
