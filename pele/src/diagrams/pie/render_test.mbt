///|
fn svg(source : String, max_width? : Double) -> String {
  let options = { ..@types.RenderOptions::default(), max_width, }
  let result = @core.render([@pie.pie], source, options) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "\{result.width}x\{result.height} \{result.svg}"
}

///|
/// "ok", or the code, message, type and Mermaid type of the error.
fn outcome(source : String) -> String {
  let options = @types.RenderOptions::default()
  let _ = @core.render([@pie.pie], source, options) catch {
    @errors.PeleError(failure) =>
      return "\{failure.code.to_string()} \{failure.message} \{failure.kind.unwrap_or("-")} \{failure.mermaid_type.unwrap_or("-")}"
  }
  "ok"
}

///|
test "a legend position nested thousands of arrays deep is written to the end" {
  let nested = (depth : Int32) => {
    "%%{init: {\"pie\": {\"legendPosition\": " +
    "[".repeat(depth) +
    "\"left\"" +
    "]".repeat(depth) +
    "}}}%%\npie\n\"a\": 1"
  }
  let left = svg(nested(0))
  inspect(outcome(nested(5000)), content="ok")
  assert_eq(svg(nested(5000)), left)
  assert_eq(svg(nested(12000)), left)
}

///|
test "a legend below the chart" {
  inspect(
    svg(
      "---\nconfig:\n  pie:\n    legendPosition: bottom\n---\npie\n\"a\":3\n\"b\":1",
    ),
    content="256x328 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-pie\" viewBox=\"0 0 256 328\" width=\"256\" height=\"328\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"pie\"><g class=\"pele-slices\" transform=\"translate(128,128)\" stroke=\"var(--_bg)\" stroke-width=\"1\" stroke-linejoin=\"round\"><path class=\"pele-slice\" data-id=\"a\" d=\"M0,0L0,-120A120,120 0 1 1 -120,0Z\" fill=\"var(--pele-series-1,#4c78a8)\"/><path class=\"pele-slice\" data-id=\"b\" d=\"M0,0L-120,0A120,120 0 0 1 0,-120Z\" fill=\"var(--pele-series-2,#f58518)\"/></g><g class=\"pele-slice-labels\" transform=\"translate(128,128)\" font-size=\"14\" text-anchor=\"middle\" fill=\"var(--_bg)\"><text x=\"63.64\" y=\"68.54\">75%</text><text x=\"-63.64\" y=\"-58.74\">25%</text></g><g class=\"pele-legend\" font-size=\"14\"><g class=\"pele-legend-item\" data-id=\"a\"><rect x=\"114.11\" y=\"275\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--pele-series-1,#4c78a8)\"/><text x=\"138\" y=\"285.9\" text-anchor=\"middle\">a</text></g><g class=\"pele-legend-item\" data-id=\"b\"><rect x=\"114.11\" y=\"301\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--pele-series-2,#f58518)\"/><text x=\"138\" y=\"311.9\" text-anchor=\"middle\">b</text></g></g></svg>",
  )
}

///|
test "a legend on the left at a fixed width" {
  inspect(
    svg(
      "---\nconfig:\n  pie:\n    legendPosition: left\n    useMaxWidth: false\n---\npie title T\n\"a\":3\n\"b\":1",
    ),
    content="316x296 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-pie\" viewBox=\"0 0 316 296\" width=\"316\" height=\"296\" style=\"--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"pie\"><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"158\" y=\"25.6\">T</tspan></text><g class=\"pele-slices\" transform=\"translate(187.78,168)\" stroke=\"var(--_bg)\" stroke-width=\"1\" stroke-linejoin=\"round\"><path class=\"pele-slice\" data-id=\"a\" d=\"M0,0L0,-120A120,120 0 1 1 -120,0Z\" fill=\"var(--pele-series-1,#4c78a8)\"/><path class=\"pele-slice\" data-id=\"b\" d=\"M0,0L-120,0A120,120 0 0 1 0,-120Z\" fill=\"var(--pele-series-2,#f58518)\"/></g><g class=\"pele-slice-labels\" transform=\"translate(187.78,168)\" font-size=\"14\" text-anchor=\"middle\" fill=\"var(--_bg)\"><text x=\"63.64\" y=\"68.54\">75%</text><text x=\"-63.64\" y=\"-58.74\">25%</text></g><g class=\"pele-legend\" font-size=\"14\"><g class=\"pele-legend-item\" data-id=\"a\"><rect x=\"8\" y=\"149\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--pele-series-1,#4c78a8)\"/><text x=\"31.89\" y=\"159.9\" text-anchor=\"middle\">a</text></g><g class=\"pele-legend-item\" data-id=\"b\"><rect x=\"8\" y=\"175\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--pele-series-2,#f58518)\"/><text x=\"31.89\" y=\"185.9\" text-anchor=\"middle\">b</text></g></g></svg>",
  )
}

///|
test "a legend in the middle of the chart" {
  inspect(
    svg("---\nconfig:\n  pie:\n    legendPosition: center\n---\npie\n\"a\":3"),
    content="256x256 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-pie\" viewBox=\"0 0 256 256\" width=\"256\" height=\"256\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"pie\"><g class=\"pele-slices\" transform=\"translate(128,128)\" stroke=\"var(--_bg)\" stroke-width=\"1\" stroke-linejoin=\"round\"><path class=\"pele-slice\" data-id=\"a\" d=\"M0,-120A120,120 0 1 1 0,120A120,120 0 1 1 0,-120Z\" fill=\"var(--pele-series-1,#4c78a8)\"/></g><g class=\"pele-slice-labels\" transform=\"translate(128,128)\" font-size=\"14\" text-anchor=\"middle\" fill=\"var(--_bg)\"><text x=\"0\" y=\"94.9\">100%</text></g><g class=\"pele-legend\" font-size=\"14\"><g class=\"pele-legend-item\" data-id=\"a\"><rect x=\"114.11\" y=\"122\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--pele-series-1,#4c78a8)\"/><text x=\"138\" y=\"132.9\" text-anchor=\"middle\">a</text></g></g></svg>",
  )
}

///|
test "a chart that does not fit maxWidth stacks its legend" {
  inspect(
    svg("pie title Wide\n\"alpha\":3\n\"beta\":1", max_width=200),
    content="200x312 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-pie\" viewBox=\"0 0 200 312\" width=\"200\" height=\"312\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"pie\"><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"100\" y=\"25.6\">Wide</tspan></text><g class=\"pele-slices\" transform=\"translate(100,140)\" stroke=\"var(--_bg)\" stroke-width=\"1\" stroke-linejoin=\"round\"><path class=\"pele-slice\" data-id=\"alpha\" d=\"M0,0L0,-92A92,92 0 1 1 -92,0Z\" fill=\"var(--pele-series-1,#4c78a8)\"/><path class=\"pele-slice\" data-id=\"beta\" d=\"M0,0L-92,0A92,92 0 0 1 0,-92Z\" fill=\"var(--pele-series-2,#f58518)\"/></g><g class=\"pele-slice-labels\" transform=\"translate(100,140)\" font-size=\"14\" text-anchor=\"middle\" fill=\"var(--_bg)\"><text x=\"48.79\" y=\"53.69\">75%</text><text x=\"-48.79\" y=\"-43.89\">25%</text></g><g class=\"pele-legend\" font-size=\"14\"><g class=\"pele-legend-item\" data-id=\"alpha\"><rect x=\"72.88\" y=\"259\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--pele-series-1,#4c78a8)\"/><text x=\"110\" y=\"269.9\" text-anchor=\"middle\">alpha</text></g><g class=\"pele-legend-item\" data-id=\"beta\"><rect x=\"72.88\" y=\"285\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--pele-series-2,#f58518)\"/><text x=\"106.5\" y=\"295.9\" text-anchor=\"middle\">beta</text></g></g></svg>",
  )
}
