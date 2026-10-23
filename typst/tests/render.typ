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

// pele's own font option wins over the default theme.
#assert(render(flowchart, fontFamily: "Inter").svg.contains("font-family:Inter\""))

// Other options reach pele under their own names.
#assert(render(flowchart, fontSize: 20).svg.contains("font:20px"))

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
