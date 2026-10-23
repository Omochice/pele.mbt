///|
/// How far a bone moves toward the tail for each unit it rises from the spine.
const SLANT : Double = 0.5

///|
let length : Double = @util.js_hypot(SLANT, 1)

///|
const FIRST_ROW : Double = 14

///|
const ROW_GAP : Double = 6

///|
const BONE_END : Double = 8

///|
const TWIG_STEP : Double = 22

///|
const STUB : Double = 18

///|
const TEXT_GAP : Double = 5

///|
const PAIR_GAP : Double = 26

///|
const HEAD_GAP : Double = 34

///|
const TAIL : Double = 28

///|
const BOX_PAD_X : Double = 10

///|
const BOX_PAD_Y : Double = 5

///|
/// A cause below a category.
/// Bones at even depths run level, from the slanted bone above them toward the tail; bones at odd
/// depths slant away from the spine, from the level bone above them.
priv struct Bone {
  label : @text.Label
  depth : Int32
  parent : Int32
  /// Its place among its siblings, counted from the spine outward.
  slot : Int32
  kids : Int32
  /// How far its row is from the spine.
  mut rise : Double
  /// Where it meets its parent, measured level from the category's bone: 0 on it, negative toward the tail.
  mut at : Double
  /// Where its text ends.
  mut text_end : Double
}

///|
priv struct Category {
  node : IshikawaNode
  label : @text.Label
  box_w : Double
  box_h : Double
  bones : Array[Bone]
  /// The length of its bone, as distance from the spine.
  mut rise : Double
  /// How far its causes reach toward the tail, measured level from its bone.
  reach : Double
}

///|
priv struct Frame {
  node : IshikawaNode
  depth : Int32
  parent : Int32
  slot : Int32
  /// Set when the bone was made and only its row is still to come.
  mut bone : Int32
}

///|
/// Gives every cause of a category a row of its own, so that no two texts can meet, and measures
/// how far the whole of it reaches.
/// A level bone takes the row nearest the spine and its twigs the rows beyond; a slanted twig
/// takes the row beyond everything that hangs off it.
/// The outline may be nested as deep as its indentation goes, so the walk keeps a stack of its own.
fn arrange(
  node : IshikawaNode,
  up : Bool,
  measurer : @text.TextMeasurer,
  size : Double,
  small : Double,
) -> Category {
  let label = @text.layout_label(Some(node.text), false, measurer, size, 180)
  let line_height = (small * 1.5).round()
  let bones : Array[Bone] = []
  let rows : Array[Int32] = []
  let stack : Array[Frame] = []
  // Above the spine the first cause goes farthest out, so that the causes read from the top down.
  let push = (children : Array[IshikawaNode], depth : Int32, parent : Int32) => {
    let n = children.length()
    for slot = n - 1; slot >= 0; slot = slot - 1 {
      stack.push({
        node: children[if up { n - 1 - slot } else { slot }],
        depth,
        parent,
        slot,
        bone: -1,
      })
    }
  }
  push(node.children, 2, -1)
  while stack.pop() is Some(frame) {
    if frame.bone != -1 {
      rows.push(frame.bone)
      continue
    }
    let index = bones.length()
    bones.push({
      label: @text.layout_label(
        Some(frame.node.text),
        false,
        measurer,
        small,
        200,
      ),
      depth: frame.depth,
      parent: frame.parent,
      slot: frame.slot,
      kids: frame.node.children.length(),
      rise: 0,
      at: 0,
      text_end: 0,
    })
    if frame.depth % 2 == 0 {
      rows.push(index)
    } else {
      frame.bone = index
      stack.push(frame)
    }
    push(frame.node.children, frame.depth + 1, index)
  }
  let mut rise = FIRST_ROW
  for index in rows {
    let height = @util.js_max(bones[index].label.height, line_height) + ROW_GAP
    bones[index].rise = rise + height / 2
    rise += height
  }
  let box_w = label.width + 2 * BOX_PAD_X
  let mut reach = box_w / 2
  for bone in bones {
    if bone.depth % 2 == 0 {
      bone.at = if bone.parent == -1 { 0 } else { bones[bone.parent].at }
      bone.text_end = bone.at -
        (if bone.kids > 0 {
          (bone.kids + 1).to_double() * TWIG_STEP
        } else {
          STUB
        }) -
        TEXT_GAP
    } else {
      // Twigs stand along their level bone, the one nearest the spine nearest the tail.
      let parent = bones[bone.parent]
      bone.at = parent.at - (parent.kids - bone.slot).to_double() * TWIG_STEP
      bone.text_end = bone.at - TEXT_GAP
    }
    reach = @util.js_max(reach, bone.label.width - bone.text_end)
  }
  {
    node,
    label,
    box_w,
    box_h: label.height + 2 * BOX_PAD_Y,
    bones,
    rise: rise + BONE_END,
    reach,
  }
}

///|
/// Draws an Ishikawa diagram as a fishbone, or as an outline when it has to run down.
pub fn render_ishikawa(
  model : IshikawaModel,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  @common.turn_to_fit(options, down => draw(model, options, down))
}

///|
fn draw(
  model : IshikawaModel,
  options : @types.RenderOptions,
  down : Bool,
) -> @types.Rendered raise @errors.PeleError {
  if down {
    return vertical_causes(model, options)
  }
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.875).round()
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let title = @text.layout_label(
    model.title,
    false,
    measurer,
    size,
    4000,
    base=@text.STYLE_BOLD,
  )
  let title_height = if title.height > 0 { title.height + 12 } else { 0 }
  let body = @svg.Markup::new()
  let mut min_x = 0.0
  let mut max_x = 0.0
  let mut min_y = 0.0
  let mut max_y = 0.0
  if model.root is Some(root) {
    let head = @text.layout_label(
      Some(root.text),
      false,
      measurer,
      size,
      200,
      base=@text.STYLE_BOLD,
    )
    let head_h = @util.js_max(head.height + 24, 48)
    let head_w = head.width + 24 + head_h / 2
    let categories = root.children.mapi((i, node) => {
      arrange(node, i % 2 == 0, measurer, size, small)
    })
    // Even a category without causes has a bone long enough to carry its name clear of the head.
    for category in categories {
      category.rise = @util.js_max(category.rise, head_h / 2 + 14)
    }

    // Categories meet the spine in pairs, one above and one below, each pair as far toward the
    // tail from the one before as the wider of the two needs.
    let xs : Array[Double] = []
    let mut x = -HEAD_GAP
    for i = 0; i < categories.length(); i = i + 2 {
      if i > 0 {
        let mut room = 0.0
        for side in 0..<2 {
          let before = categories[i - 2 + side]
          let next_half = match categories.get(i + side) {
            Some(next) => next.box_w / 2
            None => 0.0
          }
          room = @util.js_max(room, before.reach + next_half)
        }
        x = x - (room + PAIR_GAP)
      }
      xs.push(x)
      xs.push(x)
    }
    let tail = if categories.length() > 0 { x - TAIL } else { -HEAD_GAP }
    max_x = head_w
    min_x = tail
    min_y = -head_h / 2
    max_y = head_h / 2
    let groups = @svg.Markup::new()
    for i, category in categories {
      let sign = if i % 2 == 0 { -1.0 } else { 1.0 }
      let ax = xs[i]
      let px = (at : Double, rise : Double) => ax + at - rise * SLANT
      let end_x = px(0, category.rise)
      let end_y = sign * category.rise
      // The bone stops short of the spine to leave its arrowhead a clean point.
      let trim = @svg.ARROW - 1
      let d = @svg.Markup::new()
      d.write(
        "M\{@svg.num(ax - SLANT / length * trim)},\{@svg.num(sign * trim / length)}L\{@svg.num(end_x)},\{@svg.num(end_y)}",
      )
      let texts = @svg.Markup::new()
      for bone in category.bones {
        let y = sign * bone.rise
        if bone.depth % 2 == 0 {
          d.write(
            "M\{@svg.num(px(bone.at, bone.rise))},\{@svg.num(y)}H\{@svg.num(px(bone.text_end + TEXT_GAP, bone.rise))}",
          )
        } else {
          let from = category.bones[bone.parent].rise
          d.write(
            "M\{@svg.num(px(bone.at, from))},\{@svg.num(sign * from)}L\{@svg.num(px(bone.at, bone.rise))},\{@svg.num(y)}",
          )
        }
        let right = px(bone.text_end, bone.rise)
        texts.write(
          @svg.label_svg(
            bone.label,
            right - bone.label.width / 2,
            y,
            if bone.depth > 2 {
              " fill=\"var(--_m)\""
            } else {
              ""
            },
          ),
        )
        min_x = @util.js_min(min_x, right - bone.label.width)
      }
      let box_y = end_y + sign * (category.box_h / 2)
      min_x = @util.js_min(min_x, end_x - category.box_w / 2)
      max_x = @util.js_max(max_x, end_x + category.box_w / 2)
      min_y = @util.js_min(min_y, box_y - category.box_h / 2)
      max_y = @util.js_max(max_y, box_y + category.box_h / 2)
      groups.write(
        "<g class=\"pele-ishikawa-category\" data-id=\"\{@svg.esc_text(category.node.text)}\">",
      )
      groups.write_group(
        "<path class=\"pele-ishikawa-bones\" d=\"", d, "\" fill=\"none\" stroke=\"var(--_l)\"/>",
      )
      groups.write(
        @svg.marker(
          "arrow_point",
          ax,
          0,
          SLANT / length,
          -sign / length,
          "var(--_l)",
        ) +
        "<rect x=\"\{@svg.num(end_x - category.box_w / 2)}\" y=\"\{@svg.num(box_y - category.box_h / 2)}\" width=\"\{@svg.num(category.box_w)}\" height=\"\{@svg.num(category.box_h)}\" fill=\"var(--_s)\" stroke=\"var(--_b)\"\{@svg.ROUNDED}/>" +
        @svg.label_svg(category.label, end_x, box_y, " class=\"pele-label\""),
      )
      if !texts.is_empty() {
        groups.write_group(
          "<g class=\"pele-ishikawa-causes\" font-size=\"\{small}\">",
          texts,
          "</g>",
        )
      }
      groups.write("</g>")
    }
    let r = head_h / 2
    body.write(
      "<path class=\"pele-ishikawa-spine\" d=\"M\{@svg.num(tail)},0H\{@svg.num(-(@svg.ARROW - 1))}\" fill=\"none\" stroke=\"var(--_l)\"/>" +
      @svg.marker("arrow_point", 0, 0, 1, 0, "var(--_l)"),
    )
    body.write_markup(groups)
    body.write(
      "<g class=\"pele-ishikawa-head\" data-id=\"\{@svg.esc_text(root.text)}\">" +
      "<path d=\"M0,\{@svg.num(-r)}H\{@svg.num(head_w - r)}A\{@svg.num(r)},\{@svg.num(r)} 0 0 1 \{@svg.num(head_w - r)},\{@svg.num(r)}H0Z\" fill=\"var(--_s)\" stroke=\"var(--_b)\" stroke-linejoin=\"round\"/>" +
      @svg.label_svg(
        head,
        12 + head.width / 2,
        0,
        " class=\"pele-label\" font-weight=\"var(--_hw)\"",
      ) +
      "</g>",
    )
  }
  let inner = @util.js_max(max_x - min_x, title.width)
  let width = (inner + 2 * pad).ceil()
  let height = (max_y - min_y + title_height + 2 * pad).ceil()
  let ox = pad + (inner - (max_x - min_x)) / 2 - min_x
  let oy = pad + title_height - min_y
  let content = @svg.Markup::new()
  content.write(
    @svg.label_svg(
      title,
      width / 2,
      pad + title.height / 2,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
    ),
  )
  if !body.is_empty() {
    content.write_group(
      "<g transform=\"translate(\{@svg.num(ox)},\{@svg.num(oy)})\">",
      body,
      "</g>",
    )
  }
  {
    svg: @svg.markup_document(
      "ishikawa",
      width,
      height,
      size,
      options,
      None,
      None,
      content,
    ),
    width,
    height,
    links: [],
  }
}

///|
priv struct Entry {
  node : IshikawaNode
  depth : Int32
  parent : Int32
  mut x : Double
  mut y : Double
  mut w : Double
  mut h : Double
}

///|
/// The outline that replaces the fishbone where there is too little width for it: every line of
/// the diagram on a row of its own, indented by its depth, with a connector to its parent.
fn vertical_causes(
  model : IshikawaModel,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  let size = options.font_size.unwrap_or(16)
  let small = (size * 0.875).round()
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let room = @util.js_max(140, options.max_width.unwrap_or(320) - 2 * pad)
  let title = @text.layout_label(
    model.title,
    false,
    measurer,
    size,
    @common.title_room(options),
    base=@text.STYLE_BOLD,
  )
  let order : Array[Entry] = []
  let pending : Array[(IshikawaNode, Int32, Int32)] = []
  if model.root is Some(root) {
    pending.push((root, 0, -1))
  }
  let mut depth = 0
  while pending.pop() is Some((node, node_depth, parent)) {
    let index = order.length()
    order.push({ node, depth: node_depth, parent, x: 0, y: 0, w: 0, h: 0, })
    depth = if node_depth > depth { node_depth } else { depth }
    for i = node.children.length() - 1; i >= 0; i = i - 1 {
      pending.push((node.children[i], node_depth + 1, index))
    }
  }
  let indent = @util.js_min(
    20,
    @util.js_max(2, (room - 120) / @util.js_max(1, depth.to_double())),
  )
  let mut y = pad + (if title.height != 0 { title.height + 12 } else { 0 })
  let mut width = title.width
  let nodes = @svg.Markup::new()
  let edges = @svg.Markup::new()
  for entry in order {
    entry.x = pad + entry.depth.to_double() * indent
    let label_room = @util.js_max(
      60,
      room - entry.depth.to_double() * indent - 20,
    )
    let framed = entry.depth < 2
    let label = @common.break_label(
      @text.layout_label(
        Some(entry.node.text),
        false,
        measurer,
        if framed {
          size
        } else {
          small
        },
        label_room,
        base=if framed { @text.STYLE_BOLD } else { 0 },
      ),
      measurer,
      label_room,
    )
    entry.w = label.width + 20
    entry.h = label.height + 12
    entry.y = y
    y += entry.h + 12
    width = @util.js_max(width, entry.x - pad + entry.w)
    let class_name = match entry.depth {
      0 => "pele-ishikawa-head"
      1 => "pele-ishikawa-category"
      _ => "pele-ishikawa-cause"
    }
    nodes.write(
      "<g class=\"pele-node \{class_name}\" data-id=\"\{@svg.esc_text(entry.node.text)}\">",
    )
    if framed {
      nodes.write(
        "<rect x=\"\{@svg.num(entry.x)}\" y=\"\{@svg.num(entry.y)}\" width=\"\{@svg.num(entry.w)}\" height=\"\{@svg.num(entry.h)}\" rx=\"\{if entry.depth == 0 { 12 } else { 4 }}\" fill=\"var(--_s)\" stroke=\"var(--_b)\"/>",
      )
    }
    nodes.write(
      @svg.label_svg(
        label,
        entry.x + entry.w / 2,
        entry.y + entry.h / 2,
        " class=\"pele-label\"\{if framed { " font-weight=\"var(--_hw)\"" } else { "" }}\{if entry.depth > 1 { " font-size=\"\{small}\"" } else { "" }}",
      ) +
      "</g>",
    )
    if entry.parent >= 0 {
      let parent = order[entry.parent]
      let gx = parent.x + indent / 2
      edges.write(
        "<path class=\"pele-edge\" d=\"M\{@svg.num(gx)},\{@svg.num(parent.y + parent.h)}V\{@svg.num(entry.y + entry.h / 2)}H\{@svg.num(entry.x)}\" fill=\"none\" stroke=\"var(--_b)\"/>",
      )
    }
  }
  let total_width = (width + 2 * pad).ceil()
  let height = (@util.js_max(pad + title.height, y - 12) + pad).ceil()
  let content = @svg.Markup::new()
  content.write(
    @svg.label_svg(
      title,
      total_width / 2,
      pad + title.height / 2,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
    ),
  )
  content.write_markup(edges)
  content.write_markup(nodes)
  {
    svg: @svg.markup_document(
      "ishikawa",
      total_width,
      height,
      size,
      options,
      None,
      None,
      content,
    ),
    width: total_width,
    height,
    links: [],
  }
}
