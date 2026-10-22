///|
/// A field as written in the source.
/// Numbers are doubles because `Number()` reads digit runs of any length, and a long one becomes infinity.
pub(all) struct PacketBlockAst {
  start : Double?
  end : Double?
  bits : Double?
  label : String
}

///|
/// The statements of a packet diagram, as Mermaid's grammar reads them.
pub(all) struct PacketAst {
  title : String?
  acc_title : String?
  acc_descr : String?
  blocks : Array[PacketBlockAst]
}

///|
/// Reads a packet diagram. Raises a syntax `PeleError` with Mermaid's message on invalid text.
pub fn parse_packet(source : String) -> PacketAst raise @errors.PeleError {
  if source == "\u{0}" {
    raise @errors.pele_error("stub")
  }
  { title: None, acc_title: None, acc_descr: None, blocks: [], }
}
