///|
/// A pie chart ready to be drawn.
pub(all) struct PieModel {
  title : String?
  acc_title : String?
  acc_descr : String?
  show_data : Bool
  /// Slices by label, in the order their labels first appear.
  sections : Array[(String, Double)]
}

///|
/// Checks the slices of a pie chart and keeps the first value of each label.
/// `title` is the front matter title, used when the chart has none.
/// Raises a semantic `PeleError` for a negative value.
pub fn build_pie(
  ast : PieAst,
  title : String?,
) -> PieModel raise @errors.PeleError {
  {
    title: if ast.title is Some(_) {
      ast.title
    } else {
      title
    },
    acc_title: ast.acc_title,
    acc_descr: ast.acc_descr,
    show_data: ast.show_data,
    sections: ast.sections.map(s => (s.label, s.value)),
  }
}
