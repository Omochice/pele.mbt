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
  let result = @core.render([@class.class], source, options) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "\{result.width}x\{result.height} \{result.svg}"
}

///|
test "class names and annotations draw the host's icons" {
  inspect(
    with_icons(
      "classDiagram\n  class Animal[\"fa:fa-car Animal\"] {\n    <<fa:fa-car interface>>\n    +name\n  }\n",
      icons=host([("fa:fa-car", "<path id=\"car\"/>")]),
    ),
    content="157x117 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-class\" viewBox=\"0 0 157 117\" width=\"157\" height=\"117\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_hw:var(--pele-heading-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"class\"><g class=\"pele-nodes\"><g class=\"pele-node pele-class\" data-id=\"Animal\" transform=\"translate(78.12,58.5)\"><rect x=\"-70.12\" y=\"-50.5\" width=\"140.23\" height=\"101\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><path class=\"pele-divider\" d=\"M-70.12,7.5H70.12M-70.12,40.5H70.12\" fill=\"none\" stroke=\"var(--_b)\"/><text class=\"pele-annotation\" x=\"0\" y=\"-28.95\" text-anchor=\"middle\" font-size=\"13\" fill=\"var(--_m)\">«fa:fa-car interface»</text><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"-18.9\" y=\"-6.9\" text-anchor=\"start\"> Animal</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"-38.9\" y=\"-21.3\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg><g class=\"pele-members\" font-size=\"14\"><text class=\"pele-member pele-attribute\" x=\"-58.12\" y=\"28.9\">+name</text></g></g></g></svg>",
  )
}

///|
test "cardinalities and notes draw the host's icons" {
  inspect(
    with_icons(
      "classDiagram\n  Animal \"fa:fa-car 1\" --> \"many\" Dog\n  note for Dog \"fa:fa-car note\"\n",
      icons=host([("fa:fa-car", "<path id=\"car\"/>")]),
    ),
    content="206x208 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-class\" viewBox=\"0 0 206 208\" width=\"206\" height=\"208\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_hw:var(--pele-heading-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"class\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-note-edge\" data-id=\"edgeNote0\"><path d=\"M161.66,56.5C161.66,98.25 116.17,98.25 116.17,140\" stroke-dasharray=\"2 4\"/></g><g class=\"pele-edge pele-relation\" data-id=\"id_Animal_Dog_1\"><path d=\"M46.67,68L46.67,92C46.67,107.6 92.17,107.6 92.17,123.2L92.17,133\"/><path class=\"pele-marker\" d=\"M92.17,140L88.81,132L95.53,132Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-cardinalities\" font-size=\"13\" fill=\"var(--_m)\"><text class=\"pele-cardinality\" x=\"84.94\" y=\"84.55\" text-anchor=\"middle\">fa:fa-car 1</text><text class=\"pele-cardinality\" x=\"67.27\" y=\"132.55\" text-anchor=\"middle\">many</text></g><g class=\"pele-nodes\"><g class=\"pele-node pele-class\" data-id=\"Animal\" transform=\"translate(46.67,38)\"><rect x=\"-38.67\" y=\"-30\" width=\"77.34\" height=\"60\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><path class=\"pele-divider\" d=\"M-38.67,10H38.67M-38.67,20H38.67\" fill=\"none\" stroke=\"var(--_b)\"/><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"-4.4\">Animal</tspan></text></g><g class=\"pele-node pele-class\" data-id=\"Dog\" transform=\"translate(104.17,170)\"><rect x=\"-39.89\" y=\"-30\" width=\"79.79\" height=\"60\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><path class=\"pele-divider\" d=\"M-39.89,10H39.89M-39.89,20H39.89\" fill=\"none\" stroke=\"var(--_b)\"/><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"-4.4\">Dog</tspan></text></g><g class=\"pele-node pele-note\" data-id=\"note0\" transform=\"translate(161.66,38)\"><path d=\"M-36.32,-18.5H28.32L36.32,-10.5V18.5H-36.32Z\" fill=\"var(--_a)\" stroke=\"var(--_b)\" stroke-linejoin=\"round\"/><path d=\"M28.32,-18.5V-10.5H36.32\" fill=\"none\" stroke=\"var(--_b)\" stroke-linejoin=\"round\"/><text class=\"pele-label\" font-size=\"14\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"-6.82\" y=\"4.9\" text-anchor=\"start\"> note</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"-24.32\" y=\"-7.7\" width=\"15.4\" height=\"15.4\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g></g></svg>",
  )
}
