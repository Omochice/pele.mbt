///|
/// The model an agentflow is parsed into, as pele's AgentflowDb.
pub struct AgentflowDb {
  mut direction : String?
  nodes : Map[String, AgentNode]
  edges : Array[AgentEdge]
  subgraphs : Array[AgentSubgraph]
  connectors : Map[String, AgentNode]
  classes : Map[String, @flowchart.FlowClassDef]
  tooltips : Map[String, String]
  mut default_edge_style : Array[String]?
  mut default_interpolate : String?
  mut title : String?
  mut acc_title : String?
  mut acc_descr : String?
  /// Where each statement sits in the source, in the order the statements were read.
  mappings : Array[ElementMapping]
  diagnostics : Array[Diagnostic]
  /// Lines of front matter before the text the parser sees, added to every reported line.
  line_offset : Int32
  priv subgraph_lookup : Map[String, AgentSubgraph]
  priv global_nodes : Map[String, Unit]
  priv members : Map[String, Unit]
  priv edge_by_id : Map[String, AgentEdge]
  priv pair_count : Map[String, Int32]
  priv mut sub_count : Int32
  priv max_edges : Int32?
  priv inherit_dir : Bool
  priv base_direction : String?
  /// Indexes of the mappings of bare references, which become attachments when a metadata block follows them.
  priv bare_mappings : Map[Int32, Unit]
  priv first_mapping : Map[String, ElementMapping]
  priv reported : Map[String, Array[Diagnostic]]
  /// The graph drawn from the model, built once.
  priv mut graph : AgentGraph?
}

///|
/// An empty model.
/// `max_edges` limits the edges, `inherit_dir` gives flows the diagram's direction, `direction` stands in for a diagram without one, and `line_offset` counts the lines of front matter.
pub fn AgentflowDb::new(
  max_edges? : Int32,
  inherit_dir~ : Bool = false,
  direction? : String,
  line_offset~ : Int32 = 0,
) -> AgentflowDb {
  {
    mappings: [],
    diagnostics: [],
    line_offset,
    direction: None,
    nodes: Map([]),
    edges: [],
    subgraphs: [],
    connectors: Map([]),
    classes: Map([]),
    tooltips: Map([]),
    default_edge_style: None,
    default_interpolate: None,
    title: None,
    acc_title: None,
    acc_descr: None,
    subgraph_lookup: Map([]),
    global_nodes: Map([]),
    members: Map([]),
    edge_by_id: Map([]),
    pair_count: Map([]),
    sub_count: 0,
    max_edges,
    inherit_dir,
    base_direction: direction,
    bare_mappings: Map([]),
    first_mapping: Map([]),
    reported: Map([]),
    graph: None,
  }
}

///|
fn agentflow_error(
  message : String,
  code : @errors.ErrorCode,
) -> @errors.PeleError {
  @errors.pele_error(message, code~, kind="agentflow")
}

///|
/// What the three arrows agentflow knows mean.
fn edge_semantic(kind : String, stroke : String) -> String? {
  match (kind, stroke) {
    ("arrow_point", "normal") => Some("sequence")
    ("arrow_cross", "normal") => Some("failure")
    ("arrow_open", "dotted") => Some("reference")
    _ => None
  }
}

///|
fn destruct_end_link(raw : String) -> @flowchart.LinkInfo {
  let text = @util.trim(raw)
  let mut line = @util.slice(text, 0, end=-1)
  let mut kind = "arrow_open"
  match @util.slice(text, -1) {
    "x" => kind = "arrow_cross"
    ">" => kind = "arrow_point"
    "-" | "." => line = text
    _ => ()
  }
  let mut stroke = "normal"
  let mut length = line.length() - 1
  let mut dots = 0
  for i in 0..<line.length() {
    if @util.code_at(line, i) == '.' {
      dots += 1
    }
  }
  if dots > 0 {
    stroke = "dotted"
    length = dots
  }
  { kind, stroke, length: Some(length), text: None, id: None, }
}

///|
/// What a link token says: its arrow type, stroke and length.
/// The first half of a split arrow only says whether the line is dotted, and one that disagrees with the second half gives the type and stroke `INVALID`.
pub fn AgentflowDb::destruct_link(
  _self : AgentflowDb,
  end : String,
  start? : String,
) -> @flowchart.LinkInfo {
  let info = destruct_end_link(end)
  if start is Some(start) && start != "" {
    let stroke = if start.contains(".") { "dotted" } else { "normal" }
    if stroke != info.stroke {
      return {
        kind: "INVALID",
        stroke: "INVALID",
        length: None,
        text: None,
        id: None,
      }
    }
  }
  info
}

///|
/// Adds a node or updates one, as each mention of an id does.
/// The id `connectors` is reserved and makes no node, and the id of an edge names that edge rather than a node.
pub fn AgentflowDb::add_vertex(
  self : AgentflowDb,
  id : String,
  text? : @flowchart.FlowText,
  kind? : String,
  style? : Array[String],
  classes? : Array[String],
  dir? : String,
  props? : Map[String, String],
  metadata? : String,
  metadata_loc? : Loc,
) -> Unit raise @errors.PeleError {
  if @util.trim(id) == "" {
    return
  }
  let mut doc : Json? = None
  let mut fields : Map[String, Json]? = None
  let mut authored_shape : String? = None
  if metadata is Some(source) {
    let parsed = self.parse_metadata(id, source, metadata_loc)
    if parsed is Object(object) {
      fields = Some(object)
      if object.get("shape") is Some(String(shape)) {
        authored_shape = Some(shape)
        object["shape"] = Json::string(
          resolve_shape_alias(Some(shape)).unwrap(),
        )
      }
    }
    // A block that reads as a falsy scalar counts as no metadata, as in pele.
    if @util.js_truthy(parsed) {
      doc = Some(parsed)
    }
  }
  if self.subgraph_lookup.get(id) is Some(subgraph) && doc is Some(doc) {
    subgraph.metadata = Some(merge_metadata(subgraph.metadata, doc))
    return
  }
  if self.connectors.get(id) is Some(connector) && doc is Some(doc) {
    connector.metadata = Some(merge_metadata(connector.metadata, doc))
    return
  }
  // Mermaid reserves this id and creates no node for it.
  if id == "connectors" {
    return
  }
  if self.edge_by_id.get(id) is Some(edge) {
    if fields is Some(fields) {
      if fields.get("animate") is Some(value) {
        edge.animate = Some(value)
      }
      if fields.get("animation") is Some(value) {
        edge.animation = Some(value)
      }
      if fields.get("curve") is Some(value) {
        edge.interpolate = Some(value)
      }
    }
    if doc is Some(doc) {
      edge.metadata = Some(merge_metadata(edge.metadata, doc))
    }
    return
  }
  let vertex = match self.nodes.get(id) {
    Some(vertex) => vertex
    None => {
      let vertex : AgentNode = {
        id,
        text: None,
        label_type: Text,
        kind: None,
        styles: [],
        classes: [],
        dir: None,
        props: None,
        link: None,
        link_target: None,
        metadata: None,
        is_connector: false,
      }
      self.nodes[id] = vertex
      vertex
    }
  }
  match text {
    Some(label) => {
      vertex.label_type = label.kind
      vertex.text = Some(@flowchart.unquote(@util.trim(label.text)))
    }
    None => if vertex.text is None { vertex.text = Some(id) }
  }
  if kind is Some(_) {
    vertex.kind = kind
  }
  if style is Some(style) {
    for s in style {
      vertex.styles.push(s)
    }
  }
  if classes is Some(classes) {
    for c in classes {
      vertex.classes.push(c)
    }
  }
  if dir is Some(_) {
    vertex.dir = dir
  }
  match vertex.props {
    None => vertex.props = Some(props.unwrap_or(Map([])))
    Some(old) =>
      if props is Some(props) {
        for key, value in props {
          old[key] = value
        }
      }
  }
  guard doc is Some(doc) else { return }
  vertex.metadata = Some(merge_metadata(vertex.metadata, doc))
  guard fields is Some(fields) else { return }
  let shape = fields.get("shape").unwrap_or(Json::null())
  if @util.js_truthy(shape) {
    let authored = match authored_shape {
      Some(authored) => authored
      None =>
        raise self.shape_error(
          "No such shape: \{shape.stringify()}.",
          metadata_loc,
        )
    }
    if @flowchart.has_capital(authored) || authored.contains("_") {
      raise self.shape_error(
        "No such shape: \{authored}. Shape names should be lowercase.",
        metadata_loc,
      )
    }
    let name = @util.js_string(shape)
    if !is_valid_shape(name) {
      raise self.shape_error("No such shape: \{name}.", metadata_loc)
    }
    vertex.kind = Some(name)
  }
  let label = fields.get("label").unwrap_or(Json::null())
  if @util.js_truthy(label) {
    vertex.text = Some(@util.js_string(label))
    vertex.label_type = @flowchart.label_type_of(fields.get("labelType"))
  }
}

///|
/// The line and column pele reports for a metadata block.
fn AgentflowDb::block_at(self : AgentflowDb, loc : Loc?) -> (Int32, Int32) {
  match loc {
    Some(loc) => (loc.first_line + self.line_offset, loc.first_column + 1)
    None => (0, 0)
  }
}

///|
fn AgentflowDb::shape_error(
  self : AgentflowDb,
  message : String,
  loc : Loc?,
) -> @errors.PeleError {
  let (line, column) = self.block_at(loc)
  @errors.pele_error(message, code=Semantic, kind="agentflow", line~, column~)
}

///|
/// Parses a metadata block: a single-line block as the body of a flow mapping, a multi-line one as block YAML.
/// Block YAML rejects the comma-separated style of the single-line form, so a failing multi-line block is tried once more without the commas.
fn AgentflowDb::parse_metadata(
  self : AgentflowDb,
  id : String,
  source : String,
  loc : Loc?,
) -> Json raise @errors.PeleError {
  let multiline = source.contains("\n")
  let yaml = if multiline { source + "\n" } else { "{\n" + source + "\n}" }
  let parsed = @util.parse_yaml(yaml) catch {
    @util.YamlError(message) => {
      let stripped = if multiline {
        strip_line_trailing_commas(source)
      } else {
        source
      }
      let retried = if stripped != source {
        Some(@util.parse_yaml(stripped + "\n")) catch {
          _ => None
        }
      } else {
        None
      }
      match retried {
        Some(retried) => retried
        None => {
          let (line, column) = self.block_at(loc)
          let at = if loc is Some(_) { " (\{line}:\{column})" } else { "" }
          raise @errors.pele_error(
            "Metadata of \"\{id}\" is not valid YAML. \{message}\{at}",
            code=Syntax,
            kind="agentflow",
            line~,
            column~,
          )
        }
      }
    }
  }
  strip_prototype_keys(
    if parsed is Null {
      Json::object(Map([]))
    } else {
      parsed
    },
  )
}

///|
/// Adds one edge, with the id the user gave it when that id is still free.
pub fn AgentflowDb::add_single_link(
  self : AgentflowDb,
  start : String,
  end : String,
  link : @flowchart.LinkInfo?,
  id? : String,
) -> Unit raise @errors.PeleError {
  let edge : AgentEdge = {
    start,
    end,
    kind: None,
    text: "",
    label_type: Text,
    stroke: None,
    edge_semantic: None,
    length: None,
    style: None,
    classes: [],
    id: "",
    is_user_defined_id: false,
    interpolate: self.default_interpolate.map(Json::string),
    animate: None,
    animation: None,
    metadata: None,
  }
  if link is Some(link) {
    if link.text is Some(label) {
      edge.text = @flowchart.unquote(@util.trim(label.text))
      edge.label_type = label.kind
    }
    edge.kind = Some(link.kind)
    edge.stroke = Some(link.stroke)
    edge.length = link.length.map(l => if l > 10 { 10 } else { l })
    edge.edge_semantic = edge_semantic(link.kind, link.stroke)
  }
  let pair = start + "\u{0}" + end
  let count = self.pair_count.get(pair).unwrap_or(0)
  match id {
    Some(id) if id != "" && !self.edge_by_id.contains(id) => {
      edge.id = id
      edge.is_user_defined_id = true
    }
    _ => {
      let suffix = if count == 0 { 0 } else { count + 1 }
      edge.id = "L_\{start}_\{end}_\{suffix}"
    }
  }
  if self.max_edges is Some(max) && self.edges.length() >= max {
    raise agentflow_error("Edge limit exceeded. The limit is \{max}.", Limit)
  }
  self.edges.push(edge)
  self.pair_count[pair] = count + 1
  if !self.edge_by_id.contains(edge.id) {
    self.edge_by_id[edge.id] = edge
  }
}

///|
/// Adds an edge from each start to each end.
/// The link's id goes to the edge from the last start to the first end.
pub fn AgentflowDb::add_link(
  self : AgentflowDb,
  starts : Array[String],
  ends : Array[String],
  link : @flowchart.LinkInfo?,
) -> Unit raise @errors.PeleError {
  let id = match link {
    Some({ id: Some(id), .. }) => Some(id.replace(old="@", new=""))
    _ => None
  }
  let last_start = starts[starts.length() - 1]
  let first_end = ends[0]
  for start in starts {
    for end in ends {
      let own = if start == last_start && end == first_end { id } else { None }
      self.add_single_link(start, end, link, id?=own)
    }
  }
}

///|
/// Mermaid checks the bounds only for a numeric index and crashes on the strings its own parser passes.
fn AgentflowDb::edge_at(
  self : AgentflowDb,
  pos : String,
) -> AgentEdge raise @errors.PeleError {
  let index = @util.to_number(pos)
  if index >= 0.0 &&
    index < self.edges.length().to_double() &&
    index == index.floor() {
    return self.edges[index.to_int()]
  }
  raise agentflow_error(
    "The index \{pos} for linkStyle is out of bounds. Valid indices for linkStyle are between 0 and \{self.edges.length() - 1}. (Help: Ensure that the index is within the range of existing edges.)",
    Semantic,
  )
}

///|
/// Sets the curve of the edges at `positions`, or of every edge for `default`.
pub fn AgentflowDb::update_link_interpolate(
  self : AgentflowDb,
  positions : Array[String],
  interpolate : String,
) -> Unit raise @errors.PeleError {
  for pos in positions {
    if pos == "default" {
      self.default_interpolate = Some(interpolate)
    } else {
      self.edge_at(pos).interpolate = Some(Json::string(interpolate))
    }
  }
}

///|
/// Sets the style of the edges at `positions`, or of every edge for `default`.
/// The edges share `style`, which gains `fill:none` once when it sets no fill, as in pele.
pub fn AgentflowDb::update_link(
  self : AgentflowDb,
  positions : Array[String],
  style : Array[String],
) -> Unit raise @errors.PeleError {
  for pos in positions {
    if pos == "default" {
      self.default_edge_style = Some(style)
      continue
    }
    let edge = self.edge_at(pos)
    edge.style = Some(style)
    if style.length() > 0 && !style.iter().any(s => s.has_prefix("fill")) {
      style.push("fill:none")
    }
  }
}

///|
/// Defines the classes named in `ids`, separated by commas, with the given styles.
pub fn AgentflowDb::add_class(
  self : AgentflowDb,
  ids : String,
  styles : Array[String],
) -> Unit {
  let style = @flowchart.class_styles(styles)
  for id in ids.split(",") {
    let id = id.to_owned()
    let class_def = match self.classes.get(id) {
      Some(class_def) => class_def
      None => {
        let class_def : @flowchart.FlowClassDef = {
          id,
          styles: [],
          text_styles: [],
        }
        self.classes[id] = class_def
        class_def
      }
    }
    for s in style {
      if s.contains("color") {
        class_def.text_styles.push(s.replace(old="fill", new="bgFill"))
      }
      class_def.styles.push(s)
    }
  }
}

///|
/// Sets the diagram's direction from the text of its header.
pub fn AgentflowDb::set_direction(self : AgentflowDb, dir : String) -> Unit {
  self.direction = Some(@flowchart.direction_name(dir))
}

///|
/// Gives the class to the nodes, edges and flows named in `ids`, separated by commas.
pub fn AgentflowDb::set_class(
  self : AgentflowDb,
  ids : String,
  class_name : String,
) -> Unit {
  for id in ids.split(",") {
    let id = id.to_owned()
    if self.nodes.get(id) is Some(node) {
      node.classes.push(class_name)
    }
    if self.edge_by_id.get(id) is Some(edge) {
      edge.classes.push(class_name)
    }
    if self.subgraph_lookup.get(id) is Some(subgraph) {
      subgraph.classes.push(class_name)
    }
  }
}

///|
/// Sets the tooltip of the nodes named in `ids`.
pub fn AgentflowDb::set_tooltip(
  self : AgentflowDb,
  ids : String,
  tooltip : String?,
) -> Unit {
  guard tooltip is Some(tooltip) else { return }
  for id in ids.split(",") {
    self.tooltips[id.to_owned()] = tooltip
  }
}

///|
/// Links the nodes named in `ids` to the sanitized URL and marks them clickable.
pub fn AgentflowDb::set_link(
  self : AgentflowDb,
  ids : String,
  link : String,
  target? : String,
) -> Unit {
  let url = @util.trim(link)
  for id in ids.split(",") {
    if self.nodes.get(id.to_owned()) is Some(vertex) {
      vertex.link = if url == "" { None } else { Some(@url.safe_url(url)) }
      vertex.link_target = target
    }
  }
  self.set_class(ids, "clickable")
}

///|
/// Marks the nodes as clickable.
/// Callbacks are never executed, as in Mermaid's strict mode.
pub fn AgentflowDb::set_click_event(self : AgentflowDb, ids : String) -> Unit {
  self.set_class(ids, "clickable")
}

///|
/// Sets the accessible title, without its leading whitespace.
pub fn AgentflowDb::set_acc_title(self : AgentflowDb, text : String) -> Unit {
  self.acc_title = Some(@util.trim_start(text))
}

///|
/// Sets the accessible description, with the indentation of its lines removed.
pub fn AgentflowDb::set_acc_description(
  self : AgentflowDb,
  text : String,
) -> Unit {
  self.acc_descr = Some(@flowchart.acc_description(text))
}

///|
/// Adds a flow of the listed ids, or the new ids to an earlier flow of the same id, and returns its id.
/// A flow never contains itself, a node of a `global` block, or a node another flow already holds.
pub fn AgentflowDb::add_subgraph(
  self : AgentflowDb,
  id_text : @flowchart.FlowText?,
  list : Array[@flowchart.DocItem],
  title_text : @flowchart.FlowText?,
) -> String {
  let title = match title_text {
    Some(t) => t.text
    None => ""
  }
  let seen : Map[String, Unit] = Map([])
  let node_list = []
  let mut dir = None
  let add = (item : String) => {
    if @util.trim(item) != "" && !seen.contains(item) {
      seen[item] = ()
      node_list.push(item)
    }
  }
  for entry in list {
    match entry {
      Id(item) => add(item)
      Ids(items) => items.each(add)
      Direction(value) => dir = Some(value)
    }
  }
  if dir is None && self.inherit_dir {
    dir = match self.direction {
      Some(d) => Some(d)
      None => self.base_direction
    }
  }
  let id = match id_text {
    Some(t) => @util.trim(t.text)
    None => "subGraph\{self.sub_count}"
  }
  self.sub_count += 1
  let nodes = node_list.filter(node_id => {
    node_id != id &&
    !self.global_nodes.contains(node_id) &&
    !self.members.contains(node_id)
  })
  for node_id in nodes {
    self.members[node_id] = ()
  }
  match self.subgraph_lookup.get(id) {
    Some(existing) => {
      // A repeated id adds its members to the first flow; its title and direction win.
      for node_id in nodes {
        existing.nodes.push(node_id)
      }
      if @util.trim(title) != "" {
        existing.title = @util.trim(title)
      }
      if dir is Some(d) && d != "" {
        existing.dir = dir
      }
    }
    None => {
      let subgraph : AgentSubgraph = {
        id,
        nodes,
        title: @util.trim(title),
        classes: [],
        dir,
        label_type: match title_text {
          Some(t) => t.kind
          None => Markdown
        },
        metadata: None,
      }
      self.subgraphs.push(subgraph)
      self.subgraph_lookup[id] = subgraph
    }
  }
  id
}

///|
/// Keeps every node named inside a `global` block out of the flows that mention it.
pub fn AgentflowDb::add_global(
  self : AgentflowDb,
  list : Array[@flowchart.DocItem],
) -> Unit {
  let mut release = false
  let add = (item : String) => {
    let id = @util.trim(item)
    if id == "" {
      return
    }
    self.global_nodes[id] = ()
    if self.members.contains(id) {
      self.members.remove(id)
      release = true
    }
  }
  for entry in list {
    match entry {
      Id(item) => add(item)
      Ids(items) => items.each(add)
      Direction(_) => ()
    }
  }
  if !release {
    return
  }
  for subgraph in self.subgraphs {
    subgraph.nodes = subgraph.nodes.filter(node_id => {
      !self.global_nodes.contains(node_id)
    })
  }
}

///|
/// Adds a connector, or retitles an earlier one, and returns its id, which is empty for a blank one.
pub fn AgentflowDb::add_connector(
  self : AgentflowDb,
  text : @flowchart.FlowText?,
  title? : @flowchart.FlowText,
) -> String {
  let id = match text {
    Some(t) => @util.trim(t.text)
    None => ""
  }
  if id == "" {
    return ""
  }
  let title = match title {
    Some(t) => @util.trim(t.text)
    None => ""
  }
  match self.connectors.get(id) {
    None => {
      let created : AgentNode = {
        id,
        text: Some(if title.length() > 0 { title } else { id }),
        label_type: Text,
        kind: None,
        styles: [],
        classes: [],
        dir: None,
        props: None,
        link: None,
        link_target: None,
        metadata: None,
        is_connector: true,
      }
      self.connectors[id] = created
      self.nodes[id] = created
    }
    Some(connector) => if title.length() > 0 { connector.text = Some(title) }
  }
  id
}

///|
/// The flow of the id, if there is one.
pub fn AgentflowDb::subgraph(self : AgentflowDb, id : String) -> AgentSubgraph? {
  self.subgraph_lookup.get(id)
}
