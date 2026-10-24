///|
fn family(list : String?) -> String {
  let style = @svg.font_style(16, list, list)
  let at = style.find("font-family:").unwrap_or(0)
  style.view(start_offset=at).to_owned()
}

///|
test "the font style pins what text inherits" {
  inspect(
    @svg.font_style(16, None, None),
    content=";--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)",
  )
}

///|
test "font lists are kept when they cannot end the declaration" {
  inspect(
    family(Some("\"Noto Sans JP\", ヒラギノ角ゴ, sans-serif")),
    content="font-family:var(--pele-font,\"Noto Sans JP\", ヒラギノ角ゴ, sans-serif)",
  )
  inspect(
    family(Some("'Single', x")),
    content="font-family:var(--pele-font,'Single', x)",
  )
  inspect(
    family(Some("  Arial  ,  Helvetica  ")),
    content="font-family:var(--pele-font,  Arial  ,  Helvetica  )",
  )
  inspect(family(Some("-x")), content="font-family:var(--pele-font,-x)")
  inspect(
    family(Some("①font")),
    content="font-family:var(--pele-font,①font)",
  )
  inspect(family(Some("a١b")), content="font-family:var(--pele-font,a١b)")
}

///|
test "other font lists fall back to the generic family" {
  inspect(
    family(Some("Arial; color: red")),
    content="font-family:var(--pele-font,sans-serif)",
  )
  inspect(
    family(Some("Ari\tal")),
    content="font-family:var(--pele-font,sans-serif)",
  )
  inspect(family(Some(".x")), content="font-family:var(--pele-font,sans-serif)")
  inspect(
    family(Some("\u{1f600}font")),
    content="font-family:var(--pele-font,sans-serif)",
  )
  inspect(
    family(Some("a\u{1f600}")),
    content="font-family:var(--pele-font,sans-serif)",
  )
}

///|
test "series colors cycle through eight tokens" {
  inspect(@svg.series_color(0), content="var(--pele-series-1,#4c78a8)")
  inspect(@svg.series_color(7), content="var(--pele-series-8,#9d755d)")
  inspect(@svg.series_color(8), content="var(--pele-series-1,#4c78a8)")
  inspect(@svg.series_color(9), content="var(--pele-series-2,#f58518)")
  inspect(@svg.series_color(-1), content="var(--pele-series-8,#9d755d)")
}

///|
test "rounded corners are appended when there is no style attribute" {
  inspect(@svg.rounded(""), content=" style=\"rx:var(--_r)\"")
  inspect(
    @svg.rounded(" fill=\"red\""),
    content=" fill=\"red\" style=\"rx:var(--_r)\"",
  )
  inspect(@svg.ROUNDED, content=" style=\"rx:var(--_r)\"")
}

///|
test "rounded corners come first in an existing style so it can override them" {
  inspect(
    @svg.rounded(" fill=\"red\" style=\"rx:2px;\" stroke=\"x\""),
    content=" fill=\"red\" style=\"rx:var(--_r);rx:2px;\" stroke=\"x\"",
  )
  inspect(
    @svg.rounded(" data-style=\"a\" style=\"b\""),
    content=" data-style=\"a\" style=\"rx:var(--_r);b\"",
  )
}

///|
test "class names keep word characters and hyphens, one space apart" {
  inspect(@svg.class_names(""), content="")
  inspect(@svg.class_names("  "), content="")
  inspect(@svg.class_names("warn"), content=" warn")
  inspect(@svg.class_names(" a  b-c\tx_y "), content=" a b-c x_y")
  inspect(@svg.class_names("a\"><tag>b"), content=" a tag b")
  inspect(@svg.class_names("ä.b"), content=" b")
}

///|
test "node class names leave out the default class every node carries first" {
  inspect(@svg.node_class_names("default"), content="")
  inspect(@svg.node_class_names("default hot cold"), content=" hot cold")
  inspect(@svg.node_class_names("default\thot"), content=" hot")
  inspect(@svg.node_class_names("defaulted"), content=" ed")
  inspect(@svg.node_class_names("hot default"), content=" hot default")
}
