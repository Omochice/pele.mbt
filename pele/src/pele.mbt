///|
let diagrams : Array[@types.Diagram] = [
  @agentflow.agentflow, @architecture.architecture, @block.block, @c4.c4, @class.class,
  @cynefin.cynefin, @er.er, @eventmodeling.eventmodeling, @flowchart.flowchart, @gantt.gantt,
  @git.git, @info.info, @ishikawa.ishikawa, @journey.journey, @kanban.kanban, @mindmap.mindmap,
  @packet.packet, @pie.pie, @quadrant.quadrant, @radar.radar, @railroad.railroad,
  @requirement.requirement, @sankey.sankey, @sequence.sequence, @state.state, @swimlane.swimlane,
  @timeline.timeline, @treemap.treemap, @treeview.treeview, @usecase.usecase, @venn.venn,
  @wardley.wardley, @xychart.xychart,
]

///|
/// Renders Mermaid text to SVG, recognizing every diagram type the port supports.
/// `@core.render` renders with only the diagram types it is given, which keeps the other types out of a program.
/// Raises `PeleError` for text pele rejects.
pub fn render(
  source : String,
  options~ : @types.RenderOptions = @types.RenderOptions::default(),
) -> @types.RenderResult raise @errors.PeleError {
  @core.render(diagrams, source, options)
}
