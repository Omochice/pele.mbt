///|
/// A part of a graph that no edge or group joins to the rest, and the box it takes.
priv struct Part {
  nodes : Array[CNode]
  edges : Array[CEdge]
  mut left : Double
  mut top : Double
  mut right : Double
  mut bottom : Double
}

///|
fn Part::cover(
  self : Part,
  x : Double,
  y : Double,
  w~ : Double = 0,
  h~ : Double = 0,
) -> Unit {
  self.left = @util.js_min(self.left, x - w / 2)
  self.top = @util.js_min(self.top, y - h / 2)
  self.right = @util.js_max(self.right, x + w / 2)
  self.bottom = @util.js_max(self.bottom, y + h / 2)
}

///|
/// Moves the disconnected parts of a laid out graph into rows `width` wide, `gap` apart, without
/// changing the layout inside a part.
/// Returns the size of the rows, or `None`, moving nothing, when there is one part or the rows
/// would be no narrower than the graph already is.
pub fn wrap_components(
  nodes : Array[CNode],
  edges : Array[CEdge],
  width : Double,
  gap : Double,
) -> CompoundResult? {
  let parent = FixedArray::makei(nodes.length(), i => i)
  let root = (start : Int32) => {
    let mut i = start
    while parent[i] != i {
      parent[i] = parent[parent[i]]
      i = parent[i]
    }
    i
  }
  let join = (a : Int32, b : Int32) => parent[root(a)] = root(b)
  for i, node in nodes {
    if node.parent >= 0 {
      join(i, node.parent)
    }
  }
  for e in edges {
    join(e.src, e.dst)
  }
  let parts : Map[Int32, Part] = Map([])
  for i, c in nodes {
    let id = root(i)
    let part = match parts.get(id) {
      Some(part) => part
      None => {
        let part = {
          nodes: [],
          edges: [],
          left: @double.infinity,
          top: @double.infinity,
          right: @double.neg_infinity,
          bottom: @double.neg_infinity,
        }
        parts[id] = part
        part
      }
    }
    part.nodes.push(c)
    part.cover(c.x, c.y, w=c.w, h=c.h)
  }
  if parts.length() < 2 {
    return None
  }
  for e in edges {
    guard parts.get(root(e.src)) is Some(part) else { continue }
    part.edges.push(e)
    let mut k = 0
    while k < e.route.length() {
      part.cover(e.route[k], e.route[k + 1])
      k += 3
    }
    if e.label_w > 0 {
      part.cover(e.label_x, e.label_y, w=e.label_w, h=e.label_h)
    }
  }
  let mut x = 0.0
  let mut y = 0.0
  let mut row_height = 0.0
  let mut right = 0.0
  let mut from = @double.infinity
  let mut to = @double.neg_infinity
  let shifts : Array[(Double, Double)] = []
  for _, part in parts {
    let w = part.right - part.left
    let h = part.bottom - part.top
    if x > 0 && x + w > width {
      y += row_height + gap
      x = 0
      row_height = 0
    }
    shifts.push((x - part.left, y - part.top))
    from = @util.js_min(from, part.left)
    to = @util.js_max(to, part.right)
    right = @util.js_max(right, x + w)
    row_height = @util.js_max(row_height, h)
    x += w + gap
  }
  if right >= to - from {
    return None
  }
  let mut k = 0
  for _, part in parts {
    let (ox, oy) = shifts[k]
    shift_layout(part.nodes, part.edges, ox, oy)
    k += 1
  }
  Some({ width: right, height: y + row_height, })
}
