///|
test "paints tells a fill that covers what is under it from one that does not" {
  let cases = [
    ["fill:red"],
    ["fill:none"],
    ["fill:NONE"],
    ["fill: transparent"],
    ["fill:#0000"],
    ["fill:#0001"],
    ["fill:rgb(0 0 0 / 0)"],
    ["fill:url-ish"],
    ["fill:red", "fill-opacity:0"],
    ["fill:red", "fill-opacity:0%"],
    ["fill:red", "fill-opacity:calc(0)"],
    ["fill:red", "opacity:0"],
    ["fill:red", "opacity:calc(0)", "fill-opacity:0"],
    ["stroke:red"],
    ["fill:a&b"],
    ["fill:\"x\""],
    ["stroke:x&fill:none", "fill:red"],
  ]
  let painted = cases.map(decls => @svg.paints(@svg.resolve_style(decls).shape))
  debug_inspect(
    painted,
    content=(
      #|[
      #|  true,
      #|  false,
      #|  false,
      #|  false,
      #|  false,
      #|  true,
      #|  false,
      #|  true,
      #|  false,
      #|  false,
      #|  true,
      #|  false,
      #|  true,
      #|  false,
      #|  true,
      #|  true,
      #|  false,
      #|]
    ),
  )
  inspect(
    cases.map(decls => @svg.raw_paints(@svg.resolve_raw_style(decls).shape)) ==
    painted,
    content="true",
  )
}

///|
test "marker outlines an arrowhead in the stroke it is given" {
  inspect(
    @svg.marker("arrow_point", 10, 20, 0, 1, "var(--_bg)", stroke="var(--_bg)"),
    content="<path class=\"pele-marker\" d=\"M10,20L6.64,12L13.36,12Z\" fill=\"var(--_bg)\" stroke=\"var(--_bg)\"/>",
  )
}

///|
test "casing is as wide and as faint as the edge's line style makes the edge" {
  let tip = @svg.marker(
    "arrow_point",
    10,
    20,
    0,
    1,
    "var(--_bg)",
    stroke="var(--_bg)",
  )
  let cases : Array[(Array[String], Bool)] = [
    ([], false),
    (["stroke-width:10px"], false),
    (["stroke-width:1"], false),
    (["stroke-width:1px"], false),
    (["stroke-width:1em"], false),
    (["stroke-width:.."], false),
    (["stroke-width:3"], true),
    (["opacity:0", "stroke-opacity:0.5"], false),
    (["stroke:none"], false),
    (["stroke:transparent"], false),
    (["stroke:NONE"], false),
    (["stroke-width:a&b"], false),
    (["stroke-dasharray:x&stroke-width:9", "stroke-width:2"], false),
    (["stroke-dasharray:x&stroke:", "stroke:none"], false),
  ]
  let cased = cases.map(c => {
    @svg.casing("M0,0L1,1", tip, line=@svg.resolve_style(c.0).line, thick=c.1)
  })
  inspect(
    cased.join("\n"),
    content=(
      #|<path d="M0,0L1,1"/><path d="M10,20L6.64,12L13.36,12Z" fill="var(--_bg)" stroke="var(--_bg)"/>
      #|<g stroke-width="14"><path d="M0,0L1,1"/><path d="M10,20L6.64,12L13.36,12Z" fill="var(--_bg)" stroke="var(--_bg)"/></g>
      #|<path d="M0,0L1,1"/><path d="M10,20L6.64,12L13.36,12Z" fill="var(--_bg)" stroke="var(--_bg)"/>
      #|<path d="M0,0L1,1"/><path d="M10,20L6.64,12L13.36,12Z" fill="var(--_bg)" stroke="var(--_bg)"/>
      #|<g style="stroke-width:calc(1em + 4px);"><path d="M0,0L1,1"/><path d="M10,20L6.64,12L13.36,12Z" fill="var(--_bg)" stroke="var(--_bg)"/></g>
      #|<g stroke-width="NaN"><path d="M0,0L1,1"/><path d="M10,20L6.64,12L13.36,12Z" fill="var(--_bg)" stroke="var(--_bg)"/></g>
      #|<g stroke-width="6.5"><path d="M0,0L1,1"/><path d="M10,20L6.64,12L13.36,12Z" fill="var(--_bg)" stroke="var(--_bg)"/></g>
      #|<g style="opacity:0;stroke-opacity:0.5;"><path d="M0,0L1,1"/><path d="M10,20L6.64,12L13.36,12Z" fill="var(--_bg)" stroke="var(--_bg)"/></g>
      #|
      #|
      #|<path d="M0,0L1,1"/><path d="M10,20L6.64,12L13.36,12Z" fill="var(--_bg)" stroke="var(--_bg)"/>
      #|<g style="stroke-width:calc(a&amp + 4px);"><path d="M0,0L1,1"/><path d="M10,20L6.64,12L13.36,12Z" fill="var(--_bg)" stroke="var(--_bg)"/></g>
      #|<g stroke-width="13"><path d="M0,0L1,1"/><path d="M10,20L6.64,12L13.36,12Z" fill="var(--_bg)" stroke="var(--_bg)"/></g>
      #|
    ),
  )
  inspect(
    cases.map(c => {
      @svg.raw_casing(
        "M0,0L1,1",
        tip,
        css=@svg.resolve_raw_style(c.0).line,
        thick=c.1,
      )
    }) ==
    cased,
    content="true",
  )
}

///|
test "edge_casing drops the markers' class so marker styles skip the casing" {
  let path : @svg.EdgePath = {
    d: "M0,0L0,20",
    sx: 0,
    sy: 0,
    tokens: None,
    sdx: 0,
    sdy: -1,
    ex: 0,
    ey: 20,
    edx: 0,
    edy: 1,
  }
  inspect(
    @svg.edge_casing(path, "arrow_circle", "arrow_point"),
    content=(
      #|<path d="M0,0L0,20"/><circle cx="0" cy="4" r="3.5" fill="var(--_bg)" stroke="var(--_bg)"/><path d="M0,20L-3.36,12L3.36,12Z" fill="var(--_bg)" stroke="var(--_bg)"/>
    ),
  )
}

///|
test "write_casings draws the casings in a group of the page color, or nothing" {
  let out = @svg.Markup::new()
  @svg.write_casings(out, @svg.Markup::new())
  inspect(out.is_empty(), content="true")
  let casings = @svg.Markup::new()
  casings.write("<path d=\"M0,0\"/>")
  @svg.write_casings(out, casings)
  inspect(
    out.to_string(),
    content="<g class=\"pele-casings\" fill=\"none\" stroke=\"var(--_bg)\" stroke-width=\"5\" stroke-linecap=\"round\" stroke-linejoin=\"round\" pointer-events=\"none\"><path d=\"M0,0\"/></g>",
  )
}
