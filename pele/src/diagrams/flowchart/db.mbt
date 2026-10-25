///|
/// The model a flowchart is parsed into, as pele's FlowDb.
/// pele's `warn` option is left out: it only reports a style on an unknown node and changes nothing.
pub struct FlowDb {
  mut direction : String?
  nodes : Map[String, FlowNode]
  edges : Array[FlowEdge]
  subgraphs : Array[FlowSubgraph]
  classes : Map[String, FlowClassDef]
  tooltips : Map[String, String]
  mut default_edge_style : Array[String]?
  mut default_interpolate : String?
  mut title : String?
  mut acc_title : String?
  mut acc_descr : String?
  priv subgraph_lookup : Map[String, FlowSubgraph]
  priv members : Map[String, Unit]
  priv edge_by_id : Map[String, FlowEdge]
  priv pair_count : Map[String, Int32]
  priv mut sub_count : Int32
  priv max_edges : Int32?
  priv inherit_dir : Bool
  priv base_direction : String?
}

///|
/// An empty model.
/// `max_edges` limits the edges, `inherit_dir` gives subgraphs the chart's direction, and `direction` stands in for a chart without one.
pub fn FlowDb::new(
  max_edges? : Int32,
  inherit_dir~ : Bool = false,
  direction? : String,
) -> FlowDb {
  {
    direction: None,
    nodes: Map([]),
    edges: [],
    subgraphs: [],
    classes: Map([]),
    tooltips: Map([]),
    default_edge_style: None,
    default_interpolate: None,
    title: None,
    acc_title: None,
    acc_descr: None,
    subgraph_lookup: Map([]),
    members: Map([]),
    edge_by_id: Map([]),
    pair_count: Map([]),
    sub_count: 0,
    max_edges,
    inherit_dir,
    base_direction: direction,
  }
}

///|
fn flowchart_error(
  message : String,
  code : @errors.ErrorCode,
) -> @errors.PeleError {
  @errors.pele_error(message, code~, kind="flowchart")
}

///|
/// The label type a name stands for, Markdown for any other value.
pub fn label_type_of(name : Json?) -> LabelType {
  match name {
    Some(String("text")) => Text
    Some(String("string")) => Str
    _ => Markdown
  }
}

///|
/// The text without the double quotes around it, if it has them.
pub fn unquote(text : String) -> String {
  if text.length() >= 2 && text.has_prefix("\"") && text.has_suffix("\"") {
    @util.slice(text, 1, end=text.length() - 1)
  } else {
    text
  }
}

///|
fn count_char(ch : Int32, text : String) -> Int32 {
  let mut count = 0
  for i in 0..<text.length() {
    if @util.code_at(text, i) == ch {
      count += 1
    }
  }
  count
}

///|
/// Whether `toLowerCase` would change the name, for the capitals a shape name plausibly holds.
pub fn has_capital(name : String) -> Bool {
  for i in 0..<name.length() {
    let c = @util.code_at(name, i)
    let capital = (c >= 'A' && c <= 'Z') ||
      (c >= 0xc0 && c <= 0xde && c != 0xd7) ||
      (c >= 0x391 && c <= 0x3a9) ||
      (c >= 0x400 && c <= 0x42f) ||
      (c >= 0xff21 && c <= 0xff3a)
    if capital {
      return true
    }
  }
  false
}

///|
fn destruct_start_link(raw : String) -> LinkInfo {
  let mut text = @util.trim(raw)
  let mut kind = "arrow_open"
  match @util.code_at(text, 0) {
    '<' => {
      kind = "arrow_point"
      text = @util.slice(text, 1)
    }
    'x' => {
      kind = "arrow_cross"
      text = @util.slice(text, 1)
    }
    'o' => {
      kind = "arrow_circle"
      text = @util.slice(text, 1)
    }
    _ => ()
  }
  let mut stroke = "normal"
  if text.contains("=") {
    stroke = "thick"
  }
  if text.contains(".") {
    stroke = "dotted"
  }
  { kind, stroke, length: None, text: None, id: None, }
}

///|
fn destruct_end_link(raw : String) -> LinkInfo {
  let text = @util.trim(raw)
  let mut line = @util.slice(text, 0, end=-1)
  let mut kind = "arrow_open"
  match @util.slice(text, -1) {
    "x" => {
      kind = "arrow_cross"
      if text.has_prefix("x") {
        kind = "double_" + kind
        line = @util.slice(line, 1)
      }
    }
    ">" => {
      kind = "arrow_point"
      if text.has_prefix("<") {
        kind = "double_" + kind
        line = @util.slice(line, 1)
      }
    }
    "o" => {
      kind = "arrow_circle"
      if text.has_prefix("o") {
        kind = "double_" + kind
        line = @util.slice(line, 1)
      }
    }
    _ => ()
  }
  let mut stroke = "normal"
  let mut length = line.length() - 1
  if line.has_prefix("=") {
    stroke = "thick"
  }
  if line.has_prefix("~") {
    stroke = "invisible"
  }
  let dots = count_char('.', line)
  if dots > 0 {
    stroke = "dotted"
    length = dots
  }
  { kind, stroke, length: Some(length), text: None, id: None, }
}

///|
/// Adds a node or updates one, as each mention of an id does.
/// `metadata` is the text of its `@{ }` node data.
/// Node data for a subgraph or an edge id goes to that subgraph or edge instead.
pub fn FlowDb::add_vertex(
  self : FlowDb,
  id : String,
  text? : FlowText,
  kind? : String,
  style? : Array[String],
  classes? : Array[String],
  dir? : String,
  props? : Map[String, String],
  metadata? : String,
) -> Unit raise @errors.PeleError {
  if @util.trim(id) == "" {
    return
  }
  let mut doc : Map[String, Json]? = None
  if metadata is Some(metadata) {
    let yaml = if metadata.contains("\n") {
      metadata + "\n"
    } else {
      "{\n" + metadata + "\n}"
    }
    let parsed = @util.parse_yaml(yaml) catch {
      @util.YamlError(message) =>
        raise flowchart_error(
          "Metadata of \"\{id}\" is not valid YAML. \{message}",
          Syntax,
        )
    }
    if parsed is Object(fields) {
      doc = Some(fields)
    }
  }
  if self.subgraph_lookup.get(id) is Some(subgraph) && doc is Some(fields) {
    let merged : Map[String, Json] = Map([])
    if subgraph.metadata is Some(old) {
      for key, value in old {
        merged[key] = value
      }
    }
    for key, value in fields {
      merged[key] = value
    }
    subgraph.metadata = Some(merged)
    return
  }
  if self.edge_by_id.get(id) is Some(edge) {
    if doc is Some(fields) {
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
    return
  }
  let vertex = match self.nodes.get(id) {
    Some(vertex) => vertex
    None => {
      let vertex : FlowNode = {
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
        icon: None,
        form: None,
        pos: None,
        img: None,
        constraint: None,
        asset_width: None,
        asset_height: None,
      }
      self.nodes[id] = vertex
      vertex
    }
  }
  match text {
    Some(label) => {
      vertex.label_type = label.kind
      vertex.text = Some(unquote(@util.trim(label.text)))
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
  guard doc is Some(fields) else { return }
  let field = (name : String) => fields.get(name).unwrap_or(Json::null())
  let truthy = (name : String) => @util.js_truthy(field(name))
  let text_of = (name : String) => @util.js_string(field(name))
  if truthy("shape") {
    let shape = text_of("shape")
    if has_capital(shape) || shape.contains("_") {
      raise flowchart_error(
        "No such shape: \{shape}. Shape names should be lowercase.",
        Semantic,
      )
    }
    if !is_valid_shape(shape) {
      raise flowchart_error("No such shape: \{shape}.", Semantic)
    }
    vertex.kind = Some(shape)
  }
  let label = match field("label") {
    String(label) => Some(label)
    _ => None
  }
  let label_is_blank = match label {
    Some(label) => @util.trim(label) == ""
    None => true
  }
  if truthy("label") {
    vertex.text = Some(text_of("label"))
    vertex.label_type = label_type_of(fields.get("labelType"))
  }
  if truthy("icon") {
    vertex.icon = Some(text_of("icon"))
    if label_is_blank && vertex.text == Some(id) {
      vertex.text = Some("")
    }
  }
  if truthy("form") {
    vertex.form = Some(text_of("form"))
  }
  if truthy("pos") {
    vertex.pos = Some(text_of("pos"))
  }
  if truthy("img") {
    vertex.img = Some(text_of("img"))
    if label_is_blank && vertex.text == Some(id) {
      vertex.text = Some("")
    }
  }
  if truthy("constraint") {
    vertex.constraint = Some(text_of("constraint"))
  }
  if truthy("w") {
    vertex.asset_width = Some(@util.js_number(field("w")))
  }
  if truthy("h") {
    vertex.asset_height = Some(@util.js_number(field("h")))
  }
}

///|
/// Adds one edge, with the id the user gave it when that id is still free.
pub fn FlowDb::add_single_link(
  self : FlowDb,
  start : String,
  end : String,
  link : LinkInfo?,
  id? : String,
) -> Unit raise @errors.PeleError {
  let edge : FlowEdge = {
    start,
    end,
    kind: None,
    text: "",
    label_type: Text,
    stroke: None,
    length: None,
    style: None,
    classes: [],
    id: "",
    is_user_defined_id: false,
    interpolate: self.default_interpolate.map(Json::string),
    animate: None,
    animation: None,
  }
  if link is Some(link) {
    if link.text is Some(label) {
      edge.text = unquote(@util.trim(label.text))
      edge.label_type = label.kind
    }
    edge.kind = Some(link.kind)
    edge.stroke = Some(link.stroke)
    edge.length = link.length.map(l => if l > 10 { 10 } else { l })
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
    raise flowchart_error("Edge limit exceeded. The limit is \{max}.", Limit)
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
pub fn FlowDb::add_link(
  self : FlowDb,
  starts : Array[String],
  ends : Array[String],
  link : LinkInfo?,
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
fn FlowDb::edge_at(
  self : FlowDb,
  pos : String,
) -> FlowEdge raise @errors.PeleError {
  let index = @util.to_number(pos)
  if index >= 0.0 &&
    index < self.edges.length().to_double() &&
    index == index.floor() {
    return self.edges[index.to_int()]
  }
  raise flowchart_error(
    "The index \{pos} for linkStyle is out of bounds. Valid indices for linkStyle are between 0 and \{self.edges.length() - 1}. (Help: Ensure that the index is within the range of existing edges.)",
    Semantic,
  )
}

///|
/// Sets the curve of the edges at `positions`, or of every edge for `default`.
pub fn FlowDb::update_link_interpolate(
  self : FlowDb,
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
pub fn FlowDb::update_link(
  self : FlowDb,
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
/// The declarations of a `classDef`, split at its commas but not at escaped ones.
pub fn class_styles(styles : Array[String]) -> Array[String] {
  styles
  .join(",")
  .replace_all(old="\\,", new="§§§")
  .replace_all(old=",", new=";")
  .replace_all(old="§§§", new=",")
  .split(";")
  .map(s => s.to_owned())
  .collect()
}

///|
/// The direction a header's text names, with arrows and `TD` turned into direction names.
pub fn direction_name(dir : String) -> String {
  let mut d = @util.trim(dir)
  if d.contains("<") {
    d = "RL"
  }
  if d.contains("^") {
    d = "BT"
  }
  if d.contains(">") {
    d = "LR"
  }
  if d.contains("v") {
    d = "TB"
  }
  if d == "TD" {
    d = "TB"
  }
  d
}

///|
/// An accessible description with the indentation of its lines removed.
pub fn acc_description(text : String) -> String {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    if @util.code_at(text, i) == '\n' &&
      @util.is_space(@util.code_at(text, i + 1)) {
      out.write_char('\n')
      i += 1
      while @util.is_space(@util.code_at(text, i)) {
        i += 1
      }
    } else {
      @util.write_range(out, text, i, i + 1)
      i += 1
    }
  }
  out.to_string()
}

///|
/// Defines the classes named in `ids`, separated by commas, with the given styles.
pub fn FlowDb::add_class(
  self : FlowDb,
  ids : String,
  styles : Array[String],
) -> Unit {
  let style = class_styles(styles)
  for id in ids.split(",") {
    let id = id.to_owned()
    let class_def = match self.classes.get(id) {
      Some(class_def) => class_def
      None => {
        let class_def : FlowClassDef = { id, styles: [], text_styles: [], }
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
/// Sets the chart's direction from the text of a header, turning arrows and `TD` into direction names.
pub fn FlowDb::set_direction(self : FlowDb, dir : String) -> Unit {
  self.direction = Some(direction_name(dir))
}

///|
/// Gives the class to the nodes, edges and subgraphs named in `ids`, separated by commas.
pub fn FlowDb::set_class(
  self : FlowDb,
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
pub fn FlowDb::set_tooltip(
  self : FlowDb,
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
pub fn FlowDb::set_link(
  self : FlowDb,
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
pub fn FlowDb::set_click_event(self : FlowDb, ids : String) -> Unit {
  self.set_class(ids, "clickable")
}

///|
/// Sets the accessible title, without its leading whitespace.
pub fn FlowDb::set_acc_title(self : FlowDb, text : String) -> Unit {
  self.acc_title = Some(@util.trim_start(text))
}

///|
/// Sets the accessible description, with the indentation of its lines removed.
pub fn FlowDb::set_acc_description(self : FlowDb, text : String) -> Unit {
  self.acc_descr = Some(acc_description(text))
}

///|
/// Adds a subgraph of the listed ids, or the new ids to an earlier one of the same id, and returns its id.
/// `title_is_id` tells a subgraph written without a bracketed title, whose title is its id.
pub fn FlowDb::add_subgraph(
  self : FlowDb,
  id_text : FlowText?,
  list : Array[DocItem],
  title_text : FlowText?,
  title_is_id~ : Bool = false,
) -> String {
  let mut id = id_text.map(t => @util.trim(t.text))
  let title = match title_text {
    Some(t) => t.text
    None => ""
  }
  if id_text is Some(_) &&
    title_is_id &&
    title.iter().any(c => @util.is_space(c.to_int())) {
    id = None
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
  let id = match id {
    Some(id) => id
    None => "subGraph\{self.sub_count}"
  }
  self.sub_count += 1
  // A node belongs to the first subgraph that lists it, and a subgraph never contains itself.
  let nodes = node_list.filter(node_id => {
    !self.members.contains(node_id) && node_id != id
  })
  for node_id in nodes {
    self.members[node_id] = ()
  }
  match self.subgraph_lookup.get(id) {
    Some(existing) =>
      for node_id in nodes {
        existing.nodes.push(node_id)
      }
    None => {
      let subgraph : FlowSubgraph = {
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
/// Whether any of the subgraphs holds the id.
pub fn FlowDb::exists(
  _self : FlowDb,
  all : Array[FlowSubgraph],
  id : String,
) -> Bool {
  all.iter().any(sg => sg.nodes.contains(id))
}

///|
/// The ids of `subgraph` that none of `all` holds.
pub fn FlowDb::make_uniq(
  _self : FlowDb,
  subgraph : FlowSubgraph,
  all : Array[FlowSubgraph],
) -> Array[String] {
  let taken : Map[String, Unit] = Map([])
  for other in all {
    for id in other.nodes {
      taken[id] = ()
    }
  }
  subgraph.nodes.filter(id => !taken.contains(id))
}

///|
/// What a link token says: its arrow type, stroke and length, joined with the start of a link that has text.
/// Mismatched ends give the type and stroke `INVALID`.
pub fn FlowDb::destruct_link(
  _self : FlowDb,
  end : String,
  start? : String,
) -> LinkInfo {
  let info = destruct_end_link(end)
  guard start is Some(start) && start != "" else { return info }
  let start_info = destruct_start_link(start)
  let invalid : LinkInfo = {
    kind: "INVALID",
    stroke: "INVALID",
    length: None,
    text: None,
    id: None,
  }
  if start_info.stroke != info.stroke {
    return invalid
  }
  if start_info.kind == "arrow_open" {
    start_info.kind = info.kind
  } else {
    if start_info.kind != info.kind {
      return invalid
    }
    start_info.kind = "double_" + start_info.kind
  }
  if start_info.kind == "double_arrow" {
    start_info.kind = "double_arrow_point"
  }
  start_info.length = info.length
  start_info
}

///|
/// The subgraph of the id, if there is one.
pub fn FlowDb::subgraph(self : FlowDb, id : String) -> FlowSubgraph? {
  self.subgraph_lookup.get(id)
}
