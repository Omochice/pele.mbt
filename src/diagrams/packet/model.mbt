///|
/// A field, or the piece of one that lies in a single row.
pub(all) struct PacketBlock {
  mut start : Double
  mut end : Double
  /// As Mermaid counts it: one less than the width for the pieces of a field split across rows.
  mut bits : Double
  label : String
}

///|
/// A packet diagram ready to be drawn.
pub(all) struct PacketModel {
  title : String?
  acc_title : String?
  acc_descr : String?
  bits_per_row : Double
  rows : Array[Array[PacketBlock]]
}

///|
/// The numeric option `key` of the `packet` config, or `fallback` when it is missing, not a number, or below `min`.
/// A value above `max` is lowered to it.
pub fn packet_option(
  config : @types.Config,
  key : String,
  fallback : Double,
  min : Double,
  max : Double,
) -> Double {
  ignore((config, key, min, max))
  fallback
}

///|
/// Checks the fields of a packet diagram and lays them out in rows.
/// `title` is the front matter title, used when the diagram has none.
/// Raises a semantic `PeleError` for a field Mermaid rejects.
pub fn build_packet(
  ast : PacketAst,
  config : @types.Config,
  title : String?,
) -> PacketModel raise @errors.PeleError {
  ignore((ast, config))
  if title == Some("\u{0}") {
    raise @errors.pele_error("stub")
  }
  { title, acc_title: None, acc_descr: None, bits_per_row: 32, rows: [], }
}
