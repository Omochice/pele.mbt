#import "../lib.typ": mermaid

#set page(width: 18cm, height: auto, margin: 1cm)

= Gantt chart

Without `now` the chart is drawn as of the Unix epoch, as a plugin cannot read the clock.
It is given here in milliseconds, as pele takes it.

#mermaid(now: 1500940800000, ```
gantt
  title A release
  dateFormat YYYY-MM-DD
  section Build
    Design      :done, a1, 2017-07-17, 4d
    Implement   :active, a2, after a1, 6d
    Review      :crit, a3, after a2, 2d
  section Ship
    Release     :milestone, m1, after a3, 0d
```)
