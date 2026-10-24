#import "../lib.typ": mermaid

#set page(width: 16cm, height: auto, margin: 1cm)

= Charts

Charts take their colors from pele's eight series colors.

#mermaid(```
pie showData
  title Key elements in Product X
  "Calcium" : 42.96
  "Potassium" : 50.05
  "Magnesium" : 10.01
  "Iron" : 5
```)

The theme replaces any of them.

#mermaid(theme: (series-1: rgb("#2a9d8f"), series-2: rgb("#e76f51")), ```
xychart-beta
  title "Sales Revenue"
  x-axis [jan, feb, mar, apr, may, jun]
  y-axis "Revenue (in $)" 4000 --> 11000
  bar [5000, 6000, 7500, 8200, 9500, 10500]
  line [5000, 6000, 7500, 8200, 9500, 10500]
```)
