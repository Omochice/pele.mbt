#import "../lib.typ": mermaid, render

#let flowchart = "graph TD\nA-->B"

// The result carries what pele returns.
#let pie = render("pie\n  \"Dogs\": 3\n  \"Cats\": 2")
#assert.eq(pie.type, "pie")
#assert.eq(pie.mermaidType, "pie")
#assert(pie.width > 0 and pie.height > 0)

// The SVG is resolved for typst by default.
#let plain = render(flowchart)
#assert(not plain.svg.contains("var("), message: "a custom property is left")
#assert(plain.svg.contains("rx=\"4px\""), message: "the radius stays in the style")

// typst resolves no generic family, so the default theme names fonts.
#assert(plain.svg.contains("font-family:Arial, Helvetica"), message: plain.svg)
#assert(not plain.svg.contains("monospace"), message: "the mono font is generic")

// typst values are written as CSS.
#let themed = render(flowchart, theme: (surface: rgb("#123456"), radius: 0pt, heading-weight: 600))
#assert(themed.svg.contains("fill=\"#123456\""), message: themed.svg)
#assert(themed.svg.contains("rx=\"0\""), message: themed.svg)

// The README's theme compiles as written.
#let readme = render(theme: (bg: rgb("#1e1e2e"), fg: white, accent: blue, radius: 8pt, series-1: teal), "pie\n  \"A\": 1")
#assert(readme.svg.contains("#ffffff"), message: readme.svg)

// pele's own font option wins over the default theme.
#assert(render(flowchart, fontFamily: "Inter").svg.contains("font-family:Inter\""))

// Other options reach pele under their own names.
#assert(render(flowchart, fontSize: 20).svg.contains("font:20px"))

// monospace lists parts that are measured and drawn in the theme's mono font.
#let members = "classDiagram\n  class A {\n    +title: string\n  }"
#let mono = render(members, monospace: ("members",))
#assert(mono.svg.contains("<g class=\"pele-members\" font-size=\"14\" font-family=\"DejaVu Sans Mono\">"), message: mono.svg)
#assert(mono.width > render(members).width, message: "the members are measured in the mono font")
#assert(render(members, monospace: ("members",), theme: none).svg.contains("font-family=\"var(--_fm)\""))

// A string is not a list of parts, so pele draws as without the option.
#assert.eq(render(members, monospace: ("members")).svg, render(members).svg)

// The README's monospace parts compile as written.
#mermaid(monospace: ("members",), "classDiagram\n  class A {\n    +title: string\n  }")

// Icons reach pele as a dictionary from icon name to SVG fragment.
#let car = "<path d=\"M3,14H21V18H3Z\"/>"
#let iconic = render("graph TD\n  A[fa:fa-car Car]\n  B[fa:fa-bus Bus]", icons: ("fa:fa-car": car))
#assert(iconic.svg.contains("data-icon=\"fa:fa-car\""), message: iconic.svg)
#assert(iconic.svg.contains(car), message: iconic.svg)
#assert(not iconic.svg.contains("fa:fa-bus"), message: "an icon the host lacks is drawn")
#assert(render("graph TD\n  A[fa:fa-car Car]").width < iconic.width, message: "the icon takes no room")
#mermaid("architecture-beta\n  service db(database)[DB]", icons: ("database": car))

// The README's icons compile as written.
#let readme-icons = render(icons: ("fa:fa-car": "<path d=\"M3,15V11L6,6H18L21,11V15Z\"/>"), "graph TD\n  A[fa:fa-car Car]")
#assert(readme-icons.svg.contains("M3,15V11L6,6H18L21,11V15Z"), message: readme-icons.svg)

// The halo behind a cluster title that edges run through is mixed into a color typst draws.
#let namespaces = "classDiagram\n  namespace Company.Engineering.Backend {\n    class Developer\n  }\n  namespace Company.Engineering.Frontend {\n    class Designer\n  }\n  namespace Company.Engineering {\n    class TechLead\n  }\n  TechLead --> Developer : leads\n  TechLead --> Designer : leads"
#let struck = render(namespaces, maxWidth: 400)
#assert(not struck.svg.contains("color-mix("), message: struck.svg)
#assert(struck.svg.contains("stroke=\"#e9e9e9\""), message: struck.svg)
#let dark-struck = render(namespaces, maxWidth: 400, theme: (bg: rgb("#1e1e2e"), surface-alt: rgb("#45475a")))
#assert(dark-struck.svg.contains("stroke=\"#404255\""), message: dark-struck.svg)
#assert(render(namespaces, maxWidth: 400, theme: none).svg.contains("color-mix(in srgb,var(--_a) 87.5%,var(--_bg))"))
#mermaid(namespaces, maxWidth: 400)

// Without a theme the SVG is pele's own.
#assert(render(flowchart, theme: none).svg.contains("fill=\"var(--_s)\""))

// A raw block is read as its text.
#assert.eq(render(```mermaid
graph TD
  A-->B
```).type, "flowchart")

// mermaid places the SVG as an image.
#mermaid(flowchart)
#mermaid(flowchart, width: 50%)
