///|
/// A number as JavaScript's `String` writes it, which writes -0 as 0.
fn js_number(value : Double) -> String {
  if value == 0.0 {
    "0"
  } else {
    value.to_string()
  }
}

///|
/// Every field of a path, the numbers as pele's own output writes them in Node.
fn describe_path(path : @svg.EdgePath) -> String {
  [path.sx, path.sy, path.sdx, path.sdy, path.ex, path.ey, path.edx, path.edy].fold(
    init=path.d,
    (out, value) => out + " " + js_number(value),
  )
}
