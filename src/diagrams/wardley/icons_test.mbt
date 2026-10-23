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
  let result = @core.render([@wardley.wardley], source, options) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "\{result.width}x\{result.height} \{result.svg}"
}

///|
test "component and link labels draw the host's icons" {
  inspect(
    with_icons(
      "wardley-beta\ntitle Test\ncomponent \"fa:fa-car A\" [0.5, 0.5]\ncomponent B [0.2, 0.8]\n\"fa:fa-car A\" -> B ; fa:fa-car x\n",
      icons=host([("fa:fa-car", "<path id=\"car\"/>")]),
    ),
    content="846x610 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-wardley\" viewBox=\"0 0 846 610\" width=\"846\" height=\"610\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_tw:var(--pele-title-weight,bold);--_hw:var(--pele-heading-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"wardley\"><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"436\" y=\"25.6\">Test</tspan></text><g transform=\"translate(34,44)\"><g class=\"pele-wardley-frame\" fill=\"none\"><path class=\"pele-wardley-stage\" d=\"M201,0V504\" stroke=\"var(--_b)\" stroke-dasharray=\"4 4\"/><path class=\"pele-wardley-stage\" d=\"M402,0V504\" stroke=\"var(--_b)\" stroke-dasharray=\"4 4\"/><path class=\"pele-wardley-stage\" d=\"M603,0V504\" stroke=\"var(--_b)\" stroke-dasharray=\"4 4\"/><path class=\"pele-wardley-axis\" d=\"M0,0V504H804\" stroke=\"var(--_l)\"/></g><text class=\"pele-wardley-stage-label\" font-size=\"13\" fill=\"var(--_m)\" x=\"100.5\" y=\"526.55\" text-anchor=\"middle\">Genesis</text><text class=\"pele-wardley-stage-label\" font-size=\"13\" fill=\"var(--_m)\" x=\"301.5\" y=\"526.55\" text-anchor=\"middle\">Custom Built</text><text class=\"pele-wardley-stage-label\" font-size=\"13\" fill=\"var(--_m)\" x=\"502.5\" y=\"526.55\" text-anchor=\"middle\">Product</text><text class=\"pele-wardley-stage-label\" font-size=\"13\" fill=\"var(--_m)\" x=\"703.5\" y=\"526.55\" text-anchor=\"middle\">Commodity</text><text class=\"pele-wardley-axis-label\" font-size=\"13\" font-weight=\"var(--_hw)\" x=\"402\" y=\"552.55\" text-anchor=\"middle\">Evolution</text><text class=\"pele-wardley-axis-label\" font-size=\"13\" font-weight=\"var(--_hw)\" transform=\"rotate(-90 -16 252)\" x=\"-16\" y=\"256.55\" text-anchor=\"middle\">Visibility</text><g class=\"pele-edges\" fill=\"none\"><g class=\"pele-edge\" data-id=\"fa:fa-car A-B\"><path d=\"M407.08,255.19L638.12,400.01\" stroke=\"var(--_l)\"/><text class=\"pele-edge-label\" font-size=\"12\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"535.57\" y=\"315.63\" text-anchor=\"start\"> x</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"520.57\" y=\"304.83\" width=\"13.2\" height=\"13.2\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g></g><g class=\"pele-node pele-wardley-component\" data-id=\"fa:fa-car A\"><circle cx=\"402\" cy=\"252\" r=\"6\" fill=\"var(--_bg)\" stroke=\"var(--_l)\"/><text class=\"pele-label\" font-size=\"13\" xml:space=\"preserve\"><tspan x=\"410\" y=\"244\"> A</tspan></text></g><g class=\"pele-node pele-wardley-component\" data-id=\"B\"><circle cx=\"643.2\" cy=\"403.2\" r=\"6\" fill=\"var(--_bg)\" stroke=\"var(--_l)\"/><text class=\"pele-label\" font-size=\"13\" xml:space=\"preserve\"><tspan x=\"651.2\" y=\"395.2\">B</tspan></text></g></g></svg>",
  )
}

///|
test "stage labels draw the host's icons" {
  inspect(
    with_icons(
      "wardley-beta\nevolution \"fa:fa-car Genesis\" -> Custom -> Product -> Commodity\ncomponent A [0.5, 0.5]\n",
      icons=host([("fa:fa-car", "<path id=\"car\"/>")]),
    ),
    content="846x574 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-wardley\" viewBox=\"0 0 846 574\" width=\"846\" height=\"574\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_hw:var(--pele-heading-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"wardley\"><g transform=\"translate(34,8)\"><g class=\"pele-wardley-frame\" fill=\"none\"><path class=\"pele-wardley-stage\" d=\"M201,0V504\" stroke=\"var(--_b)\" stroke-dasharray=\"4 4\"/><path class=\"pele-wardley-stage\" d=\"M402,0V504\" stroke=\"var(--_b)\" stroke-dasharray=\"4 4\"/><path class=\"pele-wardley-stage\" d=\"M603,0V504\" stroke=\"var(--_b)\" stroke-dasharray=\"4 4\"/><path class=\"pele-wardley-axis\" d=\"M0,0V504H804\" stroke=\"var(--_l)\"/></g><text class=\"pele-wardley-stage-label\" font-size=\"13\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"82.98\" y=\"526.55\" text-anchor=\"start\"> Genesis</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"66.73\" y=\"514.85\" width=\"14.3\" height=\"14.3\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg><text class=\"pele-wardley-stage-label\" font-size=\"13\" fill=\"var(--_m)\" x=\"301.5\" y=\"526.55\" text-anchor=\"middle\">Custom</text><text class=\"pele-wardley-stage-label\" font-size=\"13\" fill=\"var(--_m)\" x=\"502.5\" y=\"526.55\" text-anchor=\"middle\">Product</text><text class=\"pele-wardley-stage-label\" font-size=\"13\" fill=\"var(--_m)\" x=\"703.5\" y=\"526.55\" text-anchor=\"middle\">Commodity</text><text class=\"pele-wardley-axis-label\" font-size=\"13\" font-weight=\"var(--_hw)\" x=\"402\" y=\"552.55\" text-anchor=\"middle\">Evolution</text><text class=\"pele-wardley-axis-label\" font-size=\"13\" font-weight=\"var(--_hw)\" transform=\"rotate(-90 -16 252)\" x=\"-16\" y=\"256.55\" text-anchor=\"middle\">Visibility</text><g class=\"pele-node pele-wardley-component\" data-id=\"A\"><circle cx=\"402\" cy=\"252\" r=\"6\" fill=\"var(--_bg)\" stroke=\"var(--_l)\"/><text class=\"pele-label\" font-size=\"13\" xml:space=\"preserve\"><tspan x=\"410\" y=\"244\">A</tspan></text></g></g></svg>",
  )
}
