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
  let result = @core.render([@requirement.requirement], source, options) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "\{result.width}x\{result.height} \{result.svg}"
}

///|
test "emphasized names keep the width of their icons" {
  inspect(
    with_icons(
      "requirementDiagram\n  requirement \"fa:fa-car r1\" {\n    id: 1\n    text: \"fa:fa-car after\"\n    risk: high\n  }\n",
      icons=host([("fa:fa-car", "<path id=\"car\"/>")]),
    ),
    content="141x168 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-requirement\" viewBox=\"0 0 141 168\" width=\"141\" height=\"168\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_hw:var(--pele-heading-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"requirement\"><g class=\"pele-nodes\"><g class=\"pele-node pele-requirement\" data-id=\"fa:fa-car r1\" transform=\"translate(70.19,84)\"><rect x=\"-62.19\" y=\"-76\" width=\"124.38\" height=\"152\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-stereotype\" font-size=\"14\" fill=\"var(--_m)\" x=\"0\" y=\"-50.6\" text-anchor=\"middle\">«Requirement»</text><text class=\"pele-label\" font-size=\"16\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0.22\" y=\"-27.4\" text-anchor=\"start\"> r1</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"-19.78\" y=\"-41.8\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"></svg><path class=\"pele-divider\" d=\"M-62.19,-11H62.19\" stroke=\"var(--_b)\"/><g class=\"pele-fields\" font-size=\"14\"><text class=\"pele-field\" fill=\"var(--_m)\" text-anchor=\"start\" xml:space=\"preserve\"><tspan x=\"-48.19\" y=\"14.4\">ID</tspan></text><text class=\"pele-value\" text-anchor=\"start\" xml:space=\"preserve\"><tspan x=\"-8.96\" y=\"14.4\">1</tspan></text><text class=\"pele-field\" fill=\"var(--_m)\" text-anchor=\"start\" xml:space=\"preserve\"><tspan x=\"-48.19\" y=\"37.4\">Text</tspan></text><text class=\"pele-value\" text-anchor=\"start\" xml:space=\"preserve\"><tspan x=\"-8.96\" y=\"37.4\"> after</tspan></text><text class=\"pele-field\" fill=\"var(--_m)\" text-anchor=\"start\" xml:space=\"preserve\"><tspan x=\"-48.19\" y=\"60.4\">Risk</tspan></text><text class=\"pele-value\" text-anchor=\"start\" xml:space=\"preserve\"><tspan x=\"-8.96\" y=\"60.4\">High</tspan></text></g></g></g></svg>",
  )
}
