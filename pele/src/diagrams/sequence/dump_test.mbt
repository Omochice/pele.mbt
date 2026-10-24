///|
/// The model one fact per line, in the format the expected dumps were written in from pele's model.
fn dump(db : @sequence.SeqDb) -> String {
  let out = []
  let opt = (text : String?) => {
    match text {
      Some(text) => quote(text)
      None => "-"
    }
  }
  let entries = (values : Map[String, Json]) => {
    let parts = []
    for key, value in values {
      parts.push("\{quote(key)}:\{value.stringify()}")
    }
    parts.join(",")
  }
  for id, a in db.actors {
    let box = match a.box {
      Some(box) => opt(box.name)
      None => "none"
    }
    out.push(
      "actor \{quote(id)} name=\{quote(a.name)} description=\{quote(a.description)} wrap=\{a.wrap} kind=\{quote(a.kind)} box=\{box} prev=\{opt(a.prev_actor)} next=\{opt(a.next_actor)} links={\{entries(a.links)}} properties={\{entries(a.properties)}} details=\{opt(a.details)}",
    )
  }
  for b in db.boxes {
    out.push(
      "box \{opt(b.name)} fill=\{quote(b.fill)} wrap=\{b.wrap} actors=\{b.actor_keys.map(quote).join(",")}",
    )
  }
  for m in db.messages {
    let numbering = match m.numbering {
      Some(n) => {
        let show = (value : Double?) => {
          match value {
            Some(value) => value.to_string()
            None => "-"
          }
        }
        "\{show(n.start)},\{show(n.step)},\{n.visible}"
      }
      None => "-"
    }
    let placement = match m.placement {
      Some(p) => p.to_string()
      None => "-"
    }
    out.push(
      "message \{m.id} from=\{opt(m.from)} to=\{opt(m.to)} kind=\{m.kind} message=\{quote(m.message)} wrap=\{m.wrap} activate=\{m.activate} placement=\{placement} central=\{m.central_connection} numbering=\{numbering}",
    )
  }
  for n in db.notes {
    out.push(
      "note \{n.actors.map(quote).join(",")} placement=\{n.placement} message=\{quote(n.message)} wrap=\{n.wrap}",
    )
  }
  for id, at in db.created_actors {
    out.push("created \{quote(id)}=\{at}")
  }
  for id, at in db.destroyed_actors {
    out.push("destroyed \{quote(id)}=\{at}")
  }
  out.push(
    "title=\{opt(db.title)} accTitle=\{opt(db.acc_title)} accDescr=\{opt(db.acc_descr)}",
  )
  out.join("\n")
}

///|
/// A wrap setting as pele's dump writes it.
fn show_wrap(wrap : Bool?) -> String {
  match wrap {
    Some(wrap) => wrap.to_string()
    None => "undefined"
  }
}
