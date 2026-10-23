// A deterministic text form of the model, written the same way as the dump of pele's model that the expectations came from.

///|
fn q(text : String) -> String {
  let escaped = text
    .replace_all(old="\\", new="\\\\")
    .replace_all(old="\"", new="\\\"")
    .replace_all(old="\n", new="\\n")
    .replace_all(old="\r", new="\\r")
  "\"\{escaped}\""
}

///|
fn opt(text : String?) -> String {
  match text {
    Some(text) => q(text)
    None => "-"
  }
}

///|
fn texts(items : Array[String]?) -> String {
  match items {
    Some(items) => "[" + items.map(q).join(",") + "]"
    None => "-"
  }
}

///|
fn int(value : Int32?) -> String {
  match value {
    Some(value) => value.to_string()
    None => "-"
  }
}

///|
fn json(value : Json?) -> String {
  match value {
    None => "-"
    Some(Null) => "null"
    Some(True) => "true"
    Some(False) => "false"
    Some(Number(n, ..)) => n.to_string()
    Some(String(s)) => q(s)
    Some(Array(items)) => "[" + items.map(i => json(Some(i))).join(",") + "]"
    Some(Object(fields)) => {
      let parts = []
      for key, field in fields {
        parts.push(q(key) + ":" + json(Some(field)))
      }
      "{" + parts.join(",") + "}"
    }
  }
}

///|
fn props(value : Map[String, String]?) -> String {
  match value {
    None => "-"
    Some(fields) => {
      let parts = []
      for key, field in fields {
        parts.push(q(key) + ":" + q(field))
      }
      "{" + parts.join(",") + "}"
    }
  }
}

///|
/// The statements of the model; `full` adds the metadata of nodes, edges and flows.
fn dump_statements(db : @agentflow.AgentflowDb, full~ : Bool = false) -> String {
  let meta = (value : Map[String, Json]?) => {
    if full {
      " metadata=" + json(value.map(Json::object))
    } else {
      ""
    }
  }
  let out = ["dir \{opt(db.direction)}"]
  if db.title is Some(title) {
    out.push("title \{q(title)}")
  }
  if db.acc_title is Some(title) {
    out.push("accTitle \{q(title)}")
  }
  if db.acc_descr is Some(descr) {
    out.push("accDescr \{q(descr)}")
  }
  for _, n in db.nodes {
    out.push(
      "node \{q(n.id)} text=\{opt(n.text)} lt=\{n.label_type.to_string()} type=\{opt(n.kind)} styles=\{texts(Some(n.styles))} classes=\{texts(Some(n.classes))} dir=\{opt(n.dir)} props=\{props(n.props)} link=\{opt(n.link)} target=\{opt(n.link_target)} connector=\{n.is_connector}\{meta(n.metadata)}",
    )
  }
  for e in db.edges {
    out.push(
      "edge \{q(e.start)} \{q(e.end)} id=\{q(e.id)} user=\{e.is_user_defined_id} type=\{opt(e.kind)} text=\{q(e.text)} lt=\{e.label_type.to_string()} stroke=\{opt(e.stroke)} semantic=\{opt(e.edge_semantic)} length=\{int(e.length)} style=\{texts(e.style)} classes=\{texts(Some(e.classes))} interpolate=\{json(e.interpolate)} animate=\{json(e.animate)} animation=\{json(e.animation)}\{meta(e.metadata)}",
    )
  }
  for s in db.subgraphs {
    out.push(
      "subgraph \{q(s.id)} title=\{q(s.title)} lt=\{s.label_type.to_string()} dir=\{opt(s.dir)} nodes=\{texts(Some(s.nodes))} classes=\{texts(Some(s.classes))}\{meta(s.metadata)}",
    )
  }
  for id, _ in db.connectors {
    out.push("connector \{q(id)}")
  }
  for _, c in db.classes {
    out.push(
      "class \{q(c.id)} styles=\{texts(Some(c.styles))} text=\{texts(Some(c.text_styles))}",
    )
  }
  for id, tip in db.tooltips {
    out.push("tooltip \{q(id)} \{q(tip)}")
  }
  out.push(
    "defaultStyle=\{texts(db.default_edge_style)} defaultInterpolate=\{opt(db.default_interpolate)}",
  )
  out.join("\n")
}

///|
fn position(p : @agentflow.ElementPosition) -> String {
  "\{p.start_line}:\{p.start_column}-\{p.end_line}:\{p.end_column}"
}

///|
fn metadata(value : Map[String, Json]?) -> String {
  json(value.map(Json::object))
}

///|
/// The whole model: its statements with their metadata, where each statement sits, and the semantic model.
fn dump_model(db : @agentflow.AgentflowDb) -> String {
  let out = [dump_statements(db, full=true)]
  for m in db.mappings {
    out.push("mapping \{q(m.id)} \{m.kind} \{position(m.position)}")
  }
  let s = db.semantic_model()
  out.push("semantic dir=\{opt(s.direction)}")
  for v in s.vertices {
    out.push(
      "sv \{q(v.id)} label=\{opt(v.label)} shape=\{opt(v.shape)} kind=\{q(v.vertex_kind)} metadata=\{metadata(v.metadata)}",
    )
  }
  for e in s.edges {
    out.push(
      "se \{q(e.start)} \{q(e.end)} id=\{opt(e.id)} label=\{opt(e.label)} type=\{opt(e.kind)} stroke=\{opt(e.stroke)} semantic=\{opt(e.edge_semantic)} length=\{int(e.length)} metadata=\{metadata(e.metadata)}",
    )
  }
  for g in s.subgraphs {
    out.push(
      "ss \{q(g.id)} title=\{q(g.title)} nodes=\{texts(Some(g.nodes))} direction=\{opt(g.direction)} metadata=\{metadata(g.metadata)}",
    )
  }
  for c in s.connectors {
    out.push(
      "sc \{q(c.id)} title=\{opt(c.title)} metadata=\{metadata(c.metadata)}",
    )
  }
  out.join("\n")
}

///|
/// The graph the model draws, with the eight series colors, and the diagnostics building it records.
fn dump_graph(db : @agentflow.AgentflowDb) -> String {
  let graph = @agentflow.build_agent_graph(db, 8)
  let out = []
  for n in graph.nodes {
    out.push(
      "gnode \{q(n.id)} label=\{opt(n.label)} lt=\{n.label_type.to_string()} shape=\{q(n.shape)} group=\{n.is_group} parent=\{opt(n.parent_id)} styles=\{texts(Some(n.css_styles))} compiled=\{texts(Some(n.css_compiled_styles))} classes=\{q(n.css_classes)} dir=\{opt(n.dir)} link=\{opt(n.link)} target=\{opt(n.link_target)} tooltip=\{opt(n.tooltip)} color=\{int(n.color_index)} kind=\{opt(n.kind)} metadata=\{metadata(n.metadata)}",
    )
  }
  for e in graph.edges {
    out.push(
      "gedge \{q(e.id)} user=\{e.is_user_defined_id} \{q(e.start)} \{q(e.end)} type=\{q(e.kind)} label=\{q(e.label)} lt=\{e.label_type.to_string()} thickness=\{opt(e.thickness)} minlen=\{int(e.minlen)} arrows=\{e.arrow_type_start},\{e.arrow_type_end} compiled=\{texts(Some(e.css_compiled_styles))} style=\{texts(Some(e.style))} classes=\{q(e.classes)} animate=\{json(e.animate)} animation=\{json(e.animation)} curve=\{opt(e.curve.map(@util.js_string))} metadata=\{metadata(e.metadata)}",
    )
  }
  for d in db.diagnostics {
    let at = match d.position {
      Some(p) => position(p)
      None => "-"
    }
    out.push(
      "diagnostic \{d.id} \{d.severity} \{q(d.message)} node=\{opt(d.node_id)} edge=\{opt(d.edge_id)} at=\{at}",
    )
  }
  out.join("\n")
}

///|
/// FNV-1a over UTF-16 code units, as the generator of the expectations hashes pele's dumps.
fn fnv1a(text : String) -> String {
  let mut h : UInt32 = 0x811c9dc5U
  for i in 0..<text.length() {
    h = (h ^ text.unsafe_get(i).to_int().reinterpret_as_uint()) * 0x01000193U
  }
  let digits = "0123456789abcdef"
  let out = StringBuilder()
  for shift in [28, 24, 20, 16, 12, 8, 4, 0] {
    let d = ((h >> shift) & 0xfU).reinterpret_as_int()
    out.write_char(digits.get_char(d).unwrap())
  }
  out.to_string()
}

///|
/// What reading the source gives through the same steps as `@core.render` up to parsing, written as the generator writes pele's outcome.
fn outcome(
  source : String,
  dump : (@agentflow.AgentflowDb) -> String,
) -> String {
  let model : Ref[@agentflow.AgentflowDb?] = { val: None, }
  let diagram : @types.Diagram = {
    kind: "agentflow",
    section: None,
    keep_comments: true,
    math: false,
    parse: (text, config, title, line_offset, limits) => {
      model.val = Some(
        @agentflow.parse_model(text, config, title, line_offset, limits),
      )
      { render: (_, _) => { svg: "", width: 0, height: 0, links: [], }, }
    },
  }
  let options = {
    ..@types.RenderOptions::default(),
    limit: Some(50000),
    max_edges: Some(5000),
  }
  ignore(@core.render([diagram], source, options)) catch {
    @errors.PeleError(failure) => {
      let kind = failure.kind.unwrap_or("null")
      let mermaid_type = failure.mermaid_type.unwrap_or("null")
      return "error \{failure.code.to_string()} \{kind} \{mermaid_type}\n\{failure.message}"
    }
  }
  match model.val {
    Some(db) => "ok \{fnv1a(dump(db))}"
    None => "no model"
  }
}

///|
/// The cases whose outcome differs from pele's, one per line.
fn mismatches(
  cases : Array[(String, String)],
  dump : (@agentflow.AgentflowDb) -> String,
) -> String {
  let wrong = []
  for case in cases {
    let (source, expected) = case
    let actual = outcome(source, dump)
    if actual != expected {
      wrong.push(
        "\{source.escape()}: \{actual.escape()} instead of \{expected.escape()}",
      )
    }
  }
  wrong.join("\n")
}
