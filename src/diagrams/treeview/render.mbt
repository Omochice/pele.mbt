///|
const ICON_GAP : Double = 6

///|
const DESC_GAP : Double = 16

///|
const GUIDE_INSET : Double = 7

///|
const ELBOW : Double = 4

///|
const HIGHLIGHT_OVERHANG : Double = 4

///|
fn setting(
  config : @types.Config,
  key : String,
  fallback : Double,
  min : Double,
  max : Double,
) -> Double {
  guard config.get("treeView") is Some(Object(section)) else { return fallback }
  match section.get(key) {
    Some(Number(value, ..)) if value >= min && value <= max => value
    _ => fallback
  }
}

///|
/// Mermaid's layout options, with Pele's defaults.
pub(all) struct TreeSettings {
  padding_x : Double
  padding_y : Double
  row_indent : Double
  line_thickness : Double
}

///|
/// Reads the layout options from the `treeView` section of the config.
/// A value outside its range is ignored.
pub fn tree_settings(config : @types.Config) -> TreeSettings {
  {
    padding_x: setting(config, "paddingX", 5, 0, 100),
    padding_y: setting(config, "paddingY", 2, 0, 100),
    row_indent: setting(config, "rowIndent", 15, 0, 400),
    line_thickness: setting(config, "lineThickness", 1, 0.25, 12),
  }
}

///|
priv struct Row {
  node : TreeNode
  x : Double
  cy : Double
  icon : String?
  text : String
  label_x : Double
  highlighted : Bool
  label : @text.Label?
  description : @text.Label?
  top : Double
  height : Double
}

///|
/// Whether one of the whitespace-separated classes is `highlight`.
fn has_highlight(css_class : String) -> Bool {
  let mut i = 0
  let n = css_class.length()
  while i < n {
    while i < n && @util.is_space(@util.code_at(css_class, i)) {
      i += 1
    }
    let start = i
    while i < n && !@util.is_space(@util.code_at(css_class, i)) {
      i += 1
    }
    if @util.slice(css_class, start, end=i) == "highlight" {
      return true
    }
  }
  false
}

///|
/// Draws a tree view.
pub fn render_treeview(
  model : TreeViewModel,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered {
  @common.tighten(options, tight => draw(model, config, options, tight))
}

///|
/// `tight` wraps names and descriptions to the width the host has and pulls the levels closer.
fn draw(
  model : TreeViewModel,
  config : @types.Config,
  options : @types.RenderOptions,
  tight : Bool,
) -> @types.Rendered {
  let size = options.font_size.unwrap_or(16)
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let icons = icon_config(config)
  let { padding_x, padding_y, row_indent, line_thickness, } = tree_settings(
    config,
  )
  let max_width = options.max_width.unwrap_or(320)
  let mut max_depth = 0
  if tight {
    let depths = model.root.children.map(node => (node, 0))
    let mut i = 0
    while i < depths.length() {
      let (node, depth) = depths[i]
      max_depth = @cmp.maximum(max_depth, depth)
      for child in node.children {
        depths.push((child, depth + 1))
      }
      i += 1
    }
  }
  let step = if tight {
    @util.js_min(
      row_indent + padding_x,
      @util.js_max(
        2,
        (max_width - 120) / @util.js_max(1, max_depth.to_double()),
      ),
    )
  } else {
    row_indent + padding_x
  }
  let row_height = (size * 1.5).round() + 2 * padding_y
  let icon_size = size
  let title = @text.layout_label(
    model.title,
    false,
    measurer,
    size,
    if tight {
      @common.title_room(options)
    } else {
      4000
    },
    base=@text.STYLE_BOLD,
  )
  let title_height = if title.height > 0 { title.height + 12 } else { 0 }
  // Siblings line up: when one entry of a folder has an icon, the others leave room for one.
  let has_icon = (list : Array[TreeNode]) => {
    list
    .iter()
    .any(child => {
      node_icon(child.name, child.node_type, child.icon, icons) is Some(_)
    })
  }
  let rows : Array[Row] = []
  let row_of : Map[Int32, Row] = Map([])
  let pending : Array[(TreeNode, Int32, Bool)] = []
  let push = (list : Array[TreeNode], depth : Int32) => {
    let slot = has_icon(list)
    let mut i = list.length() - 1
    while i >= 0 {
      pending.push((list[i], depth, slot))
      i -= 1
    }
  }
  push(model.root.children, 0)
  let mut label_right = 0.0
  let mut any_highlight = false
  let mut rows_height = 0.0
  while !pending.is_empty() {
    let (node, depth, slot) = pending.pop().unwrap()
    let directory = node.node_type is Directory
    let x = depth.to_double() * step
    let text = @text.decode_entities(node.name)
    let label_x = x + (if slot { icon_size + ICON_GAP } else { 0 })
    let room = @util.js_max(
      40,
      max_width - 2 * pad - 2 * HIGHLIGHT_OVERHANG - label_x,
    )
    let label = if tight {
      Some(
        @common.literal_label(
          text,
          measurer,
          size,
          room,
          style=if directory { @text.STYLE_BOLD } else { 0 },
        ),
      )
    } else {
      None
    }
    let description = match node.description {
      Some(description) if tight =>
        Some(
          @common.literal_label(
            @text.decode_entities(description),
            measurer,
            size,
            room,
            style=@text.STYLE_ITALIC,
          ),
        )
      _ => None
    }
    let width = match label {
      Some(label) => label.width
      None =>
        measurer.width(text, size, if directory { @text.STYLE_BOLD } else { 0 })
    }
    if label_x + width > label_right {
      label_right = label_x + width
    }
    let highlighted = match node.css_class {
      Some(css_class) => has_highlight(css_class)
      None => false
    }
    if highlighted {
      any_highlight = true
    }
    let label_height = label.map(l => l.height).unwrap_or(0)
    let height = if tight {
      @util.js_max(
        row_height,
        label_height +
        description.map(l => l.height).unwrap_or(0) +
        2 * padding_y,
      )
    } else {
      row_height
    }
    let cy = rows_height +
      (if tight {
        padding_y + @util.js_max(icon_size, label_height) / 2
      } else {
        height / 2
      })
    let row : Row = {
      node,
      x,
      cy,
      icon: node_icon(node.name, node.node_type, node.icon, icons),
      text,
      label_x,
      highlighted,
      label,
      description,
      top: rows_height,
      height,
    }
    rows_height += height
    rows.push(row)
    row_of[node.id] = row
    push(node.children, depth + 1)
  }
  let desc_x = label_right + DESC_GAP
  let mut width = label_right
  for row in rows {
    guard row.node.description is Some(description) else { continue }
    let w = match row.description {
      Some(label) => label.width
      None =>
        measurer.width(
          @text.decode_entities(description),
          size,
          @text.STYLE_ITALIC,
        )
    }
    width = @util.js_max(width, (if tight { row.label_x } else { desc_x }) + w)
  }
  width = @util.js_max(width, title.width)
  let inset = pad + (if any_highlight { HIGHLIGHT_OVERHANG } else { 0 })
  let top = pad + title_height
  let total_width = (width + 2 * inset).ceil()
  let total_height = (top + rows_height + pad).ceil()
  let guides = StringBuilder()
  for row in rows {
    let children = row.node.children
    if children.is_empty() {
      continue
    }
    let gx = inset + row.x + GUIDE_INSET
    let tick = @util.js_max(gx, inset + row.x + step - padding_x)
    let last = top + row_of[children[children.length() - 1].id].cy
    let r = @util.js_min(ELBOW, tick - gx)
    let d = StringBuilder()
    d.write_string(
      "M\{@svg.num(gx)},\{@svg.num(top + row.top + row.height - 2)}V\{@svg.num(last - r)}",
    )
    if r > 0 {
      d.write_string(
        "Q\{@svg.num(gx)},\{@svg.num(last)} \{@svg.num(gx + r)},\{@svg.num(last)}H\{@svg.num(tick)}",
      )
    }
    let mut i = 0
    while i < children.length() - 1 && tick > gx {
      d.write_string(
        "M\{@svg.num(gx)},\{@svg.num(top + row_of[children[i].id].cy)}H\{@svg.num(tick)}",
      )
      i += 1
    }
    guides.write_string("<path d=\"\{d.to_string()}\"/>")
  }
  let baseline = size * 0.35
  let body = StringBuilder()
  for row in rows {
    let node = row.node
    let cy = top + row.cy
    let directory = node.node_type is Directory
    let inner = StringBuilder()
    if row.highlighted {
      let x = inset + row.x - HIGHLIGHT_OVERHANG
      inner.write_string(
        "<rect class=\"pele-tree-highlight\" x=\"\{@svg.num(x)}\" y=\"\{@svg.num(top + row.top + 1)}\" width=\"\{@svg.num(total_width - inset + HIGHLIGHT_OVERHANG - x)}\" height=\"\{@svg.num(row.height - 2)}\" fill=\"var(--_c)\" fill-opacity=\"0.14\"\{@svg.ROUNDED}/>",
      )
    }
    if row.icon is Some(icon) {
      let name = if icon.has_prefix(BUILTIN_PACK + ":") {
        @util.slice(icon, BUILTIN_PACK.length() + 1)
      } else {
        ""
      }
      let outline = match glyph(name) {
        Some(outline) => outline
        None => glyph(if directory { "folder" } else { "file" }).unwrap()
      }
      inner.write_string(
        @common.icon_svg(
          icon,
          inset + row.x,
          cy - icon_size / 2,
          icon_size,
          drawing="<path d=\"\{outline}\" stroke=\"var(--_m)\" stroke-width=\"1.5\"/>",
        ),
      )
    }
    let weight = if directory { " font-weight=\"var(--_hw)\"" } else { "" }
    match row.label {
      Some(label) =>
        inner.write_string(
          @common.left_label_svg(
            label,
            inset + row.label_x,
            top + row.top + padding_y,
            " class=\"pele-label\"\{weight}",
          ),
        )
      None =>
        if row.text != "" {
          inner.write_string(
            "<text class=\"pele-label\" x=\"\{@svg.num(inset + row.label_x)}\" y=\"\{@svg.num(cy + baseline)}\"\{weight} xml:space=\"preserve\">\{@svg.esc(row.text)}</text>",
          )
        }
    }
    match (row.description, node.description) {
      (Some(label), _) =>
        inner.write_string(
          @common.left_label_svg(
            label,
            inset + row.label_x,
            top +
            row.top +
            padding_y +
            row.label.map(l => l.height).unwrap_or(0),
            " class=\"pele-tree-description\" font-style=\"italic\" fill=\"var(--_m)\"",
          ),
        )
      (None, Some(description)) =>
        inner.write_string(
          "<text class=\"pele-tree-description\" x=\"\{@svg.num(inset + desc_x)}\" y=\"\{@svg.num(cy + baseline)}\" font-style=\"italic\" fill=\"var(--_m)\" xml:space=\"preserve\">\{@svg.esc(@text.decode_entities(description))}</text>",
        )
      (None, None) => ()
    }
    body.write_string(
      "<g class=\"pele-node pele-tree-\{if directory { "dir" } else { "file" }}\{@svg.class_names(node.css_class.unwrap_or(""))}\" data-id=\"\{@svg.esc_text(node.name)}\">\{inner.to_string()}</g>",
    )
  }
  let guide_group = if guides.is_empty() {
    ""
  } else {
    "<g class=\"pele-tree-guides\" fill=\"none\" stroke=\"var(--_b)\" stroke-width=\"\{@svg.num(line_thickness)}\">\{guides.to_string()}</g>"
  }
  let content = @svg.label_svg(
      title,
      total_width / 2,
      pad + title.height / 2,
      " class=\"pele-title\" font-weight=\"var(--_tw)\"",
    ) +
    guide_group +
    body.to_string()
  {
    svg: @svg.svg_document(
      "treeView",
      total_width,
      total_height,
      size,
      options,
      model.acc_title,
      model.acc_descr,
      content,
    ),
    width: total_width,
    height: total_height,
    links: [],
  }
}
