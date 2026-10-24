// The expected markers were taken from pele v1.8.0's classMarker and classMarkerTrim.

///|
test "each relation end has its marker, with its tip on the end of the line" {
  inspect(@class.class_marker_trim("aggregation"), content="16")
  assert_eq(
    @class.class_marker("aggregation", 10.5, 20.25, 0, 1, "var(--_l)"),
    "<path class=\"pele-marker\" d=\"M10.5,20.25L5.5,12.25L10.5,4.25L15.5,12.25Z\" stroke-linejoin=\"round\"/>",
  )
  assert_eq(
    @class.class_marker("aggregation", 10.5, 20.25, 1, 0, "var(--_l)"),
    "<path class=\"pele-marker\" d=\"M10.5,20.25L2.5,25.25L-5.5,20.25L2.5,15.25Z\" stroke-linejoin=\"round\"/>",
  )
  assert_eq(
    @class.class_marker("aggregation", 10.5, 20.25, 0.6, 0.8, "var(--_l)"),
    "<path class=\"pele-marker\" d=\"M10.5,20.25L1.7,16.85L0.9,7.45L9.7,10.85Z\" stroke-linejoin=\"round\"/>",
  )
  assert_eq(
    @class.class_marker(
      "aggregation", 10.5, 20.25, -0.7071067811865476, 0.7071067811865476, "var(--_l)",
    ),
    "<path class=\"pele-marker\" d=\"M10.5,20.25L12.62,11.06L21.81,8.94L19.69,18.13Z\" stroke-linejoin=\"round\"/>",
  )
  inspect(@class.class_marker_trim("extension"), content="12")
  assert_eq(
    @class.class_marker("extension", 10.5, 20.25, 0, 1, "var(--_l)"),
    "<path class=\"pele-marker\" d=\"M10.5,20.25L4.5,8.25L16.5,8.25Z\" stroke-linejoin=\"round\"/>",
  )
  assert_eq(
    @class.class_marker("extension", 10.5, 20.25, 1, 0, "var(--_l)"),
    "<path class=\"pele-marker\" d=\"M10.5,20.25L-1.5,26.25L-1.5,14.25Z\" stroke-linejoin=\"round\"/>",
  )
  assert_eq(
    @class.class_marker("extension", 10.5, 20.25, 0.6, 0.8, "var(--_l)"),
    "<path class=\"pele-marker\" d=\"M10.5,20.25L-1.5,14.25L8.1,7.05Z\" stroke-linejoin=\"round\"/>",
  )
  assert_eq(
    @class.class_marker(
      "extension", 10.5, 20.25, -0.7071067811865476, 0.7071067811865476, "var(--_l)",
    ),
    "<path class=\"pele-marker\" d=\"M10.5,20.25L14.74,7.52L23.23,16.01Z\" stroke-linejoin=\"round\"/>",
  )
  inspect(@class.class_marker_trim("composition"), content="16")
  assert_eq(
    @class.class_marker("composition", 10.5, 20.25, 0, 1, "var(--_l)"),
    "<path class=\"pele-marker\" d=\"M10.5,20.25L5.5,12.25L10.5,4.25L15.5,12.25Z\" stroke-linejoin=\"round\" fill=\"var(--_l)\"/>",
  )
  assert_eq(
    @class.class_marker("composition", 10.5, 20.25, 1, 0, "var(--_l)"),
    "<path class=\"pele-marker\" d=\"M10.5,20.25L2.5,25.25L-5.5,20.25L2.5,15.25Z\" stroke-linejoin=\"round\" fill=\"var(--_l)\"/>",
  )
  assert_eq(
    @class.class_marker("composition", 10.5, 20.25, 0.6, 0.8, "var(--_l)"),
    "<path class=\"pele-marker\" d=\"M10.5,20.25L1.7,16.85L0.9,7.45L9.7,10.85Z\" stroke-linejoin=\"round\" fill=\"var(--_l)\"/>",
  )
  assert_eq(
    @class.class_marker(
      "composition", 10.5, 20.25, -0.7071067811865476, 0.7071067811865476, "var(--_l)",
    ),
    "<path class=\"pele-marker\" d=\"M10.5,20.25L12.62,11.06L21.81,8.94L19.69,18.13Z\" stroke-linejoin=\"round\" fill=\"var(--_l)\"/>",
  )
  inspect(@class.class_marker_trim("dependency"), content="7")
  assert_eq(
    @class.class_marker("dependency", 10.5, 20.25, 0, 1, "var(--_l)"),
    "<path class=\"pele-marker\" d=\"M10.5,20.25L7.14,12.25L13.86,12.25Z\" fill=\"var(--_l)\" stroke=\"none\"/>",
  )
  assert_eq(
    @class.class_marker("dependency", 10.5, 20.25, 1, 0, "var(--_l)"),
    "<path class=\"pele-marker\" d=\"M10.5,20.25L2.5,23.61L2.5,16.89Z\" fill=\"var(--_l)\" stroke=\"none\"/>",
  )
  assert_eq(
    @class.class_marker("dependency", 10.5, 20.25, 0.6, 0.8, "var(--_l)"),
    "<path class=\"pele-marker\" d=\"M10.5,20.25L3.01,15.87L8.39,11.83Z\" fill=\"var(--_l)\" stroke=\"none\"/>",
  )
  assert_eq(
    @class.class_marker(
      "dependency", 10.5, 20.25, -0.7071067811865476, 0.7071067811865476, "var(--_l)",
    ),
    "<path class=\"pele-marker\" d=\"M10.5,20.25L13.78,12.22L18.53,16.97Z\" fill=\"var(--_l)\" stroke=\"none\"/>",
  )
  inspect(@class.class_marker_trim("lollipop"), content="10")
  assert_eq(
    @class.class_marker("lollipop", 10.5, 20.25, 0, 1, "var(--_l)"),
    "<circle class=\"pele-marker\" cx=\"10.5\" cy=\"15.25\" r=\"5\"/>",
  )
  assert_eq(
    @class.class_marker("lollipop", 10.5, 20.25, 1, 0, "var(--_l)"),
    "<circle class=\"pele-marker\" cx=\"5.5\" cy=\"20.25\" r=\"5\"/>",
  )
  assert_eq(
    @class.class_marker("lollipop", 10.5, 20.25, 0.6, 0.8, "var(--_l)"),
    "<circle class=\"pele-marker\" cx=\"7.5\" cy=\"16.25\" r=\"5\"/>",
  )
  assert_eq(
    @class.class_marker(
      "lollipop", 10.5, 20.25, -0.7071067811865476, 0.7071067811865476, "var(--_l)",
    ),
    "<circle class=\"pele-marker\" cx=\"14.04\" cy=\"16.71\" r=\"5\"/>",
  )
  inspect(@class.class_marker_trim("none"), content="0")
  assert_eq(@class.class_marker("none", 10.5, 20.25, 0, 1, "var(--_l)"), "")
  assert_eq(@class.class_marker("none", 10.5, 20.25, 1, 0, "var(--_l)"), "")
  assert_eq(@class.class_marker("none", 10.5, 20.25, 0.6, 0.8, "var(--_l)"), "")
  assert_eq(
    @class.class_marker(
      "none", 10.5, 20.25, -0.7071067811865476, 0.7071067811865476, "var(--_l)",
    ),
    "",
  )
}
