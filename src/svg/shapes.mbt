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
  no_label : Bool
}

///|
fn ShapeDef::new(
  size~ : (Double, Double) -> ShapeSize,
  draw~ : (Double, Double, String, String) -> String,
  no_label~ : Bool = false,
) -> ShapeDef {
  { size, draw, no_label, }
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
fn fixed(w : Double, h : Double) -> (Double, Double) -> ShapeSize {
  (_, _) => { w, h, dy: 0, }
}

///|
fn tri_size(tw : Double, th : Double, flip : Bool) -> ShapeSize {
  let w = @util.js_max(1.6 * tw + 40, 80)
  let h = (th + 10) / (1 - (tw + 8) / w)
  let dy = h / 2 - 10 - th / 2
  { w, h, dy: if flip { -dy } else { dy }, }
}

///|
/// The width of a shape whose sides are slanted or notched by a share of its height.
fn slanted_size(share : Double) -> (Double, Double) -> ShapeSize {
  (tw, th) => {
    let h = th + 2 * PAD_Y
    { w: tw + 2 * PAD_X + h / share, h, dy: 0, }
  }
}

///|
fn path(d : String, a : String) -> String {
  "<path d=\"\{d}\"\{a}/>"
}

///|
/// The vertical radius of a cylinder's caps.
fn cap_ry(w : Double) -> Double {
  @util.js_min(12, @util.js_max(6, w / 14))
}

///|
fn cylinder_body(w : Double, h : Double, a : String) -> String {
  let rx = w / 2
  let ry = cap_ry(w)
  let top = -h / 2 + ry
  let bottom = h / 2 - ry
  path(
    "M\{num(-rx)},\{num(top)}A\{num(rx)},\{num(ry)} 0 0 1 \{num(rx)},\{num(top)}V\{num(bottom)}A\{num(rx)},\{num(ry)} 0 0 1 \{num(-rx)},\{num(bottom)}Z",
    a,
  )
}

///|
/// The front edge of a cylinder's top cap at `y`.
fn cap_arc(w : Double, y : Double) -> String {
  let rx = w / 2
  "M\{num(-rx)},\{num(y)}A\{num(rx)},\{num(cap_ry(w))} 0 0 0 \{num(rx)},\{num(y)}"
}

///|
/// A page whose bottom edge waves.
fn wave(w : Double, h : Double, a : String) -> String {
  let x = w / 2
  let top = -h / 2
  let base = h / 2 - 10
  let q = w / 4
  "<path d=\"M\{num(-x)},\{num(top)}H\{num(x)}V\{num(base)}q\{num(-q)},-12 \{num(-2 * q)},0t\{num(-2 * q)},0Z\"\{a}/>"
}

///|
/// A curly brace at `x`, opening to the left when `dir` is -1 and to the right when 1.
fn brace(x : Double, h : Double, dir : Double, line : String) -> String {
  let y = h / 2
  let k = 6.0 * dir
  "<path d=\"M\{num(x)},\{num(-y)}q\{num(k)},0 \{num(k)},6V-6q0,6 \{num(k)},6q\{num(-k)},0 \{num(-k)},6V\{num(y - 6)}q0,6 \{num(-k)},6\" fill=\"none\"\{line}/>"
}

///|
let hidden_box = " fill=\"none\" stroke=\"none\""

///|
/// `Math.SQRT1_2`.
const SQRT1_2 : Double = 0.7071067811865476

///|
/// The diameter of a circle around the label's diagonal.
fn circle_size(room : Double, least : Double) -> (Double, Double) -> ShapeSize {
  (tw, th) => {
    let d = @util.js_max((tw * tw + th * th).sqrt() + room, least)
    { w: d, h: d, dy: 0, }
  }
}

///|
fn bang_points(w : Double, h : Double) -> Array[Double] {
  let spikes = 14
  let points = []
  for i in 0..<(spikes * 2) {
    let angle = @math.PI * i.to_double() / spikes.to_double() - @math.PI / 2
    let k = if i % 2 == 0 { 1.0 } else { 0.82 }
    points.push(@math.cos(angle) * (w / 2) * k)
    points.push(@math.sin(angle) * (h / 2) * k)
  }
  points
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
  ) => rect(w, h, hidden_box)),
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
  "diam": ShapeDef::new(
    size=(tw, th) => {
      let a = tw + 16
      let b = th + 8
      { w: a + 1.6 * b, h: a / 1.6 + b, dy: 0, }
    },
    draw=(w, h, a, _) => poly([0, -h / 2, w / 2, 0, 0, h / 2, -w / 2, 0], a),
  ),
  "hex": ShapeDef::new(size=slanted_size(2), draw=(w, h, a, _) => {
    let m = h / 4
    poly(
      [
        -w / 2 + m,
        -h / 2,
        w / 2 - m,
        -h / 2,
        w / 2,
        0,
        w / 2 - m,
        h / 2,
        -w / 2 + m,
        h / 2,
        -w / 2,
        0,
      ],
      a,
    )
  }),
  "odd": ShapeDef::new(size=slanted_size(4), draw=(w, h, a, _) => {
    let notch = h / 4
    poly(
      [
        -w / 2,
        -h / 2,
        w / 2,
        -h / 2,
        w / 2,
        h / 2,
        -w / 2,
        h / 2,
        -w / 2 + notch,
        0,
      ],
      a,
    )
  }),
  "lean-r": ShapeDef::new(size=slanted_size(2), draw=(w, h, a, _) => {
    let s = h / 4
    poly(
      [-w / 2 + s, -h / 2, w / 2, -h / 2, w / 2 - s, h / 2, -w / 2, h / 2],
      a,
    )
  }),
  "lean-l": ShapeDef::new(size=slanted_size(2), draw=(w, h, a, _) => {
    let s = h / 4
    poly(
      [-w / 2, -h / 2, w / 2 - s, -h / 2, w / 2, h / 2, -w / 2 + s, h / 2],
      a,
    )
  }),
  "trap-b": ShapeDef::new(size=slanted_size(2), draw=(w, h, a, _) => {
    let s = h / 4
    poly(
      [-w / 2 + s, -h / 2, w / 2 - s, -h / 2, w / 2, h / 2, -w / 2, h / 2],
      a,
    )
  }),
  "trap-t": ShapeDef::new(size=slanted_size(2), draw=(w, h, a, _) => {
    let s = h / 4
    poly(
      [-w / 2, -h / 2, w / 2, -h / 2, w / 2 - s, h / 2, -w / 2 + s, h / 2],
      a,
    )
  }),
  "tri": ShapeDef::new(size=(tw, th) => tri_size(tw, th, false), draw=(
    w,
    h,
    a,
    _,
  ) => poly([0, -h / 2, w / 2, h / 2, -w / 2, h / 2], a)),
  "flip-tri": ShapeDef::new(size=(tw, th) => tri_size(tw, th, true), draw=(
    w,
    h,
    a,
    _,
  ) => poly([-w / 2, -h / 2, w / 2, -h / 2, 0, h / 2], a)),
  "sl-rect": ShapeDef::new(
    size=(tw, th) => { w: tw + 2 * PAD_X, h: th + 2 * PAD_Y + 10, dy: 5, },
    draw=(w, h, a, _) => {
      poly([-w / 2, -h / 2 + 10, w / 2, -h / 2, w / 2, h / 2, -w / 2, h / 2], a)
    },
  ),
  "notch-pent": ShapeDef::new(
    size=(tw, th) => { w: tw + 2 * PAD_X, h: th + 2 * PAD_Y, dy: 0, },
    draw=(w, h, a, _) => {
      let c = 10.0
      poly(
        [
          -w / 2 + c,
          -h / 2,
          w / 2 - c,
          -h / 2,
          w / 2,
          -h / 2 + c,
          w / 2,
          h / 2,
          -w / 2,
          h / 2,
          -w / 2,
          -h / 2 + c,
        ],
        a,
      )
    },
  ),
  "hourglass": ShapeDef::new(no_label=true, size=fixed(32, 40), draw=(
    w,
    h,
    a,
    _,
  ) => poly([-w / 2, -h / 2, w / 2, -h / 2, -w / 2, h / 2, w / 2, h / 2], a)),
  "bolt": ShapeDef::new(no_label=true, size=fixed(36, 56), draw=(w, h, a, _) => {
    poly(
      [
        w * 0.15,
        -h / 2,
        -w / 2,
        h * 0.08,
        -w * 0.05,
        h * 0.08,
        -w * 0.15,
        h / 2,
        w / 2,
        -h * 0.08,
        w * 0.05,
        -h * 0.08,
      ],
      a,
    )
  }),
  "bang": ShapeDef::new(
    size=(tw, th) => { w: tw + 2 * PAD_X + 28, h: th + 2 * PAD_Y + 24, dy: 0, },
    draw=(w, h, a, _) => poly(bang_points(w, h), a),
  ),
  "circle": ShapeDef::new(size=circle_size(16, 44), draw=(w, _, a, _) => {
    "<circle r=\"\{num(w / 2)}\"\{a}/>"
  }),
  "dbl-circ": ShapeDef::new(size=circle_size(26, 54), draw=(w, _, a, line) => {
    "<circle r=\"\{num(w / 2)}\"\{a}/><circle r=\"\{num(w / 2 - 5)}\" fill=\"none\"\{line}/>"
  }),
  "ellipse": ShapeDef::new(
    size=(tw, th) => {
      w: tw * 1.3 + 2 * PAD_X,
      h: th * 1.2 + 2 * PAD_Y,
      dy: 0,
    },
    draw=(w, h, a, _) => {
      "<ellipse rx=\"\{num(w / 2)}\" ry=\"\{num(h / 2)}\"\{a}/>"
    },
  ),
  "sm-circ": ShapeDef::new(no_label=true, size=fixed(14, 14), draw=(w, _, a, _) => {
    "<circle r=\"\{num(w / 2)}\"\{a}/>"
  }),
  "f-circ": ShapeDef::new(no_label=true, size=fixed(14, 14), draw=(
    w,
    _,
    _,
    line,
  ) => "<circle r=\"\{num(w / 2)}\" fill=\"var(--_l)\"\{line}/>"),
  "fr-circ": ShapeDef::new(no_label=true, size=fixed(18, 18), draw=(
    w,
    _,
    a,
    line,
  ) => {
    "<circle r=\"\{num(w / 2)}\"\{a}/><circle r=\"\{num(w / 2 - 4)}\" fill=\"var(--_l)\"\{line}/>"
  }),
  "cross-circ": ShapeDef::new(no_label=true, size=fixed(44, 44), draw=(
    w,
    _,
    a,
    line,
  ) => {
    let r = w / 2
    let k = r * SQRT1_2
    "<circle r=\"\{num(r)}\"\{a}/>" +
    "<path d=\"M\{num(-k)},\{num(-k)}L\{num(k)},\{num(k)}M\{num(k)},\{num(-k)}L\{num(-k)},\{num(k)}\" fill=\"none\"\{line}/>"
  }),
  "fork": ShapeDef::new(no_label=true, size=fixed(72, 8), draw=(w, h, _, line) => {
    rect(w, h, " fill=\"var(--_l)\"\{line}", rx=" rx=\"2\"")
  }),
  "cyl": ShapeDef::new(
    size=(tw, th) => {
      let w = @util.js_max(tw + 2 * PAD_X, 56)
      let ry = cap_ry(w)
      { w, h: th + 2 * PAD_Y + 2 * ry, dy: ry / 2, }
    },
    draw=(w, h, a, line) => {
      cylinder_body(w, h, a) +
      "<path d=\"\{cap_arc(w, -h / 2 + cap_ry(w))}\" fill=\"none\"\{line}/>"
    },
  ),
  "lin-cyl": ShapeDef::new(
    size=(tw, th) => {
      let w = @util.js_max(tw + 2 * PAD_X, 56)
      let ry = cap_ry(w)
      { w, h: th + 2 * PAD_Y + 2 * ry + 8, dy: ry / 2 + 4, }
    },
    draw=(w, h, a, line) => {
      let top = -h / 2 + cap_ry(w)
      cylinder_body(w, h, a) +
      "<path d=\"\{cap_arc(w, top)}\{cap_arc(w, top + 8)}\" fill=\"none\"\{line}/>"
    },
  ),
  "h-cyl": ShapeDef::new(
    size=(tw, th) => {
      let h = th + 2 * PAD_Y
      let rx = @util.js_min(12, h / 4)
      { w: tw + 2 * PAD_X + 2 * rx, h, dy: 0, }
    },
    draw=(w, h, a, line) => {
      let ry = h / 2
      let rx = @util.js_min(12, h / 4)
      let l = -w / 2 + rx
      let r = w / 2 - rx
      path(
        "M\{num(l)},\{num(-ry)}H\{num(r)}A\{num(rx)},\{num(ry)} 0 0 1 \{num(r)},\{num(ry)}H\{num(l)}A\{num(rx)},\{num(ry)} 0 0 1 \{num(l)},\{num(-ry)}Z",
        a,
      ) +
      "<path d=\"M\{num(r)},\{num(-ry)}A\{num(rx)},\{num(ry)} 0 0 0 \{num(r)},\{num(ry)}\" fill=\"none\"\{line}/>"
    },
  ),
  "delay": ShapeDef::new(size=slanted_size(4), draw=(w, h, a, _) => {
    let r = h / 2
    path(
      "M\{num(-w / 2)},\{num(-r)}H\{num(w / 2 - r)}A\{num(r)},\{num(r)} 0 0 1 \{num(w / 2 - r)},\{num(r)}H\{num(-w / 2)}Z",
      a,
    )
  }),
  "doc": ShapeDef::new(
    size=(tw, th) => { w: tw + 2 * PAD_X, h: th + 2 * PAD_Y + 10, dy: -5, },
    draw=(w, h, a, _) => wave(w, h, a),
  ),
  "docs": ShapeDef::new(
    size=(tw, th) => { w: tw + 2 * PAD_X + 8, h: th + 2 * PAD_Y + 18, dy: -1, },
    draw=(w, h, a, _) => {
      let out = StringBuilder()
      for i in 0..<3 {
        out.write_string(
          "<g transform=\"translate(\{(1 - i) * 4},\{(i - 1) * 4})\">\{wave(w - 8, h - 8, a)}</g>",
        )
      }
      out.to_string()
    },
  ),
  "tag-doc": ShapeDef::new(
    size=(tw, th) => { w: tw + 2 * PAD_X, h: th + 2 * PAD_Y + 10, dy: -5, },
    draw=(w, h, a, line) => {
      wave(w, h, a) +
      "<path d=\"M\{num(w / 2 - 12)},\{num(h / 2 - 14)}L\{num(w / 2)},\{num(h / 2 - 26)}\" fill=\"none\"\{line}/>"
    },
  ),
  "lin-doc": ShapeDef::new(
    size=(tw, th) => { w: tw + 2 * PAD_X + 8, h: th + 2 * PAD_Y + 10, dy: -5, },
    draw=(w, h, a, line) => {
      wave(w, h, a) +
      "<path d=\"M\{num(-w / 2 + 8)},\{num(-h / 2)}V\{num(h / 2 - 6)}\" fill=\"none\"\{line}/>"
    },
  ),
  "flag": ShapeDef::new(
    size=(tw, th) => { w: tw + 2 * PAD_X, h: th + 2 * PAD_Y + 16, dy: 0, },
    draw=(w, h, a, _) => {
      let x = w / 2
      let y = h / 2 - 8
      let q = w / 4
      path(
        "M\{num(-x)},\{num(-y)}q\{num(q)},-10 \{num(2 * q)},0t\{num(2 * q)},0V\{num(y)}q\{num(-q)},10 \{num(-2 * q)},0t\{num(-2 * q)},0Z",
        a,
      )
    },
  ),
  "folder": ShapeDef::new(
    size=(tw, th) => {
      w: @util.js_max(tw + 2 * PAD_X, 64),
      h: th + 2 * PAD_Y + 8,
      dy: 4,
    },
    draw=(w, h, a, _) => {
      let x = w / 2
      let y = h / 2
      let tab = @util.js_min(w * 0.4, 48)
      path(
        "M\{num(-x)},\{num(-y)}H\{num(-x + tab)}L\{num(-x + tab + 8)},\{num(-y + 8)}H\{num(x)}V\{num(y)}H\{num(-x)}Z",
        a,
      )
    },
  ),
  "bucket": ShapeDef::new(
    size=(tw, th) => { w: tw + 2 * PAD_X + 20, h: th + 2 * PAD_Y + 10, dy: 3, },
    draw=(w, h, a, line) => {
      let x = w / 2
      let y = h / 2
      let ry = 5.0
      let taper = h / 6
      path(
        "M\{num(-x)},\{num(-y + ry)}A\{num(x)},\{num(ry)} 0 0 1 \{num(x)},\{num(-y + ry)}L\{num(x - taper)},\{num(y - ry)}A\{num(x - taper)},\{num(ry)} 0 0 1 \{num(-x + taper)},\{num(y - ry)}Z",
        a,
      ) +
      "<path d=\"M\{num(-x)},\{num(-y + ry)}A\{num(x)},\{num(ry)} 0 0 0 \{num(x)},\{num(-y + ry)}\" fill=\"none\"\{line}/>"
    },
  ),
  "person": ShapeDef::new(
    size=(tw, th) => {
      w: @util.js_max(tw + 2 * PAD_X, 56),
      h: th + 2 * PAD_Y + 26,
      dy: 13,
    },
    draw=(w, h, a, _) => {
      let top = -h / 2
      "<rect x=\"\{num(-w / 2)}\" y=\"\{num(top + 26)}\" width=\"\{num(w)}\" height=\"\{num(h - 26)}\" rx=\"12\"\{a}/>" +
      "<circle cy=\"\{num(top + 14)}\" r=\"13\"\{a}/>"
    },
  ),
  "cloud": ShapeDef::new(
    size=(tw, th) => { w: tw + 2 * PAD_X + 32, h: th + 2 * PAD_Y + 24, dy: 0, },
    draw=(w, h, a, _) => {
      let x = w / 2
      let y = h / 2
      let r = y * 0.55
      path(
        "M\{num(-x + r)},\{num(y)}A\{num(r)},\{num(r)} 0 0 1 \{num(-x + r * 0.6)},\{num(-y * 0.1)}A\{num(x * 0.42)},\{num(y * 0.7)} 0 0 1 \{num(-x * 0.1)},\{num(-y * 0.72)}A\{num(x * 0.4)},\{num(y * 0.62)} 0 0 1 \{num(x * 0.62)},\{num(-y * 0.42)}A\{num(r * 1.05)},\{num(r * 1.05)} 0 0 1 \{num(x - r)},\{num(y)}Z",
        a,
      )
    },
  ),
  "brace": ShapeDef::new(
    size=(tw, th) => { w: tw + 2 * PAD_X + 12, h: th + 2 * PAD_Y, dy: 0, },
    draw=(w, h, _, line) => {
      rect(w, h, hidden_box) + brace(-w / 2 + 12, h, -1, line)
    },
  ),
  "brace-r": ShapeDef::new(
    size=(tw, th) => { w: tw + 2 * PAD_X + 12, h: th + 2 * PAD_Y, dy: 0, },
    draw=(w, h, _, line) => {
      rect(w, h, hidden_box) + brace(w / 2 - 12, h, 1, line)
    },
  ),
  "braces": ShapeDef::new(
    size=(tw, th) => { w: tw + 2 * PAD_X + 24, h: th + 2 * PAD_Y, dy: 0, },
    draw=(w, h, _, line) => {
      rect(w, h, hidden_box) +
      brace(-w / 2 + 12, h, -1, line) +
      brace(w / 2 - 12, h, 1, line)
    },
  ),
  "curv-trap": ShapeDef::new(
    size=(tw, th) => {
      let h = th + 2 * PAD_Y
      { w: tw + 2 * PAD_X + h * 0.6, h, dy: 0, }
    },
    draw=(w, h, a, _) => {
      let x = w / 2
      let y = h / 2
      let k = h * 0.3
      path(
        "M\{num(-x + k)},\{num(-y)}H\{num(x - k)}A\{num(k)},\{num(y)} 0 0 1 \{num(x - k)},\{num(y)}H\{num(-x + k)}L\{num(-x)},0Z",
        a,
      )
    },
  ),
  "bow-rect": ShapeDef::new(
    size=(tw, th) => {
      let h = th + 2 * PAD_Y
      { w: tw + 2 * PAD_X + h * 0.4, h, dy: 0, }
    },
    draw=(w, h, a, _) => {
      let x = w / 2
      let y = h / 2
      let k = h * 0.2
      path(
        "M\{num(-x + k)},\{num(-y)}H\{num(x)}A\{num(k)},\{num(y)} 0 0 0 \{num(x)},\{num(y)}H\{num(-x + k)}A\{num(k)},\{num(y)} 0 0 1 \{num(-x + k)},\{num(-y)}Z",
        a,
      )
    },
  ),
}

///|
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

///|
/// Whether the named shape has room for a label; symbol shapes such as forks do not.
pub fn shape_has_label(shape : String) -> Bool {
  match shapes.get(shape) {
    Some(def) => !def.no_label
    None => true
  }
}
