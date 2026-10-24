///|
/// The x of every route point, by its rounded y: the edges that cross a cluster's top border.
pub struct Crossings {
  priv rows : Map[Double, Array[Double]]
}

///|
/// Crossings with no edges marked yet.
pub fn Crossings::new() -> Crossings {
  { rows: {}, }
}

///|
/// Marks every point of a route of x, y, axis triples.
pub fn mark_crossings(crossings : Crossings, route : Array[Double]) -> Unit {
  for k = 0; k < route.length(); k = k + 3 {
    let key = route[k + 1].round()
    match crossings.rows.get(key) {
      Some(list) => list.push(route[k])
      None => crossings.rows[key] = [route[k]]
    }
  }
}

///|
/// The x of every point marked on the row of `y`, which is rounded as the rows are.
pub fn Crossings::at(self : Crossings, y : Double) -> Array[Double]? {
  self.rows.get(y.round())
}

///|
/// Picks where a cluster title `width` wide sits along the top edge so that edges entering there do not cross it.
/// Returns the x of its center: at the left, in the middle or at the right, whichever is clear first, and otherwise the one with the most room.
pub fn cluster_title_x(
  c : @layout.CNode,
  width : Double,
  crossings : Crossings,
  pad : Double,
) -> Double {
  if width == 0 {
    return c.x
  }
  let top = c.y - c.h / 2
  let left = c.x - c.w / 2
  let half = width / 2
  let candidates = [left + pad - 6 + half, c.x, left + c.w - pad + 6 - half]
  guard crossings.rows.get(top.round()) is Some(xs) else {
    return candidates[0]
  }
  let mut best = candidates[0]
  let mut best_gap = -1.0
  for x in candidates {
    let mut gap = @double.infinity
    for cx in xs {
      if cx > left && cx < left + c.w {
        gap = @util.js_min(gap, (cx - x).abs() - half)
      }
    }
    if gap >= 6 {
      return x
    }
    if gap > best_gap + 0.5 {
      best_gap = gap
      best = x
    }
  }
  best
}

///|
/// Whether an edge that enters the top of the cluster runs through a title `width` wide centered at `x`.
pub fn title_crossed(
  c : @layout.CNode,
  width : Double,
  x : Double,
  crossings : Crossings,
) -> Bool {
  guard width > 0 && crossings.rows.get((c.y - c.h / 2).round()) is Some(xs) else {
    return false
  }
  let left = c.x - c.w / 2
  for cx in xs {
    if cx > left && cx < left + c.w && (cx - x).abs() < width / 2 + 4 {
      return true
    }
  }
  false
}

///|
/// Writes a title that an edge runs through to `out`, to be drawn over the edges: the text, on an
/// outline in the color of the cluster behind it, so that only the line is seen to stop short of
/// the letters.
/// `nodes` and `index` find how many clusters deep the title is, each of which tints the
/// background.
/// `id` names the cluster in its data-id, escaped as `esc_text` escapes it, a piece at a time.
/// The diagrams name a cluster by its source text, which escapes to more than a doubling
/// StringBuilder holds.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_struck_title(
  out : Markup,
  label : @text.Label,
  x : Double,
  y : Double,
  attrs : String,
  id : String,
  nodes : Array[@layout.CNode],
  index : Int32,
  icons? : @types.IconResolver,
) -> Unit raise @errors.PeleError {
  let mut depth = 1
  let mut p = nodes[index].parent
  while p >= 0 && depth < 8 {
    depth += 1
    p = nodes[p].parent
  }
  // Each cluster is half its fill over what is behind it.
  let mut behind = 1.0
  for _ in 0..<depth {
    behind *= 0.5
  }
  let fill = "color-mix(in srgb,var(--_a) \{num(100 * (1 - behind))}%,var(--_bg))"
  out.write("<g class=\"pele-cluster-title\"")
  out.write_data_id(id)
  out.write(">")
  write_label(
    out,
    label,
    x,
    y,
    " fill=\"none\" stroke=\"\{fill}\" stroke-width=\"5\" stroke-linejoin=\"round\"",
    icons?,
  )
  write_label(out, label, x, y, attrs, icons?)
  out.write("</g>")
}
