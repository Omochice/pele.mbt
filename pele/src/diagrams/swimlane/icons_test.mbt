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
  let result = @core.render([@swimlane.swimlane], source, options) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "\{result.width}x\{result.height} \{result.svg}"
}

///|
test "lane titles, nodes and edge labels draw the host's icons" {
  inspect(
    with_icons(
      "swimlane-beta\n  subgraph lane1 [fa:fa-car Lane one]\n    A[fa:fa-car A]\n  end\n  subgraph lane2 [Lane two]\n    B\n  end\n  A -- fa:fa-car x --> B\n",
      icons=host([("fa:fa-car", "<path id=\"car\"/>")]),
    ),
    content="232x241 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-swimlane\" viewBox=\"0 0 232 241\" width=\"232\" height=\"241\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"swimlane\"><g class=\"pele-clusters\"><g class=\"pele-cluster pele-lane\" data-id=\"lane2\"><rect x=\"127.17\" y=\"8\" width=\"96\" height=\"225\" fill=\"none\" stroke=\"var(--_b)\"/><rect x=\"127.17\" y=\"8\" width=\"96\" height=\"40\" fill=\"var(--_a)\" stroke=\"var(--_b)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"175.17\" y=\"33.6\" text-anchor=\"middle\">Lane two</text></g><g class=\"pele-cluster pele-lane\" data-id=\"lane1\"><rect x=\"8\" y=\"8\" width=\"119.17\" height=\"225\" fill=\"none\" stroke=\"var(--_b)\"/><rect x=\"8\" y=\"8\" width=\"119.17\" height=\"40\" fill=\"var(--_a)\" stroke=\"var(--_b)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"42\" y=\"33.6\" text-anchor=\"start\"> Lane one</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"22\" y=\"19.2\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_A_B_0\"><path d=\"M103.14,96L155.17,96C167.57,96 175.17,103.6 175.17,116L175.17,154\"/><path class=\"pele-marker\" d=\"M175.17,161L171.81,153L178.53,153Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\"><g class=\"pele-edge-label\" data-id=\"L_A_B_0\"><rect x=\"120.96\" y=\"85.5\" width=\"36.39\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"142.46\" y=\"100.9\" text-anchor=\"start\"> x</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"124.96\" y=\"88.3\" width=\"15.4\" height=\"15.4\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect\" data-id=\"A\" transform=\"translate(67.58,96)\"><rect x=\"-35.56\" y=\"-24\" width=\"71.12\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"2.44\" y=\"5.6\" text-anchor=\"start\"> A</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"-17.56\" y=\"-8.8\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g><g class=\"pele-node pele-shape-rect\" data-id=\"B\" transform=\"translate(175.17,185)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">B</text></g></g></svg>",
  )
}
