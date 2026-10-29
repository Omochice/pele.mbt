///|
fn quoted(value : String?) -> String {
  match value {
    Some(text) => "\"\{text}\""
    None => "-"
  }
}

///|
fn group_line(group : @architecture.GroupAst) -> String {
  "group \{group.id}(\{quoted(group.icon)})[\{quoted(group.title)}] in \{quoted(group.parent)}"
}

///|
fn service_line(service : @architecture.ServiceAst) -> String {
  "service \{service.id}(\{quoted(service.icon)})\{quoted(service.icon_text)}[\{quoted(service.title)}] in \{quoted(service.parent)}"
}

///|
fn edge_line(edge : @architecture.EdgeAst) -> String {
  let lhs_group = if edge.lhs_group { "{group}" } else { "" }
  let lhs_into = if edge.lhs_into { "<" } else { "" }
  let rhs_into = if edge.rhs_into { ">" } else { "" }
  let rhs_group = if edge.rhs_group { "{group}" } else { "" }
  "edge \{edge.lhs_id}\{lhs_group}:\{edge.lhs_dir.name()}\{lhs_into} -\{quoted(edge.title)}- \{rhs_into}\{edge.rhs_dir.name()}:\{edge.rhs_id}\{rhs_group}"
}

///|
fn ast(source : String) -> String {
  let ast = @architecture.parse_architecture(source) catch {
    @errors.PeleError(failure) => return failure.message
  }
  let lines = [
    "title=\{quoted(ast.title)} accTitle=\{quoted(ast.acc_title)} accDescr=\{quoted(ast.acc_descr)}",
  ]
  for group in ast.groups {
    lines.push(group_line(group))
  }
  for service in ast.services {
    lines.push(service_line(service))
  }
  for junction in ast.junctions {
    lines.push("junction \{junction.id} in \{quoted(junction.parent)}")
  }
  for edge in ast.edges {
    lines.push(edge_line(edge))
  }
  for alignment in ast.alignments {
    lines.push("align \{alignment.direction} \{alignment.members.join(" ")}")
  }
  lines.join("\n")
}

///|
test "the header may stand alone, indented, or between line breaks" {
  inspect(ast("architecture-beta"), content="title=- accTitle=- accDescr=-")
  inspect(ast("  architecture-beta  "), content="title=- accTitle=- accDescr=-")
  inspect(ast("\tarchitecture-beta\t"), content="title=- accTitle=- accDescr=-")
  inspect(
    ast("\n        \tarchitecture-beta\n        "),
    content="title=- accTitle=- accDescr=-",
  )
  inspect(
    ast("\n\n\narchitecture-beta\n\n\n"),
    content="title=- accTitle=- accDescr=-",
  )
}

///|
test "a title may follow the header on its line or the next" {
  inspect(
    ast("architecture-beta title sample title"),
    content="title=\"sample title\" accTitle=- accDescr=-",
  )
  inspect(
    ast("  architecture-beta  title sample title  "),
    content="title=\"sample title\" accTitle=- accDescr=-",
  )
  inspect(
    ast("\tarchitecture-beta\ttitle sample title\t"),
    content="title=\"sample title\" accTitle=- accDescr=-",
  )
  inspect(
    ast("architecture-beta\n            \ttitle sample title\n            "),
    content="title=\"sample title\" accTitle=- accDescr=-",
  )
  inspect(
    ast("architecture-beta\n            title sample title"),
    content="title=\"sample title\" accTitle=- accDescr=-",
  )
  inspect(
    ast("architecture-beta title Simple Architecture Diagram"),
    content="title=\"Simple Architecture Diagram\" accTitle=- accDescr=-",
  )
}

///|
test "accessibility statements are read" {
  inspect(
    ast(
      "architecture-beta\n            title sample title\n            accTitle: sample accTitle\n            accDescr: sample accDescr\n            ",
    ),
    content="title=\"sample title\" accTitle=\"sample accTitle\" accDescr=\"sample accDescr\"",
  )
  inspect(
    ast(
      "architecture-beta\n            title sample title\n            accTitle: sample accTitle\n            accDescr {\n                sample accDescr\n            }\n            ",
    ),
    content="title=\"sample title\" accTitle=\"sample accTitle\" accDescr=\"sample accDescr\"",
  )
  inspect(
    ast(
      "architecture-beta\n accTitle: at\n accDescr { multi\n line }\n title t\n",
    ),
    content="title=\"t\" accTitle=\"at\" accDescr=\"multi\nline\"",
  )
}

///|
test "service titles may be quoted" {
  inspect(
    ast(
      "architecture-beta\n            service db(database)[\"Database\"] in api\n            ",
    ),
    content="title=- accTitle=- accDescr=-\nservice db(\"database\")-[\"Database\"] in \"api\"",
  )
  inspect(
    ast(
      "architecture-beta\n            service db(database)['Database'] in api\n            ",
    ),
    content="title=- accTitle=- accDescr=-\nservice db(\"database\")-[\"Database\"] in \"api\"",
  )
  inspect(
    ast(
      "architecture-beta\n            service db(database)[Database] in api\n            ",
    ),
    content="title=- accTitle=- accDescr=-\nservice db(\"database\")-[\"Database\"] in \"api\"",
  )
  inspect(
    ast(
      "architecture-beta\n            group api(cloud)[\"API\"]\n            ",
    ),
    content="title=- accTitle=- accDescr=-\ngroup api(\"cloud\")[\"API\"] in -",
  )
  inspect(
    ast(
      "architecture-beta\n            service db(database)[\"John's Database\"] in api\n            ",
    ),
    content="title=- accTitle=- accDescr=-\nservice db(\"database\")-[\"John's Database\"] in \"api\"",
  )
  inspect(
    ast(
      "architecture-beta\n            service api(server)[\"The \\\"Main\\\" API\"] in cloud\n            ",
    ),
    content="title=- accTitle=- accDescr=-\nservice api(\"server\")-[\"The \"Main\" API\"] in \"cloud\"",
  )
}

///|
test "unquoted titles keep non-ASCII text and punctuation" {
  inspect(
    ast("architecture-beta\nservice a(server)[采集器] in g1"),
    content="title=- accTitle=- accDescr=-\nservice a(\"server\")-[\"采集器\"] in \"g1\"",
  )
  inspect(
    ast("architecture-beta\nservice a(server)[Hello 世界] in g1"),
    content="title=- accTitle=- accDescr=-\nservice a(\"server\")-[\"Hello 世界\"] in \"g1\"",
  )
  inspect(
    ast("architecture-beta\nservice a(server)[Сервер] in g1"),
    content="title=- accTitle=- accDescr=-\nservice a(\"server\")-[\"Сервер\"] in \"g1\"",
  )
  inspect(
    ast("architecture-beta\nservice a(server)[Café] in g1"),
    content="title=- accTitle=- accDescr=-\nservice a(\"server\")-[\"Café\"] in \"g1\"",
  )
  inspect(
    ast("architecture-beta\nservice a(server)[Structure + Src] in g1"),
    content="title=- accTitle=- accDescr=-\nservice a(\"server\")-[\"Structure + Src\"] in \"g1\"",
  )
  inspect(
    ast("architecture-beta\nservice a(server)[Multi-Agent] in g1"),
    content="title=- accTitle=- accDescr=-\nservice a(\"server\")-[\"Multi-Agent\"] in \"g1\"",
  )
  inspect(
    ast("architecture-beta\nservice a(server)[A, B, C] in g1"),
    content="title=- accTitle=- accDescr=-\nservice a(\"server\")-[\"A, B, C\"] in \"g1\"",
  )
  inspect(
    ast("architecture-beta\nservice a(server)[TCP/IP: v6] in g1"),
    content="title=- accTitle=- accDescr=-\nservice a(\"server\")-[\"TCP/IP: v6\"] in \"g1\"",
  )
  inspect(
    ast("architecture-beta\ngroup g1(server)[你好世界]"),
    content="title=- accTitle=- accDescr=-\ngroup g1(\"server\")[\"你好世界\"] in -",
  )
}

///|
test "titles that are not cleanly quoted are read as Mermaid reads them" {
  inspect(
    ast("architecture-beta\nservice a[ sp  aced ]"),
    content="title=- accTitle=- accDescr=-\nservice a(-)-[\"sp  aced\"] in -",
  )
  inspect(
    ast("architecture-beta\nservice a[]"),
    content="Lexical error on line 2. Unrecognized text.\nservice a[]\n---------^",
  )
  inspect(
    ast("architecture-beta\nservice a[\"]"),
    content="title=- accTitle=- accDescr=-\nservice a(-)-[\"\"] in -",
  )
  inspect(
    ast("architecture-beta\nservice a[\\\"]"),
    content="title=- accTitle=- accDescr=-\nservice a(-)-[\"\\\"\"] in -",
  )
  inspect(
    ast("architecture-beta\nservice a[\"a\\\"b\"]"),
    content="title=- accTitle=- accDescr=-\nservice a(-)-[\"a\"b\"] in -",
  )
  inspect(
    ast("architecture-beta\nservice a[a\"b]"),
    content="title=- accTitle=- accDescr=-\nservice a(-)-[\"a\"b\"] in -",
  )
  inspect(
    ast("architecture-beta\nservice a[\"a\nb\"]"),
    content="title=- accTitle=- accDescr=-\nservice a(-)-[\"a\nb\"] in -",
  )
  inspect(
    ast("architecture-beta\nservice a[\"a\" b]"),
    content="title=- accTitle=- accDescr=-\nservice a(-)-[\"\"a\" b\"] in -",
  )
  inspect(
    ast("architecture-beta\nservice a['s \\' s']"),
    content="title=- accTitle=- accDescr=-\nservice a(-)-[\"s ' s\"] in -",
  )
  inspect(
    ast("architecture-beta\nservice a[\"x]"),
    content="title=- accTitle=- accDescr=-\nservice a(-)-[\"\"x\"] in -",
  )
}

///|
test "a service takes an icon or icon text" {
  inspect(
    ast(
      "architecture-beta\nservice a(disk)\nservice b \"txt\" [B]\nservice c 'i'[t]\nservice d(a:b-c)\nservice e(_)",
    ),
    content="title=- accTitle=- accDescr=-\nservice a(\"disk\")-[-] in -\nservice b(-)\"txt\"[\"B\"] in -\nservice c(-)\"i\"[\"t\"] in -\nservice d(\"a:b-c\")-[-] in -\nservice e(\"_\")-[-] in -",
  )
  inspect(
    ast("architecture-beta\nservice a \"a\\\"b\""),
    content="title=- accTitle=- accDescr=-\nservice a(-)\"a\"b\"[-] in -",
  )
  inspect(
    ast("architecture-beta\nservice a \"two\nlines\""),
    content="title=- accTitle=- accDescr=-\nservice a(-)\"two\nlines\"[-] in -",
  )
  inspect(
    ast("architecture-beta\nservice a()"),
    content="Lexical error on line 2. Unrecognized text.\nservice a()\n---------^",
  )
  inspect(
    ast("architecture-beta\nservice a(a b)"),
    content="Lexical error on line 2. Unrecognized text.\nservice a(a b)\n---------^",
  )
  inspect(
    ast("architecture-beta\nservice a \"t\"(server)"),
    content="Parse error on line 2:\nservice a \"t\"(server)\n-------------^\nExpecting a line break or the end of input but found `(server)`.",
  )
}

///|
test "groups and junctions may be placed in a group" {
  inspect(
    ast(
      "architecture-beta\ngroup g\ngroup h(a-b:c)[\"t\"] in g\nservice s 'i'[t] in h\nservice in-x(_)[ ] in g\njunction j in g\nalign column s j in-x\n",
    ),
    content="title=- accTitle=- accDescr=-\ngroup g(-)[-] in -\ngroup h(\"a-b:c\")[\"t\"] in \"g\"\nservice s(-)\"i\"[\"t\"] in \"h\"\nservice in-x(\"_\")-[\"\"] in \"g\"\njunction j in \"g\"\nalign column s j in-x",
  )
  inspect(
    ast("architecture-beta\njunction j(x)"),
    content="Parse error on line 2:\njunction j(x)\n----------^\nExpecting a line break or the end of input but found `(x)`.",
  )
}

///|
test "edges name a side and an optional arrowhead at each end" {
  inspect(
    ast("architecture-beta\nservice a\nservice b\na:R -- L:b"),
    content="title=- accTitle=- accDescr=-\nservice a(-)-[-] in -\nservice b(-)-[-] in -\nedge a:R --- L:b",
  )
  inspect(
    ast(
      "architecture-beta\nservice a\nservice b\na:R --> L:b\na:T <-- B:b\na:L <--> R:b",
    ),
    content="title=- accTitle=- accDescr=-\nservice a(-)-[-] in -\nservice b(-)-[-] in -\nedge a:R --- >L:b\nedge a:T< --- B:b\nedge a:L< --- >R:b",
  )
  inspect(
    ast(
      "architecture-beta\nservice a\nservice b\na:R >--< L:b\na:T >-[x]-< B:b\na{group}:L <-- R:b\na:B --> T:b{group}\na : L - [ y ] - R : b\n",
    ),
    content="title=- accTitle=- accDescr=-\nservice a(-)-[-] in -\nservice b(-)-[-] in -\nedge a:R< --- >L:b\nedge a:T< -\"x\"- >B:b\nedge a{group}:L< --- R:b\nedge a:B --- >T:b{group}\nedge a:L -\"y\"- R:b",
  )
  inspect(
    ast("architecture-beta\nservice a\nservice b\na:L<-[ t ]->R:b %% e\n"),
    content="title=- accTitle=- accDescr=-\nservice a(-)-[-] in -\nservice b(-)-[-] in -\nedge a:L< -\"t\"- >R:b",
  )
  inspect(
    ast("architecture-beta\na:R -[ \"q\" ]- L:b"),
    content="title=- accTitle=- accDescr=-\nedge a:R -\"q\"- L:b",
  )
  inspect(
    ast("architecture-beta\na:R - L:b"),
    content="Parse error on line 2:\na:R - L:b\n------^\nExpecting token of type 'ARCH_TITLE' but found `L`.",
  )
  inspect(
    ast("architecture-beta\na:X -- L:b"),
    content="Parse error on line 2:\na:X -- L:b\n--^\nExpecting token of type 'ARROW_DIRECTION' but found `X`.",
  )
  inspect(
    ast("architecture-beta\na:R --- L:b"),
    content="Parse error on line 2:\na:R --- L:b\n------^\nExpecting token of type 'ARROW_DIRECTION' but found `-`.",
  )
  inspect(
    ast("architecture-beta\na:R -[x] L:b"),
    content="Parse error on line 2:\na:R -[x] L:b\n---------^\nExpecting token of type '-' but found `L`.",
  )
  inspect(
    ast("architecture-beta\na:RL -- L:b"),
    content="Parse error on line 2:\na:RL -- L:b\n---^\nExpecting '--' or '-' but found `L`.",
  )
}

///|
test "ids that start with a direction letter split into a direction and the rest" {
  inspect(
    ast("architecture-beta\nservice Lambda"),
    content="Parse error on line 2:\nservice Lambda\n--------^\nExpecting token of type 'ID' but found `L`.",
  )
  inspect(
    ast("architecture-beta\nservice lambda"),
    content="title=- accTitle=- accDescr=-\nservice lambda(-)-[-] in -",
  )
  inspect(
    ast("architecture-beta\nservice B"),
    content="Parse error on line 2:\nservice B\n--------^\nExpecting token of type 'ID' but found `B`.",
  )
  inspect(
    ast("architecture-beta\nLa:R -- L:b"),
    content="Parse error on line 2:\nLa:R -- L:b\n^\nExpecting a group, a service, a junction, an edge, an alignment, a title, or a line break but found `L`.",
  )
}

///|
test "keywords give way to longer ids" {
  inspect(
    ast(
      "architecture-beta\nservice rowspan(server)[Rowspan]\nservice columnar(server)[Columnar]\nalign row rowspan columnar",
    ),
    content="title=- accTitle=- accDescr=-\nservice rowspan(\"server\")-[\"Rowspan\"] in -\nservice columnar(\"server\")-[\"Columnar\"] in -\nalign row rowspan columnar",
  )
  inspect(
    ast(
      "architecture-beta\nservice servicex\nservice in-in-in\nservice groups\nservice junctions\nservice aligned\nservice in1",
    ),
    content="title=- accTitle=- accDescr=-\nservice servicex(-)-[-] in -\nservice in-in-in(-)-[-] in -\nservice groups(-)-[-] in -\nservice junctions(-)-[-] in -\nservice aligned(-)-[-] in -\nservice in1(-)-[-] in -",
  )
  inspect(
    ast("architecture-beta\nservice align(database)[X]"),
    content="Parse error on line 2:\nservice align(database)[X]\n--------^\nExpecting token of type 'ID' but found `align`.",
  )
  inspect(
    ast("architecture-beta\nservice row"),
    content="Parse error on line 2:\nservice row\n--------^\nExpecting token of type 'ID' but found `row`.",
  )
  inspect(
    ast("architecture-beta\nservice column"),
    content="Parse error on line 2:\nservice column\n--------^\nExpecting token of type 'ID' but found `column`.",
  )
  inspect(
    ast("architecture-beta\nservice in"),
    content="Parse error on line 2:\nservice in\n--------^\nExpecting token of type 'ID' but found `in`.",
  )
  inspect(
    ast("architecture-beta\nservice a-"),
    content="Parse error on line 2:\nservice a-\n---------^\nExpecting a line break or the end of input but found `-`.",
  )
  inspect(
    ast("architecture-beta\nservice x-y\nservice _\nservice 1"),
    content="title=- accTitle=- accDescr=-\nservice x-y(-)-[-] in -\nservice _(-)-[-] in -\nservice 1(-)-[-] in -",
  )
}

///|
test "ids may start with title" {
  inspect(
    ast(
      "architecture-beta\ngroup titles(cloud)[G]\nservice title-db(database)[DB] in titles\nservice title_2 in titles\ntitle-db:R -- L:title_2",
    ),
    content="title=- accTitle=- accDescr=-\ngroup titles(\"cloud\")[\"G\"] in -\nservice title-db(\"database\")-[\"DB\"] in \"titles\"\nservice title_2(-)-[-] in \"titles\"\nedge title-db:R --- L:title_2",
  )
}

///|
test "alignments take a direction and at least two members" {
  inspect(
    ast("architecture-beta\nalign row a b c"),
    content="title=- accTitle=- accDescr=-\nalign row a b c",
  )
  inspect(
    ast("architecture-beta\nalign column a b"),
    content="title=- accTitle=- accDescr=-\nalign column a b",
  )
  inspect(
    ast("architecture-beta\nalign row a"),
    content="Parse error on line 2:\nalign row a\n-----------^\nExpecting token of type 'ID' but found end of input.",
  )
  inspect(
    ast("architecture-beta\nalign diagonal a b"),
    content="Parse error on line 2:\nalign diagonal a b\n------^\nExpecting 'row' or 'column' but found `diagonal`.",
  )
  inspect(
    ast("architecture-beta\nalign"),
    content="Parse error on line 2:\nalign\n-----^\nExpecting 'row' or 'column' but found end of input.",
  )
}

///|
test "comments, directives, and front matter fences are skipped" {
  inspect(
    ast(
      "%%{init: {\"theme\":\"dark\"}}%%\narchitecture-beta %% c\nservice a %% d\nservice b\n",
    ),
    content="title=- accTitle=- accDescr=-\nservice a(-)-[-] in -\nservice b(-)-[-] in -",
  )
  inspect(
    ast("architecture-beta\nservice a\n  %%{init: {}}%%\nservice b %%{ x }%%\n"),
    content="title=- accTitle=- accDescr=-\nservice a(-)-[-] in -\nservice b(-)-[-] in -",
  )
  inspect(
    ast(
      "architecture-beta\nservice a\nservice b\na:R -- L:b\n---\nskipped: yes\n---\nservice c\nb:B -[x]- T:c\n  ---\n---\n",
    ),
    content="title=- accTitle=- accDescr=-\nservice a(-)-[-] in -\nservice b(-)-[-] in -\nservice c(-)-[-] in -\nedge a:R --- L:b\nedge b:B -\"x\"- T:c",
  )
  inspect(
    ast("architecture-beta\nservice a\nservice b\na:R ---\n"),
    content="Parse error on line 4:\na:R ---\n------^\nExpecting token of type 'ARROW_DIRECTION' but found `-`.",
  )
}

///|
test "text Mermaid rejects is a syntax error" {
  inspect(
    ast("architecture\nservice a"),
    content="Parse error on line 1:\narchitecture\n^\nExpecting token of type 'architecture-beta' but found `architecture`.",
  )
  inspect(
    ast("service a"),
    content="Parse error on line 1:\nservice a\n^\nExpecting token of type 'architecture-beta' but found `service`.",
  )
  inspect(
    ast("architecture-beta\nservice a service b"),
    content="Parse error on line 2:\nservice a service b\n----------^\nExpecting a line break or the end of input but found `service`.",
  )
  inspect(
    ast("architecture-beta\nservice"),
    content="Parse error on line 2:\nservice\n-------^\nExpecting token of type 'ID' but found end of input.",
  )
  inspect(
    ast("architecture-beta\ngroup"),
    content="Parse error on line 2:\ngroup\n-----^\nExpecting token of type 'ID' but found end of input.",
  )
  inspect(
    ast("architecture-beta\njunction"),
    content="Parse error on line 2:\njunction\n--------^\nExpecting token of type 'ID' but found end of input.",
  )
  inspect(
    ast("architecture-beta\nfoo bar"),
    content="Parse error on line 2:\nfoo bar\n----^\nExpecting token of type ':' but found `bar`.",
  )
  inspect(
    ast("architecture-beta\n:"),
    content="Parse error on line 2:\n:\n^\nExpecting a group, a service, a junction, an edge, an alignment, a title, or a line break but found `:`.",
  )
  inspect(
    ast("architecture-beta\nservice a(server"),
    content="Lexical error on line 2. Unrecognized text.\nservice a(server\n---------^",
  )
  inspect(
    ast("architecture-beta\nservice a[b"),
    content="Lexical error on line 2. Unrecognized text.\nservice a[b\n---------^",
  )
  inspect(
    ast("architecture-beta\nservice a in"),
    content="Parse error on line 2:\nservice a in\n------------^\nExpecting token of type 'ID' but found end of input.",
  )
  inspect(
    ast("architecture-beta\nservice a \"x"),
    content="Lexical error on line 2. Unrecognized text.\nservice a \"x\n----------^",
  )
  inspect(
    ast("architecture-beta\n{group}"),
    content="Parse error on line 2:\n{group}\n^\nExpecting a group, a service, a junction, an edge, an alignment, a title, or a line break but found `{group}`.",
  )
}
