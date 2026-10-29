#import "../lib.typ": font-measurer, mermaid

#set page(width: 16cm, height: auto, margin: 1cm)

= Labels measured in their own font

pele sizes its boxes with Arial's metrics unless it is given a measurer.
A diagram drawn in DejaVu Sans Mono, which is wider, then has labels that run out of their boxes.

#let source = ```
flowchart LR
  Draft[Write a draft] -->|send| Review[Review it]
  Review -->|approve| Publish[Publish it]
```

#mermaid(fontFamily: "DejaVu Sans Mono", source)

`font-measurer` measures the font with typst, so the boxes fit the labels drawn in it.

#context mermaid(fontFamily: "DejaVu Sans Mono", measurer: font-measurer("DejaVu Sans Mono"), source)

= Code in the monospace font

`monospace` names the parts of a diagram that are code, here the members of a class, so pele measures them in the monospace font and sizes their box for it.
A list of one part is written with a trailing comma, as `("members")` is only a string.

#mermaid(monospace: ("members",), ```
classDiagram
  class Account {
    +String owner
    +deposit(amount) bool
  }
```)
