///|
/// A host that has exactly the icons in `pairs`, by name.
fn host(pairs : Array[(String, String)]) -> @types.IconResolver {
  let icons = Map::from_array(pairs)
  name => icons.get(name)
}

///|
/// The size and drawing of `source` for a host with `icons`, or the message of its error.
fn with_icons(source : String, icons~ : @types.IconResolver) -> String {
  let options = { ..@types.RenderOptions::default(), icons: Some(icons), }
  let result = @core.render([@agentflow.agentflow], source, options) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "\{result.width}x\{result.height} \{result.svg}"
}

///|
test "nodes draw the host's icons" {
  inspect(
    with_icons(
      "agentflow-beta\n  a[fa:fa-car A] --> b[B]\n",
      icons=host([("fa:fa-car", "<path id=\"car\"/>")]),
    ),
    content="172x160 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 172 160\" width=\"172\" height=\"160\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\"><path d=\"M86,56L86,97\"/><path class=\"pele-marker\" d=\"M86,104L82.64,96L89.36,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(86,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"2.44\" y=\"5.6\" text-anchor=\"start\"> A</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"-17.56\" y=\"-8.8\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"b\" transform=\"translate(86,128)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">B</text></g></g></svg>",
  )
}

///|
test "edge labels draw the host's icons" {
  inspect(
    with_icons(
      "agentflow-beta\n  a[\"fa:fa-car A\"]\n  a -- fa:fa-car go --> b\n",
      icons=host([("fa:fa-car", "<path id=\"car\"/>")]),
    ),
    content="172x185 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 172 185\" width=\"172\" height=\"185\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\"><path d=\"M86,56L86,122\"/><path class=\"pele-marker\" d=\"M86,129L82.64,121L89.36,121Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\"><g class=\"pele-edge-label\" data-id=\"L_a_b_0\"><rect x=\"63.52\" y=\"82\" width=\"44.96\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"85.02\" y=\"97.4\" text-anchor=\"start\"> go</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"67.52\" y=\"84.8\" width=\"15.4\" height=\"15.4\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(86,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"2.44\" y=\"5.6\" text-anchor=\"start\"> A</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"-17.56\" y=\"-8.8\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"b\" transform=\"translate(86,153)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b</text></g></g></svg>",
  )
}
