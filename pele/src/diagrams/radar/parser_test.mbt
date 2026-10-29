///|
fn optional(value : String?) -> String {
  match value {
    Some(text) => text.escape()
    None => "-"
  }
}

///|
fn entry_text(entry : @radar.EntryAst) -> String {
  match entry.axis {
    Some(axis) => "\{axis}:\{entry.value}"
    None => "\{entry.value}"
  }
}

///|
fn option_text(option : @radar.OptionAst) -> String {
  let value = match option.value {
    Flag(flag) => "\{flag}"
    Number(number) => "\{number}"
    Name(name) => name
  }
  "\{option.name}=\{value}"
}

///|
fn ast(source : String) -> String {
  let ast = @radar.parse_radar(source) catch {
    @errors.PeleError(failure) => return "\{failure.message}"
  }
  let axes = ast.axes.map(axis => "\{axis.name}[\{optional(axis.label)}]")
  let curves = ast.curves.map(curve => {
    let entries = curve.entries.map(entry_text).join(" ")
    "\{curve.name}[\{optional(curve.label)}]{\{entries}}"
  })
  let options = ast.options.map(option_text)
  "title=\{optional(ast.title)} accTitle=\{optional(ast.acc_title)} accDescr=\{optional(ast.acc_descr)} axes=\{axes.join(",")} curves=\{curves.join(",")} options=\{options.join(",")}"
}

///|
test "a bare header is a chart without content" {
  let bare = "title=- accTitle=- accDescr=- axes= curves= options="
  inspect(ast("radar-beta"), content=bare)
  inspect(ast("radar-beta:"), content=bare)
  inspect(ast("radar-beta :"), content=bare)
  inspect(ast("\n  \t radar-beta\t\n  "), content=bare)
}

///|
test "a title and accessibility statements are read" {
  inspect(
    ast(
      "radar-beta\n  title My Title\n  accDescr: My Accessible Description\n  accTitle: My Accessible Title",
    ),
    content="title=\"My Title\" accTitle=\"My Accessible Title\" accDescr=\"My Accessible Description\" axes= curves= options=",
  )
  inspect(
    ast("radar-beta title T axis A"),
    content="title=\"T axis A\" accTitle=- accDescr=- axes= curves= options=",
  )
}

///|
test "axes are separated by commas or by statements and may carry labels" {
  inspect(
    ast("radar-beta\naxis my-axis\naxis my-axis2[\"Second\"]"),
    content="title=- accTitle=- accDescr=- axes=my-axis[-],my-axis2[\"Second\"] curves= options=",
  )
  inspect(
    ast("radar-beta\naxis my-axis [\"One\"], my-axis2\t['Two']"),
    content="title=- accTitle=- accDescr=- axes=my-axis[\"One\"],my-axis2[\"Two\"] curves= options=",
  )
  inspect(
    ast("radar-beta\naxis a,\nb"),
    content="Parse error on line 2:\naxis a,\n-------^\nExpecting token of type 'ID' but found `\n`.",
  )
}

///|
test "a curve holds numbers or named entries" {
  inspect(
    ast("radar-beta\naxis A,B\ncurve c{ 1, 2.5 }, d[\"D\"]{\n\n3,\n\n4\n\n}"),
    content="title=- accTitle=- accDescr=- axes=A[-],B[-] curves=c[-]{1 2.5},d[\"D\"]{3 4} options=",
  )
  inspect(
    ast("radar-beta\naxis A,B\ncurve c{ A 1, B : 2 }"),
    content="title=- accTitle=- accDescr=- axes=A[-],B[-] curves=c[-]{A:1 B:2} options=",
  )
}

///|
test "options are read in order, and a value may follow its name only" {
  inspect(
    ast(
      "radar-beta\nticks 10\nshowLegend false\ngraticule polygon\nmin 1\nmax 10.5",
    ),
    content="title=- accTitle=- accDescr=- axes= curves= options=ticks=10,showLegend=false,graticule=polygon,min=1,max=10.5",
  )
  inspect(
    ast("radar-beta\nshowLegend true, ticks 3, graticule circle"),
    content="title=- accTitle=- accDescr=- axes= curves= options=showLegend=true,ticks=3,graticule=circle",
  )
  inspect(
    ast("radar-beta\nticks 3, axis"),
    content="Parse error on line 2:\nticks 3, axis\n---------^\nExpecting an option but found `axis`.",
  )
}

///|
test "numbers follow the NUMBER pattern" {
  inspect(
    ast("radar-beta\naxis A\ncurve c{0.5, 0, 12.25}"),
    content="title=- accTitle=- accDescr=- axes=A[-] curves=c[-]{0.5 0 12.25} options=",
  )
  inspect(
    ast("radar-beta\nmax 05"),
    content="Parse error on line 2:\nmax 05\n-----^\nExpecting an axis, a curve, an option, a title, or a line break but found `5`.",
  )
  inspect(
    ast("radar-beta\nmax 1.2.3"),
    content="Lexical error on line 2. Unrecognized text.\nmax 1.2.3\n-----^",
  )
  inspect(
    ast("radar-beta\nmax -5"),
    content="Lexical error on line 2. Unrecognized text.\nmax -5\n----^",
  )
}

///|
test "a word that continues as a name is a name" {
  inspect(
    ast("radar-beta\naxis axisx, maxi, min-1, _x, a_b"),
    content="title=- accTitle=- accDescr=- axes=axisx[-],maxi[-],min-1[-],_x[-],a_b[-] curves= options=",
  )
  inspect(
    ast("radar-beta\naxis a-, b"),
    content="Lexical error on line 2. Unrecognized text.\naxis a-, b\n------^",
  )
}

///|
test "a reserved value cannot be a name" {
  inspect(
    ast("radar-beta\naxis true"),
    content="Parse error on line 2:\naxis true\n-----^\nExpecting token of type 'ID' but found `true`.",
  )
  inspect(
    ast("radar-beta\n axis circle, b"),
    content="Parse error on line 2:\n axis circle, b\n------^\nExpecting token of type 'ID' but found `circle`.",
  )
}

///|
test "comments, directives, and front matter are skipped" {
  inspect(
    ast(
      "---\ntitle: x\n---\n%%{init: {\"theme\":\"dark\"}}%%\nradar-beta\naxis A %% c\ncurve c{1} %% d\n",
    ),
    content="title=- accTitle=- accDescr=- axes=A[-] curves=c[-]{1} options=",
  )
}

///|
test "an accDescr block spans lines" {
  inspect(
    ast("radar-beta\naccDescr {\n a\n b\n}\naxis A"),
    content="title=- accTitle=- accDescr=\"a\\nb\" axes=A[-] curves= options=",
  )
}

///|
test "an unclosed accDescr block is a name, not a statement" {
  inspect(
    ast("radar-beta\naccDescr {\naxis A"),
    content="Parse error on line 2:\naccDescr {\n^\nExpecting an axis, a curve, an option, a title, or a line break but found `accDescr`.",
  )
}

///|
test "a missing header is a parse error" {
  inspect(
    ast("axis A"),
    content="Parse error on line 1:\naxis A\n^\nExpecting token of type 'radar-beta' but found `axis`.",
  )
  inspect(
    ast("radar-betax"),
    content="Parse error on line 1:\nradar-betax\n^\nExpecting token of type 'radar-beta' but found `radar-betax`.",
  )
}

///|
test "malformed statements are parse errors" {
  inspect(
    ast("radar-beta\naxis"),
    content="Parse error on line 2:\naxis\n----^\nExpecting token of type 'ID' but found end of input.",
  )
  inspect(
    ast("radar-beta\naxis my-axis my-axis2"),
    content="Parse error on line 2:\naxis my-axis my-axis2\n-------------^\nExpecting an axis, a curve, an option, a title, or a line break but found `my-axis2`.",
  )
  inspect(
    ast("radar-beta\naxis A\ncurve c{ 1 2 }"),
    content="Parse error on line 3:\ncurve c{ 1 2 }\n-----------^\nExpecting token of type '}' but found `2`.",
  )
  inspect(
    ast("radar-beta\naxis A\ncurve c{ 1, A 2 }"),
    content="Parse error on line 3:\ncurve c{ 1, A 2 }\n------------^\nExpecting token of type 'NUMBER' but found `A`.",
  )
  inspect(
    ast("radar-beta\naxis A\ncurve c{}"),
    content="Parse error on line 3:\ncurve c{}\n--------^\nExpecting a number or an axis name but found `}`.",
  )
  inspect(
    ast("radar-beta\naxis A\ncurve c"),
    content="Parse error on line 3:\ncurve c\n-------^\nExpecting token of type '{' but found end of input.",
  )
}

///|
test "the end of input is reported before a trailing comment" {
  inspect(
    ast("radar-beta\ncurve a{1 %% c\n"),
    content="Parse error on line 2:\ncurve a{1 %% c\n---------^\nExpecting token of type '}' but found end of input.",
  )
}

///|
test "a name that starts with a digit lexes as a number first" {
  inspect(
    ast("radar-beta\naxis 1a"),
    content="Parse error on line 2:\naxis 1a\n-----^\nExpecting token of type 'ID' but found `1`.",
  )
}

///|
test "huge numbers do not stop the parser" {
  inspect(
    ast("radar-beta\nmax " + "9".repeat(400)),
    content="title=- accTitle=- accDescr=- axes= curves= options=max=Infinity",
  )
}

///|
test "long runs of digits and unclosed blocks are scanned once" {
  let zeros = "0".repeat(50000)
  inspect(
    ast("radar-beta\ncurve c{" + zeros + "}").length() > 0,
    content="true",
  )
  inspect(ast("radar-beta\nmax " + zeros + ".5").length() > 0, content="true")
  inspect(
    ast("radar-beta\n" + "accDescr {".repeat(5000)).has_prefix("Parse error"),
    content="true",
  )
  inspect(
    ast("radar-beta\naxis a" + "-".repeat(50000)).has_prefix("Lexical error"),
    content="true",
  )
}

///|
test "unknown text is a lexical error" {
  inspect(
    ast("radar-beta\naxis A@"),
    content="Lexical error on line 2. Unrecognized text.\naxis A@\n------^",
  )
}

///|
test "a name may start with circle, polygon, true, false or title" {
  inspect(
    ast(
      "radar-beta\n axis circles, polygonal, trueNorth, falsey, titles\n curve titles{1, 2, 3, 4, 5}, circles{ circles: 1, polygonal 2, trueNorth: 3, falsey 4, titles: 5 }",
    ),
    content="title=- accTitle=- accDescr=- axes=circles[-],polygonal[-],trueNorth[-],falsey[-],titles[-] curves=titles[-]{1 2 3 4 5},circles[-]{circles:1 polygonal:2 trueNorth:3 falsey:4 titles:5} options=",
  )
  inspect(
    ast("radar-beta\ntitleaxis a"),
    content="Parse error on line 2:\ntitleaxis a\n^\nExpecting an axis, a curve, an option, a title, or a line break but found `titleaxis`.",
  )
}

///|
test "an option value right after its option is read even when a name goes on" {
  inspect(
    ast(
      "radar-beta\n axis a, b\n showLegend falsecurve x{1, 2}\n graticule polygonaxis c",
    ),
    content="title=- accTitle=- accDescr=- axes=a[-],b[-],c[-] curves=x[-]{1 2} options=showLegend=false,graticule=polygon",
  )
  inspect(
    ast("radar-beta\ngraticule %%{init: {}}%% circlecurve x{1}"),
    content="title=- accTitle=- accDescr=- axes= curves=x[-]{1} options=graticule=circle",
  )
}
