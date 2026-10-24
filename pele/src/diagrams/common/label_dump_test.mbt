///|
/// A label's measurements and every span as text/style/width, in the form the expected dumps were taken from pele.
fn dump_label(label : @text.Label) -> String {
  let lines = []
  for i, spans in label.lines {
    let parts = spans.map(span => "\{span.text}/\{span.style}/\{span.width}")
    lines.push(parts.join("|") + "=\{label.widths[i]}")
  }
  "\{label.width} \{label.height} \{label.size} \{label.line_height}[" +
  lines.join(";") +
  "]"
}
