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
  let result = @core.render([@block.block], source, options) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "\{result.width}x\{result.height} \{result.svg}"
}

///|
test "blocks, groups and edge labels draw the host's icons" {
  inspect(
    with_icons(
      "block-beta\n  columns 2\n  a[\"fa:fa-car A\"] b\n  block:g[\"fa:fa-car group\"]\n    c\n  end\n  a -- \"fa:fa-car x\" --> b\n",
      icons=host([("fa:fa-car", "<path id=\"car\"/>")]),
    ),
    content="207x228 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-block\" viewBox=\"0 0 207 228\" width=\"207\" height=\"228\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"block\"><g class=\"pele-clusters\"><g class=\"pele-cluster\" data-id=\"g\"><rect x=\"8\" y=\"120\" width=\"89.36\" height=\"100\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"40\" y=\"147.6\" text-anchor=\"start\"> group</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"20\" y=\"133.2\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"1-a-b\"><path d=\"M97.36,58L102.36,58\"/><path class=\"pele-marker\" d=\"M109.36,58L101.36,61.36L101.36,54.64Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect\" data-id=\"a\" transform=\"translate(52.68,58)\"><rect x=\"-44.68\" y=\"-50\" width=\"89.36\" height=\"100\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"2.44\" y=\"5.6\" text-anchor=\"start\"> A</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"-17.56\" y=\"-8.8\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g><g class=\"pele-node pele-shape-rect\" data-id=\"b\" transform=\"translate(154.04,58)\"><rect x=\"-44.68\" y=\"-50\" width=\"89.36\" height=\"100\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"c\" transform=\"translate(52.68,184)\"><rect x=\"-32.68\" y=\"-24\" width=\"65.36\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">c</text></g></g><g class=\"pele-edge-labels\" font-size=\"14\"><g class=\"pele-edge-label\" data-id=\"1-a-b\"><rect x=\"85.16\" y=\"47.5\" width=\"36.39\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"106.66\" y=\"62.9\" text-anchor=\"start\"> x</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"89.16\" y=\"50.3\" width=\"15.4\" height=\"15.4\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g></g></svg>",
  )
}

///|
test "a block arrow holding only an icon is sized for its label" {
  inspect(
    with_icons(
      "block-beta\n  arrow<[\"fa:fa-car\"]>(right)\n",
      icons=host([("fa:fa-car", "<path id=\"car\"/>")]),
    ),
    content="68x62 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-block\" viewBox=\"0 0 68 62\" width=\"68\" height=\"62\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"block\"><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-block-arrow\" data-id=\"arrow\" transform=\"translate(34,31)\"><polygon points=\"-26,-16 6,-16 6,-23 26,0 6,23 6,16 -26,16\" stroke-linejoin=\"round\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><text class=\"pele-label\" text-anchor=\"middle\" xml:space=\"preserve\"></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"-20\" y=\"-8.8\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g></g></svg>",
  )
}
