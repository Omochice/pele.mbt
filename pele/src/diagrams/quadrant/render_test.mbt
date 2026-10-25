///|
fn render(
  source : String,
  max_width : Double?,
) -> @types.RenderResult raise @errors.PeleError {
  let options = { ..@types.RenderOptions::default(), max_width, }
  @core.render([@quadrant.quadrant], source, options)
}

///|
/// The size and the whole SVG, or the message of the error.
fn svg(source : String, max_width? : Double) -> String {
  let result = render(source, max_width) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "\{result.width}x\{result.height} \{result.svg}"
}

///|
fn size(source : String, max_width? : Double) -> String {
  let result = render(source, max_width) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "\{result.width}x\{result.height}"
}

///|
/// The opening tags of the elements named `name`, one to a line, after the size.
fn tags(name : String, source : String, max_width? : Double) -> String {
  let result = render(source, max_width) catch {
    @errors.PeleError(failure) => return failure.message
  }
  let found = ["\{result.width}x\{result.height}"]
  let mut from = 0
  while true {
    let at = @util.index_of(result.svg, "<\{name} ", from~)
    if at == -1 {
      break
    }
    let end = @util.index_of(result.svg, ">", from=at)
    found.push(@util.slice(result.svg, at, end=end + 1))
    from = end + 1
  }
  found.join("\n")
}

///|
fn count(name : String, source : String, max_width? : Double) -> String {
  let result = render(source, max_width) catch {
    @errors.PeleError(failure) => return failure.message
  }
  let mut found = 0
  let mut from = 0
  while true {
    let at = @util.index_of(result.svg, "<\{name} ", from~)
    if at == -1 {
      break
    }
    found += 1
    from = at + 1
  }
  found.to_string()
}

///|
test "a chart with a title, axes, quadrants and points" {
  inspect(
    svg(
      "quadrantChart\n  title Reach and engagement\n  x-axis Low Reach --> High Reach\n  y-axis Low Engagement --> High Engagement\n  quadrant-1 Expand\n  quadrant-2 Promote\n  quadrant-3 Re-evaluate\n  quadrant-4 Improve\n  Campaign A: [0.25, 0.75]\n  Campaign B: [0.75, 0.25]",
    ),
    content="500x500 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-quadrantChart\" viewBox=\"0 0 500 500\" width=\"500\" height=\"500\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"quadrantChart\"><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"250\" y=\"22.6\">Reach and engagement</tspan></text><g class=\"pele-quadrants\" fill=\"var(--_s)\" stroke=\"var(--_b)\"><g class=\"pele-quadrant\" data-id=\"1\"><rect x=\"265\" y=\"42\" width=\"227\" height=\"210\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" fill=\"var(--_fg)\" stroke=\"none\" x=\"378.5\" y=\"64.6\" text-anchor=\"middle\">Expand</text></g><g class=\"pele-quadrant\" data-id=\"2\"><rect x=\"34\" y=\"42\" width=\"227\" height=\"210\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" fill=\"var(--_fg)\" stroke=\"none\" x=\"147.5\" y=\"64.6\" text-anchor=\"middle\">Promote</text></g><g class=\"pele-quadrant\" data-id=\"3\"><rect x=\"34\" y=\"256\" width=\"227\" height=\"210\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" fill=\"var(--_fg)\" stroke=\"none\" x=\"147.5\" y=\"278.6\" text-anchor=\"middle\">Re-evaluate</text></g><g class=\"pele-quadrant\" data-id=\"4\"><rect x=\"265\" y=\"256\" width=\"227\" height=\"210\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" fill=\"var(--_fg)\" stroke=\"none\" x=\"378.5\" y=\"278.6\" text-anchor=\"middle\">Improve</text></g></g><g class=\"pele-axis-labels\" font-size=\"14\" fill=\"var(--_m)\"><text x=\"148.5\" y=\"486.4\" text-anchor=\"middle\">Low Reach</text><text x=\"377.5\" y=\"486.4\" text-anchor=\"middle\">High Reach</text><g transform=\"translate(18.5,360) rotate(-90)\"><text x=\"0\" y=\"4.9\" text-anchor=\"middle\">Low Engagement</text></g><g transform=\"translate(18.5,148) rotate(-90)\"><text x=\"0\" y=\"4.9\" text-anchor=\"middle\">High Engagement</text></g></g><g class=\"pele-points\" fill=\"var(--pele-series-1,#4c78a8)\"><circle class=\"pele-point\" data-id=\"Campaign B\" cx=\"377.5\" cy=\"360\" r=\"5\"/><circle class=\"pele-point\" data-id=\"Campaign A\" cx=\"148.5\" cy=\"148\" r=\"5\"/></g><g class=\"pele-point-labels\" font-size=\"12\"><text class=\"pele-label\" x=\"148.5\" y=\"169.4\" text-anchor=\"middle\">Campaign A</text><text class=\"pele-label\" x=\"377.5\" y=\"381.4\" text-anchor=\"middle\">Campaign B</text></g></svg>",
  )
}

///|
test "a chart narrower than its natural width is drawn narrower" {
  inspect(
    svg(
      "quadrantChart\n  title Reach and engagement\n  x-axis Low Reach --> High Reach\n  y-axis Low Engagement --> High Engagement\n  quadrant-1 Expand\n  quadrant-2 Promote\n  quadrant-3 Re-evaluate\n  quadrant-4 Improve\n  Campaign A: [0.25, 0.75]\n  Campaign B: [0.75, 0.25]",
      max_width=400,
    ),
    content="400x400 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-quadrantChart\" viewBox=\"0 0 400 400\" width=\"400\" height=\"400\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"quadrantChart\"><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"200\" y=\"22.6\">Reach and engagement</tspan></text><g class=\"pele-quadrants\" fill=\"var(--_s)\" stroke=\"var(--_b)\"><g class=\"pele-quadrant\" data-id=\"1\"><rect x=\"215\" y=\"42\" width=\"177\" height=\"160\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" fill=\"var(--_fg)\" stroke=\"none\" x=\"303.5\" y=\"64.6\" text-anchor=\"middle\">Expand</text></g><g class=\"pele-quadrant\" data-id=\"2\"><rect x=\"34\" y=\"42\" width=\"177\" height=\"160\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" fill=\"var(--_fg)\" stroke=\"none\" x=\"122.5\" y=\"64.6\" text-anchor=\"middle\">Promote</text></g><g class=\"pele-quadrant\" data-id=\"3\"><rect x=\"34\" y=\"206\" width=\"177\" height=\"160\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" fill=\"var(--_fg)\" stroke=\"none\" x=\"122.5\" y=\"228.6\" text-anchor=\"middle\">Re-evaluate</text></g><g class=\"pele-quadrant\" data-id=\"4\"><rect x=\"215\" y=\"206\" width=\"177\" height=\"160\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" fill=\"var(--_fg)\" stroke=\"none\" x=\"303.5\" y=\"228.6\" text-anchor=\"middle\">Improve</text></g></g><g class=\"pele-axis-labels\" font-size=\"14\" fill=\"var(--_m)\"><text x=\"123.5\" y=\"386.4\" text-anchor=\"middle\">Low Reach</text><text x=\"302.5\" y=\"386.4\" text-anchor=\"middle\">High Reach</text><g transform=\"translate(18.5,285) rotate(-90)\"><text x=\"0\" y=\"4.9\" text-anchor=\"middle\">Low Engagement</text></g><g transform=\"translate(18.5,123) rotate(-90)\"><text x=\"0\" y=\"4.9\" text-anchor=\"middle\">High Engagement</text></g></g><g class=\"pele-points\" fill=\"var(--pele-series-1,#4c78a8)\"><circle class=\"pele-point\" data-id=\"Campaign B\" cx=\"302.5\" cy=\"285\" r=\"5\"/><circle class=\"pele-point\" data-id=\"Campaign A\" cx=\"123.5\" cy=\"123\" r=\"5\"/></g><g class=\"pele-point-labels\" font-size=\"12\"><text class=\"pele-label\" x=\"123.5\" y=\"144.4\" text-anchor=\"middle\">Campaign A</text><text class=\"pele-label\" x=\"302.5\" y=\"306.4\" text-anchor=\"middle\">Campaign B</text></g></svg>",
  )
  inspect(
    svg(
      "quadrantChart\n  title Reach and engagement\n  x-axis Low Reach --> High Reach\n  y-axis Low Engagement --> High Engagement\n  quadrant-1 Expand\n  quadrant-2 Promote\n  quadrant-3 Re-evaluate\n  quadrant-4 Improve\n  Campaign A: [0.25, 0.75]\n  Campaign B: [0.75, 0.25]",
      max_width=200,
    ),
    content=(
      #|280x280 <svg xmlns="http://www.w3.org/2000/svg" class="pele pele-quadrantChart" viewBox="0 0 280 280" width="280" height="280" style="max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)" fill="var(--_fg)" role="graphics-document document" aria-roledescription="quadrantChart"><text class="pele-title" font-weight="var(--_tw)" text-anchor="middle" xml:space="preserve"><tspan x="140" y="22.6">Reach and engagement</tspan></text><g class="pele-quadrants" fill="var(--_s)" stroke="var(--_b)"><g class="pele-quadrant" data-id="1"><rect x="162.5" y="42" width="109.5" height="100" style="rx:var(--_r)"/><text class="pele-label" fill="var(--_fg)" stroke="none" x="217.25" y="64.6" text-anchor="middle">Expand</text></g><g class="pele-quadrant" data-id="2"><rect x="49" y="42" width="109.5" height="100" style="rx:var(--_r)"/><text class="pele-label" fill="var(--_fg)" stroke="none" x="103.75" y="64.6" text-anchor="middle">Promote</text></g><g class="pele-quadrant" data-id="3"><rect x="49" y="146" width="109.5" height="100" style="rx:var(--_r)"/><text class="pele-label" fill="var(--_fg)" stroke="none" x="103.75" y="168.6" text-anchor="middle">Re-evaluate</text></g><g class="pele-quadrant" data-id="4"><rect x="162.5" y="146" width="109.5" height="100" style="rx:var(--_r)"/><text class="pele-label" fill="var(--_fg)" stroke="none" x="217.25" y="168.6" text-anchor="middle">Improve</text></g></g><g class="pele-axis-labels" font-size="14" fill="var(--_m)"><text x="104.75" y="266.4" text-anchor="middle">Low Reach</text><text x="216.25" y="266.4" text-anchor="middle">High Reach</text><g transform="translate(26,195) rotate(-90)"><text text-anchor="middle" xml:space="preserve"><tspan x="0" y="-4.1">Low</tspan><tspan x="0" y="13.9">Engagement</tspan></text></g><g transform="translate(26,93) rotate(-90)"><text text-anchor="middle" xml:space="preserve"><tspan x="0" y="-4.1">High</tspan><tspan x="0" y="13.9">Engagement</tspan></text></g></g><g class="pele-points" fill="var(--pele-series-1,#4c78a8)"><circle class="pele-point" data-id="Campaign B" cx="216.25" cy="195" r="5"/><circle class="pele-point" data-id="Campaign A" cx="104.75" cy="93" r="5"/></g><g class="pele-point-labels" font-size="12"><text class="pele-label" x="104.75" y="114.4" text-anchor="middle">Campaign A</text><text class="pele-label" x="216.25" y="216.4" text-anchor="middle">Campaign B</text></g></svg>
    ),
  )
  inspect(
    svg(
      "quadrantChart\n  title Reach and engagement\n  x-axis Low Reach --> High Reach\n  y-axis Low Engagement --> High Engagement\n  quadrant-1 Expand\n  quadrant-2 Promote\n  quadrant-3 Re-evaluate\n  quadrant-4 Improve\n  Campaign A: [0.25, 0.75]\n  Campaign B: [0.75, 0.25]",
      max_width=900,
    ),
    content="500x500 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-quadrantChart\" viewBox=\"0 0 500 500\" width=\"500\" height=\"500\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"quadrantChart\"><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"250\" y=\"22.6\">Reach and engagement</tspan></text><g class=\"pele-quadrants\" fill=\"var(--_s)\" stroke=\"var(--_b)\"><g class=\"pele-quadrant\" data-id=\"1\"><rect x=\"265\" y=\"42\" width=\"227\" height=\"210\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" fill=\"var(--_fg)\" stroke=\"none\" x=\"378.5\" y=\"64.6\" text-anchor=\"middle\">Expand</text></g><g class=\"pele-quadrant\" data-id=\"2\"><rect x=\"34\" y=\"42\" width=\"227\" height=\"210\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" fill=\"var(--_fg)\" stroke=\"none\" x=\"147.5\" y=\"64.6\" text-anchor=\"middle\">Promote</text></g><g class=\"pele-quadrant\" data-id=\"3\"><rect x=\"34\" y=\"256\" width=\"227\" height=\"210\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" fill=\"var(--_fg)\" stroke=\"none\" x=\"147.5\" y=\"278.6\" text-anchor=\"middle\">Re-evaluate</text></g><g class=\"pele-quadrant\" data-id=\"4\"><rect x=\"265\" y=\"256\" width=\"227\" height=\"210\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" fill=\"var(--_fg)\" stroke=\"none\" x=\"378.5\" y=\"278.6\" text-anchor=\"middle\">Improve</text></g></g><g class=\"pele-axis-labels\" font-size=\"14\" fill=\"var(--_m)\"><text x=\"148.5\" y=\"486.4\" text-anchor=\"middle\">Low Reach</text><text x=\"377.5\" y=\"486.4\" text-anchor=\"middle\">High Reach</text><g transform=\"translate(18.5,360) rotate(-90)\"><text x=\"0\" y=\"4.9\" text-anchor=\"middle\">Low Engagement</text></g><g transform=\"translate(18.5,148) rotate(-90)\"><text x=\"0\" y=\"4.9\" text-anchor=\"middle\">High Engagement</text></g></g><g class=\"pele-points\" fill=\"var(--pele-series-1,#4c78a8)\"><circle class=\"pele-point\" data-id=\"Campaign B\" cx=\"377.5\" cy=\"360\" r=\"5\"/><circle class=\"pele-point\" data-id=\"Campaign A\" cx=\"148.5\" cy=\"148\" r=\"5\"/></g><g class=\"pele-point-labels\" font-size=\"12\"><text class=\"pele-label\" x=\"148.5\" y=\"169.4\" text-anchor=\"middle\">Campaign A</text><text class=\"pele-label\" x=\"377.5\" y=\"381.4\" text-anchor=\"middle\">Campaign B</text></g></svg>",
  )
}

///|
test "an empty chart is four tiles" {
  inspect(
    svg("quadrantChart"),
    content="500x500 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-quadrantChart\" viewBox=\"0 0 500 500\" width=\"500\" height=\"500\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"quadrantChart\"><g class=\"pele-quadrants\" fill=\"var(--_s)\" stroke=\"var(--_b)\"><g class=\"pele-quadrant\" data-id=\"1\"><rect x=\"252\" y=\"8\" width=\"240\" height=\"240\" style=\"rx:var(--_r)\"/></g><g class=\"pele-quadrant\" data-id=\"2\"><rect x=\"8\" y=\"8\" width=\"240\" height=\"240\" style=\"rx:var(--_r)\"/></g><g class=\"pele-quadrant\" data-id=\"3\"><rect x=\"8\" y=\"252\" width=\"240\" height=\"240\" style=\"rx:var(--_r)\"/></g><g class=\"pele-quadrant\" data-id=\"4\"><rect x=\"252\" y=\"252\" width=\"240\" height=\"240\" style=\"rx:var(--_r)\"/></g></g></svg>",
  )
  inspect(
    svg("quadrantChart\n title Only a title"),
    content="500x500 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-quadrantChart\" viewBox=\"0 0 500 500\" width=\"500\" height=\"500\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"quadrantChart\"><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"250\" y=\"22.6\">Only a title</tspan></text><g class=\"pele-quadrants\" fill=\"var(--_s)\" stroke=\"var(--_b)\"><g class=\"pele-quadrant\" data-id=\"1\"><rect x=\"252\" y=\"42\" width=\"240\" height=\"223\" style=\"rx:var(--_r)\"/></g><g class=\"pele-quadrant\" data-id=\"2\"><rect x=\"8\" y=\"42\" width=\"240\" height=\"223\" style=\"rx:var(--_r)\"/></g><g class=\"pele-quadrant\" data-id=\"3\"><rect x=\"8\" y=\"269\" width=\"240\" height=\"223\" style=\"rx:var(--_r)\"/></g><g class=\"pele-quadrant\" data-id=\"4\"><rect x=\"252\" y=\"269\" width=\"240\" height=\"223\" style=\"rx:var(--_r)\"/></g></g></svg>",
  )
  inspect(
    svg(
      "quadrantChart\n quadrant-1 q1\n quadrant-2 q2\n quadrant-3 q3\n quadrant-4 q4",
    ),
    content="500x500 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-quadrantChart\" viewBox=\"0 0 500 500\" width=\"500\" height=\"500\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"quadrantChart\"><g class=\"pele-quadrants\" fill=\"var(--_s)\" stroke=\"var(--_b)\"><g class=\"pele-quadrant\" data-id=\"1\"><rect x=\"252\" y=\"8\" width=\"240\" height=\"240\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" fill=\"var(--_fg)\" stroke=\"none\" x=\"372\" y=\"133.6\" text-anchor=\"middle\">q1</text></g><g class=\"pele-quadrant\" data-id=\"2\"><rect x=\"8\" y=\"8\" width=\"240\" height=\"240\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" fill=\"var(--_fg)\" stroke=\"none\" x=\"128\" y=\"133.6\" text-anchor=\"middle\">q2</text></g><g class=\"pele-quadrant\" data-id=\"3\"><rect x=\"8\" y=\"252\" width=\"240\" height=\"240\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" fill=\"var(--_fg)\" stroke=\"none\" x=\"128\" y=\"377.6\" text-anchor=\"middle\">q3</text></g><g class=\"pele-quadrant\" data-id=\"4\"><rect x=\"252\" y=\"252\" width=\"240\" height=\"240\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" fill=\"var(--_fg)\" stroke=\"none\" x=\"372\" y=\"377.6\" text-anchor=\"middle\">q4</text></g></g></svg>",
  )
}

///|
test "points are placed by their coordinates, x to the right and y upwards" {
  inspect(
    tags("circle", "quadrantChart\n A: [0, 0]\n B: [1, 1]\n C: [0.5, 0.5]"),
    content="500x500\n<circle class=\"pele-point\" data-id=\"C\" cx=\"250\" cy=\"250\" r=\"5\"/>\n<circle class=\"pele-point\" data-id=\"B\" cx=\"492\" cy=\"8\" r=\"5\"/>\n<circle class=\"pele-point\" data-id=\"A\" cx=\"8\" cy=\"492\" r=\"5\"/>",
  )
}

///|
test "quadrant 1 is at the top right and the others go anticlockwise" {
  inspect(
    tags(
      "rect", "quadrantChart\n quadrant-1 q1\n quadrant-2 q2\n quadrant-3 q3\n quadrant-4 q4",
    ),
    content="500x500\n<rect x=\"252\" y=\"8\" width=\"240\" height=\"240\" style=\"rx:var(--_r)\"/>\n<rect x=\"8\" y=\"8\" width=\"240\" height=\"240\" style=\"rx:var(--_r)\"/>\n<rect x=\"8\" y=\"252\" width=\"240\" height=\"240\" style=\"rx:var(--_r)\"/>\n<rect x=\"252\" y=\"252\" width=\"240\" height=\"240\" style=\"rx:var(--_r)\"/>",
  )
}

///|
test "the first point is drawn last, on top" {
  inspect(
    tags("circle", "quadrantChart\n First: [0.5, 0.5]\n Second: [0.5, 0.5]"),
    content="500x500\n<circle class=\"pele-point\" data-id=\"Second\" cx=\"250\" cy=\"250\" r=\"5\"/>\n<circle class=\"pele-point\" data-id=\"First\" cx=\"250\" cy=\"250\" r=\"5\"/>",
  )
}

///|
test "the x axis labels move below the chart once there are points" {
  inspect(
    tags("text", "quadrantChart\n x-axis Left --> Right"),
    content="500x500\n<text x=\"129\" y=\"23.4\" text-anchor=\"middle\">\n<text x=\"371\" y=\"23.4\" text-anchor=\"middle\">",
  )
  inspect(
    tags("text", "quadrantChart\n x-axis Left --> Right\n A: [0.5, 0.5]"),
    content="500x500\n<text x=\"129\" y=\"486.4\" text-anchor=\"middle\">\n<text x=\"371\" y=\"486.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"258.4\" text-anchor=\"middle\">",
  )
  inspect(
    tags(
      "text", "---\nconfig:\n  quadrantChart:\n    xAxisPosition: bottom\n---\nquadrantChart\n x-axis Left --> Right",
    ),
    content="500x500\n<text x=\"129\" y=\"486.4\" text-anchor=\"middle\">\n<text x=\"371\" y=\"486.4\" text-anchor=\"middle\">",
  )
}

///|
test "a single axis label is centered on its own side" {
  inspect(
    tags("text", "quadrantChart\n x-axis Only left\n y-axis Only bottom"),
    content="500x500\n<text x=\"59.68\" y=\"23.4\" text-anchor=\"middle\">\n<text x=\"0\" y=\"4.9\" text-anchor=\"middle\">",
  )
  inspect(
    tags(
      "text", "quadrantChart\n x-axis Left --> Right\n y-axis Bottom --> Top",
    ),
    content="500x500\n<text x=\"148.5\" y=\"23.4\" text-anchor=\"middle\">\n<text x=\"377.5\" y=\"23.4\" text-anchor=\"middle\">\n<text x=\"0\" y=\"4.9\" text-anchor=\"middle\">\n<text x=\"0\" y=\"4.9\" text-anchor=\"middle\">",
  )
  inspect(
    size("quadrantChart\n x-axis \"\" --> \"\"\n y-axis \"\""),
    content="Parse error on line 2:\n x-axis \"\" --> \"\"\n----------^\nExpecting 'STR', 'MD_STR', 'ALPHA', 'NUM', 'UNICODE_TEXT', 'PUNCTUATION', got 'AXIS-TEXT-DELIMITER'",
  )
}

///|
test "point styles apply, with direct styles over class styles" {
  inspect(
    tags(
      "circle", "quadrantChart\n        A: [0.1, 0.1] radius: 12\n        B:::c1: [0.2, 0.2] color: #ff3300, radius: 10\n        C:::c2: [0.3, 0.3]\n        D: [0.4, 0.4] color: 00f, stroke-width: 3px\n        E: [0.5, 0.5] stroke-color: #00ff00\n        classDef c1 color: #109060\n        classDef c2 color: #908342, radius : 9, stroke-color: #310085, stroke-width: 10px",
    ),
    content="500x500\n<circle class=\"pele-point\" data-id=\"E\" cx=\"250\" cy=\"250\" r=\"5\"/>\n<circle class=\"pele-point\" data-id=\"D\" cx=\"201.6\" cy=\"298.4\" r=\"5\" stroke=\"var(--pele-series-1,#4c78a8)\" style=\"fill:#00f;stroke-width:3px;\"/>\n<circle class=\"pele-point c2\" data-id=\"C\" cx=\"153.2\" cy=\"346.8\" r=\"9\" style=\"fill:#908342;stroke:#310085;stroke-width:10px;\"/>\n<circle class=\"pele-point c1\" data-id=\"B\" cx=\"104.8\" cy=\"395.2\" r=\"10\" style=\"fill:#ff3300;\"/>\n<circle class=\"pele-point\" data-id=\"A\" cx=\"56.4\" cy=\"443.6\" r=\"12\"/>",
  )
}

///|
test "a style Mermaid rejects is reported with Mermaid's message" {
  inspect(
    size("quadrantChart\n A: [0.1, 0.1] radius: big"),
    content="value for radius big is invalid, please use a valid number",
  )
  inspect(
    size("quadrantChart\n A: [0.1, 0.1] color: red"),
    content="value for color red is invalid, please use a valid hex code",
  )
  inspect(
    size("quadrantChart\n classDef c fill: #fff"),
    content="style named fill is not supported.",
  )
  inspect(
    size("quadrantChart\n A: [1.2, 0.4]"),
    content="Lexical error on line 2. Unrecognized text.\n A: [1.2, 0.4]\n------^",
  )
  inspect(
    size("quadrantChart\n A: [0.2, 0.4"),
    content="Lexical error on line 2. Unrecognized text.\n A: [0.2, 0.4\n-------------^",
  )
}

///|
test "a point whose coordinate is not a number from 0 to 1 is left out" {
  inspect(
    tags(
      "circle", "quadrantChart\n A: [0x5, 0.5]\n B: [0,5, 0.5]\n C: [0.5, 0.5]",
    ),
    content="500x500\n<circle class=\"pele-point\" data-id=\"C\" cx=\"250\" cy=\"250\" r=\"5\"/>",
  )
  inspect(
    tags("circle", "quadrantChart\n A: [055, 0e9]\n B: [00, 01]\n C: [1, 1]"),
    content="Lexical error on line 3. Unrecognized text.\n B: [00, 01]\n------^",
  )
}

///|
test "the size, radius, padding and axis settings are honoured" {
  inspect(
    size(
      "---\nconfig:\n  quadrantChart:\n    chartWidth: 400\n    chartHeight: 320\n---\nquadrantChart\n y-axis Down --> Up\n A: [0.5, 0.5]",
    ),
    content="400x320",
  )
  inspect(
    tags(
      "circle", "---\nconfig:\n  quadrantChart:\n    pointRadius: 9\n---\nquadrantChart\n y-axis Down --> Up\n A: [0.5, 0.5]",
    ),
    content="500x500\n<circle class=\"pele-point\" data-id=\"A\" cx=\"263\" cy=\"250\" r=\"9\"/>",
  )
  inspect(
    tags(
      "circle", "---\nconfig:\n  quadrantChart:\n    yAxisPosition: right\n---\nquadrantChart\n y-axis Down --> Up\n A: [0.5, 0.5]",
    ),
    content="500x500\n<circle class=\"pele-point\" data-id=\"A\" cx=\"237\" cy=\"250\" r=\"5\"/>",
  )
  inspect(
    tags(
      "circle", "---\nconfig:\n  quadrantChart:\n    yAxisLabelPadding: 40\n---\nquadrantChart\n y-axis Down --> Up\n A: [0.5, 0.5]",
    ),
    content="500x500\n<circle class=\"pele-point\" data-id=\"A\" cx=\"280.5\" cy=\"250\" r=\"5\"/>",
  )
  inspect(
    tags(
      "rect", "---\nconfig:\n  quadrantChart:\n    quadrantPadding: 30\n---\nquadrantChart\n y-axis Down --> Up\n A: [0.5, 0.5]",
    ),
    content="500x500\n<rect x=\"265\" y=\"30\" width=\"205\" height=\"218\" style=\"rx:var(--_r)\"/>\n<rect x=\"56\" y=\"30\" width=\"205\" height=\"218\" style=\"rx:var(--_r)\"/>\n<rect x=\"56\" y=\"252\" width=\"205\" height=\"218\" style=\"rx:var(--_r)\"/>\n<rect x=\"265\" y=\"252\" width=\"205\" height=\"218\" style=\"rx:var(--_r)\"/>",
  )
  inspect(
    tags(
      "text", "---\nconfig:\n  quadrantChart:\n    pointTextPadding: 30\n---\nquadrantChart\n y-axis Down --> Up\n A: [0.5, 0.5]",
    ),
    content="500x500\n<text x=\"0\" y=\"4.9\" text-anchor=\"middle\">\n<text x=\"0\" y=\"4.9\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"263\" y=\"296.4\" text-anchor=\"middle\">",
  )
  inspect(
    tags(
      "text", "---\nconfig:\n  quadrantChart:\n    titlePadding: 30\n---\nquadrantChart\n title T\n A: [0.5, 0.5]",
    ),
    content="500x500\n<text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\">\n<text class=\"pele-label\" x=\"250\" y=\"298.4\" text-anchor=\"middle\">",
  )
  inspect(
    tags(
      "text", "---\nconfig:\n  quadrantChart:\n    quadrantTextTopPadding: 30\n---\nquadrantChart\n quadrant-1 Q\n A: [0.5, 0.5]",
    ),
    content="500x500\n<text class=\"pele-label\" fill=\"var(--_fg)\" stroke=\"none\" x=\"372\" y=\"55.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">",
  )
  inspect(
    tags(
      "text", "---\nconfig:\n  quadrantChart:\n    xAxisLabelPadding: 30\n---\nquadrantChart\n x-axis a --> b",
    ),
    content="500x500\n<text x=\"129\" y=\"23.4\" text-anchor=\"middle\">\n<text x=\"371\" y=\"23.4\" text-anchor=\"middle\">",
  )
  inspect(
    tags(
      "circle", "---\nconfig:\n  quadrantChart:\n    chartWidth: \"wide\"\n    pointRadius: -3\n---\nquadrantChart\n y-axis Down --> Up\n A: [0.5, 0.5]",
    ),
    content="500x500\n<circle class=\"pele-point\" data-id=\"A\" cx=\"263\" cy=\"250\" r=\"5\"/>",
  )
  inspect(
    size(
      "---\nconfig:\n  quadrantChart:\n    chartWidth: 90000\n    chartHeight: 20\n---\nquadrantChart\n y-axis Down --> Up\n A: [0.5, 0.5]",
    ),
    content="4000x100",
  )
  inspect(
    size(
      "---\nconfig:\n  quadrantChart:\n    useMaxWidth: false\n---\nquadrantChart\n y-axis Down --> Up\n A: [0.5, 0.5]",
    ),
    content="500x500",
  )
}

///|
test "a point label goes where it is inside the chart and free" {
  inspect(
    tags(
      "text", "quadrantChart\n One: [0.5, 0]\n Two: [0.5, 0.02]\n Three: [1, 1]\n Four: [0, 0.5]",
    ),
    content=(
      #|500x500
      #|<text class="pele-label" x="250" y="479" text-anchor="middle">
      #|<text class="pele-label" x="250" y="469.32" text-anchor="middle">
      #|<text class="pele-label" x="476.33" y="29.4" text-anchor="middle">
      #|<text class="pele-label" x="30.34" y="273.4" text-anchor="middle">
    ),
  )
  inspect(
    tags(
      "text", "quadrantChart\n A: [0.5, 0.5]\n B: [0.5, 0.5]\n C: [0.5, 0.5]\n D: [0.5, 0.5]\n E: [0.5, 0.5]",
    ),
    content="500x500\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"237\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"264.33\" y=\"254.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"235.67\" y=\"254.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">",
  )
  inspect(
    tags(
      "text", "quadrantChart\n A very long point label that wraps around: [0.5, 0.5]",
    ),
    content="500x500\n<text class=\"pele-label\" text-anchor=\"middle\" xml:space=\"preserve\">",
  )
}

///|
let crowded_chart : String = "quadrantChart\n  title Q4 candidates by effort and impact\n  x-axis Low effort --> High effort\n  y-axis Low impact --> High impact\n  quadrant-1 Plan carefully\n  quadrant-2 Do first\n  quadrant-3 Reconsider\n  quadrant-4 Quick wins\n"

///|
test "a point label at a quadrant's edge goes below the quadrant's title before crossing a gap" {
  inspect(
    tags(
      "text",
      crowded_chart +
      "  Chart gallery editor: [0.72, 0.85]\n  First-run onboarding: [0.35, 0.78]\n  Shared folders: [0.88, 0.70]\n  Export to PDF: [0.30, 0.55]\n  Custom themes: [0.45, 0.20]\n  Calendar sync: [0.65, 0.30]\n  Keyboard shortcut sheet: [0.12, 0.48]",
    ),
    content=(
      #|500x500
      #|<text class="pele-title" font-weight="var(--_tw)" text-anchor="middle" xml:space="preserve">
      #|<text class="pele-label" fill="var(--_fg)" stroke="none" x="378.5" y="64.6" text-anchor="middle">
      #|<text class="pele-label" fill="var(--_fg)" stroke="none" x="147.5" y="64.6" text-anchor="middle">
      #|<text class="pele-label" fill="var(--_fg)" stroke="none" x="147.5" y="278.6" text-anchor="middle">
      #|<text class="pele-label" fill="var(--_fg)" stroke="none" x="378.5" y="278.6" text-anchor="middle">
      #|<text x="148.5" y="486.4" text-anchor="middle">
      #|<text x="377.5" y="486.4" text-anchor="middle">
      #|<text x="0" y="4.9" text-anchor="middle">
      #|<text x="0" y="4.9" text-anchor="middle">
      #|<text class="pele-label" x="363.76" y="127" text-anchor="middle">
      #|<text class="pele-label" x="194.3" y="156.68" text-anchor="middle">
      #|<text class="pele-label" x="437.04" y="190.6" text-anchor="middle">
      #|<text class="pele-label" x="171.4" y="219.8" text-anchor="middle">
      #|<text class="pele-label" x="188.09" y="385.4" text-anchor="middle">
      #|<text class="pele-label" x="331.7" y="360.2" text-anchor="middle">
      #|<text class="pele-label" x="109.03" y="301.4" text-anchor="middle">
    ),
  )
}

///|
test "a point label stays beside its point when there is room, before going below the title" {
  inspect(
    tags("text", crowded_chart + "  Left edge: [0, 0.5]", max_width=320),
    content=(
      #|320x320
      #|<text class="pele-title" font-weight="var(--_tw)" text-anchor="middle" xml:space="preserve">
      #|<text class="pele-label" fill="var(--_fg)" stroke="none" x="243.5" y="64.6" text-anchor="middle">
      #|<text class="pele-label" fill="var(--_fg)" stroke="none" x="102.5" y="64.6" text-anchor="middle">
      #|<text class="pele-label" fill="var(--_fg)" stroke="none" x="102.5" y="188.6" text-anchor="middle">
      #|<text class="pele-label" fill="var(--_fg)" stroke="none" x="243.5" y="188.6" text-anchor="middle">
      #|<text x="103.5" y="306.4" text-anchor="middle">
      #|<text x="242.5" y="306.4" text-anchor="middle">
      #|<text x="0" y="4.9" text-anchor="middle">
      #|<text x="0" y="4.9" text-anchor="middle">
      #|<text class="pele-label" x="59.02" y="151" text-anchor="middle">
    ),
  )
}

///|
test "labels read markdown strings and line breaks" {
  inspect(
    svg(
      "quadrantChart\n quadrant-1 \"`**Bold** text`\"\n \"two<br>lines\": [0.5, 0.5]",
    ),
    content=(
      #|500x500 <svg xmlns="http://www.w3.org/2000/svg" class="pele pele-quadrantChart" viewBox="0 0 500 500" width="500" height="500" style="max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_w:var(--pele-bold-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)" fill="var(--_fg)" role="graphics-document document" aria-roledescription="quadrantChart"><g class="pele-quadrants" fill="var(--_s)" stroke="var(--_b)"><g class="pele-quadrant" data-id="1"><rect x="252" y="8" width="240" height="240" style="rx:var(--_r)"/><text class="pele-label" fill="var(--_fg)" stroke="none" text-anchor="middle" xml:space="preserve"><tspan x="372" y="30.6" font-weight="var(--_w)">Bold</tspan><tspan> text</tspan></text></g><g class="pele-quadrant" data-id="2"><rect x="8" y="8" width="240" height="240" style="rx:var(--_r)"/></g><g class="pele-quadrant" data-id="3"><rect x="8" y="252" width="240" height="240" style="rx:var(--_r)"/></g><g class="pele-quadrant" data-id="4"><rect x="252" y="252" width="240" height="240" style="rx:var(--_r)"/></g></g><g class="pele-points" fill="var(--pele-series-1,#4c78a8)"><circle class="pele-point" data-id="two&lt;br&gt;lines" cx="250" cy="250" r="5"/></g><g class="pele-point-labels" font-size="12"><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="250" y="271.4">two</tspan><tspan x="250" y="287.4">lines</tspan></text></g></svg>
    ),
  )
}

///|
test "the title comes from the front matter unless the chart sets one" {
  inspect(
    tags(
      "text", "---\ntitle: From front matter\n---\nquadrantChart\n A: [0.5, 0.5]",
    ),
    content="500x500\n<text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\">\n<text class=\"pele-label\" x=\"250\" y=\"288.4\" text-anchor=\"middle\">",
  )
  inspect(
    tags(
      "text", "---\ntitle: From front matter\n---\nquadrantChart\n title Own",
    ),
    content="500x500\n<text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\">",
  )
  inspect(
    tags("text", "---\ntitle: From front matter\n---\nquadrantChart\n title"),
    content="500x500",
  )
}

///|
test "the chart is named for assistive technology" {
  inspect(
    svg(
      "quadrantChart\n accTitle: Priorities\n accDescr: Four boxes\n quadrant-1 Plan",
    ),
    content="500x500 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-quadrantChart\" viewBox=\"0 0 500 500\" width=\"500\" height=\"500\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"quadrantChart\" aria-labelledby=\"pele-title\" aria-describedby=\"pele-desc\"><title id=\"pele-title\">Priorities</title><desc id=\"pele-desc\">Four boxes</desc><g class=\"pele-quadrants\" fill=\"var(--_s)\" stroke=\"var(--_b)\"><g class=\"pele-quadrant\" data-id=\"1\"><rect x=\"252\" y=\"8\" width=\"240\" height=\"240\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" fill=\"var(--_fg)\" stroke=\"none\" x=\"372\" y=\"133.6\" text-anchor=\"middle\">Plan</text></g><g class=\"pele-quadrant\" data-id=\"2\"><rect x=\"8\" y=\"8\" width=\"240\" height=\"240\" style=\"rx:var(--_r)\"/></g><g class=\"pele-quadrant\" data-id=\"3\"><rect x=\"8\" y=\"252\" width=\"240\" height=\"240\" style=\"rx:var(--_r)\"/></g><g class=\"pele-quadrant\" data-id=\"4\"><rect x=\"252\" y=\"252\" width=\"240\" height=\"240\" style=\"rx:var(--_r)\"/></g></g></svg>",
  )
}

///|
test "a chart of more than 300 points skips the search for free places" {
  inspect(
    count(
      "circle", "quadrantChart\n P0: [0.5, 0.5]\n P1: [0.5, 0.5]\n P2: [0.5, 0.5]\n P3: [0.5, 0.5]\n P4: [0.5, 0.5]\n P5: [0.5, 0.5]\n P6: [0.5, 0.5]\n P7: [0.5, 0.5]\n P8: [0.5, 0.5]\n P9: [0.5, 0.5]\n P10: [0.5, 0.5]\n P11: [0.5, 0.5]\n P12: [0.5, 0.5]\n P13: [0.5, 0.5]\n P14: [0.5, 0.5]\n P15: [0.5, 0.5]\n P16: [0.5, 0.5]\n P17: [0.5, 0.5]\n P18: [0.5, 0.5]\n P19: [0.5, 0.5]\n P20: [0.5, 0.5]\n P21: [0.5, 0.5]\n P22: [0.5, 0.5]\n P23: [0.5, 0.5]\n P24: [0.5, 0.5]\n P25: [0.5, 0.5]\n P26: [0.5, 0.5]\n P27: [0.5, 0.5]\n P28: [0.5, 0.5]\n P29: [0.5, 0.5]\n P30: [0.5, 0.5]\n P31: [0.5, 0.5]\n P32: [0.5, 0.5]\n P33: [0.5, 0.5]\n P34: [0.5, 0.5]\n P35: [0.5, 0.5]\n P36: [0.5, 0.5]\n P37: [0.5, 0.5]\n P38: [0.5, 0.5]\n P39: [0.5, 0.5]\n P40: [0.5, 0.5]\n P41: [0.5, 0.5]\n P42: [0.5, 0.5]\n P43: [0.5, 0.5]\n P44: [0.5, 0.5]\n P45: [0.5, 0.5]\n P46: [0.5, 0.5]\n P47: [0.5, 0.5]\n P48: [0.5, 0.5]\n P49: [0.5, 0.5]\n P50: [0.5, 0.5]\n P51: [0.5, 0.5]\n P52: [0.5, 0.5]\n P53: [0.5, 0.5]\n P54: [0.5, 0.5]\n P55: [0.5, 0.5]\n P56: [0.5, 0.5]\n P57: [0.5, 0.5]\n P58: [0.5, 0.5]\n P59: [0.5, 0.5]\n P60: [0.5, 0.5]\n P61: [0.5, 0.5]\n P62: [0.5, 0.5]\n P63: [0.5, 0.5]\n P64: [0.5, 0.5]\n P65: [0.5, 0.5]\n P66: [0.5, 0.5]\n P67: [0.5, 0.5]\n P68: [0.5, 0.5]\n P69: [0.5, 0.5]\n P70: [0.5, 0.5]\n P71: [0.5, 0.5]\n P72: [0.5, 0.5]\n P73: [0.5, 0.5]\n P74: [0.5, 0.5]\n P75: [0.5, 0.5]\n P76: [0.5, 0.5]\n P77: [0.5, 0.5]\n P78: [0.5, 0.5]\n P79: [0.5, 0.5]\n P80: [0.5, 0.5]\n P81: [0.5, 0.5]\n P82: [0.5, 0.5]\n P83: [0.5, 0.5]\n P84: [0.5, 0.5]\n P85: [0.5, 0.5]\n P86: [0.5, 0.5]\n P87: [0.5, 0.5]\n P88: [0.5, 0.5]\n P89: [0.5, 0.5]\n P90: [0.5, 0.5]\n P91: [0.5, 0.5]\n P92: [0.5, 0.5]\n P93: [0.5, 0.5]\n P94: [0.5, 0.5]\n P95: [0.5, 0.5]\n P96: [0.5, 0.5]\n P97: [0.5, 0.5]\n P98: [0.5, 0.5]\n P99: [0.5, 0.5]\n P100: [0.5, 0.5]\n P101: [0.5, 0.5]\n P102: [0.5, 0.5]\n P103: [0.5, 0.5]\n P104: [0.5, 0.5]\n P105: [0.5, 0.5]\n P106: [0.5, 0.5]\n P107: [0.5, 0.5]\n P108: [0.5, 0.5]\n P109: [0.5, 0.5]\n P110: [0.5, 0.5]\n P111: [0.5, 0.5]\n P112: [0.5, 0.5]\n P113: [0.5, 0.5]\n P114: [0.5, 0.5]\n P115: [0.5, 0.5]\n P116: [0.5, 0.5]\n P117: [0.5, 0.5]\n P118: [0.5, 0.5]\n P119: [0.5, 0.5]\n P120: [0.5, 0.5]\n P121: [0.5, 0.5]\n P122: [0.5, 0.5]\n P123: [0.5, 0.5]\n P124: [0.5, 0.5]\n P125: [0.5, 0.5]\n P126: [0.5, 0.5]\n P127: [0.5, 0.5]\n P128: [0.5, 0.5]\n P129: [0.5, 0.5]\n P130: [0.5, 0.5]\n P131: [0.5, 0.5]\n P132: [0.5, 0.5]\n P133: [0.5, 0.5]\n P134: [0.5, 0.5]\n P135: [0.5, 0.5]\n P136: [0.5, 0.5]\n P137: [0.5, 0.5]\n P138: [0.5, 0.5]\n P139: [0.5, 0.5]\n P140: [0.5, 0.5]\n P141: [0.5, 0.5]\n P142: [0.5, 0.5]\n P143: [0.5, 0.5]\n P144: [0.5, 0.5]\n P145: [0.5, 0.5]\n P146: [0.5, 0.5]\n P147: [0.5, 0.5]\n P148: [0.5, 0.5]\n P149: [0.5, 0.5]\n P150: [0.5, 0.5]\n P151: [0.5, 0.5]\n P152: [0.5, 0.5]\n P153: [0.5, 0.5]\n P154: [0.5, 0.5]\n P155: [0.5, 0.5]\n P156: [0.5, 0.5]\n P157: [0.5, 0.5]\n P158: [0.5, 0.5]\n P159: [0.5, 0.5]\n P160: [0.5, 0.5]\n P161: [0.5, 0.5]\n P162: [0.5, 0.5]\n P163: [0.5, 0.5]\n P164: [0.5, 0.5]\n P165: [0.5, 0.5]\n P166: [0.5, 0.5]\n P167: [0.5, 0.5]\n P168: [0.5, 0.5]\n P169: [0.5, 0.5]\n P170: [0.5, 0.5]\n P171: [0.5, 0.5]\n P172: [0.5, 0.5]\n P173: [0.5, 0.5]\n P174: [0.5, 0.5]\n P175: [0.5, 0.5]\n P176: [0.5, 0.5]\n P177: [0.5, 0.5]\n P178: [0.5, 0.5]\n P179: [0.5, 0.5]\n P180: [0.5, 0.5]\n P181: [0.5, 0.5]\n P182: [0.5, 0.5]\n P183: [0.5, 0.5]\n P184: [0.5, 0.5]\n P185: [0.5, 0.5]\n P186: [0.5, 0.5]\n P187: [0.5, 0.5]\n P188: [0.5, 0.5]\n P189: [0.5, 0.5]\n P190: [0.5, 0.5]\n P191: [0.5, 0.5]\n P192: [0.5, 0.5]\n P193: [0.5, 0.5]\n P194: [0.5, 0.5]\n P195: [0.5, 0.5]\n P196: [0.5, 0.5]\n P197: [0.5, 0.5]\n P198: [0.5, 0.5]\n P199: [0.5, 0.5]\n P200: [0.5, 0.5]\n P201: [0.5, 0.5]\n P202: [0.5, 0.5]\n P203: [0.5, 0.5]\n P204: [0.5, 0.5]\n P205: [0.5, 0.5]\n P206: [0.5, 0.5]\n P207: [0.5, 0.5]\n P208: [0.5, 0.5]\n P209: [0.5, 0.5]\n P210: [0.5, 0.5]\n P211: [0.5, 0.5]\n P212: [0.5, 0.5]\n P213: [0.5, 0.5]\n P214: [0.5, 0.5]\n P215: [0.5, 0.5]\n P216: [0.5, 0.5]\n P217: [0.5, 0.5]\n P218: [0.5, 0.5]\n P219: [0.5, 0.5]\n P220: [0.5, 0.5]\n P221: [0.5, 0.5]\n P222: [0.5, 0.5]\n P223: [0.5, 0.5]\n P224: [0.5, 0.5]\n P225: [0.5, 0.5]\n P226: [0.5, 0.5]\n P227: [0.5, 0.5]\n P228: [0.5, 0.5]\n P229: [0.5, 0.5]\n P230: [0.5, 0.5]\n P231: [0.5, 0.5]\n P232: [0.5, 0.5]\n P233: [0.5, 0.5]\n P234: [0.5, 0.5]\n P235: [0.5, 0.5]\n P236: [0.5, 0.5]\n P237: [0.5, 0.5]\n P238: [0.5, 0.5]\n P239: [0.5, 0.5]\n P240: [0.5, 0.5]\n P241: [0.5, 0.5]\n P242: [0.5, 0.5]\n P243: [0.5, 0.5]\n P244: [0.5, 0.5]\n P245: [0.5, 0.5]\n P246: [0.5, 0.5]\n P247: [0.5, 0.5]\n P248: [0.5, 0.5]\n P249: [0.5, 0.5]\n P250: [0.5, 0.5]\n P251: [0.5, 0.5]\n P252: [0.5, 0.5]\n P253: [0.5, 0.5]\n P254: [0.5, 0.5]\n P255: [0.5, 0.5]\n P256: [0.5, 0.5]\n P257: [0.5, 0.5]\n P258: [0.5, 0.5]\n P259: [0.5, 0.5]\n P260: [0.5, 0.5]\n P261: [0.5, 0.5]\n P262: [0.5, 0.5]\n P263: [0.5, 0.5]\n P264: [0.5, 0.5]\n P265: [0.5, 0.5]\n P266: [0.5, 0.5]\n P267: [0.5, 0.5]\n P268: [0.5, 0.5]\n P269: [0.5, 0.5]\n P270: [0.5, 0.5]\n P271: [0.5, 0.5]\n P272: [0.5, 0.5]\n P273: [0.5, 0.5]\n P274: [0.5, 0.5]\n P275: [0.5, 0.5]\n P276: [0.5, 0.5]\n P277: [0.5, 0.5]\n P278: [0.5, 0.5]\n P279: [0.5, 0.5]\n P280: [0.5, 0.5]\n P281: [0.5, 0.5]\n P282: [0.5, 0.5]\n P283: [0.5, 0.5]\n P284: [0.5, 0.5]\n P285: [0.5, 0.5]\n P286: [0.5, 0.5]\n P287: [0.5, 0.5]\n P288: [0.5, 0.5]\n P289: [0.5, 0.5]\n P290: [0.5, 0.5]\n P291: [0.5, 0.5]\n P292: [0.5, 0.5]\n P293: [0.5, 0.5]\n P294: [0.5, 0.5]\n P295: [0.5, 0.5]\n P296: [0.5, 0.5]\n P297: [0.5, 0.5]\n P298: [0.5, 0.5]\n P299: [0.5, 0.5]\n",
    ),
    content="300",
  )
  inspect(
    count(
      "circle", "quadrantChart\n P0: [0.5, 0.5]\n P1: [0.5, 0.5]\n P2: [0.5, 0.5]\n P3: [0.5, 0.5]\n P4: [0.5, 0.5]\n P5: [0.5, 0.5]\n P6: [0.5, 0.5]\n P7: [0.5, 0.5]\n P8: [0.5, 0.5]\n P9: [0.5, 0.5]\n P10: [0.5, 0.5]\n P11: [0.5, 0.5]\n P12: [0.5, 0.5]\n P13: [0.5, 0.5]\n P14: [0.5, 0.5]\n P15: [0.5, 0.5]\n P16: [0.5, 0.5]\n P17: [0.5, 0.5]\n P18: [0.5, 0.5]\n P19: [0.5, 0.5]\n P20: [0.5, 0.5]\n P21: [0.5, 0.5]\n P22: [0.5, 0.5]\n P23: [0.5, 0.5]\n P24: [0.5, 0.5]\n P25: [0.5, 0.5]\n P26: [0.5, 0.5]\n P27: [0.5, 0.5]\n P28: [0.5, 0.5]\n P29: [0.5, 0.5]\n P30: [0.5, 0.5]\n P31: [0.5, 0.5]\n P32: [0.5, 0.5]\n P33: [0.5, 0.5]\n P34: [0.5, 0.5]\n P35: [0.5, 0.5]\n P36: [0.5, 0.5]\n P37: [0.5, 0.5]\n P38: [0.5, 0.5]\n P39: [0.5, 0.5]\n P40: [0.5, 0.5]\n P41: [0.5, 0.5]\n P42: [0.5, 0.5]\n P43: [0.5, 0.5]\n P44: [0.5, 0.5]\n P45: [0.5, 0.5]\n P46: [0.5, 0.5]\n P47: [0.5, 0.5]\n P48: [0.5, 0.5]\n P49: [0.5, 0.5]\n P50: [0.5, 0.5]\n P51: [0.5, 0.5]\n P52: [0.5, 0.5]\n P53: [0.5, 0.5]\n P54: [0.5, 0.5]\n P55: [0.5, 0.5]\n P56: [0.5, 0.5]\n P57: [0.5, 0.5]\n P58: [0.5, 0.5]\n P59: [0.5, 0.5]\n P60: [0.5, 0.5]\n P61: [0.5, 0.5]\n P62: [0.5, 0.5]\n P63: [0.5, 0.5]\n P64: [0.5, 0.5]\n P65: [0.5, 0.5]\n P66: [0.5, 0.5]\n P67: [0.5, 0.5]\n P68: [0.5, 0.5]\n P69: [0.5, 0.5]\n P70: [0.5, 0.5]\n P71: [0.5, 0.5]\n P72: [0.5, 0.5]\n P73: [0.5, 0.5]\n P74: [0.5, 0.5]\n P75: [0.5, 0.5]\n P76: [0.5, 0.5]\n P77: [0.5, 0.5]\n P78: [0.5, 0.5]\n P79: [0.5, 0.5]\n P80: [0.5, 0.5]\n P81: [0.5, 0.5]\n P82: [0.5, 0.5]\n P83: [0.5, 0.5]\n P84: [0.5, 0.5]\n P85: [0.5, 0.5]\n P86: [0.5, 0.5]\n P87: [0.5, 0.5]\n P88: [0.5, 0.5]\n P89: [0.5, 0.5]\n P90: [0.5, 0.5]\n P91: [0.5, 0.5]\n P92: [0.5, 0.5]\n P93: [0.5, 0.5]\n P94: [0.5, 0.5]\n P95: [0.5, 0.5]\n P96: [0.5, 0.5]\n P97: [0.5, 0.5]\n P98: [0.5, 0.5]\n P99: [0.5, 0.5]\n P100: [0.5, 0.5]\n P101: [0.5, 0.5]\n P102: [0.5, 0.5]\n P103: [0.5, 0.5]\n P104: [0.5, 0.5]\n P105: [0.5, 0.5]\n P106: [0.5, 0.5]\n P107: [0.5, 0.5]\n P108: [0.5, 0.5]\n P109: [0.5, 0.5]\n P110: [0.5, 0.5]\n P111: [0.5, 0.5]\n P112: [0.5, 0.5]\n P113: [0.5, 0.5]\n P114: [0.5, 0.5]\n P115: [0.5, 0.5]\n P116: [0.5, 0.5]\n P117: [0.5, 0.5]\n P118: [0.5, 0.5]\n P119: [0.5, 0.5]\n P120: [0.5, 0.5]\n P121: [0.5, 0.5]\n P122: [0.5, 0.5]\n P123: [0.5, 0.5]\n P124: [0.5, 0.5]\n P125: [0.5, 0.5]\n P126: [0.5, 0.5]\n P127: [0.5, 0.5]\n P128: [0.5, 0.5]\n P129: [0.5, 0.5]\n P130: [0.5, 0.5]\n P131: [0.5, 0.5]\n P132: [0.5, 0.5]\n P133: [0.5, 0.5]\n P134: [0.5, 0.5]\n P135: [0.5, 0.5]\n P136: [0.5, 0.5]\n P137: [0.5, 0.5]\n P138: [0.5, 0.5]\n P139: [0.5, 0.5]\n P140: [0.5, 0.5]\n P141: [0.5, 0.5]\n P142: [0.5, 0.5]\n P143: [0.5, 0.5]\n P144: [0.5, 0.5]\n P145: [0.5, 0.5]\n P146: [0.5, 0.5]\n P147: [0.5, 0.5]\n P148: [0.5, 0.5]\n P149: [0.5, 0.5]\n P150: [0.5, 0.5]\n P151: [0.5, 0.5]\n P152: [0.5, 0.5]\n P153: [0.5, 0.5]\n P154: [0.5, 0.5]\n P155: [0.5, 0.5]\n P156: [0.5, 0.5]\n P157: [0.5, 0.5]\n P158: [0.5, 0.5]\n P159: [0.5, 0.5]\n P160: [0.5, 0.5]\n P161: [0.5, 0.5]\n P162: [0.5, 0.5]\n P163: [0.5, 0.5]\n P164: [0.5, 0.5]\n P165: [0.5, 0.5]\n P166: [0.5, 0.5]\n P167: [0.5, 0.5]\n P168: [0.5, 0.5]\n P169: [0.5, 0.5]\n P170: [0.5, 0.5]\n P171: [0.5, 0.5]\n P172: [0.5, 0.5]\n P173: [0.5, 0.5]\n P174: [0.5, 0.5]\n P175: [0.5, 0.5]\n P176: [0.5, 0.5]\n P177: [0.5, 0.5]\n P178: [0.5, 0.5]\n P179: [0.5, 0.5]\n P180: [0.5, 0.5]\n P181: [0.5, 0.5]\n P182: [0.5, 0.5]\n P183: [0.5, 0.5]\n P184: [0.5, 0.5]\n P185: [0.5, 0.5]\n P186: [0.5, 0.5]\n P187: [0.5, 0.5]\n P188: [0.5, 0.5]\n P189: [0.5, 0.5]\n P190: [0.5, 0.5]\n P191: [0.5, 0.5]\n P192: [0.5, 0.5]\n P193: [0.5, 0.5]\n P194: [0.5, 0.5]\n P195: [0.5, 0.5]\n P196: [0.5, 0.5]\n P197: [0.5, 0.5]\n P198: [0.5, 0.5]\n P199: [0.5, 0.5]\n P200: [0.5, 0.5]\n P201: [0.5, 0.5]\n P202: [0.5, 0.5]\n P203: [0.5, 0.5]\n P204: [0.5, 0.5]\n P205: [0.5, 0.5]\n P206: [0.5, 0.5]\n P207: [0.5, 0.5]\n P208: [0.5, 0.5]\n P209: [0.5, 0.5]\n P210: [0.5, 0.5]\n P211: [0.5, 0.5]\n P212: [0.5, 0.5]\n P213: [0.5, 0.5]\n P214: [0.5, 0.5]\n P215: [0.5, 0.5]\n P216: [0.5, 0.5]\n P217: [0.5, 0.5]\n P218: [0.5, 0.5]\n P219: [0.5, 0.5]\n P220: [0.5, 0.5]\n P221: [0.5, 0.5]\n P222: [0.5, 0.5]\n P223: [0.5, 0.5]\n P224: [0.5, 0.5]\n P225: [0.5, 0.5]\n P226: [0.5, 0.5]\n P227: [0.5, 0.5]\n P228: [0.5, 0.5]\n P229: [0.5, 0.5]\n P230: [0.5, 0.5]\n P231: [0.5, 0.5]\n P232: [0.5, 0.5]\n P233: [0.5, 0.5]\n P234: [0.5, 0.5]\n P235: [0.5, 0.5]\n P236: [0.5, 0.5]\n P237: [0.5, 0.5]\n P238: [0.5, 0.5]\n P239: [0.5, 0.5]\n P240: [0.5, 0.5]\n P241: [0.5, 0.5]\n P242: [0.5, 0.5]\n P243: [0.5, 0.5]\n P244: [0.5, 0.5]\n P245: [0.5, 0.5]\n P246: [0.5, 0.5]\n P247: [0.5, 0.5]\n P248: [0.5, 0.5]\n P249: [0.5, 0.5]\n P250: [0.5, 0.5]\n P251: [0.5, 0.5]\n P252: [0.5, 0.5]\n P253: [0.5, 0.5]\n P254: [0.5, 0.5]\n P255: [0.5, 0.5]\n P256: [0.5, 0.5]\n P257: [0.5, 0.5]\n P258: [0.5, 0.5]\n P259: [0.5, 0.5]\n P260: [0.5, 0.5]\n P261: [0.5, 0.5]\n P262: [0.5, 0.5]\n P263: [0.5, 0.5]\n P264: [0.5, 0.5]\n P265: [0.5, 0.5]\n P266: [0.5, 0.5]\n P267: [0.5, 0.5]\n P268: [0.5, 0.5]\n P269: [0.5, 0.5]\n P270: [0.5, 0.5]\n P271: [0.5, 0.5]\n P272: [0.5, 0.5]\n P273: [0.5, 0.5]\n P274: [0.5, 0.5]\n P275: [0.5, 0.5]\n P276: [0.5, 0.5]\n P277: [0.5, 0.5]\n P278: [0.5, 0.5]\n P279: [0.5, 0.5]\n P280: [0.5, 0.5]\n P281: [0.5, 0.5]\n P282: [0.5, 0.5]\n P283: [0.5, 0.5]\n P284: [0.5, 0.5]\n P285: [0.5, 0.5]\n P286: [0.5, 0.5]\n P287: [0.5, 0.5]\n P288: [0.5, 0.5]\n P289: [0.5, 0.5]\n P290: [0.5, 0.5]\n P291: [0.5, 0.5]\n P292: [0.5, 0.5]\n P293: [0.5, 0.5]\n P294: [0.5, 0.5]\n P295: [0.5, 0.5]\n P296: [0.5, 0.5]\n P297: [0.5, 0.5]\n P298: [0.5, 0.5]\n P299: [0.5, 0.5]\n P300: [0.5, 0.5]\n",
    ),
    content="301",
  )
  inspect(
    tags(
      "text", "quadrantChart\n P0: [0.0, 0.0]\n P1: [0.1, 0.7]\n P2: [0.2, 0.4]\n P3: [0.3, 0.1]\n P4: [0.4, 0.8]\n P5: [0.5, 0.5]\n P6: [0.6, 0.2]\n P7: [0.7, 0.9]\n P8: [0.8, 0.6]\n P9: [0.9, 0.3]\n P10: [0.0, 0.0]\n P11: [0.1, 0.7]\n P12: [0.2, 0.4]\n P13: [0.3, 0.1]\n P14: [0.4, 0.8]\n P15: [0.5, 0.5]\n P16: [0.6, 0.2]\n P17: [0.7, 0.9]\n P18: [0.8, 0.6]\n P19: [0.9, 0.3]\n P20: [0.0, 0.0]\n P21: [0.1, 0.7]\n P22: [0.2, 0.4]\n P23: [0.3, 0.1]\n P24: [0.4, 0.8]\n P25: [0.5, 0.5]\n P26: [0.6, 0.2]\n P27: [0.7, 0.9]\n P28: [0.8, 0.6]\n P29: [0.9, 0.3]\n P30: [0.0, 0.0]\n P31: [0.1, 0.7]\n P32: [0.2, 0.4]\n P33: [0.3, 0.1]\n P34: [0.4, 0.8]\n P35: [0.5, 0.5]\n P36: [0.6, 0.2]\n P37: [0.7, 0.9]\n P38: [0.8, 0.6]\n P39: [0.9, 0.3]\n P40: [0.0, 0.0]\n P41: [0.1, 0.7]\n P42: [0.2, 0.4]\n P43: [0.3, 0.1]\n P44: [0.4, 0.8]\n P45: [0.5, 0.5]\n P46: [0.6, 0.2]\n P47: [0.7, 0.9]\n P48: [0.8, 0.6]\n P49: [0.9, 0.3]\n P50: [0.0, 0.0]\n P51: [0.1, 0.7]\n P52: [0.2, 0.4]\n P53: [0.3, 0.1]\n P54: [0.4, 0.8]\n P55: [0.5, 0.5]\n P56: [0.6, 0.2]\n P57: [0.7, 0.9]\n P58: [0.8, 0.6]\n P59: [0.9, 0.3]\n P60: [0.0, 0.0]\n P61: [0.1, 0.7]\n P62: [0.2, 0.4]\n P63: [0.3, 0.1]\n P64: [0.4, 0.8]\n P65: [0.5, 0.5]\n P66: [0.6, 0.2]\n P67: [0.7, 0.9]\n P68: [0.8, 0.6]\n P69: [0.9, 0.3]\n P70: [0.0, 0.0]\n P71: [0.1, 0.7]\n P72: [0.2, 0.4]\n P73: [0.3, 0.1]\n P74: [0.4, 0.8]\n P75: [0.5, 0.5]\n P76: [0.6, 0.2]\n P77: [0.7, 0.9]\n P78: [0.8, 0.6]\n P79: [0.9, 0.3]\n P80: [0.0, 0.0]\n P81: [0.1, 0.7]\n P82: [0.2, 0.4]\n P83: [0.3, 0.1]\n P84: [0.4, 0.8]\n P85: [0.5, 0.5]\n P86: [0.6, 0.2]\n P87: [0.7, 0.9]\n P88: [0.8, 0.6]\n P89: [0.9, 0.3]\n P90: [0.0, 0.0]\n P91: [0.1, 0.7]\n P92: [0.2, 0.4]\n P93: [0.3, 0.1]\n P94: [0.4, 0.8]\n P95: [0.5, 0.5]\n P96: [0.6, 0.2]\n P97: [0.7, 0.9]\n P98: [0.8, 0.6]\n P99: [0.9, 0.3]\n P100: [0.0, 0.0]\n P101: [0.1, 0.7]\n P102: [0.2, 0.4]\n P103: [0.3, 0.1]\n P104: [0.4, 0.8]\n P105: [0.5, 0.5]\n P106: [0.6, 0.2]\n P107: [0.7, 0.9]\n P108: [0.8, 0.6]\n P109: [0.9, 0.3]\n P110: [0.0, 0.0]\n P111: [0.1, 0.7]\n P112: [0.2, 0.4]\n P113: [0.3, 0.1]\n P114: [0.4, 0.8]\n P115: [0.5, 0.5]\n P116: [0.6, 0.2]\n P117: [0.7, 0.9]\n P118: [0.8, 0.6]\n P119: [0.9, 0.3]\n P120: [0.0, 0.0]\n P121: [0.1, 0.7]\n P122: [0.2, 0.4]\n P123: [0.3, 0.1]\n P124: [0.4, 0.8]\n P125: [0.5, 0.5]\n P126: [0.6, 0.2]\n P127: [0.7, 0.9]\n P128: [0.8, 0.6]\n P129: [0.9, 0.3]\n P130: [0.0, 0.0]\n P131: [0.1, 0.7]\n P132: [0.2, 0.4]\n P133: [0.3, 0.1]\n P134: [0.4, 0.8]\n P135: [0.5, 0.5]\n P136: [0.6, 0.2]\n P137: [0.7, 0.9]\n P138: [0.8, 0.6]\n P139: [0.9, 0.3]\n P140: [0.0, 0.0]\n P141: [0.1, 0.7]\n P142: [0.2, 0.4]\n P143: [0.3, 0.1]\n P144: [0.4, 0.8]\n P145: [0.5, 0.5]\n P146: [0.6, 0.2]\n P147: [0.7, 0.9]\n P148: [0.8, 0.6]\n P149: [0.9, 0.3]\n P150: [0.0, 0.0]\n P151: [0.1, 0.7]\n P152: [0.2, 0.4]\n P153: [0.3, 0.1]\n P154: [0.4, 0.8]\n P155: [0.5, 0.5]\n P156: [0.6, 0.2]\n P157: [0.7, 0.9]\n P158: [0.8, 0.6]\n P159: [0.9, 0.3]\n P160: [0.0, 0.0]\n P161: [0.1, 0.7]\n P162: [0.2, 0.4]\n P163: [0.3, 0.1]\n P164: [0.4, 0.8]\n P165: [0.5, 0.5]\n P166: [0.6, 0.2]\n P167: [0.7, 0.9]\n P168: [0.8, 0.6]\n P169: [0.9, 0.3]\n P170: [0.0, 0.0]\n P171: [0.1, 0.7]\n P172: [0.2, 0.4]\n P173: [0.3, 0.1]\n P174: [0.4, 0.8]\n P175: [0.5, 0.5]\n P176: [0.6, 0.2]\n P177: [0.7, 0.9]\n P178: [0.8, 0.6]\n P179: [0.9, 0.3]\n P180: [0.0, 0.0]\n P181: [0.1, 0.7]\n P182: [0.2, 0.4]\n P183: [0.3, 0.1]\n P184: [0.4, 0.8]\n P185: [0.5, 0.5]\n P186: [0.6, 0.2]\n P187: [0.7, 0.9]\n P188: [0.8, 0.6]\n P189: [0.9, 0.3]\n P190: [0.0, 0.0]\n P191: [0.1, 0.7]\n P192: [0.2, 0.4]\n P193: [0.3, 0.1]\n P194: [0.4, 0.8]\n P195: [0.5, 0.5]\n P196: [0.6, 0.2]\n P197: [0.7, 0.9]\n P198: [0.8, 0.6]\n P199: [0.9, 0.3]\n P200: [0.0, 0.0]\n P201: [0.1, 0.7]\n P202: [0.2, 0.4]\n P203: [0.3, 0.1]\n P204: [0.4, 0.8]\n P205: [0.5, 0.5]\n P206: [0.6, 0.2]\n P207: [0.7, 0.9]\n P208: [0.8, 0.6]\n P209: [0.9, 0.3]\n P210: [0.0, 0.0]\n P211: [0.1, 0.7]\n P212: [0.2, 0.4]\n P213: [0.3, 0.1]\n P214: [0.4, 0.8]\n P215: [0.5, 0.5]\n P216: [0.6, 0.2]\n P217: [0.7, 0.9]\n P218: [0.8, 0.6]\n P219: [0.9, 0.3]\n P220: [0.0, 0.0]\n P221: [0.1, 0.7]\n P222: [0.2, 0.4]\n P223: [0.3, 0.1]\n P224: [0.4, 0.8]\n P225: [0.5, 0.5]\n P226: [0.6, 0.2]\n P227: [0.7, 0.9]\n P228: [0.8, 0.6]\n P229: [0.9, 0.3]\n P230: [0.0, 0.0]\n P231: [0.1, 0.7]\n P232: [0.2, 0.4]\n P233: [0.3, 0.1]\n P234: [0.4, 0.8]\n P235: [0.5, 0.5]\n P236: [0.6, 0.2]\n P237: [0.7, 0.9]\n P238: [0.8, 0.6]\n P239: [0.9, 0.3]\n P240: [0.0, 0.0]\n P241: [0.1, 0.7]\n P242: [0.2, 0.4]\n P243: [0.3, 0.1]\n P244: [0.4, 0.8]\n P245: [0.5, 0.5]\n P246: [0.6, 0.2]\n P247: [0.7, 0.9]\n P248: [0.8, 0.6]\n P249: [0.9, 0.3]\n P250: [0.0, 0.0]\n P251: [0.1, 0.7]\n P252: [0.2, 0.4]\n P253: [0.3, 0.1]\n P254: [0.4, 0.8]\n P255: [0.5, 0.5]\n P256: [0.6, 0.2]\n P257: [0.7, 0.9]\n P258: [0.8, 0.6]\n P259: [0.9, 0.3]\n P260: [0.0, 0.0]\n P261: [0.1, 0.7]\n P262: [0.2, 0.4]\n P263: [0.3, 0.1]\n P264: [0.4, 0.8]\n P265: [0.5, 0.5]\n P266: [0.6, 0.2]\n P267: [0.7, 0.9]\n P268: [0.8, 0.6]\n P269: [0.9, 0.3]\n P270: [0.0, 0.0]\n P271: [0.1, 0.7]\n P272: [0.2, 0.4]\n P273: [0.3, 0.1]\n P274: [0.4, 0.8]\n P275: [0.5, 0.5]\n P276: [0.6, 0.2]\n P277: [0.7, 0.9]\n P278: [0.8, 0.6]\n P279: [0.9, 0.3]\n P280: [0.0, 0.0]\n P281: [0.1, 0.7]\n P282: [0.2, 0.4]\n P283: [0.3, 0.1]\n P284: [0.4, 0.8]\n P285: [0.5, 0.5]\n P286: [0.6, 0.2]\n P287: [0.7, 0.9]\n P288: [0.8, 0.6]\n P289: [0.9, 0.3]\n P290: [0.0, 0.0]\n P291: [0.1, 0.7]\n P292: [0.2, 0.4]\n P293: [0.3, 0.1]\n P294: [0.4, 0.8]\n P295: [0.5, 0.5]\n P296: [0.6, 0.2]\n P297: [0.7, 0.9]\n P298: [0.8, 0.6]\n P299: [0.9, 0.3]\n P300: [0.0, 0.0]\n",
    ),
    content="500x500\n<text class=\"pele-label\" x=\"15.34\" y=\"479\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"18.67\" y=\"479\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"18.67\" y=\"479\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"18.67\" y=\"479\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"18.67\" y=\"479\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"18.67\" y=\"479\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"18.67\" y=\"479\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"18.67\" y=\"479\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"18.67\" y=\"479\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"18.67\" y=\"479\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"8\" y=\"513.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"8\" y=\"513.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"8\" y=\"513.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"8\" y=\"513.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"8\" y=\"513.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"8\" y=\"513.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"8\" y=\"513.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"8\" y=\"513.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"8\" y=\"513.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"8\" y=\"513.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"8\" y=\"513.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"8\" y=\"513.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"8\" y=\"513.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"8\" y=\"513.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"8\" y=\"513.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"8\" y=\"513.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"8\" y=\"513.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"8\" y=\"513.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"8\" y=\"513.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"8\" y=\"513.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"56.4\" y=\"174.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"104.8\" y=\"319.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"153.2\" y=\"465\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"201.6\" y=\"126.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"298.4\" y=\"416.6\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"346.8\" y=\"77.8\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"395.2\" y=\"223\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"443.6\" y=\"368.2\" text-anchor=\"middle\">\n<text class=\"pele-label\" x=\"8\" y=\"513.4\" text-anchor=\"middle\">",
  )
}

///|
test "text from the source is escaped" {
  inspect(
    svg(
      "quadrantChart\n title <script>alert(1)</script>\n x-axis \"a & b\" --> \"<c>\"\n A:::\"><x: [0.5, 0.5]\n \"<img src=x onerror=1>\": [0.2, 0.2]",
    ),
    content="Lexical error on line 4. Unrecognized text.\n A:::\"><x: [0.5, 0.5]\n-----^",
  )
  inspect(
    svg(
      "quadrantChart\n A:::__proto__: [0.5, 0.5]\n B:::constructor: [0.1, 0.1]\n C:::toString: [0.2, 0.2]\n classDef constructor radius: 3\n classDef hasOwnProperty color: #f00",
    ),
    content="500x500 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-quadrantChart\" viewBox=\"0 0 500 500\" width=\"500\" height=\"500\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"quadrantChart\"><g class=\"pele-quadrants\" fill=\"var(--_s)\" stroke=\"var(--_b)\"><g class=\"pele-quadrant\" data-id=\"1\"><rect x=\"252\" y=\"8\" width=\"240\" height=\"240\" style=\"rx:var(--_r)\"/></g><g class=\"pele-quadrant\" data-id=\"2\"><rect x=\"8\" y=\"8\" width=\"240\" height=\"240\" style=\"rx:var(--_r)\"/></g><g class=\"pele-quadrant\" data-id=\"3\"><rect x=\"8\" y=\"252\" width=\"240\" height=\"240\" style=\"rx:var(--_r)\"/></g><g class=\"pele-quadrant\" data-id=\"4\"><rect x=\"252\" y=\"252\" width=\"240\" height=\"240\" style=\"rx:var(--_r)\"/></g></g><g class=\"pele-points\" fill=\"var(--pele-series-1,#4c78a8)\"><circle class=\"pele-point toString\" data-id=\"C\" cx=\"104.8\" cy=\"395.2\" r=\"5\"/><circle class=\"pele-point constructor\" data-id=\"B\" cx=\"56.4\" cy=\"443.6\" r=\"3\"/><circle class=\"pele-point __proto__\" data-id=\"A\" cx=\"250\" cy=\"250\" r=\"5\"/></g><g class=\"pele-point-labels\" font-size=\"12\"><text class=\"pele-label\" x=\"250\" y=\"271.4\" text-anchor=\"middle\">A</text><text class=\"pele-label\" x=\"56.4\" y=\"463\" text-anchor=\"middle\">B</text><text class=\"pele-label\" x=\"104.8\" y=\"416.6\" text-anchor=\"middle\">C</text></g></svg>",
  )
}

///|
test "extreme numbers are kept within bounds" {
  inspect(
    tags(
      "circle", "quadrantChart\n A: [0.5, 0.5] radius: 9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999",
    ),
    content="500x500\n<circle class=\"pele-point\" data-id=\"A\" cx=\"250\" cy=\"250\" r=\"2000\"/>",
  )
  inspect(
    tags(
      "circle", "quadrantChart\n A: [0.5, 0.5] stroke-width: 9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999px",
    ),
    content="500x500\n<circle class=\"pele-point\" data-id=\"A\" cx=\"250\" cy=\"250\" r=\"5\" stroke=\"var(--pele-series-1,#4c78a8)\" style=\"stroke-width:9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999px;\"/>",
  )
  inspect(
    tags(
      "circle", "---\nconfig:\n  quadrantChart:\n    chartWidth: .inf\n    pointRadius: .inf\n    quadrantPadding: .inf\n---\nquadrantChart\n y-axis Down --> Up\n A: [0.5, 0.5]",
    ),
    content="4000x500\n<circle class=\"pele-point\" data-id=\"A\" cx=\"2013\" cy=\"250\" r=\"200\"/>",
  )
  inspect(
    size(
      "---\nconfig:\n  quadrantChart:\n    chartWidth: -1\n    chartHeight: 0\n    quadrantPadding: .inf\n---\nquadrantChart\n y-axis Down --> Up\n A: [0.5, 0.5]",
    ),
    content="500x100",
  )
}
