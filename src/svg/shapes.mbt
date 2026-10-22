///|
/// The size of a node's shape around a label of a given size.
pub(all) struct ShapeSize {
  w : Double
  h : Double
  /// Vertical shift of the label from the shape's center.
  dy : Double
}

///|
/// Horizontal room between a label and the sides of a rectangular shape.
pub const PAD_X : Double = 18

///|
/// Vertical room between a label and the top and bottom of a rectangular shape.
pub const PAD_Y : Double = 12

///|
priv struct ShapeDef {
  size : (Double, Double) -> ShapeSize
  draw : (Double, Double, String, String) -> String
}

///|
fn ShapeDef::new(
  size~ : (Double, Double) -> ShapeSize,
  draw~ : (Double, Double, String, String) -> String,
) -> ShapeDef {
  { size, draw, }
}

///|
fn box_size(tw : Double, th : Double) -> ShapeSize {
  { w: @util.js_max(tw + 2 * PAD_X, 2 * PAD_X + 12), h: th + 2 * PAD_Y, dy: 0, }
}

///|
fn poly(points : Array[Double], a : String) -> String {
  let d = StringBuilder()
  for i = 0; i < points.length(); i = i + 2 {
    if i > 0 {
      d.write_string(" ")
    }
    d.write_string(num(points[i]) + "," + num(points[i + 1]))
  }
  "<polygon points=\"\{d}\"\{a}/>"
}

///|
fn rect(w : Double, h : Double, a : String, rx~ : String = "") -> String {
  "<rect x=\"\{num(-w / 2)}\" y=\"\{num(-h / 2)}\" width=\"\{num(w)}\" height=\"\{num(h)}\"\{rx}\{a}/>"
}

///|
let rect_shape : ShapeDef = ShapeDef::new(size=box_size, draw=(w, h, a, _) => {
  rect(w, h, rounded(a))
})

///|
let shapes : Map[String, ShapeDef] = {
  "rect": rect_shape,
  "rounded": ShapeDef::new(size=box_size, draw=(w, h, a, _) => {
    rect(w, h, a, rx=" rx=\"\{num(@util.js_min(12, h / 2))}\"")
  }),
  "stadium": ShapeDef::new(
    size=(tw, th) => {
      let h = th + 2 * PAD_Y
      { w: tw + h * 0.5 + 2 * PAD_X - 8, h, dy: 0, }
    },
    draw=(w, h, a, _) => rect(w, h, a, rx=" rx=\"\{num(h / 2)}\""),
  ),
  "fr-rect": ShapeDef::new(
    size=(tw, th) => { w: tw + 2 * PAD_X + 16, h: th + 2 * PAD_Y, dy: 0, },
    draw=(w, h, a, line) => {
      let x = w / 2 - 8
      rect(w, h, rounded(a)) +
      "<path d=\"M\{num(-x)},\{num(-h / 2)}V\{num(h / 2)}M\{num(x)},\{num(-h / 2)}V\{num(h / 2)}\" fill=\"none\"\{line}/>"
    },
  ),
  "text": ShapeDef::new(size=(tw, th) => { w: tw + 8, h: th + 8, dy: 0, }, draw=(
    w,
    h,
    _,
    _,
  ) => rect(w, h, " fill=\"none\" stroke=\"none\"")),
  "notch-rect": ShapeDef::new(size=box_size, draw=(w, h, a, _) => {
    let c = 10.0
    poly(
      [
        -w / 2 + c,
        -h / 2,
        w / 2,
        -h / 2,
        w / 2,
        h / 2,
        -w / 2,
        h / 2,
        -w / 2,
        -h / 2 + c,
      ],
      a,
    )
  }),
  "lin-rect": ShapeDef::new(
    size=(tw, th) => { w: tw + 2 * PAD_X + 8, h: th + 2 * PAD_Y, dy: 0, },
    draw=(w, h, a, line) => {
      rect(w, h, rounded(a)) +
      "<path d=\"M\{num(-w / 2 + 8)},\{num(-h / 2)}V\{num(h / 2)}\" fill=\"none\"\{line}/>"
    },
  ),
  "div-rect": ShapeDef::new(
    size=(tw, th) => { w: tw + 2 * PAD_X, h: th + 2 * PAD_Y + 8, dy: 4, },
    draw=(w, h, a, line) => {
      rect(w, h, rounded(a)) +
      "<path d=\"M\{num(-w / 2)},\{num(-h / 2 + 8)}H\{num(w / 2)}\" fill=\"none\"\{line}/>"
    },
  ),
  "win-pane": ShapeDef::new(
    size=(tw, th) => { w: tw + 2 * PAD_X + 8, h: th + 2 * PAD_Y + 8, dy: 4, },
    draw=(w, h, a, line) => {
      rect(w, h, rounded(a)) +
      "<path d=\"M\{num(-w / 2 + 8)},\{num(-h / 2)}V\{num(h / 2)}M\{num(-w / 2)},\{num(-h / 2 + 8)}H\{num(w / 2)}\" fill=\"none\"\{line}/>"
    },
  ),
  "st-rect": ShapeDef::new(
    size=(tw, th) => { w: tw + 2 * PAD_X + 8, h: th + 2 * PAD_Y + 8, dy: 4, },
    draw=(w, h, a, _) => {
      let bw = w - 8
      let bh = h - 8
      let out = StringBuilder()
      for i in 0..<3 {
        let x = -w / 2 + (2 - i).to_double() * 4
        let y = -h / 2 + i.to_double() * 4
        out.write_string(
          "<rect x=\"\{num(x)}\" y=\"\{num(y)}\" width=\"\{num(bw)}\" height=\"\{num(bh)}\"\{rounded(a)}/>",
        )
      }
      out.to_string()
    },
  ),
  "tag-rect": ShapeDef::new(size=box_size, draw=(w, h, a, line) => {
    rect(w, h, rounded(a)) +
    "<path d=\"M\{num(w / 2 - 12)},\{num(h / 2)}L\{num(w / 2)},\{num(h / 2 - 12)}\" fill=\"none\"\{line}/>"
  }),
  "datastore": ShapeDef::new(size=box_size, draw=(w, h, a, line) => {
    rect(w, h, a.replace(old="stroke=\"var(--_b)\"", new="stroke=\"none\"")) +
    "<path d=\"M\{num(-w / 2)},\{num(-h / 2)}H\{num(w / 2)}M\{num(-w / 2)},\{num(h / 2)}H\{num(w / 2)}\" fill=\"none\"\{line}/>"
  }),
  "console": ShapeDef::new(
    size=(tw, th) => {
      w: @util.js_max(tw + 2 * PAD_X, 72),
      h: th + 2 * PAD_Y + 12,
      dy: 6,
    },
    draw=(w, h, a, line) => {
      rect(w, h, rounded(a)) +
      "<path d=\"M\{num(-w / 2)},\{num(-h / 2 + 12)}H\{num(w / 2)}M\{num(-w / 2 + 7)},\{num(-h / 2 + 4)}l3,2.5l-3,2.5M\{num(-w / 2 + 13)},\{num(-h / 2 + 9)}h4\" fill=\"none\"\{line}/>"
    },
  ),
  "browser": ShapeDef::new(
    size=(tw, th) => {
      w: @util.js_max(tw + 2 * PAD_X, 72),
      h: th + 2 * PAD_Y + 12,
      dy: 6,
    },
    draw=(w, h, a, line) => {
      let dots = StringBuilder()
      for i in 0..<3 {
        dots.write_string(
          "<circle cx=\"\{num(-w / 2 + 8 + i.to_double() * 7)}\" cy=\"\{num(-h / 2 + 6)}\" r=\"1.5\" fill=\"none\"\{line}/>",
        )
      }
      rect(w, h, rounded(a)) +
      "<path d=\"M\{num(-w / 2)},\{num(-h / 2 + 12)}H\{num(w / 2)}\" fill=\"none\"\{line}/>" +
      dots.to_string()
    },
  ),
  "collapsedGroup": ShapeDef::new(
    size=(tw, th) => { w: tw + 2 * PAD_X + 8, h: th + 2 * PAD_Y + 8, dy: -2, },
    draw=(w, h, a, _) => {
      "<rect x=\"\{num(-w / 2 + 6)}\" y=\"\{num(-h / 2 + 8)}\" width=\"\{num(w - 12)}\" height=\"\{num(h - 8)}\"\{rounded(a)}/>" +
      "<rect x=\"\{num(-w / 2)}\" y=\"\{num(-h / 2)}\" width=\"\{num(w)}\" height=\"\{num(h - 4)}\"\{rounded(a)}/>"
    },
  ),
}

///|
/// Unknown names fall back to a rectangle; a Map lookup also keeps names like `constructor` from
/// reaching anything but the table, as pele guards against with its own Map.
fn shape_def(shape : String) -> ShapeDef {
  shapes.get(shape).unwrap_or(rect_shape)
}

///|
/// The size of the named shape around a label `tw` wide and `th` high.
pub fn shape_size(shape : String, tw : Double, th : Double) -> ShapeSize {
  (shape_def(shape).size)(tw, th)
}

///|
/// The outline of the named shape, `w` by `h` and centered on the origin.
/// `a` carries the fill and border attributes, and `line` the attributes of inner strokes.
pub fn draw_shape(
  shape : String,
  w : Double,
  h : Double,
  a : String,
  line : String,
) -> String {
  (shape_def(shape).draw)(w, h, a, line)
}
