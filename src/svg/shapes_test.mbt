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
fn draw(shape : String) -> String {
  @svg.draw_shape(shape, 101.25, 43.2, attrs, line)
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

///|
test "polygon shapes leave room for the label" {
  inspect(size("diam", 37.5, 19.2), content="97.02000000000001 60.6375 0")
  inspect(size("hex", 37.5, 19.2), content="95.1 43.2 0")
  inspect(size("odd", 37.5, 19.2), content="84.3 43.2 0")
  inspect(size("lean-r", 37.5, 19.2), content="95.1 43.2 0")
  inspect(size("lean-l", 37.5, 19.2), content="95.1 43.2 0")
  inspect(size("trap-b", 37.5, 19.2), content="95.1 43.2 0")
  inspect(size("trap-t", 37.5, 19.2), content="95.1 43.2 0")
  inspect(
    size("tri", 37.5, 19.2),
    content="100 53.577981651376156 7.188990825688078",
  )
  inspect(
    size("flip-tri", 37.5, 19.2),
    content="100 53.577981651376156 -7.188990825688078",
  )
  inspect(size("sl-rect", 37.5, 19.2), content="73.5 53.2 5")
  inspect(size("notch-pent", 37.5, 19.2), content="73.5 43.2 0")
  inspect(size("hourglass", 37.5, 19.2), content="32 40 0")
  inspect(size("bolt", 37.5, 19.2), content="36 56 0")
  inspect(size("bang", 37.5, 19.2), content="101.5 67.2 0")
}

///|
test "polygon shapes are drawn around the origin" {
  inspect(
    draw("diam"),
    content="<polygon points=\"0,-21.6 50.63,0 0,21.6 -50.62,0\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/>",
  )
  inspect(
    draw("hex"),
    content="<polygon points=\"-39.83,-21.6 39.83,-21.6 50.63,0 39.83,21.6 -39.83,21.6 -50.62,0\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/>",
  )
  inspect(
    draw("odd"),
    content="<polygon points=\"-50.62,-21.6 50.63,-21.6 50.63,21.6 -50.62,21.6 -39.83,0\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/>",
  )
  inspect(
    draw("lean-r"),
    content="<polygon points=\"-39.83,-21.6 50.63,-21.6 39.83,21.6 -50.62,21.6\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/>",
  )
  inspect(
    draw("lean-l"),
    content="<polygon points=\"-50.62,-21.6 39.83,-21.6 50.63,21.6 -39.83,21.6\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/>",
  )
  inspect(
    draw("trap-b"),
    content="<polygon points=\"-39.83,-21.6 39.83,-21.6 50.63,21.6 -50.62,21.6\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/>",
  )
  inspect(
    draw("trap-t"),
    content="<polygon points=\"-50.62,-21.6 50.63,-21.6 39.83,21.6 -39.83,21.6\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/>",
  )
  inspect(
    draw("tri"),
    content="<polygon points=\"0,-21.6 50.63,21.6 -50.62,21.6\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/>",
  )
  inspect(
    draw("flip-tri"),
    content="<polygon points=\"-50.62,-21.6 50.63,-21.6 0,21.6\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/>",
  )
  inspect(
    draw("sl-rect"),
    content="<polygon points=\"-50.62,-11.6 50.63,-21.6 50.63,21.6 -50.62,21.6\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/>",
  )
  inspect(
    draw("notch-pent"),
    content="<polygon points=\"-40.62,-21.6 40.63,-21.6 50.63,-11.6 50.63,21.6 -50.62,21.6 -50.62,-11.6\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/>",
  )
  inspect(
    draw("hourglass"),
    content="<polygon points=\"-50.62,-21.6 50.63,-21.6 -50.62,21.6 50.63,21.6\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/>",
  )
  inspect(
    draw("bolt"),
    content="<polygon points=\"15.19,-21.6 -50.62,3.46 -5.06,3.46 -15.19,21.6 50.63,-3.46 5.06,-3.46\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/>",
  )
  inspect(
    draw("bang"),
    content="<polygon points=\"0,-21.6 9.24,-17.27 21.97,-19.46 25.88,-13.85 39.58,-13.47 37.4,-7.68 49.36,-4.81 41.51,0 49.36,4.81 37.4,7.68 39.58,13.47 25.88,13.85 21.97,19.46 9.24,17.27 0,21.6 -9.24,17.27 -21.97,19.46 -25.88,13.85 -39.58,13.47 -37.4,7.68 -49.36,4.81 -41.51,0 -49.36,-4.81 -37.4,-7.68 -39.58,-13.47 -25.88,-13.85 -21.97,-19.46 -9.24,-17.27\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/>",
  )
}

///|
test "round shapes fit the label diagonal" {
  inspect(
    size("circle", 37.5, 19.2),
    content="58.12944338583172 58.12944338583172 0",
  )
  inspect(
    size("dbl-circ", 37.5, 19.2),
    content="68.12944338583172 68.12944338583172 0",
  )
  inspect(size("ellipse", 37.5, 19.2), content="84.75 47.04 0")
  inspect(size("sm-circ", 37.5, 19.2), content="14 14 0")
  inspect(size("f-circ", 37.5, 19.2), content="14 14 0")
  inspect(size("fr-circ", 37.5, 19.2), content="18 18 0")
  inspect(size("cross-circ", 37.5, 19.2), content="44 44 0")
  inspect(size("fork", 37.5, 19.2), content="72 8 0")
}

///|
test "round shapes are drawn around the origin" {
  inspect(
    draw("circle"),
    content="<circle r=\"50.63\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/>",
  )
  inspect(
    draw("dbl-circ"),
    content="<circle r=\"50.63\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><circle r=\"45.63\" fill=\"none\" stroke=\"var(--_l)\"/>",
  )
  inspect(
    draw("ellipse"),
    content="<ellipse rx=\"50.63\" ry=\"21.6\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/>",
  )
  inspect(
    draw("sm-circ"),
    content="<circle r=\"50.63\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/>",
  )
  inspect(
    draw("f-circ"),
    content="<circle r=\"50.63\" fill=\"var(--_l)\" stroke=\"var(--_l)\"/>",
  )
  inspect(
    draw("fr-circ"),
    content="<circle r=\"50.63\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><circle r=\"46.63\" fill=\"var(--_l)\" stroke=\"var(--_l)\"/>",
  )
  inspect(
    draw("cross-circ"),
    content="<circle r=\"50.63\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><path d=\"M-35.8,-35.8L35.8,35.8M35.8,-35.8L-35.8,35.8\" fill=\"none\" stroke=\"var(--_l)\"/>",
  )
  inspect(
    draw("fork"),
    content="<rect x=\"-50.62\" y=\"-21.6\" width=\"101.25\" height=\"43.2\" rx=\"2\" fill=\"var(--_l)\" stroke=\"var(--_l)\"/>",
  )
}
