// The expected markers were taken from pele's erMarker.

///|
test "each cardinality has its marker, drawn back along the line from the box" {
  let drawn = [
    "only_one", "zero_or_one", "one_or_more", "zero_or_more", "md_parent", "other",
  ].map(kind => "\{kind} [\{@er.er_marker(kind, 10.25, -4, 0, 1)}]")
  inspect(
    drawn.join("\n"),
    content=(
      #|only_one [<path class="pele-marker" d="M15.25,-10L5.25,-10M15.25,-14L5.25,-14"/>]
      #|zero_or_one [<path class="pele-marker" d="M15.25,-10L5.25,-10"/><circle class="pele-marker" cx="10.25" cy="-17.5" r="3.5" fill="var(--_bg)"/>]
      #|one_or_more [<path class="pele-marker" d="M16.25,-4L10.25,-14L4.25,-4M15.25,-17.5L5.25,-17.5"/>]
      #|zero_or_more [<path class="pele-marker" d="M16.25,-4L10.25,-14L4.25,-4"/><circle class="pele-marker" cx="10.25" cy="-18" r="3.5" fill="var(--_bg)"/>]
      #|md_parent [<path class="pele-marker" d="M10.25,-4L6.25,-10L10.25,-16L14.25,-10Z" fill="var(--_bg)"/>]
      #|other []
    ),
  )
}

///|
test "a marker turns with a slanted line" {
  inspect(
    @er.er_marker("one_or_more", 3, 7, 0.6, -0.8),
    content=(
      #|<path class="pele-marker" d="M-1.8,3.4L-3,15L7.8,10.6M-9.1,14.8L-1.1,20.8"/>
    ),
  )
  inspect(
    @er.er_marker("zero_or_one", 0, 0, -1, 0),
    content=(
      #|<path class="pele-marker" d="M6,5L6,-5"/><circle class="pele-marker" cx="13.5" cy="0" r="3.5" fill="var(--_bg)"/>
    ),
  )
}
