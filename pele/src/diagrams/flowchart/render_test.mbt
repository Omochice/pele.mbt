///|
fn svg(
  source : String,
  max_width? : Double,
  icons? : @types.IconResolver,
) -> String {
  let options = { ..@types.RenderOptions::default(), max_width, icons, }
  let result = @core.render([@flowchart.flowchart], source, options) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "\{result.width}x\{result.height} \{result.svg}"
}

///|
fn linked_svg(source : String) -> String {
  let result = @core.render(
    [@flowchart.flowchart],
    source,
    @types.RenderOptions::default(),
  ) catch {
    @errors.PeleError(failure) => return failure.message
  }
  let links = result.links.map(link => {
    "\{link.id}|\{link.href}|\{link.internal}"
  })
  "\{result.width}x\{result.height} \{result.svg} \{links.join(" ")}"
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

///|
test "draws subgraphs as clusters behind their members" {
  inspect(
    svg(
      "flowchart TD\n  subgraph one [First group]\n    A --> B\n  end\n  B --> C",
    ),
    content="121x336 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-flowchart\" viewBox=\"0 0 121 336\" width=\"121\" height=\"336\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"flowchart\"><g class=\"pele-clusters\"><g class=\"pele-cluster\" data-id=\"one\"><rect x=\"8\" y=\"8\" width=\"104.46\" height=\"224\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"60.23\" y=\"33.6\" text-anchor=\"middle\">First group</text></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_A_B_0\"><path d=\"M60.23,96L60.23,137\"/><path class=\"pele-marker\" d=\"M60.23,144L56.87,136L63.59,136Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_B_C_0\"><path d=\"M60.23,192L60.23,273\"/><path class=\"pele-marker\" d=\"M60.23,280L56.87,272L63.59,272Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect\" data-id=\"A\" transform=\"translate(60.23,72)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">A</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"B\" transform=\"translate(60.23,168)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">B</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"C\" transform=\"translate(60.23,304)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">C</text></g></g></svg>",
  )
}

///|
test "lays a subgraph out in its own direction" {
  inspect(
    svg(
      "flowchart LR\n  subgraph outer\n    direction TB\n    subgraph inner [<b>Inner</b>]\n      A --> B\n    end\n  end\n  C --> inner\n  classDef hot fill:#f00\n  class outer hot",
    ),
    content="240x280 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-flowchart\" viewBox=\"0 0 240 280\" width=\"240\" height=\"280\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_w:var(--pele-bold-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"flowchart\"><g class=\"pele-clusters\"><g class=\"pele-cluster hot\" data-id=\"outer\"><rect x=\"104\" y=\"8\" width=\"128\" height=\"264\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r);fill:#f00;\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"136.23\" y=\"33.6\" text-anchor=\"middle\">outer</text></g><g class=\"pele-cluster\" data-id=\"inner\"><rect x=\"124\" y=\"48\" width=\"88\" height=\"204\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" font-weight=\"var(--_w)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"157.56\" y=\"73.6\">Inner</tspan></text></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_A_B_0\"><path d=\"M168,136L168,177\"/><path class=\"pele-marker\" d=\"M168,184L164.64,176L171.36,176Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_C_inner_0\"><path d=\"M56,150L117,150\"/><path class=\"pele-marker\" d=\"M124,150L116,153.36L116,146.64Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect\" data-id=\"A\" transform=\"translate(168,112)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">A</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"B\" transform=\"translate(168,208)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">B</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"C\" transform=\"translate(32,150)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">C</text></g></g></svg>",
  )
}

///|
test "draws cluster titles that edges run through over the edges" {
  inspect(
    svg(
      "flowchart TB\n    c1-->a2\n    subgraph one\n    a1-->a2\n    end\n    subgraph two\n    b1-->b2\n    end\n    subgraph three\n    c1-->c2\n    end\n    one --> two\n    three --> two\n    two --> c2",
    ),
    content="229x764 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-flowchart\" viewBox=\"0 0 229 764\" width=\"229\" height=\"764\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"flowchart\"><g class=\"pele-clusters\"><g class=\"pele-cluster\" data-id=\"three\"><rect x=\"99.34\" y=\"8\" width=\"120.9\" height=\"224\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"131.58\" y=\"33.6\" text-anchor=\"middle\">three</text></g><g class=\"pele-cluster\" data-id=\"two\"><rect x=\"100.38\" y=\"552\" width=\"93.79\" height=\"204\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/></g><g class=\"pele-cluster\" data-id=\"one\"><rect x=\"8\" y=\"280\" width=\"121.79\" height=\"224\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"68.9\" y=\"305.6\" text-anchor=\"middle\">one</text></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_c1_a2_0\"><path d=\"M138.57,96C138.57,120 119.34,120 119.34,144L119.34,232C119.34,256 28,256 28,280L28,388C28,405.5 47.45,405.5 47.45,423L47.45,429\"/><path class=\"pele-marker\" d=\"M47.45,436L44.09,428L50.81,428Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_a1_a2_0\"><path d=\"M82.9,388C82.9,405.5 63.45,405.5 63.45,423L63.45,429\"/><path class=\"pele-marker\" d=\"M63.45,436L60.09,428L66.81,428Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_b1_b2_0\"><path d=\"M147.27,640L147.27,681\"/><path class=\"pele-marker\" d=\"M147.27,688L143.91,680L150.63,680Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_c1_c2_0\"><path d=\"M154.57,96C154.57,113.5 173.79,113.5 173.79,131L173.79,137\"/><path class=\"pele-marker\" d=\"M173.79,144L170.43,136L177.15,136Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_one_two_0\"><path d=\"M68.9,504C68.9,521.5 141.79,521.5 141.79,539L141.79,545\"/><path class=\"pele-marker\" d=\"M141.79,552L138.43,544L145.15,544Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_three_two_0\"><path d=\"M157.79,232L157.79,545\"/><path class=\"pele-marker\" d=\"M157.79,552L154.43,544L161.15,544Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_two_c2_0\"><path d=\"M173.79,552L173.79,199\"/><path class=\"pele-marker\" d=\"M173.79,192L177.15,200L170.43,200Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-cluster-titles\"><g class=\"pele-cluster-title\" data-id=\"two\"><text fill=\"none\" stroke=\"color-mix(in srgb,var(--_a) 50%,var(--_bg))\" stroke-width=\"5\" stroke-linejoin=\"round\" x=\"126.83\" y=\"577.6\" text-anchor=\"middle\">two</text><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"126.83\" y=\"577.6\" text-anchor=\"middle\">two</text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect\" data-id=\"c1\" transform=\"translate(146.57,72)\"><rect x=\"-26.45\" y=\"-24\" width=\"52.9\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">c1</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"a2\" transform=\"translate(55.45,460)\"><rect x=\"-26.9\" y=\"-24\" width=\"53.79\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">a2</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"a1\" transform=\"translate(82.9,364)\"><rect x=\"-26.9\" y=\"-24\" width=\"53.79\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">a1</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"b1\" transform=\"translate(147.27,616)\"><rect x=\"-26.9\" y=\"-24\" width=\"53.79\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b1</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"b2\" transform=\"translate(147.27,712)\"><rect x=\"-26.9\" y=\"-24\" width=\"53.79\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b2</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"c2\" transform=\"translate(173.79,168)\"><rect x=\"-26.45\" y=\"-24\" width=\"52.9\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">c2</text></g></g></svg>",
  )
}

///|
test "tightens the padding of clusters on a narrow host" {
  inspect(
    svg(
      "flowchart TB\n    c1-->a2\n    subgraph one\n    a1-->a2\n    end\n    subgraph two\n    b1-->b2\n    end\n    subgraph three\n    c1-->c2\n    end\n    one --> two\n    three --> two\n    two --> c2\n  subgraph four [A wide group with a long title]\n  x1 --> x2 & x3 & x4\n  end",
      max_width=400,
    ),
    content="393x712 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-flowchart\" viewBox=\"0 0 393 712\" width=\"393\" height=\"712\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"flowchart\"><g class=\"pele-clusters\"><g class=\"pele-cluster\" data-id=\"four\"><rect x=\"161.57\" y=\"28\" width=\"222.69\" height=\"184\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"269.4\" y=\"53.6\" text-anchor=\"middle\">A wide group with a long title</text></g><g class=\"pele-cluster\" data-id=\"three\"><rect x=\"42.45\" y=\"8\" width=\"99.12\" height=\"204\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"66.68\" y=\"33.6\" text-anchor=\"middle\">three</text></g><g class=\"pele-cluster\" data-id=\"two\"><rect x=\"61.28\" y=\"520\" width=\"77.79\" height=\"184\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/></g><g class=\"pele-cluster\" data-id=\"one\"><rect x=\"8\" y=\"280\" width=\"100.24\" height=\"204\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"58.12\" y=\"305.6\" text-anchor=\"middle\">one</text></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_c1_a2_0\"><path d=\"M72.9,96C72.9,114 58.68,114 58.68,132L58.68,212C58.68,246 24.45,246 24.45,280L24.45,388C24.45,399.5 38.9,399.5 38.9,411L38.9,417\"/><path class=\"pele-marker\" d=\"M38.9,424L35.54,416L42.26,416Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_a1_a2_0\"><path d=\"M69.34,388C69.34,399.5 54.9,399.5 54.9,411L54.9,417\"/><path class=\"pele-marker\" d=\"M54.9,424L51.54,416L58.26,416Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_b1_b2_0\"><path d=\"M100.18,608L100.18,637\"/><path class=\"pele-marker\" d=\"M100.18,644L96.82,636L103.54,636Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_c1_c2_0\"><path d=\"M88.9,96C88.9,107.5 103.12,107.5 103.12,119L103.12,125\"/><path class=\"pele-marker\" d=\"M103.12,132L99.76,124L106.48,124Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_one_two_0\"><path d=\"M58.12,484C58.12,495.5 92.87,495.5 92.87,507L92.87,513\"/><path class=\"pele-marker\" d=\"M92.87,520L89.51,512L96.23,512Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_three_two_0\"><path d=\"M87.12,212L87.12,240C87.12,260 126.24,260 126.24,280L126.24,484C126.24,495.5 108.87,495.5 108.87,507L108.87,513\"/><path class=\"pele-marker\" d=\"M108.87,520L105.51,512L112.23,512Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_two_c2_0\"><path d=\"M124.87,520L124.87,507C124.87,495.5 142.24,495.5 142.24,484L142.24,280C142.24,246 103.12,246 103.12,212L103.12,187\"/><path class=\"pele-marker\" d=\"M103.12,180L106.48,188L99.76,188Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_x1_x2_0\"><path d=\"M258.47,116C258.47,127.5 200.02,127.5 200.02,139L200.02,145\"/><path class=\"pele-marker\" d=\"M200.02,152L196.66,144L203.38,144Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_x1_x3_0\"><path d=\"M272.92,116L272.92,145\"/><path class=\"pele-marker\" d=\"M272.92,152L269.56,144L276.28,144Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_x1_x4_0\"><path d=\"M287.36,116C287.36,127.5 345.81,127.5 345.81,139L345.81,145\"/><path class=\"pele-marker\" d=\"M345.81,152L342.45,144L349.17,144Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-cluster-titles\"><g class=\"pele-cluster-title\" data-id=\"two\"><text fill=\"none\" stroke=\"color-mix(in srgb,var(--_a) 50%,var(--_bg))\" stroke-width=\"5\" stroke-linejoin=\"round\" x=\"79.73\" y=\"545.6\" text-anchor=\"middle\">two</text><text class=\"pele-cluster-label\" fill=\"var(--_m)\" x=\"79.73\" y=\"545.6\" text-anchor=\"middle\">two</text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect\" data-id=\"c1\" transform=\"translate(80.9,72)\"><rect x=\"-26.45\" y=\"-24\" width=\"52.9\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">c1</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"a2\" transform=\"translate(46.9,448)\"><rect x=\"-26.9\" y=\"-24\" width=\"53.79\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">a2</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"a1\" transform=\"translate(69.34,364)\"><rect x=\"-26.9\" y=\"-24\" width=\"53.79\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">a1</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"b1\" transform=\"translate(100.18,584)\"><rect x=\"-26.9\" y=\"-24\" width=\"53.79\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b1</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"b2\" transform=\"translate(100.18,668)\"><rect x=\"-26.9\" y=\"-24\" width=\"53.79\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b2</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"c2\" transform=\"translate(103.12,156)\"><rect x=\"-26.45\" y=\"-24\" width=\"52.9\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">c2</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"x1\" transform=\"translate(272.92,92)\"><rect x=\"-26.45\" y=\"-24\" width=\"52.9\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">x1</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"x2\" transform=\"translate(200.02,176)\"><rect x=\"-26.45\" y=\"-24\" width=\"52.9\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">x2</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"x3\" transform=\"translate(272.92,176)\"><rect x=\"-26.45\" y=\"-24\" width=\"52.9\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">x3</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"x4\" transform=\"translate(345.81,176)\"><rect x=\"-26.45\" y=\"-24\" width=\"52.9\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">x4</text></g></g></svg>",
  )
}

///|
test "draws self-loops beside their node, across the flow" {
  inspect(
    svg("flowchart TD\n  A[Retry] --> A\n  A -->|again| A\n  A --> B"),
    content="287x160 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-flowchart\" viewBox=\"0 0 287 160\" width=\"287\" height=\"160\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"flowchart\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_A_A_0\"><path d=\"M180.47,24C206.47,16 206.47,48 187.16,42.06\"/><path class=\"pele-marker\" d=\"M180.47,40L189.1,39.14L187.13,45.56Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_A_A_2\"><path d=\"M180.47,18C214.47,4 214.47,60 186.94,48.67\"/><path class=\"pele-marker\" d=\"M180.47,46L189.14,45.94L186.59,52.15Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_A_B_0\"><path d=\"M143.36,56L143.36,97\"/><path class=\"pele-marker\" d=\"M143.36,104L140,96L146.72,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\"><g class=\"pele-edge-label\" data-id=\"L_A_A_2\"><rect x=\"220.47\" y=\"21.5\" width=\"42.24\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"241.59\" y=\"36.9\" text-anchor=\"middle\">again</text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect\" data-id=\"A\" transform=\"translate(143.36,32)\"><rect x=\"-37.11\" y=\"-24\" width=\"74.22\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Retry</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"B\" transform=\"translate(143.36,128)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">B</text></g></g></svg>",
  )
}

///|
test "grows a node's box to hold its self-loops in a flow that runs across" {
  inspect(
    svg("flowchart LR\n  A -->|loop| A\n  B -.-> B\n  A --> B"),
    content="160x174 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-flowchart\" viewBox=\"0 0 160 174\" width=\"160\" height=\"174\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"flowchart\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_A_A_0\"><path d=\"M24,111C16,137 48,137 42.06,117.69\"/><path class=\"pele-marker\" d=\"M40,111L45.56,117.66L39.14,119.63Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_B_B_0\"><path d=\"M120,111C112,137 144,137 138.06,117.69\" stroke-dasharray=\"3 4\"/><path class=\"pele-marker\" d=\"M136,111L141.56,117.66L135.14,119.63Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_A_B_0\"><path d=\"M56,87L97,87\"/><path class=\"pele-marker\" d=\"M104,87L96,90.36L96,83.64Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\"><g class=\"pele-edge-label\" data-id=\"L_A_A_0\"><rect x=\"14.77\" y=\"143\" width=\"34.46\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"32\" y=\"158.4\" text-anchor=\"middle\">loop</text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect\" data-id=\"A\" transform=\"translate(32,87)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">A</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"B\" transform=\"translate(128,87)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">B</text></g></g></svg>",
  )
}

///|
test "links nodes and neutralizes script URLs" {
  inspect(
    linked_svg(
      "flowchart TD\n  A --> B --> C\n  click A \"https://example.com\" \"A tooltip\" _blank\n  click B \"javascript:alert(1)\"\n  click C call doSomething()",
    ),
    content="64x256 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-flowchart\" viewBox=\"0 0 64 256\" width=\"64\" height=\"256\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"flowchart\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_A_B_0\"><path d=\"M32,56L32,97\"/><path class=\"pele-marker\" d=\"M32,104L28.64,96L35.36,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_B_C_0\"><path d=\"M32,152L32,193\"/><path class=\"pele-marker\" d=\"M32,200L28.64,192L35.36,192Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect clickable\" data-id=\"A\" transform=\"translate(32,32)\"><a href=\"https://example.com/\" target=\"_blank\" rel=\"noopener\"><title>A tooltip</title><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">A</text></a></g><g class=\"pele-node pele-shape-rect clickable\" data-id=\"B\" transform=\"translate(32,128)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">B</text></g><g class=\"pele-node pele-shape-rect clickable\" data-id=\"C\" transform=\"translate(32,224)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">C</text></g></g></svg> A|https://example.com/|false",
  )
}

///|
test "turns internal-link nodes into Obsidian links" {
  inspect(
    linked_svg("flowchart TD\n  A[My note] --> B\n  class A internal-link;"),
    content="109x160 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-flowchart\" viewBox=\"0 0 109 160\" width=\"109\" height=\"160\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"flowchart\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_A_B_0\"><path d=\"M54.46,56L54.46,97\"/><path class=\"pele-marker\" d=\"M54.46,104L51.1,96L57.82,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect internal-link\" data-id=\"A\" transform=\"translate(54.46,32)\"><rect x=\"-46.46\" y=\"-24\" width=\"92.91\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><a class=\"internal-link\" href=\"My note\" rel=\"noopener\" data-href=\"My note\"><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">My note</text></a></g><g class=\"pele-node pele-shape-rect\" data-id=\"B\" transform=\"translate(54.46,128)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">B</text></g></g></svg> A|My note|true",
  )
}

///|
test "keeps the href of an internal link that is not a safe URL out" {
  inspect(
    linked_svg(
      "flowchart TD\n  A[\"javascript:alert(1)\"] --> B[\"#lt;b#gt; x\"]\n  class A,B internal-link",
    ),
    content="175x160 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-flowchart\" viewBox=\"0 0 175 160\" width=\"175\" height=\"160\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"flowchart\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_A_B_0\"><path d=\"M87.34,56L87.34,97\"/><path class=\"pele-marker\" d=\"M87.34,104L83.98,96L90.7,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect internal-link\" data-id=\"A\" transform=\"translate(87.34,32)\"><rect x=\"-79.34\" y=\"-24\" width=\"158.69\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><a class=\"internal-link\" data-href=\"javascript:alert(1)\"><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">javascript:alert(1)</text></a></g><g class=\"pele-node pele-shape-rect internal-link\" data-id=\"B\" transform=\"translate(87.34,128)\"><rect x=\"-38.02\" y=\"-24\" width=\"76.03\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><a class=\"internal-link\" href=\"&lt;b&gt; x\" rel=\"noopener\" data-href=\"&lt;b&gt; x\"><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">&lt;b&gt; x</text></a></g></g></svg> A|javascript:alert(1)|true B|<b> x|true",
  )
}

///|
test "draws picture nodes at their asset size with the label below" {
  inspect(
    svg(
      "flowchart TD\n  A@{ img: \"https://example.com/a.png\", label: \"Picture\", pos: \"b\", w: 60, h: 40, constraint: \"on\" } --> B@{ img: \"https://example.com/b.png\" }\n  C@{ img: \"javascript:alert(1)\", label: \"Top\", pos: \"t\" }",
    ),
    content="206x254 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-flowchart\" viewBox=\"0 0 206 254\" width=\"206\" height=\"254\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"flowchart\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_A_B_0\"><path d=\"M48,98L48,159\"/><path class=\"pele-marker\" d=\"M48,166L44.64,158L51.36,158Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-imageSquare\" data-id=\"A\" transform=\"translate(48,63)\"><image href=\"https://example.com/a.png\" x=\"-30\" y=\"-35\" width=\"60\" height=\"40\" preserveAspectRatio=\"xMidYMid meet\"/><text class=\"pele-label\" x=\"0\" y=\"25.6\" text-anchor=\"middle\">Picture</text></g><g class=\"pele-node pele-shape-imageSquare\" data-id=\"B\" transform=\"translate(48,206)\"><image href=\"https://example.com/b.png\" x=\"-40\" y=\"-40\" width=\"80\" height=\"80\" preserveAspectRatio=\"none\"/></g><g class=\"pele-node pele-shape-imageSquare\" data-id=\"C\" transform=\"translate(158,63)\"><text class=\"pele-label\" x=\"0\" y=\"-34.4\" text-anchor=\"middle\">Top</text></g></g></svg>",
  )
}

///|
test "draws icon nodes in their frames" {
  inspect(
    svg(
      "flowchart LR\n  A@{ icon: \"fa:user\", form: \"circle\", label: \"User\" } --> B@{ icon: \"fa:gear\", form: \"rounded\", label: \"Gear\", pos: \"t\", h: 64 }\n  B --> C@{ icon: \"fa:box\", form: \"square\" }\n  C --> D@{ icon: \"fa:x\" }",
    ),
    content="352x110 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-flowchart\" viewBox=\"0 0 352 110\" width=\"352\" height=\"110\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"flowchart\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_A_B_0\"><path d=\"M56,55L97,55\"/><path class=\"pele-marker\" d=\"M104,55L96,58.36L96,51.64Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_B_C_0\"><path d=\"M152,55L193,55\"/><path class=\"pele-marker\" d=\"M200,55L192,58.36L192,51.64Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_C_D_0\"><path d=\"M248,55L289,55\"/><path class=\"pele-marker\" d=\"M296,55L288,58.36L288,51.64Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-iconCircle\" data-id=\"A\" transform=\"translate(32,55)\"><circle cy=\"-15\" r=\"24\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><svg class=\"pele-icon\" data-icon=\"fa:user\" x=\"-14.4\" y=\"-29.4\" width=\"28.8\" height=\"28.8\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"></svg><text class=\"pele-label\" x=\"0\" y=\"29.6\" text-anchor=\"middle\">User</text></g><g class=\"pele-node pele-shape-iconRounded\" data-id=\"B\" transform=\"translate(128,55)\"><rect x=\"-32\" y=\"-17\" width=\"64\" height=\"64\" rx=\"8\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><svg class=\"pele-icon\" data-icon=\"fa:gear\" x=\"-19.2\" y=\"-4.2\" width=\"38.4\" height=\"38.4\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"></svg><text class=\"pele-label\" x=\"0\" y=\"-26.4\" text-anchor=\"middle\">Gear</text></g><g class=\"pele-node pele-shape-iconSquare\" data-id=\"C\" transform=\"translate(224,55)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" rx=\"0\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><svg class=\"pele-icon\" data-icon=\"fa:box\" x=\"-14.4\" y=\"-14.4\" width=\"28.8\" height=\"28.8\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"></svg></g><g class=\"pele-node pele-shape-icon\" data-id=\"D\" transform=\"translate(320,55)\"><svg class=\"pele-icon\" data-icon=\"fa:x\" x=\"-14.4\" y=\"-14.4\" width=\"28.8\" height=\"28.8\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"></svg></g></g></svg>",
  )
}

///|
test "applies style, classDef and linkStyle" {
  inspect(
    svg(
      "flowchart TD\n  A --> B\n  style A fill:#f9f,stroke:#333,stroke-width:4px,color:#fff\n  classDef warn fill:#ff0\n  class B warn\n  linkStyle 0 stroke:#f00,stroke-width:3px",
    ),
    content="64x160 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-flowchart\" viewBox=\"0 0 64 160\" width=\"64\" height=\"160\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"flowchart\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_A_B_0\" style=\"stroke:#f00;stroke-width:3px;\"><path d=\"M32,56L32,97\"/><path class=\"pele-marker\" d=\"M32,104L28.64,96L35.36,96Z\" fill=\"#f00\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect\" data-id=\"A\" transform=\"translate(32,32)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r);fill:#f9f;stroke:#333;stroke-width:4px;\"/><text class=\"pele-label\" style=\"fill:#fff;\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">A</text></g><g class=\"pele-node pele-shape-rect warn\" data-id=\"B\" transform=\"translate(32,128)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r);fill:#ff0;\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">B</text></g></g></svg>",
  )
}

///|
test "writes the title and the accessible title and description" {
  inspect(
    svg(
      "---\ntitle: Front title\n---\nflowchart TD\n  accTitle: A title\n  accDescr: A description\n  A --> B",
    ),
    content="90x196 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-flowchart\" viewBox=\"0 0 90 196\" width=\"90\" height=\"196\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"flowchart\" aria-labelledby=\"pele-title\" aria-describedby=\"pele-desc\"><title id=\"pele-title\">A title</title><desc id=\"pele-desc\">A description</desc><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"45\" y=\"25.6\">Front title</tspan></text><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_A_B_0\"><path d=\"M44.89,92L44.89,133\"/><path class=\"pele-marker\" d=\"M44.89,140L41.53,132L48.25,132Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect\" data-id=\"A\" transform=\"translate(44.89,68)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">A</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"B\" transform=\"translate(44.89,164)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">B</text></g></g></svg>",
  )
}

///|
test "keeps invisible links out of the drawing but in the layout" {
  inspect(
    svg("flowchart LR\n  A ~~~ B\n  B == thick ==> C -. dotted .-> D"),
    content="444x64 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-flowchart\" viewBox=\"0 0 444 64\" width=\"444\" height=\"64\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"flowchart\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_B_C_0\"><path d=\"M152,32L233.78,32\" stroke-width=\"2.5\"/><path class=\"pele-marker\" d=\"M240.78,32L232.78,35.36L232.78,28.64Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_C_D_0\"><path d=\"M288.78,32L380.7,32\" stroke-dasharray=\"3 4\"/><path class=\"pele-marker\" d=\"M387.7,32L379.7,35.36L379.7,28.64Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\"><g class=\"pele-edge-label\" data-id=\"L_B_C_0\"><rect x=\"174.5\" y=\"21.5\" width=\"36.78\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"192.89\" y=\"36.9\" text-anchor=\"middle\">thick</text></g><g class=\"pele-edge-label\" data-id=\"L_C_D_0\"><rect x=\"311.28\" y=\"21.5\" width=\"46.92\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"334.74\" y=\"36.9\" text-anchor=\"middle\">dotted</text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect\" data-id=\"A\" transform=\"translate(32,32)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">A</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"B\" transform=\"translate(128,32)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">B</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"C\" transform=\"translate(264.78,32)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">C</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"D\" transform=\"translate(411.7,32)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">D</text></g></g></svg>",
  )
}

///|
test "routes a stepped flowchart at right angles" {
  inspect(
    svg(
      "---\nconfig:\n  flowchart:\n    curve: step\n---\nflowchart TD\n  A[Start] --> B[Parse]\n  A --> C[Measure]\n  A --> D[Theme]\n  B --> E[Fits]\n  C --> E\n  D --> E\n  E -->|Yes| F[Draw]\n  E -->|No| A",
    ),
    content="416x377 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-flowchart\" viewBox=\"0 0 416 377\" width=\"416\" height=\"377\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"flowchart\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_A_B_0\"><path d=\"M216.61,56L216.61,63.87Q216.61,74 206.48,74L58.9,74Q46.9,74 46.9,86L46.9,97\"/><path class=\"pele-marker\" d=\"M46.9,104L43.54,96L50.26,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_A_C_0\"><path d=\"M231.87,56L231.87,74Q231.87,86 219.87,86L183.16,86Q174.91,86 174.91,94.25L174.91,97\"/><path class=\"pele-marker\" d=\"M174.91,104L171.55,96L178.27,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_A_D_0\"><path d=\"M247.14,56L247.14,74Q247.14,86 259.14,86L298.68,86Q306.93,86 306.93,94.25L306.93,97\"/><path class=\"pele-marker\" d=\"M306.93,104L303.57,96L310.29,96Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_B_E_0\"><path d=\"M46.9,152L46.9,170Q46.9,182 58.9,182L213.78,182Q222.03,182 222.03,190.25L222.03,193\"/><path class=\"pele-marker\" d=\"M222.03,200L218.67,192L225.39,192Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_C_E_0\"><path d=\"M174.91,152L174.91,158Q174.91,170 186.91,170L222.62,170Q234.62,170 234.62,182L234.62,193\"/><path class=\"pele-marker\" d=\"M234.62,200L231.26,192L237.98,192Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_D_E_0\"><path d=\"M306.93,152L306.93,158Q306.93,170 294.93,170L259.22,170Q247.22,170 247.22,182L247.22,193\"/><path class=\"pele-marker\" d=\"M247.22,200L243.86,192L250.58,192Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_E_F_0\"><path d=\"M240.92,248L240.92,314\"/><path class=\"pele-marker\" d=\"M240.92,321L237.56,313L244.28,313Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_E_A_0\"><path d=\"M259.81,200L259.81,192.13Q259.81,182 269.93,182L380.77,182Q392.77,182 392.77,170L392.77,86Q392.77,74 380.77,74L270.65,74Q262.4,74 262.4,65.75L262.4,63\"/><path class=\"pele-marker\" d=\"M262.4,56L265.76,64L259.04,64Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\"><g class=\"pele-edge-label\" data-id=\"L_E_F_0\"><rect x=\"224.86\" y=\"274\" width=\"32.12\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"240.92\" y=\"289.4\" text-anchor=\"middle\">Yes</text></g><g class=\"pele-edge-label\" data-id=\"L_E_A_0\"><rect x=\"379.82\" y=\"117.5\" width=\"25.89\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"392.77\" y=\"132.9\" text-anchor=\"middle\">No</text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect\" data-id=\"A\" transform=\"translate(239.51,32)\"><rect x=\"-34.9\" y=\"-24\" width=\"69.79\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Start</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"B\" transform=\"translate(46.9,128)\"><rect x=\"-38.9\" y=\"-24\" width=\"77.79\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Parse</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"C\" transform=\"translate(174.91,128)\"><rect x=\"-49.12\" y=\"-24\" width=\"98.24\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Measure</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"D\" transform=\"translate(306.93,128)\"><rect x=\"-42.9\" y=\"-24\" width=\"85.79\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Theme</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"E\" transform=\"translate(240.92,224)\"><rect x=\"-30.89\" y=\"-24\" width=\"61.78\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Fits</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"F\" transform=\"translate(240.92,345)\"><rect x=\"-36.66\" y=\"-24\" width=\"73.33\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Draw</text></g></g></svg>",
  )
}

///|
test "turns a flowchart that runs across down on a narrow host" {
  inspect(
    svg(
      "flowchart LR\n  A[Christmas] -->|Get money| B(Go shopping)\n  B --> C{Let me think}\n  C -->|One| D[Laptop]\n  C -->|Two| E[iPhone]\n  C -->|Three| F[fa:fa-car Car]",
      max_width=400,
    ),
    content="329x451 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-flowchart\" viewBox=\"0 0 329 451\" width=\"329\" height=\"451\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"flowchart\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_A_B_0\"><path d=\"M175.83,56L175.83,122\"/><path class=\"pele-marker\" d=\"M175.83,129L172.47,121L179.19,121Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_B_C_0\"><path d=\"M175.83,177L175.83,218\"/><path class=\"pele-marker\" d=\"M175.83,225L172.47,217L179.19,217Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_C_D_0\"><path d=\"M159.83,311.47C159.83,326.72 50.46,326.72 50.46,341.97L50.46,387.47\"/><path class=\"pele-marker\" d=\"M50.46,394.47L47.1,386.47L53.82,386.47Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_C_E_0\"><path d=\"M175.83,321.47L175.83,387.47\"/><path class=\"pele-marker\" d=\"M175.83,394.47L172.47,386.47L179.19,386.47Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_C_F_0\"><path d=\"M191.83,311.47C191.83,326.72 289.62,326.72 289.62,341.97L289.62,387.47\"/><path class=\"pele-marker\" d=\"M289.62,394.47L286.26,386.47L292.98,386.47Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\"><g class=\"pele-edge-label\" data-id=\"L_A_B_0\"><rect x=\"137.6\" y=\"78.5\" width=\"76.47\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"175.83\" y=\"93.9\" text-anchor=\"middle\">Get money</text></g><g class=\"pele-edge-label\" data-id=\"L_C_D_0\"><rect x=\"33.23\" y=\"343.97\" width=\"34.46\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"50.46\" y=\"359.37\" text-anchor=\"middle\">One</text></g><g class=\"pele-edge-label\" data-id=\"L_C_E_0\"><rect x=\"158.61\" y=\"343.97\" width=\"34.45\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"175.83\" y=\"359.37\" text-anchor=\"middle\">Two</text></g><g class=\"pele-edge-label\" data-id=\"L_C_F_0\"><rect x=\"267.34\" y=\"343.97\" width=\"44.57\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text x=\"289.62\" y=\"359.37\" text-anchor=\"middle\">Three</text></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect\" data-id=\"A\" transform=\"translate(175.83,32)\"><rect x=\"-54\" y=\"-24\" width=\"108\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Christmas</text></g><g class=\"pele-node pele-shape-rounded\" data-id=\"B\" transform=\"translate(175.83,153)\"><rect x=\"-63.36\" y=\"-24\" width=\"126.72\" height=\"48\" rx=\"12\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Go shopping</text></g><g class=\"pele-node pele-shape-diam\" data-id=\"C\" transform=\"translate(175.83,273.24)\"><polygon points=\"0,-48.23 77.18,0 0,48.24 -77.18,0\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Let me think</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"D\" transform=\"translate(50.46,418.47)\"><rect x=\"-42.46\" y=\"-24\" width=\"84.93\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Laptop</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"E\" transform=\"translate(175.83,418.47)\"><rect x=\"-42.9\" y=\"-24\" width=\"85.81\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">iPhone</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"F\" transform=\"translate(289.62,418.47)\"><rect x=\"-30.89\" y=\"-24\" width=\"61.78\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">Car</text></g></g></svg>",
  )
}

///|
test "renders markdown labels" {
  inspect(
    svg(
      "flowchart TD\n  A[\"`This **is** _Markdown_`\"] -->|\"`**bold** edge`\"| B[\"a #quot;b#quot; #35; #9829;<br/>second line\"]",
    ),
    content=(
      #|179x203 <svg xmlns="http://www.w3.org/2000/svg" class="pele pele-flowchart" viewBox="0 0 179 203" width="179" height="203" style="max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_w:var(--pele-bold-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)" fill="var(--_fg)" role="graphics-document document" aria-roledescription="flowchart"><g class="pele-edges" fill="none" stroke="var(--_l)" stroke-linecap="round"><g class="pele-edge" data-id="L_A_B_0"><path d="M89.13,56L89.13,122"/><path class="pele-marker" d="M89.13,129L85.77,121L92.49,121Z" fill="var(--_l)" stroke="none"/></g></g><g class="pele-edge-labels" font-size="14"><g class="pele-edge-label" data-id="L_A_B_0"><rect x="52.84" y="78.5" width="72.58" height="21" rx="3" fill="var(--_bg)"/><text text-anchor="middle" xml:space="preserve"><tspan x="89.13" y="93.9" font-weight="var(--_w)">bold</tspan><tspan> edge</tspan></text></g></g><g class="pele-nodes"><g class="pele-node pele-shape-rect" data-id="A" transform="translate(89.13,32)"><rect x="-81.13" y="-24" width="162.26" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="5.6">This </tspan><tspan font-weight="var(--_w)">is</tspan><tspan> </tspan><tspan font-style="italic">Markdown</tspan></text></g><g class="pele-node pele-shape-rect" data-id="B" transform="translate(89.13,162)"><rect x="-58.46" y="-33" width="116.93" height="66" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="-4.9">a &quot;b&quot; # ♥</tspan><tspan x="0" y="16.1">second line</tspan></text></g></g></svg>
    ),
  )
}

///|
test "renders <sub> and <sup> in labels with baseline shift and smaller text" {
  inspect(
    svg("flowchart LR\n  A[\"H<sub>2</sub>O\"] --> B[\"x<sup>2</sup>\"]"),
    content=(
      #|183x64 <svg xmlns="http://www.w3.org/2000/svg" class="pele pele-flowchart" viewBox="0 0 183 64" width="183" height="64" style="max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)" fill="var(--_fg)" role="graphics-document document" aria-roledescription="flowchart"><g class="pele-edges" fill="none" stroke="var(--_l)" stroke-linecap="round"><g class="pele-edge" data-id="L_A_B_0"><path d="M75.41,32L116.41,32"/><path class="pele-marker" d="M123.41,32L115.41,35.36L115.41,28.64Z" fill="var(--_l)" stroke="none"/></g></g><g class="pele-nodes"><g class="pele-node pele-shape-rect" data-id="A" transform="translate(41.71,32)"><rect x="-33.71" y="-24" width="67.41" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="5.6">H</tspan><tspan baseline-shift="sub" font-size="smaller">2</tspan><tspan>O</tspan></text></g><g class="pele-node pele-shape-rect" data-id="B" transform="translate(149.12,32)"><rect x="-25.71" y="-24" width="51.41" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="5.6">x</tspan><tspan baseline-shift="super" font-size="smaller">2</tspan></text></g></g></svg>
    ),
  )
}

///|
test "nesting sub/sup inside other emphasis keeps each style on its own span" {
  inspect(
    svg("flowchart LR\n  A[\"<b>H<sub>2</sub>O</b>\"]"),
    content=(
      #|84x64 <svg xmlns="http://www.w3.org/2000/svg" class="pele pele-flowchart" viewBox="0 0 84 64" width="84" height="64" style="max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_w:var(--pele-bold-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)" fill="var(--_fg)" role="graphics-document document" aria-roledescription="flowchart"><g class="pele-nodes"><g class="pele-node pele-shape-rect" data-id="A" transform="translate(41.71,32)"><rect x="-33.71" y="-24" width="67.41" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" font-weight="var(--_w)" text-anchor="middle" xml:space="preserve"><tspan x="0" y="5.6">H</tspan><tspan baseline-shift="sub" font-size="smaller">2</tspan><tspan>O</tspan></text></g></g></svg>
    ),
  )
}

///|
test "shifts text inside both <sup> and <sub> by the inner tag" {
  inspect(
    svg("flowchart LR\n  A[\"x<sup>a<sub>b</sub>c</sup>\"]"),
    content=(
      #|82x64 <svg xmlns="http://www.w3.org/2000/svg" class="pele pele-flowchart" viewBox="0 0 82 64" width="82" height="64" style="max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)" fill="var(--_fg)" role="graphics-document document" aria-roledescription="flowchart"><g class="pele-nodes"><g class="pele-node pele-shape-rect" data-id="A" transform="translate(40.75,32)"><rect x="-32.75" y="-24" width="65.49" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="5.6">x</tspan><tspan baseline-shift="super" font-size="smaller">a</tspan><tspan baseline-shift="sub" font-size="smaller">b</tspan><tspan baseline-shift="super" font-size="smaller">c</tspan></text></g></g></svg>
    ),
  )
}

///|
test "restores the outer <sup> when a nested <sup> closes" {
  inspect(
    svg("flowchart LR\n  A[\"<sup>a<sub>b<sup>c</sup>d</sub>e</sup>\"]"),
    content=(
      #|89x64 <svg xmlns="http://www.w3.org/2000/svg" class="pele pele-flowchart" viewBox="0 0 89 64" width="89" height="64" style="max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)" fill="var(--_fg)" role="graphics-document document" aria-roledescription="flowchart"><g class="pele-nodes"><g class="pele-node pele-shape-rect" data-id="A" transform="translate(44.16,32)"><rect x="-36.16" y="-24" width="72.32" height="48" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="5.6" baseline-shift="super" font-size="smaller">a</tspan><tspan baseline-shift="sub" font-size="smaller">b</tspan><tspan baseline-shift="super" font-size="smaller">c</tspan><tspan baseline-shift="sub" font-size="smaller">d</tspan><tspan baseline-shift="super" font-size="smaller">e</tspan></text></g></g></svg>
    ),
  )
}

///|
test "keeps the inner of <sup> and <sub> across a line break" {
  inspect(
    svg("flowchart LR\n  A[\"<sup>a<sub>b<br/>c</sub>d</sup>\"]"),
    content=(
      #|67x82 <svg xmlns="http://www.w3.org/2000/svg" class="pele pele-flowchart" viewBox="0 0 67 82" width="67" height="82" style="max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)" fill="var(--_fg)" role="graphics-document document" aria-roledescription="flowchart"><g class="pele-nodes"><g class="pele-node pele-shape-rect" data-id="A" transform="translate(33.41,41)"><rect x="-25.41" y="-33" width="50.83" height="66" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="-4.9" baseline-shift="super" font-size="smaller">a</tspan><tspan baseline-shift="sub" font-size="smaller">b</tspan><tspan x="0" y="16.1" baseline-shift="sub" font-size="smaller">c</tspan><tspan baseline-shift="super" font-size="smaller">d</tspan></text></g></g></svg>
    ),
  )
}

///|
/// The label of node `id`, from its `<text` to its `</text>`.
fn node_text(svg : String, id : String) -> String {
  let node = @util.index_of(svg, "data-id=\"\{id}\"")
  let from = @util.index_of(svg, "<text", from=node)
  @util.slice(svg, from, end=@util.index_of(svg, "</text>", from~) + 7)
}

///|
test "draws <code> spans in labels in the monospace font" {
  inspect(
    node_text(
      svg("flowchart TD\n  A[\"Call <code>render()</code> once\"]"),
      "A",
    ),
    content=(
      #|<text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="5.6">Call </tspan><tspan font-family="var(--_fm)">render()</tspan><tspan> once</tspan></text>
    ),
  )
}

///|
test "writes the monospace family once when a whole label is code" {
  let drawn = svg("flowchart TD\n  A[\"<code>render()</code>\"]")
  inspect(
    node_text(drawn, "A"),
    content=(
      #|<text class="pele-label" font-family="var(--_fm)" text-anchor="middle" xml:space="preserve"><tspan x="0" y="5.6">render()</tspan></text>
    ),
  )
  let mut found = 0
  let mut at = @util.index_of(drawn, "font-family=\"var(--_fm)\"")
  while at != -1 {
    found += 1
    at = @util.index_of(drawn, "font-family=\"var(--_fm)\"", from=at + 1)
  }
  assert_eq(found, 1)
}

///|
test "keeps text shaped like a tag that is not HTML, and drops HTML tags" {
  inspect(
    [
      "List<T>", "<T>", "<span title=x>red</span> and <small>print</small><img src=x>",
      "<b>bold</b> and <T>",
    ]
    .map(label => node_text(svg("flowchart LR\n  A[\"\{label}\"]"), "A"))
    .join("\n"),
    content=(
      #|<text class="pele-label" x="0" y="5.6" text-anchor="middle">List&lt;T&gt;</text>
      #|<text class="pele-label" x="0" y="5.6" text-anchor="middle">&lt;T&gt;</text>
      #|<text class="pele-label" x="0" y="5.6" text-anchor="middle">red and print</text>
      #|<text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="5.6" font-weight="var(--_w)">bold</tspan><tspan> and &lt;T&gt;</tspan></text>
    ),
  )
}

///|
test "underlines <u> text" {
  let drawn = svg(
    "flowchart LR\n  A[\"a <u>underlined</u> word\"]\n  B[\"<u>all of it</u>\"]",
  )
  inspect(
    node_text(drawn, "A") + "\n" + node_text(drawn, "B"),
    content=(
      #|<text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="5.6">a </tspan><tspan text-decoration="underline">underlined</tspan><tspan> word</tspan></text>
      #|<text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="5.6" text-decoration="underline">all of it</tspan></text>
    ),
  )
}

///|
test "styles other inline tags as browsers do" {
  inspect(
    ["cite", "dfn", "var", "kbd", "samp", "tt", "ins"]
    .map(tag => {
      node_text(
        svg("flowchart LR\n  A[\"plain <\{tag}>tagged</\{tag}> plain\"]"),
        "A",
      )
    })
    .join("\n"),
    content=(
      #|<text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="5.6">plain </tspan><tspan font-style="italic">tagged</tspan><tspan> plain</tspan></text>
      #|<text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="5.6">plain </tspan><tspan font-style="italic">tagged</tspan><tspan> plain</tspan></text>
      #|<text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="5.6">plain </tspan><tspan font-style="italic">tagged</tspan><tspan> plain</tspan></text>
      #|<text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="5.6">plain </tspan><tspan font-family="var(--_fm)">tagged</tspan><tspan> plain</tspan></text>
      #|<text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="5.6">plain </tspan><tspan font-family="var(--_fm)">tagged</tspan><tspan> plain</tspan></text>
      #|<text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="5.6">plain </tspan><tspan font-family="var(--_fm)">tagged</tspan><tspan> plain</tspan></text>
      #|<text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="0" y="5.6">plain </tspan><tspan text-decoration="underline">tagged</tspan><tspan> plain</tspan></text>
    ),
  )
}

///|
test "an internal link that sanitizing alone would let through gets no href" {
  let options = {
    ..@types.RenderOptions::default(),
    link_schemes: Some(["about"]),
  }
  let result = @core.render(
    [@flowchart.flowchart],
    "flowchart TD\n  A[\"javascript:alert(1)\"]:::internal-link",
    options,
  )
  assert_false(result.svg.contains(" href="))
}

///|
/// The code and message of the error `source` fails with.
fn failure_of(source : String) -> String {
  let _ = @core.render(
    [@flowchart.flowchart],
    source,
    @types.RenderOptions::default(),
  ) catch {
    @errors.PeleError(failure) =>
      return "\{failure.code.to_string()}: \{failure.message}"
  }
  "rendered"
}

///|
test "entity codes show in errors as they were written" {
  assert_true(
    failure_of("flowchart TD\nA[a#35;b] --> -->").has_prefix(
      "syntax: Parse error on line 2:\nA[a#35;b] --> -->\n",
    ),
  )
  inspect(
    failure_of("flowchart TD\na@{shape: \"#35;x\"}"),
    content="semantic: No such shape: #35;x.",
  )
}

///|
/// The line, column and snippet of the error `source` fails with.
fn position_of(source : String) -> String {
  let _ = @core.render(
    [@flowchart.flowchart],
    source,
    @types.RenderOptions::default(),
  ) catch {
    @errors.PeleError(failure) =>
      return "\{failure.line}:\{failure.column}\n\{failure.snippet}\n\{failure.message}"
  }
  "rendered"
}

///|
test "errors report lines and columns in the source as written" {
  inspect(
    position_of("flowchart TD\nA[a#35;b] --> -->"),
    content=(
      #|2:15
      #|A[a#35;b] --> -->
      #|--------------^
      #|Parse error on line 2:
      #|A[a#35;b] --> -->
      #|--------------^
      #|Expecting 'NODE_STRING', got 'LINK'
    ),
  )
  inspect(
    position_of(
      "---\ntitle: T\n---\n\n%% A comment\nflowchart TD\n  A --> B\n  C --> --> D",
    ),
    content=(
      #|8:9
      #|  C --> --> D
      #|--------^
      #|Parse error on line 8:
      #|  C --> --> D
      #|--------^
      #|Expecting 'NODE_STRING', got 'LINK'
    ),
  )
  assert_true(
    position_of("flowchart TD\n  A{a}  \n\n  C --> --> D").has_prefix("4:9\n"),
  )
}

///|
/// A host that has exactly the icons in `pairs`, by name.
fn host(pairs : Array[(String, String)]) -> @types.IconResolver {
  let icons = Map::from_array(pairs)
  name => icons.get(name)
}

///|
test "icon nodes, labels and edge labels draw the host's icons" {
  inspect(
    svg(
      "flowchart TD\n    A@{ icon: \"fa:user\", form: \"square\", label: \"User fa:fa-car\", pos: \"t\", h: 60 }\n    B@{ icon: \"fa:none\", form: \"circle\", label: \"B\" }\n    C@{ icon: \"fa:user\", form: \"rounded\" }\n    D@{ icon: \"fa:blank\" }\n    A -- fa:fa-car go --> B\n",
      icons=host([
        ("fa:user", "<path id=\"user\"/>"),
        ("fa:fa-car", "<path id=\"car\"/>"),
        ("fa:blank", ""),
      ]),
    ),
    content="259x257 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-flowchart\" viewBox=\"0 0 259 257\" width=\"259\" height=\"257\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"flowchart\"><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_A_B_0\"><path d=\"M41.11,98L41.11,164\"/><path class=\"pele-marker\" d=\"M41.11,171L37.75,163L44.47,163Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\"><g class=\"pele-edge-label\" data-id=\"L_A_B_0\"><rect x=\"18.63\" y=\"120.5\" width=\"44.96\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"40.13\" y=\"135.9\" text-anchor=\"start\"> go</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"22.63\" y=\"123.3\" width=\"15.4\" height=\"15.4\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-iconSquare\" data-id=\"A\" transform=\"translate(41.11,53)\"><rect x=\"-30\" y=\"-15\" width=\"60\" height=\"60\" rx=\"0\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><svg class=\"pele-icon\" data-icon=\"fa:user\" x=\"-18\" y=\"-3\" width=\"36\" height=\"36\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"user\"/></svg><text class=\"pele-label\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"-29.11\" y=\"-24.4\" text-anchor=\"start\">User </tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"9.11\" y=\"-38.8\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g><g class=\"pele-node pele-shape-iconCircle\" data-id=\"B\" transform=\"translate(41.11,210)\"><circle cy=\"-15\" r=\"24\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><svg class=\"pele-icon\" data-icon=\"fa:none\" x=\"-14.4\" y=\"-29.4\" width=\"28.8\" height=\"28.8\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"></svg><text class=\"pele-label\" x=\"0\" y=\"29.6\" text-anchor=\"middle\">B</text></g><g class=\"pele-node pele-shape-iconRounded\" data-id=\"C\" transform=\"translate(138.22,53)\"><rect x=\"-24\" y=\"-24\" width=\"48\" height=\"48\" rx=\"8\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><svg class=\"pele-icon\" data-icon=\"fa:user\" x=\"-14.4\" y=\"-14.4\" width=\"28.8\" height=\"28.8\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"user\"/></svg></g><g class=\"pele-node pele-shape-icon\" data-id=\"D\" transform=\"translate(226.22,53)\"><svg class=\"pele-icon\" data-icon=\"fa:blank\" x=\"-14.4\" y=\"-14.4\" width=\"28.8\" height=\"28.8\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"></svg></g></g></svg>",
  )
}

///|
test "group titles, struck through or not, draw the host's icons" {
  inspect(
    svg(
      "flowchart TB\n    c1-->a2\n    subgraph one [fa:fa-car one]\n    a1-->a2\n    end\n    subgraph two [fa:fa-car two]\n    b1-->b2\n    end\n    subgraph three [fa:fa-car three]\n    c1-->c2\n    end\n    one --> two\n    three --> two\n    two --> c2\n",
      icons=host([("fa:fa-car", "<path id=\"car\"/>")]),
    ),
    content="229x764 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-flowchart\" viewBox=\"0 0 229 764\" width=\"229\" height=\"764\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"flowchart\"><g class=\"pele-clusters\"><g class=\"pele-cluster\" data-id=\"three\"><rect x=\"99.34\" y=\"8\" width=\"120.9\" height=\"224\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"133.34\" y=\"33.6\" text-anchor=\"start\"> three</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"113.34\" y=\"19.2\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g><g class=\"pele-cluster\" data-id=\"two\"><rect x=\"100.38\" y=\"552\" width=\"93.79\" height=\"204\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/></g><g class=\"pele-cluster\" data-id=\"one\"><rect x=\"8\" y=\"280\" width=\"121.79\" height=\"224\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"63.33\" y=\"305.6\" text-anchor=\"start\"> one</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"43.33\" y=\"291.2\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g></g><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_c1_a2_0\"><path d=\"M138.57,96C138.57,120 119.34,120 119.34,144L119.34,232C119.34,256 28,256 28,280L28,388C28,405.5 47.45,405.5 47.45,423L47.45,429\"/><path class=\"pele-marker\" d=\"M47.45,436L44.09,428L50.81,428Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_a1_a2_0\"><path d=\"M82.9,388C82.9,405.5 63.45,405.5 63.45,423L63.45,429\"/><path class=\"pele-marker\" d=\"M63.45,436L60.09,428L66.81,428Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_b1_b2_0\"><path d=\"M147.27,640L147.27,681\"/><path class=\"pele-marker\" d=\"M147.27,688L143.91,680L150.63,680Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_c1_c2_0\"><path d=\"M154.57,96C154.57,113.5 173.79,113.5 173.79,131L173.79,137\"/><path class=\"pele-marker\" d=\"M173.79,144L170.43,136L177.15,136Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_one_two_0\"><path d=\"M68.9,504C68.9,521.5 141.79,521.5 141.79,539L141.79,545\"/><path class=\"pele-marker\" d=\"M141.79,552L138.43,544L145.15,544Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_three_two_0\"><path d=\"M157.79,232L157.79,545\"/><path class=\"pele-marker\" d=\"M157.79,552L154.43,544L161.15,544Z\" fill=\"var(--_l)\" stroke=\"none\"/></g><g class=\"pele-edge\" data-id=\"L_two_c2_0\"><path d=\"M173.79,552L173.79,199\"/><path class=\"pele-marker\" d=\"M173.79,192L177.15,200L170.43,200Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-cluster-titles\"><g class=\"pele-cluster-title\" data-id=\"two\"><text fill=\"none\" stroke=\"color-mix(in srgb,var(--_a) 50%,var(--_bg))\" stroke-width=\"5\" stroke-linejoin=\"round\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"134.38\" y=\"577.6\" text-anchor=\"start\"> two</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"114.38\" y=\"563.2\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg><text class=\"pele-cluster-label\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"134.38\" y=\"577.6\" text-anchor=\"start\"> two</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"114.38\" y=\"563.2\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect\" data-id=\"c1\" transform=\"translate(146.57,72)\"><rect x=\"-26.45\" y=\"-24\" width=\"52.9\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">c1</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"a2\" transform=\"translate(55.45,460)\"><rect x=\"-26.9\" y=\"-24\" width=\"53.79\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">a2</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"a1\" transform=\"translate(82.9,364)\"><rect x=\"-26.9\" y=\"-24\" width=\"53.79\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">a1</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"b1\" transform=\"translate(147.27,616)\"><rect x=\"-26.9\" y=\"-24\" width=\"53.79\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b1</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"b2\" transform=\"translate(147.27,712)\"><rect x=\"-26.9\" y=\"-24\" width=\"53.79\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">b2</text></g><g class=\"pele-node pele-shape-rect\" data-id=\"c2\" transform=\"translate(173.79,168)\"><rect x=\"-26.45\" y=\"-24\" width=\"52.9\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">c2</text></g></g></svg>",
  )
}

///|
test "the title leaves its icon squares empty" {
  inspect(
    svg(
      "---\ntitle: fa:fa-car Title\n---\nflowchart LR\n    A[fa:fa-car Start] --> B(fa:fa-car)\n",
      icons=host([("fa:fa-car", "<path id=\"car\"/>")]),
    ),
    content="215x100 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-flowchart\" viewBox=\"0 0 215 100\" width=\"215\" height=\"100\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"flowchart\"><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"98.83\" y=\"25.6\" text-anchor=\"start\"> Title</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"78.83\" y=\"11.2\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"></svg><g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge\" data-id=\"L_A_B_0\"><path d=\"M102.24,68L143.24,68\"/><path class=\"pele-marker\" d=\"M150.24,68L142.24,71.36L142.24,64.64Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-shape-rect\" data-id=\"A\" transform=\"translate(55.12,68)\"><rect x=\"-47.12\" y=\"-24\" width=\"94.24\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"-9.12\" y=\"5.6\" text-anchor=\"start\"> Start</tspan></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"-29.12\" y=\"-8.8\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g><g class=\"pele-node pele-shape-rounded\" data-id=\"B\" transform=\"translate(178.24,68)\"><rect x=\"-28\" y=\"-24\" width=\"56\" height=\"48\" rx=\"12\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/><text class=\"pele-label\" text-anchor=\"middle\" xml:space=\"preserve\"></text><svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"-10\" y=\"-8.8\" width=\"17.6\" height=\"17.6\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg></g></g></svg>",
  )
}
