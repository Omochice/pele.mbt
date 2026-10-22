///|
/// A row of a treemap that names a section or a leaf.
pub(all) enum ItemAst {
  /// A name, and the class applied with `:::`.
  Section(String, String?)
  /// A name, a value, and the class applied with `:::`.
  Leaf(String, Double, String?)
}

///|
/// A line of a treemap, with the width of the whitespace before it when there is some.
pub(all) enum RowAst {
  Item(Int32?, ItemAst)
  /// A class name and the text of its declarations.
  ClassDef(Int32?, String, String?)
}

///|
/// The statements of a treemap, as Mermaid's grammar reads them.
pub(all) struct TreemapAst {
  title : String?
  acc_title : String?
  acc_descr : String?
  rows : Array[RowAst]
}

///|
fn read_selector(r : @common.TokenReader) -> String? raise @errors.PeleError {
  if r.accept(STYLE_SEPARATOR) {
    Some(r.expect(ID))
  } else {
    None
  }
}

///|
/// Reads a treemap. Raises a syntax `PeleError` with Mermaid's message on invalid text.
pub fn parse_treemap(source : String) -> TreemapAst raise @errors.PeleError {
  let r = @common.TokenReader::new(
    @common.tokenize(source, treemap_tokens, "treemap"),
    treemap_tokens,
    "treemap",
  )
  let kinds = r.tokens.kinds
  let mut title = None
  let mut acc_title = None
  let mut acc_descr = None
  let rows = []
  r.expect(KEYWORD) |> ignore
  while r.kind() != -1 {
    let kind = r.kind()
    if kind == ACC_DESCR {
      acc_descr = Some(@common.acc_descr_value(r.take()))
      continue
    }
    if kind == ACC_TITLE {
      acc_title = Some(@common.acc_title_value(r.take()))
      continue
    }
    if kind == TITLE {
      title = Some(@common.title_value(r.take()))
      continue
    }
    if kind != INDENTATION && kind != STRING && kind != CLASS_DEF {
      r.fail("a node, a class definition, or a title")
    }
    let indent = if kind == INDENTATION {
      Some(r.take().length())
    } else {
      None
    }
    if r.kind() == CLASS_DEF {
      let text = r.take()
      // The token was matched by the same scan, so it matches again.
      let span = scan_class_def(text, 0).unwrap()
      let style = if span.style_end > span.style_start && span.style_start >= 0 {
        Some(@util.slice(text, span.style_start, end=span.style_end))
      } else {
        None
      }
      rows.push(
        ClassDef(
          indent,
          @util.slice(text, span.name_start, end=span.name_end),
          style,
        ),
      )
      continue
    }
    let name = r.expect(STRING)
    let name = @util.slice(name, 1, end=name.length() - 1)
    // A leaf is a name followed by a colon or comma, with or without whitespace before it.
    let after = if kinds[r.i] == INDENTATION { r.i + 1 } else { r.i }
    let item = if kinds[after] == SEPARATOR || kinds[after] == COMMA {
      r.i = after + 1
      r.accept(INDENTATION) |> ignore
      let value = @util.parse_float(
        r.expect(NUMBER).replace_all(old=",", new=""),
      )
      Leaf(name, value, read_selector(r))
    } else {
      Section(name, read_selector(r))
    }
    rows.push(Item(indent, item))
  }
  { title, acc_title, acc_descr, rows, }
}
