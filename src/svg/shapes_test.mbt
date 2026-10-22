///|
let attrs = " fill=\"var(--_s)\" stroke=\"var(--_b)\""

///|
let line = " stroke=\"var(--_l)\""

///|
fn size(shape : String, tw : Double, th : Double) -> String {
  let s = @svg.shape_size(shape, tw, th)
  "\{s.w} \{s.h} \{s.dy}"
}

///|
test "rectangular shapes pad the label" {
  inspect(size("rect", 37.5, 19.2), content="73.5 43.2 0")
  inspect(size("rounded", 37.5, 19.2), content="73.5 43.2 0")
  inspect(size("stadium", 37.5, 19.2), content="87.1 43.2 0")
  inspect(size("fr-rect", 37.5, 19.2), content="89.5 43.2 0")
  inspect(size("text", 37.5, 19.2), content="45.5 27.2 0")
  inspect(size("notch-rect", 37.5, 19.2), content="73.5 43.2 0")
  inspect(size("lin-rect", 37.5, 19.2), content="81.5 43.2 0")
  inspect(size("div-rect", 37.5, 19.2), content="73.5 51.2 4")
  inspect(size("win-pane", 37.5, 19.2), content="81.5 51.2 4")
  inspect(size("st-rect", 37.5, 19.2), content="81.5 51.2 4")
  inspect(size("tag-rect", 37.5, 19.2), content="73.5 43.2 0")
  inspect(size("datastore", 37.5, 19.2), content="73.5 43.2 0")
  inspect(size("console", 37.5, 19.2), content="73.5 55.2 6")
  inspect(size("browser", 37.5, 19.2), content="73.5 55.2 6")
  inspect(size("collapsedGroup", 37.5, 19.2), content="81.5 51.2 -2")
}

///|
test "rectangular shapes keep a minimum width" {
  inspect(size("rect", 0, 0), content="48 24 0")
  inspect(size("console", 10, 0), content="72 36 6")
  inspect(size("text", 0, 0), content="8 8 0")
}

///|
test "unknown shapes are sized and drawn as rectangles" {
  inspect(size("nope", 37.5, 19.2), content="73.5 43.2 0")
  inspect(size("constructor", 37.5, 19.2), content="73.5 43.2 0")
  inspect(size("Rect", 37.5, 19.2), content="73.5 43.2 0")
  inspect(
    @svg.draw_shape("nope", 101.25, 43.2, attrs, line),
    content="<rect x=\"-50.62\" y=\"-21.6\" width=\"101.25\" height=\"43.2\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/>",
  )
  inspect(
    @svg.draw_shape("constructor", 101.25, 43.2, attrs, line),
    content="<rect x=\"-50.62\" y=\"-21.6\" width=\"101.25\" height=\"43.2\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/>",
  )
}

///|
test "rectangular shapes are drawn around the origin" {
  inspect(
    @svg.draw_shape("rect", 101.25, 43.2, attrs, line),
    content="<rect x=\"-50.62\" y=\"-21.6\" width=\"101.25\" height=\"43.2\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/>",
  )
  inspect(
    @svg.draw_shape("rounded", 101.25, 43.2, attrs, line),
    content="<rect x=\"-50.62\" y=\"-21.6\" width=\"101.25\" height=\"43.2\" rx=\"12\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/>",
  )
  inspect(
    @svg.draw_shape("stadium", 101.25, 43.2, attrs, line),
    content="<rect x=\"-50.62\" y=\"-21.6\" width=\"101.25\" height=\"43.2\" rx=\"21.6\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/>",
  )
  inspect(
    @svg.draw_shape("fr-rect", 101.25, 43.2, attrs, line),
    content="<rect x=\"-50.62\" y=\"-21.6\" width=\"101.25\" height=\"43.2\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><path d=\"M-42.62,-21.6V21.6M42.63,-21.6V21.6\" fill=\"none\" stroke=\"var(--_l)\"/>",
  )
  inspect(
    @svg.draw_shape("text", 101.25, 43.2, attrs, line),
    content="<rect x=\"-50.62\" y=\"-21.6\" width=\"101.25\" height=\"43.2\" fill=\"none\" stroke=\"none\"/>",
  )
  inspect(
    @svg.draw_shape("notch-rect", 101.25, 43.2, attrs, line),
    content="<polygon points=\"-40.62,-21.6 50.63,-21.6 50.63,21.6 -50.62,21.6 -50.62,-11.6\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/>",
  )
  inspect(
    @svg.draw_shape("lin-rect", 101.25, 43.2, attrs, line),
    content="<rect x=\"-50.62\" y=\"-21.6\" width=\"101.25\" height=\"43.2\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><path d=\"M-42.62,-21.6V21.6\" fill=\"none\" stroke=\"var(--_l)\"/>",
  )
  inspect(
    @svg.draw_shape("div-rect", 101.25, 43.2, attrs, line),
    content="<rect x=\"-50.62\" y=\"-21.6\" width=\"101.25\" height=\"43.2\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><path d=\"M-50.62,-13.6H50.63\" fill=\"none\" stroke=\"var(--_l)\"/>",
  )
  inspect(
    @svg.draw_shape("win-pane", 101.25, 43.2, attrs, line),
    content="<rect x=\"-50.62\" y=\"-21.6\" width=\"101.25\" height=\"43.2\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><path d=\"M-42.62,-21.6V21.6M-50.62,-13.6H50.63\" fill=\"none\" stroke=\"var(--_l)\"/>",
  )
  inspect(
    @svg.draw_shape("st-rect", 101.25, 43.2, attrs, line),
    content="<rect x=\"-42.62\" y=\"-21.6\" width=\"93.25\" height=\"35.2\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><rect x=\"-46.62\" y=\"-17.6\" width=\"93.25\" height=\"35.2\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><rect x=\"-50.62\" y=\"-13.6\" width=\"93.25\" height=\"35.2\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/>",
  )
  inspect(
    @svg.draw_shape("tag-rect", 101.25, 43.2, attrs, line),
    content="<rect x=\"-50.62\" y=\"-21.6\" width=\"101.25\" height=\"43.2\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><path d=\"M38.63,21.6L50.63,9.6\" fill=\"none\" stroke=\"var(--_l)\"/>",
  )
  inspect(
    @svg.draw_shape("console", 101.25, 43.2, attrs, line),
    content="<rect x=\"-50.62\" y=\"-21.6\" width=\"101.25\" height=\"43.2\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><path d=\"M-50.62,-9.6H50.63M-43.62,-17.6l3,2.5l-3,2.5M-37.62,-12.6h4\" fill=\"none\" stroke=\"var(--_l)\"/>",
  )
  inspect(
    @svg.draw_shape("browser", 101.25, 43.2, attrs, line),
    content="<rect x=\"-50.62\" y=\"-21.6\" width=\"101.25\" height=\"43.2\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><path d=\"M-50.62,-9.6H50.63\" fill=\"none\" stroke=\"var(--_l)\"/><circle cx=\"-42.62\" cy=\"-15.6\" r=\"1.5\" fill=\"none\" stroke=\"var(--_l)\"/><circle cx=\"-35.62\" cy=\"-15.6\" r=\"1.5\" fill=\"none\" stroke=\"var(--_l)\"/><circle cx=\"-28.62\" cy=\"-15.6\" r=\"1.5\" fill=\"none\" stroke=\"var(--_l)\"/>",
  )
  inspect(
    @svg.draw_shape("collapsedGroup", 101.25, 43.2, attrs, line),
    content="<rect x=\"-44.62\" y=\"-13.6\" width=\"89.25\" height=\"35.2\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><rect x=\"-50.62\" y=\"-21.6\" width=\"101.25\" height=\"39.2\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/>",
  )
}

///|
test "a datastore drops only the first border stroke" {
  inspect(
    @svg.draw_shape("datastore", 101.25, 43.2, attrs, line),
    content="<rect x=\"-50.62\" y=\"-21.6\" width=\"101.25\" height=\"43.2\" fill=\"var(--_s)\" stroke=\"none\"/><path d=\"M-50.62,-21.6H50.63M-50.62,21.6H50.63\" fill=\"none\" stroke=\"var(--_l)\"/>",
  )
  inspect(
    @svg.draw_shape(
      "datastore", 50, 30, " fill=\"x\" stroke=\"var(--_b)\" stroke=\"var(--_b)\"",
      " L",
    ),
    content="<rect x=\"-25\" y=\"-15\" width=\"50\" height=\"30\" fill=\"x\" stroke=\"none\" stroke=\"var(--_b)\"/><path d=\"M-25,-15H25M-25,15H25\" fill=\"none\" L/>",
  )
}

///|
test "rounded corners join an existing style" {
  inspect(
    @svg.draw_shape("rect", 10, 10, " style=\"fill:red;\"", line),
    content="<rect x=\"-5\" y=\"-5\" width=\"10\" height=\"10\" style=\"rx:var(--_r);fill:red;\"/>",
  )
}
