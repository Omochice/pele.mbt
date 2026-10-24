///|
/// The model in the form pele's test helper prints it, so expectations can be taken from pele.
fn dump_model(db : @block.BlockDb) -> String {
  let out = ["root columns=\{db.root.columns}"]
  fn walk(list : Array[@block.Block], depth : Int32) {
    for b in list {
      let line = StringBuilder()
      line.write_string("  ".repeat(depth))
      line.write_string("\{b.id} \{b.kind} \"\{b.label}\"")
      if b.width_in_columns is Some(span) {
        line.write_string(" span=\{span}")
      }
      if b.kind == "space" {
        line.write_string(" width=\{b.width}")
      }
      if b.columns != -1 {
        line.write_string(" columns=\{b.columns}")
      }
      if b.classes.length() > 0 {
        line.write_string(" classes=\{b.classes.join(",")}")
      }
      if b.styles.length() > 0 {
        line.write_string(" styles=\{b.styles.join("|")}")
      }
      if b.directions.length() > 0 {
        line.write_string(" dirs=\{b.directions.join("|")}")
      }
      if b.color_index is Some(index) {
        line.write_string(" color=\{index}")
      }
      out.push(line.to_string())
      walk(b.children, depth + 1)
    }
  }

  walk(db.root.children, 1)
  for e in db.edges {
    let dirs = if e.directions.length() > 0 {
      " dirs=" + e.directions.join("|")
    } else {
      ""
    }
    out.push(
      "edge \{e.id} \{e.start}->\{e.end} \"\{e.label}\" \{e.arrow_type_start} \{e.arrow_type_end} \{e.thickness} \{e.pattern}\{dirs}",
    )
  }
  for _, c in db.classes {
    out.push(
      "class \{c.id} styles=[\{c.styles.join("|")}] text=[\{c.text_styles.join("|")}]",
    )
  }
  out.join("\n")
}
