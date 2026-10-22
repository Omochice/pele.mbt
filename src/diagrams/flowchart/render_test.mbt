///|
fn svg(source : String, max_width? : Double) -> String {
  let options = { ..@types.RenderOptions::default(), max_width, }
  let result = @core.render([@flowchart.flowchart], source, options) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "\{result.width}x\{result.height} \{result.svg}"
}

///|
test "draws nodes and the edges between them" {
  inspect(
    svg("flowchart LR\n  A --> B"),
    content="160x64 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-flowchart\" viewBox=\"0 0 160 64\" width=\"160\" height=\"64\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"flowchart\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_A_B_0\"><path d=\"M56,32L97,32\"/><path class=\"pele-marker\" d=\"M104,32L96,35.36L96,28.64Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect\" data-id=\"A\" transform=\"translate(32,32)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">A</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"B\" transform=\"translate(128,32)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">B</text></g></g></svg>",
  )
}

///|
test "lays out along the declared direction" {
  inspect(
    svg(
      "flowchart TD\n  A[Start] --> B{Choice}\n  B -->|yes| C((Done))\n  B --- D>Flag]",
    ),
    content="197x320 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-flowchart\" viewBox=\"0 0 197 320\" width=\"197\" height=\"320\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"flowchart\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_A_B_0\"><path d=\"M93.64,56L93.64,97\"/><path class=\"pele-marker\" d=\"M93.64,104L90.28,96L97,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_B_C_0\"><path d=\"M85.64,172.12C85.64,184.87 38.57,184.87 38.57,197.62L38.57,243.12\"/><path class=\"pele-marker\" d=\"M38.57,250.12L35.21,242.12L41.93,242.12Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_B_D_0\"><path d=\"M101.64,172.12C101.64,211.12 148.71,211.12 148.71,250.12\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\"><g class=\"pele-edge-label\" data-id=\"L_B_C_0\"><rect x=\"23.68\" y=\"199.62\" width=\"29.78\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"38.57\" y=\"215.02\" text-anchor=\"middle\">yes</text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect\" data-id=\"A\" transform=\"translate(93.64,32)\"><rect x=\"-34.9\" y=\"-24\" width=\"69.79\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Start</text></g><g class=\"pele-node pele-shape-diam\" data-id=\"B\" transform=\"translate(93.64,140.56)\"><polygon points=\"0,-36.56 58.5,0 0,36.56 -58.5,0\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Choice</text></g><g class=\"pele-node pele-shape-circle\" data-id=\"C\" transform=\"translate(38.57,280.69)\"><circle r=\"30.57\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Done</text></g><g class=\"pele-node pele-shape-odd\" data-id=\"D\" transform=\"translate(148.71,274.12)\"><polygon points=\"-39.56,-24 39.56,-24 39.56,24 -39.56,24 -27.56,0\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Flag</text></g></g></svg>",
  )
}
