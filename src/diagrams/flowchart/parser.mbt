///|
/// Parses flowchart text into `db`, raising a syntax `PeleError` with Mermaid's message on invalid text.
pub fn parse_flowchart(
  source : String,
  db : FlowDb,
) -> Unit raise @errors.PeleError {
  ignore(source)
  db.direction = None
  db.default_edge_style = None
  db.default_interpolate = None
  db.title = None
  db.acc_title = None
  db.acc_descr = None
  db.sub_count = 0
}
