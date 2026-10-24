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
  let result = @core.render([@xychart.xychart], source, options) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "\{result.width}x\{result.height} \{result.svg}"
}

///|
test "a tick label of only an icon is drawn as a label with an empty square" {
  inspect(
    with_icons(
      "xychart-beta\n  x-axis [\"fa:fa-car\", b, c]\n  y-axis \"fa:fa-car\" 0 --> 10\n  bar [1, 2, 3]\n",
      icons=host([("fa:fa-car", "<path id=\"car\"/>")]),
    ),
    content="700x500 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-xychart\" viewBox=\"0 0 700 500\" width=\"700\" height=\"500\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"xychart\"><path class=\"pele-grid\" d=\"M60.57,463H692M60.57,374.1H692M60.57,285.2H692M60.57,196.3H692M60.57,107.4H692M60.57,18.5H692\" stroke=\"var(--_a)\"/><g class=\"pele-plot\"><g class=\"pele-series pele-bars\" fill=\"var(--pele-series-1,#4c78a8)\"><rect x=\"92.14\" y=\"418.55\" width=\"147.33\" height=\"44.45\"/><rect x=\"302.62\" y=\"374.1\" width=\"147.33\" height=\"88.9\"/><rect x=\"513.09\" y=\"329.65\" width=\"147.33\" height=\"133.35\"/></g></g><path class=\"pele-axis\" d=\"M60.57,18.5V463M60.57,463H692M60.57,463h-4M60.57,374.1h-4M60.57,285.2h-4M60.57,196.3h-4M60.57,107.4h-4M60.57,18.5h-4M165.81,463v4M376.28,463v4M586.76,463v4\" fill=\"none\" stroke=\"var(--_b)\"/><g class=\"pele-axis-labels\" font-size=\"14\" fill=\"var(--_m)\"><text x=\"50.57\" y=\"467.9\" text-anchor=\"end\">0</text><text x=\"50.57\" y=\"379\" text-anchor=\"end\">2</text><text x=\"50.57\" y=\"290.1\" text-anchor=\"end\">4</text><text x=\"50.57\" y=\"201.2\" text-anchor=\"end\">6</text><text x=\"50.57\" y=\"112.3\" text-anchor=\"end\">8</text><text x=\"50.57\" y=\"23.4\" text-anchor=\"end\">10</text><text text-anchor=\"middle\" xml:space=\"preserve\"></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"157.06\" y=\"473.8\" width=\"15.4\" height=\"15.4\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"></svg><text x=\"376.28\" y=\"486.4\" text-anchor=\"middle\">b</text><text x=\"586.76\" y=\"486.4\" text-anchor=\"middle\">c</text></g><g class=\"pele-axis-titles\" font-size=\"14\"><g transform=\"translate(18.5,240.75) rotate(-90)\"><text text-anchor=\"middle\" xml:space=\"preserve\"></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"-8.75\" y=\"-7.7\" width=\"15.4\" height=\"15.4\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"></svg></g></g></svg>",
  )
}
