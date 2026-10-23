///|
/// The sequence model, built as Mermaid's SequenceDB builds it.
pub struct SeqDb {
  actors : Map[String, SeqActor]
  created_actors : Map[String, Int32]
  destroyed_actors : Map[String, Int32]
  boxes : Array[SeqBox]
  messages : Array[SeqMessage]
  notes : Array[SeqNote]
  mut title : String?
  mut acc_title : String?
  mut acc_descr : String?
  priv mut prev_actor : String?
  priv mut current_box : SeqBox?
  priv mut last_created : String?
  priv mut last_destroyed : String?
  priv wrap_enabled : Bool?
  priv sequence_wrap : Bool
  priv active : Map[String, Int32]
}

///|
/// A model with the top-level `wrap` setting, which the `%%{wrap}%%` directive also sets, and `sequence.wrap`.
pub fn SeqDb::new(wrap? : Bool, sequence_wrap~ : Bool = false) -> SeqDb {
  {
    actors: Map([]),
    created_actors: Map([]),
    destroyed_actors: Map([]),
    boxes: [],
    messages: [],
    notes: [],
    title: None,
    acc_title: None,
    acc_descr: None,
    prev_actor: None,
    current_box: None,
    last_created: None,
    last_destroyed: None,
    wrap_enabled: wrap,
    sequence_wrap,
    active: Map([]),
  }
}

///|
fn fail(message : String) -> @errors.PeleError {
  @errors.pele_error(message, code=Semantic, kind="sequence")
}

///|
/// Whether text without a `wrap:` or `nowrap:` prefix wraps.
pub fn SeqDb::auto_wrap(self : SeqDb) -> Bool {
  self.wrap_enabled.unwrap_or(self.sequence_wrap)
}

///|
pub fn SeqDb::set_acc_title(self : SeqDb, text : String) -> Unit {
  self.acc_title = Some(@util.trim_start(text))
}

///|
/// Keeps the description with the indentation of every line after the first removed, as `replace(/\n\s+/g, '\n')` does.
pub fn SeqDb::set_acc_description(self : SeqDb, text : String) -> Unit {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    let c = @util.code_at(text, i)
    @util.write_range(out, text, i, i + 1)
    i += 1
    if c == 10 {
      while i < text.length() && @util.is_space(@util.code_at(text, i)) {
        i += 1
      }
    }
  }
  self.acc_descr = Some(out.to_string())
}

///|
pub fn SeqDb::set_diagram_title(self : SeqDb, text : String) -> Unit {
  self.title = Some(text)
}

///|
/// The length of a `wrap:` or `nowrap:` prefix, with an optional colon before it, at the start of `text`, or -1.
fn wrap_prefix(text : String, word : String) -> Int32 {
  let start = if @util.code_at(text, 0) == 58 { 1 } else { 0 }
  if @util.starts_with_at(text, word + ":", start) {
    start + word.length() + 1
  } else {
    -1
  }
}

///|
fn extract_wrap(raw : String) -> SeqText {
  let text = @util.trim(raw)
  let wrap = wrap_prefix(text, "wrap")
  let nowrap = wrap_prefix(text, "nowrap")
  if wrap >= 0 {
    { text: @util.trim(@util.slice(text, wrap)), wrap: Some(true), }
  } else if nowrap >= 0 {
    { text: @util.trim(@util.slice(text, nowrap)), wrap: Some(false), }
  } else {
    { text, wrap: None, }
  }
}

///|
/// Whether `text` holds a line terminator other than a line feed, from `from` on.
fn has_line_terminator(text : String, from : Int32) -> Bool {
  for i in from..<text.length() {
    let c = @util.code_at(text, i)
    if c == 13 || c == 0x2028 || c == 0x2029 {
      return true
    }
  }
  false
}

///|
/// The length of a leading `/^(?:rgba?|hsla?)\s*\(/`, or -1.
fn box_function(text : String) -> Int32 {
  if !text.has_prefix("rgb") && !text.has_prefix("hsl") {
    return -1
  }
  let mut i = 3
  if @util.code_at(text, i) == 97 {
    i += 1
  }
  while @util.is_space(@util.code_at(text, i)) {
    i += 1
  }
  if @util.code_at(text, i) == 40 {
    i + 1
  } else {
    -1
  }
}

///|
/// Splits a box line into a leading color and the rest, as Mermaid's
/// `/^((?:rgba?|hsla?)\s*\(.*\)|\w*)(.*)$/` does.
/// pele treats only `\r`, U+2028, and U+2029 as the line terminators that stop the match, which this follows.
fn split_box(text : String) -> (String, String)? {
  let open = box_function(text)
  if open >= 0 {
    let close = @util.last_index_of(text, ")")
    if close >= open {
      if has_line_terminator(text, open) {
        return None
      }
      return Some(
        (@util.slice(text, 0, end=close + 1), @util.slice(text, close + 1)),
      )
    }
  }
  if has_line_terminator(text, 0) {
    return None
  }
  let mut word = 0
  while @util.is_word(@util.code_at(text, word)) {
    word += 1
  }
  Some((@util.slice(text, 0, end=word), @util.slice(text, word)))
}

///|
/// Reads the `wrap:` or `nowrap:` prefix of a text.
pub fn SeqDb::parse_message(self : SeqDb, text : String) -> SeqText {
  ignore(self)
  extract_wrap(text)
}

///|
/// Splits a box line into its fill and its title.
/// A first word that is not a color belongs to the title.
pub fn SeqDb::parse_box_data(self : SeqDb, line : String) -> SeqBoxData {
  ignore(self)
  let parts = split_box(line)
  let mut color = match parts {
    Some((color, _)) if color != "" => @util.trim(color)
    _ => "transparent"
  }
  let mut title = match parts {
    Some((_, title)) if title != "" => Some(@util.trim(title))
    _ => None
  }
  if !is_css_color(color) {
    color = "transparent"
    title = Some(@util.trim(line))
  }
  guard title is Some(title) else { return { text: None, color, wrap: None, } }
  let { text, wrap, } = extract_wrap(title)
  { text: if text == "" { None } else { Some(text) }, color, wrap, }
}

///|
fn SeqDb::add_box(self : SeqDb, data : SeqBoxData) -> Unit {
  let box = {
    name: data.text,
    wrap: data.wrap.unwrap_or(self.auto_wrap()),
    fill: data.color,
    actor_keys: [],
  }
  self.current_box = Some(box)
  self.boxes.push(box)
}

///|
fn SeqDb::add_actor(
  self : SeqDb,
  id : String,
  name : String,
  description : SeqText?,
  kind : String?,
  metadata : String?,
) -> Unit raise @errors.PeleError {
  let mut description = description
  let mut kind = kind
  let mut assigned_box = self.current_box
  let mut doc : Map[String, Json]? = None
  if metadata is Some(metadata) {
    let source = if @util.index_of(metadata, "\n") != -1 {
      metadata + "\n"
    } else {
      "{\n" + metadata + "\n}"
    }
    let parsed = @util.parse_yaml(source) catch {
      @util.YamlError(message) =>
        raise @errors.pele_error(
          "Config of participant \"\{id}\" is not valid YAML. \{message}",
          code=Syntax,
          kind="sequence",
        )
    }
    if parsed is Object(fields) {
      doc = Some(fields)
    }
  }
  if doc is Some(doc) {
    match doc.get("type") {
      Some(Null) | None => ()
      Some(value) => kind = Some(@util.js_string(value))
    }
    if doc.get("alias") is Some(alias_value) &&
      @util.js_truthy(alias_value) &&
      (
        description is None ||
        (description is Some({ text, .. }) && text == name)
      ) {
      description = Some({
        text: @util.js_string(alias_value),
        wrap: description.bind(d => d.wrap),
      })
    }
  }
  if self.actors.get(id) is Some(old) {
    if self.current_box is Some(current) &&
      old.box is Some(previous) &&
      !physical_equal(current, previous) {
      let show = (box : SeqBox) => box.name.unwrap_or("undefined")
      raise fail(
        "A same participant should only be defined in one Box: \{old.name} can't be in '\{show(previous)}' and in '\{show(current)}' at the same time.",
      )
    }
    assigned_box = if old.box is Some(_) { old.box } else { self.current_box }
    old.box = assigned_box
    if name == old.name && description is None {
      return
    }
  }
  // A participant that is only mentioned in a message has no kind and takes its name as its label.
  let label = match (description, kind) {
    (Some(description), Some(_)) => description
    _ => { text: name, wrap: None, }
  }
  self.actors.set(id, {
    box: assigned_box,
    name,
    description: label.text,
    wrap: label.wrap.unwrap_or(self.auto_wrap()),
    prev_actor: self.prev_actor,
    next_actor: None,
    links: Map([]),
    properties: Map([]),
    details: None,
    kind: kind.unwrap_or("participant"),
  })
  if self.prev_actor is Some(prev) && prev != "" {
    if self.actors.get(prev) is Some(previous) {
      previous.next_actor = Some(id)
    }
  }
  if self.current_box is Some(box) {
    box.actor_keys.push(id)
  }
  self.prev_actor = Some(id)
}

///|
fn SeqDb::add_signal(
  self : SeqDb,
  from : String?,
  to : String?,
  message : SeqText?,
  kind : Int32,
  activate~ : Bool = false,
  central_connection? : Int32,
) -> Unit raise @errors.PeleError {
  // Mermaid recounts every earlier message here. A running count per participant says the same.
  if kind == ACTIVE_END {
    let count = match from {
      Some(from) if from != "" => self.active.get(from).unwrap_or(0)
      _ => 0
    }
    if count < 1 {
      raise fail(
        "Trying to inactivate an inactive participant (\{from.unwrap_or("undefined")})",
      )
    }
    self.active.set(from.unwrap(), count - 1)
  } else if kind == ACTIVE_START && from is Some(from) && from != "" {
    self.active.set(from, self.active.get(from).unwrap_or(0) + 1)
  }
  self.messages.push({
    id: self.messages.length().to_string(),
    from,
    to,
    message: match message {
      Some(message) => message.text
      None => ""
    },
    numbering: None,
    wrap: match message {
      Some({ wrap: Some(wrap), .. }) => wrap
      _ => self.auto_wrap()
    },
    kind,
    activate,
    placement: None,
    central_connection: central_connection.unwrap_or(0),
  })
}

///|
fn SeqDb::add_note(
  self : SeqDb,
  actors : Array[String],
  placement : Int32,
  message : SeqText,
) -> Unit {
  let wrap = message.wrap.unwrap_or(self.auto_wrap())
  self.notes.push({ actors, placement, message: message.text, wrap, })
  let to = if actors.length() > 1 { actors[1] } else { actors[0] }
  self.messages.push({
    id: self.messages.length().to_string(),
    from: Some(actors[0]),
    to: Some(to),
    message: message.text,
    numbering: None,
    wrap,
    kind: NOTE,
    activate: false,
    placement: Some(placement),
    central_connection: 0,
  })
}

///|
/// The index an object key stands for when JavaScript treats it as an array index, or -1.
fn array_index(key : String) -> Int64 {
  let n = key.length()
  if n == 0 || n > 10 || (n > 1 && @util.code_at(key, 0) == 48) {
    return -1
  }
  let mut value = 0L
  for i in 0..<n {
    let c = @util.code_at(key, i)
    if !@util.is_digit(c) {
      return -1
    }
    value = value * 10 + (c - 48).to_int64()
  }
  if value < 4294967295L {
    value
  } else {
    -1
  }
}

///|
/// The entries of a parsed value, as `Object.entries` lists them.
/// Keys that are array indexes come first in ascending order, as JavaScript orders an object's own keys.
fn entries(value : Json) -> Array[(String, Json)] {
  match value {
    String(text) => {
      let out = []
      let mut i = 0
      for char in text {
        out.push((i.to_string(), Json::string(char.to_string())))
        i += 1
      }
      out
    }
    Array(items) => items.mapi((i, item) => (i.to_string(), item))
    Object(fields) => {
      let indexed = []
      let named = []
      for key, item in fields {
        let index = array_index(key)
        if index >= 0 {
          indexed.push((index, key, item))
        } else {
          named.push((key, item))
        }
      }
      indexed.sort_by((a, b) => a.0.compare(b.0))
      indexed.map(entry => (entry.1, entry.2)) + named
    }
    _ => []
  }
}

///|
/// Reads menu text as JSON, as `JSON.parse` does; text that is not JSON gives nothing.
fn menu_json(text : String) -> Json? {
  Some(@json.parse(text)) catch {
    _ => None
  }
}

///|
/// Mermaid logs and ignores menu text that is not valid JSON.
/// It also undoes the `&amp;` and `&equals;` its sanitizer writes; pele has no sanitizer, and a `;` cannot occur in the text.
fn SeqDb::add_links(self : SeqDb, actor_id : String, text : SeqText) -> Unit {
  guard self.actors.get(actor_id) is Some(actor) else { return }
  guard menu_json(text.text) is Some(parsed) else { return }
  for entry in entries(parsed) {
    actor.links.set(entry.0, entry.1)
  }
}

///|
fn SeqDb::add_a_link(self : SeqDb, actor_id : String, text : SeqText) -> Unit {
  guard self.actors.get(actor_id) is Some(actor) else { return }
  let sep = @util.index_of(text.text, "@")
  actor.links.set(
    @util.trim(@util.slice(text.text, 0, end=sep - 1)),
    Json::string(@util.trim(@util.slice(text.text, sep + 1))),
  )
}

///|
fn SeqDb::add_properties(
  self : SeqDb,
  actor_id : String,
  text : SeqText,
) -> Unit {
  guard self.actors.get(actor_id) is Some(actor) else { return }
  guard menu_json(text.text) is Some(parsed) else { return }
  for entry in entries(parsed) {
    actor.properties.set(entry.0, entry.1)
  }
}

///|
/// Mermaid reads the properties and links from a page element with this id. pele keeps the id.
fn SeqDb::add_details(self : SeqDb, actor_id : String, text : SeqText) -> Unit {
  if self.actors.get(actor_id) is Some(actor) {
    actor.details = Some(text.text)
  }
}

///|
/// Applies the statements of a diagram in order.
/// Raises `PeleError` for statements the model refuses.
pub fn SeqDb::apply(
  self : SeqDb,
  statements : Array[SeqStatement],
) -> Unit raise @errors.PeleError {
  for statement in statements {
    self.apply_one(statement)
  }
}

///|
fn SeqDb::apply_one(
  self : SeqDb,
  statement : SeqStatement,
) -> Unit raise @errors.PeleError {
  match statement {
    SequenceIndex(start~, step~, visible~) =>
      self.messages.push({
        id: self.messages.length().to_string(),
        from: None,
        to: None,
        message: "",
        numbering: Some({ start, step, visible, }),
        wrap: false,
        kind: AUTONUMBER,
        activate: false,
        placement: None,
        central_connection: 0,
      })
    AddParticipant(actor~, draw~, description~, config~) =>
      self.add_actor(actor, actor, description, draw, config)
    CreateParticipant(actor~, draw~, description~, config~) => {
      if self.actors.contains(actor) {
        raise fail(
          "It is not possible to have actors with the same id, even if one is destroyed before the next is created. Use 'AS' aliases to simulate the behavior",
        )
      }
      self.last_created = Some(actor)
      self.add_actor(actor, actor, description, draw, config)
      self.created_actors.set(actor, self.messages.length())
    }
    DestroyParticipant(actor) => {
      self.last_destroyed = Some(actor)
      self.destroyed_actors.set(actor, self.messages.length())
    }
    ActiveStart(actor) => self.add_signal(Some(actor), None, None, ACTIVE_START)
    ActiveEnd(actor) => self.add_signal(Some(actor), None, None, ACTIVE_END)
    CentralConnectionStart(actor) =>
      self.add_signal(Some(actor), None, None, CENTRAL_CONNECTION)
    CentralConnectionReverseStart(actor) =>
      self.add_signal(Some(actor), None, None, CENTRAL_CONNECTION_REVERSE)
    AddNote(actors~, placement~, text~) =>
      self.add_note(actors, placement, text)
    AddLinks(actor, text) => self.add_links(actor, text)
    AddALink(actor, text) => self.add_a_link(actor, text)
    AddProperties(actor, text) => self.add_properties(actor, text)
    AddDetails(actor, text) => self.add_details(actor, text)
    AddMessage(from~, to~, signal_type~, msg~, activate~, central_connection~) => {
      if self.last_created is Some(created) && created != "" {
        if to != created {
          raise fail(
            "The created participant \{created} does not have an associated creating message after its declaration. Please check the sequence diagram.",
          )
        }
        self.last_created = None
      } else if self.last_destroyed is Some(destroyed) && destroyed != "" {
        if to != destroyed && from != destroyed {
          raise fail(
            "The destroyed participant \{destroyed} does not have an associated destroying message after its declaration. Please check the sequence diagram.",
          )
        }
        self.last_destroyed = None
      }
      self.add_signal(
        Some(from),
        Some(to),
        Some(msg),
        signal_type,
        activate~,
        central_connection?,
      )
    }
    BoxStart(data) => self.add_box(data)
    BoxEnd => self.current_box = None
    BlockStart(kind, text) => self.add_signal(None, None, Some(text), kind)
    BlockEnd(kind) => self.add_signal(None, None, None, kind)
  }
}
