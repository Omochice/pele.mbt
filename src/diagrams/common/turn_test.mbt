///|
fn turns(
  options : @types.RenderOptions,
  across : Double,
  down : Double,
) -> String {
  let calls = []
  let kept = @common.turn_to_fit(options, turned => {
    calls.push(if turned { "down" } else { "across" })
    {
      svg: "",
      width: if turned {
        down
      } else {
        across
      },
      height: 1,
      links: [],
    }
  })
  calls.join(" ") + " -> " + kept.width.to_string()
}

///|
fn narrow(max_width : Double) -> @types.RenderOptions {
  { ..@types.RenderOptions::default(), max_width: Some(max_width), }
}

///|
test "a diagram that runs across stays across when it fits or nothing limits it" {
  inspect(
    turns(@types.RenderOptions::default(), 900, 300),
    content="across -> 900",
  )
  inspect(turns(narrow(500), 500, 300), content="across -> 500")
}

///|
test "a diagram too wide for a host under the breakpoint is turned when down is narrower" {
  inspect(turns(narrow(400), 900, 300), content="across down -> 300")
  inspect(turns(narrow(400), 900, 950), content="across down -> 900")
}

///|
test "a host at or past the breakpoint, or without auto direction, keeps the diagram across" {
  inspect(turns(narrow(640), 900, 300), content="across -> 900")
  inspect(
    turns({ ..narrow(700), direction_breakpoint: Some(800), }, 900, 300),
    content="across down -> 300",
  )
  inspect(
    turns({ ..narrow(400), direction_breakpoint: Some(300), }, 900, 300),
    content="across -> 900",
  )
  inspect(
    turns({ ..narrow(400), auto_direction: Some(false), }, 900, 300),
    content="across -> 900",
  )
}

///|
test "only LR and RL run across" {
  inspect(
    [Some("LR"), Some("RL"), Some("TB"), Some("TD"), Some("BT"), None]
    .map(dir => @common.runs_across(dir).to_string())
    .join(" "),
    content="true true false false false false",
  )
}
