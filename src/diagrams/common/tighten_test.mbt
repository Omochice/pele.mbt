///|
fn drawn(width : Double) -> @types.Rendered {
  { svg: "", width, height: 1, links: [] }
}

///|
fn widths(max_width : Double?) -> Array[Bool] {
  let calls = []
  let options = { ..@types.RenderOptions::default(), max_width, }
  tighten(options, tight => {
    calls.push(tight)
    drawn(if tight { 80 } else { 100 })
  })
  |> ignore
  calls
}

///|
test "a diagram without a width limit is drawn loosely once" {
  inspect(widths(None), content="[false]")
}

///|
test "a diagram that fits is drawn loosely once" {
  inspect(widths(Some(100)), content="[false]")
}

///|
test "a diagram that does not fit is drawn tightly as well" {
  inspect(widths(Some(90)), content="[false, true]")
}

///|
test "the narrower drawing is kept" {
  let options = { ..@types.RenderOptions::default(), max_width: Some(50), }
  let kept = tighten(options, tight => drawn(if tight { 80 } else { 100 }))
  inspect(kept.width, content="80")
  let kept = tighten(options, tight => drawn(if tight { 120 } else { 100 }))
  inspect(kept.width, content="100")
}
