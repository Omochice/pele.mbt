///|
let default_lane = "__swimlane_default__"

///|
/// Nodes outside every lane share one unnamed lane, as in Mermaid.
/// Lanes all run the same way, so a `direction` inside a subgraph has no effect.
fn prepare(graph : @flowchart.FlowGraph) -> Unit {
  let mut loose = false
  for i, node in graph.nodes {
    if node.is_group {
      graph.nodes[i] = { ..node, dir: None, }
    } else if node.parent_id is None {
      loose = true
    }
  }
  if !loose {
    return
  }
  for i, node in graph.nodes {
    if !node.is_group && node.parent_id is None {
      graph.nodes[i] = { ..node, parent_id: Some(default_lane), }
    }
  }
  graph.nodes.push({
    id: default_lane,
    label: None,
    label_type: Text,
    shape: "rect",
    is_group: true,
    parent_id: None,
    css_styles: [],
    css_compiled_styles: [],
    css_classes: "",
    dir: None,
    link: None,
    link_target: None,
    tooltip: None,
    icon: None,
    pos: None,
    img: None,
    asset_width: None,
    asset_height: None,
    constraint: None,
    color_index: None,
    metadata: None,
  })
}

///|
/// A lane: an outline the length of the diagram, with its title in a band at the start.
fn draw_lane(
  out : @svg.Markup,
  c : @layout.CNode,
  label : @text.Label,
  style : @svg.ResolvedStyle,
  classes : String,
  id : String,
  dir : @layout.Dir,
  icons : @types.IconResolver?,
) -> Unit raise @errors.PeleError {
  let left = c.x - c.w / 2
  let top = c.y - c.h / 2
  let sideways = dir is (LR | RL)
  let cx = if sideways { left + c.pad_top / 2 } else { c.x }
  let cy = if sideways { c.y } else { top + c.pad_top / 2 }
  let text = @svg.Markup::new()
  @svg.write_label(
    text,
    label,
    cx,
    cy,
    " class=\"pele-cluster-label\"\{@svg.ink_fill(style, fallback="var(--_m)")}\{style.text}",
    icons?,
  )
  let band_w = if sideways { c.pad_top } else { c.w }
  let band_h = if sideways { c.h } else { c.pad_top }
  out.write("<g class=\"pele-cluster pele-lane\{classes}\"")
  out.write_data_id(id)
  out.write(
    "><rect x=\"\{@svg.num(left)}\" y=\"\{@svg.num(top)}\" width=\"\{@svg.num(c.w)}\" height=\"\{@svg.num(c.h)}\" fill=\"none\" stroke=\"var(--_b)\"/>" +
    "<rect x=\"\{@svg.num(left)}\" y=\"\{@svg.num(top)}\" width=\"\{@svg.num(band_w)}\" height=\"\{@svg.num(band_h)}\" fill=\"var(--_a)\" stroke=\"var(--_b)\"\{style.shape}/>",
  )
  if sideways && !text.is_empty() {
    out.write_group(
      "<g transform=\"rotate(-90 \{@svg.num(cx)} \{@svg.num(cy)})\">",
      text,
      "</g>",
    )
  } else {
    out.write_markup(text)
  }
  out.write("</g>")
}

///|
/// The band at the start of a lane that holds its title, which is the part a style fills.
fn lane_band(c : @layout.CNode, dir : @layout.Dir) -> Array[Double] {
  let left = c.x - c.w / 2
  let top = c.y - c.h / 2
  if dir is (LR | RL) {
    [left, top, left + c.pad_top, top + c.h]
  } else {
    [left, top, left + c.w, top + c.pad_top]
  }
}

///|
let variant : @flowchart.FlowVariant = {
  kind: "swimlane",
  prepare,
  layout: (nodes, edges, dir, options, tight) => {
    @layout.lane_layout(
      nodes,
      edges,
      dir,
      options,
      lane_pad?=if tight { Some(12) } else { None },
    )
  },
  draw_group: Some(draw_lane),
  filled_box: Some(lane_band),
}

///|
/// Draws a swimlane diagram as a flowchart whose top-level groups are lanes.
pub fn render_swimlane(
  db : @flowchart.FlowDb,
  config : @types.Config,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  @flowchart.render_flowchart(db, config, options, variant~)
}
