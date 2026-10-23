///|
/// A node to draw: a state, a composite or one of its regions, a note, or the group a note sits in.
pub(all) struct StateNode {
  id : String
  /// rect, rectWithTitle, stateStart, stateEnd, choice, fork, join, divider, roundedWithTitle, note or noteGroup.
  mut shape : String?
  mut label : String?
  mut description : Array[String]
  mut css_classes : String
  mut css_compiled_styles : Array[String]
  mut css_styles : Array[String]
  mut kind : String?
  mut is_group : Bool
  mut parent_id : String?
  /// The direction inside a composite: its last `direction` statement, or TB.
  mut dir : String?
  mut position : String?
  mut note_for : String?
  mut color_index : Int32?
}

///|
/// A transition, or the dashed line between a note and its state.
/// Labels are markdown throughout, as in Mermaid.
pub(all) struct StateEdge {
  id : String
  start : String
  end : String
  label : String
  classes : String
  dashed : Bool
}

///|
/// The nodes and edges a state diagram draws.
pub(all) struct StateGraph {
  nodes : Array[StateNode]
  edges : Array[StateEdge]
}

///|
/// What is known of a state across the statements that mention it.
priv struct Draft {
  mut shape : String?
  mut description : Description
  mut css_classes : String
  css_styles : Array[String]
  mut kind : String?
  mut dir : String?
  mut color_index : Int32?
}

///|
priv struct Frame {
  item : StateStmt?
  doc : Array[Stmt]
  mut at : Int32
  alt : Bool
}

///|
/// The length JavaScript gives a description: of the string, or of the array.
fn description_length(description : Description) -> Int32 {
  match description {
    Text(text) => text.length()
    Lines(lines) => lines.length()
  }
}

///|
/// The description as the lines `[description].flat()` gives.
fn flat(description : Description) -> Array[String] {
  match description {
    Text(text) => [text]
    Lines(lines) => lines.copy()
  }
}

///|
/// Mermaid's dataFetcher: walks the documents and resolves them into the nodes and edges that are drawn.
pub fn build_state_graph(
  root_doc : Array[Stmt],
  states : Map[String, StateStmt],
  classes : Map[String, StateClassDef],
) -> StateGraph raise @errors.PeleError {
  let nodes : Array[StateNode] = []
  let edges : Array[StateEdge] = []
  let by_id : Map[String, StateNode] = Map([])
  let drafts : Map[String, Draft] = Map([])
  let slots : Map[String, Int32?] = Map([])
  let mut counter = 0
  let mut next_slot = 0
  // `aside` marks the nodes made for a note, which carry a position and no palette slot; a node merged into an existing one overwrites only the fields its kind carries, as `Object.assign` does in pele.
  let insert = (node : StateNode, aside : Bool) => {
    // The two literal ids are what DOMPurify leaves of `<<fork>>` and `<<choice>>` in Mermaid; kept for parity.
    if node.id == "" || node.id == "</join></fork>" || node.id == "</choice>" {
      return
    }
    if node.css_classes != "" {
      // One copy, however many classes: a state named in a class statement many times has a long list.
      let mut compiled : Array[String]? = None
      for name in split(node.css_classes, " ") {
        guard classes.get(name) is Some(def) else { continue }
        let list = match compiled {
          Some(list) => list
          None => {
            let list = node.css_compiled_styles.copy()
            compiled = Some(list)
            list
          }
        }
        for style in def.styles {
          list.push(style)
        }
      }
      if compiled is Some(list) {
        node.css_compiled_styles = list
      }
    }
    match by_id.get(node.id) {
      Some(existing) => {
        let parent_id = match node.parent_id {
          Some(_) => node.parent_id
          None => existing.parent_id
        }
        existing.shape = node.shape
        existing.label = node.label
        existing.description = node.description
        existing.css_classes = node.css_classes
        existing.css_compiled_styles = node.css_compiled_styles
        existing.css_styles = node.css_styles
        existing.kind = node.kind
        existing.is_group = node.is_group
        existing.dir = node.dir
        if aside {
          existing.position = node.position
        } else {
          existing.color_index = node.color_index
        }
        if node.note_for is Some(_) {
          existing.note_for = node.note_for
        }
        existing.parent_id = parent_id
      }
      None => {
        by_id.set(node.id, node)
        nodes.push(node)
      }
    }
  }
  let visit = (parent : StateStmt?, item : StateStmt, alt : Bool) => {
    let id = item.id
    if id == "root" {
      return
    }
    let known = states.get(id)
    let class_str = match known {
      Some(known) => known.classes.join(" ")
      None => ""
    }
    let styles = match known {
      Some(known) => known.styles
      None => []
    }
    let draft = match drafts.get(id) {
      Some(draft) => draft
      None => {
        let mut shape : String? = Some("rect")
        match item.start {
          Some(true) => shape = Some("stateStart")
          Some(false) => shape = Some("stateEnd")
          None => ()
        }
        if item.kind != Some("default") {
          shape = item.kind
        }
        let draft = {
          shape,
          description: Text(id),
          css_classes: "\{class_str} statediagram-state",
          css_styles: styles,
          kind: None,
          dir: None,
          color_index: None,
        }
        drafts.set(id, draft)
        draft
      }
    }
    match item.description {
      Some(Text("")) | None => ()
      Some(given) =>
        match draft.description {
          Lines(lines) => {
            draft.shape = Some("rectWithTitle")
            draft.description = Lines(lines + flat(given))
          }
          Text(text) if text.length() > 0 => {
            draft.shape = Some("rectWithTitle")
            draft.description = Lines(
              if text == id {
                flat(given)
              } else {
                [text] + flat(given)
              },
            )
          }
          Text(_) => {
            draft.shape = Some("rect")
            draft.description = match given {
              Lines(lines) => Lines(lines.copy())
              Text(_) => given
            }
          }
        }
    }
    if description_length(draft.description) == 1 &&
      draft.shape == Some("rectWithTitle") {
      draft.shape = Some(
        if draft.kind == Some("group") {
          "roundedWithTitle"
        } else {
          "rect"
        },
      )
    }
    if draft.kind is (None | Some("")) && item.doc is Some(doc) {
      draft.kind = Some("group")
      draft.dir = Some(doc_direction(doc))
      draft.shape = Some(
        if item.kind == Some("divider") {
          "divider"
        } else {
          "roundedWithTitle"
        },
      )
      // A container takes the next palette slot unless it is a region, which shares its composite's.
      let shared = match parent {
        Some(parent) if draft.shape == Some("divider") => slots.get(parent.id)
        _ => None
      }
      match shared {
        Some(slot) => draft.color_index = slot
        None => {
          let slot = next_slot
          next_slot += 1
          draft.color_index = if @util.trim(class_str) != "" ||
            styles.length() > 0 {
            None
          } else {
            Some(slot)
          }
        }
      }
      slots.set(id, draft.color_index)
      let alt_class = if alt { "statediagram-cluster-alt" } else { "" }
      draft.css_classes = "\{draft.css_classes} statediagram-cluster \{alt_class}"
    }
    let (label, description) = match draft.description {
      Text(text) => (Some(text), [])
      Lines(lines) =>
        (
          lines.get(0),
          if lines.length() > 1 {
            lines[1:].to_owned()
          } else {
            []
          },
        )
    }
    let node : StateNode = {
      id,
      shape: draft.shape,
      label: if draft.shape == Some("divider") {
        Some("")
      } else {
        label
      },
      description,
      css_classes: draft.css_classes,
      css_compiled_styles: [],
      css_styles: draft.css_styles,
      kind: draft.kind,
      is_group: draft.kind == Some("group"),
      parent_id: match parent {
        Some(parent) if parent.id != "root" => Some(parent.id)
        _ => None
      },
      dir: draft.dir,
      position: None,
      note_for: None,
      color_index: draft.color_index,
    }
    guard item.note is Some(note) else {
      insert(node, false)
      return
    }
    // Mermaid puts each note in a group of its own, named after the state.
    // Pele keeps that group in the model and lays the note out beside its state instead.
    let aside = (
      aside_id : String,
      shape : String,
      css_classes : String,
      is_group : Bool,
    ) => {
      id: aside_id,
      shape: Some(shape),
      label: Some(note.text),
      description: [],
      css_classes,
      css_compiled_styles: [],
      css_styles: [],
      kind: Some(if is_group { "group" } else { "node" }),
      is_group,
      parent_id: None,
      dir: None,
      position: Some(note.position),
      note_for: None,
      color_index: None,
    }
    let note_node = aside(
      "\{id}----note-\{counter}",
      "note",
      "statediagram-note",
      false,
    )
    counter += 1
    let group_id = "\{id}----parent"
    note_node.parent_id = Some(group_id)
    note_node.note_for = Some(id)
    insert(aside(group_id, "noteGroup", draft.css_classes, true), true)
    insert(note_node, true)
    insert(node, false)
    let left = note.position == "left of"
    let from = if left { note_node.id } else { id }
    let to = if left { id } else { note_node.id }
    edges.push({
      id: "\{from}-\{to}",
      start: from,
      end: to,
      label: "",
      classes: "transition note-edge",
      dashed: true,
    })
  }
  let stack : Array[Frame] = [{ item: None, doc: root_doc, at: 0, alt: true, }]
  while stack.last() is Some(frame) {
    if frame.at >= frame.doc.length() {
      ignore(stack.pop())
      continue
    }
    let item = frame.doc[frame.at]
    frame.at += 1
    match item {
      State(s) => {
        visit(frame.item, s, frame.alt)
        if s.doc is Some(doc) {
          stack.push({ item: Some(s), doc, at: 0, alt: !frame.alt, })
        }
      }
      Relation(state1, state2, description) => {
        visit(frame.item, state1, frame.alt)
        visit(frame.item, state2, frame.alt)
        edges.push({
          id: "edge\{counter}",
          start: state1.id,
          end: state2.id,
          label: description.unwrap_or(""),
          classes: "transition",
          dashed: false,
        })
        counter += 1
      }
      _ => ()
    }
  }
  for node in nodes {
    if node.is_group && node.description.length() > 0 {
      raise @errors.pele_error(
        "Group nodes can only have label. Remove the additional description for node [\{node.id}]",
        code=Semantic,
        kind="state",
      )
    }
  }
  { nodes, edges, }
}
