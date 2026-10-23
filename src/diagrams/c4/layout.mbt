///|
const SHAPE_W : Double = 216

///|
const SHAPE_MIN_H : Double = 64

///|
const PAD_X : Double = 14

///|
const PAD_Y : Double = 12

///|
const GAP_X : Double = 100

///|
const GAP_Y : Double = 88

///|
/// Room for a relation to run along the inside of a boundary.
const GROUP_PAD : Double = 28

///|
const GROUP_GAP : Double = 48

///|
/// How far in from a boundary's left edge its heading starts, unless a line crossing it moves it.
pub const HEAD_LEFT : Double = 16

///|
/// How far below a boundary's top edge its heading starts.
pub const HEAD_TOP : Double = 10

///|
/// Shape keywords Mermaid accepts in $shape, $sprite or $tags, as names of the shared shapes.
let forms : Map[String, String] = {
  "person": "person",
  "box": "rect",
  "rounded": "rect",
  "component": "rect",
  "cylinder": "cyl",
  "database": "cyl",
  "db": "cyl",
  "queue": "h-cyl",
  "pipe": "h-cyl",
}

///|
/// A laid out shape.
pub(all) struct Node {
  box : Box
  shape : C4Element
  /// Type, name, technology, description.
  labels : Array[@text.Label]
  text_h : Double
}

///|
/// A laid out boundary.
pub(all) struct Group {
  box : Box
  boundary : C4Element
  kids : Array[Group]
  nodes : Array[Node]
  /// Name, type, description.
  labels : Array[@text.Label]
  head : Double
  head_w : Double
  mut head_x : Double
}

///|
/// Where everything is drawn.
pub(all) struct Layout {
  /// The boundaries that are drawn, parents before children. The first is the unnamed top level.
  order : Array[Group]
  /// The box of each element that is drawn, by element id.
  boxes : Map[Int32, Box]
}

///|
/// ASCII lower case, which is all the shape keywords need: no other character lower-cases into one of their letters.
fn lower_ascii(text : String) -> String {
  let out = StringBuilder()
  for c in text {
    if c >= 'A' && c <= 'Z' {
      out.write_char((c.to_int() + 32).unsafe_to_char())
    } else {
      out.write_char(c)
    }
  }
  out.to_string()
}

///|
fn form_of(shape : C4Element) -> String {
  let explicit = match forms.get(lower_ascii(shape.shape.unwrap_or(""))) {
    Some(form) => Some(form)
    None => forms.get(lower_ascii(shape.sprite.unwrap_or("")))
  }
  if explicit is Some(form) {
    return form
  }
  if shape.tags is Some(tags) && tags != "" {
    for tag in tags.split(",") {
      if forms.get(lower_ascii(@util.trim(tag.to_owned()))) is Some(form) {
        return form
      }
    }
  }
  let kind = shape.kind
  if kind.has_suffix("person") {
    "person"
  } else if kind.has_suffix("_db") {
    "cyl"
  } else if kind.has_suffix("_queue") {
    "h-cyl"
  } else {
    "rect"
  }
}

///|
/// `[text]`, or nothing for an empty or missing value.
fn bracketed(text : String?) -> String? {
  match text {
    Some(t) if t != "" => Some("[" + t + "]")
    _ => None
  }
}

///|
fn measure(
  shape : C4Element,
  measurer : @text.TextMeasurer,
  size : Double,
  small : Double,
  width : Double,
) -> Node {
  let form = form_of(shape)
  let cap_w = if form == "h-cyl" { 36.0 } else { 0 }
  let cap_h = if form == "person" {
    HEAD
  } else if form == "cyl" {
    24
  } else {
    0
  }
  let inner = width - 2 * PAD_X - cap_w
  let labels = [
    @text.layout_label(
      Some("«" + shape.kind.replace_all(old="_", new=" ") + "»"),
      false,
      measurer,
      small - 1,
      inner,
    ),
    @text.layout_label(
      Some(shape.label),
      false,
      measurer,
      size,
      inner,
      base=@text.STYLE_BOLD,
    ),
    @text.layout_label(bracketed(shape.techn), false, measurer, small, inner),
    @text.layout_label(shape.descr, false, measurer, small, inner),
  ]
  let mut tw = 0.0
  let mut text_h = if labels[3].height > 0 { 4.0 } else { 0 }
  for label in labels {
    tw = @util.js_max(tw, label.width)
    text_h += label.height
  }
  {
    box: {
      id: shape.id,
      x: 0,
      y: 0,
      w: @util.js_max(width, tw + 2 * PAD_X + cap_w),
      h: @util.js_max(SHAPE_MIN_H, text_h + 2 * PAD_Y + cap_h),
      form,
    },
    shape,
    labels,
    text_h,
  }
}

///|
/// Places boxes left to right in rows of `per_row`, from (0, 0), and returns the width and height the rows take.
/// Shapes are stretched to the height of their row; boundaries keep their own.
fn rows(
  boxes : Array[Box],
  per_row : Double,
  gap_x : Double,
  gap_y : Double,
  stretch : Bool,
) -> (Double, Double) {
  let count = boxes.length()
  let mut width = 0.0
  let mut y = 0.0
  let mut from = 0.0
  while from < count.to_double() {
    let start = from.to_int()
    let end = @util.js_min(count.to_double(), from + per_row).to_int()
    let mut x = 0.0
    let mut row_h = 0.0
    for i in start..<end {
      row_h = @util.js_max(row_h, boxes[i].h)
    }
    for i in start..<end {
      let box = boxes[i]
      box.x = x
      box.y = y
      if stretch {
        box.h = row_h
      }
      x += box.w + gap_x
    }
    width = @util.js_max(width, x - gap_x)
    y += row_h + gap_y
    from += per_row
  }
  (width, if count > 0 { y - gap_y } else { 0 })
}

///|
/// Mermaid's grid: in each boundary, its shapes in rows of c4ShapeInRow, then the boundaries inside it in rows of
/// c4BoundaryInRow, each sized around its own content.
/// With `room`, rows hold no more than fit in it, and `gap` is the space between shapes.
pub fn layout_c4(
  db : C4Db,
  measurer : @text.TextMeasurer,
  size : Double,
  small : Double,
  room : Double?,
  gap : Double,
) -> Layout {
  let group_pad = if room is None { GROUP_PAD } else { 12 }
  let groups : Map[Int32, Group] = Map([])
  for boundary in db.boundaries {
    let label_room = match room {
      None => 4000.0
      Some(room) => @util.js_max(80, room - 2 * HEAD_LEFT - 2 * GROUP_PAD * 2)
    }
    let labels = if boundary.parent is Some(_) {
      [
        @text.layout_label(
          Some(boundary.label),
          false,
          measurer,
          size,
          label_room,
          base=@text.STYLE_BOLD,
        ),
        @text.layout_label(
          bracketed(boundary.type_),
          false,
          measurer,
          small,
          label_room,
        ),
        @text.layout_label(boundary.descr, false, measurer, small, label_room),
      ]
    } else {
      []
    }
    let mut head = 0.0
    let mut head_w = 0.0
    for label in labels {
      head += label.height
      head_w = @util.js_max(head_w, label.width)
    }
    groups[boundary.id] = {
      box: { id: boundary.id, x: 0, y: 0, w: 0, h: 0, form: "rect", },
      boundary,
      kids: [],
      nodes: [],
      labels,
      head: if head > 0 {
        head + HEAD_TOP + 6 + LANE
      } else {
        group_pad
      },
      head_w,
      head_x: HEAD_LEFT,
    }
  }
  let root = groups.get(db.boundaries[0].id).unwrap()
  for _, group in groups {
    if group.boundary.parent is Some(parent) &&
      groups.get(parent.id) is Some(holder) {
      holder.kids.push(group)
    }
  }
  // A boundary that ends up inside itself is not reachable from the top, as in Mermaid.
  let order = [root]
  let depths : Map[Int32, Int32] = Map([(root.boundary.id, 0)])
  for i = 0; i < order.length(); i = i + 1 {
    for kid in order[i].kids {
      depths[kid.boundary.id] = depths.get(order[i].boundary.id).unwrap() + 1
      order.push(kid)
    }
  }
  for shape in db.shapes {
    if shape.parent is Some(parent) {
      let depth = depths.get(parent.id).unwrap_or(0)
      let node_width = match room {
        None => SHAPE_W
        Some(room) =>
          @util.js_max(
            100,
            @util.js_min(SHAPE_W, room - 2 * depth.to_double() * group_pad - 32),
          )
      }
      if groups.get(parent.id) is Some(group) {
        group.nodes.push(measure(shape, measurer, size, small, node_width))
      }
    }
  }
  let per_row = @util.js_max(1, db.shape_in_row)
  let groups_per_row = @util.js_max(1, db.boundary_in_row)
  let kids_top : Map[Int32, Double] = Map([])
  for i = order.length() - 1; i >= 0; i = i - 1 {
    let group = order[i]
    let gap_x = if room is None { GAP_X } else { gap }
    let count = (boxes : Array[Box], limit : Double, gap : Double) => {
      match room {
        None => limit
        Some(room) => {
          let mut widest = 1.0
          for box in boxes {
            widest = @util.js_max(widest, box.w)
          }
          @util.js_max(
            1,
            @util.js_min(
              limit,
              ((room + gap - 2 * group_pad) / (widest + gap)).floor(),
            ),
          )
        }
      }
    }
    let node_boxes = group.nodes.map(node => node.box)
    let kid_boxes = group.kids.map(kid => kid.box)
    let (grid_w, grid_h) = rows(
      node_boxes,
      count(node_boxes, per_row, gap_x),
      gap_x,
      GAP_Y,
      true,
    )
    let (kids_w, kids_h) = rows(
      kid_boxes,
      count(kid_boxes, groups_per_row, GROUP_GAP),
      GROUP_GAP,
      GROUP_GAP,
      false,
    )
    let between = if grid_h > 0 && kids_h > 0 { GROUP_GAP } else { 0 }
    let is_root = i == 0
    let frame = if is_root { 0.0 } else { group_pad }
    kids_top[group.boundary.id] = grid_h + between
    group.box.w = @util.js_max(
        @util.js_max(grid_w, kids_w),
        group.head_w + 2 * HEAD_LEFT - 2 * frame,
      ) +
      2 * frame
    group.box.h = (if frame == 0 { 0 } else { group.head }) +
      grid_h +
      between +
      kids_h +
      frame
  }
  let boxes : Map[Int32, Box] = Map([])
  for i, group in order {
    let is_root = i == 0
    let left = group.box.x + (if is_root { 0 } else { group_pad })
    let top = group.box.y + (if is_root { 0 } else { group.head })
    for node in group.nodes {
      node.box.x += left
      node.box.y += top
      boxes[node.shape.id] = node.box
    }
    for kid in group.kids {
      kid.box.x += left
      kid.box.y += top + kids_top.get(group.boundary.id).unwrap()
    }
    if !is_root {
      boxes[group.boundary.id] = group.box
    }
  }
  { order, boxes, }
}
