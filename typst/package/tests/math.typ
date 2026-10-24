#import "../lib.typ": mermaid, render

// TeX between `$$` is drawn from the markup the document gives for it at the label's font size.
#let math = (
  "x^2": (
    "16": (svg: "<text x=\"0\" y=\"16\" font-size=\"16\" fill=\"currentColor\">x²</text>", width: 18, height: 20),
  ),
)
#let source = "graph LR\n  A[\"$$x^2$$ grows\"] --> B[\"$$y$$\"]"

#let typeset = render(source, math: math)
#assert(typeset.svg.contains("<svg class=\"pele-math\""), message: typeset.svg)
#assert(typeset.svg.contains(">x²</text></svg>"), message: typeset.svg)

// TeX without markup stays as its text.
#assert(typeset.svg.contains("$$y$$"), message: typeset.svg)

// A size the map does not hold leaves the TeX as text too.
#let other = render(source, math: math, fontSize: 20)
#assert(not other.svg.contains("pele-math"), message: other.svg)

// Without the option the TeX is text.
#assert(not render(source).svg.contains("pele-math"))

// The README's example compiles as written.
#let readme-math = ("x^2": ("16": (svg: "<text y=\"16\" fill=\"currentColor\">x²</text>", width: 18, height: 20)))
#assert(render(math: readme-math, "graph LR\n  A[\"$$x^2$$ grows\"]").svg.contains("pele-math"))

// typst draws the nested markup.
#mermaid(source, math: math)
