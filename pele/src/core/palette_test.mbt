///|
let palette_diagrams : Array[@types.Diagram] = [
  @flowchart.flowchart, @git.git, @journey.journey, @mindmap.mindmap, @pie.pie, @radar.radar,
  @timeline.timeline, @treemap.treemap, @venn.venn, @xychart.xychart,
]

///|
fn palette_svg(
  source : String,
  config? : @types.Config,
) -> String raise @errors.PeleError {
  @core.render(palette_diagrams, source, {
    ..@types.RenderOptions::default(),
    config,
  }).svg
}

///|
fn themed(vars : Json, body : String) -> String {
  let directive : Json = { "themeVariables": vars }
  "%%{init: \{directive.stringify()}}%%\n\{body}"
}

///|
/// The `--pele-series-N` declarations of the root element's style, as `N:color` pairs.
fn series_of(svg : String) -> String {
  let open = "style=\""
  let start = svg.find(open).unwrap() + open.length()
  let style = @util.slice(svg, start, end=@util.index_of(svg, "\"", from=start))
  let found = []
  for declaration in style.split(";") {
    let declaration = declaration.to_owned()
    if declaration.has_prefix("--pele-series-") {
      found.push(@util.slice(declaration, "--pele-series-".length()))
    }
  }
  found.join(" ")
}

///|
const PIE : String = "pie\n  \"A\": 1\n  \"B\": 2"

///|
const XYCHART : String = "xychart\n  bar [1, 2]\n  line [2, 1]"

///|
test "xychart series take their colors from plotColorPalette, repeating a short list" {
  let source =
    #|---
    #|config:
    #|  themeVariables:
    #|    xyChart:
    #|      plotColorPalette: '#000000, #0000FF, #00FF00, #FF0000'
    #|---
    #|xychart
    #|title "Different Colors in xyChart"
    #|x-axis "categoriesX" ["Category 1", "Category 2", "Category 3", "Category 4"]
    #|y-axis "valuesY" 0 --> 50
    #|line [10,20,30,40]
    #|bar [20,30,25,35]
    #|bar [15,25,20,30]
    #|line [5,15,25,35]
  let svg = palette_svg(source)
  inspect(
    series_of(svg),
    content="1:#000000 2:#0000FF 3:#00FF00 4:#FF0000 5:#000000 6:#0000FF 7:#00FF00 8:#FF0000",
  )
  assert_true(svg.contains("stroke=\"var(--pele-series-1,"))
}

///|
test "a plotColorPalette keeps the commas inside color functions" {
  let svg = palette_svg(
    themed(
      {
        "xyChart": { "plotColorPalette": "rgb(0, 0, 0), hsl(0 50% 50% / 0.5)" },
      },
      XYCHART,
    ),
  )
  inspect(
    series_of(svg),
    content="1:rgb(0, 0, 0) 2:hsl(0 50% 50% / 0.5) 3:rgb(0, 0, 0) 4:hsl(0 50% 50% / 0.5) 5:rgb(0, 0, 0) 6:hsl(0 50% 50% / 0.5) 7:rgb(0, 0, 0) 8:hsl(0 50% 50% / 0.5)",
  )
}

///|
test "each diagram's palette maps onto its series in order" {
  let cases : Array[(String, Json)] = [
    (PIE, { "pie1": "red", "pie2": "blue" }),
    ("gitGraph\n  commit", { "git0": "red", "git1": "blue" }),
    (
      "timeline\n  2001 : a\n  2002 : b",
      { "cScale0": "red", "cScale1": "blue" },
    ),
    (
      "radar-beta\n  axis a, b, c\n  curve x{1,2,3}",
      { "cScale0": "red", "cScale1": "blue" },
    ),
    ("treemap\n\"a\": 1\n\"b\": 2", { "cScale0": "red", "cScale1": "blue" }),
    (
      "mindmap\n  root\n    a\n    b",
      { "cScale0": "green", "cScale1": "red", "cScale2": "blue" },
    ),
  ]
  for entry in cases {
    let (body, vars) = entry
    assert_eq(series_of(palette_svg(themed(vars, body))), "1:red 2:blue")
  }
}

///|
test "a venn palette repeats the colors it sets" {
  let svg = palette_svg(
    themed({ "venn2": "red", "venn4": "blue" }, "venn-beta\n  set A\n  set B"),
  )
  inspect(
    series_of(svg),
    content="1:red 2:blue 3:red 4:blue 5:red 6:blue 7:red 8:blue",
  )
}

///|
test "palettes of other diagrams and other theme colors set no series" {
  inspect(
    series_of(
      palette_svg(themed({ "cScale0": "red", "primaryColor": "red" }, PIE)),
    ),
    content="",
  )
  inspect(
    series_of(
      palette_svg(
        themed(
          { "fillType0": "red", "cScale0": "red" },
          "journey\n  section S\n    Task: 5: Me",
        ),
      ),
    ),
    content="",
  )
  inspect(
    series_of(palette_svg(themed({ "pie1": "red" }, "flowchart LR\n  a --> b"))),
    content="",
  )
}

///|
test "theme variables are read from front matter, directives and the config option" {
  let front = "---\nconfig:\n  themeVariables:\n    pie1: '#123456'\n---\n\{PIE}"
  inspect(series_of(palette_svg(front)), content="1:#123456")
  let from_option = palette_svg(PIE, config={
    "themeVariables": { "pie2": "oklch(70% 0.1 200)" },
  })
  inspect(series_of(from_option), content="2:oklch(70% 0.1 200)")
}

///|
test "theme-aware colors are accepted" {
  let vars : Json = {
    "pie1": "var(--pele-accent)",
    "pie2": "light-dark(#000, #fff)",
    "pie3": "color-mix(in srgb, red 40%, blue)",
  }
  inspect(
    series_of(palette_svg(themed(vars, PIE))),
    content="1:var(--pele-accent) 2:light-dark(#000, #fff) 3:color-mix(in srgb, red 40%, blue)",
  )
}

///|
test "values that are not colors are dropped and keep the theme color in their place" {
  let rejected = [
    "url(https://example.com/a.svg)", "url(//example.com/a.svg)", "image-set(a 1x)",
    "red;stroke:blue", "\"><script>alert(1)</script>", "expression(alert(1))", "rgb(0, 0",
    "red)", "red}", "javascript:alert(1)", "/*", "reddish", "#ff00000", "var(--page-color)",
    "color-mix(in srgb, var(--page-color) 50%, red)",
  ]
  for value in rejected {
    let svg = palette_svg(themed({ "pie1": value, "pie2": "blue" }, PIE))
    assert_eq(series_of(svg), "2:blue")
    assert_false(svg.contains("<script"))
    assert_false(svg.contains("url("))
  }
  let list = palette_svg(
    themed({ "xyChart": { "plotColorPalette": "url(a), blue" } }, XYCHART),
  )
  inspect(series_of(list), content="2:blue 4:blue 6:blue 8:blue")
}

///|
fn count_of(text : String, part : String) -> Int32 {
  text.split(part).count() - 1
}

///|
test "labels on palette colors take the label color that contrasts with them" {
  let on_light = "fill=\"var(--pele-fg-on-light,#1f1f1f)\""
  let on_dark = "fill=\"var(--pele-fg-on-dark,#fff)\""
  let pie = palette_svg(
    themed(
      { "pie1": "#ffeb3b", "pie2": "navy", "pie3": "var(--pele-accent)" },
      "pie\n  \"A\": 1\n  \"B\": 1\n  \"C\": 1",
    ),
  )
  let labels = pie
    .split("<text ")
    .filter(label => label.contains("%</text>"))
    .map(label => @util.slice(label.to_owned(), 0, end=label.find(">").unwrap()))
    .to_array()
  assert_true(labels[0].contains(on_light))
  assert_true(labels[1].contains(on_dark))
  assert_false(labels[2].contains("fill="))
  assert_true(pie.contains("class=\"pele-slice-labels\""))
  let git = palette_svg(
    themed({ "git0": "#ffeb3b" }, "gitGraph\n  commit\n  branch dev\n  commit"),
  )
  assert_true(git.contains("class=\"pele-label\" \{on_light}"))
  assert_true(git.contains("class=\"pele-label\" fill=\"var(--_bg)\""))
  let timeline = palette_svg(
    themed({ "cScale0": "#ffeb3b" }, "timeline\n  section S\n    2001 : a"),
  )
  inspect(count_of(timeline, on_light), content="2")
  let treemap = palette_svg(
    themed({ "cScale0": "#ffeb3b" }, "treemap\n\"a\": 1\n\"b\": 1"),
  )
  inspect(count_of(treemap, on_light), content="2")
}

///|
test "the output is unchanged without a palette" {
  assert_eq(
    palette_svg(PIE),
    palette_svg(themed({ "primaryColor": "red" }, PIE)),
  )
  assert_false(palette_svg(PIE).contains("--pele-series-1:"))
}

///|
test "colors are read as pele's own patterns read them" {
  let read = (value : String) => {
    series_of(palette_svg(themed({ "pie1": value }, PIE)))
  }
  inspect(read("var( --pele-accent )"), content="1:var( --pele-accent )")
  inspect(read("VAR(--pele-accent)"), content="1:VAR(--pele-accent)")
  inspect(read("var(--PELE-accent)"), content="")
  inspect(read("rgb (0,0,0)"), content="1:rgb (0,0,0)")
  inspect(read("(red)"), content="")
  inspect(read("GREY"), content="1:GREY")
  inspect(read("\u{a0}navy\u{3000}"), content="1:navy")
  inspect(read("currentColor"), content="1:currentColor")
  inspect(read("rgb(0,\u{b}0,0)"), content="1:rgb(0,0,0)")
  let padded = (length : Int32) => {
    "rgb(1 2 3" + " ".repeat(length - "rgb(1 2 3)".length()) + ")"
  }
  assert_eq(read(padded(200)), "1:" + padded(200))
  inspect(read(padded(201)), content="")
}
