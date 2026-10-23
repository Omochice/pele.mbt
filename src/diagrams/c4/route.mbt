///|
/// A laid out shape or boundary: top-left corner, size, and the shared shape it is drawn as.
/// `id` tells boxes apart, as pele does by object identity.
pub(all) struct Box {
  id : Int32
  mut x : Double
  mut y : Double
  mut w : Double
  mut h : Double
  form : String
}

///|
/// How a relation is drawn: its path, its markers, and where its label goes.
pub(all) struct Route {
  d : String
  // Where the markers go: the tip, and the way it points.
  sx : Double
  sy : Double
  sdx : Double
  sdy : Double
  ex : Double
  ey : Double
  edx : Double
  edy : Double
  // The stretch the label may sit on.
  x0 : Double
  y0 : Double
  x1 : Double
  y1 : Double
  // The side of that stretch the label is pushed to, as a unit vector; zero centers it on the stretch.
  nx : Double
  ny : Double
  // When set, the label stays over the line and moves that way by at most this much.
  lean : Double
  // The widest the label should be.
  room : Double
  // The corners of the line, as x, y pairs.
  points : Array[Double]
}

///|
pub const LANE : Double = 20

///|
/// The shared person shape: a head of radius 13 centered 14 below the top, over a body that starts 26 below it.
pub const HEAD : Double = 26

///|
/// What the routes drawn so far take up, so that the next keeps apart from them: upright stretches as x, top, bottom;
/// level ones as y, left, right; and where lines leave or reach each side of a shape.
pub struct Lanes {
  upright : Array[Double]
  level : Array[Double]
  upright_frames : Array[Double]
  level_frames : Array[Double]
  taken : Map[Int32, Array[Double]]
  // Routes that found no lane of their own: a line left straight behind a shape, or a lane that runs along another.
  mut squeezed : Int32
}

///|
/// Lanes with nothing taken.
pub fn Lanes::new() -> Lanes {
  {
    upright: [],
    level: [],
    upright_frames: [],
    level_frames: [],
    taken: {},
    squeezed: 0,
  }
}

///|
/// Marks the frame of a boundary, which lines keep a little apart from.
pub fn Lanes::frame(self : Lanes, box : Box) -> Unit {
  self.squeezed = 0
  ignore(box)
}

///|
/// Routes a relation from a to b.
pub fn route(
  a : Box,
  b : Box,
  shift : Double,
  others : Array[Box]?,
  lanes : Lanes,
  start_trim : Double,
  end_trim : Double,
) -> Route {
  ignore((a, b, shift, others, lanes, start_trim, end_trim))
  {
    d: "",
    sx: 0,
    sy: 0,
    sdx: 0,
    sdy: 0,
    ex: 0,
    ey: 0,
    edx: 0,
    edy: 0,
    x0: 0,
    y0: 0,
    x1: 0,
    y1: 0,
    nx: 0,
    ny: 0,
    lean: 0,
    room: 0,
    points: [],
  }
}
