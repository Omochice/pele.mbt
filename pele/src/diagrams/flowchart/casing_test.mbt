///|
/// What the group of casings in a drawing holds, or an empty string when it has none.
fn casings_of(svg : String) -> String {
  let open = @util.index_of(svg, "<g class=\"pele-casings\"")
  if open < 0 {
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
/// The path data of the edge with `id`.
fn edge_path(svg : String, id : String) -> String {
  let at = @util.index_of(svg, "data-id=\"\{id}\"")
  let start = @util.index_of(svg, "<path d=\"", from=at) + 9
  @util.slice(svg, start, end=@util.index_of(svg, "\"", from=start))
}

///|
/// Whether a casing lies under the edge with `id`.
fn cased(svg : String, id : String) -> Bool {
  casings_of(svg).contains("<path d=\"\{edge_path(svg, id)}\"/>")
}

///|
test "cases edges that run over a subgraph fill a style sets" {
  let source = "flowchart LR\n  subgraph S[\"Cluster\"]\n    A[Start] -- Launch --> B[Worker]\n  end\n  subgraph T\n    D --> E\n  end\n  C[Output]\n  B --> C\n  C ==> D\n  B --> B\n  F --> C\n  style S fill:#BBDEFB\n  style C fill:#BBDEFB"
  let drawn = svg(source)
  inspect(
    ["L_A_B_0", "L_B_C_0", "L_B_B_0", "L_C_D_0", "L_D_E_0", "L_F_C_0"]
    .map(id => "\{id} \{cased(drawn, id)}")
    .join("\n"),
    content=(
      #|L_A_B_0 true
      #|L_B_C_0 true
      #|L_B_B_0 true
      #|L_C_D_0 false
      #|L_D_E_0 false
      #|L_F_C_0 false
    ),
  )
  inspect(
    drawn.contains(
      "<g class=\"pele-casings\" fill=\"none\" stroke=\"var(--_bg)\" stroke-width=\"5\" stroke-linecap=\"round\" stroke-linejoin=\"round\" pointer-events=\"none\">",
    ),
    content="true",
  )
  let casings = casings_of(drawn)
  inspect(
    casings.contains("Z\" fill=\"var(--_bg)\" stroke=\"var(--_bg)\"/>"),
    content="true",
  )
  inspect(casings.contains("pele-marker"), content="false")
  inspect(
    @util.index_of(drawn, "class=\"pele-casings\"") <
    @util.index_of(drawn, "class=\"pele-edges\""),
    content="true",
  )
  inspect(
    svg(source.replace(old="\n  style S fill:#BBDEFB", new="")).contains(
      "pele-casings",
    ),
    content="false",
  )
}

///|
test "cases an edge whose curve runs into a filled subgraph" {
  let drawn = svg(
    "flowchart LR\nsubgraph S\n  A\n  B\nend\nD\nE --> A\nD --> F\nF --> C\nB --> C\nstyle S fill:white",
  )
  inspect(cased(drawn, "L_F_C_0"), content="true")
  inspect(cased(drawn, "L_D_F_0"), content="false")
}

///|
test "cases an edge as wide and as faint as its line style makes it" {
  fn casings(link : String, fill : String) -> String {
    casings_of(
      svg(
        "flowchart TB\nsubgraph S\n  A --x B\nend\nstyle S fill:\{fill}\n\{link}",
      ),
    )
  }
  inspect(
    casings("linkStyle 0 stroke-width:10px", "white"),
    content=(
      #|<g stroke-width="14"><path d="M52,96L52,140"/><path d="M55.5,136.5L48.5,143.5M48.5,136.5L55.5,143.5"/></g>
    ),
  )
  inspect(
    casings("linkStyle 0 stroke-width:1em", "white"),
    content=(
      #|<g style="stroke-width:calc(1em + 4px);"><path d="M52,96L52,140"/><path d="M55.5,136.5L48.5,143.5M48.5,136.5L55.5,143.5"/></g>
    ),
  )
  inspect(
    casings("linkStyle 0 opacity:0,stroke-opacity:0.5", "white"),
    content=(
      #|<g style="opacity:0;stroke-opacity:0.5;"><path d="M52,96L52,140"/><path d="M55.5,136.5L48.5,143.5M48.5,136.5L55.5,143.5"/></g>
    ),
  )
  inspect(casings("linkStyle 0 stroke:none", "white"), content="")
  inspect(casings("", "none"), content="")
  inspect(casings("", "transparent"), content="")
  inspect(casings("", "#0000"), content="")
}
