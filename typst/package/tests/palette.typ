#import "../lib.typ": render

#let pie = "pie\n  \"A\": 1\n  \"B\": 1"
#let themed(vars) = "%%{init: " + json.encode((themeVariables: vars), pretty: false) + "}%%\n" + pie

// A palette the source sets reaches typst without a theme of series colors.
#let plain = render(themed((pie1: "#ff0000")))
#assert(plain.svg.contains("fill=\"#ff0000\""), message: plain.svg)
#assert(not plain.svg.contains("--pele-series"), message: "a custom property is left")

// The source's palette is declared on the root, so it wins over the theme as it does in a browser.
#let over = render(themed((pie1: "#ff0000")), theme: (series-1: teal, series-2: navy))
#assert(over.svg.contains("fill=\"#ff0000\""), message: over.svg)
#assert(not over.svg.contains("#008080"), message: over.svg)
#assert(over.svg.contains("fill=\"#001f3f\""), message: over.svg)

// A palette color may read the theme's own values.
#let accent = render(themed((pie1: "var(--pele-accent)")), theme: (accent: rgb("#123456")))
#assert(accent.svg.contains("fill=\"#123456\""), message: accent.svg)

// The config option sets a palette as the source does.
#let option = render(pie, config: (themeVariables: (pie2: "#00ff00")), theme: (series-2: teal))
#assert(option.svg.contains("fill=\"#00ff00\""), message: option.svg)
