///|
fn capped(max_width : Double?, around~ : Double = 0) -> Double {
  let options = { ..@types.RenderOptions::default(), max_width, }
  @common.cap_width(options, 640, 200, around~)
}

///|
test "a chart keeps its own width when the host sets no limit" {
  inspect(capped(None), content="640")
  inspect(capped(Some(0)), content="640")
  inspect(capped(Some(-5)), content="640")
}

///|
test "a chart keeps its own width when it fits" {
  inspect(capped(Some(1000)), content="640")
}

///|
test "a chart is narrowed to the host's width minus what it adds around itself" {
  inspect(capped(Some(500)), content="500")
  inspect(capped(Some(500), around=16), content="484")
}

///|
test "a chart is never narrowed below its least width" {
  inspect(capped(Some(100), around=16), content="200")
}

///|
test "the least width never exceeds the natural width" {
  let options = { ..@types.RenderOptions::default(), max_width: Some(10), }
  inspect(@common.cap_width(options, 150, 200), content="150")
}
