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
fn num(value : Double?) -> String {
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
fn metadata(value : Map[String, Json]?) -> String {
  match value {
    None => "-"
    Some(fields) => json(Some(Json::object(fields)))
  }
}

///|
fn dump(db : @flowchart.FlowDb) -> String {
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
      "node \{q(n.id)} text=\{opt(n.text)} lt=\{n.label_type.to_string()} type=\{opt(n.kind)} styles=\{texts(Some(n.styles))} classes=\{texts(Some(n.classes))} dir=\{opt(n.dir)} props=\{props(n.props)} link=\{opt(n.link)} target=\{opt(n.link_target)} icon=\{opt(n.icon)} form=\{opt(n.form)} pos=\{opt(n.pos)} img=\{opt(n.img)} constraint=\{opt(n.constraint)} w=\{num(n.asset_width)} h=\{num(n.asset_height)}",
    )
  }
  for e in db.edges {
    let length = num(e.length.map(l => l.to_double()))
    out.push(
      "edge \{q(e.start)} \{q(e.end)} id=\{q(e.id)} user=\{e.is_user_defined_id} type=\{opt(e.kind)} text=\{q(e.text)} lt=\{e.label_type.to_string()} stroke=\{opt(e.stroke)} length=\{length} style=\{texts(e.style)} classes=\{texts(Some(e.classes))} interpolate=\{json(e.interpolate)} animate=\{json(e.animate)} animation=\{json(e.animation)}",
    )
  }
  for s in db.subgraphs {
    out.push(
      "subgraph \{q(s.id)} title=\{q(s.title)} lt=\{s.label_type.to_string()} dir=\{opt(s.dir)} nodes=\{texts(Some(s.nodes))} classes=\{texts(Some(s.classes))} metadata=\{metadata(s.metadata)}",
    )
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
