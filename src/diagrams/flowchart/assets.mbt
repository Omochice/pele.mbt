///|
/// Whether the node shows a picture or an icon in place of a shape.
fn has_asset(node : GraphNode) -> Bool {
  is_set(node.img) || is_set(node.icon)
}

///|
fn asset_size(value : Double?, fallback : Double) -> Double {
  match value {
    Some(size) if size > 0 && size <= 4000 => size
    _ => fallback
  }
}

///|
/// The top of a picture or an icon `box` high: above or below the label, or centered without one.
fn asset_top(node : GraphNode, view : NodeView, box : Double) -> Double {
  if view.label.height == 0 {
    -box / 2
  } else if node.pos is Some("t") {
    view.h / 2 - box
  } else {
    -view.h / 2
  }
}

///|
/// Writes the picture of a node, with its URL escaped a piece at a time.
fn write_picture(
  out : @svg.Markup,
  node : GraphNode,
  img : String,
  view : NodeView,
  options : @types.RenderOptions,
) -> Unit raise @errors.PeleError {
  guard @url.image_url(@url.safe_url(img), options) is Some(src) else { return }
  let aw = asset_size(node.asset_width, 80)
  let ah = asset_size(node.asset_height, 80)
  let fit = if node.constraint is Some("on") { "xMidYMid meet" } else { "none" }
  out.write("<image href=\"")
  @svg.write_esc(out, src)
  out.write(
    "\" x=\"\{@svg.num(-aw / 2)}\" y=\"\{@svg.num(asset_top(node, view, ah))}\" width=\"\{@svg.num(aw)}\" height=\"\{@svg.num(ah)}\" preserveAspectRatio=\"\{fit}\"/>",
  )
}

///|
/// Writes the icon of a node in its frame, with its name escaped a piece at a time.
fn write_icon(
  out : @svg.Markup,
  node : GraphNode,
  icon : String,
  view : NodeView,
  icons : @types.IconResolver?,
) -> Unit raise @errors.PeleError {
  let box = asset_size(node.asset_height, 48)
  let top = asset_top(node, view, box)
  match node.shape {
    "icon" => ()
    "iconCircle" =>
      out.write(
        "<circle cy=\"\{@svg.num(top + box / 2)}\" r=\"\{@svg.num(box / 2)}\"\{SHAPE_ATTRS}\{view.style.shape}/>",
      )
    shape => {
      let rx = if shape == "iconRounded" { 8 } else { 0 }
      out.write(
        "<rect x=\"\{@svg.num(-box / 2)}\" y=\"\{@svg.num(top)}\" width=\"\{@svg.num(box)}\" height=\"\{@svg.num(box)}\" rx=\"\{rx}\"\{SHAPE_ATTRS}\{view.style.shape}/>",
      )
    }
  }
  let glyph = box * 0.6
  @common.write_icon(
    out,
    icon,
    -glyph / 2,
    top + (box - glyph) / 2,
    glyph,
    icons?,
  )
}
