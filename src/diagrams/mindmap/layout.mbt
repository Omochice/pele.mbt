///|
/// The shapes of Mermaid's node types, by type.
/// A node without delimiters is text on a line, except the root.
let shape_names : Array[String] = [
  "", "rounded", "rect", "circle", "cloud", "bang", "hex",
]

///|
const ROOT_SHAPE : String = "stadium"

///|
const GAP_X : Double = 36

///|
const GAP_Y : Double = 8

///|
/// Between two subtrees, of which at least one has children of its own.
const GROUP_GAP : Double = 18

///|
const BRANCH_GAP_X : Double = 52

///|
const BRANCH_GAP_Y : Double = 28

///|
/// Running down, each level is set in by this much.
const INDENT : Double = 28

///|
const ROW_GAP : Double = 10

///|
const TEXT_PAD : Double = 6

///|
const PILL_PAD : Double = 12

///|
/// A node's size and where it stands, relative to the root's center.
priv struct Layout {
  parent : Array[Int32]
  shapes : Array[String]
  labels : Array[@text.Label]
  w : Array[Double]
  h : Array[Double]
  /// How far the label sits below the middle of its node.
  dy : Array[Double]
  /// Where links meet the node, measured down from its top.
  anchor : Array[Double]
  x : Array[Double]
  y : Array[Double]
  /// Which side of the root a node is on: 1 to the right, -1 to the left.
  side : Array[Int32]
}

///|
fn max_node_width(config : @types.Config) -> Double {
  guard config.get("mindmap") is Some(Object(section)) else { return 200 }
  match section.get("maxNodeWidth") {
    Some(Number(width, ..)) if width > 0 => @util.js_min(width, 2000)
    _ => 200
  }
}

///|
fn layout(
  model : MindmapModel,
  config : @types.Config,
  options : @types.RenderOptions,
  down : Bool,
) -> Layout {
  let size = options.font_size.unwrap_or(16)
  let measurer = options.text_measurer()
  let wrap = max_node_width(config)
  let nodes = model.nodes
  let n = nodes.length()
  let parent = Array::make(n, 0)
  let depth = Array::make(n, 0)
  for i in 0..<n {
    for child in nodes[i].children {
      parent[child.id] = i
      depth[child.id] = depth[i] + 1
    }
  }
  // An outline has the width the host gives it, less what its level is set in.
  let room = match options.max_width {
    Some(available) if down && available > 0 =>
      available - 2 * options.padding.unwrap_or(8)
    _ => @double.infinity
  }
  let labels = []
  let shapes = []
  let w = Array::make(n, 0.0)
  let h = Array::make(n, 0.0)
  let dy = Array::make(n, 0.0)
  let anchor = Array::make(n, 0.0)
  for i in 0..<n {
    let node = nodes[i]
    let fit = @util.js_min(
      wrap,
      @util.js_max(72, room - depth[i].to_double() * INDENT - 2 * TEXT_PAD),
    )
    let label = @text.layout_label(Some(node.descr), true, measurer, size, fit)
    labels.push(label)
    let th = @util.js_max(label.height, (size * 1.5).round())
    let named = if node.node_type >= 0 && node.node_type < shape_names.length() {
      shape_names[node.node_type]
    } else {
      ""
    }
    let shape = if named != "" {
      named
    } else if i == 0 {
      ROOT_SHAPE
    } else {
      ""
    }
    // In an outline the root heads a column, and the trunk drops from under its left end.
    // A circle or a cloud would stand wide of that, so the root is a pill there unless it is a box already.
    let shape = if down && i == 0 && shape != "rect" && shape != "rounded" {
      ROOT_SHAPE
    } else {
      shape
    }
    shapes.push(shape)
    if shape == "" {
      // A node with no shape of its own is plain text when it ends a branch, and text in a
      // tinted pill when the branch goes on from it, which sets the levels apart.
      let pill = !node.children.is_empty()
      w[i] = label.width + 2 * (if pill { PILL_PAD } else { TEXT_PAD })
      h[i] = th + (if pill { 6 } else { 0 })
      anchor[i] = h[i] / 2
    } else {
      let s = @svg.shape_size(shape, label.width, th)
      w[i] = s.w
      h[i] = s.h
      dy[i] = s.dy
      anchor[i] = s.h / 2
    }
  }

  // Each subtree takes a band of height `extent`. `rel` is a subtree's offset among its siblings,
  // `own` the node's offset inside its band, and `kids` the offset of its children's bands.
  let extent = Array::make(n, 0.0)
  let rel = Array::make(n, 0.0)
  let own = Array::make(n, 0.0)
  let kids = Array::make(n, 0.0)
  let mut stacked = 0.0

  // Stacks subtrees top to bottom and returns the height at which their parent's anchor belongs.
  let stack = (
    list : Array[MindmapNode],
    from : Int32,
    to : Int32,
    gap : Double,
  ) => {
    let mut y = 0.0
    let mut last = 0.0
    for k in from..<to {
      let c = list[k].id
      rel[c] = y
      let grouped = !list[k].children.is_empty() ||
        (k + 1 < to && !list[k + 1].children.is_empty())
      last = if grouped { @util.js_max(gap, GROUP_GAP) } else { gap }
      y += extent[c] + last
    }
    stacked = y - last
    let a = list[from].id
    let b = list[to - 1].id
    (rel[a] + own[a] + anchor[a] + rel[b] + own[b] + anchor[b]) / 2
  }

  // Nodes are in depth-first order, so going backwards visits children before their parent.
  for i = n - 1; i > 0; i = i - 1 {
    let children = nodes[i].children
    if children.is_empty() {
      extent[i] = h[i]
      continue
    }
    let top = stack(children, 0, children.length(), GAP_Y) - anchor[i]
    let low = @util.js_min(0, top)
    extent[i] = @util.js_max(stacked, top + h[i]) - low
    own[i] = top - low
    kids[i] = -low
  }
  let x = Array::make(n, 0.0)
  let y = Array::make(n, 0.0)
  let band = Array::make(n, 0.0)
  let side = Array::make(n, 0)
  if down {
    // Nodes are in depth-first order, which is the order of an outline's rows.
    let mut row = 0.0
    for i in 0..<n {
      if i > 0 && parent[i] == 0 {
        row += ROW_GAP
      }
      x[i] = depth[i].to_double() * INDENT + w[i] / 2
      y[i] = row
      row += h[i] + ROW_GAP
    }
  } else if n > 0 {
    // The first branches go right and the rest left, split where the two sides are closest in height.
    let branches = nodes[0].children
    let count = branches.length()
    let mut total = 0.0
    for branch in branches {
      total += extent[branch.id]
    }
    let mut split = count
    let mut best = @double.infinity
    let mut right = 0.0
    for k in 1..<count {
      right += extent[branches[k - 1].id]
      let diff = (2.0 * right -
      total +
      (2 * k - count).to_double() * BRANCH_GAP_Y).abs()
      if diff < best {
        best = diff
        split = k
      }
    }
    for part in [(0, split, 1), (split, count, -1)] {
      let (from, to, dir) = part
      if from >= count {
        continue
      }
      let middle = stack(branches, from, to, BRANCH_GAP_Y)
      for k in from..<to {
        let c = branches[k].id
        band[c] = rel[c] - middle
        side[c] = dir
      }
    }
    y[0] = -h[0] / 2
    for i in 0..<n {
      if i > 0 {
        y[i] = band[i] + own[i]
      }
      for child in nodes[i].children {
        let c = child.id
        if i > 0 {
          side[c] = side[i]
          band[c] = band[i] + kids[i] + rel[c]
        }
        x[c] = x[i] +
          side[c].to_double() *
          (w[i] / 2 + (if i > 0 { GAP_X } else { BRANCH_GAP_X }) + w[c] / 2)
      }
    }
  }
  { parent, shapes, labels, w, h, dy, anchor, x, y, side, }
}
