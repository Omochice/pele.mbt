///|
fn model(source : String) -> String {
  let built = @radar.build_radar(@radar.parse_radar(source), Some("front")) catch {
    @errors.PeleError(failure) =>
      return "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")}"
  }
  let axes = built.axes.map(axis => "\{axis.name}[\{axis.label}]")
  let curves = built.curves.map(curve => {
    let values = curve.entries.map(value => value.to_string()).join(", ")
    "\{curve.name}[\{curve.label}][\{values}]"
  })
  let options = built.options
  let max = match options.max {
    Some(value) => "\{value}"
    None => "-"
  }
  "title=\{built.title.unwrap_or("-")} accTitle=\{built.acc_title.unwrap_or("-")} accDescr=\{built.acc_descr.unwrap_or("-")} axes=\{axes.join(",")} curves=\{curves.join(",")} legend=\{options.show_legend} ticks=\{options.ticks} max=\{max} min=\{options.min} graticule=\{options.graticule}"
}

///|
test "defaults apply when no option is given" {
  inspect(
    model("radar-beta\naxis A,B,C\ncurve mycurve{1,2,3}"),
    content="title=front accTitle=- accDescr=- axes=A[A],B[B],C[C] curves=mycurve[mycurve][1, 2, 3] legend=true ticks=5 max=- min=0 graticule=circle",
  )
}

///|
test "labels replace names for display" {
  inspect(
    model(
      "radar-beta\ntitle Radar diagram\naccTitle: Radar accTitle\naccDescr: Radar accDescription\naxis A[\"Axis A\"], B[\"Axis B\"] ,C[\"Axis C\"]\ncurve mycurve[\"My Curve\"]{1,2,3}",
    ),
    content="title=Radar diagram accTitle=Radar accTitle accDescr=Radar accDescription axes=A[Axis A],B[Axis B],C[Axis C] curves=mycurve[My Curve][1, 2, 3] legend=true ticks=5 max=- min=0 graticule=circle",
  )
}

///|
test "named entries are ordered by axis" {
  inspect(
    model("radar-beta\naxis A,B,C\ncurve mycurve{ C: 3, A: 1, B: 2 }"),
    content="title=front accTitle=- accDescr=- axes=A[A],B[B],C[C] curves=mycurve[mycurve][1, 2, 3] legend=true ticks=5 max=- min=0 graticule=circle",
  )
}

///|
test "the first of repeated named entries wins and extra ones are ignored" {
  inspect(
    model("radar-beta\naxis A,B\ncurve c{ A 1, A 9, B 2, X 5 }"),
    content="title=front accTitle=- accDescr=- axes=A[A],B[B] curves=c[c][1, 2] legend=true ticks=5 max=- min=0 graticule=circle",
  )
}

///|
test "a named entry needs axes declared before the curve" {
  inspect(
    model("radar-beta\ncurve c{ B: 2 }"),
    content="semantic: Axes must be populated before curves for reference entries radar",
  )
}

///|
test "a missing named entry is reported with the label of its axis" {
  inspect(
    model("radar-beta\naxis A[\"Alpha\"], B\ncurve c{ B: 2 }"),
    content="semantic: Missing entry for axis Alpha radar",
  )
}

///|
test "numbered entries are not checked against the axes" {
  inspect(
    model("radar-beta\ncurve c{1,2,3}"),
    content="title=front accTitle=- accDescr=- axes= curves=c[c][1, 2, 3] legend=true ticks=5 max=- min=0 graticule=circle",
  )
}

///|
test "the last value of a repeated option wins and ticks are capped at 32" {
  inspect(
    model(
      "radar-beta\nticks 3\nticks 100\nmax 5\nmax 7\ngraticule polygon\nshowLegend false\nmin 2",
    ),
    content="title=front accTitle=- accDescr=- axes= curves= legend=false ticks=32 max=7 min=2 graticule=polygon",
  )
  inspect(
    model("radar-beta\nticks 33"),
    content="title=front accTitle=- accDescr=- axes= curves= legend=true ticks=32 max=- min=0 graticule=circle",
  )
  inspect(
    model("radar-beta\nticks 32"),
    content="title=front accTitle=- accDescr=- axes= curves= legend=true ticks=32 max=- min=0 graticule=circle",
  )
  inspect(
    model("radar-beta\nticks 12"),
    content="title=front accTitle=- accDescr=- axes= curves= legend=true ticks=12 max=- min=0 graticule=circle",
  )
}

///|
test "the chart's own title wins over the front matter title" {
  inspect(
    model("radar-beta\ntitle own"),
    content="title=own accTitle=- accDescr=- axes= curves= legend=true ticks=5 max=- min=0 graticule=circle",
  )
  inspect(
    model("radar-beta\ntitle\naxis A"),
    content="title=front accTitle=- accDescr=- axes=A[A] curves= legend=true ticks=5 max=- min=0 graticule=circle",
  )
}

///|
test "accessibility text is trimmed as pele does" {
  inspect(
    model("radar-beta\naccDescr {\n a\n  b\n}"),
    content="title=front accTitle=- accDescr=a\nb axes= curves= legend=true ticks=5 max=- min=0 graticule=circle",
  )
}
