///|
/// A node as drawn: a vertex, or a subgraph as a group or a collapsed node.
pub(all) struct GraphNode {
  id : String
  label : String?
  label_type : LabelType
  shape : String
  is_group : Bool
  parent_id : String?
  mut css_styles : Array[String]
  mut css_compiled_styles : Array[String]
  mut css_classes : String
  dir : String?
  link : String?
  link_target : String?
  tooltip : String?
  icon : String?
  pos : String?
  img : String?
  asset_width : Double?
  asset_height : Double?
  constraint : String?
  color_index : Int32?
  metadata : Map[String, Json]?
}

///|
/// An edge as drawn. `kind` is pele's `type`; `curve` is any YAML value node data gave it, as in pele.
pub(all) struct GraphEdge {
  id : String
  is_user_defined_id : Bool
  start : String
  end : String
  kind : String
  label : String
  label_type : LabelType
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
}

///|
/// The nodes and edges that are drawn.
pub(all) struct FlowGraph {
  nodes : Array[GraphNode]
  edges : Array[GraphEdge]
}

///|
/// Resolves a parsed flowchart into the nodes and edges that are actually drawn:
/// group membership, collapsed subgraphs, class styles and edge defaults.
pub fn build_flow_graph(model : FlowDb, default_curve? : String) -> FlowGraph {
  let nodes : Array[GraphNode] = []
  let edges : Array[GraphEdge] = []
  let subgraphs = model.subgraphs
  let compiled = (class_names : Array[String]) => {
    let out = []
    for name in class_names {
      guard model.classes.get(name) is Some(def) else { continue }
      for s in def.styles {
        out.push(@util.trim(s))
      }
      for s in def.text_styles {
        out.push(@util.trim(s))
      }
    }
    out
  }
  let subgraph_parent : Map[String, String] = Map([])
  for sg in subgraphs {
    for child_id in sg.nodes {
      if model.subgraph(child_id) is Some(_) {
        subgraph_parent[child_id] = sg.id
      }
    }
  }
  let declaration_index : Map[String, Int32] = Map([])
  let children_of : Map[String, Array[String]] = Map([])
  for sg in subgraphs {
    guard subgraph_parent.get(sg.id) is Some(parent) else { continue }
    match children_of.get(parent) {
      Some(kids) => kids.push(sg.id)
      None => children_of[parent] = [sg.id]
    }
  }
  let mut next_index = 0
  for sg in subgraphs {
    if subgraph_parent.contains(sg.id) {
      continue
    }
    let pending = [sg.id]
    while pending.pop() is Some(id) {
      if declaration_index.contains(id) {
        continue
      }
      declaration_index[id] = next_index
      next_index += 1
      if children_of.get(id) is Some(kids) {
        for i = kids.length() - 1; i >= 0; i = i - 1 {
          pending.push(kids[i])
        }
      }
    }
  }
  let is_collapsed = (id : String) => {
    match model.subgraph(id) {
      Some(sg) => view_is_collapsed(sg.metadata)
      None => false
    }
  }
  let any_collapsed = subgraphs.iter().any(sg => view_is_collapsed(sg.metadata))
  // The outermost collapsed subgraph around each subgraph, resolved once per chain of parents.
  let outermost : Map[String, String?] = Map([])
  let outermost_collapsed = (id : String) => {
    let chain = []
    let seen : Map[String, Unit] = Map([])
    let mut current = Some(id)
    while current is Some(c) && !outermost.contains(c) && !seen.contains(c) {
      seen[c] = ()
      chain.push(c)
      current = subgraph_parent.get(c)
    }
    let mut result = match current {
      Some(c) => outermost.get(c).flatten()
      None => None
    }
    for i = chain.length() - 1; i >= 0; i = i - 1 {
      if result is None && is_collapsed(chain[i]) {
        result = Some(chain[i])
      }
      outermost[chain[i]] = result
    }
    result
  }
  let hidden : Map[String, Unit] = Map([])
  let collapsed_into : Map[String, String] = Map([])
  if any_collapsed {
    for sg in subgraphs {
      guard outermost_collapsed(sg.id) is Some(ancestor) else { continue }
      if sg.id != ancestor {
        hidden[sg.id] = ()
        collapsed_into[sg.id] = ancestor
      }
      for child_id in sg.nodes {
        if child_id == ancestor {
          continue
        }
        hidden[child_id] = ()
        collapsed_into[child_id] = ancestor
      }
    }
  }
  let parent_of : Map[String, String] = Map([])
  let groups : Map[String, Unit] = Map([])
  for i = subgraphs.length() - 1; i >= 0; i = i - 1 {
    let sg = subgraphs[i]
    if hidden.contains(sg.id) {
      continue
    }
    if sg.nodes.length() > 0 {
      groups[sg.id] = ()
    }
    for id in sg.nodes {
      parent_of[id] = sg.id
    }
  }
  let by_id : Map[String, GraphNode] = Map([])
  for i = subgraphs.length() - 1; i >= 0; i = i - 1 {
    let sg = subgraphs[i]
    if hidden.contains(sg.id) {
      continue
    }
    let collapsed = view_is_collapsed(sg.metadata)
    let node : GraphNode = {
      id: sg.id,
      label: Some(sg.title),
      label_type: sg.label_type,
      parent_id: parent_of.get(sg.id),
      css_styles: [],
      css_compiled_styles: compiled(sg.classes),
      css_classes: sg.classes.join(" "),
      shape: if collapsed {
        "collapsedGroup"
      } else {
        "rect"
      },
      dir: sg.dir,
      is_group: !collapsed,
      color_index: declaration_index.get(sg.id),
      metadata: if collapsed {
        None
      } else {
        sg.metadata
      },
      link: None,
      link_target: None,
      tooltip: None,
      icon: None,
      pos: None,
      img: None,
      asset_width: None,
      asset_height: None,
      constraint: None,
    }
    nodes.push(node)
    by_id[sg.id] = node
  }
  for _, vertex in model.nodes {
    if hidden.contains(vertex.id) {
      continue
    }
    if by_id.get(vertex.id) is Some(existing) {
      existing.css_styles = vertex.styles
      existing.css_compiled_styles = compiled(vertex.classes)
      existing.css_classes = vertex.classes.join(" ")
      continue
    }
    let is_group = groups.contains(vertex.id)
    nodes.push({
      id: vertex.id,
      label: vertex.text,
      label_type: vertex.label_type,
      parent_id: parent_of.get(vertex.id),
      css_styles: vertex.styles,
      css_compiled_styles: compiled(["default", "node", ..vertex.classes]),
      css_classes: "default " + vertex.classes.join(" "),
      dir: vertex.dir,
      link: vertex.link,
      link_target: vertex.link_target,
      tooltip: model.tooltips.get(vertex.id),
      icon: vertex.icon,
      pos: vertex.pos,
      img: vertex.img,
      asset_width: vertex.asset_width,
      asset_height: vertex.asset_height,
      constraint: vertex.constraint,
      is_group,
      shape: if is_group {
        "rect"
      } else {
        shape_of(vertex)
      },
      color_index: None,
      metadata: None,
    })
  }
  for index, raw in model.edges {
    let start = collapsed_into.get(raw.start).unwrap_or(raw.start)
    let end = collapsed_into.get(raw.end).unwrap_or(raw.end)
    if start == end &&
      (collapsed_into.contains(raw.start) || collapsed_into.contains(raw.end)) {
      continue
    }
    let (arrow_start, arrow_end) = arrows(raw.kind)
    let styles = match model.default_edge_style {
      Some(style) => style.copy()
      None => []
    }
    if raw.style is Some(style) {
      styles.append(style)
    }
    let plain = raw.stroke == Some("invisible") ||
      raw.kind == Some("arrow_open")
    let curve = if raw.interpolate is Some(value) && @util.js_truthy(value) {
      raw.interpolate
    } else if model.default_interpolate is Some(name) && name != "" {
      Some(Json::string(name))
    } else {
      default_curve.map(Json::string)
    }
    edges.push({
      id: if raw.id == "" {
        "L_\{start}_\{end}_\{index}"
      } else {
        raw.id
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
      classes: if raw.stroke == Some("invisible") {
        ""
      } else {
        "edge-thickness-normal edge-pattern-solid flowchart-link"
      },
      arrow_type_start: if plain {
        "none"
      } else {
        arrow_start
      },
      arrow_type_end: if plain {
        "none"
      } else {
        arrow_end
      },
      css_compiled_styles: compiled(raw.classes),
      style: styles,
      animate: raw.animate,
      animation: raw.animation,
      curve,
    })
  }
  { nodes, edges, }
}

///|
fn view_is_collapsed(metadata : Map[String, Json]?) -> Bool {
  match metadata {
    Some(fields) => fields.get("view") is Some(String("collapsed"))
    None => false
  }
}

///|
fn is_set(text : String?) -> Bool {
  text is Some(text) && text != ""
}

///|
fn shape_of(vertex : FlowNode) -> String {
  if is_set(vertex.img) {
    return "imageSquare"
  }
  if is_set(vertex.icon) {
    return match vertex.form {
      Some("circle") => "iconCircle"
      Some("square") => "iconSquare"
      Some("rounded") => "iconRounded"
      _ => "icon"
    }
  }
  match vertex.kind {
    Some("square") | None => "squareRect"
    Some("round") => "roundedRect"
    Some(kind) => kind
  }
}

///|
/// The markers at the start and end of an edge of the given type.
fn arrows(kind : String?) -> (String, String) {
  match kind {
    Some("arrow_point" | "arrow_circle" | "arrow_cross" as single) =>
      ("none", single)
    Some(
      "double_arrow_point"
      | "double_arrow_circle"
      | "double_arrow_cross" as double
    ) => {
      let single = double.replace(old="double_", new="")
      (single, single)
    }
    _ => ("none", "arrow_point")
  }
}
