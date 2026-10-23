// The expected nodes and edges were taken from pele's graph builder.

///|
fn graph_option(name : String, value : String?) -> String {
  match value {
    Some(text) => " \{name}=\{quote(text)}"
    None => ""
  }
}

///|
/// The drawn graph one node, JSON row or edge a line.
fn graph(source : String) -> String {
  let built = @usecase.build_usecase_graph(@usecase.parse_usecase(source)) catch {
    @errors.PeleError(failure) => return "error: \{failure.message}"
  }
  let out = []
  for n in built.nodes {
    let business = match n.business {
      Some(value) => " business=\{value}"
      None => ""
    }
    out.push(
      "node \{quote(n.id)} \{quote(n.label)} \{n.label_type} \{n.shape}\{flag("group", n.is_group)} padding=\{n.padding} classes=\{quote(n.css_classes)}" +
      list("styles", n.css_styles) +
      list("compiled", n.css_compiled_styles) +
      graph_option("actorType", n.actor_type) +
      business +
      graph_option("icon", n.icon) +
      graph_option("stereotype", n.stereotype) +
      graph_option("parent", n.parent_id) +
      graph_option("noteTarget", n.note_target) +
      graph_option("boundaryType", n.boundary_type),
    )
    for row in n.json_rows.unwrap_or([]) {
      out.push(
        "  row \{quote(row.key)} \{quote(row.accessible_key)} \{quote(row.value)}",
      )
    }
  }
  for e in built.edges {
    out.push(
      "edge \{quote(e.id)} \{quote(e.start)} \{quote(e.end)} \{e.relationship_type} \{e.pattern} \{e.arrow_type_start}/\{e.arrow_type_end}" +
      graph_option("label", e.label) +
      graph_option("labelType", e.label_type) +
      " classes=\{quote(e.classes)}" +
      list("style", e.style) +
      list("compiled", e.css_compiled_styles) +
      flag("animate", e.animate) +
      graph_option("animation", e.animation) +
      " minlen=\{e.minlen}" +
      flag("explicit", e.explicit_id) +
      flag("internal", e.internal),
    )
  }
  out.join("\n")
}

///|
test "build_usecase_graph: actors and use cases as nodes with their shapes and classes" {
  inspect(
    graph(
      "usecase-beta\nactor A\nactor H@{ type: hollow }:::x\nactor W@{ type: awesome }\nactor I@{ icon: \"fa:user\" } <<Bot>>\nactor B@{ business: true }\nU(Use)@{ business: true }\nR[Box]\n\"`**md**`\"",
    ),
    content="node \"A\" \"A\" text usecaseActor padding=10 classes=\"default usecase-actor usecase-actor-normal\" actorType=\"normal\" business=false\nnode \"H\" \"H\" text usecaseActorHollow padding=10 classes=\"default usecase-actor usecase-actor-hollow x\" actorType=\"hollow\" business=false\nnode \"W\" \"W\" text usecaseActorAwesome padding=10 classes=\"default usecase-actor usecase-actor-awesome\" actorType=\"awesome\" business=false\nnode \"I\" \"I\" text usecaseActorIcon padding=10 classes=\"default usecase-actor usecase-actor-icon\" actorType=\"icon\" business=false icon=\"fa:user\" stereotype=\"Bot\"\nnode \"B\" \"B\" text usecaseActor padding=10 classes=\"default usecase-actor usecase-actor-normal usecase-business\" actorType=\"normal\" business=true\nnode \"U\" \"Use\" text usecaseBusiness padding=20 classes=\"default usecase-element usecase-ellipse usecase-business\" business=true\nnode \"R\" \"Box\" text rect padding=10 classes=\"default usecase-element usecase-rect\" business=false\nnode \"__md__\" \"**md**\" markdown usecaseEllipse padding=20 classes=\"default usecase-element usecase-ellipse\" business=false",
  )
}

///|
test "build_usecase_graph: boundaries, notes and their parents" {
  inspect(
    graph(
      "usecase-beta\nsystemBoundary S[\"Shop\"]\n  actor Clerk\n  Pay\nend\nsystemBoundary P@{ type: package }\nend\nP@{ type: package }\nnote for Pay \"Needs a card\"\nnote for Clerk `md`",
    ),
    content="node \"Clerk\" \"Clerk\" text usecaseActor padding=10 classes=\"default usecase-actor usecase-actor-normal\" actorType=\"normal\" business=false parent=\"S\"\nnode \"Pay\" \"Pay\" text usecaseEllipse padding=20 classes=\"default usecase-element usecase-ellipse\" business=false parent=\"S\"\nnode \"note-0\" \"Needs a card\" text note padding=10 classes=\"default usecase-note\" noteTarget=\"Pay\"\nnode \"note-1\" \"`md`\" text note padding=10 classes=\"default usecase-note\" noteTarget=\"Clerk\"\nnode \"S\" \"Shop\" text usecaseSystemBoundary group padding=20 classes=\"default system-boundary system-boundary-rect\" boundaryType=\"rect\"\nnode \"P\" \"P\" text usecaseSystemBoundary group padding=20 classes=\"default system-boundary system-boundary-package\" boundaryType=\"package\"\nedge \"note-0-edge\" \"note-0\" \"Pay\" note dotted none/none classes=\"default relationship relationship-note\" minlen=1 internal\nedge \"note-1-edge\" \"note-1\" \"Clerk\" note dotted none/none classes=\"default relationship relationship-note\" minlen=1 internal",
  )
}

///|
test "build_usecase_graph: JSON tables of every leaf in written order" {
  inspect(
    graph(
      "usecase-beta\njson Payload@{\n  \"2\": \"second\",\n  \"1\": \"first\",\n  \"colors\": [\"Red\", \"Green\"],\n  \"address\": { \"city\": \"Oslo\", \"zip\": null },\n  \"none\": null,\n  \"empty\": {},\n  \"list\": [],\n  \"mixed\": [1, {\"a\": true}, [2, 3]],\n  \"\": {\"\": -0, \"n\": 1e21}\n}",
    ),
    content="node \"Payload\" \"Payload\" text usecaseJsonTable padding=10 classes=\"default usecase-json-table\"\n  row \"2\" \"2\" \"second\"\n  row \"1\" \"1\" \"first\"\n  row \"colors\" \"colors\" \"Red\"\n  row \"\" \"colors\" \"Green\"\n  row \"address.city\" \"address.city\" \"Oslo\"\n  row \"address.zip\" \"address.zip\" \"null\"\n  row \"none\" \"none\" \"null\"\n  row \"empty\" \"empty\" \"{}\"\n  row \"list\" \"list\" \"[]\"\n  row \"mixed[0]\" \"mixed[0]\" \"1\"\n  row \"mixed[1].a\" \"mixed[1].a\" \"true\"\n  row \"mixed[2]\" \"mixed[2]\" \"2\"\n  row \"\" \"mixed[2]\" \"3\"\n  row \"\" \"\" \"0\"\n  row \"n\" \"n\" \"1e+21\"",
  )
  inspect(
    graph("usecase-beta\njson E@{}"),
    content="node \"E\" \"E\" text usecaseJsonTable padding=10 classes=\"default usecase-json-table\"\n  row \"\" \"\" \"{}\"",
  )
}

///|
test "build_usecase_graph: edges with markers, labels and animation" {
  inspect(
    graph(
      "usecase-beta\nA a@--> B\nA b@<-- B\nA c@-- B\nA d@--o B\nA e@o-- B\nA f@--x B\nA g@x-- B\nA -- \"\" --> B\nA -- label --> B",
    ),
    content="node \"A\" \"A\" text usecaseEllipse padding=20 classes=\"default usecase-element usecase-ellipse\" business=false\nnode \"B\" \"B\" text usecaseEllipse padding=20 classes=\"default usecase-element usecase-ellipse\" business=false\nedge \"a\" \"A\" \"B\" association solid none/arrow_point classes=\"default relationship relationship-association\" minlen=1 explicit\nedge \"b\" \"A\" \"B\" association solid arrow_point/none classes=\"default relationship relationship-association\" minlen=1 explicit\nedge \"c\" \"A\" \"B\" association solid none/none classes=\"default relationship relationship-association\" minlen=1 explicit\nedge \"d\" \"A\" \"B\" association solid none/arrow_circle classes=\"default relationship relationship-association\" minlen=1 explicit\nedge \"e\" \"A\" \"B\" association solid arrow_circle/none classes=\"default relationship relationship-association\" minlen=1 explicit\nedge \"f\" \"A\" \"B\" association solid none/arrow_cross classes=\"default relationship relationship-association\" minlen=1 explicit\nedge \"g\" \"A\" \"B\" association solid arrow_cross/none classes=\"default relationship relationship-association\" minlen=1 explicit\nedge \"edge-0\" \"A\" \"B\" association solid none/arrow_point labelType=\"text\" classes=\"default relationship relationship-association\" minlen=1\nedge \"edge-1\" \"A\" \"B\" association solid none/arrow_point label=\"label\" labelType=\"text\" classes=\"default relationship relationship-association\" minlen=1",
  )
  inspect(
    graph(
      "usecase-beta\nA i@..> : include B\nC x@..> : EXTEND D\nactor P\nactor Q\nP g@--|> Q\nA e@--> B\ne@{ animation: slow }\nA f@--> B\nf@{ animate: false }\nA t@--> B\nt@{ animate: true }",
    ),
    content="node \"P\" \"P\" text usecaseActor padding=10 classes=\"default usecase-actor usecase-actor-normal\" actorType=\"normal\" business=false\nnode \"Q\" \"Q\" text usecaseActor padding=10 classes=\"default usecase-actor usecase-actor-normal\" actorType=\"normal\" business=false\nnode \"A\" \"A\" text usecaseEllipse padding=20 classes=\"default usecase-element usecase-ellipse\" business=false\nnode \"B\" \"B\" text usecaseEllipse padding=20 classes=\"default usecase-element usecase-ellipse\" business=false\nnode \"C\" \"C\" text usecaseEllipse padding=20 classes=\"default usecase-element usecase-ellipse\" business=false\nnode \"D\" \"D\" text usecaseEllipse padding=20 classes=\"default usecase-element usecase-ellipse\" business=false\nedge \"i\" \"A\" \"B\" include dotted none/arrow_point label=\"include\" labelType=\"text\" classes=\"default relationship relationship-include\" minlen=1 explicit\nedge \"x\" \"C\" \"D\" extend dotted none/arrow_point label=\"extend\" labelType=\"text\" classes=\"default relationship relationship-extend\" minlen=1 explicit\nedge \"g\" \"P\" \"Q\" generalization solid none/extension classes=\"default relationship relationship-generalization\" minlen=1 explicit\nedge \"e\" \"A\" \"B\" association solid none/arrow_point classes=\"default relationship relationship-association edge-animation-slow\" animate animation=\"slow\" minlen=1 explicit\nedge \"f\" \"A\" \"B\" association solid none/arrow_point classes=\"default relationship relationship-association\" minlen=1 explicit\nedge \"t\" \"A\" \"B\" association solid none/arrow_point classes=\"default relationship relationship-association edge-animation-fast\" animate minlen=1 explicit",
  )
}

///|
test "build_usecase_graph: class definitions compiled into styles" {
  inspect(
    graph(
      "usecase-beta\nactor A:::hot\nU(Use)\nsystemBoundary S\n  V\nend\nA e@--> U\nclassDef hot fill:#fee,stroke:#c33,color:#900\nclassDef default stroke-width:2px\nclassDef cold fill:#00f, stroke : #00a, fill:#0f0\nclass U,S,e hot,cold\nstyle U stroke:#06c\nstyle e stroke-width:4px\njson J@{\"a\":1}:::cold",
    ),
    content="node \"A\" \"A\" text usecaseActor padding=10 classes=\"default usecase-actor usecase-actor-normal hot\" compiled=\"stroke-width:2px\",\"fill:#fee\",\"stroke:#c33\",\"color:#900\" actorType=\"normal\" business=false\nnode \"U\" \"Use\" text usecaseEllipse padding=20 classes=\"default usecase-element usecase-ellipse hot cold\" styles=\"stroke:#06c\" compiled=\"stroke-width:2px\",\"fill:#0f0\",\"stroke : #00a\",\"color:#900\" business=false\nnode \"V\" \"V\" text usecaseEllipse padding=20 classes=\"default usecase-element usecase-ellipse\" compiled=\"stroke-width:2px\" business=false parent=\"S\"\nnode \"J\" \"J\" text usecaseJsonTable padding=10 classes=\"default usecase-json-table cold\" compiled=\"stroke-width:2px\",\"fill:#0f0\",\"stroke : #00a\"\n  row \"a\" \"a\" \"1\"\nnode \"S\" \"S\" text usecaseSystemBoundary group padding=20 classes=\"default system-boundary system-boundary-rect hot cold\" compiled=\"stroke-width:2px\",\"fill:#0f0\",\"stroke : #00a\",\"color:#900\" boundaryType=\"rect\"\nedge \"e\" \"A\" \"U\" association solid none/arrow_point classes=\"default relationship relationship-association hot cold\" style=\"stroke-width:4px\" compiled=\"stroke-width:2px\",\"fill:#0f0\",\"stroke : #00a\",\"color:#900\" minlen=1 explicit",
  )
}
