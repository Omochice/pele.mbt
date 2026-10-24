// The expected models and messages were taken from pele's parser.

///|
/// The model one element a line, or the code, message, line and column of the error.
fn model(source : String, title? : String) -> String {
  let parsed = @usecase.parse_usecase(source, title?) catch {
    @errors.PeleError(failure) =>
      return "error \{failure.code.to_string()}: \{failure.message} @\{failure.line}:\{failure.column}"
  }
  dump(parsed)
}

///|
test "parse_usecase: the header alone, and statements on their lines" {
  inspect(model("usecase-beta"), content="direction LR")
  inspect(
    model("usecase-beta\n\n%% a comment\n  %% another\nactor User\n"),
    content="actor \"User\" \"User\" text normal\ndirection LR",
  )
}

///|
test "parse_usecase: actors, declared alone, in lists and with relationships" {
  inspect(
    model(
      "usecase-beta\nactor User\nactor A, B(\"Bee\"), \"Long name\"\nactor C --> Login\nactor D(Dee) <<Human>>, E:::hot\nactor F:::a, G",
    ),
    content="actor \"User\" \"User\" text normal\nactor \"A\" \"A\" text normal\nactor \"B\" \"Bee\" text normal\nactor \"Long_name\" \"Long name\" text normal\nactor \"C\" \"C\" text normal\nactor \"D\" \"Dee\" text normal stereotype=\"Human\"\nactor \"E\" \"E\" text normal classes=\"hot\"\nactor \"F\" \"F\" text normal classes=\"a\",\"G\"\nusecase \"Login\" \"Login\" text ellipse\nrelationship \"edge-0\" \"C\" association/0 \"Login\" minlen=1\ndirection LR",
  )
}

///|
test "parse_usecase: use cases from declarations, strings and relationship ends" {
  inspect(
    model(
      "usecase-beta\nLogin\nReport[Generate report]\nPay(\"Pay now\")\n\"Reset password\"\n\"`**md** label`\"\nA --> B\nB --> A",
    ),
    content="usecase \"Login\" \"Login\" text ellipse\nusecase \"Report\" \"Generate report\" text rect\nusecase \"Pay\" \"Pay now\" text ellipse\nusecase \"Reset_password\" \"Reset password\" text ellipse\nusecase \"__md___label\" \"**md** label\" markdown ellipse\nusecase \"A\" \"A\" text ellipse\nusecase \"B\" \"B\" text ellipse\nrelationship \"edge-0\" \"A\" association/0 \"B\" minlen=1\nrelationship \"edge-1\" \"B\" association/0 \"A\" minlen=1\ndirection LR",
  )
}

///|
test "parse_usecase: every relationship operator with its marker and minimum length" {
  inspect(
    model(
      "usecase-beta\nA --> B\nA <-- B\nA -- B\nA --o B\nA o-- B\nA --x B\nA x-- B\nA ---> C\nA <--- C\nA --- C\nA -----> D",
    ),
    content="usecase \"A\" \"A\" text ellipse\nusecase \"B\" \"B\" text ellipse\nusecase \"C\" \"C\" text ellipse\nusecase \"D\" \"D\" text ellipse\nrelationship \"edge-0\" \"A\" association/0 \"B\" minlen=1\nrelationship \"edge-1\" \"A\" association/1 \"B\" minlen=1\nrelationship \"edge-2\" \"A\" association/2 \"B\" minlen=1\nrelationship \"edge-3\" \"A\" association/3 \"B\" minlen=1\nrelationship \"edge-4\" \"A\" association/5 \"B\" minlen=1\nrelationship \"edge-5\" \"A\" association/4 \"B\" minlen=1\nrelationship \"edge-6\" \"A\" association/6 \"B\" minlen=1\nrelationship \"edge-7\" \"A\" association/0 \"C\" minlen=2\nrelationship \"edge-8\" \"A\" association/1 \"C\" minlen=2\nrelationship \"edge-9\" \"A\" association/2 \"C\" minlen=2\nrelationship \"edge-10\" \"A\" association/0 \"D\" minlen=4\ndirection LR",
  )
}

///|
test "parse_usecase: include, extend and generalization" {
  inspect(
    model(
      "usecase-beta\nA ..> : include B\nA ..> : EXTEND C\nactor X\nactor Y\nX --|> Y",
    ),
    content="actor \"X\" \"X\" text normal\nactor \"Y\" \"Y\" text normal\nusecase \"A\" \"A\" text ellipse\nusecase \"B\" \"B\" text ellipse\nusecase \"C\" \"C\" text ellipse\nrelationship \"edge-0\" \"A\" include/0 \"B\" minlen=1 label=\"include\" text\nrelationship \"edge-1\" \"A\" extend/0 \"C\" minlen=1 label=\"extend\" text\nrelationship \"edge-2\" \"X\" generalization/0 \"Y\" minlen=1\ndirection LR",
  )
}

///|
test "parse_usecase: labels on associations" {
  inspect(
    model(
      "usecase-beta\nA -- starts a session --> B\nA -- \"quoted\" -- B\nA -- `md` --o B\nA -- x --x B\nA <-- back -- B\nA o-- circle -- B\nA x-- cross -- B\nA -- long ---> C\nA <-- long --- C",
    ),
    content="usecase \"A\" \"A\" text ellipse\nusecase \"B\" \"B\" text ellipse\nusecase \"C\" \"C\" text ellipse\nrelationship \"edge-0\" \"A\" association/0 \"B\" minlen=1 label=\"starts a session\" text\nrelationship \"edge-1\" \"A\" association/2 \"B\" minlen=1 label=\"quoted\" text\nrelationship \"edge-2\" \"A\" association/3 \"B\" minlen=1 label=\"`md`\" text\nrelationship \"edge-3\" \"A\" association/4 \"B\" minlen=1 label=\"x\" text\nrelationship \"edge-4\" \"A\" association/1 \"B\" minlen=1 label=\"back\" text\nrelationship \"edge-5\" \"A\" association/5 \"B\" minlen=1 label=\"circle\" text\nrelationship \"edge-6\" \"A\" association/6 \"B\" minlen=1 label=\"cross\" text\nrelationship \"edge-7\" \"A\" association/0 \"C\" minlen=2 label=\"long\" text\nrelationship \"edge-8\" \"A\" association/1 \"C\" minlen=2 label=\"long\" text\ndirection LR",
  )
}

///|
test "parse_usecase: explicit relationship ids" {
  inspect(
    model("usecase-beta\nA e1@--> B\nA e2@..> : include B"),
    content="usecase \"A\" \"A\" text ellipse\nusecase \"B\" \"B\" text ellipse\nrelationship \"e1\" explicit \"A\" association/0 \"B\" minlen=1\nrelationship \"e2\" explicit \"A\" include/0 \"B\" minlen=1 label=\"include\" text\ndirection LR",
  )
}

///|
test "parse_usecase: system boundaries and their members" {
  inspect(
    model(
      "usecase-beta\nactor User\nsystemBoundary Shop[\"The shop\"]\n  Browse\n  actor Clerk\n  Pay(Pay)\nend\nsystemBoundary \"Back office\"\n  Audit\nend\nsystemBoundary P(Payments)@{ type: package }:::hot\nend\nUser --> Browse",
    ),
    content="actor \"User\" \"User\" text normal\nactor \"Clerk\" \"Clerk\" text normal parent=\"Shop\"\nusecase \"Browse\" \"Browse\" text ellipse parent=\"Shop\"\nusecase \"Pay\" \"Pay\" text ellipse parent=\"Shop\"\nusecase \"Audit\" \"Audit\" text ellipse parent=\"Back_office\"\nboundary \"Shop\" \"The shop\" text rect members=\"Browse\",\"Clerk\",\"Pay\"\nboundary \"Back_office\" \"Back office\" text rect members=\"Audit\"\nboundary \"P\" \"Payments\" text package classes=\"hot\"\nrelationship \"edge-0\" \"User\" association/0 \"Browse\" minlen=1\ndirection LR",
  )
}

///|
test "parse_usecase: metadata on actors, use cases, boundaries and edges" {
  inspect(
    model(
      "usecase-beta\nactor A@{ type: awesome }\nactor B@{ icon: \"fa:user\" }\nactor C@{ business: true, type: hollow }\nU(Use)@{ business: true }\nA e@--> U\ne@{ animation: slow }\nA f@--> U\nf@{ animate: true }\nsystemBoundary S\nend\nS@{ type: package }\nA@{\n  type: normal\n}",
    ),
    content="actor \"A\" \"A\" text normal\nactor \"B\" \"B\" text icon icon=\"fa:user\"\nactor \"C\" \"C\" text hollow business\nusecase \"U\" \"Use\" text ellipse business\nboundary \"S\" \"S\" text package\nrelationship \"e\" explicit \"A\" association/0 \"U\" minlen=1 animate animation=slow\nrelationship \"f\" explicit \"A\" association/0 \"U\" minlen=1 animate\ndirection LR",
  )
}

///|
test "parse_usecase: stereotypes and classes" {
  inspect(
    model(
      "usecase-beta\nactor A <<Human>>\nU(Use) <<Core>>:::a,b\nV:::c\nclassDef a,b fill:#fee,stroke:#c33\nclassDef c stroke-width:1.5px, stroke-dasharray: 5 5\nclass A,U b,c\nstyle U stroke:#06c,color:red\\,blue",
    ),
    content="actor \"A\" \"A\" text normal stereotype=\"Human\" classes=\"b\",\"c\"\nusecase \"U\" \"Use\" text ellipse stereotype=\"Core\" classes=\"a\",\"b\",\"c\" styles=\"stroke:#06c\",\"color:red,blue\"\nusecase \"V\" \"V\" text ellipse classes=\"c\"\nclassDef \"a\" styles=\"fill:#fee\",\"stroke:#c33\"\nclassDef \"b\" styles=\"fill:#fee\",\"stroke:#c33\"\nclassDef \"c\" styles=\"stroke-width:1.5px\",\"stroke-dasharray: 5 5\"\ndirection LR",
  )
}

///|
test "parse_usecase: notes" {
  inspect(
    model(
      "usecase-beta\nactor User\nnote for User \"Starts the workflow\"\nnote for Login \"`Needs a **session**`\"\nnote for Login plain words here\nUser --> Login",
    ),
    content="actor \"User\" \"User\" text normal\nusecase \"Login\" \"Login\" text ellipse\nrelationship \"edge-0\" \"User\" association/0 \"Login\" minlen=1\nnote \"note-0\" \"User\" \"Starts the workflow\" text\nnote \"note-1\" \"Login\" \"Needs a **session**\" markdown\nnote \"note-2\" \"Login\" \"plain words here\" text\ndirection LR",
  )
}

///|
test "parse_usecase: JSON nodes" {
  inspect(
    model(
      "usecase-beta\njson Payload@{\n  \"2\": \"second\",\n  \"1\": \"first\",\n  \"colors\": [\"Red\", \"Green\"]\n} :::data\nPayload --> Inspect\njson Empty @ {}",
    ),
    content="usecase \"Inspect\" \"Inspect\" text ellipse\nrelationship \"edge-0\" \"Payload\" association/0 \"Inspect\" minlen=1\njson \"Payload\" {\"2\":\"second\",\"1\":\"first\",\"colors\":[\"Red\",\"Green\"]} classes=\"data\"\njson \"Empty\" {}\ndirection LR",
  )
}

///|
test "parse_usecase: direction and accessibility" {
  inspect(
    model(
      "usecase-beta\ndirection TD\naccTitle: Online ordering\naccDescr {\n  A customer orders.\n   Staff review.\n}",
    ),
    content="direction TB\naccTitle \"Online ordering\"\naccDescr \"A customer orders.\\nStaff review.\"",
  )
  inspect(
    model("usecase-beta\ndirection RL\naccDescr: one line\ndirection BT\n"),
    content="direction BT\naccDescr \"one line\"",
  )
  inspect(
    model("usecase-beta\nactor A\n", title="Ordering"),
    content="actor \"A\" \"A\" text normal\ndirection LR\ntitle \"Ordering\"",
  )
}

///|
test "parse_usecase: syntax errors in Mermaid's words" {
  inspect(
    model("usecase-beta\nactor A actor B"),
    content="error syntax: Error parsing usecase diagram: Expecting: one of these possible Token sequences:\n  1. [NEWLINE]\n  2. [EOF]\nbut found: 'actor' at line 2, column 9 [21,26) @2:9",
  )
  inspect(
    model("usecase-beta\nsystemBoundary S\nA --> B\nend"),
    content="error syntax: Error parsing usecase diagram: Expecting: one of these possible Token sequences:\n  1. [NEWLINE]\n  2. [EOF]\nbut found: '-->' at line 3, column 3 [32,35) @3:3",
  )
  inspect(
    model("usecase-beta\nsystemBoundary S\nA"),
    content="error syntax: Error parsing usecase diagram: Expecting token of type --> END <-- but found --> '' <-- at line 3, column 2 [31,31) @3:2",
  )
  inspect(
    model("usecase-beta\nA \"b"),
    content="error syntax: Error lexing usecase diagram: unexpected character: ->\"<- at offset: 15, skipped 1 characters. at line 2, column 3 [15,16) @2:3",
  )
  inspect(
    model(
      "usecase-beta\nsystemBoundary ${declaration}\nAuthorize(\"Authorize payment\")\nend",
    ),
    content="error syntax: Error parsing usecase diagram: Expecting: one of these possible Token sequences:\n  1. [IDENTIFIER]\n  2. [PLAIN_STRING]\n  3. [MARKDOWN_STRING]\nbut found: '$' at line 2, column 16 [28,29) @2:16",
  )
  inspect(
    model("usecase-beta\nsystemBoundary sb1:::system@{ type: package }\nend"),
    content="error syntax: Error parsing usecase diagram: Expecting: one of these possible Token sequences:\n  1. [NEWLINE]\n  2. [EOF]\nbut found: '@{' at line 2, column 28 [40,42) @2:28",
  )
  inspect(
    model("usecase-beta\n${statement}"),
    content="error syntax: Error parsing usecase diagram: Redundant input, expecting EOF but found: $ at line 2, column 1 [13,14) @2:1",
  )
  inspect(
    model("usecase-beta\njson ${id} @{\"a\": 1}"),
    content="error syntax: Error parsing usecase diagram: Redundant input, expecting EOF but found: json at line 2, column 1 [13,17) @2:1",
  )
  inspect(
    model("usecase-beta\nsystemBoundary Auth\njson Payload@{}\nend"),
    content="error syntax: Error parsing usecase diagram: Expecting token of type --> END <-- but found --> 'json Payload@' <-- at line 3, column 1 [33,46) @3:1",
  )
  inspect(
    model("usecase-beta\nA@{ type: , }"),
    content="error syntax: Error parsing usecase diagram: Expecting: one of these possible Token sequences:\n  1. [IDENTIFIER]\n  2. [PLAIN_STRING]\n  3. [TRUE]\n  4. [FALSE]\nbut found: ',' at line 2, column 11 [23,24) @2:11",
  )
  inspect(
    model("usecase-beta\nA@{ a: b,\n\n}"),
    content="error syntax: Error parsing usecase diagram: Expecting: one of these possible Token sequences:\n  1. [IDENTIFIER]\n  2. [PLAIN_STRING]\nbut found: '}' at line 4, column 1 [24,25) @4:1",
  )
  inspect(
    model("usecase-beta\nstyle A fill:"),
    content="error syntax: Error parsing usecase diagram: Expecting: expecting at least one iteration which starts with one of these possible Token sequences::\n  <[WORD] ,[PLAIN_STRING] ,[NUMBER] ,[HASH_COLOR] ,[CSS_IDENTIFIER] ,[CSS_ESCAPED_COMMA] ,[DASH] ,[DOT] ,[PERCENT] ,[CSS_PUNCTUATION] ,[COLON] ,[LPAREN] ,[RPAREN] ,[LBRACKET] ,[RBRACKET] ,[LBRACE] ,[RBRACE] ,[AT] ,[MARKERLESS_SOLID]>\nbut found: '' at line 2, column 14 [26,26) @2:14",
  )
  inspect(
    model("usecase-beta\nstyle A --:red"),
    content="error syntax: Error parsing usecase diagram: Expecting token of type --> WORD <-- but found --> ':' <-- at line 2, column 11 [23,24) @2:11",
  )
  inspect(
    model("usecase-beta\nrectangle R"),
    content="error syntax: Error parsing usecase diagram: Expecting: one of these possible Token sequences:\n  1. [ACC_TITLE_LINE]\n  2. [ACC_DESCR_LINE]\n  3. [ACC_DESCR_BLOCK]\n  4. [DIRECTION]\n  5. [ACTOR]\n  6. [SYSTEM_BOUNDARY]\n  7. [NOTE]\n  8. [JSON_DECLARATION_START]\n  9. [CLASS_DEF]\n  10. [CLASS]\n  11. [STYLE]\n  12. [IDENTIFIER, METADATA_START, NEWLINE]\n  13. [IDENTIFIER, METADATA_START, IDENTIFIER]\n  14. [IDENTIFIER, METADATA_START, PLAIN_STRING]\n  15. [IDENTIFIER, METADATA_START, RBRACE]\n  16. [PLAIN_STRING, METADATA_START, NEWLINE]\n  17. [PLAIN_STRING, METADATA_START, IDENTIFIER]\n  18. [PLAIN_STRING, METADATA_START, PLAIN_STRING]\n  19. [PLAIN_STRING, METADATA_START, RBRACE]\n  20. [MARKDOWN_STRING, METADATA_START, NEWLINE]\n  21. [MARKDOWN_STRING, METADATA_START, IDENTIFIER]\n  22. [MARKDOWN_STRING, METADATA_START, PLAIN_STRING]\n  23. [MARKDOWN_STRING, METADATA_START, RBRACE]\n  24. [IDENTIFIER, LPAREN]\n  25. [IDENTIFIER, LBRACKET]\n  26. [IDENTIFIER, STEREOTYPE_START]\n  27. [IDENTIFIER, CLASS_SEPARATOR]\n  28. [IDENTIFIER, IDENTIFIER]\n  29. [IDENTIFIER, DEPENDENCY_ARROW]\n  30. [IDENTIFIER, GENERALIZATION]\n  31. [IDENTIFIER, FORWARD_SOLID]\n  32. [IDENTIFIER, BACKWARD_SOLID]\n  33. [IDENTIFIER, MARKERLESS_SOLID]\n  34. [IDENTIFIER, FORWARD_CIRCLE]\n  35. [IDENTIFIER, BACKWARD_CIRCLE]\n  36. [IDENTIFIER, FORWARD_CROSS]\n  37. [IDENTIFIER, BACKWARD_CROSS]\n  38. [IDENTIFIER, NEWLINE]\n  39. [IDENTIFIER, EOF]\n  40. [PLAIN_STRING, STEREOTYPE_START]\n  41. [PLAIN_STRING, CLASS_SEPARATOR]\n  42. [PLAIN_STRING, IDENTIFIER]\n  43. [PLAIN_STRING, DEPENDENCY_ARROW]\n  44. [PLAIN_STRING, GENERALIZATION]\n  45. [PLAIN_STRING, FORWARD_SOLID]\n  46. [PLAIN_STRING, BACKWARD_SOLID]\n  47. [PLAIN_STRING, MARKERLESS_SOLID]\n  48. [PLAIN_STRING, FORWARD_CIRCLE]\n  49. [PLAIN_STRING, BACKWARD_CIRCLE]\n  50. [PLAIN_STRING, FORWARD_CROSS]\n  51. [PLAIN_STRING, BACKWARD_CROSS]\n  52. [PLAIN_STRING, NEWLINE]\n  53. [PLAIN_STRING, EOF]\n  54. [MARKDOWN_STRING, STEREOTYPE_START]\n  55. [MARKDOWN_STRING, CLASS_SEPARATOR]\n  56. [MARKDOWN_STRING, IDENTIFIER]\n  57. [MARKDOWN_STRING, DEPENDENCY_ARROW]\n  58. [MARKDOWN_STRING, GENERALIZATION]\n  59. [MARKDOWN_STRING, FORWARD_SOLID]\n  60. [MARKDOWN_STRING, BACKWARD_SOLID]\n  61. [MARKDOWN_STRING, MARKERLESS_SOLID]\n  62. [MARKDOWN_STRING, FORWARD_CIRCLE]\n  63. [MARKDOWN_STRING, BACKWARD_CIRCLE]\n  64. [MARKDOWN_STRING, FORWARD_CROSS]\n  65. [MARKDOWN_STRING, BACKWARD_CROSS]\n  66. [MARKDOWN_STRING, NEWLINE]\n  67. [MARKDOWN_STRING, EOF]\n  68. [IDENTIFIER, METADATA_START, NEWLINE]\n  69. [IDENTIFIER, METADATA_START, IDENTIFIER]\n  70. [IDENTIFIER, METADATA_START, PLAIN_STRING]\n  71. [IDENTIFIER, METADATA_START, RBRACE]\n  72. [PLAIN_STRING, METADATA_START, NEWLINE]\n  73. [PLAIN_STRING, METADATA_START, IDENTIFIER]\n  74. [PLAIN_STRING, METADATA_START, PLAIN_STRING]\n  75. [PLAIN_STRING, METADATA_START, RBRACE]\n  76. [MARKDOWN_STRING, METADATA_START, NEWLINE]\n  77. [MARKDOWN_STRING, METADATA_START, IDENTIFIER]\n  78. [MARKDOWN_STRING, METADATA_START, PLAIN_STRING]\n  79. [MARKDOWN_STRING, METADATA_START, RBRACE]\nbut found: 'rectangle' at line 2, column 1 [13,22) @2:1",
  )
  inspect(
    model("usecase-beta\nA ..> B"),
    content="error syntax: Error parsing usecase diagram: Expecting token of type --> COLON <-- but found --> 'B' <-- at line 2, column 7 [19,20) @2:7",
  )
  inspect(
    model("usecase-beta\nA -- label B"),
    content="error syntax: Error parsing usecase diagram: Expecting: one of these possible Token sequences:\n  1. [NEWLINE]\n  2. [EOF]\nbut found: 'B' at line 2, column 12 [24,25) @2:12",
  )
  inspect(
    model("usecase-beta\nA@{ \"x\" }"),
    content="error syntax: Error parsing usecase diagram: Expecting token of type --> COLON <-- but found --> '}' <-- at line 2, column 9 [21,22) @2:9",
  )
  inspect(
    model("usecase-beta\ndirection XX"),
    content="error syntax: Error parsing usecase diagram: Expecting: one of these possible Token sequences:\n  1. [TD]\n  2. [TB]\n  3. [BT]\n  4. [LR]\n  5. [RL]\nbut found: 'XX' at line 2, column 11 [23,25) @2:11",
  )
  inspect(
    model("usecase-beta\nA <<x"),
    content="error syntax: Error parsing usecase diagram: Expecting token of type --> STEREOTYPE_TEXT <-- but found --> 'x' <-- at line 2, column 5 [17,18) @2:5",
  )
  inspect(
    model("usecase-beta\njson P@{\"a\":}"),
    content="error syntax: Invalid JSON: Unexpected token '}', \"{\"a\":}\" is not valid JSON (line 2, column 13) @2:13",
  )
  inspect(
    model("usecase-beta\njson P@{\"a\":1"),
    content="error syntax: Error parsing usecase diagram: Expecting token of type --> JSON_OBJECT_LITERAL <-- but found --> '{\"a\":1' <-- at line 2, column 8 [20,26) @2:8",
  )
  inspect(
    model("graph TD"),
    content="error syntax: Error parsing usecase diagram: Expecting token of type --> USECASE <-- but found --> 'graph' <-- at line 1, column 1 [0,5) @1:1",
  )
}

///|
test "parse_usecase: semantic errors with both locations" {
  inspect(
    model("usecase-beta\nactor User@{ fillColor: red }"),
    content="error semantic: Metadata property 'fillColor' is invalid for actor 'User' at line 2, column 14 [26,35) @2:14",
  )
  inspect(
    model("usecase-beta\nactor Awesome@{ type: awesome, business: true }"),
    content="error semantic: Business actor 'Awesome' must use normal or hollow geometry at line 2, column 7 [19,26) @2:7",
  )
  inspect(
    model("usecase-beta\nactor \"A-B\"\n\"A B\""),
    content="error semantic: ID 'A_B' is declared as both actor and usecase at line 3, column 2 [26,29) (label \"A B\"); previous declaration at line 2, column 8 [20,23) (label \"A-B\") @3:2",
  )
  inspect(
    model("usecase-beta\nA link@--> B\nlink@{ animate: fast }"),
    content="error semantic: Metadata property 'animate' is invalid for edge 'link' at line 3, column 8 [33,40) @3:8",
  )
  inspect(
    model("usecase-beta\nA known@--> B\nstyle missingEdge stroke:red"),
    content="error semantic: Class/style target 'missingEdge' is unresolved or anonymous at line 3, column 7 [33,44) @3:7",
  )
  inspect(
    model("usecase-beta\nA link@--> B\nB link@--> C"),
    content="error semantic: ID 'link' is declared more than once (edge and edge) at line 3, column 3 [28,32); previous declaration at line 2, column 3 [15,19) @3:3",
  )
  inspect(
    model("usecase-beta\n\"A-B\"\n\"A B\""),
    content="error semantic: Generated ID 'A_B' collides with another declaration at line 3, column 2 [20,23) (label \"A B\"); previous declaration at line 2, column 2 [14,17) (label \"A-B\") @3:2",
  )
  inspect(
    model("usecase-beta\nReport[Generate report]@{ business: true }"),
    content="error semantic: Rectangular use case 'Report' cannot be a business use case at line 2, column 1 [13,19) @2:1",
  )
  inspect(
    model(
      "usecase-beta\njson Payload@{}\nInspect\nPayload ..> : include Inspect",
    ),
    content="error semantic: include relationship requires use-case endpoints at line 4, column 9 [45,66) @4:9",
  )
  inspect(
    model(
      "usecase-beta\nsystemBoundary Auth\nLogin\nend\nnote for Auth \"invalid\"",
    ),
    content="error semantic: Note target 'Auth' must be an actor or use case, not boundary at line 5, column 10 [52,56); previous declaration at line 2, column 16 [28,32) @5:10",
  )
  inspect(
    model("usecase-beta\nactor User\nLogin\nUser --|> Login"),
    content="error semantic: Generalization requires actor-to-actor or use-case-to-use-case endpoints at line 4, column 6 [35,45) @4:6",
  )
  inspect(
    model("usecase-beta\njson Payload@{}\nInspect --o Payload"),
    content="error semantic: JSON relationship 'Inspect' to 'Payload' permits only point, reversed-point, or markerless solid association at line 3, column 9 [37,48) @3:9",
  )
  inspect(
    model("usecase-beta\n\"A B\"\nA_B(Explicit)"),
    content="error semantic: Generated ID 'A_B' collides with another declaration at line 3, column 1 [19,22); previous declaration at line 2, column 2 [14,17) (label \"A B\") @3:1",
  )
  inspect(
    model(
      "usecase-beta\nsystemBoundary sb1[\"Payment service\"]@{ animate: true }\nend",
    ),
    content="error semantic: Metadata property 'animate' is invalid for boundary 'sb1' at line 2, column 41 [53,60) @2:41",
  )
  inspect(
    model("usecase-beta\nactor User@{ icon: \"fa:user\", type: awesome }"),
    content="error semantic: Actor 'User' cannot combine icon with type 'awesome' at line 2, column 7 [19,23) @2:7",
  )
  inspect(
    model("usecase-beta\nactor A@{ type: hollow }\nactor A@{ type: awesome }"),
    content="error semantic: Actor 'A' has conflicting type metadata at line 3, column 11 [48,52); previous declaration at line 2, column 7 [19,20) @3:11",
  )
  inspect(
    model("usecase-beta\nA:::x --> B:::y"),
    content="error semantic: Relationship endpoint 'A' uses ::: without declaring the node at line 2, column 1 [13,14) @2:1",
  )
  inspect(
    model("usecase-beta\nGhost@{ type: package }"),
    content="error semantic: Metadata target 'Ghost' is unresolved (metadata implies boundary) at line 2, column 1 [13,18) @2:1",
  )
  inspect(
    model("usecase-beta\nGhost@{ icon: x }"),
    content="error semantic: Metadata target 'Ghost' is unresolved (metadata implies actor) at line 2, column 1 [13,18) @2:1",
  )
  inspect(
    model("usecase-beta\nsystemBoundary S\nend\nS --> A"),
    content="error semantic: Relationship source 'S' cannot be boundary at line 4, column 1 [34,35); previous declaration at line 2, column 16 [28,29) @4:1",
  )
  inspect(
    model(
      "usecase-beta\nsystemBoundary First\nLogin\nend\nsystemBoundary Second\nLogin\nend",
    ),
    content="error semantic: Element 'Login' belongs to more than one system boundary at line 5, column 16 [59,65); previous declaration at line 2, column 16 [28,33) @5:16",
  )
  inspect(
    model("usecase-beta\nLogin <<Primary>>\nLogin <<Secondary>>"),
    content="error semantic: Element 'Login' has conflicting stereotypes at line 3, column 1 [31,36); previous declaration at line 2, column 1 [13,18) @3:1",
  )
  inspect(
    model("usecase-beta\nU(Use)@{ business: true }\nU(Use)@{ business: false }"),
    content="error semantic: Use case 'U' has conflicting business metadata at line 3, column 10 [48,56); previous declaration at line 2, column 1 [13,14) @3:10",
  )
  inspect(
    model("usecase-beta\njson P@{}\nP@{ type: package }"),
    content="error semantic: Metadata property 'type' is invalid for json 'P' at line 3, column 5 [27,31) @3:5",
  )
}
