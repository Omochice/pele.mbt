#import "../lib.typ": mermaid

#let dark = (
  bg: rgb("#1e1e2e"),
  fg: rgb("#cdd6f4"),
  muted: rgb("#a6adc8"),
  line: rgb("#bac2de"),
  surface: rgb("#313244"),
  surface-alt: rgb("#45475a"),
  border: rgb("#7f849c"),
  accent: rgb("#89b4fa"),
  radius: 8pt,
)

#set page(width: 16cm, height: auto, margin: 1cm, fill: dark.bg)
#set text(fill: dark.fg)

= A dark theme

Every color, the corner radius and the fonts can be set through the theme, with the keys of pele's `--pele-*` custom properties.

#mermaid(theme: dark, ```
stateDiagram-v2
  [*] --> Draft
  Draft --> Review : submit
  Review --> Draft : request changes
  Review --> Published : approve
  Published --> [*]
```)

#mermaid(theme: dark + (font: "Courier New, DejaVu Sans Mono"), ```
mindmap
  root((pele))
    Diagrams
      Flowchart
      Sequence
    Output
      SVG
      typst
```)
