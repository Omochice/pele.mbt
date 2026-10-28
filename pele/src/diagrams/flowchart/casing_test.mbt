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
/// The group that draws the edge with `id`, its line and its markers.
fn edge_group(svg : String, id : String) -> String {
  let at = @util.index_of(svg, "data-id=\"\{id}\"")
  let start = @util.last_index_of(svg, "<g ", from=at)
  @util.slice(svg, start, end=@util.index_of(svg, "</g>", from=at) + 4)
}

///|
test "cases edges that cross into a subgraph fill a style sets and inks edges inside it" {
  let source = "flowchart LR\n  subgraph S[\"Cluster\"]\n    A[Start] -- Launch --> B[Worker]\n    subgraph N\n      G --> H\n    end\n  end\n  subgraph T\n    D --> E\n  end\n  C[Output]\n  B --> C\n  C ==> D\n  B --> B\n  F --> C\n  B --> G\n  A --> H\n  style S fill:#BBDEFB\n  style N fill:navy\n  style C fill:#BBDEFB"
  let drawn = svg(source)
  // Inside one fill an edge takes that fill's ink, on its line and its arrowhead; across a fill's border, including into a nested fill, it takes a casing and the theme's line.
  inspect(
    [
      "L_A_B_0", "L_B_B_0", "L_G_H_0", "L_B_C_0", "L_B_G_0", "L_A_H_0", "L_C_D_0",
      "L_D_E_0", "L_F_C_0",
    ]
    .map(id => {
      let group = edge_group(drawn, id)
      let head = @util.slice(group, 0, end=@util.index_of(group, ">") + 1)
      let marker = @util.index_of(group, "<path class=\"pele-marker\"")
      let tip = if marker == -1 {
        ""
      } else {
        @util.slice(
          group,
          marker,
          end=@util.index_of(group, "/>", from=marker) + 2,
        )
      }
      "\{id} cased=\{cased(drawn, id)} \{head} \{tip}"
    })
    .join("\n"),
    content=(
      #|L_A_B_0 cased=false <g class="pele-edge" data-id="L_A_B_0" stroke="var(--pele-fg-on-light,#1f1f1f)"> <path class="pele-marker" d="M203.71,200L195.71,203.36L195.71,196.64Z" fill="var(--pele-fg-on-light,#1f1f1f)" stroke="none"/>
      #|L_B_B_0 cased=false <g class="pele-edge" data-id="L_B_B_0" stroke="var(--pele-fg-on-light,#1f1f1f)"> <path class="pele-marker" d="M255.49,224L261.05,230.66L254.63,232.63Z" fill="var(--pele-fg-on-light,#1f1f1f)" stroke="none"/>
      #|L_G_H_0 cased=false <g class="pele-edge" data-id="L_G_H_0" stroke="var(--pele-fg-on-dark,#fff)"> <path class="pele-marker" d="M475.71,122L467.71,125.36L467.71,118.64Z" fill="var(--pele-fg-on-dark,#fff)" stroke="none"/>
      #|L_B_C_0 cased=true <g class="pele-edge" data-id="L_B_C_0"> <path class="pele-marker" d="M631.71,265L623.71,268.36L623.71,261.64Z" fill="var(--_l)" stroke="none"/>
      #|L_B_G_0 cased=true <g class="pele-edge" data-id="L_B_G_0"> <path class="pele-marker" d="M379.26,140L371.26,143.36L371.26,136.64Z" fill="var(--_l)" stroke="none"/>
      #|L_A_H_0 cased=true <g class="pele-edge" data-id="L_A_H_0"> <path class="pele-marker" d="M475.71,106L467.71,109.36L467.71,102.64Z" fill="var(--_l)" stroke="none"/>
      #|L_C_D_0 cased=false <g class="pele-edge" data-id="L_C_D_0"> <path class="pele-marker" d="M803.74,273L795.74,276.36L795.74,269.64Z" fill="var(--_l)" stroke="none"/>
      #|L_D_E_0 cased=false <g class="pele-edge" data-id="L_D_E_0"> <path class="pele-marker" d="M899.74,273L891.74,276.36L891.74,269.64Z" fill="var(--_l)" stroke="none"/>
      #|L_F_C_0 cased=false <g class="pele-edge" data-id="L_F_C_0"> <path class="pele-marker" d="M631.71,281L623.71,284.36L623.71,277.64Z" fill="var(--_l)" stroke="none"/>
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
  let plain = svg(
    source
    .replace(old="\n  style S fill:#BBDEFB", new="")
    .replace(old="\n  style N fill:navy", new=""),
  )
  inspect(plain.contains("pele-casings"), content="false")
  inspect(plain.contains("--pele-fg-on-dark"), content="false")
  inspect(
    plain.contains("stroke=\"var(--pele-fg-on-light,#1f1f1f)\""),
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
        "flowchart TB\nsubgraph S\n  A\nend\nA --x B\nstyle S fill:\{fill}\n\{link}",
      ),
    )
  }
  inspect(
    casings("linkStyle 0 stroke-width:10px", "white"),
    content=(
      #|<g stroke-width="14"><path d="M52,96L52,180"/><path d="M55.5,176.5L48.5,183.5M48.5,176.5L55.5,183.5"/></g>
    ),
  )
  inspect(
    casings("linkStyle 0 stroke-width:1em", "white"),
    content=(
      #|<g style="stroke-width:calc(1em + 4px);"><path d="M52,96L52,180"/><path d="M55.5,176.5L48.5,183.5M48.5,176.5L55.5,183.5"/></g>
    ),
  )
  inspect(
    casings("linkStyle 0 opacity:0,stroke-opacity:0.5", "white"),
    content=(
      #|<g style="opacity:0;stroke-opacity:0.5;"><path d="M52,96L52,180"/><path d="M55.5,176.5L48.5,183.5M48.5,176.5L55.5,183.5"/></g>
    ),
  )
  inspect(casings("linkStyle 0 stroke:none", "white"), content="")
  inspect(casings("", "none"), content="")
  inspect(casings("", "transparent"), content="")
  inspect(casings("", "#0000"), content="")
}
