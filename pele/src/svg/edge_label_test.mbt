///|
test "write_edge_label puts the label on a patch of the background" {
  let label = @text.layout_label(
    Some("yes"),
    false,
    @text.metrics_measurer,
    14,
    200,
  )
  inspect(
    written(out => @svg.write_edge_label(out, "A-->B", label, 50.123, -20, "")),
    content="<g class=\"pele-edge-label\" data-id=\"A--&gt;B\"><rect x=\"35.23\" y=\"-30.5\" width=\"29.78\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"50.12\" y=\"-15.1\" text-anchor=\"middle\">yes</text></g>",
  )
}

///|
test "write_edge_label decodes and escapes the id and passes the text attributes on" {
  let label = @text.layout_label(
    Some("a long label<br>on two lines"),
    false,
    @text.metrics_measurer,
    14,
    200,
  )
  inspect(
    written(out => {
      @svg.write_edge_label(
        out, "e&amp;1\"<x>", label, 0, 0, " fill=\"var(--_m)\"",
      )
    }),
    content=(
      #|<g class="pele-edge-label" data-id="e&amp;1&quot;&lt;x&gt;"><rect x="-40.96" y="-18" width="81.92" height="36" rx="3" fill="var(--_bg)"/><text fill="var(--_m)" text-anchor="middle" xml:space="preserve"><tspan x="0" y="-4.1">a long label</tspan><tspan x="0" y="13.9">on two lines</tspan></text></g>
    ),
  )
}
