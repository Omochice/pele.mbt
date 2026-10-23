///|
/// The string as `JSON.stringify` writes it.
fn quote(text : String) -> String {
  let out = StringBuilder()
  out.write_char('"')
  for c in text {
    match c {
      '"' => out.write_string("\\\"")
      '\\' => out.write_string("\\\\")
      '\b' => out.write_string("\\b")
      '\u{0c}' => out.write_string("\\f")
      '\n' => out.write_string("\\n")
      '\r' => out.write_string("\\r")
      '\t' => out.write_string("\\t")
      _ => out.write_char(c)
    }
  }
  out.write_char('"')
  out.to_string()
}

///|
/// The value with object keys in the order they were written and numbers as JavaScript prints them.
fn show(value : Json) -> String {
  match value {
    Null => "null"
    True => "true"
    False => "false"
    Number(number, ..) => if number == 0 { "0" } else { number.to_string() }
    String(text) => quote(text)
    Array(items) => "[" + items.map(show).join(",") + "]"
    Object(entries) =>
      "{" +
      entries
      .iter()
      .map(entry => quote(entry.0) + ":" + show(entry.1))
      .join(",") +
      "}"
  }
}

///|
fn list(name : String, values : Array[String]) -> String {
  if values.length() > 0 {
    " \{name}=" + values.map(quote).join(",")
  } else {
    ""
  }
}

///|
fn optional(name : String, value : String?) -> String {
  match value {
    Some(text) => " \{name}=\{quote(text)}"
    None => ""
  }
}

///|
fn flag(name : String, on : Bool) -> String {
  if on {
    " \{name}"
  } else {
    ""
  }
}

///|
/// The model one element a line, in the format the expected values were written in.
fn dump(m : @usecase.UsecaseModel) -> String {
  let out = []
  for _, a in m.actors {
    out.push(
      "actor \{quote(a.id)} \{quote(a.label)} \{a.label_type} \{a.actor_type}" +
      optional("icon", a.icon) +
      flag("business", a.business) +
      optional("stereotype", a.stereotype) +
      optional("parent", a.parent_id) +
      list("classes", a.classes) +
      list("styles", a.styles),
    )
  }
  for _, u in m.use_cases {
    out.push(
      "usecase \{quote(u.id)} \{quote(u.label)} \{u.label_type} \{u.shape}" +
      flag("business", u.business) +
      optional("stereotype", u.stereotype) +
      optional("parent", u.parent_id) +
      list("classes", u.classes) +
      list("styles", u.styles),
    )
  }
  for _, b in m.system_boundaries {
    out.push(
      "boundary \{quote(b.id)} \{quote(b.label)} \{b.label_type} \{b.boundary_type}" +
      list("members", b.members) +
      list("classes", b.classes) +
      list("styles", b.styles),
    )
  }
  for r in m.relationships {
    let label = match (r.label, r.label_type) {
      (Some(label), Some(label_type)) => " label=\{quote(label)} \{label_type}"
      _ => ""
    }
    let animation = match r.animation {
      Some(animation) => " animation=\{animation}"
      None => ""
    }
    out.push(
      "relationship \{quote(r.id)}\{flag("explicit", r.explicit_id)} \{quote(r.source)} \{r.rel_type}/\{r.arrow_type} \{quote(r.target)} minlen=\{r.minlen}" +
      label +
      list("classes", r.classes) +
      list("styles", r.styles) +
      flag("animate", r.animate) +
      animation,
    )
  }
  for _, n in m.notes {
    out.push(
      "note \{quote(n.id)} \{quote(n.target)} \{quote(n.label)} \{n.label_type}",
    )
  }
  for _, j in m.json_nodes {
    out.push(
      "json \{quote(j.id)} \{show(Json::object(j.value))}" +
      list("classes", j.classes) +
      list("styles", j.styles),
    )
  }
  for _, c in m.class_defs {
    out.push("classDef \{quote(c.id)}" + list("styles", c.styles))
  }
  out.push("direction \{m.direction}")
  if m.title is Some(title) {
    out.push("title \{quote(title)}")
  }
  if m.acc_title != "" {
    out.push("accTitle \{quote(m.acc_title)}")
  }
  if m.acc_descr != "" {
    out.push("accDescr \{quote(m.acc_descr)}")
  }
  out.join("\n")
}
