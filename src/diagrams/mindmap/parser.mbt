///|
/// Parses a mindmap.
/// `title` is the front matter title.
/// Raises a semantic `PeleError` for a second root and a syntax one for text the grammar rejects.
pub fn parse_mindmap(
  source : String,
  title : String?,
) -> MindmapModel raise @errors.PeleError {
  let db = MindmapDb::new()
  @common.parse_outline(source, db, false)
  { title, nodes: db.nodes, }
}
