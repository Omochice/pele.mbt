///|
fn drawn(width : Double) -> @types.Rendered {
  { svg: "", width, height: 1, links: [], }
}

///|
fn widths(max_width : Double?) -> String {
  let calls = []
  let options = { ..@types.RenderOptions::default(), max_width, }
  @common.tighten(options, tight => {
    calls.push(tight)
    drawn(if tight { 80 } else { 100 })
  })
  |> ignore
  calls.map(tight => if tight { "tight" } else { "loose" }).join(" ")
}

///|
test "a diagram without a width limit is drawn loosely once" {
  inspect(widths(None), content="loose")
}

///|
test "a diagram that fits is drawn loosely once" {
  inspect(widths(Some(100)), content="loose")
}

///|
test "a diagram that does not fit is drawn tightly as well" {
  inspect(widths(Some(90)), content="loose tight")
}

///|
test "the narrower drawing is kept" {
  let options = { ..@types.RenderOptions::default(), max_width: Some(50), }
  let kept = @common.tighten(options, tight => {
    drawn(if tight { 80 } else { 100 })
  })
  inspect(kept.width, content="80")
  let kept = @common.tighten(options, tight => {
    drawn(if tight { 120 } else { 100 })
  })
  inspect(kept.width, content="100")
}
