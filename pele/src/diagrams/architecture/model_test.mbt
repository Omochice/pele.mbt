///|
fn failure_text(failure : @errors.Failure) -> String {
  "\{failure.code.to_string()}: \{failure.message}"
}

///|
fn dump(db : @architecture.ArchitectureDb) -> String {
  let lines = [
    "title=\{quoted(db.title)} accTitle=\{quoted(db.acc_title)} accDescr=\{quoted(db.acc_descr)}",
  ]
  for _, group in db.groups {
    lines.push(
      "group \{group.id}(\{quoted(group.icon)})[\{quoted(group.title)}] in \{quoted(group.parent)}",
    )
  }
  for _, node in db.nodes {
    match node.kind {
      Service =>
        lines.push(
          "service \{node.id}(\{quoted(node.icon)})\{quoted(node.icon_text)}[\{quoted(node.title)}] in \{quoted(node.parent)}",
        )
      Junction => lines.push("junction \{node.id} in \{quoted(node.parent)}")
    }
  }
  for e in db.edges {
    lines.push(
      "edge \{e.lhs_id}:\{e.lhs_dir.name()} into=\{e.lhs_into} group=\{e.lhs_group} \{quoted(e.title)} \{e.rhs_id}:\{e.rhs_dir.name()} into=\{e.rhs_into} group=\{e.rhs_group}",
    )
  }
  for hint in db.layout_hints {
    lines.push("align \{hint.direction} \{hint.members.join(" ")}")
  }
  lines.join("\n")
}

///|
fn model(source : String) -> String {
  let db = @architecture.ArchitectureDb::new()
  @architecture.populate(@architecture.parse_architecture(source), db) catch {
    @errors.PeleError(failure) => return failure_text(failure)
  }
  dump(db)
}

///|
fn attempt(run : () -> Unit raise @errors.PeleError) -> String {
  run() catch {
    @errors.PeleError(failure) => return failure_text(failure)
  }
  "ok"
}

///|
test "the database checks a junction as it checks any node" {
  let db = @architecture.ArchitectureDb::new()
  db.add_group("g1", title="Group")
  db.add_service("svc", icon="server", title="Svc", parent="g1")
  inspect(
    attempt(() => db.add_junction("svc")),
    content="semantic: The junction id [svc] is already in use by another node",
  )
  inspect(
    attempt(() => db.add_junction("g1")),
    content="semantic: The junction id [g1] is already in use by another group",
  )
  inspect(
    attempt(() => db.add_junction("j1", parent="nonexistent")),
    content="semantic: The junction [j1]'s parent does not exist. Please make sure the parent is created before this junction",
  )
  db.add_service("app", icon="server", title="App")
  inspect(
    attempt(() => db.add_junction("j1", parent="app")),
    content="semantic: The junction [j1]'s parent is not a group",
  )
  inspect(
    attempt(() => db.add_junction("j1", parent="j1")),
    content="semantic: The junction [j1] cannot be placed within itself",
  )
  db.add_group("app_env", title="App Env")
  inspect(attempt(() => db.add_junction("mid", parent="app_env")), content="ok")
}

///|
test "the database refuses an alignment of fewer than two members" {
  let db = @architecture.ArchitectureDb::new()
  inspect(
    attempt(() => db.add_layout_hint({ direction: "row", members: [], })),
    content="semantic: An align directive requires at least two members; got 0",
  )
  inspect(
    attempt(() => {
      db.add_layout_hint({ direction: "column", members: ["only_one"], })
    }),
    content="semantic: An align directive requires at least two members; got 1",
  )
}

///|
test "groups come first, then services, junctions, edges, and alignments" {
  inspect(
    model(
      "architecture-beta\ntitle T\ngroup g(cloud)[G]\nservice a(server)[A] in g\njunction j\na:R -[x]-> L:j\nalign row a j",
    ),
    content="title=\"T\" accTitle=- accDescr=-\ngroup g(\"cloud\")[\"G\"] in -\nservice a(\"server\")-[\"A\"] in \"g\"\njunction j in -\nedge a:R into=false group=false \"x\" j:L into=true group=false\nalign row a j",
  )
  inspect(
    model(
      "architecture-beta\nservice a\njunction j\ngroup g\nservice b in g\ngroup h in g\nj:B -- T:b{group}",
    ),
    content="title=- accTitle=- accDescr=-\ngroup g(-)[-] in -\ngroup h(-)[-] in \"g\"\nservice a(-)-[-] in -\nservice b(-)-[-] in \"g\"\njunction j in -\nedge j:B into=false group=false - b:T into=false group=true",
  )
}

///|
test "accessible texts are tidied as Mermaid tidies them" {
  inspect(
    model(
      "architecture-beta\naccTitle:   spaced title\naccDescr {\n  first\n    second\n}\nservice a",
    ),
    content="title=- accTitle=\"spaced title\" accDescr=\"first\nsecond\"\nservice a(-)-[-] in -",
  )
  inspect(
    model("architecture-beta\naccTitle:\naccDescr:\ntitle\nservice a"),
    content="title=- accTitle=- accDescr=-\nservice a(-)-[-] in -",
  )
}

///|
test "nodes keep the order they were declared in" {
  inspect(
    model(
      "architecture-beta\nservice a(server)[A]\nservice 20(server)[B]\nservice 10(server)[C]",
    ),
    content="title=- accTitle=- accDescr=-\nservice a(\"server\")-[\"A\"] in -\nservice 20(\"server\")-[\"B\"] in -\nservice 10(\"server\")-[\"C\"] in -",
  )
  inspect(
    model(
      "architecture-beta\ngroup __proto__(cloud)[Marker]\nservice a(server)[A] in __proto__\nservice b(server)[B] in __proto__\na:R -- L:b",
    ),
    content="title=- accTitle=- accDescr=-\ngroup __proto__(\"cloud\")[\"Marker\"] in -\nservice a(\"server\")-[\"A\"] in \"__proto__\"\nservice b(\"server\")-[\"B\"] in \"__proto__\"\nedge a:R into=false group=false - b:L into=false group=false",
  )
}

///|
test "a deeply nested diagram keeps every group, service, and edge" {
  inspect(
    model(
      "architecture-beta\n    group sub1(cloud)[Subscription A]\n    group vnet1(cloud)[VNet A] in sub1\n    service vm1(server)[VM] in vnet1\n\n    group sub2(cloud)[Subscription B]\n    group shared(cloud)[Shared] in sub2\n    service reg(database)[Registry] in shared\n\n    group env(cloud)[Environment] in sub2\n    group vnet(cloud)[VNet] in env\n    group snet1(cloud)[App Subnet] in vnet\n    service nsg(server)[NSG] in snet1\n    service asp(server)[App Plan] in snet1\n    service web(server)[Web App] in snet1\n\n    group snet2(cloud)[PE Subnet] in vnet\n    service pe1(server)[PE Blob] in snet2\n    service pe2(server)[PE Bus] in snet2\n\n    service storage(disk)[Storage] in env\n    service container(disk)[Container] in env\n    service bus(server)[Service Bus] in env\n    service dns(server)[DNS Zone] in env\n\n    service client(internet)[Client]\n\n    reg:B --> T:web\n    nsg:R --> L:asp\n    asp:R --> L:web\n    web:R --> L:pe1\n    pe1:R --> L:storage\n    storage:B --> T:container\n    web:B --> T:pe2\n    pe2:R --> L:bus\n    vm1:R --> L:pe2",
    ),
    content="title=- accTitle=- accDescr=-\ngroup sub1(\"cloud\")[\"Subscription A\"] in -\ngroup vnet1(\"cloud\")[\"VNet A\"] in \"sub1\"\ngroup sub2(\"cloud\")[\"Subscription B\"] in -\ngroup shared(\"cloud\")[\"Shared\"] in \"sub2\"\ngroup env(\"cloud\")[\"Environment\"] in \"sub2\"\ngroup vnet(\"cloud\")[\"VNet\"] in \"env\"\ngroup snet1(\"cloud\")[\"App Subnet\"] in \"vnet\"\ngroup snet2(\"cloud\")[\"PE Subnet\"] in \"vnet\"\nservice vm1(\"server\")-[\"VM\"] in \"vnet1\"\nservice reg(\"database\")-[\"Registry\"] in \"shared\"\nservice nsg(\"server\")-[\"NSG\"] in \"snet1\"\nservice asp(\"server\")-[\"App Plan\"] in \"snet1\"\nservice web(\"server\")-[\"Web App\"] in \"snet1\"\nservice pe1(\"server\")-[\"PE Blob\"] in \"snet2\"\nservice pe2(\"server\")-[\"PE Bus\"] in \"snet2\"\nservice storage(\"disk\")-[\"Storage\"] in \"env\"\nservice container(\"disk\")-[\"Container\"] in \"env\"\nservice bus(\"server\")-[\"Service Bus\"] in \"env\"\nservice dns(\"server\")-[\"DNS Zone\"] in \"env\"\nservice client(\"internet\")-[\"Client\"] in -\nedge reg:B into=false group=false - web:T into=true group=false\nedge nsg:R into=false group=false - asp:L into=true group=false\nedge asp:R into=false group=false - web:L into=true group=false\nedge web:R into=false group=false - pe1:L into=true group=false\nedge pe1:R into=false group=false - storage:L into=true group=false\nedge storage:B into=false group=false - container:T into=true group=false\nedge web:B into=false group=false - pe2:T into=true group=false\nedge pe2:R into=false group=false - bus:L into=true group=false\nedge vm1:R into=false group=false - pe2:L into=true group=false",
  )
  inspect(
    model(
      "architecture-beta\n  group app_env(cloud)[App Env]\n  service app(server)[Web App] in app_env\n  service db(database)[DB] in app_env\n  service api(server)[API] in app_env\n  junction mid in app_env\n  app:B -- T:mid\n  mid:R -- L:db\n  mid:B -- T:api",
    ),
    content="title=- accTitle=- accDescr=-\ngroup app_env(\"cloud\")[\"App Env\"] in -\nservice app(\"server\")-[\"Web App\"] in \"app_env\"\nservice db(\"database\")-[\"DB\"] in \"app_env\"\nservice api(\"server\")-[\"API\"] in \"app_env\"\njunction mid in \"app_env\"\nedge app:B into=false group=false - mid:T into=false group=false\nedge mid:R into=false group=false - db:L into=false group=false\nedge mid:B into=false group=false - api:T into=false group=false",
  )
}

///|
test "ids must be unique and parents must be groups declared before" {
  inspect(
    model("architecture-beta\nservice a\nservice a"),
    content="semantic: The service id [a] is already in use by another node",
  )
  inspect(
    model("architecture-beta\ngroup a\njunction a"),
    content="semantic: The junction id [a] is already in use by another group",
  )
  inspect(
    model("architecture-beta\ngroup a\ngroup a"),
    content="semantic: The group id [a] is already in use by another group",
  )
  inspect(
    model("architecture-beta\nservice a\ngroup a"),
    content="semantic: The service id [a] is already in use by another group",
  )
  inspect(
    model("architecture-beta\nservice a in g"),
    content="semantic: The service [a]'s parent does not exist. Please make sure the parent is created before this service",
  )
  inspect(
    model("architecture-beta\ngroup g in g"),
    content="semantic: The group [g] cannot be placed within itself",
  )
  inspect(
    model("architecture-beta\nservice a in a"),
    content="semantic: The service [a] cannot be placed within itself",
  )
  inspect(
    model("architecture-beta\njunction j in j"),
    content="semantic: The junction [j] cannot be placed within itself",
  )
  inspect(
    model("architecture-beta\nservice a\nservice b in a"),
    content="semantic: The service [b]'s parent is not a group",
  )
  inspect(
    model("architecture-beta\nservice a\njunction j in a"),
    content="semantic: The junction [j]'s parent is not a group",
  )
  inspect(
    model("architecture-beta\nservice a\ngroup g in a"),
    content="semantic: The group [g]'s parent does not exist. Please make sure the parent is created before this group",
  )
  inspect(
    model("architecture-beta\ngroup h in g\ngroup g"),
    content="semantic: The group [h]'s parent does not exist. Please make sure the parent is created before this group",
  )
  inspect(
    model(
      "architecture-beta\ngroup mermaidPrototypePollutionMarker(cloud)[Marker]\nservice a(server)[A] in __proto__\nservice b(server)[B] in mermaidPrototypePollutionMarker\na:R -- L:b",
    ),
    content="semantic: The service [a]'s parent does not exist. Please make sure the parent is created before this service",
  )
}

///|
test "edges must join declared services or junctions" {
  inspect(
    model("architecture-beta\nservice a\na:R -- L:b"),
    content="semantic: The right-hand id [b] does not yet exist. Please create the service/group before declaring an edge to it.",
  )
  inspect(
    model("architecture-beta\nservice b\na:R -- L:b"),
    content="semantic: The left-hand id [a] does not yet exist. Please create the service/group before declaring an edge to it.",
  )
  inspect(
    model("architecture-beta\ngroup g\nservice a\na:R -- L:g"),
    content="semantic: The right-hand id [g] is a group. Add {group} to a service inside it instead.",
  )
  inspect(
    model("architecture-beta\ngroup g\nservice a\ng:R -- L:a"),
    content="semantic: The left-hand id [g] is a group. Add {group} to a service inside it instead.",
  )
  inspect(
    model(
      "architecture-beta\ngroup g\nservice a in g\nservice b in g\na{group}:R -- L:b",
    ),
    content="semantic: The left-hand id [a] is modified to traverse the group boundary, but the edge does not pass through two groups.",
  )
  inspect(
    model(
      "architecture-beta\ngroup g\nservice a in g\nservice b in g\na:R -- L:b{group}",
    ),
    content="semantic: The right-hand id [b] is modified to traverse the group boundary, but the edge does not pass through two groups.",
  )
  inspect(
    model(
      "architecture-beta\ngroup g\ngroup h\nservice a in g\nservice b in h\na{group}:R -- L:b{group}",
    ),
    content="title=- accTitle=- accDescr=-\ngroup g(-)[-] in -\ngroup h(-)[-] in -\nservice a(-)-[-] in \"g\"\nservice b(-)-[-] in \"h\"\nedge a:R into=false group=true - b:L into=false group=true",
  )
  inspect(
    model("architecture-beta\nservice a\nservice b\na{group}:R -- L:b{group}"),
    content="title=- accTitle=- accDescr=-\nservice a(-)-[-] in -\nservice b(-)-[-] in -\nedge a:R into=false group=true - b:L into=false group=true",
  )
}

///|
test "alignments name distinct services or junctions" {
  inspect(
    model("architecture-beta\nservice a\nservice b\nalign row a b c"),
    content="semantic: align row references [c], which is not a service or junction",
  )
  inspect(
    model("architecture-beta\nservice a\nservice b\nalign column a a"),
    content="semantic: align column lists [a] more than once",
  )
  inspect(
    model("architecture-beta\ngroup g\nservice a\nalign row a g"),
    content="semantic: align row references [g], which is not a service or junction",
  )
  inspect(
    model(
      "architecture-beta\nservice a(server)[A]\nservice b(server)[B]\nalign row a b ghost",
    ),
    content="semantic: align row references [ghost], which is not a service or junction",
  )
  inspect(
    model("architecture-beta\nservice a(server)[A]\nalign row a a"),
    content="semantic: align row lists [a] more than once",
  )
  inspect(
    model(
      "architecture-beta\ngroup api(cloud)[API]\nservice db1(database)[DB1] in api\nservice db2(database)[DB2] in api\nservice db3(database)[DB3] in api\nalign row db1 db2 db3",
    ),
    content="title=- accTitle=- accDescr=-\ngroup api(\"cloud\")[\"API\"] in -\nservice db1(\"database\")-[\"DB1\"] in \"api\"\nservice db2(\"database\")-[\"DB2\"] in \"api\"\nservice db3(\"database\")-[\"DB3\"] in \"api\"\nalign row db1 db2 db3",
  )
}
