#import "../lib.typ": font-measurer, mermaid, render

#let flowchart = "graph LR\nA[Hello world]"

// A measurer written as data reaches pele, which lays the labels out with it.
#assert.eq(render(flowchart).width, 132)
#assert.eq(render(flowchart, measurer: (:)).width, 64)
#assert.eq(render(flowchart, measurer: (styles: ("0": (default: 2000)))).width, 212)

#context {
  let serif = font-measurer("Libertinus Serif", font-mono: "DejaVu Sans Mono")
  let styles = serif.styles

  // Every one of pele's eight styles has a table of its own.
  assert.eq(styles.keys(), range(8).map(str))

  // The advances are the font's own, so a proportional font's differ and a monospace font's do not.
  let regular = styles.at("0").advances
  assert(regular.at("i") < regular.at("W"), message: repr(regular))
  let mono = styles.at("4").advances
  assert.eq(mono.at("i"), mono.at("W"))

  // Bold and italic are measured in their own faces.
  assert(styles.at("1").advances.at("a") > regular.at("a"), message: repr(styles.at("1")))
  assert(styles.at("2").advances.at("a") != regular.at("a"), message: repr(styles.at("2")))

  // Labels are laid out with those advances.
  let measured = render(flowchart, fontFamily: "Libertinus Serif", measurer: serif)
  assert(measured.width != render(flowchart, fontFamily: "Libertinus Serif").width, message: repr(measured.width))
}

// mermaid takes a measurer as it takes any other option.
#context mermaid(flowchart, fontFamily: "Libertinus Serif", measurer: font-measurer("Libertinus Serif"))
