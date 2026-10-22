///|
/// A domain block as written: the domain's name and the labels of its items.
pub(all) struct DomainBlockAst {
  domain : String
  items : Array[String]
}

///|
pub(all) struct TransitionAst {
  from : String
  to : String
  label : String?
}

///|
/// The statements of a cynefin diagram, as Mermaid's grammar reads them.
pub(all) struct CynefinAst {
  title : String?
  acc_title : String?
  acc_descr : String?
  domains : Array[DomainBlockAst]
  transitions : Array[TransitionAst]
}

///|
/// Reads a cynefin diagram. Raises a syntax `PeleError` with Mermaid's message on invalid text.
pub fn parse_cynefin(source : String) -> CynefinAst raise @errors.PeleError {
  ignore(@common.title)
  ignore(source)
  abort("not implemented")
}
