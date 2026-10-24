#import "../lib.typ": mermaid

#set page(width: 16cm, height: auto, margin: 1cm)
#show raw.where(lang: "mermaid"): it => mermaid(it)

= Flowchart

A raw block tagged `mermaid` is drawn through the show rule above.

```mermaid
flowchart LR
  start([Start]) --> input[/Read the order/]
  input --> check{In stock?}
  check -- yes --> ship[Ship it]
  check -- no --> order[(Back order)]
  subgraph fulfilment [Fulfilment]
    ship --> invoice>Send the invoice]
  end
  order -.-> check
  invoice --> stop((Done))
```

A call with a width scales the diagram to it.

#mermaid("graph TD\n  A[Christmas] -->|Get money| B(Go shopping)\n  B --> C{Let me think}\n  C -->|One| D[Laptop]\n  C -->|Two| E[iPhone]\n  C -->|Three| F[fa:fa-car Car]", width: 60%)
