///|
test "seeded_random is mulberry32 on a 32-bit truncated seed" {
  inspect(@cynefin.seeded_random(42), content="0.6011037519201636")
  inspect(@cynefin.seeded_random(0), content="0.26642920868471265")
  inspect(@cynefin.seeded_random(-50), content="0.2312965493183583")
  inspect(@cynefin.seeded_random(1.0e15 + 3), content="0.3180053129326552")
}

///|
test "seeded_random truncates a fractional seed after the offset is added" {
  inspect(@cynefin.seeded_random(0.5), content="0.26642920868471265")
}

///|
test "hash_string wraps to 32 bits" {
  inspect(@cynefin.hash_string("cynefin"), content="1237376062")
  inspect(@cynefin.hash_string("pele"), content="3437102")
  inspect(@cynefin.hash_string(""), content="0")
  inspect(@cynefin.hash_string("mermaid-1"), content="1795732973")
}

///|
test "a configured nonzero finite seed wins over the id" {
  inspect(@cynefin.resolve_seed(Some(42), "x"), content="42")
  inspect(@cynefin.resolve_seed(Some(-3), "y"), content="-3")
  inspect(@cynefin.resolve_seed(Some(0), "pele"), content="3437102")
  inspect(@cynefin.resolve_seed(None, "pele"), content="3437102")
  inspect(
    @cynefin.resolve_seed(Some(@double.not_a_number), "pele"),
    content="3437102",
  )
  inspect(@cynefin.resolve_seed(Some(@double.infinity), "a"), content="97")
}

///|
test "a vertical fold wave" {
  inspect(
    @cynefin.curve_path(@cynefin.wave(0, 600, 400, 42, 9, @cynefin.fold)),
    content="M401.82,0C406.87,42.86 393.07,42.86 398.12,85.71C387.52,128.57 409.67,128.57 399.08,171.43C412.44,214.29 382.16,214.29 395.53,257.14C386.72,300 402.1,300 393.29,342.86C393.98,385.71 394.67,385.71 395.35,428.57C387.37,471.43 400.12,471.43 392.14,514.29C397.55,557.14 390.81,557.14 396.23,600",
  )
}

///|
test "a horizontal wave can pin either end to the center line" {
  let pin_start = { ..@cynefin.horizon, segments: 4, pin_start: true, }
  let pin_end = { ..@cynefin.horizon, segments: 4, pin_end: true, }
  inspect(
    @cynefin.curve_path(@cynefin.wave(0, 800, 300, 42, 12, pin_start)),
    content="M0,300C100,301.16 100,289.43 200,290.58C300,289.84 300,308.85 400,308.11C500,312.46 500,307.41 600,311.76C700,307.48 700,307.31 800,303.03",
  )
  inspect(
    @cynefin.curve_path(@cynefin.wave(0, 800, 300, 42, 12, pin_end)),
    content="M0,302.43C100,303.58 100,289.43 200,290.58C300,289.84 300,308.85 400,308.11C500,312.46 500,307.41 600,311.76C700,307.48 700,304.28 800,300",
  )
}

///|
test "the cliff is a steep S and can be walked in both directions" {
  let curve = @cynefin.cliff(400, 300, 600, 24)
  inspect(
    @cynefin.curve_path(curve),
    content="M400,300C424,360 364,465 412,525C376,555 407.2,585 400,600",
  )
  inspect(
    @cynefin.forward(curve),
    content="C424,360 364,465 412,525C376,555 407.2,585 400,600",
  )
  inspect(
    @cynefin.backward(curve),
    content="C407.2,585 376,555 412,525C364,465 424,360 400,300",
  )
}

///|
test "an ellipse is two arcs closed" {
  inspect(
    @cynefin.ellipse_path(400, 300, 50, 40),
    content="M350,300A50,40 0 1,1 450,300A50,40 0 1,1 350,300Z",
  )
}
