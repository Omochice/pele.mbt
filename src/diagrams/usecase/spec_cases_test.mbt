// The sources are those Mermaid's use case specs parse, as pele ports them; the expected
// models and messages were taken from pele's parser.

///|
test "Mermaid spec: the diagram parsed before each test" {
  inspect(
    model("usecase-beta\n actor TestActor\n"),
    content="actor \"TestActor\" \"TestActor\" text normal\ndirection LR",
  )
}

///|
test "Mermaid spec: accepts the header at EOF and publishes an empty AST" {
  inspect(model("usecase-beta"), content="direction LR")
}

///|
test "Mermaid spec: publishes accessibility text through common DB and normalized AST transactionally" {
  inspect(
    model(
      "usecase-beta\naccTitle: Authentication use cases\naccDescr {\n  First line\n  Second line\n}\nactor User",
    ),
    content="actor \"User\" \"User\" text normal\ndirection LR\naccTitle \"Authentication use cases\"\naccDescr \"First line\\nSecond line\"",
  )
  inspect(
    model(
      "usecase-beta\naccTitle: Draft title\naccDescr: Draft description\nnote for Missing \"invalid\"",
    ),
    content="error semantic: Note target 'Missing' is unresolved at line 4, column 10 [72,79) @4:10",
  )
}

///|
test "Mermaid spec: accepts a final statement without a newline and keeps end-exclusive source spans" {
  inspect(
    model("usecase-beta\nactor User"),
    content="actor \"User\" \"User\" text normal\ndirection LR",
  )
}

///|
test "Mermaid spec: isolates success, clear, failure, and a second success across singleton reuse" {
  inspect(
    model(
      "usecase-beta\nactor First\nFirst --> Login\nnote for Login \"First note\"",
    ),
    content="actor \"First\" \"First\" text normal\nusecase \"Login\" \"Login\" text ellipse\nrelationship \"edge-0\" \"First\" association/0 \"Login\" minlen=1\nnote \"note-0\" \"Login\" \"First note\" text\ndirection LR",
  )
  inspect(
    model(
      "usecase-beta\nactor Draft\nDraft --> Pending\nnote for Missing \"invalid\"",
    ),
    content="error semantic: Note target 'Missing' is unresolved at line 4, column 10 [52,59) @4:10",
  )
  inspect(
    model(
      "usecase-beta\nactor Second\nSecond --> Done\nnote for Done \"Second note\"",
    ),
    content="actor \"Second\" \"Second\" text normal\nusecase \"Done\" \"Done\" text ellipse\nrelationship \"edge-0\" \"Second\" association/0 \"Done\" minlen=1\nnote \"note-0\" \"Done\" \"Second note\" text\ndirection LR",
  )
}

///|
test "Mermaid spec: resolves forward actor refinement independently of declaration order" {
  inspect(
    model("usecase-beta\nactor User\nUser --> Login"),
    content="actor \"User\" \"User\" text normal\nusecase \"Login\" \"Login\" text ellipse\nrelationship \"edge-0\" \"User\" association/0 \"Login\" minlen=1\ndirection LR",
  )
  inspect(
    model("usecase-beta\nUser --> Login\nactor User"),
    content="actor \"User\" \"User\" text normal\nusecase \"Login\" \"Login\" text ellipse\nrelationship \"edge-0\" \"User\" association/0 \"Login\" minlen=1\ndirection LR",
  )
}

///|
test "Mermaid spec: resolves forward rectangular use case refinement independently of declaration order" {
  inspect(
    model("usecase-beta\nLogin[Sign in]\nUser --> Login"),
    content="usecase \"Login\" \"Sign in\" text rect\nusecase \"User\" \"User\" text ellipse\nrelationship \"edge-0\" \"User\" association/0 \"Login\" minlen=1\ndirection LR",
  )
  inspect(
    model("usecase-beta\nUser --> Login\nLogin[Sign in]"),
    content="usecase \"User\" \"User\" text ellipse\nusecase \"Login\" \"Sign in\" text rect\nrelationship \"edge-0\" \"User\" association/0 \"Login\" minlen=1\ndirection LR",
  )
}

///|
test "Mermaid spec: finalizes unresolved relation endpoints as ellipse use cases without actor inference" {
  inspect(
    model("usecase-beta\nLeft --> Right"),
    content="usecase \"Left\" \"Left\" text ellipse\nusecase \"Right\" \"Right\" text ellipse\nrelationship \"edge-0\" \"Left\" association/0 \"Right\" minlen=1\ndirection LR",
  )
}

///|
test "Mermaid spec: merges equivalent repeated declarations, including equivalent parent ownership" {
  inspect(
    model(
      "usecase-beta\nsystemBoundary Auth\nactor User(\"Person\")@{ type: hollow } <<Human>>\nactor User(\"Person\")@{ type: hollow } <<Human>>\nLogin[Sign in] <<Primary>>\nLogin[Sign in] <<Primary>>\nend",
    ),
    content="actor \"User\" \"Person\" text hollow stereotype=\"Human\" parent=\"Auth\"\nusecase \"Login\" \"Sign in\" text rect stereotype=\"Primary\" parent=\"Auth\"\nboundary \"Auth\" \"Auth\" text rect members=\"User\",\"Login\"\ndirection LR",
  )
}

///|
test "Mermaid spec: rejects conflicting kind declarations transactionally" {
  inspect(
    model("usecase-beta\nactor Shared\nShared"),
    content="error semantic: ID 'Shared' is declared as both actor and usecase at line 3, column 1 [26,32); previous declaration at line 2, column 7 [19,25) @3:1",
  )
}

///|
test "Mermaid spec: rejects conflicting shape declarations transactionally" {
  inspect(
    model("usecase-beta\nLogin(Sign in)\nLogin[Sign in]"),
    content="error semantic: Use case 'Login' has conflicting shapes at line 3, column 1 [28,33); previous declaration at line 2, column 1 [13,18) @3:1",
  )
}

///|
test "Mermaid spec: rejects conflicting label declarations transactionally" {
  inspect(
    model("usecase-beta\nLogin(First label)\nLogin(Second label)"),
    content="error semantic: ID 'Login' has conflicting labels at line 3, column 1 [32,37); previous declaration at line 2, column 1 [13,18) @3:1",
  )
}

///|
test "Mermaid spec: rejects conflicting stereotype declarations transactionally" {
  inspect(
    model("usecase-beta\nLogin <<Primary>>\nLogin <<Secondary>>"),
    content="error semantic: Element 'Login' has conflicting stereotypes at line 3, column 1 [31,36); previous declaration at line 2, column 1 [13,18) @3:1",
  )
}

///|
test "Mermaid spec: rejects conflicting parent declarations transactionally" {
  inspect(
    model(
      "usecase-beta\nsystemBoundary First\nLogin\nend\nsystemBoundary Second\nLogin\nend",
    ),
    content="error semantic: Element 'Login' belongs to more than one system boundary at line 5, column 16 [59,65); previous declaration at line 2, column 16 [28,33) @5:16",
  )
}

///|
test "Mermaid spec: rejects a generated ID collision in the diagram-global namespace" {
  inspect(
    model("usecase-beta\n\"A-B\"\n\"A B\""),
    content="error semantic: Generated ID 'A_B' collides with another declaration at line 3, column 2 [20,23) (label \"A B\"); previous declaration at line 2, column 2 [14,17) (label \"A-B\") @3:2",
  )
}

///|
test "Mermaid spec: rejects a generated and explicit ID collision in the diagram-global namespace" {
  inspect(
    model("usecase-beta\n\"A B\"\nA_B(Explicit)"),
    content="error semantic: Generated ID 'A_B' collides with another declaration at line 3, column 1 [19,22); previous declaration at line 2, column 2 [14,17) (label \"A B\") @3:1",
  )
}

///|
test "Mermaid spec: rejects a global cross-kind ID collision in the diagram-global namespace" {
  inspect(
    model("usecase-beta\nactor Shared\njson Shared@{}"),
    content="error semantic: ID 'Shared' is declared more than once (actor and json) at line 3, column 6 [31,37); previous declaration at line 2, column 7 [19,25) @3:6",
  )
}

///|
test "Mermaid spec: rejects a element and explicit edge ID collision in the diagram-global namespace" {
  inspect(
    model("usecase-beta\nactor link\nA link@--> B"),
    content="error semantic: ID 'link' is declared more than once (actor and edge) at line 3, column 3 [26,30); previous declaration at line 2, column 7 [19,23) @3:3",
  )
}

///|
test "Mermaid spec: rejects a duplicate explicit edge ID collision in the diagram-global namespace" {
  inspect(
    model("usecase-beta\nA link@--> B\nB link@--> C"),
    content="error semantic: ID 'link' is declared more than once (edge and edge) at line 3, column 3 [28,32); previous declaration at line 2, column 3 [15,19) @3:3",
  )
}

///|
test "Mermaid spec: rejects an unresolved note target" {
  inspect(
    model("usecase-beta\nnote for Ghost \"Missing\""),
    content="error semantic: Note target 'Ghost' is unresolved at line 2, column 10 [22,27) @2:10",
  )
}

///|
test "Mermaid spec: rejects an unresolved class target" {
  inspect(
    model("usecase-beta\nclass Ghost important"),
    content="error semantic: Class/style target 'Ghost' is unresolved or anonymous at line 2, column 7 [19,24) @2:7",
  )
}

///|
test "Mermaid spec: rejects an unresolved style target" {
  inspect(
    model("usecase-beta\nstyle Ghost fill:red"),
    content="error semantic: Class/style target 'Ghost' is unresolved or anonymous at line 2, column 7 [19,24) @2:7",
  )
}

///|
test "Mermaid spec: rejects an unresolved metadata target" {
  inspect(
    model("usecase-beta\nGhost@{ type: package }"),
    content="error semantic: Metadata target 'Ghost' is unresolved (metadata implies boundary) at line 2, column 1 [13,18) @2:1",
  )
}

///|
test "Mermaid spec: publishes no draft collection or AST when final semantic resolution fails" {
  inspect(
    model("usecase-beta\nactor Previous\nPrevious --> Published"),
    content="actor \"Previous\" \"Previous\" text normal\nusecase \"Published\" \"Published\" text ellipse\nrelationship \"edge-0\" \"Previous\" association/0 \"Published\" minlen=1\ndirection LR",
  )
  inspect(
    model(
      "usecase-beta\ndirection TB\nclassDef important fill:red\nactor User:::important\nLogin[Sign in]\nUser link@--> Login\nlink@{ animation: fast }\njson Payload@{\"ok\": true}\nnote for Missing \"late failure\"",
    ),
    content="error semantic: Note target 'Missing' is unresolved at line 9, column 10 [172,179) @9:10",
  )
}

///|
test "Mermaid spec: allocates anonymous edge and note IDs deterministically in source order" {
  inspect(
    model(
      "usecase-beta\nactor User\nUser --> Login\nnote for User \"first\"\nLogin --> Logout\nnote for Logout \"second\"",
    ),
    content="actor \"User\" \"User\" text normal\nusecase \"Login\" \"Login\" text ellipse\nusecase \"Logout\" \"Logout\" text ellipse\nrelationship \"edge-0\" \"User\" association/0 \"Login\" minlen=1\nrelationship \"edge-1\" \"Login\" association/0 \"Logout\" minlen=1\nnote \"note-0\" \"User\" \"first\" text\nnote \"note-1\" \"Logout\" \"second\" text\ndirection LR",
  )
}

///|
test "Mermaid spec: distinguishes generated and explicit IDs and records their exact occurrences" {
  inspect(
    model("usecase-beta\n\"Reset password\"\nLogin(\"Reset password\")"),
    content="usecase \"Reset_password\" \"Reset password\" text ellipse\nusecase \"Login\" \"Reset password\" text ellipse\ndirection LR",
  )
}

///|
test "Mermaid spec: names both exact locations and the source labels for generated and explicit ID collisions" {
  inspect(
    model("usecase-beta\nactor \"A-B\"\n\"A B\""),
    content="error semantic: ID 'A_B' is declared as both actor and usecase at line 3, column 2 [26,29) (label \"A B\"); previous declaration at line 2, column 8 [20,23) (label \"A-B\") @3:2",
  )
  inspect(
    model(
      "usecase-beta\nsystemBoundary \"A-B\"\nend\nsystemBoundary \"A B\"\nend",
    ),
    content="error semantic: Generated ID 'A_B' collides with another declaration at line 4, column 17 [54,57) (label \"A B\"); previous declaration at line 2, column 17 [29,32) (label \"A-B\") @4:17",
  )
}

///|
test "Mermaid spec: preserves entity codes and literal backslash-n while accepting physical newlines only in Markdown labels" {
  inspect(
    model(
      "usecase-beta\nclassDef decorated fill:#fee\nactor User(\"`**User**\nrole`\") <<Human>>:::decorated\nLogin(\"`Sign\nin`\") <<Primary>>:::decorated\nEscaped(\"Open #40;safe#41; #91;now#93;\")\nLiteral(\"First\\nSecond\")",
    ),
    content="actor \"User\" \"**User**\\nrole\" markdown normal stereotype=\"Human\" classes=\"decorated\"\nusecase \"Login\" \"Sign\\nin\" markdown ellipse stereotype=\"Primary\" classes=\"decorated\"\nusecase \"Escaped\" \"Open #40;safe#41; #91;now#93;\" text ellipse\nusecase \"Literal\" \"First\\\\nSecond\" text ellipse\nclassDef \"decorated\" styles=\"fill:#fee\"\ndirection LR",
  )
  inspect(
    model("usecase-beta\nBroken(\"First\nSecond\")"),
    content="error syntax: Error lexing usecase diagram: unexpected character: ->\"<- at offset: 20, skipped 1 characters. at line 2, column 8 [20,21) @2:8",
  )
}

///|
test "Mermaid spec: accepts markdown markers, punctuation, and non-ASCII characters in unquoted labels" {
  inspect(
    model(
      "usecase-beta\nactor Reviewer(*Reviewer*)\nLiteral(**Literal markers**)\nPriced[Costs 19.95 EUR, incl. VAT!]\nProgress(Ärende — 50% klart)\nReviewer -- opens **form** --> Literal\nReviewer --> Priced\nReviewer --> Progress\nnote for Literal Read the guide; then sign off.",
    ),
    content="actor \"Reviewer\" \"*Reviewer*\" text normal\nusecase \"Literal\" \"**Literal markers**\" text ellipse\nusecase \"Priced\" \"Costs 19.95 EUR, incl. VAT!\" text rect\nusecase \"Progress\" \"Ärende — 50% klart\" text ellipse\nrelationship \"edge-0\" \"Reviewer\" association/0 \"Literal\" minlen=1 label=\"opens **form**\" text\nrelationship \"edge-1\" \"Reviewer\" association/0 \"Priced\" minlen=1\nrelationship \"edge-2\" \"Reviewer\" association/0 \"Progress\" minlen=1\nnote \"note-0\" \"Literal\" \"Read the guide; then sign off.\" text\ndirection LR",
  )
}

///|
test "Mermaid spec: still rejects a parenthesis inside an unquoted label" {
  inspect(
    model("usecase-beta\nLiteral(Literal (nested) markers)"),
    content="error syntax: Error parsing usecase diagram: Expecting token of type --> RPAREN <-- but found --> '(' <-- at line 2, column 17 [29,30) @2:17",
  )
}

///|
test "Mermaid spec: still rejects a bracket inside an unquoted label" {
  inspect(
    model("usecase-beta\nLiteral[Literal [nested] markers]"),
    content="error syntax: Error parsing usecase diagram: Expecting token of type --> RBRACKET <-- but found --> '[' <-- at line 2, column 17 [29,30) @2:17",
  )
}

///|
test "Mermaid spec: still rejects a brace inside an unquoted label" {
  inspect(
    model("usecase-beta\nLiteral(Literal {nested} markers)"),
    content="error syntax: Error parsing usecase diagram: Expecting token of type --> RPAREN <-- but found --> '{' <-- at line 2, column 17 [29,30) @2:17",
  )
}

///|
test "Mermaid spec: still rejects a relationship operator inside an unquoted label" {
  inspect(
    model("usecase-beta\nLiteral(Literal -- markers)"),
    content="error syntax: Error parsing usecase diagram: Expecting token of type --> RPAREN <-- but found --> '--' <-- at line 2, column 17 [29,31) @2:17",
  )
}

///|
test "Mermaid spec: still rejects the class suffix inside an unquoted label" {
  inspect(
    model("usecase-beta\nLiteral(Literal ::: markers)"),
    content="error syntax: Error parsing usecase diagram: Expecting token of type --> RPAREN <-- but found --> ':::' <-- at line 2, column 17 [29,32) @2:17",
  )
}

///|
test "Mermaid spec: still rejects the metadata suffix inside an unquoted label" {
  inspect(
    model("usecase-beta\nLiteral(Literal @{ markers)"),
    content="error syntax: Error parsing usecase diagram: Expecting token of type --> RPAREN <-- but found --> '@{' <-- at line 2, column 17 [29,31) @2:17",
  )
}

///|
test "Mermaid spec: still rejects a double quote inside an unquoted label" {
  inspect(
    model("usecase-beta\nLiteral(Literal \"markers)"),
    content="error syntax: Error lexing usecase diagram: unexpected character: ->\"<- at offset: 29, skipped 1 characters. at line 2, column 17 [29,30) @2:17",
  )
}

///|
test "Mermaid spec: still rejects a single quote inside an unquoted label" {
  inspect(
    model("usecase-beta\nLiteral(Reviewer's markers)"),
    content="error syntax: Error lexing usecase diagram: unexpected character: ->'<- at offset: 29, skipped 1 characters. at line 2, column 17 [29,30) @2:17",
  )
}

///|
test "Mermaid spec: reports exact actor metadata and incompatible icon locations" {
  inspect(
    model("usecase-beta\nactor User@{ type: giant }"),
    content="error semantic: Metadata property 'type' is invalid for actor 'User' at line 2, column 14 [26,30) @2:14",
  )
  inspect(
    model("usecase-beta\nactor User@{ fillColor: red }"),
    content="error semantic: Metadata property 'fillColor' is invalid for actor 'User' at line 2, column 14 [26,35) @2:14",
  )
  inspect(
    model("usecase-beta\nactor User@{ icon: \"fa:user\", type: awesome }"),
    content="error semantic: Actor 'User' cannot combine icon with type 'awesome' at line 2, column 7 [19,23) @2:7",
  )
}

///|
test "Mermaid spec: rejects mixed-kind generalization and actor include at the exact relation span" {
  inspect(
    model("usecase-beta\nactor User\nLogin\nUser --|> Login"),
    content="error semantic: Generalization requires actor-to-actor or use-case-to-use-case endpoints at line 4, column 6 [35,45) @4:6",
  )
  inspect(
    model("usecase-beta\nactor User\nactor Admin\nUser ..> : include Admin"),
    content="error semantic: include relationship requires use-case endpoints at line 4, column 6 [41,60) @4:6",
  )
}

///|
test "Mermaid spec: rejects duplicate and unknown edge class/style targets with exact locations" {
  inspect(
    model("usecase-beta\nA known@--> B\nclass missingEdge decorated"),
    content="error semantic: Class/style target 'missingEdge' is unresolved or anonymous at line 3, column 7 [33,44) @3:7",
  )
  inspect(
    model("usecase-beta\nA known@--> B\nstyle missingEdge stroke:red"),
    content="error semantic: Class/style target 'missingEdge' is unresolved or anonymous at line 3, column 7 [33,44) @3:7",
  )
}

///|
test "Mermaid spec: publishes exact true, fast, slow, and false animation state and rejects invalid values" {
  inspect(
    model(
      "usecase-beta\nA trueEdge@--> B\ntrueEdge@{ animate: true }\nA fastEdge@--> B\nfastEdge@{ animation: fast }\nA slowEdge@--> B\nslowEdge@{ animation: slow }\nA offEdge@--> B\noffEdge@{ animate: false }",
    ),
    content="usecase \"A\" \"A\" text ellipse\nusecase \"B\" \"B\" text ellipse\nrelationship \"trueEdge\" explicit \"A\" association/0 \"B\" minlen=1 animate\nrelationship \"fastEdge\" explicit \"A\" association/0 \"B\" minlen=1 animate animation=fast\nrelationship \"slowEdge\" explicit \"A\" association/0 \"B\" minlen=1 animate animation=slow\nrelationship \"offEdge\" explicit \"A\" association/0 \"B\" minlen=1\ndirection LR",
  )
  inspect(
    model("usecase-beta\nA link@--> B\nlink@{ animation: medium }"),
    content="error semantic: Metadata property 'animation' is invalid for edge 'link' at line 3, column 8 [33,42) @3:8",
  )
  inspect(
    model("usecase-beta\nA link@--> B\nlink@{ animate: fast }"),
    content="error semantic: Metadata property 'animate' is invalid for edge 'link' at line 3, column 8 [33,40) @3:8",
  )
}

///|
test "Mermaid spec: locates rejected relation content inside a boundary" {
  inspect(
    model("usecase-beta\nsystemBoundary Auth\nUser --> Login\nend"),
    content="error syntax: Error parsing usecase diagram: Expecting: one of these possible Token sequences:\n  1. [NEWLINE]\n  2. [EOF]\nbut found: '-->' at line 3, column 6 [38,41) @3:6",
  )
}

///|
test "Mermaid spec: locates rejected note content inside a boundary" {
  inspect(
    model("usecase-beta\nsystemBoundary Auth\nnote for User \"inside\"\nend"),
    content="error syntax: Error parsing usecase diagram: Expecting token of type --> END <-- but found --> 'note' <-- at line 3, column 1 [33,37) @3:1",
  )
}

///|
test "Mermaid spec: locates rejected JSON content inside a boundary" {
  inspect(
    model("usecase-beta\nsystemBoundary Auth\njson Payload@{}\nend"),
    content="error syntax: Error parsing usecase diagram: Expecting token of type --> END <-- but found --> 'json Payload@' <-- at line 3, column 1 [33,46) @3:1",
  )
}

///|
test "Mermaid spec: locates rejected nested boundary content inside a boundary" {
  inspect(
    model("usecase-beta\nsystemBoundary Auth\nsystemBoundary Nested\nend\nend"),
    content="error syntax: Error parsing usecase diagram: Expecting token of type --> END <-- but found --> 'systemBoundary' <-- at line 3, column 1 [33,47) @3:1",
  )
}

///|
test "Mermaid spec: rejects notes targeting JSON, boundary, and explicit edge IDs with both locations" {
  inspect(
    model("usecase-beta\njson Payload@{}\nnote for Payload \"invalid\""),
    content="error semantic: Note target 'Payload' must be an actor or use case, not json at line 3, column 10 [38,45); previous declaration at line 2, column 6 [18,25) @3:10",
  )
  inspect(
    model(
      "usecase-beta\nsystemBoundary Auth\nLogin\nend\nnote for Auth \"invalid\"",
    ),
    content="error semantic: Note target 'Auth' must be an actor or use case, not boundary at line 5, column 10 [52,56); previous declaration at line 2, column 16 [28,32) @5:10",
  )
  inspect(
    model("usecase-beta\nA link@--> B\nnote for link \"invalid\""),
    content="error semantic: Note target 'link' must be an actor or use case, not edge at line 3, column 10 [35,39); previous declaration at line 2, column 3 [15,19) @3:10",
  )
}

///|
test "Mermaid spec: locates a stereotype on invalid boundary syntax" {
  inspect(
    model("usecase-beta\nsystemBoundary Auth <<System>>\nLogin\nend"),
    content="error syntax: Error parsing usecase diagram: Expecting: one of these possible Token sequences:\n  1. [NEWLINE]\n  2. [EOF]\nbut found: '<<' at line 2, column 21 [33,35) @2:21",
  )
}

///|
test "Mermaid spec: locates a stereotype on invalid note syntax" {
  inspect(
    model("usecase-beta\nLogin\nnote for Login \"text\" <<Memo>>"),
    content="error syntax: Error parsing usecase diagram: Expecting: one of these possible Token sequences:\n  1. [NEWLINE]\n  2. [EOF]\nbut found: '<<' at line 3, column 23 [41,43) @3:23",
  )
}

///|
test "Mermaid spec: locates a stereotype on invalid JSON syntax" {
  inspect(
    model("usecase-beta\njson Payload@{} <<Data>>"),
    content="error syntax: Error parsing usecase diagram: Expecting: one of these possible Token sequences:\n  1. [NEWLINE]\n  2. [EOF]\nbut found: '<<' at line 2, column 17 [29,31) @2:17",
  )
}

///|
test "Mermaid spec: locates a stereotype on invalid edge syntax" {
  inspect(
    model("usecase-beta\nA link@--> B\nlink@{ animate: true } <<Link>>"),
    content="error syntax: Error parsing usecase diagram: Expecting: one of these possible Token sequences:\n  1. [NEWLINE]\n  2. [EOF]\nbut found: '<<' at line 3, column 24 [49,51) @3:24",
  )
}

///|
test "Mermaid spec: locates an unterminated declaration at the end of input" {
  inspect(
    model("usecase-beta\nactor"),
    content="error syntax: Error parsing usecase diagram: Expecting: one of these possible Token sequences:\n  1. [IDENTIFIER]\n  2. [PLAIN_STRING]\n  3. [MARKDOWN_STRING]\nbut found: '' at line 2, column 6 [18,18) @2:6",
  )
}

///|
test "Mermaid spec: locates an unterminated edge at the end of input" {
  inspect(
    model("usecase-beta\nA -->"),
    content="error syntax: Error parsing usecase diagram: Expecting: one of these possible Token sequences:\n  1. [IDENTIFIER]\n  2. [PLAIN_STRING]\n  3. [MARKDOWN_STRING]\nbut found: '' at line 2, column 6 [18,18) @2:6",
  )
}

///|
test "Mermaid spec: rejects business icon, awesome, and rectangular declarations at exact locations" {
  inspect(
    model("usecase-beta\nactor Icon@{ icon: \"fa:user\", business: true }"),
    content="error semantic: Business actor 'Icon' must use normal or hollow geometry at line 2, column 7 [19,23) @2:7",
  )
  inspect(
    model("usecase-beta\nactor Awesome@{ type: awesome, business: true }"),
    content="error semantic: Business actor 'Awesome' must use normal or hollow geometry at line 2, column 7 [19,26) @2:7",
  )
  inspect(
    model("usecase-beta\nReport[Generate report]@{ business: true }"),
    content="error semantic: Rectangular use case 'Report' cannot be a business use case at line 2, column 1 [13,19) @2:1",
  )
}

///|
test "Mermaid spec: rejects JSON in boundaries and JSON semantic or circle relations at exact locations" {
  inspect(
    model(
      "usecase-beta\njson Payload@{}\nInspect\nPayload ..> : include Inspect",
    ),
    content="error semantic: include relationship requires use-case endpoints at line 4, column 9 [45,66) @4:9",
  )
  inspect(
    model("usecase-beta\njson Payload@{}\nInspect --o Payload"),
    content="error semantic: JSON relationship 'Inspect' to 'Payload' permits only point, reversed-point, or markerless solid association at line 3, column 9 [37,48) @3:9",
  )
}

///|
test "Mermaid spec: declares a boundary with an explicit id, a label, inline metadata, and classes" {
  inspect(
    model(
      "usecase-beta\nclassDef system fill:#f8f8ff\nsystemBoundary sb1[\"Payment service\"]@{ type: package }:::system\n  actor Clerk(\"Payment clerk\")\n  Authorize(\"Authorize payment\")\nend\nClerk --> Authorize",
    ),
    content="actor \"Clerk\" \"Payment clerk\" text normal parent=\"sb1\"\nusecase \"Authorize\" \"Authorize payment\" text ellipse parent=\"sb1\"\nboundary \"sb1\" \"Payment service\" text package members=\"Clerk\",\"Authorize\" classes=\"system\"\nrelationship \"edge-0\" \"Clerk\" association/0 \"Authorize\" minlen=1\nclassDef \"system\" styles=\"fill:#f8f8ff\"\ndirection LR",
  )
}

///|
test "Mermaid spec: accepts a bracketed text boundary label" {
  inspect(
    model(
      "usecase-beta\nsystemBoundary sb1[Payment service]\nAuthorize(\"Authorize payment\")\nend",
    ),
    content="usecase \"Authorize\" \"Authorize payment\" text ellipse parent=\"sb1\"\nboundary \"sb1\" \"Payment service\" text rect members=\"Authorize\"\ndirection LR",
  )
}

///|
test "Mermaid spec: accepts a bracketed plain string boundary label" {
  inspect(
    model(
      "usecase-beta\nsystemBoundary sb1[\"Payment service\"]\nAuthorize(\"Authorize payment\")\nend",
    ),
    content="usecase \"Authorize\" \"Authorize payment\" text ellipse parent=\"sb1\"\nboundary \"sb1\" \"Payment service\" text rect members=\"Authorize\"\ndirection LR",
  )
}

///|
test "Mermaid spec: accepts a bracketed Markdown string boundary label" {
  inspect(
    model(
      "usecase-beta\nsystemBoundary sb1[\"`**Payment** service`\"]\nAuthorize(\"Authorize payment\")\nend",
    ),
    content="usecase \"Authorize\" \"Authorize payment\" text ellipse parent=\"sb1\"\nboundary \"sb1\" \"**Payment** service\" markdown rect members=\"Authorize\"\ndirection LR",
  )
}

///|
test "Mermaid spec: accepts a parenthesized text boundary label" {
  inspect(
    model(
      "usecase-beta\nsystemBoundary sb1(Payment service)\nAuthorize(\"Authorize payment\")\nend",
    ),
    content="usecase \"Authorize\" \"Authorize payment\" text ellipse parent=\"sb1\"\nboundary \"sb1\" \"Payment service\" text rect members=\"Authorize\"\ndirection LR",
  )
}

///|
test "Mermaid spec: accepts a parenthesized plain string boundary label" {
  inspect(
    model(
      "usecase-beta\nsystemBoundary sb1(\"Payment service\")\nAuthorize(\"Authorize payment\")\nend",
    ),
    content="usecase \"Authorize\" \"Authorize payment\" text ellipse parent=\"sb1\"\nboundary \"sb1\" \"Payment service\" text rect members=\"Authorize\"\ndirection LR",
  )
}

///|
test "Mermaid spec: accepts a parenthesized Markdown string boundary label" {
  inspect(
    model(
      "usecase-beta\nsystemBoundary sb1(\"`**Payment** service`\")\nAuthorize(\"Authorize payment\")\nend",
    ),
    content="usecase \"Authorize\" \"Authorize payment\" text ellipse parent=\"sb1\"\nboundary \"sb1\" \"**Payment** service\" markdown rect members=\"Authorize\"\ndirection LR",
  )
}

///|
test "Mermaid spec: keeps plain ids, derived ids, and separate metadata statements working" {
  inspect(
    model(
      "usecase-beta\nclassDef system fill:#f8f8ff\nsystemBoundary \"Payment service\":::system\n  Authorize(\"Authorize payment\")\nend\nsystemBoundary Billing\n  Invoice[Create invoice]\nend\nPayment_service@{ type: package }",
    ),
    content="usecase \"Authorize\" \"Authorize payment\" text ellipse parent=\"Payment_service\"\nusecase \"Invoice\" \"Create invoice\" text rect parent=\"Billing\"\nboundary \"Payment_service\" \"Payment service\" text package members=\"Authorize\" classes=\"system\"\nboundary \"Billing\" \"Billing\" text rect members=\"Invoice\"\nclassDef \"system\" styles=\"fill:#f8f8ff\"\ndirection LR",
  )
}

///|
test "Mermaid spec: lets a later metadata statement override inline boundary metadata" {
  inspect(
    model(
      "usecase-beta\nsystemBoundary \"Payment service\"@{ type: package }\n  Authorize(\"Authorize payment\")\nend\nPayment_service@{ type: rect }",
    ),
    content="usecase \"Authorize\" \"Authorize payment\" text ellipse parent=\"Payment_service\"\nboundary \"Payment_service\" \"Payment service\" text rect members=\"Authorize\"\ndirection LR",
  )
}

///|
test "Mermaid spec: records the boundary id, title, and inline metadata spans in the AST" {
  inspect(
    model(
      "usecase-beta\nsystemBoundary sb1[\"Payment service\"]@{ type: package }\nAuthorize(\"Authorize payment\")\nend",
    ),
    content="usecase \"Authorize\" \"Authorize payment\" text ellipse parent=\"sb1\"\nboundary \"sb1\" \"Payment service\" text package members=\"Authorize\"\ndirection LR",
  )
}

///|
test "Mermaid spec: requires inline boundary metadata before the class suffix" {
  inspect(
    model(
      "usecase-beta\nsystemBoundary sb1:::system@{ type: package }\nAuthorize(\"Authorize payment\")\nend\nclassDef system fill:#f8f8ff",
    ),
    content="error syntax: Error parsing usecase diagram: Expecting: one of these possible Token sequences:\n  1. [NEWLINE]\n  2. [EOF]\nbut found: '@{' at line 2, column 28 [40,42) @2:28",
  )
}

///|
test "Mermaid spec: rejects inline boundary metadata that a boundary does not accept" {
  inspect(
    model(
      "usecase-beta\nsystemBoundary sb1[\"Payment service\"]@{ animate: true }\nAuthorize(\"Authorize payment\")\nend",
    ),
    content="error semantic: Metadata property 'animate' is invalid for boundary 'sb1' at line 2, column 41 [53,60) @2:41",
  )
}

///|
test "Mermaid spec: publishes a complete serializable AST v1 with ordered statements and exact spans" {
  inspect(
    model(
      "usecase-beta\n\n%% representative\nsystemBoundary Auth\nactor User@{ type: hollow } <<Human>>\nLogin[Sign in]\nend\nAuth@{ type: package }\njson Payload@{\"ok\": true}\nLogin includeEdge@..> : include Login\nincludeEdge@{ animation: fast }\nnote for Login \"Remember\"",
    ),
    content="actor \"User\" \"User\" text hollow stereotype=\"Human\" parent=\"Auth\"\nusecase \"Login\" \"Sign in\" text rect parent=\"Auth\"\nboundary \"Auth\" \"Auth\" text package members=\"User\",\"Login\"\nrelationship \"includeEdge\" explicit \"Login\" include/0 \"Login\" minlen=1 label=\"include\" text animate animation=fast\nnote \"note-0\" \"Login\" \"Remember\" text\njson \"Payload\" {\"ok\":true}\ndirection LR",
  )
}

///|
test "Mermaid spec: locates the JSON id o even when it is a substring of the json keyword" {
  inspect(
    model("usecase-beta\njson o @{\"a\": 1}"),
    content="json \"o\" {\"a\":1}\ndirection LR",
  )
}

///|
test "Mermaid spec: locates the JSON id n even when it is a substring of the json keyword" {
  inspect(
    model("usecase-beta\njson n @{\"a\": 1}"),
    content="json \"n\" {\"a\":1}\ndirection LR",
  )
}

///|
test "Mermaid spec: locates the JSON id s even when it is a substring of the json keyword" {
  inspect(
    model("usecase-beta\njson s @{\"a\": 1}"),
    content="json \"s\" {\"a\":1}\ndirection LR",
  )
}

///|
test "Mermaid spec: locates the JSON id j even when it is a substring of the json keyword" {
  inspect(
    model("usecase-beta\njson j @{\"a\": 1}"),
    content="json \"j\" {\"a\":1}\ndirection LR",
  )
}

///|
test "Mermaid spec: locates the JSON id jo even when it is a substring of the json keyword" {
  inspect(
    model("usecase-beta\njson jo @{\"a\": 1}"),
    content="json \"jo\" {\"a\":1}\ndirection LR",
  )
}

///|
test "Mermaid spec: locates the JSON id so even when it is a substring of the json keyword" {
  inspect(
    model("usecase-beta\njson so @{\"a\": 1}"),
    content="json \"so\" {\"a\":1}\ndirection LR",
  )
}

///|
test "Mermaid spec: locates the JSON id on even when it is a substring of the json keyword" {
  inspect(
    model("usecase-beta\njson on @{\"a\": 1}"),
    content="json \"on\" {\"a\":1}\ndirection LR",
  )
}

///|
test "Mermaid spec: locates the JSON id son even when it is a substring of the json keyword" {
  inspect(
    model("usecase-beta\njson son @{\"a\": 1}"),
    content="json \"son\" {\"a\":1}\ndirection LR",
  )
}

///|
test "Mermaid spec: locates the JSON id json even when it is a substring of the json keyword" {
  inspect(
    model("usecase-beta\njson json @{\"a\": 1}"),
    content="json \"json\" {\"a\":1}\ndirection LR",
  )
}

///|
test "Mermaid spec: preserves the separators inside multi-word style and classDef values" {
  inspect(
    model(
      "usecase-beta\nCheckout(\"Place order\")\nclassDef big font-family:Arial Black\nstyle Checkout border:1px solid red,fill:#eee",
    ),
    content="usecase \"Checkout\" \"Place order\" text ellipse styles=\"border:1px solid red\",\"fill:#eee\"\nclassDef \"big\" styles=\"font-family:Arial Black\"\ndirection LR",
  )
}

///|
test "Mermaid spec: reports the source position of a lexer failure" {
  inspect(
    model("usecase-beta\nactor \"Bob"),
    content="error syntax: Error lexing usecase diagram: unexpected character: ->\"<- at offset: 19, skipped 1 characters. at line 2, column 7 [19,20) @2:7",
  )
}

///|
test "Mermaid spec: accepts ids that start with a digit" {
  inspect(
    model(
      "usecase-beta\nactor 1(\"Customer\")\nactor 1mg(\"Milligram\")\n2(\"Place order\")\n3rd(\"Third party\")\n1 --> 2\n1mg --> 3rd\njson 4 @{\"a\": 1}\n2 --> 4",
    ),
    content="actor \"1\" \"Customer\" text normal\nactor \"1mg\" \"Milligram\" text normal\nusecase \"2\" \"Place order\" text ellipse\nusecase \"3rd\" \"Third party\" text ellipse\nrelationship \"edge-0\" \"1\" association/0 \"2\" minlen=1\nrelationship \"edge-1\" \"1mg\" association/0 \"3rd\" minlen=1\nrelationship \"edge-2\" \"2\" association/0 \"4\" minlen=1\njson \"4\" {\"a\":1}\ndirection LR",
  )
}

///|
test "Mermaid spec: keeps decimal style values intact now that ids may start with a digit" {
  inspect(
    model(
      "usecase-beta\nA(\"x\")\nstyle A stroke-width:1.5px,opacity:0.5,margin:2",
    ),
    content="usecase \"A\" \"x\" text ellipse styles=\"stroke-width:1.5px\",\"opacity:0.5\",\"margin:2\"\ndirection LR",
  )
}

///|
test "Mermaid spec: should parse a single actor" {
  inspect(
    model("usecase-beta\n        actor User\n"),
    content="actor \"User\" \"User\" text normal\ndirection LR",
  )
}

///|
test "Mermaid spec: should parse multiple actors" {
  inspect(
    model(
      "usecase-beta\n        actor User\n        actor Admin\n        actor Guest\n",
    ),
    content="actor \"User\" \"User\" text normal\nactor \"Admin\" \"Admin\" text normal\nactor \"Guest\" \"Guest\" text normal\ndirection LR",
  )
}

///|
test "Mermaid spec: should parse actor with simple name" {
  inspect(
    model("usecase-beta\n        actor SystemUser\n"),
    content="actor \"SystemUser\" \"SystemUser\" text normal\ndirection LR",
  )
}

///|
test "Mermaid spec: should parse use cases from relationships" {
  inspect(
    model("usecase-beta\n        actor User\n        User --> Login\n"),
    content="actor \"User\" \"User\" text normal\nusecase \"Login\" \"Login\" text ellipse\nrelationship \"edge-0\" \"User\" association/0 \"Login\" minlen=1\ndirection LR",
  )
}

///|
test "Mermaid spec: should parse multiple use cases from relationships" {
  inspect(
    model(
      "usecase-beta\n        actor User\n        User --> Login\n        User --> Logout\n        User --> Register\n",
    ),
    content="actor \"User\" \"User\" text normal\nusecase \"Login\" \"Login\" text ellipse\nusecase \"Logout\" \"Logout\" text ellipse\nusecase \"Register\" \"Register\" text ellipse\nrelationship \"edge-0\" \"User\" association/0 \"Login\" minlen=1\nrelationship \"edge-1\" \"User\" association/0 \"Logout\" minlen=1\nrelationship \"edge-2\" \"User\" association/0 \"Register\" minlen=1\ndirection LR",
  )
}

///|
test "Mermaid spec: should parse use case from relationship" {
  inspect(
    model(
      "usecase-beta\n        actor User\n        User --> UserLoginProcess\n",
    ),
    content="actor \"User\" \"User\" text normal\nusecase \"UserLoginProcess\" \"UserLoginProcess\" text ellipse\nrelationship \"edge-0\" \"User\" association/0 \"UserLoginProcess\" minlen=1\ndirection LR",
  )
}

///|
test "Mermaid spec: should parse use cases with quoted names" {
  inspect(
    model(
      "usecase-beta\n        actor \"Customer Service\"\n        actor \"System Administrator\"\n        \"Customer Service\" --> \"Handle Tickets\"\n        \"System Administrator\" --> \"Manage System\"\n",
    ),
    content="actor \"Customer_Service\" \"Customer Service\" text normal\nactor \"System_Administrator\" \"System Administrator\" text normal\nusecase \"Handle_Tickets\" \"Handle Tickets\" text ellipse\nusecase \"Manage_System\" \"Manage System\" text ellipse\nrelationship \"edge-0\" \"Customer_Service\" association/0 \"Handle_Tickets\" minlen=1\nrelationship \"edge-1\" \"System_Administrator\" association/0 \"Manage_System\" minlen=1\ndirection LR",
  )
}

///|
test "Mermaid spec: should parse multiple relationships" {
  inspect(
    model(
      "usecase-beta\n        actor User\n        User --> Login\n        User --> Logout\n",
    ),
    content="actor \"User\" \"User\" text normal\nusecase \"Login\" \"Login\" text ellipse\nusecase \"Logout\" \"Logout\" text ellipse\nrelationship \"edge-0\" \"User\" association/0 \"Login\" minlen=1\nrelationship \"edge-1\" \"User\" association/0 \"Logout\" minlen=1\ndirection LR",
  )
}

///|
test "Mermaid spec: should parse relationship with label" {
  inspect(
    model(
      "usecase-beta\n        actor Developer\n        Developer --important--> WriteCode\n",
    ),
    content="actor \"Developer\" \"Developer\" text normal\nusecase \"WriteCode\" \"WriteCode\" text ellipse\nrelationship \"edge-0\" \"Developer\" association/0 \"WriteCode\" minlen=1 label=\"important\" text\ndirection LR",
  )
}

///|
test "Mermaid spec: should parse different arrow types" {
  inspect(
    model(
      "usecase-beta\n        actor User\n        actor Admin\n        User --> Login\n        Admin <-- Logout\n        User -- ViewData\n",
    ),
    content="actor \"User\" \"User\" text normal\nactor \"Admin\" \"Admin\" text normal\nusecase \"Login\" \"Login\" text ellipse\nusecase \"Logout\" \"Logout\" text ellipse\nusecase \"ViewData\" \"ViewData\" text ellipse\nrelationship \"edge-0\" \"User\" association/0 \"Login\" minlen=1\nrelationship \"edge-1\" \"Admin\" association/1 \"Logout\" minlen=1\nrelationship \"edge-2\" \"User\" association/2 \"ViewData\" minlen=1\ndirection LR",
  )
}

///|
test "Mermaid spec: should parse a system boundary" {
  inspect(
    model(
      "usecase-beta\n        actor Admin, User\n        systemBoundary \"Authentication\"\n          Login\n          Logout\n        end\n        Admin --> Login\n        User --> Login\n",
    ),
    content="actor \"Admin\" \"Admin\" text normal\nactor \"User\" \"User\" text normal\nusecase \"Login\" \"Login\" text ellipse parent=\"Authentication\"\nusecase \"Logout\" \"Logout\" text ellipse parent=\"Authentication\"\nboundary \"Authentication\" \"Authentication\" text rect members=\"Login\",\"Logout\"\nrelationship \"edge-0\" \"Admin\" association/0 \"Login\" minlen=1\nrelationship \"edge-1\" \"User\" association/0 \"Login\" minlen=1\ndirection LR",
  )
}

///|
test "Mermaid spec: should parse use cases within system boundary" {
  inspect(
    model(
      "usecase-beta\n        actor User\n        systemBoundary \"Authentication System\"\n          Login\n          Logout\n        end\n        User --> Login\n",
    ),
    content="actor \"User\" \"User\" text normal\nusecase \"Login\" \"Login\" text ellipse parent=\"Authentication_System\"\nusecase \"Logout\" \"Logout\" text ellipse parent=\"Authentication_System\"\nboundary \"Authentication_System\" \"Authentication System\" text rect members=\"Login\",\"Logout\"\nrelationship \"edge-0\" \"User\" association/0 \"Login\" minlen=1\ndirection LR",
  )
}

///|
test "Mermaid spec: should parse a boundary with an explicit id, a label, and inline metadata" {
  inspect(
    model(
      "usecase-beta\n        systemBoundary sb1[\"Payment service\"]@{ type: package }\n          actor Clerk(\"Payment clerk\")\n          Authorize(\"Authorize payment\")\n        end\n        Clerk --> Authorize\n",
    ),
    content="actor \"Clerk\" \"Payment clerk\" text normal parent=\"sb1\"\nusecase \"Authorize\" \"Authorize payment\" text ellipse parent=\"sb1\"\nboundary \"sb1\" \"Payment service\" text package members=\"Clerk\",\"Authorize\"\nrelationship \"edge-0\" \"Clerk\" association/0 \"Authorize\" minlen=1\ndirection LR",
  )
}

///|
test "Mermaid spec: should handle TB direction" {
  inspect(
    model("usecase-beta\n        direction TB\n        actor User\n"),
    content="actor \"User\" \"User\" text normal\ndirection TB",
  )
}

///|
test "Mermaid spec: should handle LR direction" {
  inspect(
    model("usecase-beta\n        direction LR\n        actor User\n"),
    content="actor \"User\" \"User\" text normal\ndirection LR",
  )
}

///|
test "Mermaid spec: should normalize TD to TB" {
  inspect(
    model("usecase-beta\n        direction TD\n        actor User\n"),
    content="actor \"User\" \"User\" text normal\ndirection TB",
  )
}

///|
test "Mermaid spec: should parse actor with metadata" {
  inspect(
    model(
      "usecase-beta\n        actor User@{ \"type\" : \"normal\", \"icon\" : \"user\" }\n        User --> Login\n",
    ),
    content="actor \"User\" \"User\" text icon icon=\"user\"\nusecase \"Login\" \"Login\" text ellipse\nrelationship \"edge-0\" \"User\" association/0 \"Login\" minlen=1\ndirection LR",
  )
}

///|
test "Mermaid spec: should parse multiple actors with different metadata" {
  inspect(
    model(
      "usecase-beta\n        actor User@{ \"icon\" : \"user\" }\n        actor Admin@{ \"type\" : \"hollow\" }\n        User --> Login\n        Admin --> ManageUsers\n",
    ),
    content="actor \"User\" \"User\" text icon icon=\"user\"\nactor \"Admin\" \"Admin\" text hollow\nusecase \"Login\" \"Login\" text ellipse\nusecase \"ManageUsers\" \"ManageUsers\" text ellipse\nrelationship \"edge-0\" \"User\" association/0 \"Login\" minlen=1\nrelationship \"edge-1\" \"Admin\" association/0 \"ManageUsers\" minlen=1\ndirection LR",
  )
}

///|
test "Mermaid spec: should parse a complete authentication system" {
  inspect(
    model(
      "usecase-beta\n        actor User\n        actor Admin\n\n        systemBoundary \"Authentication System\"\n          Login\n          Logout\n          Register\n          ResetPassword\n        end\n\n        User --> Login\n        User --> Register\n        User --> Logout\n        Admin --> Login\n",
    ),
    content="actor \"User\" \"User\" text normal\nactor \"Admin\" \"Admin\" text normal\nusecase \"Login\" \"Login\" text ellipse parent=\"Authentication_System\"\nusecase \"Logout\" \"Logout\" text ellipse parent=\"Authentication_System\"\nusecase \"Register\" \"Register\" text ellipse parent=\"Authentication_System\"\nusecase \"ResetPassword\" \"ResetPassword\" text ellipse parent=\"Authentication_System\"\nboundary \"Authentication_System\" \"Authentication System\" text rect members=\"Login\",\"Logout\",\"Register\",\"ResetPassword\"\nrelationship \"edge-0\" \"User\" association/0 \"Login\" minlen=1\nrelationship \"edge-1\" \"User\" association/0 \"Register\" minlen=1\nrelationship \"edge-2\" \"User\" association/0 \"Logout\" minlen=1\nrelationship \"edge-3\" \"Admin\" association/0 \"Login\" minlen=1\ndirection LR",
  )
}

///|
test "Mermaid spec: should handle use case creation from relationships" {
  inspect(
    model(
      "usecase-beta\n        actor Developer\n        Developer --> LoginSystem\n        Developer --> Authentication\n",
    ),
    content="actor \"Developer\" \"Developer\" text normal\nusecase \"LoginSystem\" \"LoginSystem\" text ellipse\nusecase \"Authentication\" \"Authentication\" text ellipse\nrelationship \"edge-0\" \"Developer\" association/0 \"LoginSystem\" minlen=1\nrelationship \"edge-1\" \"Developer\" association/0 \"Authentication\" minlen=1\ndirection LR",
  )
}

///|
test "Mermaid spec: should handle classDef" {
  inspect(
    model(
      "usecase-beta\n        actor User\n        User --> Login\n        classDef important fill:#f96,stroke:#333,stroke-width:4px\n        class Login important\n",
    ),
    content="actor \"User\" \"User\" text normal\nusecase \"Login\" \"Login\" text ellipse classes=\"important\"\nrelationship \"edge-0\" \"User\" association/0 \"Login\" minlen=1\nclassDef \"important\" styles=\"fill:#f96\",\"stroke:#333\",\"stroke-width:4px\"\ndirection LR",
  )
}

///|
test "Mermaid spec: should get specific actor by id" {
  inspect(
    model("usecase-beta\n        actor User\n        actor Admin\n"),
    content="actor \"User\" \"User\" text normal\nactor \"Admin\" \"Admin\" text normal\ndirection LR",
  )
}

///|
test "Mermaid spec: projects parser-produced actor and use-case geometry exactly into AST and LayoutData" {
  inspect(
    model(
      "usecase-beta\nactor Normal\nactor Hollow@{ type: hollow, business: true }\nBusiness(Business)@{ business: true }\nEllipse\nRectCase[Rectangle]\n",
    ),
    content="actor \"Normal\" \"Normal\" text normal\nactor \"Hollow\" \"Hollow\" text hollow business\nusecase \"Business\" \"Business\" text ellipse business\nusecase \"Ellipse\" \"Ellipse\" text ellipse\nusecase \"RectCase\" \"Rectangle\" text rect\ndirection LR",
  )
}

///|
test "Mermaid spec: projects base, one-extra, N-extra, and labelled minimum lengths from parser to layout" {
  inspect(
    model(
      "usecase-beta\nA base@--> B\nB two@---> C\nC many@-----> D\nD labelled@-- \"long\" ----> E\n",
    ),
    content="usecase \"A\" \"A\" text ellipse\nusecase \"B\" \"B\" text ellipse\nusecase \"C\" \"C\" text ellipse\nusecase \"D\" \"D\" text ellipse\nusecase \"E\" \"E\" text ellipse\nrelationship \"base\" explicit \"A\" association/0 \"B\" minlen=1\nrelationship \"two\" explicit \"B\" association/0 \"C\" minlen=2\nrelationship \"many\" explicit \"C\" association/0 \"D\" minlen=4\nrelationship \"labelled\" explicit \"D\" association/0 \"E\" minlen=3 label=\"long\" text\ndirection LR",
  )
}

///|
test "Mermaid spec: projects parser-produced animation metadata into exact shared layout classes" {
  inspect(
    model(
      "usecase-beta\nA trueEdge@--> B\ntrueEdge@{ animate: true }\nA fastEdge@--> B\nfastEdge@{ animation: fast }\nA slowEdge@--> B\nslowEdge@{ animation: slow }\nA offEdge@--> B\noffEdge@{ animate: false }\n",
    ),
    content="usecase \"A\" \"A\" text ellipse\nusecase \"B\" \"B\" text ellipse\nrelationship \"trueEdge\" explicit \"A\" association/0 \"B\" minlen=1 animate\nrelationship \"fastEdge\" explicit \"A\" association/0 \"B\" minlen=1 animate animation=fast\nrelationship \"slowEdge\" explicit \"A\" association/0 \"B\" minlen=1 animate animation=slow\nrelationship \"offEdge\" explicit \"A\" association/0 \"B\" minlen=1\ndirection LR",
  )
}

///|
test "Mermaid spec: projects complex source-ordered JSON, a forward edge, classes, and styles end to end" {
  inspect(
    model(
      "usecase-beta\nclassDef data fill:#eef,stroke:#369\njson Payload@{\n  \"2\": \"second\",\n  \"1\": \"first\",\n  \"colors\": [\"Red\", \"Green\"],\n  \"items\": [{ \"name\": \"A\" }, {}],\n  \"empty\": {},\n  \"duplicate\": \"old\",\n  \"duplicate\": \"new\"\n}:::data\nstyle Payload stroke-width:4px\nInspect payloadEdge@--> Payload\nclass payloadEdge data\nstyle payloadEdge stroke:#f00\n",
    ),
    content="usecase \"Inspect\" \"Inspect\" text ellipse\nrelationship \"payloadEdge\" explicit \"Inspect\" association/0 \"Payload\" minlen=1 classes=\"data\" styles=\"stroke:#f00\"\njson \"Payload\" {\"2\":\"second\",\"1\":\"first\",\"colors\":[\"Red\",\"Green\"],\"items\":[{\"name\":\"A\"},{}],\"empty\":{},\"duplicate\":\"new\"} classes=\"data\" styles=\"stroke-width:4px\"\nclassDef \"data\" styles=\"fill:#eef\",\"stroke:#369\"\ndirection LR",
  )
}
