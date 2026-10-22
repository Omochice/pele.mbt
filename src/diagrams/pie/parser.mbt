///|
/// A slice as written in the source.
pub(all) struct PieSection {
  label : String
  value : Double
}

///|
/// The statements of a pie chart, as Mermaid's grammar reads them.
pub(all) struct PieAst {
  show_data : Bool
  title : String?
  acc_title : String?
  acc_descr : String?
  sections : Array[PieSection]
}

///|
/// Reads a pie chart. Raises a syntax `PeleError` with Mermaid's message on invalid text.
pub fn parse_pie(source : String) -> PieAst raise @errors.PeleError {
  ignore(source)
  {
    show_data: false,
    title: None,
    acc_title: None,
    acc_descr: None,
    sections: [],
  }
}
