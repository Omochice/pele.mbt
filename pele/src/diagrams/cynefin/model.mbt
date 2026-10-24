///|
/// A cynefin diagram ready to be drawn.
pub(all) struct CynefinModel {
  title : String?
  acc_title : String?
  acc_descr : String?
  /// The labels of the items of each domain the source declares, in declaration order.
  /// All five domains are drawn either way.
  domains : Map[String, Array[String]]
  transitions : Array[TransitionAst]
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
/// Keeps the blocks by domain, where a later block replaces an earlier one, and the transitions that are not self loops.
/// `title` is the front matter title, used when the diagram has none.
pub fn build_cynefin(ast : CynefinAst, title : String?) -> CynefinModel {
  let domains : Map[String, Array[String]] = Map([])
  for block in ast.domains {
    domains[block.domain] = block.items
  }
  let transitions = ast.transitions
    .filter(t => t.from != t.to)
    .map(t => { from: t.from, to: t.to, label: non_empty(t.label), })
  {
    title: match non_empty(ast.title) {
      Some(_) as own => own
      None => title
    },
    acc_title: non_empty(ast.acc_title).map(@util.trim_start),
    acc_descr: non_empty(ast.acc_descr).map(join_indented_lines),
    domains,
    transitions,
  }
}
