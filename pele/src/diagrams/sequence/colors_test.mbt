// The expected answers were taken from pele's isCssColor.

///|
test "recognizes color keywords and the rgb() and hsl() notations" {
  let inputs = [
    "red",
    "Aqua",
    "GrayText",
    "TRANSPARENT",
    "currentColor",
    "notacolor",
    "",
    "blac\u{212a}",
    "red ",
    "rgb(1, 2, 3)",
    "rgb(1,2)",
    "rgba(1, 2, 3, 0.5)",
    "rgba(1, 2, 3, 50%)",
    "rgb(10%, 20%, 30%)",
    "rgb(10%, 20, 30)",
    "rgb(1 2 3)",
    "rgb(1 2 3 / .5)",
    "rgb(1 2 3 / none)",
    "rgb(1, 2, 3, none)",
    "rgb(none 2 3)",
    "rgb(1 2 3 / 4 / 5)",
    "hsl(120, 50%, 50%)",
    "hsl(120deg, 50%, 50%)",
    "hsl(120, 50, 50%)",
    "hsl(120deg 50% 50% / 0.5)",
    "hsl(1turn 50% 50%)",
    "hsla(2.5rad, 1%, 1%, 1)",
    "hsl(120 50 50)",
    "rgb(1e2, 2E-1, +3)",
    "rgb(.5, 1., 3)",
    "rgb(1, 2, 3)x",
    "rgb(1, 2, 3))",
    "RGB(1, 2, 3)",
    "calc(1)",
    "rgb (1, 2, 3)",
    "rgb(  1 ,2 ,  3  )",
    "rgb()",
    "rgb(1  2   3)",
    "hsl(10DEG 5% 5%)",
    "rgb(" + "1, ".repeat(40) + ")",
    "rgb(1, 2, 3, 4, 5)",
    "hsl(1grad 2% 3%)",
    "rgb(-1, -2, -3)",
    "rgb(1 2 3 /)",
  ]
  inspect(
    inputs.map(color => "\{color} \{@sequence.is_css_color(color)}").join("\n"),
    content=(
      #|red true
      #|Aqua true
      #|GrayText true
      #|TRANSPARENT true
      #|currentColor true
      #|notacolor false
      #| false
      #|blacK true
      #|red  false
      #|rgb(1, 2, 3) true
      #|rgb(1,2) false
      #|rgba(1, 2, 3, 0.5) true
      #|rgba(1, 2, 3, 50%) true
      #|rgb(10%, 20%, 30%) true
      #|rgb(10%, 20, 30) false
      #|rgb(1 2 3) true
      #|rgb(1 2 3 / .5) true
      #|rgb(1 2 3 / none) true
      #|rgb(1, 2, 3, none) false
      #|rgb(none 2 3) true
      #|rgb(1 2 3 / 4 / 5) false
      #|hsl(120, 50%, 50%) true
      #|hsl(120deg, 50%, 50%) true
      #|hsl(120, 50, 50%) false
      #|hsl(120deg 50% 50% / 0.5) true
      #|hsl(1turn 50% 50%) true
      #|hsla(2.5rad, 1%, 1%, 1) true
      #|hsl(120 50 50) true
      #|rgb(1e2, 2E-1, +3) true
      #|rgb(.5, 1., 3) false
      #|rgb(1, 2, 3)x false
      #|rgb(1, 2, 3)) false
      #|RGB(1, 2, 3) false
      #|calc(1) false
      #|rgb (1, 2, 3) false
      #|rgb(  1 ,2 ,  3  ) true
      #|rgb() false
      #|rgb(1  2   3) true
      #|hsl(10DEG 5% 5%) true
      #|rgb(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, ) false
      #|rgb(1, 2, 3, 4, 5) false
      #|hsl(1grad 2% 3%) true
      #|rgb(-1, -2, -3) true
      #|rgb(1 2 3 /) false
    ),
  )
}
