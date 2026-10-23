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
  let result = @core.render([@gantt.gantt], source, options) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "\{result.width}x\{result.height} \{result.svg}"
}

///|
test "section labels draw the host's icons and the rest leave their squares empty" {
  inspect(
    with_icons(
      "gantt\n    dateFormat YYYY-MM-DD\n    title fa:fa-car Plan\n    section fa:fa-car Section\n    fa:fa-car A task :a1, 2024-10-01, 3d\n",
      icons=host([("fa:fa-car", "<path id=\"car\"/>")]),
    ),
    content="800x107 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-gantt\" viewBox=\"0 0 800 107\" width=\"800\" height=\"107\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"gantt\"><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"390.88\" y=\"25.6\" text-anchor=\"start\"> Plan</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"370.88\" y=\"11.2\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"></svg><g class=\"pele-sections\"><rect class=\"pele-section pele-section-0\" x=\"0\" y=\"48\" width=\"800\" height=\"30\" fill=\"var(--_s)\"/></g><g class=\"pele-grid\" fill=\"none\"><path d=\"M95.22,48V78M206.24,48V78M317.25,48V78M428.27,48V78M539.28,48V78M650.3,48V78M761.32,48V78\" stroke=\"var(--_b)\" stroke-dasharray=\"1 3\"/><path d=\"M95.22,78H761.32\" stroke=\"var(--_b)\"/></g><g class=\"pele-tasks\" font-size=\"13\"><g class=\"pele-task\" data-id=\"fa-car A task :a1\"><rect x=\"95.22\" y=\"51\" width=\"666.1\" height=\"24\" fill=\"var(--_c)\" stroke=\"var(--_c)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" fill=\"var(--_bg)\" x=\"428.27\" y=\"67.55\" text-anchor=\"middle\">fa</text></g></g><g class=\"pele-section-labels\" font-size=\"13\"><text class=\"pele-section-label\" data-id=\"fa:fa-car Section\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"32.25\" y=\"67.55\" text-anchor=\"start\"> Section</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"16\" y=\"55.85\" width=\"14.3\" height=\"14.3\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g><g class=\"pele-axis\" font-size=\"12\" fill=\"var(--_m)\"><text x=\"95.22\" y=\"94.7\" text-anchor=\"middle\">2024-10-01</text><text x=\"317.25\" y=\"94.7\" text-anchor=\"middle\">2024-10-02</text><text x=\"539.28\" y=\"94.7\" text-anchor=\"middle\">2024-10-03</text><text x=\"761.32\" y=\"94.7\" text-anchor=\"middle\">2024-10-04</text></g></svg>",
  )
}
