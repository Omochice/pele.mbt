// Ported from pele v1.8.0, tests/render/agentflow.test.ts; the snapshots were taken from pele's render under the default options.

///|
/// The size, the links and the document pele draws for the source, or the message of the error.
fn snapshot(source : String, max_width? : Double) -> String {
  let options = { ..@types.RenderOptions::default(), max_width, }
  let result = @core.render([@agentflow.agentflow], source, options) catch {
    @errors.PeleError(failure) => return "error \{failure.message}"
  }
  let links = result.links.map(link => {
    "{\"id\":\{Json::string(link.id).stringify()},\"href\":\{Json::string(link.href).stringify()},\"internal\":\{link.internal}}"
  })
  "\{result.width}x\{result.height} [\{links.join(",")}]\n\{result.svg}"
}

///|
test "is detected and drawn as an agentflow document" {
  let result = @core.render(
    [@agentflow.agentflow],
    "agentflow-beta TB\n  a[\"A\"] --> b[\"B\"]",
    @types.RenderOptions::default(),
  )
  inspect(result.kind, content="agentflow")
  inspect(
    result.svg.has_prefix(
      "<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\"",
    ),
    content="true",
  )
}

///|
test "draws each of the six shapes, and a connector, in the color of its kind" {
  assert_eq(
    snapshot(
      "agentflow-beta LR\n  t[\"T\"]@{ shape: task }\n  o[\"O\"]@{ shape: tool }\n  i[\"I\"]@{ shape: input }\n  d[\"D\"]@{ shape: decision }\n  r[\"R\"]@{ shape: refdoc }\n  c[\"C\"]@{ shape: action }\n  connector k[\"K\"]\n  plain",
    ),
    "196x692 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 196 692\" width=\"196\" height=\"692\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"t\" transform=\"translate(98,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">T</text></g><g class=\"pele-node pele-shape-fr-rect pele-kind-tool\" data-id=\"o\" transform=\"translate(98,120)\"><rect x=\"-86\" y=\"-24\" width=\"172\" height=\"48\" fill=\"var(--pele-series-1,#4c78a8)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-1,#4c78a8)\" style=\"rx:var(--_r)\"/><path d=\"M-78,-24V24M78,-24V24\" fill=\"none\" stroke=\"var(--pele-series-1,#4c78a8)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">O</text></g><g class=\"pele-node pele-shape-lean-r pele-kind-input\" data-id=\"i\" transform=\"translate(98,208)\"><polygon points=\"-78,-24 90,-24 78,24 -90,24\" fill=\"var(--pele-series-4,#e45756)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-4,#e45756)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">I</text></g><g class=\"pele-node pele-shape-diam pele-kind-decision\" data-id=\"d\" transform=\"translate(98,296.61)\"><polygon points=\"0,-24.61 39.38,0 0,24.61 -39.38,0\" fill=\"var(--pele-series-3,#54a24b)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-3,#54a24b)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">D</text></g><g class=\"pele-node pele-shape-lin-doc pele-kind-refdoc\" data-id=\"r\" transform=\"translate(98,390.22)\"><path d=\"M-82,-29H82V19q-41,-12 -82,0t-82,0Z\" fill=\"var(--pele-series-5,#72b7b2)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-5,#72b7b2)\"/><path d=\"M-74,-29V23\" fill=\"none\" stroke=\"var(--pele-series-5,#72b7b2)\"/><text class=\"pele-label\" x=\"0\" y=\"0.6\" text-anchor=\"middle\">R</text></g><g class=\"pele-node pele-shape-hex pele-kind-action\" data-id=\"c\" transform=\"translate(98,483.22)\"><polygon points=\"-78,-24 78,-24 90,0 78,24 -78,24 -90,0\" fill=\"var(--pele-series-7,#b279a2)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-7,#b279a2)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">C</text></g><g class=\"pele-node pele-shape-rounded pele-kind-connector\" data-id=\"k\" transform=\"translate(98,571.22)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-6,#eeca3b)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-6,#eeca3b)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">K</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"plain\" transform=\"translate(98,659.22)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">plain</text></g></g></svg>",
  )
}

///|
test "writes the bracket shapes agentflow removed as plain tasks" {
  assert_eq(
    snapshot(
      "agentflow-beta TB\n  a((circle)) --> b([stadium]) --> c[(db)] --> d>odd] --> e(round)",
    ),
    "172x448 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 172 448\" width=\"172\" height=\"448\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\"><path d=\"M86,56L86,97\"/><path class=\"pele-marker\" d=\"M86,104L82.64,96L89.36,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_b_c_0\"><path d=\"M86,152L86,193\"/><path class=\"pele-marker\" d=\"M86,200L82.64,192L89.36,192Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_c_d_0\"><path d=\"M86,248L86,289\"/><path class=\"pele-marker\" d=\"M86,296L82.64,288L89.36,288Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_d_e_0\"><path d=\"M86,344L86,385\"/><path class=\"pele-marker\" d=\"M86,392L82.64,384L89.36,384Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(86,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">circle</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"b\" transform=\"translate(86,128)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">stadium</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"c\" transform=\"translate(86,224)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">db</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"d\" transform=\"translate(86,320)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">odd</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"e\" transform=\"translate(86,416)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">round</text></g></g></svg>",
  )
}

///|
test "draws a node with a shape outside the catalogue as a task" {
  assert_eq(
    snapshot(
      "agentflow-beta TB\n  a[\"A\"]\n  a@{ shape: \"triangle\" }\n  a --> b",
    ),
    "172x160 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 172 160\" width=\"172\" height=\"160\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\"><path d=\"M86,56L86,97\"/><path class=\"pele-marker\" d=\"M86,104L82.64,96L89.36,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(86,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">A</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"b\" transform=\"translate(86,128)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b</text></g></g></svg>",
  )
}

///|
test "draws the three edge kinds differently" {
  assert_eq(
    snapshot(
      "agentflow-beta TB\n  a --> b\n  a --x c\n  a -.- d\n  a -- \"why\" --> e",
    ),
    "760x198 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 760 198\" width=\"760\" height=\"198\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\"><path d=\"M380,56C380,92.38 86,92.38 86,128.75L86,134.75\"/><path class=\"pele-marker\" d=\"M86,141.75L82.64,133.75L89.36,133.75Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge pele-edge-failure\" data-id=\"L_a_c_0\"><path d=\"M380,56C380,93.88 282,93.88 282,131.75L282,137.75\"/><path class=\"pele-marker\" d=\"M285.5,134.25L278.5,141.25M278.5,134.25L285.5,141.25\"/></g><g class=\"pele-edge pele-edge-reference\" data-id=\"L_a_d_0\"><path d=\"M380,56C380,98.88 478,98.88 478,141.75\" stroke-dasharray=\"3 4\"/></g><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_e_0\"><path d=\"M380,56C380,74.38 674,74.38 674,92.75L674,134.75\"/><path class=\"pele-marker\" d=\"M674,141.75L670.64,133.75L677.36,133.75Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\"><g class=\"pele-edge-label\" data-id=\"L_a_e_0\"><rect x=\"657.55\" y=\"94.75\" width=\"32.89\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"674\" y=\"110.15\" text-anchor=\"middle\">why</text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(380,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">a</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"b\" transform=\"translate(86,165.75)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"c\" transform=\"translate(282,165.75)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">c</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"d\" transform=\"translate(478,165.75)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">d</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"e\" transform=\"translate(674,165.75)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">e</text></g></g></svg>",
  )
}

///|
test "fans an edge out over every pair that an ampersand names" {
  assert_eq(
    snapshot("agentflow-beta TB\n  a & b --> c & d"),
    "368x160 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 368 160\" width=\"368\" height=\"160\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_c_0\"><path d=\"M86,56L86,97\"/><path class=\"pele-marker\" d=\"M86,104L82.64,96L89.36,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_d_0\"><path d=\"M86,56C86,73.5 282,73.5 282,91L282,97\"/><path class=\"pele-marker\" d=\"M282,104L278.64,96L285.36,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_b_c_0\"><path d=\"M282,56C282,73.5 86,73.5 86,91L86,97\"/><path class=\"pele-marker\" d=\"M86,104L82.64,96L89.36,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_b_d_0\"><path d=\"M282,56L282,97\"/><path class=\"pele-marker\" d=\"M282,104L278.64,96L285.36,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(86,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">a</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"b\" transform=\"translate(282,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"c\" transform=\"translate(86,128)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">c</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"d\" transform=\"translate(282,128)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">d</text></g></g></svg>",
  )
}

///|
test "draws a self-loop beside its node" {
  assert_eq(
    snapshot("agentflow-beta TB\n  a[\"Alpha\"]\n  a --> a"),
    "224x64 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 224 64\" width=\"224\" height=\"64\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_a_0\"><path d=\"M190,24C216,16 216,48 196.69,42.06\"/><path class=\"pele-marker\" d=\"M190,40L198.63,39.14L196.66,45.56Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(112,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Alpha</text></g></g></svg>",
  )
}

///|
test "draws a self-loop across a flow that runs sideways" {
  assert_eq(
    snapshot("agentflow-beta LR\n  a[\"Alpha\"]\n  a -- again --> a\n  a --> a"),
    "172x226 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 172 226\" width=\"172\" height=\"226\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_a_0\"><path d=\"M78,137C70,163 102,163 96.06,143.69\"/><path class=\"pele-marker\" d=\"M94,137L99.56,143.66L93.14,145.63Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_a_2\"><path d=\"M72,137C58,171 114,171 102.67,143.47\"/><path class=\"pele-marker\" d=\"M100,137L106.15,143.12L99.94,145.68Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\"><g class=\"pele-edge-label\" data-id=\"L_a_a_0\"><rect x=\"64.88\" y=\"169\" width=\"42.24\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"86\" y=\"184.4\" text-anchor=\"middle\">again</text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(86,113)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Alpha</text></g></g></svg>",
  )
}

///|
test "frames a flow around its members, with its title" {
  assert_eq(
    snapshot(
      "agentflow-beta TB\n  flow team[\"Content Team\"]\n    a[\"A\"] --> b[\"B\"]\n  end\n  c[\"C\"]\n  b --> c",
    ),
    "212x336 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 212 336\" width=\"212\" height=\"336\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-clusters\"><g class=\"pele-cluster pele-flow\" data-id=\"team\"><rect x=\"8\" y=\"8\" width=\"196\" height=\"224\" fill=\"var(--pele-series-8,#9d755d)\" fill-opacity=\"0.06\" stroke=\"var(--pele-series-8,#9d755d)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"72.69\" y=\"33.6\" text-anchor=\"middle\">Content Team</text></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\"><path d=\"M106,96L106,137\"/><path class=\"pele-marker\" d=\"M106,144L102.64,136L109.36,136Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_b_c_0\"><path d=\"M106,192L106,273\"/><path class=\"pele-marker\" d=\"M106,280L102.64,272L109.36,272Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(106,72)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">A</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"b\" transform=\"translate(106,168)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">B</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"c\" transform=\"translate(106,304)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">C</text></g></g></svg>",
  )
}

///|
test "nests flows, and gives a flow without a bracketed title no title" {
  assert_eq(
    snapshot(
      "agentflow-beta TB\n  flow outer[\"Outer\"]\n    flow inner\n      a --> b\n    end\n    c\n  end",
    ),
    "448x260 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 448 260\" width=\"448\" height=\"260\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-clusters\"><g class=\"pele-cluster pele-flow\" data-id=\"outer\"><rect x=\"8\" y=\"8\" width=\"432\" height=\"244\" fill=\"var(--pele-series-8,#9d755d)\" fill-opacity=\"0.06\" stroke=\"var(--pele-series-8,#9d755d)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"42.01\" y=\"33.6\" text-anchor=\"middle\">Outer</text></g><g class=\"pele-cluster pele-flow\" data-id=\"inner\"><rect x=\"28\" y=\"48\" width=\"196\" height=\"184\" fill=\"var(--pele-series-8,#9d755d)\" fill-opacity=\"0.06\" stroke=\"var(--pele-series-8,#9d755d)\" style=\"rx:var(--_r)\"/></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\"><path d=\"M126,116L126,157\"/><path class=\"pele-marker\" d=\"M126,164L122.64,156L129.36,156Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(126,92)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">a</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"b\" transform=\"translate(126,188)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"c\" transform=\"translate(342,140)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">c</text></g></g></svg>",
  )
}

///|
test "lays a flow out in its own direction" {
  assert_eq(
    snapshot(
      "agentflow-beta TB\n  flow f[\"F\"]\n    direction LR\n    a --> b\n  end\n  f --> c",
    ),
    "416x220 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 416 220\" width=\"416\" height=\"220\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-clusters\"><g class=\"pele-cluster pele-flow\" data-id=\"f\"><rect x=\"8\" y=\"8\" width=\"400\" height=\"108\" fill=\"var(--pele-series-8,#9d755d)\" fill-opacity=\"0.06\" stroke=\"var(--pele-series-8,#9d755d)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"26.89\" y=\"33.6\" text-anchor=\"middle\">F</text></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\"><path d=\"M184,72L225,72\"/><path class=\"pele-marker\" d=\"M232,72L224,75.36L224,68.64Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_f_c_0\"><path d=\"M208,116L208,157\"/><path class=\"pele-marker\" d=\"M208,164L204.64,156L211.36,156Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(106,72)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">a</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"b\" transform=\"translate(310,72)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"c\" transform=\"translate(208,188)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">c</text></g></g></svg>",
  )
}

///|
test "ignores a flow's direction when its nodes link outside it" {
  let flows = "agentflow-beta LR\nflow S\n direction TB\n s1\n s2\nend\nflow P\n direction TB\n p1\n p2\nend\n"
  let links = "s1 --> p2\ns2 --> p1\n"
  assert_eq(
    snapshot(flows + links),
    snapshot(flows.replace_all(old=" direction TB\n", new="") + links),
  )
}

///|
test "keeps a global node out of the flows that mention it" {
  assert_eq(
    snapshot(
      "agentflow-beta TB\n  global\n    corpus[\"Shared\"]@{ shape: refdoc }\n  end\n  flow one[\"One\"]\n    a -.- corpus\n  end\n  flow two[\"Two\"]\n    b -.- corpus\n  end",
    ),
    "448x250 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 448 250\" width=\"448\" height=\"250\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-clusters\"><g class=\"pele-cluster pele-flow\" data-id=\"two\"><rect x=\"244\" y=\"8\" width=\"196\" height=\"128\" fill=\"var(--pele-series-8,#9d755d)\" fill-opacity=\"0.06\" stroke=\"var(--pele-series-8,#9d755d)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"273.11\" y=\"33.6\" text-anchor=\"middle\">Two</text></g><g class=\"pele-cluster pele-flow\" data-id=\"one\"><rect x=\"8\" y=\"8\" width=\"196\" height=\"128\" fill=\"var(--pele-series-8,#9d755d)\" fill-opacity=\"0.06\" stroke=\"var(--pele-series-8,#9d755d)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"37.12\" y=\"33.6\" text-anchor=\"middle\">One</text></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-reference\" data-id=\"L_a_corpus_0\"><path d=\"M106,96L106,136C106,160 224,160 224,184\" stroke-dasharray=\"3 4\"/></g><g class=\"pele-edge pele-edge-reference\" data-id=\"L_b_corpus_0\"><path d=\"M342,96L342,136C342,160 224,160 224,184\" stroke-dasharray=\"3 4\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-lin-doc pele-kind-refdoc\" data-id=\"corpus\" transform=\"translate(224,213)\"><path d=\"M-82,-29H82V19q-41,-12 -82,0t-82,0Z\" fill=\"var(--pele-series-5,#72b7b2)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-5,#72b7b2)\"/><path d=\"M-74,-29V23\" fill=\"none\" stroke=\"var(--pele-series-5,#72b7b2)\"/><text class=\"pele-label\" x=\"0\" y=\"0.6\" text-anchor=\"middle\">Shared</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(106,72)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">a</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"b\" transform=\"translate(342,72)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b</text></g></g></svg>",
  )
}

///|
test "folds a collapsed flow into one node and reconnects its edges" {
  assert_eq(
    snapshot(
      "agentflow-beta TB\n  in[\"In\"] --> v\n  flow p[\"Processing\"]\n    v[\"Validate\"] --> e[\"Enrich\"]\n  end\n  p@{ view: \"collapsed\" }\n  e --> out[\"Out\"]",
    ),
    "172x270 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 172 270\" width=\"172\" height=\"270\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_in_v_0\"><path d=\"M86,56L86,97\"/><path class=\"pele-marker\" d=\"M86,104L82.64,96L89.36,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_e_out_0\"><path d=\"M86,166L86,207\"/><path class=\"pele-marker\" d=\"M86,214L82.64,206L89.36,206Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-collapsed\" data-id=\"p\" transform=\"translate(86,135)\"><rect x=\"-78\" y=\"-31\" width=\"156\" height=\"62\" fill=\"var(--pele-series-8,#9d755d)\" fill-opacity=\"0.06\" stroke=\"var(--pele-series-8,#9d755d)\" style=\"rx:var(--_r)\"/><path d=\"M-68,15H68\" fill=\"none\" stroke=\"var(--pele-series-8,#9d755d)\" stroke-dasharray=\"3 3\"/><path class=\"pele-collapsed-mark\" d=\"M-10.75,23a1.75,1.75 0 1 0 3.5,0a1.75,1.75 0 1 0 -3.5,0ZM-1.75,23a1.75,1.75 0 1 0 3.5,0a1.75,1.75 0 1 0 -3.5,0ZM7.25,23a1.75,1.75 0 1 0 3.5,0a1.75,1.75 0 1 0 -3.5,0Z\" fill=\"var(--pele-series-8,#9d755d)\" stroke=\"none\"/><text class=\"pele-label\" x=\"0\" y=\"-1.4\" text-anchor=\"middle\">Processing</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"in\" transform=\"translate(86,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">In</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"out\" transform=\"translate(86,238)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Out</text></g></g></svg>",
  )
}

///|
test "numbers containers in the order they were written" {
  assert_eq(
    snapshot(
      "agentflow-beta TB\n  flow one\n    flow two\n      a\n    end\n  end\n  flow three\n    b\n  end\n  three@{ view: collapsed }",
    ),
    "448x144 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 448 144\" width=\"448\" height=\"144\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-clusters\"><g class=\"pele-cluster pele-flow\" data-id=\"one\"><rect x=\"204\" y=\"8\" width=\"236\" height=\"128\" fill=\"var(--pele-series-8,#9d755d)\" fill-opacity=\"0.06\" stroke=\"var(--pele-series-8,#9d755d)\" style=\"rx:var(--_r)\"/></g><g class=\"pele-cluster pele-flow\" data-id=\"two\"><rect x=\"224\" y=\"28\" width=\"196\" height=\"88\" fill=\"var(--pele-series-8,#9d755d)\" fill-opacity=\"0.06\" stroke=\"var(--pele-series-8,#9d755d)\" style=\"rx:var(--_r)\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-collapsed\" data-id=\"three\" transform=\"translate(86,72)\"><rect x=\"-78\" y=\"-19\" width=\"156\" height=\"38\" fill=\"var(--pele-series-8,#9d755d)\" fill-opacity=\"0.06\" stroke=\"var(--pele-series-8,#9d755d)\" style=\"rx:var(--_r)\"/><path d=\"M-68,3H68\" fill=\"none\" stroke=\"var(--pele-series-8,#9d755d)\" stroke-dasharray=\"3 3\"/><path class=\"pele-collapsed-mark\" d=\"M-10.75,11a1.75,1.75 0 1 0 3.5,0a1.75,1.75 0 1 0 -3.5,0ZM-1.75,11a1.75,1.75 0 1 0 3.5,0a1.75,1.75 0 1 0 -3.5,0ZM7.25,11a1.75,1.75 0 1 0 3.5,0a1.75,1.75 0 1 0 -3.5,0Z\" fill=\"var(--pele-series-8,#9d755d)\" stroke=\"none\"/></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(322,72)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">a</text></g></g></svg>",
  )
}

///|
test "draws a container that two flows fight over once" {
  assert_eq(
    snapshot(
      "agentflow-beta TB\n  flow A[\"Flow A\"]\n    a1 --> B\n  end\n  flow B[\"Flow B\"]\n    b1 --> A\n  end",
    ),
    "252x280 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 252 280\" width=\"252\" height=\"280\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-clusters\"><g class=\"pele-cluster pele-flow\" data-id=\"B\"><rect x=\"8\" y=\"8\" width=\"236\" height=\"264\" fill=\"var(--pele-series-8,#9d755d)\" fill-opacity=\"0.06\" stroke=\"var(--pele-series-8,#9d755d)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"46.45\" y=\"33.6\" text-anchor=\"middle\">Flow B</text></g><g class=\"pele-cluster pele-flow\" data-id=\"A\"><rect x=\"28\" y=\"144\" width=\"196\" height=\"108\" fill=\"var(--pele-series-8,#9d755d)\" fill-opacity=\"0.06\" stroke=\"var(--pele-series-8,#9d755d)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"66.45\" y=\"169.6\" text-anchor=\"middle\">Flow A</text></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_b1_A_0\"><path d=\"M126,96L126,137\"/><path class=\"pele-marker\" d=\"M126,144L122.64,136L129.36,136Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a1_B_0\"><path d=\"M126,232L126,265\"/><path class=\"pele-marker\" d=\"M126,272L122.64,264L129.36,264Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a1\" transform=\"translate(126,208)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">a1</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"b1\" transform=\"translate(126,72)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b1</text></g></g></svg>",
  )
}

///|
test "runs an edge between a node and its own flow to the border of the flow" {
  assert_eq(
    snapshot(
      "agentflow-beta TB\n  flow f[\"My Flow\"]\n    a[\"Task A\"] --> b[\"Task B\"]\n    b --> f\n    f --> a\n  end",
    ),
    "212x220 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 212 220\" width=\"212\" height=\"220\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-clusters\"><g class=\"pele-cluster pele-flow\" data-id=\"f\"><rect x=\"8\" y=\"8\" width=\"196\" height=\"204\" fill=\"var(--pele-series-8,#9d755d)\" fill-opacity=\"0.06\" stroke=\"var(--pele-series-8,#9d755d)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"51.78\" y=\"33.6\" text-anchor=\"middle\">My Flow</text></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\"><path d=\"M106,96L106,137\"/><path class=\"pele-marker\" d=\"M106,144L102.64,136L109.36,136Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_b_f_0\"><path d=\"M106,192L106,205\"/><path class=\"pele-marker\" d=\"M106,212L102.64,204L109.36,204Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_f_a_0\"><path d=\"M106,8L106,41\"/><path class=\"pele-marker\" d=\"M106,48L102.64,40L109.36,40Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(106,72)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Task A</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"b\" transform=\"translate(106,168)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Task B</text></g></g></svg>",
  )
}

///|
test "takes a side when another node blocks the way to the flow's border" {
  assert_eq(
    snapshot(
      "agentflow-beta TB\n  flow f[\"My Flow\"]\n    a[\"Task A\"] --> b[\"Task B\"]\n    a --> f\n  end",
    ),
    "212x220 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 212 220\" width=\"212\" height=\"220\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-clusters\"><g class=\"pele-cluster pele-flow\" data-id=\"f\"><rect x=\"8\" y=\"8\" width=\"196\" height=\"204\" fill=\"var(--pele-series-8,#9d755d)\" fill-opacity=\"0.06\" stroke=\"var(--pele-series-8,#9d755d)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"51.78\" y=\"33.6\" text-anchor=\"middle\">My Flow</text></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\"><path d=\"M106,96L106,137\"/><path class=\"pele-marker\" d=\"M106,144L102.64,136L109.36,136Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_f_0\"><path d=\"M28,72L15,72\"/><path class=\"pele-marker\" d=\"M8,72L16,68.64L16,75.36Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(106,72)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Task A</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"b\" transform=\"translate(106,168)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Task B</text></g></g></svg>",
  )
}

///|
test "draws a front matter title above the diagram" {
  assert_eq(
    snapshot("---\ntitle: Release pipeline\n---\nagentflow-beta TB\n  a --> b"),
    "172x196 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 172 196\" width=\"172\" height=\"196\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"86\" y=\"25.6\">Release pipeline</tspan></text><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\"><path d=\"M86,92L86,133\"/><path class=\"pele-marker\" d=\"M86,140L82.64,132L89.36,132Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(86,68)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">a</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"b\" transform=\"translate(86,164)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b</text></g></g></svg>",
  )
}

///|
test "writes the accessible title and description" {
  assert_eq(
    snapshot(
      "agentflow-beta TB\n  accTitle: Review flow\n  accDescr: How a change is reviewed\n  a --> b",
    ),
    "172x160 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 172 160\" width=\"172\" height=\"160\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\" aria-labelledby=\"pele-title\" aria-describedby=\"pele-desc\"><title id=\"pele-title\">Review flow</title><desc id=\"pele-desc\">How a change is reviewed</desc><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\"><path d=\"M86,56L86,97\"/><path class=\"pele-marker\" d=\"M86,104L82.64,96L89.36,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(86,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">a</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"b\" transform=\"translate(86,128)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b</text></g></g></svg>",
  )
}

///|
test "applies classes, styles and link styles" {
  assert_eq(
    snapshot(
      "agentflow-beta TB\n  classDef hot fill:#fdd,stroke:#c00,color:#900\n  a[\"A\"]:::hot --> b[\"B\"]\n  style b stroke-width:3px\n  linkStyle 0 stroke:#0a0",
    ),
    "172x160 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 172 160\" width=\"172\" height=\"160\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\" style=\"stroke:#0a0;\"><path d=\"M86,56L86,97\"/><path class=\"pele-marker\" d=\"M86,104L82.64,96L89.36,96Z\" fill=\"#0a0\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task hot\" data-id=\"a\" transform=\"translate(86,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" stroke=\"var(--pele-series-2,#f58518)\" style=\"fill:#fdd;stroke:#c00;\"/><text class=\"pele-label\" style=\"fill:#900;\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">A</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"b\" transform=\"translate(86,128)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\" style=\"stroke-width:3px;\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">B</text></g></g></svg>",
  )
}

///|
test "links a clicked node and never writes a callback" {
  assert_eq(
    snapshot(
      "agentflow-beta TB\n  a --> b\n  click a href \"https://example.com/x\" \"Open it\" _blank\n  click b call doIt()",
    ),
    "172x160 [{\"id\":\"a\",\"href\":\"https://example.com/x\",\"internal\":false}]\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 172 160\" width=\"172\" height=\"160\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\"><path d=\"M86,56L86,97\"/><path class=\"pele-marker\" d=\"M86,104L82.64,96L89.36,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task clickable\" data-id=\"a\" transform=\"translate(86,32)\"><a href=\"https://example.com/x\" target=\"_blank\" rel=\"noopener\"><title>Open it</title><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">a</text></a></g><g class=\"pele-node pele-shape-rounded pele-kind-task clickable\" data-id=\"b\" transform=\"translate(86,128)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b</text></g></g></svg>",
  )
}

///|
test "links an internal note by its label" {
  assert_eq(
    snapshot(
      "agentflow-beta TB\n  a[\"My Note\"]:::internal-link --> b[\"javascript:alert(1)\"]:::internal-link",
    ),
    "175x160 [{\"id\":\"a\",\"href\":\"My Note\",\"internal\":true},{\"id\":\"b\",\"href\":\"javascript:alert(1)\",\"internal\":true}]\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 175 160\" width=\"175\" height=\"160\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\"><path d=\"M87.34,56L87.34,97\"/><path class=\"pele-marker\" d=\"M87.34,104L83.98,96L90.7,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task internal-link\" data-id=\"a\" transform=\"translate(87.34,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><a class=\"internal-link\" href=\"My Note\" rel=\"noopener\" data-href=\"My Note\"><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">My Note</text></a></g><g class=\"pele-node pele-shape-rounded pele-kind-task internal-link\" data-id=\"b\" transform=\"translate(87.34,128)\"><rect x=\"-79.34\" y=\"-24\" width=\"158.69\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><a class=\"internal-link\" data-href=\"javascript:alert(1)\"><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">javascript:alert(1)</text></a></g></g></svg>",
  )
}

///|
test "wraps long labels" {
  assert_eq(
    snapshot(
      "agentflow-beta TB\n  a[\"A fairly long label that has to wrap over several lines to fit\"]",
    ),
    "172x145 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 172 145\" width=\"172\" height=\"145\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(86,72.5)\"><rect x=\"-78\" y=\"-64.5\" width=\"156\" height=\"129\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"-36.4\">A fairly long</tspan><tspan x=\"0\" y=\"-15.4\">label that has to</tspan><tspan x=\"0\" y=\"5.6\">wrap over</tspan><tspan x=\"0\" y=\"26.6\">several lines to</tspan><tspan x=\"0\" y=\"47.6\">fit</tspan></text></g></g></svg>",
  )
}

///|
test "honors spacing options" {
  assert_eq(
    snapshot(
      "---\nconfig:\n  agentflow:\n    rankSpacing: 150\n    nodeSpacing: 90\n    wrappingWidth: 60\n---\nagentflow-beta TB\n  a --> b & c",
    ),
    "418x262 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 418 262\" width=\"418\" height=\"262\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\"><path d=\"M209,56C209,124.5 86,124.5 86,193L86,199\"/><path class=\"pele-marker\" d=\"M86,206L82.64,198L89.36,198Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_c_0\"><path d=\"M209,56C209,124.5 332,124.5 332,193L332,199\"/><path class=\"pele-marker\" d=\"M332,206L328.64,198L335.36,198Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(209,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">a</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"b\" transform=\"translate(86,230)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"c\" transform=\"translate(332,230)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">c</text></g></g></svg>",
  )
}

///|
test "gives nodes with short labels a common width, except a decision" {
  assert_eq(
    snapshot(
      "agentflow-beta TB\n  a[\"A\"] --> b[\"Beta\"]@{ shape: tool }\n  b --> d{\"ok?\"}",
    ),
    "188x267 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 188 267\" width=\"188\" height=\"267\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\"><path d=\"M94,56L94,97\"/><path class=\"pele-marker\" d=\"M94,104L90.64,96L97.36,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_b_d_0\"><path d=\"M94,152L94,193\"/><path class=\"pele-marker\" d=\"M94,200L90.64,192L97.36,192Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(94,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">A</text></g><g class=\"pele-node pele-shape-fr-rect pele-kind-tool\" data-id=\"b\" transform=\"translate(94,128)\"><rect x=\"-86\" y=\"-24\" width=\"172\" height=\"48\" fill=\"var(--pele-series-1,#4c78a8)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-1,#4c78a8)\" style=\"rx:var(--_r)\"/><path d=\"M-78,-24V24M78,-24V24\" fill=\"none\" stroke=\"var(--pele-series-1,#4c78a8)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Beta</text></g><g class=\"pele-node pele-shape-diam pele-kind-decision\" data-id=\"d\" transform=\"translate(94,229.06)\"><polygon points=\"0,-29.06 46.5,0 0,29.06 -46.5,0\" fill=\"var(--pele-series-3,#54a24b)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-3,#54a24b)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">ok?</text></g></g></svg>",
  )
}

///|
test "honors the minimum node width" {
  assert_eq(
    snapshot(
      "---\nconfig:\n  agentflow:\n    minNodeWidth: 10\n---\nagentflow-beta TB\n  a[\"A\"] --> b[\"Beta\"]@{ shape: tool }\n  b --> d{\"ok?\"}",
    ),
    "109x267 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 109 267\" width=\"109\" height=\"267\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\"><path d=\"M54.5,56L54.5,97\"/><path class=\"pele-marker\" d=\"M54.5,104L51.14,96L57.86,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_b_d_0\"><path d=\"M54.5,152L54.5,193\"/><path class=\"pele-marker\" d=\"M54.5,200L51.14,192L57.86,192Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(54.5,32)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">A</text></g><g class=\"pele-node pele-shape-fr-rect pele-kind-tool\" data-id=\"b\" transform=\"translate(54.5,128)\"><rect x=\"-42.46\" y=\"-24\" width=\"84.91\" height=\"48\" fill=\"var(--pele-series-1,#4c78a8)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-1,#4c78a8)\" style=\"rx:var(--_r)\"/><path d=\"M-34.46,-24V24M34.46,-24V24\" fill=\"none\" stroke=\"var(--pele-series-1,#4c78a8)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Beta</text></g><g class=\"pele-node pele-shape-diam pele-kind-decision\" data-id=\"d\" transform=\"translate(54.5,229.06)\"><polygon points=\"0,-29.06 46.5,0 0,29.06 -46.5,0\" fill=\"var(--pele-series-3,#54a24b)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-3,#54a24b)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">ok?</text></g></g></svg>",
  )
}

///|
test "draws edges with markdown labels and curves" {
  assert_eq(
    snapshot(
      "---\nconfig:\n  flowchart:\n    curve: linear\n---\nagentflow-beta LR\n  a -- \"`**bold** move`\" --> b\n  b e1@--> c\n  e1@{ curve: step }",
    ),
    "660x64 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 660 64\" width=\"660\" height=\"64\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_w:var(--pele-bold-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\"><path d=\"M164,32L284.68,32\"/><path class=\"pele-marker\" d=\"M291.68,32L283.68,35.36L283.68,28.64Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge pele-edge-sequence\" data-id=\"e1\"><path d=\"M447.68,32L488.68,32\"/><path class=\"pele-marker\" d=\"M495.68,32L487.68,35.36L487.68,28.64Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\"><g class=\"pele-edge-label\" data-id=\"L_a_b_0\"><rect x=\"190\" y=\"21.5\" width=\"75.68\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"227.84\" y=\"36.9\" font-weight=\"var(--_w)\">bold</tspan><tspan> move</tspan></text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(86,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">a</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"b\" transform=\"translate(369.68,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"c\" transform=\"translate(573.68,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">c</text></g></g></svg>",
  )
}

///|
test "lays out along the declared direction upward" {
  assert_eq(
    snapshot("agentflow-beta BT\n  a --> b"),
    "172x160 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 172 160\" width=\"172\" height=\"160\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\"><path d=\"M86,104L86,63\"/><path class=\"pele-marker\" d=\"M86,56L89.36,64L82.64,64Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(86,128)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">a</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"b\" transform=\"translate(86,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b</text></g></g></svg>",
  )
}

///|
test "lays out along the declared direction backward" {
  assert_eq(
    snapshot("agentflow-beta RL\n  a --> b"),
    "376x64 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 376 64\" width=\"376\" height=\"64\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\"><path d=\"M212,32L171,32\"/><path class=\"pele-marker\" d=\"M164,32L172,28.64L172,35.36Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(290,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">a</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"b\" transform=\"translate(86,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b</text></g></g></svg>",
  )
}

///|
test "turns a diagram that runs across to fit a narrow host" {
  assert_eq(
    snapshot(
      "agentflow-beta LR\n  a[\"Alpha step\"] --> b[\"Beta step\"] --> c[\"Gamma step\"] --> d[\"Delta step\"]",
      max_width=400,
    ),
    "172x352 []\n<svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-agentflow\" viewBox=\"0 0 172 352\" width=\"172\" height=\"352\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"agentflow\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_a_b_0\"><path d=\"M86,56L86,97\"/><path class=\"pele-marker\" d=\"M86,104L82.64,96L89.36,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_b_c_0\"><path d=\"M86,152L86,193\"/><path class=\"pele-marker\" d=\"M86,200L82.64,192L89.36,192Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge pele-edge-sequence\" data-id=\"L_c_d_0\"><path d=\"M86,248L86,289\"/><path class=\"pele-marker\" d=\"M86,296L82.64,288L89.36,288Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"a\" transform=\"translate(86,32)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Alpha step</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"b\" transform=\"translate(86,128)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Beta step</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"c\" transform=\"translate(86,224)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Gamma step</text></g><g class=\"pele-node pele-shape-rounded pele-kind-task\" data-id=\"d\" transform=\"translate(86,320)\"><rect x=\"-78\" y=\"-24\" width=\"156\" height=\"48\" rx=\"12\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.14\" stroke=\"var(--pele-series-2,#f58518)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Delta step</text></g></g></svg>",
  )
}

///|
test "an error after a brace with trailing blanks is placed in the source as written" {
  let failure = try {
    @core.render(
      [@agentflow.agentflow],
      "---\ntitle: T\n---\nagentflow-beta TB\n  a@{ shape: rounded }  \n  b -.-> c",
      @types.RenderOptions::default(),
    )
    |> ignore
    None
  } catch {
    @errors.PeleError(failure) => Some(failure)
  }
  guard failure is Some(failure) else { fail("accepted") }
  inspect("\{failure.line}:\{failure.column}", content="6:8")
}

///|
test "a metadata error after a directive is placed in the source as written" {
  let metadata = "%%{init:\n{}\n}%%\nagentflow-beta\na[\"#35;\"] --> b@{shape: "
  let shown = []
  for tail in ["bad}", "[bad}"] {
    let failure = try {
      @core.render(
        [@agentflow.agentflow],
        metadata + tail,
        @types.RenderOptions::default(),
      )
      |> ignore
      None
    } catch {
      @errors.PeleError(failure) => Some(failure)
    }
    guard failure is Some(failure) else { fail("accepted") }
    shown.push(
      "\{failure.code.to_string()} \{failure.line}:\{failure.column} \{failure.message}",
    )
  }
  inspect(
    shown.join("\n"),
    content=(
      #|semantic 5:16 No such shape: bad.
      #|syntax 5:16 Metadata of "b" is not valid YAML. YAML: unexpected end of the stream within a flow collection (5:16)
    ),
  )
}

///|
test "picks a contrasting label color on fills a style sets" {
  let svg = snapshot(
    "agentflow-beta TB\n  flow f[\"Flow\"]\n    a[\"A\"] --> b[\"B\"]\n  end\n  flow p[\"Packed\"]\n    c[\"C\"]\n  end\n  p@{ view: \"collapsed\" }\n  b --> d[\"D\"]\n  style f fill:#FFF9C4\n  style a fill:#1f3a5f\n  style b fill:#1f3a5f,color:#eee\n  style p fill:navy",
  )
  let text_of = (id : String) => {
    let at = @util.index_of(
      svg,
      "<text ",
      from=@util.index_of(svg, "data-id=\"\{id}\""),
    )
    @util.slice(svg, at, end=@util.index_of(svg, ">", from=at) + 1)
  }
  inspect(
    ["f", "a", "b", "p", "d"].map(text_of).join("\n"),
    content=(
      #|<text class="pele-cluster-label" fill="var(--pele-fg-on-light,#1f1f1f)" x="234.89" y="33.6" text-anchor="middle">
      #|<text class="pele-label" fill="var(--pele-fg-on-dark,#fff)" x="0" y="5.6" text-anchor="middle">
      #|<text class="pele-label" style="fill:#eee;" x="0" y="5.6" text-anchor="middle">
      #|<text class="pele-label" fill="var(--pele-fg-on-dark,#fff)" x="0" y="-1.4" text-anchor="middle">
      #|<text class="pele-label" x="0" y="5.6" text-anchor="middle">
    ),
  )
}

///|
/// The `d` of every edge's line, in order.
fn edge_paths(svg : String) -> Array[String] {
  let paths = []
  let head = "<g class=\"pele-edge "
  let mut at = @util.index_of(svg, head)
  while at != -1 {
    let open = @util.index_of(svg, "<path d=\"", from=at) + 9
    paths.push(@util.slice(svg, open, end=@util.index_of(svg, "\"", from=open)))
    at = @util.index_of(svg, head, from=open)
  }
  paths
}

///|
/// What the group of casings in a drawing holds, or an empty string when it has none.
fn casings_of(svg : String) -> String {
  let open = @util.index_of(svg, "<g class=\"pele-casings\"")
  if open == -1 {
    return ""
  }
  let start = @util.index_of(svg, ">", from=open) + 1
  @util.slice(
    svg,
    start,
    end=@util.index_of(svg, "</g><g class=\"pele-edges\"", from=start),
  )
}

///|
test "cases edges that cross a flow fill a style sets and inks those inside it" {
  let source = "agentflow-beta TB\n  flow f[\"Flow\"]\n    a[\"A\"] --> b[\"B\"]\n  end\n  b --> c[\"C\"]\n  c --> d[\"D\"]\n  style f fill:#FFF9C4"
  let svg = snapshot(source)
  let casings = casings_of(svg)
  let paths = edge_paths(svg)
  inspect(paths.length(), content="3")
  inspect(
    paths.map(d => casings.contains("<path d=\"\{d}\"/>").to_string()).join(" "),
    content="false true false",
  )
  inspect(
    edge_heads(svg),
    content=(
      #|<g class="pele-edge pele-edge-sequence" data-id="L_a_b_0" stroke="var(--pele-fg-on-light,#1f1f1f)">
      #|<g class="pele-edge pele-edge-sequence" data-id="L_b_c_0">
      #|<g class="pele-edge pele-edge-sequence" data-id="L_c_d_0">
    ),
  )
  let plain = snapshot(source.replace(old="\n  style f fill:#FFF9C4", new=""))
  inspect(plain.contains("pele-casings"), content="false")
  inspect(plain.contains("stroke=\"var(--pele-fg-on"), content="false")
  // An edge from a flow to a node inside it starts on the flow's border and stays on its fill.
  let held = snapshot(
    "agentflow-beta TB\n  flow f[Flow]\n    a[A]\n  end\n  f --> a\n  style f fill:white",
  )
  inspect(
    edge_heads(held),
    content=(
      #|<g class="pele-edge pele-edge-sequence" data-id="L_f_a_0" stroke="var(--pele-fg-on-light,#1f1f1f)">
    ),
  )
  inspect(held.contains("pele-casings"), content="false")
}

///|
/// The opening tag of every edge's group, one to a line.
fn edge_heads(svg : String) -> String {
  let heads = []
  let head = "<g class=\"pele-edge "
  let mut at = @util.index_of(svg, head)
  while at != -1 {
    heads.push(@util.slice(svg, at, end=@util.index_of(svg, ">", from=at) + 1))
    at = @util.index_of(svg, head, from=at + 1)
  }
  heads.join("\n")
}
