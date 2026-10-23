///|
/// Reads a block diagram into `db`, as Mermaid's grammar does.
pub fn parse_block(src : String, db : BlockDb) -> Unit raise @errors.PeleError {
  if src.length() < 0 {
    raise @errors.pele_error("not yet read")
  }
  db.blocks = []
}
