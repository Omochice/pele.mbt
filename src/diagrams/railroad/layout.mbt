///|
priv enum Kind {
  TerminalBox
  NonTerminalBox
  SpecialBox
  SequenceBox
  ChoiceBox
  BypassBox
  LoopBox
  FoldedBox
}

///|
/// A laid-out element.
/// The track enters at the left edge and leaves at the right edge on one baseline,
/// with `up` above it and `down` below it.
priv struct Box {
  kind : Kind
  width : Double
  up : Double
  down : Double
  kids : Array[Box]
  /// A leaf's text, or a loop's count.
  text : String
  /// The name a non-terminal refers to.
  id : String
  /// How far a bypass rises above the baseline, or a loop drops below it.
  reach : Double
}

///|
priv struct Metrics {
  measurer : @text.TextMeasurer
  size : Double
  padding : Double
  height : Double
  /// Space between elements in a sequence, and between stacked branches.
  gap : Double
  sep : Double
  arc : Double
}

///|
const COUNT_SIZE : Double = 12

///|
const ARROW : Double = 7

///|
fn even(value : Double) -> Double {
  (value / 2).ceil() * 2
}

///|
fn maximum(a : Double, b : Double) -> Double {
  if b > a {
    b
  } else {
    a
  }
}

///|
fn replace_controls(text : String) -> String {
  let out = StringBuilder()
  for i in 0..<text.length() {
    let c = @util.code_at(text, i)
    if c == '\n'.to_int() {
      out.write_string("\\n")
    } else if c == '\r'.to_int() {
      out.write_string("\\r")
    } else if c == '\t'.to_int() {
      out.write_string("\\t")
    } else {
      @util.write_range(out, text, i, i + 1)
    }
  }
  out.to_string()
}

///|
/// Text is literal here: a terminal such as "<br>" or "*" is itself, not markup.
/// Mermaid's `#35;` codes still stand for characters, and escapes that would be invisible are written out.
fn shown(text : String) -> String {
  let decoded = if @util.index_of(text, "¶ß") != -1 {
    @text.decode_entities(text.replace_all(old="&", new="&amp;"))
  } else {
    text
  }
  replace_controls(decoded)
}

///|
fn leaf(
  kind : Kind,
  text : String,
  id : String,
  style : Int32,
  m : Metrics,
) -> Box {
  let half = m.height / 2
  let width = maximum(
    even(m.measurer.width(text, m.size, style) + 2 * m.padding),
    m.height,
  )
  { kind, width, up: half, down: half, kids: [], text, id, reach: 0, }
}

///|
fn count(min : Double, max : Double) -> String {
  if max == @double.infinity && min <= 1 {
    return ""
  }
  let text = (value : Double) => {
    if value.is_inf() {
      "∞"
    } else {
      value.to_string()
    }
  }
  if min == max {
    return text(min) + "×"
  }
  if max == @double.infinity {
    return "≥" + text(min) + "×"
  }
  if min == 0 {
    "≤" + text(max) + "×"
  } else {
    text(min) + "–" + text(max) + "×"
  }
}

///|
/// Where the next branch of a choice sits below the baseline, given the one above it.
fn below(offset : Double, above : Box, branch : Box, m : Metrics) -> Double {
  maximum(offset + above.down + m.sep + branch.up, 2 * m.arc)
}

///|
fn bypass(kid : Box, m : Metrics) -> Box {
  let reach = maximum(kid.up + m.sep, 2 * m.arc)
  {
    kind: BypassBox,
    width: kid.width + 4 * m.arc,
    up: reach,
    down: kid.down,
    kids: [kid],
    text: "",
    id: "",
    reach,
  }
}

///|
fn group(kind : Kind, kids : Array[Box], width : Double) -> Box {
  let mut up = 0.0
  let mut down = 0.0
  for kid in kids {
    up = maximum(up, kid.up)
    down = maximum(down, kid.down)
  }
  { kind, width, up, down, kids, text: "", id: "", reach: 0, }
}

///|
fn fold_rows(kids : Array[Box], room : Double, m : Metrics) -> Box {
  let mut width = maximum(0, (kids.length() - 1).to_double()) * m.gap
  for kid in kids {
    width += kid.width
  }
  let sequence = group(SequenceBox, kids, width)
  if width <= room || kids.length() < 2 {
    return sequence
  }
  let rows : Array[Box] = []
  let mut row : Array[Box] = []
  let mut row_width = 0.0
  let flush = () => {
    rows.push(group(SequenceBox, row, row_width))
    row = []
    row_width = 0
  }
  for kid in kids {
    if row.length() > 0 &&
      row_width + m.gap + kid.width > maximum(40, room - 6 * m.arc) {
      flush()
    }
    row_width += (if row.length() > 0 { m.gap } else { 0 }) + kid.width
    row.push(kid)
  }
  flush()
  if rows.length() < 2 {
    return sequence
  }
  let mut folded_width = 0.0
  let mut offset = 0.0
  for i, row in rows {
    folded_width = maximum(folded_width, row.width)
    if i > 0 {
      offset += rows[i - 1].down + maximum(m.sep, 2 * m.arc) + row.up
    }
  }
  {
    kind: FoldedBox,
    width: folded_width + 6 * m.arc,
    up: rows[0].up,
    down: offset + rows[rows.length() - 1].down,
    kids: rows,
    text: "",
    id: "",
    reach: 0,
  }
}

///|
fn stack_choice(kids : Array[Box], m : Metrics) -> Box {
  let mut inner = 0.0
  let mut offset = 0.0
  for i, kid in kids {
    inner = maximum(inner, kid.width)
    if i > 0 {
      offset = below(offset, kids[i - 1], kid, m)
    }
  }
  {
    kind: ChoiceBox,
    width: inner + 4 * m.arc,
    up: if kids.length() > 0 {
      kids[0].up
    } else {
      0
    },
    down: if kids.length() > 0 {
      offset + kids[kids.length() - 1].down
    } else {
      0
    },
    kids,
    text: "",
    id: "",
    reach: 0,
  }
}

///|
fn loop_back(kid : Box, min : Double, max : Double, m : Metrics) -> Box {
  let text = count(min, max)
  let reach = maximum(kid.down + m.sep, 2 * m.arc)
  let label = if text == "" {
    0.0
  } else {
    even(m.measurer.width(text, COUNT_SIZE, 0))
  }
  let looped = {
    kind: LoopBox,
    width: maximum(kid.width, label) + 2 * m.arc,
    up: kid.up,
    down: reach + (if text == "" { ARROW / 2 + 1 } else { COUNT_SIZE + 6 }),
    kids: [kid],
    text,
    id: "",
    reach,
  }
  if min == 0 {
    bypass(looped, m)
  } else {
    looped
  }
}

///|
fn build(
  node : RailroadNode,
  room : Double,
  kids : Array[Box],
  m : Metrics,
) -> Box {
  match node {
    Terminal(value) => {
      let text = shown(value)
      let spaces = text.length() > 0 && text.iter().all(c => c == ' ')
      leaf(
        TerminalBox,
        if spaces {
          "␣".repeat(text.length())
        } else {
          text
        },
        "",
        @text.STYLE_MONO,
        m,
      )
    }
    NonTerminal(name) => leaf(NonTerminalBox, shown(name), name, 0, m)
    Special(text) =>
      leaf(SpecialBox, "? " + shown(text) + " ?", "", @text.STYLE_ITALIC, m)
    Sequence(_) => fold_rows(kids, room, m)
    Choice(_) => stack_choice(kids, m)
    Optional(_) => bypass(kids[0], m)
    Repetition(min~, max~, ..) =>
      if min == 1 && max == 1 {
        kids[0]
      } else {
        loop_back(kids[0], min, max, m)
      }
  }
}

///|
fn children(node : RailroadNode) -> Array[RailroadNode] {
  match node {
    Sequence(elements) => elements
    Choice(alternatives) => alternatives
    Optional(element) => [element]
    Repetition(element~, ..) => [element]
    _ => []
  }
}

///|
/// How much of its width a node's parts must give up, when a sequence that folds puts its rows inside rails.
fn around(node : RailroadNode, m : Metrics) -> Double {
  match node {
    Choice(_) | Optional(_) => 4 * m.arc
    Repetition(min~, ..) => (if min == 0 { 6.0 } else { 2.0 }) * m.arc
    Sequence(_) => 6 * m.arc
    _ => 0
  }
}

///|
priv struct Pending {
  node : RailroadNode
  room : Double
  kids : Array[RailroadNode]
  results : Array[Box]
}

///|
fn pending(node : RailroadNode, room : Double) -> Pending {
  { node, room, kids: children(node), results: [], }
}

///|
/// Lays out a node with an explicit stack, so that nesting depth is bounded by memory, not by the stack.
/// `room` is the width the node should fit in, or infinity.
fn measure(root : RailroadNode, m : Metrics, room : Double) -> Box {
  let stack = [pending(root, room)]
  while true {
    let top = stack[stack.length() - 1]
    if top.results.length() < top.kids.length() {
      let child = top.kids[top.results.length()]
      let child_room = if top.room == @double.infinity {
        @double.infinity
      } else {
        maximum(40, top.room - around(top.node, m))
      }
      stack.push(pending(child, child_room))
    } else {
      let value = build(top.node, top.room, top.results, m)
      stack.pop() |> ignore
      if stack.is_empty() {
        return value
      }
      stack[stack.length() - 1].results.push(value)
    }
  }
  abort("unreachable")
}
