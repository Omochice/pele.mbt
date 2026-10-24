///|
test "marker_trim leaves room for each of Mermaid's markers and none for others" {
  inspect(@svg.marker_trim("arrow_point"), content="7")
  inspect(@svg.marker_trim("arrow_circle"), content="8")
  inspect(@svg.marker_trim("arrow_cross"), content="4")
  inspect(@svg.marker_trim("none"), content="0")
  inspect(@svg.marker_trim(""), content="0")
}

///|
test "marker draws an arrowhead with its tip at the end of the edge" {
  inspect(
    @svg.marker("arrow_point", 10, 20, 0, 1, "var(--_l)"),
    content="<path class=\"pele-marker\" d=\"M10,20L6.64,12L13.36,12Z\" fill=\"var(--_l)\" stroke=\"none\"/>",
  )
  inspect(
    @svg.marker("arrow_point", -3.333, 7.25, 0.6, -0.8, "#f00"),
    content="<path class=\"pele-marker\" d=\"M-3.33,7.25L-5.44,15.67L-10.82,11.63Z\" fill=\"#f00\" stroke=\"none\"/>",
  )
}

///|
test "marker draws a circle just short of the end of the edge" {
  inspect(
    @svg.marker("arrow_circle", 10, 20, 0, 1, "var(--_l)"),
    content="<circle class=\"pele-marker\" cx=\"10\" cy=\"16\" r=\"3.5\" fill=\"var(--_l)\" stroke=\"none\"/>",
  )
  inspect(
    @svg.marker("arrow_circle", -3.333, 7.25, 0.6, -0.8, "#f00"),
    content="<circle class=\"pele-marker\" cx=\"-5.73\" cy=\"10.45\" r=\"3.5\" fill=\"#f00\" stroke=\"none\"/>",
  )
}

///|
test "marker draws a cross in the line's own stroke" {
  inspect(
    @svg.marker("arrow_cross", 10, 20, 0, 1, "var(--_l)"),
    content="<path class=\"pele-marker\" d=\"M13.5,12.5L6.5,19.5M6.5,12.5L13.5,19.5\"/>",
  )
  inspect(
    @svg.marker("arrow_cross", -3.333, 7.25, 0.6, -0.8, "#f00"),
    content="<path class=\"pele-marker\" d=\"M-10.63,11.15L-0.83,9.75M-5.03,15.35L-6.43,5.55\"/>",
  )
}

///|
test "marker draws nothing for a type Mermaid does not know" {
  inspect(@svg.marker("none", 10, 20, 0, 1, "var(--_l)"), content="")
  inspect(@svg.marker("", 10, 20, 0, 1, "var(--_l)"), content="")
}
