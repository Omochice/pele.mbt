///|
pub(all) enum EntityKind {
  Ui
  Processor
  Command
  ReadModel
  Event
}

///|
pub(all) enum LaneGroup {
  Trigger
  State
  Stream
}

///|
pub(all) struct EmLane {
  /// Mermaid's ordering key: 0 for UI/Automation, 100 for Command/Read Model, 200 for Events, and the next free number after those for each namespace.
  /// Namespaces of different groups can share a number, so a lane is told apart by its `key`.
  index : Int32
  key : String
  label : String
  group : LaneGroup
  /// The namespace of the lane, which pele spells `namespace`, a reserved word here.
  scope : String?
}

///|
pub(all) struct EmBox {
  /// The frame number as written, such as "01".
  id : String
  kind : EntityKind
  entity : String
  name : String
  scope : String?
  reset : Bool
  lane : EmLane
  /// Example data from the frame or from the data block it refers to.
  data : String?
  data_type : String?
}

///|
/// A relation between two boxes of the model, told apart by their ids, which are unique.
pub(all) struct EmRelation {
  source : EmBox
  target : EmBox
}

///|
pub(all) struct EmNote {
  frame : String
  text : String
  data_type : String?
}

///|
pub(all) struct EmSpecification {
  frame : String
  given : Array[String]
  when_ : Array[String]
  then_ : Array[String]
}

///|
pub(all) struct EventModelingModel {
  title : String?
  acc_title : String?
  acc_descr : String?
  boxes : Array[EmBox]
  /// Sorted from top to bottom.
  lanes : Array[EmLane]
  relations : Array[EmRelation]
  notes : Array[EmNote]
  specifications : Array[EmSpecification]
  entities : Array[String]
}

///|
fn entity_kind(type_ : String) -> EntityKind {
  match type_ {
    "ui" => Ui
    "pcr" | "processor" => Processor
    "rmo" | "readmodel" => ReadModel
    "cmd" | "command" => Command
    _ => Event
  }
}

///|
fn group_of(kind : EntityKind) -> LaneGroup {
  match kind {
    Ui | Processor => Trigger
    Event => Stream
    Command | ReadModel => State
  }
}

///|
/// The key, first index, label and label prefix for a namespace of a group.
fn group_details(group : LaneGroup) -> (String, Int32, String, String) {
  match group {
    Trigger => ("trigger", 0, "UI/Automation", "UI/A: ")
    State => ("state", 100, "Command/Read Model", "C/RM: ")
    Stream => ("stream", 200, "Events", "Stream: ")
  }
}

///|
/// Does what `text.split('\n')` does: an empty text gives one empty line.
fn split_lines(text : String) -> Array[String] {
  let lines = []
  let mut from = 0
  while true {
    let at = @util.index_of(text, "\n", from~)
    if at == -1 {
      lines.push(@util.slice(text, from))
      break
    }
    lines.push(@util.slice(text, from, end=at))
    from = at + 1
  }
  lines
}

///|
fn without_returns(text : String) -> String {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    if @util.code_at(text, i) != '\r'.to_int() {
      @util.write_range(out, text, i, i + 1)
    }
    i += 1
  }
  out.to_string()
}

///|
/// The text between the outer braces, without the indentation its lines share.
fn block_text(raw : String) -> String {
  let open = @util.index_of(raw, "{")
  let close = @util.last_index_of(raw, "}")
  let inner = if open != -1 && close > open {
    @util.slice(raw, open + 1, end=close)
  } else if open == -1 && raw.length() >= 2 {
    @util.slice(raw, 1, end=-1)
  } else {
    ""
  }
  let lines = split_lines(without_returns(inner))
  let blank = (line : String) => @util.trim(line) == ""
  let mut first = 0
  let mut last = lines.length()
  while first < last && blank(lines[first]) {
    first += 1
  }
  while last > first && blank(lines[last - 1]) {
    last -= 1
  }
  let mut indent = None
  for i in first..<last {
    let line = lines[i]
    if blank(line) {
      continue
    }
    let width = line.length() - @util.trim_start(line).length()
    indent = match indent {
      Some(shared) if shared <= width => Some(shared)
      _ => Some(width)
    }
  }
  let shared = indent.unwrap_or(0)
  let out = []
  for i in first..<last {
    let line = lines[i]
    out.push(
      @util.trim_end(@util.slice(line, @cmp.minimum(shared, line.length()))),
    )
  }
  out.join("\n")
}

///|
/// Does what `text.replace(/\n\s+/g, '\n')` does.
fn join_indented_lines(text : String) -> String {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    @util.write_range(out, text, i, i + 1)
    if @util.code_at(text, i) == '\n'.to_int() &&
      @util.is_space(@util.code_at(text, i + 1)) {
      i += 1
      while @util.is_space(@util.code_at(text, i)) {
        i += 1
      }
    } else {
      i += 1
    }
  }
  out.to_string()
}

///|
/// Builds the model of an event model, with the front matter title as the title it has none of its own.
pub fn build_event_model(
  ast : EventModelAst,
  title : String?,
) -> EventModelingModel raise @errors.PeleError {
  let ids : Map[String, Unit] = Map([])
  for frame in ast.frames {
    if ids.contains(frame.name) {
      let line = @errors.locate(ast.source, frame.offset).0
      raise @errors.pele_error(
        "Duplicate event modeling frame ID \"\{frame.name}\" on line \{line}",
        code=Semantic,
        kind="eventmodeling",
        line~,
      )
    }
    ids[frame.name] = ()
  }
  let data : Map[String, String] = Map([])
  for entity in ast.data_entities {
    if !data.contains(entity.name) {
      data[entity.name] = entity.data_block_value
    }
  }

  // One lane per group, and one more per namespace within a group.
  let lane_of : Map[String, EmLane] = Map([])
  let next : Map[String, Int32] = Map([])
  let lane = (kind : EntityKind, scope : String?) => {
    let group = group_of(kind)
    let (name, first, label, prefix) = group_details(group)
    let key = match scope {
      Some(scope) => "\{name} \{scope}"
      None => name
    }
    match lane_of.get(key) {
      Some(found) => found
      None => {
        let index = match scope {
          Some(_) => {
            let index = next.get(name).unwrap_or(first + 1)
            next[name] = index + 1
            index
          }
          None => first
        }
        let label = match scope {
          Some(scope) => prefix + scope
          None => label
        }
        let created : EmLane = { index, key, label, group, scope, }
        lane_of[key] = created
        created
      }
    }
  }

  let boxes : Array[EmBox] = []
  let relations = []
  for index, frame in ast.frames {
    let dots = frame.entity_identifier.split(".").collect()
    // Only a two-part name has a namespace.
    let scope = if dots.length() == 2 { Some(dots[0].to_owned()) } else { None }
    let kind = entity_kind(frame.model_entity_type)
    let mut text = frame.data_inline_value.map(block_text)
    if frame.data_reference is Some(reference) &&
      data.get(reference) is Some(block) {
      text = Some(block_text(block))
    }
    let box : EmBox = {
      id: frame.name,
      kind,
      entity: frame.entity_identifier,
      name: if dots.length() == 2 {
        dots[1].to_owned()
      } else {
        frame.entity_identifier
      },
      scope,
      reset: frame.reset,
      lane: lane(kind, scope),
      data: text,
      data_type: frame.data_type,
    }
    boxes.push(box)
    if frame.source_frames.length() > 0 {
      // Sources connect in frame order, and only frames that already have a box.
      let wanted : Map[String, Unit] = Map([])
      for source in frame.source_frames {
        wanted[source] = ()
      }
      for source in boxes {
        if wanted.contains(source.id) {
          relations.push({ source, target: box, })
        }
      }
    } else if index > 0 && !box.reset {
      // Otherwise the nearest earlier frame in another lane feeds this one.
      for i = index - 1; i >= 0; i = i - 1 {
        if boxes[i].lane.key != box.lane.key {
          relations.push({ source: boxes[i], target: box, })
          break
        }
      }
    }
  }

  let lanes = lane_of.values().collect()
  let order = Array::makei(lanes.length(), i => i)
  order.sort_by((a, b) => {
    let by_index = lanes[a].index.compare(lanes[b].index)
    if by_index != 0 {
      by_index
    } else {
      a.compare(b)
    }
  })
  let own_title = match ast.title {
    Some(text) => @common.title_value(text)
    None => ""
  }
  {
    title: if own_title != "" {
      Some(own_title)
    } else {
      title
    },
    acc_title: ast.acc_title.map(text => {
      @util.trim_start(@common.acc_title_value(text))
    }),
    acc_descr: ast.acc_descr.map(text => {
      join_indented_lines(@common.acc_descr_value(text))
    }),
    boxes,
    lanes: order.map(i => lanes[i]),
    relations,
    notes: ast.note_entities.map(note => {
      frame: note.source_frame,
      text: block_text(note.data_block_value),
      data_type: note.data_type,
    }),
    specifications: ast.gwt_entities.map(gwt => {
      frame: gwt.source_frame,
      given: gwt.given,
      when_: gwt.when_,
      then_: gwt.then_,
    }),
    entities: ast.model_entities,
  }
}
