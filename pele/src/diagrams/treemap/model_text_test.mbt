///|
fn model_of(source : String, title : String?) -> @treemap.TreemapModel {
  let ast = @treemap.parse_treemap(source + "\n") catch {
    @errors.PeleError(_) => panic()
  }
  @treemap.build_treemap(ast, title)
}

///|
fn shown(text : String?) -> String {
  match text {
    Some(value) => value.escape()
    None => "none"
  }
}

///|
test "the treemap's own title wins over the front matter title" {
  inspect(
    shown(model_of("treemap title Own", Some("front")).title),
    content="\"Own\"",
  )
}

///|
test "the front matter title is used when the treemap has none or an empty one" {
  inspect(shown(model_of("treemap", Some("front")).title), content="\"front\"")
  inspect(
    shown(model_of("treemap\ntitle\n", Some("front")).title),
    content="\"front\"",
  )
  inspect(shown(model_of("treemap", None).title), content="none")
}

///|
test "accessibility text is kept, and an empty one is dropped" {
  let model = model_of("treemap\naccTitle: Name\naccDescr: Text", None)
  inspect(shown(model.acc_title), content="\"Name\"")
  inspect(shown(model.acc_descr), content="\"Text\"")
  let bare = model_of("treemap\naccTitle:\naccDescr:", None)
  inspect(shown(bare.acc_title), content="none")
  inspect(shown(bare.acc_descr), content="none")
}

///|
test "the indentation of an accessible description's lines is removed" {
  let ast : @treemap.TreemapAst = {
    title: None,
    acc_title: Some("  Name"),
    acc_descr: Some("one\n   two\n\tthree"),
    rows: [],
  }
  let model = @treemap.build_treemap(ast, None)
  inspect(shown(model.acc_title), content="\"Name\"")
  inspect(shown(model.acc_descr), content="\"one\\ntwo\\nthree\"")
}
