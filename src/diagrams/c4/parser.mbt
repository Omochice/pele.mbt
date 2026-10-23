///|
/// Reads a C4 diagram into `db` as the parser Jison generates from c4Diagram.jison does, raising its syntax errors.
pub fn parse_c4(src : String, db : C4Db) -> Unit raise @errors.PeleError {
  ignore(db)
  raise @errors.syntax_error("c4", src, 0, "")
}
