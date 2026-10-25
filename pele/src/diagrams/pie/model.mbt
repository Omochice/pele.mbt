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
fn non_empty(value : String?) -> String? {
  match value {
    Some("") => None
    _ => value
  }
}

///|
/// Does what `text.replace(/\n\s+/g, '\n')` does.
fn join_indented_lines(text : String) -> String {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    @util.write_range(out, text, i, i + 1)
    if @util.code_at(text, i) == '\n'.to_int() &&
      @util.is_space(@util.code_at(text, i + 1)) {
      i += 1
      while @util.is_space(@util.code_at(text, i)) {
        i += 1
      }
    } else {
      i += 1
    }
  }
  out.to_string()
}

///|
/// Checks the slices of a pie chart and keeps the first value of each label.
/// `title` is the front matter title, used when the chart has none.
/// Raises a semantic `PeleError` for a negative value.
pub fn build_pie(
  ast : PieAst,
  title : String?,
) -> PieModel raise @errors.PeleError {
  let seen : Set[String] = Set([])
  let sections = []
  for section in ast.sections {
    if section.value < 0 {
      raise @errors.pele_error(
        "\"\{@text.decode_entities(section.label)}\" has invalid value: \{section.value}. Negative values are not allowed in pie charts. All slice values must be >= 0.",
        code=Semantic,
        kind="pie",
      )
    }
    if !seen.contains(section.label) {
      seen.add(section.label)
      sections.push((section.label, section.value))
    }
  }
  {
    title: match non_empty(ast.title) {
      Some(_) as own => own
      None => title
    },
    acc_title: non_empty(ast.acc_title).map(@util.trim_start),
    acc_descr: non_empty(ast.acc_descr).map(join_indented_lines),
    show_data: ast.show_data,
    sections,
  }
}
