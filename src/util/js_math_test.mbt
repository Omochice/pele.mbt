///|
test "js_hypot rounds as V8's Math.hypot does" {
  inspect(@util.js_hypot(3, 4), content="5")
  inspect(@util.js_hypot(0.1, 0.2), content="0.223606797749979")
  inspect(
    @util.js_hypot(1.7841241161527712, 3.835866849728458),
    content="4.230481456132816",
  )
  inspect(
    @util.js_hypot(2.2647835454917606, 1.9613600844688546),
    content="2.9960270173811687",
  )
  inspect(@util.js_hypot(1.0e-200, 3.0e-200), content="3.1622776601683794e-200")
  inspect(@util.js_hypot(5, 12), content="13")
  inspect(@util.js_hypot(0.3, 0.7), content="0.7615773105863908")
  inspect(@util.js_hypot(123.456, 78.9), content="146.51482497003502")
  inspect(@util.js_hypot(1, 1), content="1.4142135623730951")
  inspect(@util.js_hypot(-2.5, 0.1), content="2.5019992006393608")
}

///|
test "js_hypot of nothing, infinity and NaN" {
  inspect(@util.js_hypot(0, 0), content="0")
  inspect(
    @util.js_hypot(@double.infinity, @double.not_a_number),
    content="Infinity",
  )
  inspect(@util.js_hypot(@double.not_a_number, 1), content="NaN")
}
