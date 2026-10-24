///|
/// A node as it is drawn: a flow, a collapsed flow, a node or a connector.
pub(all) struct GraphNode {
  id : String
  label : String?
  label_type : @flowchart.LabelType
  mut shape : String
  is_group : Bool
  parent_id : String?
  mut css_styles : Array[String]
  mut css_compiled_styles : Array[String]
  mut css_classes : String
  dir : String?
  link : String?
  link_target : String?
  tooltip : String?
  /// Palette slot of a container.
  mut color_index : Int32?
  /// What a node is, which picks its palette slot.
  mut kind : String?
  metadata : Map[String, Json]?
}

///|
/// An edge as it is drawn.
pub(all) struct GraphEdge {
  id : String
  is_user_defined_id : Bool
  start : String
  end : String
  kind : String
  label : String
  label_type : @flowchart.LabelType
  thickness : String?
  pattern : String?
  minlen : Int32?
  arrow_type_start : String
  arrow_type_end : String
  css_compiled_styles : Array[String]
  style : Array[String]
  classes : String
  animate : Json?
  animation : Json?
  curve : Json?
  metadata : Map[String, Json]?
}

///|
/// The nodes and edges an agentflow draws.
pub(all) struct AgentGraph {
  nodes : Array[GraphNode]
  edges : Array[GraphEdge]
}

///|
/// Resolves a parsed agentflow into the nodes and edges that are drawn: flow membership, collapsed flows, shapes reduced to the ones agentflow has, class styles and palette slots.
/// Shape and containment problems are reported on the model as diagnostics.
pub fn build_agent_graph(
  db : AgentflowDb,
  palette_length : Int32,
  default_curve? : String,
) -> AgentGraph {
  let subgraphs = db.subgraphs
  let compiled = (class_names : Array[String]) => {
    let out = []
    for name in class_names {
      if db.classes.get(name) is Some(def) {
        for s in def.styles {
          out.push(s)
        }
        for s in def.text_styles {
          out.push(s)
        }
      }
    }
    out.map(@util.trim)
  }
  let collapsed_flow = (sg : AgentSubgraph) => {
    match sg.metadata {
      Some(fields) => fields.get("view") is Some(String("collapsed"))
      None => false
    }
  }
  // Everything inside a collapsed flow is hidden, and stands for its outermost collapsed flow.
  // Mermaid walks the whole inside of each collapsed flow, in the order the flows closed, and the last walk to reach a thing wins.
  // A thing has one container, so a later walk can only enter an earlier one through its root: it stops there, and the root's owner is followed afterwards.
  let hidden : Map[String, Unit] = Map([])
  let owner : Map[String, String] = Map([])
  let walked : Map[String, Unit] = Map([])
  for sg in subgraphs {
    if !collapsed_flow(sg) || hidden.contains(sg.id) {
      continue
    }
    let pending = [sg.id]
    while pending.pop() is Some(id) {
      guard db.subgraph(id) is Some(inner) else { continue }
      for child_id in inner.nodes {
        if child_id == sg.id || hidden.contains(child_id) {
          continue
        }
        hidden[child_id] = ()
        owner[child_id] = sg.id
        if !walked.contains(child_id) {
          pending.push(child_id)
        }
      }
    }
    walked[sg.id] = ()
  }
  let collapsed_into : Map[String, String] = Map([])
  for id, _ in hidden {
    let path = [id]
    let mut top = owner[id]
    while true {
      let known = collapsed_into.get(top)
      let up = match known {
        Some(_) => known
        None => owner.get(top)
      }
      guard up is Some(up) else { break }
      if known is None {
        path.push(top)
      }
      top = up
      if known is Some(_) {
        break
      }
    }
    for p in path {
      collapsed_into[p] = top
    }
  }
  let position : Map[String, Int32] = Map([])
  for i, sg in subgraphs {
    position[sg.id] = i
  }
  // Two flows can each name the other; the nesting that would close the loop is dropped.
  let parent_of : Map[String, String] = Map([])
  let closes_loop = (child_id : String, parent_id : String, at : Int32) => {
    // Only a flow handled earlier in this pass can already be above the parent.
    match position.get(child_id) {
      Some(child_at) if child_at >= at => {
        let mut current : String? = Some(parent_id)
        let mut hops = 0
        while current is Some(c) && hops <= subgraphs.length() {
          if c == child_id {
            return true
          }
          current = parent_of.get(c)
          hops += 1
        }
        false
      }
      _ => false
    }
  }
  for i = subgraphs.length() - 1; i >= 0; i = i - 1 {
    let sg = subgraphs[i]
    if hidden.contains(sg.id) {
      continue
    }
    for id in sg.nodes {
      if closes_loop(id, sg.id, i) {
        db.emit(
          "CONTAINMENT_VIOLATION",
          "warning",
          "Container \"\{sg.id}\" cannot contain \"\{id}\" because \"\{id}\" already contains it. The nesting that would close the loop is dropped.",
          node_id=id,
        )
        continue
      }
      parent_of[id] = sg.id
    }
  }
  let nodes : Array[GraphNode] = []
  let by_id : Map[String, GraphNode] = Map([])
  for i = subgraphs.length() - 1; i >= 0; i = i - 1 {
    let sg = subgraphs[i]
    if hidden.contains(sg.id) {
      continue
    }
    let collapsed = collapsed_flow(sg)
    let metadata = if collapsed {
      let fields : Map[String, Json] = Map([])
      if sg.metadata is Some(old) {
        for key, value in old {
          fields[key] = value
        }
      }
      fields["containerType"] = Json::string("flow")
      Some(fields)
    } else {
      sg.metadata
    }
    let node : GraphNode = {
      id: sg.id,
      label: Some(sg.title),
      label_type: sg.label_type,
      shape: if collapsed {
        "collapsedGroup"
      } else {
        "flowGroup"
      },
      is_group: !collapsed,
      parent_id: parent_of.get(sg.id),
      css_styles: [],
      css_compiled_styles: compiled(sg.classes),
      css_classes: sg.classes.join(" "),
      dir: sg.dir,
      link: None,
      link_target: None,
      tooltip: None,
      color_index: None,
      kind: None,
      metadata,
    }
    nodes.push(node)
    by_id[sg.id] = node
  }
  for id, vertex in db.nodes {
    if hidden.contains(id) {
      continue
    }
    if by_id.get(id) is Some(existing) {
      existing.css_styles = vertex.styles
      existing.css_compiled_styles = compiled(vertex.classes)
      existing.css_classes = vertex.classes.join(" ")
      continue
    }
    let shape = match resolve_shape_alias(vertex.kind) {
      None | Some("square") => "squareRect"
      Some(shape) => shape
    }
    let node : GraphNode = {
      id,
      label: vertex.text,
      label_type: vertex.label_type,
      shape,
      is_group: false,
      parent_id: parent_of.get(id),
      css_styles: vertex.styles,
      css_compiled_styles: compiled(["default", "node", ..vertex.classes]),
      css_classes: "default " + vertex.classes.join(" "),
      dir: vertex.dir,
      link: vertex.link,
      link_target: vertex.link_target,
      tooltip: db.tooltips.get(id),
      color_index: None,
      kind: None,
      metadata: vertex.metadata,
    }
    nodes.push(node)
    by_id[id] = node
  }
  let edges : Array[GraphEdge] = []
  for index, raw in db.edges {
    let start = collapsed_into.get(raw.start).unwrap_or(raw.start)
    let end = collapsed_into.get(raw.end).unwrap_or(raw.end)
    // An edge between two things inside one collapsed flow has nothing left to connect.
    if start == end && raw.start != raw.end {
      continue
    }
    let style = db.default_edge_style.unwrap_or([]).copy()
    if raw.style is Some(own) {
      for s in own {
        style.push(s)
      }
    }
    let arrow = match raw.kind {
      Some("arrow_open") => "none"
      Some("arrow_cross" | "arrow_point" as kind) => kind
      _ => "arrow_point"
    }
    let curve = match raw.interpolate {
      Some(value) if @util.js_truthy(value) => Some(value)
      _ =>
        match db.default_interpolate {
          Some(name) if name != "" => Some(Json::string(name))
          _ => default_curve.map(Json::string)
        }
    }
    edges.push({
      id: if raw.id != "" {
        raw.id
      } else {
        "L_\{start}_\{end}_\{index}"
      },
      is_user_defined_id: raw.is_user_defined_id,
      start,
      end,
      kind: raw.kind.unwrap_or("normal"),
      label: raw.text,
      label_type: raw.label_type,
      thickness: raw.stroke,
      pattern: raw.stroke,
      minlen: raw.length,
      arrow_type_start: "none",
      arrow_type_end: arrow,
      css_compiled_styles: compiled(raw.classes),
      style,
      classes: "edge-thickness-normal edge-pattern-solid flowchart-link",
      animate: raw.animate,
      animation: raw.animation,
      curve,
      metadata: raw.metadata,
    })
  }
  normalise_node_shapes(nodes, db)
  // Containers are numbered in the order they were written: a walk of the nesting, parents first.
  // `subgraphs` itself is in the order the blocks closed, with a nested flow before its parent.
  let children : Map[String, Array[String]] = Map([])
  for sg in subgraphs {
    guard parent_of.get(sg.id) is Some(parent) else { continue }
    match children.get(parent) {
      Some(kids) => kids.push(sg.id)
      None => children[parent] = [sg.id]
    }
  }
  let order : Map[String, Int32] = Map([])
  for sg in subgraphs {
    if parent_of.contains(sg.id) {
      continue
    }
    let pending = [sg.id]
    while pending.pop() is Some(id) {
      if order.contains(id) {
        continue
      }
      order[id] = order.length()
      if children.get(id) is Some(kids) {
        for k = kids.length() - 1; k >= 0; k = k - 1 {
          pending.push(kids[k])
        }
      }
    }
  }
  assign_color_slots(
    nodes,
    id => {
      if db.connectors.contains(id) {
        return Some("connector")
      }
      db.nodes.get(id).map(vertex => db.vertex_kind(vertex))
    },
    order,
    palette_length,
  )
  { nodes, edges, }
}
