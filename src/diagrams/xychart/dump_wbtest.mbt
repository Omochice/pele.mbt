///|
/// The tokens of a source, each as its name, its offset, and its text.
fn tokens(source : String) -> String {
  let found = tokenize(source)
  let parts = []
  for i, kind in found.types {
    parts.push("\{kind.name()}@\{found.starts[i]}\{found.texts[i].escape()}")
  }
  parts.join(" ")
}
