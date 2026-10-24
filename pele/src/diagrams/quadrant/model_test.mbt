///|
fn optional(value : String?) -> String {
  match value {
    Some(text) => text.escape()
    None => "-"
  }
}

///|
fn label(text : @quadrant.QuadrantText?) -> String {
  match text {
    Some({ text, markdown, }) =>
      "\{text.escape()}\{if markdown { "(md)" } else { "" }}"
    None => "-"
  }
}

///|
fn style(style : @quadrant.PointStyle) -> String {
  let parts = []
  if style.radius is Some(radius) {
    parts.push("radius=\{radius}")
  }
  if style.color is Some(color) {
    parts.push("color=\{color}")
  }
  if style.stroke_color is Some(color) {
    parts.push("stroke-color=\{color}")
  }
  if style.stroke_width is Some(width) {
    parts.push("stroke-width=\{width}")
  }
  parts.join(" ")
}

///|
fn styles(source : Array[String]) -> String {
  let parsed = @quadrant.parse_styles(source) catch {
    @errors.PeleError(failure) =>
      return "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")}"
  }
  "{\{style(parsed)}}"
}

///|
test "styles are read into a style object" {
  inspect(
    styles([
      "radius: 10", "color: #ff0000", "stroke-color: #ff00ff", "stroke-width: 10px",
    ]),
    content="{radius=10 color=#ff0000 stroke-color=#ff00ff stroke-width=10px}",
  )
}

///|
test "no styles make an empty style object" {
  inspect(styles([]), content="{}")
}

///|
test "a style that is not supported is rejected by name" {
  inspect(
    styles(["test_name: value"]),
    content="semantic: style named test_name is not supported. quadrantChart",
  )
  inspect(
    styles(["fill: #fff"]),
    content="semantic: style named fill is not supported. quadrantChart",
  )
}

///|
test "a value Mermaid rejects is reported with its kind" {
  inspect(
    styles(["radius: f"]),
    content="semantic: value for radius f is invalid, please use a valid number quadrantChart",
  )
  inspect(
    styles(["color: ffaa"]),
    content="semantic: value for color ffaa is invalid, please use a valid hex code quadrantChart",
  )
  inspect(
    styles(["stroke-color: #f677779"]),
    content="semantic: value for stroke-color #f677779 is invalid, please use a valid hex code quadrantChart",
  )
  inspect(
    styles(["stroke-width: 30"]),
    content="semantic: value for stroke-width 30 is invalid, please use a valid number of pixels (eg. 10px) quadrantChart",
  )
}

///|
test "a hex code has three or six digits and an optional hash" {
  inspect(styles(["color: abc"]), content="{color=abc}")
  inspect(styles(["color: #ABCDEF"]), content="{color=#ABCDEF}")
  inspect(
    styles(["color: #abcd"]),
    content="semantic: value for color #abcd is invalid, please use a valid hex code quadrantChart",
  )
  inspect(
    styles(["color: #"]),
    content="semantic: value for color # is invalid, please use a valid hex code quadrantChart",
  )
  inspect(
    styles(["color: ##abc"]),
    content="semantic: value for color ##abc is invalid, please use a valid hex code quadrantChart",
  )
}

///|
test "a radius is an unsigned whole number" {
  inspect(styles(["radius: 007"]), content="{radius=7}")
  inspect(
    styles(["radius: 1.5"]),
    content="semantic: value for radius 1.5 is invalid, please use a valid number quadrantChart",
  )
  inspect(
    styles(["radius: -1"]),
    content="semantic: value for radius -1 is invalid, please use a valid number quadrantChart",
  )
}

///|
test "a radius of hundreds of digits is read as infinity" {
  inspect(styles(["radius: " + "9".repeat(400)]), content="{radius=Infinity}")
}

///|
test "a style is split at its first colon and cut at its second" {
  inspect(styles(["  radius  :   5 : 6 "]), content="{radius=5}")
  inspect(styles(["stroke-width\t:\n3px"]), content="{stroke-width=3px}")
}

///|
test "a style without a colon has the value undefined" {
  inspect(
    styles(["radius"]),
    content="semantic: value for radius undefined is invalid, please use a valid number quadrantChart",
  )
}

///|
test "the last style of a kind wins" {
  inspect(styles(["radius: 1", "radius: 2"]), content="{radius=2}")
}

///|
fn dump(db : @quadrant.QuadrantDb) -> String {
  let points = db.points.map(p => {
    "\{p.text.text.escape()}:\{p.class_name.escape()}:\{p.x}:\{p.y}:{\{style(p.style)}}"
  })
  let classes = db.classes.iter().map(pair => "\{pair.0}={\{style(pair.1)}}")
  "title=\{optional(db.title)} accTitle=\{optional(db.acc_title)} accDescr=\{optional(db.acc_descr)} quadrants=\{db.quadrants.map(label).join(",")} x=\{label(db.x_axis_left)}|\{label(db.x_axis_right)} y=\{label(db.y_axis_bottom)}|\{label(db.y_axis_top)} points=\{points.join(",")} classes=\{classes.collect().join(",")}"
}

///|
test "a new chart has nothing but the front matter title" {
  inspect(
    dump(@quadrant.QuadrantDb::new(Some("front"))),
    content="title=\"front\" accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
}

///|
test "labels are trimmed and keep how they were written" {
  let db = @quadrant.QuadrantDb::new(None)
  db.set_quadrant_text(1, { text: "  one ", markdown: false, })
  db.set_quadrant_text(2, { text: "two", markdown: true, })
  db.set_quadrant_text(3, { text: "three\t", markdown: false, })
  db.set_quadrant_text(4, { text: " four", markdown: false, })
  db.set_x_axis_left_text({ text: " l ", markdown: false, })
  db.set_x_axis_right_text({ text: " r ", markdown: false, })
  db.set_y_axis_bottom_text({ text: " b ", markdown: false, })
  db.set_y_axis_top_text({ text: " t ", markdown: true, })
  inspect(
    dump(db),
    content="title=- accTitle=- accDescr=- quadrants=\"one\",\"two\"(md),\"three\",\"four\" x=\"l\"|\"r\" y=\"b\"|\"t\"(md) points= classes=",
  )
}

///|
test "a point reads its coordinates as JavaScript numbers do" {
  let db = @quadrant.QuadrantDb::new(None)
  db.add_point({ text: " A ", markdown: false, }, "", "0.25", "1", [])
  db.add_point({ text: "B", markdown: false, }, "k", "0x5", "0e9", [])
  db.add_point({ text: "C", markdown: false, }, "", "0,5", "055", [])
  inspect(
    dump(db),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"A\":\"\":0.25:1:{},\"B\":\"k\":5:0:{},\"C\":\"\":NaN:55:{} classes=",
  )
}

///|
test "a point keeps the styles it was given" {
  let db = @quadrant.QuadrantDb::new(None)
  db.add_point({ text: "A", markdown: false, }, "", "0.1", "0.2", [
    "color: #ABC", "radius: 3",
  ])
  inspect(
    dump(db),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points=\"A\":\"\":0.1:0.2:{radius=3 color=#ABC} classes=",
  )
}

///|
test "a point with an invalid style is rejected" {
  let db = @quadrant.QuadrantDb::new(None)
  let message = try {
    db.add_point({ text: "A", markdown: false, }, "", "0.1", "0.2", [
      "radius: x",
    ])
    "accepted"
  } catch {
    @errors.PeleError(failure) => failure.message
  }
  inspect(
    message,
    content="value for radius x is invalid, please use a valid number",
  )
  inspect(db.points.length(), content="0")
}

///|
test "a class defined again replaces its styles and keeps its place" {
  let db = @quadrant.QuadrantDb::new(None)
  db.add_class("k", ["color: #fff"])
  db.add_class("j", ["radius: 1"])
  db.add_class("k", ["radius: 2"])
  inspect(
    dump(db),
    content="title=- accTitle=- accDescr=- quadrants=-,-,-,- x=-|- y=-|- points= classes=k={radius=2},j={radius=1}",
  )
}

///|
test "a class with an invalid style is rejected" {
  let db = @quadrant.QuadrantDb::new(None)
  let message = try {
    db.add_class("k", ["fill: #fff"])
    "accepted"
  } catch {
    @errors.PeleError(failure) => failure.message
  }
  inspect(message, content="style named fill is not supported.")
}

///|
test "the title and the accessibility texts are set as Mermaid sets them" {
  let db = @quadrant.QuadrantDb::new(Some("front"))
  db.set_diagram_title("own")
  db.set_acc_title("  a title  ")
  db.set_acc_description("one\n   two\n\t three")
  inspect(
    dump(db),
    content="title=\"own\" accTitle=\"a title  \" accDescr=\"one\\ntwo\\nthree\" quadrants=-,-,-,- x=-|- y=-|- points= classes=",
  )
}

///|
test "an empty chart title replaces the front matter title" {
  let db = @quadrant.QuadrantDb::new(Some("front"))
  db.set_diagram_title("")
  inspect(optional(db.title), content="\"\"")
}
