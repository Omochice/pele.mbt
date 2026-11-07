///|
test "render passes every diagram type to core" {
  let kinds = diagrams.map(d => d.kind)
  inspect(
    kinds.join(" "),
    content=(
      #|agentflow architecture block c4 class cynefin er eventmodeling flowchart gantt gitGraph info ishikawa journey kanban mindmap packet pie quadrantChart radar railroad requirement sankey sequence state swimlane timeline treemap treeView usecase venn wardley xychart
    ),
  )
}
