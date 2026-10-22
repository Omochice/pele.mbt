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
fn picture(
  node : GraphNode,
  img : String,
  view : NodeView,
  options : @types.RenderOptions,
) -> String {
  guard @url.image_url(@url.safe_url(img), options) is Some(src) else {
    return ""
  }
  let aw = asset_size(node.asset_width, 80)
  let ah = asset_size(node.asset_height, 80)
  let fit = if node.constraint is Some("on") { "xMidYMid meet" } else { "none" }
  "<image href=\"\{@svg.esc(src)}\" x=\"\{@svg.num(-aw / 2)}\" y=\"\{@svg.num(asset_top(node, view, ah))}\" width=\"\{@svg.num(aw)}\" height=\"\{@svg.num(ah)}\" preserveAspectRatio=\"\{fit}\"/>"
}

///|
fn icon_svg(node : GraphNode, icon : String, view : NodeView) -> String {
  let box = asset_size(node.asset_height, 48)
  let top = asset_top(node, view, box)
  let frame = match node.shape {
    "icon" => ""
    "iconCircle" =>
      "<circle cy=\"\{@svg.num(top + box / 2)}\" r=\"\{@svg.num(box / 2)}\"\{SHAPE_ATTRS}\{view.style.shape}/>"
    shape => {
      let rx = if shape == "iconRounded" { 8 } else { 0 }
      "<rect x=\"\{@svg.num(-box / 2)}\" y=\"\{@svg.num(top)}\" width=\"\{@svg.num(box)}\" height=\"\{@svg.num(box)}\" rx=\"\{rx}\"\{SHAPE_ATTRS}\{view.style.shape}/>"
    }
  }
  let glyph = box * 0.6
  // The plugin has no icon resolver to ask, so the glyph stays empty as it does in pele without one.
  frame +
  "<svg class=\"pele-icon\" data-icon=\"\{@svg.esc_text(icon)}\" x=\"\{@svg.num(-glyph / 2)}\" y=\"\{@svg.num(top + (box - glyph) / 2)}\" width=\"\{@svg.num(glyph)}\" height=\"\{@svg.num(glyph)}\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"></svg>"
}
