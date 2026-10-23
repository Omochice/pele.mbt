///|
const STUB : Double = 12

///|
const CORNER : Double = 6

///|
const LABEL_GAP : Double = 4

///|
const DOT : Double = 3

///|
let side_x : Array[Double] = [-1, 1, 0, 0]

///|
let side_y : Array[Double] = [0, 0, -1, 1]

///|
/// A number from the `architecture` config section, held to its range.
fn setting(
  config : @types.Config,
  key : String,
  fallback : Double,
  min : Double,
  max : Double,
) -> Double {
  guard config.get("architecture") is Some(Object(section)) else {
    return fallback
  }
  match section.get(key) {
    Some(Number(value, ..)) if !value.is_nan() && !value.is_inf() =>
      @util.js_min(max, @util.js_max(min, value))
    _ => fallback
  }
}

///|
/// Maps the grid lines in use to consecutive indexes, so empty rows and columns take no room.
fn rank(values : Array[Int32]) -> Map[Int32, Int32] {
  let out : Map[Int32, Int32] = Map([])
  values.sort()
  for value in values {
    if !out.contains(value) {
      out.set(value, out.length())
    }
  }
  out
}

///|
fn icon_slot(
  name : String,
  x : Double,
  y : Double,
  side : Double,
  icons : @types.IconResolver?,
) -> String {
  @common.icon_svg(name, x, y, side, icons?, drawing=builtin_icon(name))
}

///|
/// A whole number as JavaScript writes one into a template, where -0 reads as 0.
fn whole(value : Double) -> String {
  if value == 0 {
    "0"
  } else {
    value.to_string()
  }
}

///|
fn is_set(value : String?) -> Bool {
  value is Some(text) && text != ""
}

///|
/// Cuts a label down to a box, ending what is left with an ellipsis.
fn fit(
  label : @text.Label,
  max_width : Double,
  max_lines : Int32,
  measurer : @text.TextMeasurer,
) -> @text.Label {
  let cut = label.lines.length() > max_lines
  if !cut && label.width <= max_width {
    return label
  }
  let dots = measurer.width("…", label.size, 0)
  let lines : Array[Array[@text.Span]] = []
  let widths : Array[Double] = []
  let mut widest = 0.0
  let count = if max_lines < label.lines.length() {
    max_lines
  } else {
    label.lines.length()
  }
  for i in 0..<count {
    let line = label.lines[i].map(span => { ..span, })
    let mut width = label.widths[i]
    if width > max_width || (cut && i == max_lines - 1) {
      while true {
        guard line.last() is Some(span) else {
          line.push({
            text: "…",
            style: 0,
            icon: None,
            width: dots,
            math: None,
          })
          width = dots
          break
        }
        let rest = width - span.width
        if span.icon is None && rest + dots < max_width {
          let mut lo = 0
          let mut hi = span.text.length()
          while lo < hi {
            let mid = (lo + hi + 1) >> 1
            if rest +
              measurer.width(
                @util.slice(span.text, 0, end=mid),
                label.size,
                span.style,
              ) +
              dots <=
              max_width {
              lo = mid
            } else {
              hi = mid - 1
            }
          }
          let code = if lo > 0 { @util.code_at(span.text, lo - 1) } else { 0 }
          if code >= 0xd800 && code <= 0xdbff {
            lo -= 1
          }
          span.text = @util.trim_end(@util.slice(span.text, 0, end=lo)) + "…"
          span.width = measurer.width(span.text, label.size, span.style)
          width = rest + span.width
          break
        }
        line.pop() |> ignore
        width = rest
      }
    }
    lines.push(line)
    widths.push(width)
    widest = @util.js_max(widest, width)
  }
  {
    ..label,
    lines,
    widths,
    width: widest,
    height: lines.length().to_double() * label.line_height,
  }
}

///|
priv struct Port {
  mut x : Double
  mut y : Double
  dx : Double
  dy : Double
  /// The box the route has to stay out of when it cannot leave straight.
  mut x0 : Double
  mut y0 : Double
  mut x1 : Double
  mut y1 : Double
  /// How far short of the port an arrowhead stops: the radius of a junction's dot.
  mut gap : Double
  /// Set where a junction is reached through the border of its group: the line carries on to the junction.
  mut wire : Bool
}

///|
/// An orthogonal route from one port to another, each left along its side's normal.
fn route(s : Port, e : Port) -> Array[Double] {
  let { x: sx, y: sy, dx: sdx, dy: sdy, .. } = s
  let { x: ex, y: ey, dx: edx, dy: edy, .. } = e
  let s1x = sx + sdx * STUB
  let s1y = sy + sdy * STUB
  let e1x = ex + edx * STUB
  let e1y = ey + edy * STUB
  if sdx * edx + sdy * edy == 0 {
    let cx = if sdx != 0 { ex } else { sx }
    let cy = if sdx != 0 { sy } else { ey }
    if (cx - sx) * sdx + (cy - sy) * sdy > 0 &&
      (cx - ex) * edx + (cy - ey) * edy > 0 {
      return [sx, sy, cx, cy, ex, ey]
    }
    return if sdx != 0 {
      [sx, sy, s1x, s1y, s1x, e1y, e1x, e1y, ex, ey]
    } else {
      [sx, sy, s1x, s1y, e1x, s1y, e1x, e1y, ex, ey]
    }
  }
  let sideways = sdx != 0
  let offset = if sideways { ey - sy } else { ex - sx }
  if sdx == -edx && sdy == -edy {
    let ahead = (ex - sx) * sdx + (ey - sy) * sdy
    if ahead > 0 {
      if offset.abs() < 0.5 {
        return [sx, sy, ex, ey]
      }
      // Turn midway between the two boxes, which is clear of both titles, when there is such a place.
      if sideways {
        let lo = if sdx > 0 { s.x1 } else { e.x1 }
        let hi = if sdx > 0 { e.x0 } else { s.x0 }
        let mx = if lo < hi { (lo + hi) / 2 } else { (sx + ex) / 2 }
        return [sx, sy, mx, sy, mx, ey, ex, ey]
      }
      let lo = if sdy > 0 { s.y1 } else { e.y1 }
      let hi = if sdy > 0 { e.y0 } else { s.y0 }
      let my = if lo < hi { (lo + hi) / 2 } else { (sy + ey) / 2 }
      return [sx, sy, sx, my, ex, my, ex, ey]
    }
  } else if offset.abs() >= 1 {
    if sideways {
      let x = if sdx > 0 {
        @util.js_max(sx, ex) + STUB
      } else {
        @util.js_min(sx, ex) - STUB
      }
      return [sx, sy, x, sy, x, ey, ex, ey]
    }
    let y = if sdy > 0 {
      @util.js_max(sy, ey) + STUB
    } else {
      @util.js_min(sy, ey) - STUB
    }
    return [sx, sy, sx, y, ex, y, ex, ey]
  }
  // The straight way is blocked by one of the two nodes: go between them, or around both.
  if sideways {
    let lane = if s.y1 + STUB <= e.y0 {
      (s.y1 + e.y0) / 2
    } else if e.y1 + STUB <= s.y0 {
      (e.y1 + s.y0) / 2
    } else {
      @util.js_max(s.y1, e.y1) + STUB
    }
    return [sx, sy, s1x, sy, s1x, lane, e1x, lane, e1x, ey, ex, ey]
  }
  let lane = if s.x1 + STUB <= e.x0 {
    (s.x1 + e.x0) / 2
  } else if e.x1 + STUB <= s.x0 {
    (e.x1 + s.x0) / 2
  } else {
    @util.js_max(s.x1, e.x1) + STUB
  }
  [sx, sy, sx, s1y, lane, s1y, lane, e1y, ex, e1y, ex, ey]
}

///|
/// Drops repeated points and joins runs that continue in a straight line.
fn simplify(p : Array[Double]) -> Array[Double] {
  let out = [p[0], p[1]]
  for i = 2; i < p.length(); i = i + 2 {
    let x = p[i]
    let y = p[i + 1]
    let n = out.length()
    let same_x = (x - out[n - 2]).abs() < 0.01
    let same_y = (y - out[n - 1]).abs() < 0.01
    if same_x && same_y {
      continue
    }
    if n >= 4 &&
      (
        (same_x && (out[n - 4] - out[n - 2]).abs() < 0.01) ||
        (same_y && (out[n - 3] - out[n - 1]).abs() < 0.01)
      ) {
      out[n - 2] = x
      out[n - 1] = y
    } else {
      out.push(x)
      out.push(y)
    }
  }
  out
}

///|
fn path_data(
  p : Array[Double],
  start_trim : Double,
  end_trim : Double,
) -> String {
  let n = p.length() / 2
  let xs = Array::makei(n, i => p[i * 2])
  let ys = Array::makei(n, i => p[i * 2 + 1])
  fn trim(at : Int32, toward : Int32, amount : Double) {
    let len = @util.js_hypot(xs[toward] - xs[at], ys[toward] - ys[at])
    let t = @util.js_min(amount, @util.js_max(0, len - 1))
    if len > 0 && t > 0 {
      xs[at] += (xs[toward] - xs[at]) / len * t
      ys[at] += (ys[toward] - ys[at]) / len * t
    }
  }

  trim(0, 1, start_trim)
  trim(n - 1, n - 2, end_trim)
  let d = StringBuilder()
  d.write_string("M\{@svg.num(xs[0])},\{@svg.num(ys[0])}")
  for i in 1..<(n - 1) {
    let before = @util.js_hypot(xs[i] - xs[i - 1], ys[i] - ys[i - 1])
    let after = @util.js_hypot(xs[i + 1] - xs[i], ys[i + 1] - ys[i])
    let r = @util.js_min(CORNER, @util.js_min(before / 2, after / 2))
    if r < 0.5 {
      d.write_string("L\{@svg.num(xs[i])},\{@svg.num(ys[i])}")
      continue
    }
    let in_x = xs[i] - (xs[i] - xs[i - 1]) / before * r
    let in_y = ys[i] - (ys[i] - ys[i - 1]) / before * r
    let out_x = xs[i] + (xs[i + 1] - xs[i]) / after * r
    let out_y = ys[i] + (ys[i + 1] - ys[i]) / after * r
    d.write_string(
      "L\{@svg.num(in_x)},\{@svg.num(in_y)}Q\{@svg.num(xs[i])},\{@svg.num(ys[i])} \{@svg.num(out_x)},\{@svg.num(out_y)}",
    )
  }
  d.write_string("L\{@svg.num(xs[n - 1])},\{@svg.num(ys[n - 1])}")
  d.to_string()
}

///|
/// Draws an architecture diagram.
pub fn render_architecture(
  model : ArchitectureDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  @common.tighten(options, tight => draw(model, config, options, tight))
}

///|
/// `tight` wraps titles to the width the host has and pulls the cells closer.
fn draw(
  model : ArchitectureDb,
  config : @types.Config,
  options : @types.RenderOptions,
  tight : Bool,
) -> @types.Rendered raise @errors.PeleError {
  let icon_size = setting(config, "iconSize", 48, 8, 512)
  let size = setting(
    config,
    "fontSize",
    options.font_size.unwrap_or(16),
    4,
    128,
  )
  let padding = setting(config, "padding", 20, 0, 256)
  let group_pad = if tight { @util.js_min(padding, 12) } else { padding }
  let small = (size * 0.875).round()
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let half = icon_size / 2
  let nodes = model.nodes.values().collect()
  let groups = model.groups.values().collect()
  let n = nodes.length()
  let g_count = groups.length()
  let grid = place_on_grid(nodes, groups, model.edges, model.layout_hints)
  let index : Map[String, Int32] = Map([])
  for i, node in nodes {
    index.set(node.id, i)
  }

  // A service is its icon square with the title beneath; a junction takes the same room.
  let wrap = if tight {
    @util.js_max(icon_size, 64)
  } else {
    @util.js_max(icon_size * 2.25, 96)
  }
  let labels = nodes.map(node => {
    @text.layout_label(
      if node.kind is Service {
        node.title
      } else {
        None
      },
      true,
      measurer,
      size,
      wrap,
    )
  })
  let box_w = labels.map(label => {
    @util.js_max(icon_size, 2 * (label.width / 2).ceil())
  })
  let box_h = labels.map(label => {
    icon_size + (if label.height > 0 { LABEL_GAP + label.height } else { 0 })
  })
  let col_values : Array[Int32] = []
  let row_values : Array[Int32] = []
  for i in 0..<n {
    col_values.push(grid.col[i])
    row_values.push(grid.row[i])
  }
  for g in 0..<g_count {
    if !grid.group_empty[g] {
      continue
    }
    col_values.push(grid.group_col[g])
    row_values.push(grid.group_row[g])
  }
  let col_of = rank(col_values)
  let row_of = rank(row_values)
  let cols = col_of.length()
  let rows = row_of.length()
  let col_w = Array::make(cols, 0.0)
  let row_h = Array::make(rows, 0.0)
  let gap = if tight {
    @util.js_max(24, 2 * STUB)
  } else {
    @util.js_max(40, (icon_size * 0.75).round())
  }
  let gap_x = Array::make(cols, gap)
  let gap_y = Array::make(rows, gap)
  let node_col = Array::make(n, 0)
  let node_row = Array::make(n, 0)
  for i in 0..<n {
    let c = col_of[grid.col[i]]
    let r = row_of[grid.row[i]]
    node_col[i] = c
    node_row[i] = r
    col_w[c] = @util.js_max(col_w[c], box_w[i])
    row_h[r] = @util.js_max(row_h[r], box_h[i])
  }
  for g in 0..<g_count {
    if !grid.group_empty[g] {
      continue
    }
    let c = col_of[grid.group_col[g]]
    let r = row_of[grid.group_row[g]]
    col_w[c] = @util.js_max(col_w[c], icon_size)
    row_h[r] = @util.js_max(row_h[r], half)
  }

  // An edge label needs the gap its edge crosses to be wide enough to hold it.
  let edge_count = model.edges.length()
  let edge_labels : Array[@text.Label] = []
  let ends = Array::make(edge_count * 2, -1)
  for k, edge in model.edges {
    let a = index.get(edge.lhs_id).unwrap_or(-1)
    let b = index.get(edge.rhs_id).unwrap_or(-1)
    ends[k * 2] = a
    ends[k * 2 + 1] = b
    let label = @text.layout_label(edge.title, true, measurer, small, 160)
    edge_labels.push(label)
    if label.width == 0 || a < 0 || b < 0 {
      continue
    }
    if node_col[a] != node_col[b] {
      let c = if node_col[a] < node_col[b] { node_col[a] } else { node_col[b] }
      gap_x[c] = @util.js_max(gap_x[c], label.width.ceil() + 28)
    } else {
      col_w[node_col[a]] = @util.js_max(
        col_w[node_col[a]],
        2 * (label.width / 2).ceil() + 8,
      )
      if node_row[a] != node_row[b] {
        let r = if node_row[a] < node_row[b] {
          node_row[a]
        } else {
          node_row[b]
        }
        gap_y[r] = @util.js_max(gap_y[r], label.height.ceil() + 24)
      }
    }
  }

  // Room around each group, kept on the rows and columns at its edges.
  // A group that shares an edge with a group inside it stands that much further out.
  // Children come after their parents, so walking backwards settles every group before the one that holds it.
  let group_labels : Array[@text.Label] = []
  let c0 = Array::make(g_count, 0)
  let c1 = Array::make(g_count, 0)
  let r0 = Array::make(g_count, 0)
  let r1 = Array::make(g_count, 0)
  let ins_l = Array::make(g_count, 0.0)
  let ins_r = Array::make(g_count, 0.0)
  let ins_t = Array::make(g_count, 0.0)
  let ins_b = Array::make(g_count, 0.0)
  let head_w = Array::make(g_count, 0.0)
  let head_h = Array::make(g_count, 0.0)
  let col_l = Array::make(cols, 0.0)
  let col_r = Array::make(cols, 0.0)
  let row_t = Array::make(rows, 0.0)
  let row_b = Array::make(rows, 0.0)
  let badge = (size * 1.25).round()
  for g in 0..<g_count {
    c0[g] = col_of[grid.group_col[g]]
    c1[g] = col_of[grid.group_col[g] + grid.group_cols[g] - 1]
    r0[g] = row_of[grid.group_row[g]]
    r1[g] = row_of[grid.group_row[g] + grid.group_rows[g] - 1]
    let label = @text.layout_label(
      groups[g].title,
      true,
      measurer,
      size,
      if tight {
        @util.js_max(80, @common.title_room(options) / 2)
      } else {
        320
      },
    )
    group_labels.push(label)
    let icon = if is_set(groups[g].icon) { badge } else { 0 }
    head_w[g] = label.width +
      icon +
      (if label.width > 0 && icon > 0 { 6 } else { 0 })
    head_h[g] = @util.js_max(label.height, icon)
  }
  for g = g_count - 1; g >= 0; g = g - 1 {
    let left = group_pad + ins_l[g]
    let mut right = group_pad + ins_r[g]
    let top = (if head_h[g] > 0 {
        @util.js_max(group_pad, head_h[g] + 12)
      } else {
        group_pad
      }) +
      ins_t[g]
    let bottom = group_pad + ins_b[g]
    if head_w[g] > 0 {
      let mut inner = left + right
      for c in c0[g]..<=c1[g] {
        inner += col_w[c] +
          (if c < c1[g] { col_r[c] + gap_x[c] + col_l[c + 1] } else { 0 })
      }
      if head_w[g] + 20 > inner {
        right += (head_w[g] + 20 - inner).ceil()
      }
    }
    ins_l[g] = left
    ins_r[g] = right
    ins_t[g] = top
    ins_b[g] = bottom
    col_l[c0[g]] = @util.js_max(col_l[c0[g]], left)
    col_r[c1[g]] = @util.js_max(col_r[c1[g]], right)
    row_t[r0[g]] = @util.js_max(row_t[r0[g]], top)
    row_b[r1[g]] = @util.js_max(row_b[r1[g]], bottom)
    let p = grid.group_parent[g]
    if p < 0 {
      continue
    }
    if c0[p] == c0[g] {
      ins_l[p] = @util.js_max(ins_l[p], left)
    }
    if c1[p] == c1[g] {
      ins_r[p] = @util.js_max(ins_r[p], right)
    }
    if r0[p] == r0[g] {
      ins_t[p] = @util.js_max(ins_t[p], top)
    }
    if r1[p] == r1[g] {
      ins_b[p] = @util.js_max(ins_b[p], bottom)
    }
  }
  let col_x = Array::make(cols, 0.0)
  let row_y = Array::make(rows, 0.0)
  let mut inner_w = 0.0
  for c in 0..<cols {
    col_x[c] = inner_w + col_l[c]
    inner_w = col_x[c] +
      col_w[c] +
      col_r[c] +
      (if c < cols - 1 { gap_x[c] } else { 0 })
  }
  let mut inner_h = 0.0
  for r in 0..<rows {
    row_y[r] = inner_h + row_t[r]
    inner_h = row_y[r] +
      row_h[r] +
      row_b[r] +
      (if r < rows - 1 { gap_y[r] } else { 0 })
  }
  // What is drawn, which an edge that has to go around a node can push past the grid.
  let mut min_x = 0.0
  let mut min_y = 0.0
  let mut max_x = inner_w
  let mut max_y = inner_h
  let left = g => col_x[c0[g]] - ins_l[g]
  let right = g => col_x[c1[g]] + col_w[c1[g]] + ins_r[g]
  let top = g => row_y[r0[g]] - ins_t[g]
  let bottom = g => row_y[r1[g]] + row_h[r1[g]] + ins_b[g]
  let center_x = i => col_x[node_col[i]] + col_w[node_col[i]] / 2
  let port = (i : Int32, side : Int32, via_group : Bool) => {
    let dx = side_x[side]
    let dy = side_y[side]
    let cx = center_x(i)
    let y = row_y[node_row[i]]
    let p : Port = {
      x: cx,
      y: y + half,
      dx,
      dy,
      x0: cx - box_w[i] / 2,
      y0: y,
      x1: cx + box_w[i] / 2,
      y1: y + box_h[i],
      gap: 0,
      wire: false,
    }
    if nodes[i].kind is Junction {
      p.x0 = cx
      p.x1 = cx
      p.y0 = p.y
      p.y1 = p.y
      p.gap = DOT
    } else if dx != 0 {
      p.x = cx + dx * half
    } else {
      p.y = if dy < 0 {
        y
      } else {
        y + box_h[i] + (if labels[i].height > 0 { 2 } else { 0 })
      }
    }
    let g = if via_group { grid.node_parent[i] } else { -1 }
    if g >= 0 {
      p.x0 = left(g)
      p.x1 = right(g)
      p.y0 = top(g)
      p.y1 = bottom(g)
      p.gap = 0
      p.wire = nodes[i].kind is Junction
      if dx != 0 {
        p.x = if dx < 0 { p.x0 } else { p.x1 }
      } else {
        p.y = if dy < 0 { p.y0 } else { p.y1 }
      }
    }
    p
  }
  let edges_out = @svg.Markup::new()
  let labels_out = @svg.Markup::new()
  // Vertical runs of the edges, to keep group titles out from under them.
  let runs : Array[Double] = []
  let trim_length = @svg.marker_trim("arrow_point")
  for k, edge in model.edges {
    let a = ends[k * 2]
    let b = ends[k * 2 + 1]
    if a < 0 || b < 0 {
      continue
    }
    let s = port(a, edge.lhs_dir.index(), edge.lhs_group)
    let e = port(b, edge.rhs_dir.index(), edge.rhs_group)
    if s.x == e.x && s.y == e.y && s.dx == e.dx {
      // An edge from a side back to the same side: part the two ends so it shows as a loop.
      s.x -= 8 * s.dy.abs()
      s.y -= 8 * s.dx.abs()
      e.x += 8 * s.dy.abs()
      e.y += 8 * s.dx.abs()
    }
    let routed = route(s, e)
    if s.wire {
      routed.insert(0, row_y[node_row[a]] + half)
      routed.insert(0, center_x(a))
    }
    if e.wire {
      routed.push(center_x(b))
      routed.push(row_y[node_row[b]] + half)
    }
    let points = simplify(routed)
    if points.length() < 4 {
      continue
    }
    let start_trim = if edge.lhs_into && !s.wire {
      trim_length + s.gap
    } else {
      0
    }
    let end_trim = if edge.rhs_into && !e.wire {
      trim_length + e.gap
    } else {
      0
    }
    edges_out.write(
      "<g class=\"pele-edge\" data-id=\"\{@svg.esc_text(edge.lhs_id + "-" + edge.rhs_id)}\">",
    )
    edges_out.write("<path d=\"\{path_data(points, start_trim, end_trim)}\"/>")
    if edge.lhs_into {
      edges_out.write(
        @svg.marker(
          "arrow_point",
          s.x + s.dx * s.gap,
          s.y + s.dy * s.gap,
          -s.dx,
          -s.dy,
          "var(--_l)",
        ),
      )
    }
    if edge.rhs_into {
      edges_out.write(
        @svg.marker(
          "arrow_point",
          e.x + e.dx * e.gap,
          e.y + e.dy * e.gap,
          -e.dx,
          -e.dy,
          "var(--_l)",
        ),
      )
    }
    edges_out.write("</g>")
    let mut best = -1
    let mut best_length = -1.0
    let mut flat = -1
    let mut flat_length = -1.0
    let label = edge_labels[k]
    for i = 0; i < points.length(); i = i + 2 {
      min_x = @util.js_min(min_x, points[i] - 4)
      max_x = @util.js_max(max_x, points[i] + 4)
      min_y = @util.js_min(min_y, points[i + 1] - 4)
      max_y = @util.js_max(max_y, points[i + 1] + 4)
    }
    for i = 0; i + 3 < points.length(); i = i + 2 {
      let horizontal = (points[i + 1] - points[i + 3]).abs() < 0.01
      let length = (points[i] - points[i + 2]).abs() +
        (points[i + 1] - points[i + 3]).abs()
      if !horizontal {
        runs.push(points[i])
        runs.push(@util.js_min(points[i + 1], points[i + 3]))
        runs.push(@util.js_max(points[i + 1], points[i + 3]))
      }
      if length > best_length {
        best = i
        best_length = length
      }
      if horizontal && length > flat_length {
        flat = i
        flat_length = length
      }
    }
    if label.width > 0 {
      let at = if flat_length >= label.width + 8 { flat } else { best }
      let mut x = (points[at] + points[at + 2]) / 2
      let mut y = (points[at + 1] + points[at + 3]) / 2
      let w = label.width + 8
      let upright = (points[at] - points[at + 2]).abs() < 0.01
      // On a short run next to a node the label would land on the node, so it moves off to the side.
      for p in [s, e] {
        if x + w / 2 <= p.x0 ||
          x - w / 2 >= p.x1 ||
          y + label.height / 2 <= p.y0 ||
          y - label.height / 2 >= p.y1 {
          continue
        }
        if upright {
          x = if x >= (p.x0 + p.x1) / 2 {
            p.x1 + w / 2 + 4
          } else {
            p.x0 - w / 2 - 4
          }
        } else {
          y = if y >= (p.y0 + p.y1) / 2 {
            p.y1 + label.height / 2 + 4
          } else {
            p.y0 - label.height / 2 - 4
          }
        }
      }
      min_x = @util.js_min(min_x, x - w / 2)
      max_x = @util.js_max(max_x, x + w / 2)
      min_y = @util.js_min(min_y, y - label.height / 2)
      max_y = @util.js_max(max_y, y + label.height / 2)
      @svg.write_edge_label(
        labels_out,
        edge.lhs_id + "-" + edge.rhs_id,
        label,
        x,
        y,
        "",
        icons?=options.icons,
      )
    }
  }
  let clusters = @svg.Markup::new()
  for g, group in groups {
    let x = left(g)
    let y = top(g)
    let w = right(g) - x
    let label = group_labels[g]
    clusters.write(
      "<g class=\"pele-cluster\" data-id=\"\{@svg.esc_text(group.id)}\">" +
      "<rect x=\"\{@svg.num(x)}\" y=\"\{@svg.num(y)}\" width=\"\{@svg.num(w)}\" height=\"\{@svg.num(bottom(g) - y)}\" fill=\"var(--_a)\" fill-opacity=\"0.5\" stroke=\"var(--_b)\"\{@svg.ROUNDED}/>",
    )
    if head_w[g] > 0 {
      // The title starts at the left, or after the edges that come down through that corner.
      let band = y + head_h[g] + 12
      let crossings : Array[Double] = []
      for i = 0; i < runs.length(); i = i + 3 {
        if runs[i + 1] < band &&
          runs[i + 2] > y &&
          runs[i] > x &&
          runs[i] < x + w {
          crossings.push(runs[i])
        }
      }
      crossings.sort()
      crossings.push(x + w - 4)
      let mut start = x + 10
      for crossing in crossings {
        if crossing - 6 - start >= head_w[g] {
          break
        }
        start = @util.js_max(start, crossing + 6)
      }
      if start + head_w[g] > x + w - 4 {
        start = x + 10
      }
      let cy = y + 6 + head_h[g] / 2
      let mut text_x = start
      if group.icon is Some(icon) && icon != "" {
        clusters.write(
          icon_slot(icon, start, cy - badge / 2, badge, options.icons),
        )
        text_x += badge + 6
      }
      @svg.write_label(
        clusters,
        label,
        text_x + label.width / 2,
        cy,
        " class=\"pele-cluster-label\" fill=\"var(--_m)\"",
        icons?=options.icons,
      )
    }
    clusters.write("</g>")
  }
  let nodes_out = @svg.Markup::new()
  let glyph = icon_size * 0.5
  let text_size = @util.js_max(6, (size * 0.75).round())
  for i, node in nodes {
    let at = "data-id=\"\{@svg.esc_text(node.id)}\" transform=\"translate(\{@svg.num(center_x(i))},\{@svg.num(row_y[node_row[i]])})\""
    if node.kind is Junction {
      nodes_out.write(
        "<g class=\"pele-node pele-junction\" \{at}><circle cy=\"\{@svg.num(half)}\" r=\"\{whole(DOT)}\" fill=\"var(--_l)\"/></g>",
      )
      continue
    }
    nodes_out.write(
      "<g class=\"pele-node pele-service\" \{at}>" +
      "<rect x=\"\{@svg.num(-half)}\" width=\"\{@svg.num(icon_size)}\" height=\"\{@svg.num(icon_size)}\" fill=\"var(--_s)\" stroke=\"var(--_b)\"\{@svg.ROUNDED}/>",
    )
    match (node.icon, node.icon_text) {
      (Some(icon), _) if icon != "" =>
        nodes_out.write(
          icon_slot(
            icon,
            -glyph / 2,
            (icon_size - glyph) / 2,
            glyph,
            options.icons,
          ),
        )
      (_, Some(icon_text)) if icon_text != "" => {
        let text = @text.layout_label(
          Some(icon_text),
          false,
          measurer,
          text_size,
          icon_size - 8,
        )
        let line_height = if text.line_height == 0 {
          1.0
        } else {
          text.line_height
        }
        let lines = @cmp.maximum(
          1,
          ((icon_size - 4) / line_height).floor().to_int(),
        )
        @svg.write_label(
          nodes_out,
          fit(text, icon_size - 8, lines, measurer),
          0,
          half,
          " class=\"pele-icon-text\" font-size=\"\{whole(text_size)}\"",
          icons?=options.icons,
        )
      }
      _ => ()
    }
    @svg.write_label(
      nodes_out,
      labels[i],
      0,
      icon_size + LABEL_GAP + labels[i].height / 2,
      " class=\"pele-label\"",
      icons?=options.icons,
    )
    nodes_out.write("</g>")
  }
  let title = @text.layout_label(
    model.title,
    false,
    measurer,
    size,
    if tight {
      @common.title_room(options)
    } else {
      4000
    },
    base=@text.STYLE_BOLD,
  )
  let title_height = if title.height > 0 { title.height + 12 } else { 0 }
  let width = (@util.js_max(max_x - min_x, title.width) + 2 * pad).ceil()
  let height = (max_y - min_y + title_height + 2 * pad).ceil()
  let ox = ((width - (max_x - min_x)) / 2 - min_x).round()
  let oy = (pad + title_height - min_y).round()
  let body = @svg.Markup::new()
  if !clusters.is_empty() {
    body.write_group("<g class=\"pele-clusters\">", clusters, "</g>")
  }
  if !edges_out.is_empty() {
    body.write_group(
      "<g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\" stroke-linejoin=\"round\">",
      edges_out, "</g>",
    )
  }
  if !labels_out.is_empty() {
    body.write_group(
      "<g class=\"pele-edge-labels\" font-size=\"\{whole(small)}\">",
      labels_out,
      "</g>",
    )
  }
  if !nodes_out.is_empty() {
    body.write_group("<g class=\"pele-nodes\">", nodes_out, "</g>")
  }
  let content = @svg.Markup::new()
  content.write(
    @svg.label_svg(
      title,
      width / 2,
      pad + title.height / 2,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
    ),
  )
  if !body.is_empty() {
    content.write_group(
      "<g transform=\"translate(\{whole(ox)},\{whole(oy)})\">",
      body,
      "</g>",
    )
  }
  let svg = @svg.markup_document(
    "architecture",
    width,
    height,
    size,
    options,
    model.acc_title,
    model.acc_descr,
    content,
  )
  { svg, width, height, links: [], }
}
