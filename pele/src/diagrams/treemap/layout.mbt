///|
/// A node placed in the treemap.
pub(all) struct Box {
  node : TreemapNode
  parent : Box?
  /// The position among the top-level nodes of the branch the box belongs to, which picks its color.
  series : Int32
  /// A leaf's own value, or the sum of the leaves under a section.
  mut value : Double
  children : Array[Box]
  /// Small sections give their header space to their children.
  mut headed : Bool
  /// The height of the header of a section that has one, or 0.
  mut header : Double
  mut x : Double
  mut y : Double
  mut w : Double
  mut h : Double
}

///|
/// The space between boxes, and the space a section keeps for its header and around its children.
pub(all) struct Insets {
  gap : Double
  header : Double
  /// The header a section too short for a full one keeps instead.
  short : Double
  side : Double
}

///|
/// Places the nodes that have a positive value as a squarified treemap in `width` by `height`.
/// Returns every box with a positive value, even one left with no room, parents before their children.
pub fn layout_treemap(
  roots : Array[TreemapNode],
  width : Double,
  height : Double,
  insets : Insets,
) -> Array[Box] {
  let top = roots.mapi((index, node) => make_box(node, None, index))
  let all = top.copy()
  let mut next = 0
  while next < all.length() {
    let parent = all[next]
    for node in parent.node.children.unwrap_or([]) {
      let child = make_box(node, Some(parent), parent.series)
      parent.children.push(child)
      all.push(child)
    }
    next += 1
  }
  for i = all.length() - 1; i >= 0; i = i - 1 {
    if all[i].parent is Some(parent) {
      parent.value += all[i].value
    }
  }
  let { gap, header, short, side, } = insets
  let placed = []
  let place = (
    children : Array[Box],
    x : Double,
    y : Double,
    w : Double,
    h : Double,
  ) => {
    let shown = by_value(children.filter(b => b.value > 0))
    let mut total = 0.0
    for b in shown {
      total += b.value
    }
    if shown.is_empty() || total.is_nan() || total.is_inf() {
      return
    }
    let w = @util.js_max(0, w)
    let h = @util.js_max(0, h)
    if w > 0 && h > 0 {
      squarify(shown, total, x - gap / 2, y - gap / 2, w + gap, h + gap, gap)
    }
    for b in shown {
      let x0 = clamp(b.x, x, x + w)
      let y0 = clamp(b.y, y, y + h)
      b.w = clamp(b.x + b.w, x0, x + w) - x0
      b.h = clamp(b.y + b.h, y0, y + h) - y0
      b.x = x0
      b.y = y0
      placed.push(b)
    }
  }
  place(top, 0, 0, width, height)
  let mut i = 0
  while i < placed.length() {
    let b = placed[i]
    i += 1
    if b.children.is_empty() {
      continue
    }
    let top = if b.h - header - side >= 12 { header } else { short }
    b.headed = b.w > @util.js_max(24, 2 * side) && b.h - top - side >= 8
    b.header = if b.headed { top } else { 0 }
    if b.headed {
      place(b.children, b.x + side, b.y + top, b.w - 2 * side, b.h - top - side)
    } else {
      place(b.children, b.x, b.y, b.w, b.h)
    }
  }
  placed
}

///|
fn make_box(node : TreemapNode, parent : Box?, series : Int32) -> Box {
  let value = match (node.children, node.value) {
    (None, Some(v)) if !v.is_nan() && !v.is_inf() && v > 0 => v
    _ => 0.0
  }
  {
    node,
    parent,
    series,
    value,
    children: [],
    headed: false,
    header: 0,
    x: 0,
    y: 0,
    w: 0,
    h: 0,
  }
}

///|
/// Keeps `v` within `low` and `high`, taking `low` for NaN.
fn clamp(v : Double, low : Double, high : Double) -> Double {
  if v >= low {
    @util.js_min(v, high)
  } else {
    low
  }
}

///|
/// Largest first, with equal values in their original order as a stable sort keeps them.
fn by_value(boxes : Array[Box]) -> Array[Box] {
  let indexed = boxes.mapi((index, b) => (index, b))
  indexed.sort_by((p, q) => {
    if p.1.value > q.1.value {
      -1
    } else if p.1.value < q.1.value {
      1
    } else {
      p.0.compare(q.0)
    }
  })
  indexed.map(p => p.1)
}

///|
/// Lays out `boxes` in the rectangle as one squarified treemap: rows are added along the shorter
/// side, and a row stops growing when another box would make its boxes less square.
fn squarify(
  boxes : Array[Box],
  total : Double,
  x0 : Double,
  y0 : Double,
  w0 : Double,
  h0 : Double,
  gap : Double,
) -> Unit {
  let mut x = x0
  let mut y = y0
  let mut w = w0
  let mut h = h0
  let mut rest = total
  let mut from = 0
  while from < boxes.length() {
    let scale = w * h / rest
    let side = @util.js_min(w, h)
    let mut sum = boxes[from].value * scale
    let largest = sum
    let mut worst = @util.js_max(
      side * side * largest / (sum * sum),
      sum * sum / (side * side * largest),
    )
    let mut to = from + 1
    while to < boxes.length() {
      let smallest = boxes[to].value * scale
      let next = sum + smallest
      let ratio = @util.js_max(
        side * side * largest / (next * next),
        next * next / (side * side * smallest),
      )
      if ratio > worst {
        break
      }
      worst = ratio
      sum = next
      to += 1
    }
    let thickness = sum / side
    let mut offset = 0.0
    for i in from..<to {
      let b = boxes[i]
      let length = if i == to - 1 {
        side - offset
      } else {
        b.value * scale / thickness
      }
      let across = w >= h
      let bx = if across { x } else { x + offset }
      let by = if across { y + offset } else { y }
      let bw = if across { thickness } else { length }
      let bh = if across { length } else { thickness }
      // A box thinner than the gap keeps its sliver instead of losing it to the gap.
      let gx = if (bx + bw - gap / 2).round() > (bx + gap / 2).round() {
        gap / 2
      } else {
        0
      }
      let gy = if (by + bh - gap / 2).round() > (by + gap / 2).round() {
        gap / 2
      } else {
        0
      }
      b.x = (bx + gx).round()
      b.y = (by + gy).round()
      b.w = (bx + bw - gx).round() - b.x
      b.h = (by + bh - gy).round() - b.y
      offset += length
      rest -= b.value
    }
    if w >= h {
      x += thickness
      w -= thickness
    } else {
      y += thickness
      h -= thickness
    }
    from = to
  }
}
