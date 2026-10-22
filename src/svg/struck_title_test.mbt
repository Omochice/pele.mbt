///|
/// The struck title of the cluster at `index` in a chain of ten clusters, each inside the one before.
fn struck(index : Int32) -> String {
  let nodes = Array::makei(10, i => @layout.cnode(0, 0, parent=i - 1))
  let label = @text.layout_label(
    Some("Group & co"),
    false,
    @text.metrics_measurer,
    14,
    200,
  )
  @svg.struck_title(
    label, 12.5, -3, " class=\"pele-cluster-label\"", "g<1>", nodes, index,
  )
}

///|
test "struck_title outlines the title in the color of the cluster behind it" {
  inspect(
    struck(0),
    content="<g class=\"pele-cluster-title\" data-id=\"g<1>\"><text fill=\"none\" stroke=\"color-mix(in srgb,var(--_a) 50%,var(--_bg))\" stroke-width=\"5\" stroke-linejoin=\"round\" x=\"12.5\" y=\"1.9\" text-anchor=\"middle\">Group &amp; co</text><text class=\"pele-cluster-label\" x=\"12.5\" y=\"1.9\" text-anchor=\"middle\">Group &amp; co</text></g>",
  )
}

///|
test "struck_title tints the outline once more for each cluster it is in, up to eight" {
  let tint = fn(index) {
    let svg = struck(index)
    let from = svg.find("var(--_a) ").unwrap() + 10
    svg[from:from + svg[from:].find("%").unwrap()].to_owned()
  }
  inspect(
    [1, 2, 6, 7, 9].map(tint).join(" "),
    content="75 87.5 99.22 99.61 99.61",
  )
}
