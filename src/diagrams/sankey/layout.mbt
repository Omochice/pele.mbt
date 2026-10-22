///|
/// Which column a node takes when it does not simply follow its distance from a source.
pub(all) enum Alignment {
  Justify
  Left
  Right
  Center
}

///|
pub(all) struct LayoutOptions {
  width : Double
  height : Double
  node_width : Double
  node_padding : Double
  /// Height of a label line; thin nodes are kept at least this far apart where there is room.
  label_height : Double
  alignment : Alignment
}

///|
pub(all) struct PlacedNode {
  layer : Int32
  /// Total flow through the node, in the diagram's units.
  value : Double
  x : Double
  mut y : Double
  mut height : Double
}

///|
pub(all) struct PlacedLink {
  source : Int32
  target : Int32
  value : Double
  mut thickness : Double
  /// Vertical centers of the band where it leaves its source and where it enters its target.
  mut source_y : Double
  mut target_y : Double
}

///|
pub(all) struct SankeyLayout {
  nodes : Array[PlacedNode]
  links : Array[PlacedLink]
}

///|
const PASSES : Int32 = 6

///|
/// Orders by `first - second` as JavaScript's `a - b || ...` does, then by index.
/// A NaN difference counts as a tie, so the order stays total.
fn by_position(first : Double, second : Double, a : Int32, b : Int32) -> Int32 {
  let difference = first - second
  if difference < 0 {
    -1
  } else if difference > 0 {
    1
  } else {
    a.compare(b)
  }
}

///|
/// Fails with the name of a node on a cycle, given the nodes left after removing every node whose
/// predecessors were all placed.
fn circular(
  db : SankeyDb,
  links : Array[PlacedLink],
  incoming : Array[Array[Int32]],
  pending : Array[Int32],
) -> Unit raise @errors.PeleError {
  // Every node left over has a predecessor that is left over too; walking back finds the loop.
  let mut stuck = 0
  while pending[stuck] == 0 {
    stuck += 1
  }
  let seen = Array::make(pending.length(), false)
  while !seen[stuck] {
    seen[stuck] = true
    for k in incoming[stuck] {
      if pending[links[k].source] > 0 {
        stuck = links[k].source
        break
      }
    }
  }
  raise @errors.pele_error(
    "Sankey diagrams cannot have circular links, and \"\{db.nodes[stuck].id}\" is part of one.",
    code=Semantic,
    kind="sankey",
  )
}

///|
/// Places nodes in columns by their distance from a source, sizes them by their flow, and
/// then lets each column settle next to its neighbours so that the bands cross less.
/// Raises a semantic `PeleError` when the links form a cycle.
pub fn layout_sankey(
  db : SankeyDb,
  options : LayoutOptions,
) -> SankeyLayout raise @errors.PeleError {
  let n = db.nodes.length()
  let links : Array[PlacedLink] = db.links.map(link => {
    source: link.source.index,
    target: link.target.index,
    value: if link.value.is_inf() || link.value.is_nan() || !(link.value > 0) {
      0
    } else {
      link.value
    },
    thickness: 0,
    source_y: 0,
    target_y: 0,
  })
  let outgoing : Array[Array[Int32]] = Array::makei(n, _ => [])
  let incoming : Array[Array[Int32]] = Array::makei(n, _ => [])
  for k, link in links {
    outgoing[link.source].push(k)
    incoming[link.target].push(k)
  }

  // Longest distance from a source, in topological order; what is left over lies on a cycle.
  let depth = Array::make(n, 0)
  let pending = Array::make(n, 0)
  let order : Array[Int32] = []
  for i in 0..<n {
    pending[i] = incoming[i].length()
    if pending[i] == 0 {
      order.push(i)
    }
  }
  let mut q = 0
  while q < order.length() {
    let i = order[q]
    for k in outgoing[i] {
      let t = links[k].target
      if depth[t] < depth[i] + 1 {
        depth[t] = depth[i] + 1
      }
      pending[t] -= 1
      if pending[t] == 0 {
        order.push(t)
      }
    }
    q += 1
  }
  if order.length() < n {
    circular(db, links, incoming, pending)
  }
  let mut layers = 1
  for i in 0..<n {
    if depth[i] + 1 > layers {
      layers = depth[i] + 1
    }
  }
  let reach = Array::make(n, 0)
  for r = n - 1; r >= 0; r = r - 1 {
    let i = order[r]
    for k in outgoing[i] {
      if reach[i] < reach[links[k].target] + 1 {
        reach[i] = reach[links[k].target] + 1
      }
    }
  }

  // Flows are scaled to the largest one, so that sums of huge values stay finite.
  let mut largest = 0.0
  for link in links {
    if link.value > largest {
      largest = link.value
    }
  }
  let unit : Double = if largest > 0 { 1.0 / largest } else { 0.0 }

  let nodes : Array[PlacedNode] = []
  let flow = Array::make(n, 0.0)
  let columns : Array[Array[Int32]] = Array::makei(layers, _ => [])
  let step = if layers > 1 {
    (options.width - options.node_width) / (layers - 1).to_double()
  } else {
    0
  }
  for i in 0..<n {
    let layer = match options.alignment {
      Left => depth[i]
      Right => layers - 1 - reach[i]
      Center => {
        let mut layer = depth[i]
        if incoming[i].length() == 0 && outgoing[i].length() > 0 {
          layer = layers
          for k in outgoing[i] {
            if depth[links[k].target] - 1 < layer {
              layer = depth[links[k].target] - 1
            }
          }
        }
        layer
      }
      Justify => if outgoing[i].length() > 0 { depth[i] } else { layers - 1 }
    }
    let mut into = 0.0
    let mut out = 0.0
    let mut value = 0.0
    let mut value_out = 0.0
    for k in incoming[i] {
      into += links[k].value * unit
      value += links[k].value
    }
    for k in outgoing[i] {
      out += links[k].value * unit
      value_out += links[k].value
    }
    flow[i] = @cmp.maximum(into, out)
    nodes.push({
      layer,
      value: @cmp.maximum(value, value_out),
      x: layer.to_double() * step,
      y: 0,
      height: 0,
    })
    columns[layer].push(i)
  }

  let mut tallest = 1
  for column in columns {
    if column.length() > tallest {
      tallest = column.length()
    }
  }
  let gap = if tallest > 1 {
    @cmp.minimum(
      options.node_padding,
      options.height / (tallest - 1).to_double(),
    )
  } else {
    options.node_padding
  }
  let mut scale = @double.infinity
  for column in columns {
    let mut sum = 0.0
    for i in column {
      sum += flow[i]
    }
    if sum > 0 {
      scale = @cmp.minimum(
        scale,
        (options.height - (column.length() - 1).to_double() * gap) / sum,
      )
    }
  }
  if scale.is_inf() || scale.is_nan() || scale < 0 {
    scale = 0
  }

  // A thin node still needs room for its label. Where every column can afford it, each node
  // claims at least a label's height, and the flows are scaled down to make that fit.
  let mut claim = @cmp.maximum(0.0, options.label_height - gap)
  let fits = (s : Double, claim : Double) => {
    for column in columns {
      let mut extent = (column.length() - 1).to_double() * gap
      for i in column {
        extent += @cmp.maximum(flow[i] * s, claim)
      }
      if extent > options.height + 1.0e-6 {
        return false
      }
    }
    true
  }
  if claim > 0 && !fits(scale, claim) {
    if fits(0, claim) {
      let mut low = 0.0
      for _ in 0..<40 {
        let mid = (low + scale) / 2
        if fits(mid, claim) {
          low = mid
        } else {
          scale = mid
        }
      }
      scale = low
    } else {
      claim = 0
    }
  }

  // The room a node keeps clear above and below itself.
  let margin = Array::make(n, 0.0)
  for link in links {
    link.thickness = link.value * unit * scale
  }
  for column in columns {
    let mut y = 0.0
    for i in column {
      nodes[i].height = flow[i] * scale
      margin[i] = @cmp.maximum(0.0, claim - nodes[i].height) / 2
      nodes[i].y = y + margin[i]
      y += nodes[i].height + 2 * margin[i] + gap
    }
    // Spare room is shared out between the nodes of a column.
    let spare = (options.height - y + gap) / (column.length() + 1).to_double()
    for k, i in column {
      nodes[i].y += spare * (k + 1).to_double()
    }
  }

  let center = (i : Int32) => nodes[i].y + nodes[i].height / 2

  // Bands leave and enter a node in the order of where they go, so they do not cross at it.
  // These are the offsets of each band's middle from the top of the node at either end.
  let source_offset = Array::make(links.length(), 0.0)
  let target_offset = Array::make(links.length(), 0.0)
  let by_target = (a : Int32, b : Int32) => {
    by_position(center(links[a].target), center(links[b].target), a, b)
  }
  let by_source = (a : Int32, b : Int32) => {
    by_position(center(links[a].source), center(links[b].source), a, b)
  }
  let by_center = (a : Int32, b : Int32) => {
    by_position(center(a), center(b), a, b)
  }
  let stack_out = (i : Int32) => {
    let mut y = 0.0
    outgoing[i].sort_by(by_target)
    for k in outgoing[i] {
      source_offset[k] = y + links[k].thickness / 2
      y += links[k].thickness
    }
  }
  let stack_in = (i : Int32) => {
    let mut y = 0.0
    incoming[i].sort_by(by_source)
    for k in incoming[i] {
      target_offset[k] = y + links[k].thickness / 2
      y += links[k].thickness
    }
  }
  let stack_all = () => {
    for i in 0..<n {
      stack_out(i)
      stack_in(i)
    }
  }

  // Moves each node of a column towards where its bands would run level, then restores the
  // order and the gaps. `forward` looks at the bands coming in, otherwise at those going out.
  let settle = (column : Array[Int32], pull : Double, forward : Bool) => {
    for i in column {
      let list = if forward { incoming[i] } else { outgoing[i] }
      if list.length() == 0 {
        continue
      }
      if forward {
        stack_in(i)
      } else {
        stack_out(i)
      }
      let mut weighted = 0.0
      let mut weight = 0.0
      let mut plain = 0.0
      for k in list {
        let level = if forward {
          nodes[links[k].source].y + source_offset[k] - target_offset[k]
        } else {
          nodes[links[k].target].y + target_offset[k] - source_offset[k]
        }
        weighted += level * links[k].thickness
        weight += links[k].thickness
        plain += center(if forward { links[k].source } else { links[k].target }) -
          nodes[i].height / 2
      }
      let wanted = if weight > 0 {
        weighted / weight
      } else {
        plain / list.length().to_double()
      }
      nodes[i].y += (wanted - nodes[i].y) * pull
    }
    column.sort_by(by_center)
    let mut y = 0.0
    for i in column {
      if nodes[i].y - margin[i] < y {
        nodes[i].y = y + margin[i]
      }
      y = nodes[i].y + nodes[i].height + margin[i] + gap
    }
    y = options.height
    for k = column.length() - 1; k >= 0; k = k - 1 {
      let i = column[k]
      if nodes[i].y + nodes[i].height + margin[i] > y {
        nodes[i].y = y - nodes[i].height - margin[i]
      }
      y = nodes[i].y - margin[i] - gap
    }
  }

  stack_all()
  for pass in 0..<PASSES {
    let pull = @math.pow(0.99, pass.to_double())
    for l = layers - 2; l >= 0; l = l - 1 {
      settle(columns[l], pull, false)
    }
    stack_all()
    for l = 1; l < layers; l = l + 1 {
      settle(columns[l], pull, true)
    }
    stack_all()
  }
  for k, link in links {
    link.source_y = nodes[link.source].y + source_offset[k]
    link.target_y = nodes[link.target].y + target_offset[k]
  }
  { nodes, links, }
}
