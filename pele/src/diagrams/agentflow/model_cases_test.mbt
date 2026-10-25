// What pele makes of each agentflow input of its reference corpus, its documentation corpus, Mermaid's fixtures and the goldens.
// Generated from pele 1.8.0: a success is a hash of the dump written as `dump_model` writes it.

///|
let model_cases : Array[(String, String)] = [
  (
    "agentflow-beta TB\n\nflow demo\n  helper[\"Helper\"]\nend\n\nhelper@{ instruction: \"Answer precisely.\" }",
    "ok 1faa7a51",
  ),
  (
    "agentflow-beta TB\n  flow pipeline[\"Pipeline\"]\n    a --> b\n  end\n  pipeline@{ view: \"collapsed\" }",
    "ok e70f8360",
  ),
  (
    "agentflow-beta TB\n  connector github[\"GitHub\"]\n  github@{ protocol: \"mcp\", transport: \"stdio\" }",
    "ok de455a60",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]\n  b[\"B\"]\n  a e1@--> b\n  e1@{ instruction: \"hand off\" }",
    "ok 93a7c48c",
  ),
  (
    "agentflow-beta TB\n  a[\"Alpha\"]\n  a@{\n    instruction: \"do the thing\"\n  }",
    "ok 73827055",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]\n  b[\"B\"]@{ shape: rect }\n  a --> b", "ok d183650c",
  ),
  ("agentflow-beta TB\n  a --> b", "ok 77bd605e"),
  (
    "agentflow-beta TB\n  flow p[\"P\"]\n    a --> b\n  end\n  p@{ view: \"collapsed\" }",
    "ok fd041902",
  ),
  (
    "agentflow-beta\nflow f[\"F\"]\n  a[\"A\"]@{ shape: rounded }\n\n  b[\"B\"]\nend",
    "ok 2a2abfcf",
  ),
  (
    "agentflow-beta\nflow f[\"F\"]\n  a[\"A\"]@{ shape: rounded }\n\n\n  b[\"B\"]\nend",
    "ok 454f4f32",
  ),
  (
    "agentflow-beta\nflow f[\"F\"]\n  a[\"A\"]@{ shape: rounded }\n  %% a note\n  b[\"B\"]\nend",
    "ok 2a2abfcf",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]@{ shape: rounded }\n\n  c[\"C\"]\n  a --> c",
    "ok c3f9f1af",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]@{ shape: rounded }\n\n  b[\"B\"]@{ shape: rounded }\n\n  c[\"C\"]\"]\n",
    "error syntax agentflow agentflow\nParse error on line 6:\n  c[\"C\"]\"]\n---------^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'EOF', got 'STR'",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]@{ shape: rounded }   \n\n  b[\"B\"]", "ok 29ba4f70",
  ),
  ("%% leading comment\nagentflow-beta TB\n  a --> b", "ok cfd3297e"),
  ("%% first\n%% second\n%% third\nagentflow-beta TB\n  a --> b", "ok c855abba"),
  ("agentflow-beta TB\n%% trailing header comment\n  a --> b", "ok cfd3297e"),
  ("agentflow-beta TB\n  a --> b\n%% mid comment\n  b --> c", "ok ae9a23dc"),
  (
    "agentflow-beta TB\n  a --> b\n%% first mid comment\n%% second mid comment\n  b --> c",
    "ok 06b4f8bc",
  ),
  ("agentflow-beta TB\n  a --> b\n%% trailing comment", "ok 77bd605e"),
  ("agentflow-beta TB\n  a --> b\n%%no-space comment\n  b --> c", "ok ae9a23dc"),
  ("agentflow-beta TB\n  a --> b\n%%\n  b --> c", "ok ae9a23dc"),
  (
    "agentflow-beta TB\n  a[Plain %% not part of the label\nlabel]\n  b --> a", "ok 56daf8cc",
  ),
  (
    "agentflow-beta TB\n  a(-ellipse %% not part of the label\nlabel-)\n  b --> a",
    "ok 6eb45c8b",
  ),
  (
    "agentflow-beta TB\n  a[/trap %% not part of the label\nlabel/]\n  b --> a",
    "ok 6bc9ef10",
  ),
  (
    "agentflow-beta TB\n%% before flow\nflow f1[\"Flow One\"]\n%% inside flow\n  a --> b\nend\n%% after flow",
    "ok d5e5423d",
  ),
  (
    "agentflow-beta TB\n%% before connector\nconnector github[\"GitHub\"]\n%% after connector\n  a --> b",
    "ok 8638d189",
  ),
  (
    "agentflow-beta TB\n  flow A[\"Flow A\"]${viewA}\n    a1[\"Task A1\"]\n    a1 --> B\n  end\n  flow B[\"Flow B\"]${viewB}\n    b1[\"Task B1\"]\n    b1 --> A\n  end",
    "error syntax agentflow agentflow\nParse error on line 2:\n  flow A[\"Flow A\"]${viewA}\n------------------^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'EOF', 'SHAPE_DATA', got 'NODE_STRING'",
  ),
  (
    "agentflow-beta TB\n  flow A[\"A\"]@{ view: collapsed }\n    a1[\"a1\"]\n    a1 --> B\n  end\n  flow B[\"B\"]\n    b1[\"b1\"]\n    b1 --> C\n  end\n  flow C[\"C\"]\n    c1[\"c1\"]\n    c1 --> A\n  end",
    "ok c579c4c9",
  ),
  (
    "agentflow-beta TB\n  a[\"Alpha\"]\n  a@{ shape: \"triangle\" }\n  b[\"Beta\"]\n  a --> b",
    "ok 73daadd9",
  ),
  (
    "agentflow-beta TB\n  a[\"Alpha\"]\n  a@{ shape: \"cylinder\" }\n  b[\"Beta\"]\n  a --> b",
    "ok 3695e9a7",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]\n  b[\"B\"]\n  a e1@--> b\n  e1@{ instruction: \"${INSTRUCTION}\" }",
    "ok 0696a66e",
  ),
  ("agentflow-beta TB\n  a[\"A\"]\n  b[\"B\"]\n  a --> b", "ok 640afc11"),
  (
    "agentflow-beta TB\n  a[\"A\"]\n  b[\"B\"]\n  a ${operator} b", "error syntax agentflow agentflow\nParse error on line 4:\n  a ${operator} b\n----^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'EOF', got 'NODE_STRING'",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]\n  b[\"B\"]\n  c[\"C\"]\n  a --> b\n  b --x c",
    "ok 83ffad2d",
  ),
  ("agentflow-beta TB\n  newtask[\"Example\"]@{\n}", "ok 7ebdb2dd"),
  ("agentflow-beta TB\n  a[\"A\"]@{\n\n}", "ok 9c36577e"),
  ("agentflow-beta TB\n  a[\"A\"]@{   }", "ok 5e72da4c"),
  ("agentflow-beta TB\n  a[\"A\"]@{}", "ok 3ab632ff"),
  ("agentflow-beta TB\n  a[\"A\"]@{\n}", "ok 5b285905"),
  (
    "agentflow-beta TB\n  flow f[\"F\"]\n    a --> b\n  end\n  f@{}", "ok be5cccb5",
  ),
  (
    "agentflow-beta TB\n  flow f[\"F\"]\n    a --> b\n  end\n  f@{\n}", "ok e26b0997",
  ),
  ("agentflow-beta TB\n  a[\"A\"]@{\n:\n}", "ok cae78e5d"),
  (
    "agentflow-beta TB\n  a[\"A\"]@{ shape: 123 }", "error semantic agentflow agentflow\nNo such shape: 123.",
  ),
  ("agentflow-beta TB\n  a[\"A\"]@{ shape: task }", "ok 759ca07b"),
  (
    "agentflow-beta TB\n  flow article_generation@{\n         model: \"claude-opus-4\"\n       }\n        A --> B\n  end",
    "ok c67c8b9f",
  ),
  (
    "agentflow-beta TB\n  flow f@{ model: \"claude-opus-4\", memory: \"shared\" }\n    a --> b\n  end",
    "ok 6a86d4c4",
  ),
  (
    "agentflow-beta TB\n  flow f[\"Article Generation\"]@{ model: \"claude-opus-4\" }\n    a --> b\n  end",
    "ok 299cb4aa",
  ),
  (
    "agentflow-beta TB\n  flow f@{ model: \"m\", memory: \"shared\", execution: \"parallel\", custom: 1 }\n    a --> b\n  end",
    "ok 84a36696",
  ),
  (
    "agentflow-beta TB\n  flow myFlow[\"My Flow\"]\n    a[\"Task A\"]\n    a --> myFlow\n  end",
    "ok 9a1ba383",
  ),
  (
    "agentflow-beta TB\n  flow outer[\"Outer\"]\n    flow inner[\"Inner\"]\n      b[\"Task B\"]\n      b --> inner\n    end\n  end",
    "ok 3e8ed44a",
  ),
  (
    "agentflow-beta TB\n  flow top[\"Top\"]\n    flow mid[\"Mid\"]\n      flow leafFlow[\"Leaf\"]\n        c[\"Task C\"]\n      end\n      m[\"Task M\"]\n      m --> mid\n    end\n  end",
    "ok b0359f21",
  ),
  (
    "agentflow-beta TB\n  flow outer[\"Outer\"]\n    flow inner[\"Inner\"]\n      b[\"Task B\"]\n      b --> inner\n    end\n    a[\"Task A\"]\n    a --> outer\n  end",
    "ok 9fd1b00f",
  ),
  ("agentflow-beta TB\n  flow f[\"F\"]\n    a --> b\n  end", "ok ea964fce"),
  ("agentflow-beta TB\n${body}\n", "ok 1ccd15d2"),
  (
    "agentflow-beta\n\nglobal\n  A\nend\n\nflow\n A --> B --> C\nend", "ok 57cdde77",
  ),
  (
    "agentflow-beta\n\nflow pipeline[\"Pipeline\"]\n  A --> B\nend\n\nglobal\n  A\nend",
    "ok db58e098",
  ),
  (
    "agentflow-beta\n\nglobal\n  A --> X\nend\n\nflow f[\"Flow\"]\n  A --> B\n  X --> B\nend",
    "ok 174cc17f",
  ),
  (
    "agentflow-beta\n\nflow f[\"Flow\"]\n  global\n    A\n  end\n  A --> B\nend",
    "ok 4c9fd04d",
  ),
  (
    "agentflow-beta\n\nglobal\n  A[\"Shared input\"]\n  D{\"Decision\"}\nend\n\nflow f[\"Flow\"]\n  A --> B --> D\nend",
    "ok 6cad0701",
  ),
  (
    "agentflow-beta\n\nglobal\n  A\nend\n\nglobal\n  B\nend\n\nflow f[\"Flow\"]\n  A --> B --> C\nend",
    "ok 02d67fef",
  ),
  (
    "agentflow-beta\n\nflow f[\"global settings\"]\n  a[\"a global thing\"] --> b\nend",
    "ok 19db08cb",
  ),
  (
    "agentflow-beta TB\n  flow f[\"F\"]\n    a[\"Alpha\"]@{\n      instruction: \"do the thing\"\n    }\n  end",
    "ok 1914411e",
  ),
  (
    "agentflow-beta TB\n  x --> b[\"Beta\"]@{\n    instruction: \"hand off\"\n  }",
    "ok e8985325",
  ),
  ("agentflow-beta TB\n  a[\"Alpha\"]\n  a --> b", "ok a383f523"),
  ("agentflow-beta TB\n  a[\"Alpha\"]\n  b[\"Beta\"]\n  a --> b", "ok 34d055ca"),
  ("agentflow-beta TB\n  a[\"Alpha\"]\n  b --> a", "ok 38775b48"),
  (
    "agentflow-beta TB\n  a[\"sq\"]\n  c{\"diamond\"}\n  d[/\"trap\"/]\n  f --> a",
    "ok c92601fe",
  ),
  ("agentflow-beta TB\n  a --> b\n  b --> c\n  c --> d", "ok 85dee191"),
  (
    "agentflow-beta TB\n  flow pipeline[\"Pipeline\"]\n    a --> b\n  end", "ok 6ff4b5ac",
  ),
  (
    "agentflow-beta TB\n  flow outer[\"Outer\"]\n    flow inner[\"Inner\"]\n      n1 --> n2\n    end\n  end",
    "ok 83ea17b4",
  ),
  ("agentflow-beta TB\n  a --> b\n  c --> d", "ok 9732990a"),
  (
    "agentflow-beta TB\n  flow pipeline[\"Pipeline\"]\n    inner --> next\n  end",
    "ok 577d307d",
  ),
  ("agentflow-beta TB\n  flow p[\"P\"]\n    a --> b\n  end", "ok 732bdaf0"),
  ("agentflow-beta TB\n  c --> d", "ok cdaad214"),
  ("agentflow-beta TB\n  a[\"A\"]\n  a@{ myExtension: 42 }", "ok 65a1c494"),
  (
    "agentflow-beta TB\n  flow f[\"F\"]\n    a --> b\n  end\n  f@{ totallyCustomKey: \"opaque\" }",
    "ok 2986d6af",
  ),
  (
    "agentflow-beta TB\n  flow f[\"F\"]\n    a --> b\n  end\n  f@{ execution: \"parallel\" }",
    "ok aec0e87b",
  ),
  (
    "agentflow-beta TB\n  a e1@--> b\n  e1@{ instruction: \"hand off\", weight: 5 }",
    "ok 1dfa458b",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]\n  a@{ prompt: \"do the thing\" }", "ok d33818a9",
  ),
  (
    "agentflow-beta TB\n  call[\"call\"]@{ shape: action, connectorRef: \"nonexistent.op\" }\n  input[\"in\"]@{ shape: input }\n  input --> call",
    "error syntax agentflow agentflow\nParse error on line 5:\n\n^\nExpecting 'NODE_STRING', got 'CALLBACKNAME'",
  ),
  (
    "agentflow-beta TB\n  a[\"First\"]\n  a[\"Second\"]\n  a --> b", "ok 246a5f33",
  ),
  (
    "agentflow-beta TB\n  connectors[\"My group\"]\n  connectors --> b", "ok 3c37974b",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]\n  a@{ shape: NotAShape }", "error semantic agentflow agentflow\nNo such shape: NotAShape. Shape names should be lowercase.",
  ),
  (
    "agentflow-beta TB\n  flow f[\"F\"]\n    a --> b\n  end\n  f@{ view: \"collapsed\" }",
    "ok d309dbf6",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]\n  a@{\n    __proto__:\n      polluted: true\n  }",
    "ok 8840a780",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]\n  a@{ constructor: \"x\", prototype: \"y\", description: \"kept\" }",
    "ok 83f6a890",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]\n  a@{\n    params:\n      - name: first\n        __proto__:\n          polluted: true\n    description: \"kept\"\n  }",
    "ok ae521d48",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]\n  a@{ shape: rounded, description: \"hello\", myExtension: 42 }",
    "ok a7c21966",
  ),
  (
    "agentflow-beta TB\n  connector github[\"GitHub\"]@{\n    protocol: \"mcp\",\n    transport: \"stdio\",\n  }",
    "ok 2ec3a77a",
  ),
  (
    "agentflow-beta TB\n  connector github[\"GitHub\"]@{\n    protocol: \"mcp\",\n    endpoint: \"https://api.github.com\"\n    token_required: true,\n  }",
    "ok 7771b051",
  ),
  (
    "agentflow-beta TB\n  a[\"Alpha\"]\n  a@{\n    description: \"alpha node\",\n    instruction: \"be careful\",\n  }",
    "ok 7ab4e306",
  ),
  (
    "agentflow-beta TB\n  flow f[\"Flow\"]@{\n    model: \"claude-opus-4\",\n    memory: \"shared\",\n  }\n    a --> b\n  end",
    "ok 7c1839c9",
  ),
  (
    "agentflow-beta TB\n  connector github[\"GitHub\"]@{\n    protocol: \"mcp\", # main protocol\n    transport: \"stdio\"\n  }",
    "ok 2ec3a77a",
  ),
  (
    "agentflow-beta TB\n  a[\"Alpha\"]\n  a@{\n    instruction: |\n      Do a thing,\n      then stop\n    protocol: \"mcp\",\n  }",
    "ok 195b05ac",
  ),
  (
    "agentflow-beta TB\n  a[\"Alpha\"]\n  a@{\n    tools: [\"read\",\n      \"write\"],\n    protocol: \"mcp\"\n  }",
    "ok 034d66c3",
  ),
  (
    "agentflow-beta TB\n  a[\"Alpha\"]\n  a@{\n    note: 'first,\n      second',\n    protocol: \"mcp\"\n  }",
    "ok f85d6737",
  ),
  (
    "agentflow-beta LR\n  connector github[\"GitHub API\"]@{\n    protocol: \"http\",\n    endpoint: \"https://api.github.com\",\n    token_required: true,\n  }\n\n  query[\"query\"]\n  query@{ shape: input }\n  fetch_issues[\"fetch_issues\"]\n  fetch_issues@{ shape: tool, connectorRef: \"github.list_issues\" }\n  query --> fetch_issues",
    "ok 2fd04dd2",
  ),
  (
    "agentflow-beta TB\n  connector github[\"GitHub\"]@{ protocol: \"mcp\", }", "ok 6157ec53",
  ),
  (
    "agentflow-beta TB\n  a[\"Alpha\"]\n  a@{\n    protocol: *undefined_alias,\n  }",
    "ok 7977b43b",
  ),
  (
    "agentflow-beta TB\n  classDef highlight fill:#f9f,stroke:#333,stroke-width:2px\n  a:::highlight --> b\n  style a fill:#0f0\n  linkStyle 0 stroke:red,stroke-width:3px",
    "ok 39e23166",
  ),
  (
    "agentflow-beta TB\n  a[\"Alpha\"]\n  a@{ icon: \"star\", img: \"http://example/a.png\", w: 100, h: 50, view: \"collapsed\" }\n  a:::highlight\n  a --> b",
    "ok a4751ece",
  ),
  (
    "agentflow-beta TB\n  flow researcher[\"Researcher\"]\n    a --> b\n  end\n  researcher@{ model: \"claude-opus-4-6\", memory: \"shared\" }",
    "ok 4db671c6",
  ),
  (
    "agentflow-beta TB\n  connector github[\"GitHub\"]\n  github@{ protocol: \"mcp\", transport: \"stdio\" }\n  connector slack[\"Slack\"]\n  slack@{ protocol: \"http\" }",
    "ok c11b6639",
  ),
  (
    "agentflow-beta TB\n  file_path[\"file_path\"]\n  file_path@{ shape: input, value: \"src/HelloWorld.java\" }",
    "ok cb07ee9d",
  ),
  (
    "agentflow-beta TB\n  a -- yes --> b\n  a --x c\n  refdoc1[\"RefDoc\"]\n  refdoc1@{ shape: refdoc }\n  a -.- refdoc1",
    "ok 2530c6a2",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]@{ icon: \"fa:bell\", form: circle }\n  b[\"B\"]\n  a --> b",
    "ok 152ae67e",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]@{ img: \"https://example.com/x.png\", w: 40, h: 40 }\n  b[\"B\"]\n  a --> b",
    "ok 75004631",
  ),
  (
    "agentflow-beta TB\n  a[\"Real label\"]@{ icon: \"fa:bell\" }\n  b[\"B\"]\n  a --> b",
    "ok 184f7dd2",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]@{ shape: icon, icon: \"fa:bell\" }\n  b[\"B\"]\n  a --> b",
    "ok 53710435",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]@{ icon: \"fa:bell\", img: \"x.png\", form: circle, pos: t, w: 40, h: 40, description: \"kept\" }\n  b[\"B\"]\n  a --> b",
    "ok 28bf0b54",
  ),
  (
    "agentflow-beta TB\n  t[\"T\"]@{ shape: task }\n  o[\"O\"]@{ shape: tool }\n  i[\"I\"]@{ shape: input }\n  d[\"D\"]@{ shape: decision }\n  r[\"R\"]@{ shape: refdoc }\n  c[\"C\"]@{ shape: action }\n  t --> o --> i --> d --> r --> c",
    "ok da568825",
  ),
  (
    "agentflow-beta TB\n\n  flow f2[\"F2\"]\n    a --> b\n  end\n\n  flow f1[\"F1\"]\n    c --> d\n  end",
    "ok 71e12b39",
  ),
  (
    "agentflow-beta TB\n  flow outer[\"Outer\"]\n    flow inner[\"Inner\"]\n      a --> b\n    end\n    c --> d\n  end",
    "ok 437d3464",
  ),
  (
    "agentflow-beta TB\n  flow outer[\"Outer\"]\n    flow inner[\"Inner\"]\n      a[\"Alpha\"]\n    end\n  end",
    "ok 55e2d1e5",
  ),
  (
    "agentflow-beta TB\n  flow outer[\"Outer\"]\n    a[\"${wide}\"] --> b[\"B\"]\n  end",
    "ok 6dfb683f",
  ),
  (
    "agentflow-beta TB\n  search[\"search\"]\n  search@{ shape: subroutine, returns: \"Result\" }",
    "ok f5f084c3",
  ),
  (
    "agentflow-beta TB\n  search[\"search\"]\n  search@{ shape: tool }", "ok e114a889",
  ),
  (
    "agentflow-beta TB\n  search[\"search\"]\n  search@{ shape: subprocess }", "ok 64f0f608",
  ),
  ("agentflow-beta TB\n  plain[\"plain node\"]", "ok 7e3d3449"),
  (
    "agentflow-beta TB\n  i[\"i\"]\n  i@{ shape: input }\n  h[\"h\"]\n  h@{ shape: action }",
    "ok 8101c681",
  ),
  (
    "agentflow-beta TB\n  a[\"a\"]\n  a@{ shape: subroutine }\n  b[\"b\"]\n  b@{ shape: tool }\n  c[\"c\"]\n  d[\"d\"]\n  d@{ shape: framed-rectangle }",
    "ok bb0ef6d1",
  ),
  (
    "agentflow-beta TB\n  search[\"search\"]\n  search@{ shape: tool, returns: \"Result\" }",
    "ok 283039f1",
  ),
  (
    "agentflow-beta TB\n  a[\"a\"]\n  a@{ shape: subprocess }\n  b[\"b\"]\n  b@{ shape: framed-rectangle }",
    "ok 6ff314d1",
  ),
  (
    "agentflow-beta TB\n  search[\"search\"]\n  search@{ shape: tool, retry: 3, cache: \"24h\", returns: \"Result\" }",
    "ok 0c788783",
  ),
  (
    "agentflow-beta TB\n\n  content_ref@{ shape: procs,* type: \"BilingualContent\" }",
    "ok 5d69fb87",
  ),
  (
    "agentflow-beta\nflow f[\"F\"]\n  a[\"A\"]\n  b[\"B\"]\n  c[\"C\"]@{\n\tshape: rounded\n  }\nend",
    "error syntax agentflow agentflow\nMetadata of \"c\" is not valid YAML. YAML: tabs are not allowed for indentation (5:9)",
  ),
  ("agentflow-beta TB\n  a[\"A\"]@{ x: *,\n    y: 1 }", "ok bd53c333"),
  (
    "agentflow-beta TB\n  a[\"A\"]@{ shape: rounded }\n\n  b[\"B\"]@{ shape: procs,* x: 1 }",
    "ok d0b1a3c0",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]@{ shape: Rounded }", "error semantic agentflow agentflow\nNo such shape: Rounded. Shape names should be lowercase.",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]@{ shape: rounded }\n\n  b[\"B\"]", "ok 29ba4f70",
  ),
  ("agentflow-beta TB\n", "ok 990ecac4"),
  (
    "agentflow-beta TB\n  research[\"Research\"]\n  research --> write", "ok 4ac17210",
  ),
  ("agentflow-beta LR\n  a --> b", "ok f702e8ce"),
  ("agentflow-beta TB\n  a[\"Alpha\"]\n  a --> a", "ok bcb55f8e"),
  (
    "agentflow-beta TB\n  a[\"Alpha\"]\n  b[\"Beta\"]\n  a --> b\n  b --> b", "ok d6a86027",
  ),
  ("agentflow-beta TB\n  flow pipeline\n    a --> b\n  end", "ok 747bbaea"),
  (
    "agentflow-beta TB\n  flow outer[\"Outer\"]\n    flow inner[\"Inner\"]\n      a --> b\n    end\n  end",
    "ok 2c5e31da",
  ),
  ("agentflow-beta TB\n  a --x b", "ok 846b14c8"),
  ("agentflow-beta TB\n  a -.- b", "ok db5610dc"),
  ("agentflow-beta TB\n  a -- yes --> b", "ok f46f3349"),
  (
    "agentflow-beta TB\n  s[\"Search\"]\n  s@{ shape: tool, returns: \"Result\" }",
    "ok a58d1b8c",
  ),
  ("agentflow-beta TB\n  a[\"Action\"]\n  a@{ shape: action }", "ok 66de1863"),
  (
    "agentflow-beta TB\n  i[\"x\"]\n  i@{ shape: input, value: \"literal\" }", "ok ed7a85db",
  ),
  ("agentflow-beta TB\n  r[\"Guide\"]\n  r@{ shape: refdoc }", "ok 4fe901c7"),
  ("agentflow-beta TB\n  d{\"is_valid?\"}", "ok 320e08c2"),
  (
    "agentflow-beta TB\n  connector github[\"GitHub\"]\n  connector slack[\"Slack\"]",
    "ok 65f292c2",
  ),
  (
    "agentflow-beta TB\n  connector github[\"GitHub\"]@{ protocol: \"mcp\", transport: \"stdio\" }",
    "ok 08155ebf",
  ),
  ("agentflow-beta TB\n  connector github@{ protocol: \"mcp\" }", "ok 8a3aae35"),
  (
    "agentflow-beta TB\n  connector github[\"GitHub\"]@{ protocol: \"mcp\" }\n  github@{ transport: \"stdio\" }",
    "ok 0c7f3c62",
  ),
  (
    "agentflow-beta TB\n  connector github[\"GitHub\"]@{\n    protocol: \"mcp\"\n    transport: \"stdio\"\n  }\n  a --> b",
    "ok 7e0c2284",
  ),
  ("agentflow-beta TB\n  a --> b & c", "ok e9ef7ddc"),
  (
    "agentflow-beta TB\n  a[\"Alpha\"]\n  a@{ description: \"alpha node\", instruction: \"be careful\" }",
    "ok baa77baf",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]\n  a@{ description: \"first\" }\n  a@{ instruction: \"second\" }",
    "ok 4ffe0784",
  ),
  (
    "agentflow-beta TB\n  flow pipeline[\"P\"]\n    a --> b\n  end\n  pipeline@{ model: \"claude-opus-4-6\", memory: \"shared\" }",
    "ok eb3333bc",
  ),
  (
    "agentflow-beta TB\n  flow pipeline[\"P\"]\n    a --> b\n  end\n  pipeline@{ view: \"collapsed\" }",
    "ok dba42ca8",
  ),
  (
    "agentflow-beta TB\n      flow first[\"First\"]\n        a[\"a\"]\n      end\n      flow second[\"Second\"]\n        b[\"b\"]\n      end\n      flow third[\"Third\"]\n        c[\"c\"]\n      end\n    ",
    "ok db58f9e8",
  ),
  (
    "agentflow-beta TB\n      flow outer[\"Outer\"]\n        flow inner[\"Inner\"]\n          a[\"a\"]\n        end\n      end\n      flow sibling[\"Sibling\"]\n        b[\"b\"]\n      end\n    ",
    "ok 6fe34269",
  ),
  (
    "agentflow-beta TB\n      flow one[\"One\"]\n        a[\"a\"]\n      end\n      flow two[\"Two\"]\n        b[\"b\"]\n      end\n      two@{ view: \"collapsed\" }\n      flow three[\"Three\"]\n        c[\"c\"]\n      end\n    ",
    "ok 0c251b3e",
  ),
  (
    "agentflow-beta TB\n  flow A[\"Flow A\"]\n    a1[\"Task A1\"]\n    a1 --> B\n  end\n  flow B[\"Flow B\"]\n    b1[\"Task B1\"]\n    b1 --> A\n  end",
    "ok 1b121153",
  ),
  (
    "agentflow-beta TB\n  flow orphan[\"Orphan\"]\n    a[\"Alpha\"]", "error syntax agentflow agentflow\nParse error on line 4:\n\n^\nExpecting 'end', got '$end'",
  ),
  (
    "agentflow-beta TB\n  flow reviewer[\"Review Agent\"]\n    changes[\"Gather changes\"]@{ shape: input }\n    analyse[\"Analyse diff\"]@{ shape: task }\n    lint[\"run_linter\"]@{ shape: tool }\n    ok[\"Clean?\"]@{ shape: decision }\n\n    changes --> analyse --> lint --> ok\n  end\n",
    "ok f96ba636",
  ),
  (
    "agentflow-beta TB\n  brief[\"Release brief\"]@{ shape: input }\n  flow writer[\"Drafting Agent\"]\n    draft[\"Draft the notes\"]@{ shape: task }\n    lookup[\"changelog_search\"]@{ shape: tool }\n    guide[\"Tone of voice\"]@{ shape: refdoc }\n    draft --> lookup\n    draft -.- guide\n  end\n  flow reviewer[\"Review Agent\"]\n    check[\"Check the claims\"]@{ shape: task }\n    ok[\"Accurate?\"]@{ shape: decision }\n    check --> ok\n  end\n  publish[\"Publish\"]@{ shape: action }\n  brief --> writer\n  writer --> reviewer\n  ok --> publish\n",
    "ok 9b0e4393",
  ),
  (
    "---\nconfig:\n  theme: default\n  look: classic\n  layout: dagre\n---\nagentflow-beta TB\n  brief[\"Release brief\"]@{ shape: input }\n  flow writer[\"Drafting Agent\"]\n    draft[\"Draft the notes\"]@{ shape: task }\n    lookup[\"changelog_search\"]@{ shape: tool }\n    guide[\"Tone of voice\"]@{ shape: refdoc }\n    draft --> lookup\n    draft -.- guide\n  end\n  flow reviewer[\"Review Agent\"]\n    check[\"Check the claims\"]@{ shape: task }\n    ok[\"Accurate?\"]@{ shape: decision }\n    check --> ok\n  end\n  publish[\"Publish\"]@{ shape: action }\n  brief --> writer\n  writer --> reviewer\n  ok --> publish\n",
    "ok 406aac0f",
  ),
  (
    "agentflow-beta LR\n  brief[\"Brief\"]@{ shape: input }\n  draft[\"Draft copy\"]@{ shape: task }\n  spellcheck[\"spell_check\"]@{ shape: tool }\n  guide[\"Style guide\"]@{ shape: refdoc }\n  publish[\"Publish\"]@{ shape: action }\n\n  brief --> draft --> spellcheck --> publish\n  draft -.- guide\n",
    "ok 795716a2",
  ),
  (
    "agentflow-beta TB\n  check[\"Tests pass?\"]@{ shape: decision }\n  ship[\"Ship it\"]@{ shape: action }\n  fix[\"Fix the build\"]@{ shape: task }\n  logs[\"Build logs\"]@{ shape: refdoc }\n\n  check -- yes --> ship\n  check -- no --> fix\n  fix --x check\n  fix -.- logs\n",
    "ok 081500c2",
  ),
  (
    "agentflow-beta TB\n  flow team[\"Content Team\"]\n    flow researcher[\"Researcher\"]\n      gather[\"Gather sources\"]@{ shape: task }\n    end\n\n    flow writer[\"Writer\"]\n      compose[\"Compose draft\"]@{ shape: task }\n    end\n\n    researcher --> writer\n  end\n",
    "ok 285b6386",
  ),
  (
    "agentflow-beta TB\n  global\n    corpus[\"Shared corpus\"]@{ shape: refdoc }\n  end\n\n  flow summariser[\"Summariser\"]\n    summarise[\"Summarise\"]@{ shape: task }\n    summarise -.- corpus\n  end\n\n  flow indexer[\"Indexer\"]\n    index[\"Build index\"]@{ shape: task }\n    index -.- corpus\n  end\n",
    "ok 0d494715",
  ),
  (
    "agentflow-beta TB\n  flow intake[\"Intake\"]\n    receive[\"Receive request\"]@{ shape: input }\n  end\n\n  flow processing[\"Processing\"]\n    validate[\"Validate\"]@{ shape: task }\n    enrich[\"Enrich\"]@{ shape: task }\n    validate --> enrich\n  end\n  processing@{ view: \"collapsed\" }\n\n  flow output[\"Output\"]\n    publish[\"Publish\"]@{ shape: action }\n  end\n\n  receive --> validate\n  enrich --> publish\n",
    "ok 9be81074",
  ),
  (
    "agentflow-beta LR\n  connector github[\"GitHub API\"]\n  github@{ protocol: \"http\", endpoint: \"https://api.github.com\" }\n\n  title[\"Issue title\"]@{ shape: input }\n  create[\"create_issue\"]@{ shape: tool, connectorRef: \"github.create_issue\" }\n\n  title --> create\n",
    "ok 9936209f",
  ),
  (
    "agentflow-beta TB\n  connector llm[\"LLM API\"]\n  llm@{ protocol: \"http\", endpoint: \"https://api.example.com/chat\" }\n\n  flow coffee_team[\"Coffee Team\"]\n    city[\"city\"]@{ shape: input, value: \"Stockholm\" }\n\n    flow researcher[\"Researcher\"]\n      research[\"research_location\"]@{ shape: tool, params: \"city :: String\", returns: \"Report\" }\n      write[\"write_copy\"]@{ shape: tool, connectorRef: \"llm.chat\", returns: \"CoffeeCopy\" }\n      city --> research --> write\n    end\n    researcher@{ instruction: \"Research the city and draft English coffee copy citing sources.\" }\n\n    flow designer[\"Designer\"]\n      render[\"generate_html\"]@{ shape: tool, connectorRef: \"llm.chat\", returns: \"String\" }\n      brand[\"Nordic Brand Guide\"]@{ shape: refdoc }\n      render -.- brand\n    end\n\n    researcher --> designer\n  end\n",
    "ok 3b8d5015",
  ),
  (
    "---\nconfig:\n  agentflow:\n    nodeSpacing: 70\n    rankSpacing: 70\n---\nagentflow-beta TB\n  a[\"A\"] --> b[\"B\"]\n",
    "ok 84c4113b",
  ),
  (
    "---\nconfig:\n  layout: elk\n---\nagentflow-beta TB\n  flow tools[\"Tools\"]\n    a[\"a\"]@{ shape: tool }\n    b[\"b\"]@{ shape: tool }\n  end\n  tools@{ algorithm: \"elk.rectpacking\" }\n",
    "ok 17ec66b6",
  ),
  (
    "%% §17 Complete Example — Coffee Team coffee-website builder (v0.8.1).\nagentflow-beta TB\n  connector llm_api[\"LLM API\"]\n  llm_api@{ protocol: \"http\", endpoint: \"https://api.example.com/chat\" }\n\n  flow coffee_team[\"Coffee Team\"]\n    city[\"city\"]\n    city@{ shape: input, type: \"String\", value: \"Stockholm\" }\n\n    flow researcher[\"Researcher\"]\n      research_loc[\"research_location\"]\n      research_loc@{ shape: tool, params: \"city :: String\", returns: \"String\", cache: \"24h\" }\n      write_copy[\"write_copy\"]\n      write_copy@{ shape: tool, connectorRef: \"llm_api.chat\", params: \"brief :: String\", returns: \"CoffeeCopy\", retry: 2 }\n      city --> research_loc --> write_copy\n    end\n    researcher@{ model: \"claude-sonnet-4-20250514\", instruction: \"Research the city and draft English coffee copy citing sources.\" }\n\n    flow translator[\"Translator\"]\n      translate_sv[\"translate_to_swedish\"]\n      translate_sv@{ shape: tool, connectorRef: \"llm_api.chat\", params: \"english :: CoffeeCopy\", returns: \"BilingualPage\" }\n    end\n    translator@{ model: \"claude-sonnet-4-20250514\" }\n\n    flow designer[\"Designer\"]\n      gen_html[\"generate_html\"]\n      gen_html@{ shape: tool, connectorRef: \"llm_api.chat\", params: \"page :: BilingualPage\", returns: \"String\" }\n      style_guide[\"Nordic Brand Guide\"]\n      style_guide@{ shape: refdoc }\n      gen_html -.- style_guide\n    end\n    designer@{ model: \"claude-sonnet-4-20250514\", instruction: \"Render the bilingual page as semantic HTML following the brand guide.\" }\n\n    researcher --> translator --> designer\n  end\n",
    "ok f20af06f",
  ),
  (
    "%% `cylinder` is one of the shapes v0.8.1 removed (§4.3.3). It is a hard error:\n%% the node still renders, coerced to the default shape, but the diagram is\n%% classified `error` rather than `warning`.\nagentflow-beta TB\n  input[\"q\"]\n  input@{ shape: input }\n  store[\"Store\"]\n  store@{ shape: \"cylinder\" }\n  input --> store\n",
    "ok 2d9f759f",
  ),
  (
    "%% A `flow` block with no `end`. The JISON parser raises, so no semantic model\n%% is produced and the outcome is `parse-error` rather than any diagnostic.\nagentflow-beta TB\n  flow orphan[\"Orphan\"]\n    a[\"Alpha\"]\n    b[\"Beta\"]\n    a --> b\n",
    "error syntax agentflow agentflow\nParse error on line 9:\n\n^\nExpecting 'end', got '$end'",
  ),
  (
    "%% Connector reference validator — dotted-operation form uses\n%% prefix-before-first-dot for resolution. With a declared `github`\n%% connector, `github.create_issue` resolves cleanly.\nagentflow-beta TB\n  connector github[\"GitHub\"]\n  payload[\"payload\"]\n  payload@{ shape: input }\n  create_issue[\"Create Issue\"]\n  create_issue@{ shape: tool, connectorRef: \"github.create_issue\" }\n  payload --> create_issue\n",
    "ok a113a61d",
  ),
  (
    "%% §16 Parallel Execution Pattern — `&` fan-out in edges only.\nagentflow-beta TB\n  query[\"query\"]\n  query@{ shape: input }\n  orchestrator[\"Orchestrate\"]\n  search[\"Search\"]\n  analyze[\"Analyze\"]\n  validate[\"Validate\"]\n  query --> orchestrator --> search & analyze & validate\n",
    "ok 07b0fff2",
  ),
  (
    "%% §16 Reference Document Pattern — `-.-` reference edge to a refdoc node.\nagentflow-beta TB\n  query[\"query\"]\n  query@{ shape: input }\n  gen_html[\"generate_html\"]\n  style_guide[\"Brand Guide\"]\n  style_guide@{ shape: refdoc }\n  query --> gen_html\n  gen_html -.- style_guide\n",
    "ok 2b4fa2cb",
  ),
  (
    "agentflow-beta TB\n  input[\"x\"]\n  input@{ shape: input }\n  a[\"Alpha\"]\n  b[\"Beta\"]\n  input --> a --> b\n",
    "ok eaffac4a",
  ),
  (
    "%% A Mermaid-valid shape that's not in agentflow's v0.8.1 catalogue and\n%% not in the removed-shape blacklist emits a SHAPE_UNSUPPORTED warning\n%% from transformData. (Removed shapes like `cylinder`, `doc`, `procs`\n%% emit SHAPE_REMOVED at error tier — see those fixtures.)\nagentflow-beta TB\n  input[\"q\"]\n  input@{ shape: input }\n  x[\"X\"]\n  y[\"Y\"]\n  x@{ shape: \"triangle\" }\n  input --> x --> y\n",
    "ok 30654f0d",
  ),
  (
    "agentflow-beta TB\n  flow article_generation@{\n         model: @{ shape: tool }\"claude-opus-4\"\n       }\n        A --> B\n  end",
    "error syntax agentflow agentflow\nParse error on line 3:\n         model: @{ shape: tool }\"claude-opus-4\"\n---------------------------------^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'EOF', 'SHAPE_DATA', got 'STR'",
  ),
  (
    "agentflow-beta\nflow f[\"F\"]\n  a[\"A\"]@{ shape: roe: rounded }\n  %% a note\n  b[\"B\"]\nend",
    "error semantic agentflow agentflow\nNo such shape: roe: rounded.",
  ),
  (
    "agentflow-beta TB\n  a[\"a\"]\n  a@{ shape: subprocess[ }\n  { shape: procs,* x:b[\"b\"]\n  b@{ shape: framed-rectangle }",
    "error semantic agentflow agentflow\nNo such shape: subprocess[.",
  ),
  (
    "agentflow-beta TB\n  call[\"call\"]@{ shape: action, connectorRef: \"nonexistent.op\" }\n  input[\"in\"]@{ se: input }\n  input --> call",
    "error syntax agentflow agentflow\nParse error on line 5:\n\n^\nExpecting 'NODE_STRING', got 'CALLBACKNAME'",
  ),
  (
    "agentflow-beta TB\n  flow )outer[\"Outer\"]\n    flow inner[\"Inner\"]\n      n1 --> n2\n    end\n  end",
    "error syntax agentflow agentflow\nLexical error on line 2. Unrecognized text.\n  flow )outer[\"Outer\"]\n-------^",
  ),
  (
    "agentflow-beta TB\n  flow team[global\n\"Content Team\"]\n    flow researcher[\"Researcher\"]\n      gather[\"Gather sourceslow-beta\n\n\"]@{ shape: task }\n    end\n\n    flow writer[\"Writer\"]\n      copose[\"Compose draft\"]@{ shape: task }\n    end\n\n    researcher --> writer\n  end\n",
    "error syntax agentflow agentflow\nParse error on line 3:\n\"Content Team\"]\n-^\nExpecting 'SQE', 'UNICODE_TEXT', 'TEXT', 'TAGSTART', got 'STR'",
  ),
  (
    "%% §16 Reference Document ment Pattern — `-.-` reference edge to a refdoc node.\nagentflow-beta TB\n  query[\"query\"]\n  query@{ shape: input }\n  gen_html[\"generate_html\"]\n  style_guide[\"Brand Guide\"]\n  style_guie@{ shape: refdoc }\n  query --> gen_html\n  gen_html -.- style_guide\n",
    "ok a4286f72",
  ),
  ("agentflow-beta TB\n  &r[\"Guide\"]\n  r@{ shape: refdoc }", "ok 106b5803"),
  (
    "agentflow-beta TB\nflow   [\"Alpha\"]\n  a@{ description: \"alpha ne\", instruction: \"be careful\" }",
    "error syntax agentflow agentflow\nParse error on line 4:\n\n^\nExpecting 'end', got '$end'",
  ),
  (
    "agentflow-beta TB\n  ow f@{ model: \"claude-opus-4\", memory: \"sred\" }\n    a --> b\n  end",
    "error syntax agentflow agentflow\nParse error on line 2:\n  ow f@{ model: \"claude-opus-4\", memory: \"sred\" }\n-----^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'EOF', got 'NODE_STRING'",
  ),
  (
    "agentflow-beta LR\n  connector github[\"GitHub API\"]\n  github@{ protocol: \"http\", endpoint: \"https://api.github.com\" }\n\n  title[\"Issue title\"]@{ shape: input }\n  create[\"create_issue\"]@{ shape: tool, connectorRef: \"github.create_issue\" }\nflow f\n  title --> create\n",
    "error syntax agentflow agentflow\nParse error on line 10:\n\n^\nExpecting 'end', got '$end'",
  ),
  (
    "agentflow-beta TB\n  global\n    corpus[\"Shared corpus\"]@{ shape: refdoc   end\n\n  flow summariser[\"Summariser\"]\n    summarise[\"Summarise\"]@{ shape: task }\n    summarise -.- corpus\n  end\n\n  flow indexer[\"Indexer\"]\n    index[\"Build index\"]@{ shape: task }\n    index -.- corpus\n  end\n",
    "error semantic agentflow agentflow\nNo such shape: refdoc   end\nflow summariser[\"Summariser\"] summarise[\"Summarise\"]@{ shape: task. Shape names should be lowercase.",
  ),
  (
    "---\nconfig:\n  layout: elk\n---\nagentflow-beta TB\n  flow tools[\"Tools\"]\n    a[\"a\"]@{ shape: tool }\nF\"]\n  a[\"    b[\"b\"]@{ shape: tool  }\n  end\n  tools@{ algorithm: \"elk.rectpacking\" }\n",
    "error syntax agentflow agentflow\nLexical error on line 8. Unrecognized text.\nF\"]\n--^",
  ),
  (
    "agentflow-beta TB\n  file_path[\"file_path\"]\n  file_path@{ shape: i flow f[\"F\"]\n nput, value: \"src/HelloWorld.java\" }",
    "error semantic agentflow agentflow\nNo such shape: i flow f[\"F\"]. Shape names should be lowercase.",
  ),
  (
    "agentflow-beta TB\n  a[\"Alpha\"]\n  a@{\n    description: \"alpha node\",\n    instruction: \"Accurate?\"be careful\",\n  }",
    "error syntax agentflow agentflow\nMetadata of \"a\" is not valid YAML. YAML: unexpected content after a value (3:4)",
  ),
  (
    "%% A Mermaid-valid shape that's not in agentflow's v0.8.1 catalogue and\n%% not in the removed-shape blacklist emits a SHAPE_UNSUPPORTED warning\n%% from transformData. (Removed shapes like `cylinder`, `doc`, `procs`\n%% emit SHAPE_REMOVED at error tier — see those fixtures.)\nagentflow-beta TB\n  input[\"q\"]\n  input@{ shape: input }\n  x[\"X\"]\n  y[\"Y\"]\n  x@{ shape: \"triangle\"\n  input --> x --> y\n",
    "error syntax agentflow agentflow\nMetadata of \"x\" is not valid YAML. YAML: bad indentation of a mapping entry (10:4)",
  ),
  (
    "agentflow-beta TB\n  flow f@{ model: \"claude-opus-4memory: \"shared\" }\n    a --> b\n  end",
    "error syntax agentflow agentflow\nParse error on line 5:\n\n^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'EOF', 'SHAPE_DATA', got '$end'",
  ),
  (
    "agentflow-beta TB\n  a[\"a\"]\n  a@{ shape: subrout end\n  endine }\n  b[\"b\"]\n  b@{ Beta\"shape: tool }\n  c[\"c\"]\n  d[\"d\"]\n  d@{ shape: framed-rectangle }",
    "error semantic agentflow agentflow\nNo such shape: subrout end endine.",
  ),
  (
    "agentflow-beta TB\n  a yesstyle a fill:red\n --> b", "error syntax agentflow agentflow\nParse error on line 2:\n  a yesstyle a fill:red\n----^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'EOF', got 'NODE_STRING'",
  ),
  (
    "agentflow-beta TB\n  a[lpha\"]\n  a@{\n    instruction: |\n      Do a thing,\n    e1@{ curve: basis }\n  then stop\n    protocol: \"mcp\",\n  },\n  }",
    "error syntax agentflow agentflow\nParse error on line 2:\n  a[lpha\"]\n---------^\nExpecting 'SQE', 'UNICODE_TEXT', 'TEXT', 'TAGSTART', got 'STR'",
  ),
  (
    "agentflow-beta\nflow f[\"F\"]\n  a[\"A\"linkStyle 0 stroke:red\n]\n  b[\"B\"]\n  c[\"C\"]@{\n\tshape: rounded\n  }\nend",
    "error syntax agentflow agentflow\nMetadata of \"c\" is not valid YAML. YAML: tabs are not allowed for indentation (6:9)",
  ),
  (
    "agentflow-beta TB\n  flow f[\"F\"]\n    a ---> b\n  end\n  f@{\n-beta TB\n}",
    "ok 46ad2336",
  ),
  (
    "agentflow-beta TB\n  flow A[\"Flow A\"]$ A\"]${viewA}\n    a1[\"Task A1\"]\n    a1 --> B\n  end\n  flow B[\"Flow B\"]${viewB}\n    b1[\"Task B1\"]\n    b1 --> A\n  end",
    "error syntax agentflow agentflow\nParse error on line 2:\n  flow A[\"Flow A\"]$ A\"]${viewA}\n------------------^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'EOF', 'SHAPE_DATA', got 'NODE_STRING'",
  ),
  (
    "agentflow-beta TB\n  a[\"a\"]\n  a@{ shape: subprocess }\n  b[\"\n  b@{ shape:e&: framed-rectangle }",
    "error syntax agentflow agentflow\nParse error on line 6:\n\n^\nExpecting 'SQE', 'UNICODE_TEXT', 'TEXT', 'TAGSTART', got '$end'",
  ),
  (
    "agentflow-beta B\n  a[\"A\"]@{ img: \"https://example.com/x.png\", w: 40, h: 40 }\n  b[\"B\"]\n  a --> b",
    "error syntax agentflow agentflow\nLexical error on line 1. Unrecognized text.\nagentflow-beta B\n--------------^",
  ),
  (
    "agentflow-beta--> TB\n  i[\"x\"]\n  i@{ sh--xape: input, value:@{ view: collapsed }\"literal\" }",
    "error syntax agentflow agentflow\nLexical error on line 1. Unrecognized text.\nagentflow-beta--> TB\n--------------^",
  ),
  (
    "agentflow-beta TB\n  a[\"Alpha\"]\n  a@{ descption: \"alpha node\", instruction: \"be careful\" }",
    "ok 80140b47",
  ),
  (
    "agentflow-beta TB\n  flow reviewer[\"Review Agent\"]\n    changes[\"Gather changes\"]@{ shape: input }\n    analyse[\"Analyse diff\"]@{ shape: task }\n    lint[\"run_linter\"]@{ shape: tool }\n   class a b\n ok[\"Clean?\"]@{ shape: decision }\n\n    changes --> analyse --> lint --> ok\n  end\n",
    "ok 8446598c",
  ),
  (
    "agentflow-beta TB\n  flow outer[\"Outer\"]\n    flow inner[\"Inner\"]\n      b[\"Task B\"]\n      b --> inne\"]\nr\n    end\n  end",
    "error syntax agentflow agentflow\nLexical error on line 5. Unrecognized text.\n      b --> inne\"]\n-----------------^",
  ),
  (
    "agentflow-beta TB\n  flow f[\"Flow\"]@{\n    model: \"claude-opus-4\",\n    memory: \"shared\",\n  }\n    a --> b\n  end@{ viw: collapsed }",
    "error syntax agentflow agentflow\nParse error on line 7:\n  end@{ viw: collapsed }\n-----^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'SPACE', 'EOF', 'flow', 'global', 'connector', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'STYLE', 'LINKSTYLE', 'CLASSDEF', 'CLASS', 'CLICK', 'NODE_STRING', got 'SHAPE_DATA'",
  ),
  (
    "agentflow-beta TB\n  flow intakd\n      flow sie[\"Intake\"]\n    receive[\"Receive request\"]@{ shape: input }\n  end\n\n  flow processing[\"Processing\"]\n    validate[\"Validate\"]@{ shape: task }\n    enrich[\"Enrich\"]@{ shape: task }\n    validate --> enrich\n  end\n  processing@{ view: warn\"collapsed\" }\n\n  flow output[\"Output\"]\n   publish[\"Publish\"]@{ shape: action }\n  end\n\n  receive --> validate\n  enrich --> publish\n",
    "error syntax agentflow agentflow\nParse error on line 21:\n\n^\nExpecting 'end', got '$end'",
  ),
  (
    "agentflow-beta TB\n    a[[\"Alpha\"]\n  a --> b", "error syntax agentflow agentflow\nParse error on line 2:\n    a[[\"Alpha\"]\n--------------^\nExpecting 'SUBROUTINEEND', 'UNICODE_TEXT', 'TEXT', 'TAGSTART', got 'SQE'",
  ),
  (
    "agentflow-beta TB\n  a[\"Real label\"]@{ :::icon: \"fa:bell\" }\n  b[\"B\"]\n  a --> b",
    "ok bccf13a9",
  ),
  (
    "agentflow-beta TB\n  flow f@{ model: \"m\", memory: y: \"sy: \"shared\", exxecution: \"parallel\", custom: 1 }\n    a --> b\n  end",
    "error syntax agentflow agentflow\nParse error on line 5:\n\n^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'EOF', 'SHAPE_DATA', got '$end'",
  ),
  (
    "agentflow-beta TB\n  i[\"i\"]\n  i@{ shape: input }\n  h[\"h\"]\n  h@{ ape: action }",
    "ok 0fe94623",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]\n  a@{ constructor: \"x\",\n    a  prototype: \";y\", description: \"kept\" }",
    "error syntax agentflow agentflow\nMetadata of \"a\" is not valid YAML. YAML: unexpected content after a value (3:4)",
  ),
  (
    "agentflow-beta TB\n  input[\"x\"]\n  input@{ shape: input }\n  a[\"Alpha\"]\n  b[\"Beta\"]x\n  input --> a --> b\n",
    "error syntax agentflow agentflow\nParse error on line 5:\n  b[\"Beta\"]x\n-----------^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'EOF', got 'NODE_STRING'",
  ),
  (
    "agentflow-beta TB\n\n  flow f[\"F\"]\n    a --> b end", "error syntax agentflow agentflow\nParse error on line 4:\n    a --> b end\n------------^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'EOF', got 'end'",
  ),
  (
    "---\nconfig:\n  theme: default\n  look: classic\n  layout: dagre\n---\nagentflow-beta TB\n  brief[\"Release brief\"]@{ shape: input }\n  flow writer[\"Drafting Agent\"]\n    draft[\"Draft the notes\"]@{ shape: task }\n    lookup[\"changelog_search\"]@{ shape: tool }\n    guide[\"Tone of voice\"]@{ shape: refdoc }click a href \"https://x.y\"\n\n    draft --> lookup\n    draft -.- guide\n  end\n  flow reviewer[\"Review Agent\"]\n    check[\"Check the claims\"]@{ shape: task }\n    ok[\"Accurate?\"]@{ shape: decision }\n    check --> ok\n  end\n  publish[\"Publi@{ shape: cylinder }sh\"]@{ shape: action }\n  brief --> writer\n  writer --> reviewer\n  ok --> publish\n",
    "error syntax agentflow agentflow\nParse error on line 12:\n    guide[\"Tone of voice\"]@{ shape: refdoc }click a href \"https://x.y\"\n--------------------------------------------------^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'EOF', got 'CLICK'",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]@{ shape: rounded }\n\n  b;[\"B\"]@{ shape: rounded }\n\nf  c[\"C\"]\"]\n",
    "error syntax agentflow agentflow\nParse error on line 4:\n  b;[\"B\"]@{ shape: rounded }\n----^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'SPACE', 'EOF', 'flow', 'global', 'connector', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'STYLE', 'LINKSTYLE', 'CLASSDEF', 'CLASS', 'CLICK', 'NODE_STRING', got 'SQS'",
  ),
  (
    "agentflow-beta TB\n  flow A[\"Flow A\"]\n    a1[\"Task A1\"]\n    a1 --> B\n  end\n  fe1@low B[\"Flow B\"]\n    b1[\"Task B1k B1\"]\n    b1 --> A\n  end",
    "error syntax agentflow agentflow\nParse error on line 6:\n  fe1@low B[\"Flow B\"]\n--^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'SPACE', 'EOF', 'flow', 'global', 'connector', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'STYLE', 'LINKSTYLE', 'CLASSDEF', 'CLASS', 'CLICK', 'NODE_STRING', got 'LINK_ID'",
  ),
  (
    "agentflow-beta TB\n  flow f[\"F\"]\n [\"Alpha\"]@{\n      instruction: \"do the thing\"\n    }\n  end",
    "error syntax agentflow agentflow\nParse error on line 3:\n [\"Alpha\"]@{\n-^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'SPACE', 'EOF', 'flow', 'global', 'connector', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'STYLE', 'LINKSTYLE', 'CLASSDEF', 'CLASS', 'CLICK', 'NODE_STRING', got 'SQS'",
  ),
  (
    "agentflow-beta TB\n  flow outer[\"Outer\"]\n    flow inn]er[\"Inner\"]\n --    a --> b\n    end\n    c --> d\n  end",
    "error syntax agentflow agentflow\nLexical error on line 3. Unrecognized text.\n    flow inn]er[\"Inner\"]\n------------^",
  ),
  (
    "agentflow-beta TB\n  searcsearch\"]\n  searcarch@{ shape: tool, ret: 3, cache: \"24h\", returns: \"Result\" }",
    "error syntax agentflow agentflow\nLexical error on line 2. Unrecognized text.\n  searcsearch\"]\n--------------^",
  ),
  (
    "agentflow-beta LR\n  brief[\"Brief\"]@{A\" shape: input }\n  draft[\"Draft copy\"]@{ shape: task }\n  spellcheck[\"spell_check\"]@{ shape: tool }\n  guide[\"Style guide\"]@{ shape: refdoc }\n  publish[\"Publish\"]@{ shape: action }\n\n  brief --> draft --> spellcheck --> publish\n  draft -.- guide\n",
    "error syntax agentflow agentflow\nMetadata of \"brief\" is not valid YAML. YAML: unexpected content after a value (2:17)",
  ),
  (
    "%% A `flow` block with no `end`. The JISON parser raises, so no semantic model\n\n%% is produced and the outcome is `parse-error` rather than any diagnostic.\nagentflow-beta TB\n  flow orphan[\"Orphan\"]\n    a[\"Alpha\"]\n    b[\"Beta\"]\n    a --> b\n",
    "error syntax agentflow agentflow\nParse error on line 10:\n\n^\nExpecting 'end', got '$end'",
  ),
  (
    "agentflow-beta TB\n      flow outer[\"Outer\"]\n        flow inner[\"Inner\"]\n         a[\"a\"]\n        end\n      end  end\n      flow sibling[\"Sibling\"]\n        b[\"b\"]\n      end\n    ",
    "error syntax agentflow agentflow\nParse error on line 6:\n      end  end\n-----------^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'SPACE', 'EOF', 'flow', 'global', 'connector', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'STYLE', 'LINKSTYLE', 'CLASSDEF', 'CLASS', 'CLICK', 'NODE_STRING', got 'end'",
  ),
  (
    "agentflow-beta TB\n  a[\"First\"]\n  a[\"Second\"]\n e1@ a --> b", "error syntax agentflow agentflow\nParse error on line 4:\n e1@ a --> b\n-^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'SPACE', 'EOF', 'flow', 'global', 'connector', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'STYLE', 'LINKSTYLE', 'CLASSDEF', 'CLASS', 'CLICK', 'NODE_STRING', got 'LINK_ID'",
  ),
  ("agentflow-beta TB\n  a[\"Alphaha\"]\n  a --> a", "ok 0b660894"),
  (
    "agentflow-beta TB\n  connector github[\"GitHub\"]{ protocol: \"mcp\", transport: \"stddio\" }",
    "error syntax agentflow agentflow\nParse error on line 2:\n  connector github[\"GitHub\"]{ protocol: \"mcp\", transport: \"stddio\" }\n----------------------------^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'EOF', 'SHAPE_DATA', got 'DIAMOND_START'",
  ),
  (
    "agentflow-beta TB\n      flow --irst[\"First\"]\n        a[\"a\"]\n       end\n      flow second[\"Second\"]\n        b[\"b\"]\n      end\n      flothird[\"Third\"]\n        c[\"c\"]\n      end\n    ",
    "error syntax agentflow agentflow\nParse error on line 2:\n      flow --irst[\"First\"]\n----------^\nExpecting 'SPACE', 'COMMENT', 'SEMI', 'NEWLINE', 'EOF', got 'START_LINK'",
  ),
  (
    "agentflow-beta TB\n  connect\"]\n  A -ors[d, descr\"My group\"]\n  connectors --> b",
    "error syntax agentflow agentflow\nLexical error on line 2. Unrecognized text.\n  connect\"]\n----------^",
  ),
  (
    "agentflow-beta TB\n  flow f[\"F\"]\n    a[\"Alpha\"lpha\"]@{\n      intruction: \"do the thing\"\n    }\n  end",
    "error syntax agentflow agentflow\nParse error on line 3:\n    a[\"Alpha\"lpha\"]@{\n------------------^\nExpecting 'SQE', 'UNICODE_TEXT', 'TEXT', 'TAGSTART', got 'STR'",
  ),
  (
    "agentflow-beta TB\n | a[\"A@{ shapeclick a href \"https://x.y\"\n: cylinder }lpha\"]\n  a@{ shape: \"cylinder\" }\n  b[\"Beta\"]\n  a --> b",
    "error syntax agentflow agentflow\nParse error on line 2:\n | a[\"A@{ shapeclick a href \"https://x.y\"\n-^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'SPACE', 'EOF', 'flow', 'global', 'connector', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'STYLE', 'LINKSTYLE', 'CLASSDEF', 'CLASS', 'CLICK', 'NODE_STRING', got 'PIPE'",
  ),
  (
    "agentflow-beta TB\n  a[\"Alpha\"]\n  a@{\n    description: \"alpha node\",\n    global\nnstruction: \"be careful\",\n  }",
    "error syntax agentflow agentflow\nMetadata of \"a\" is not valid YAML. YAML: unexpected content after a value (3:4)",
  ),
  (
    "agentflow-beta TB\n  connector github[\"GitHu & b\"]\n  connector slaic.\nagck[\"Slack\"]",
    "ok 00fd1269",
  ),
  (
    "agentflow-beta TB\n  flow article_generation@{\n         model:class a b\n\"clau]de-opus-4\"\n       }\n        A --> B\n  end",
    "error syntax agentflow agentflow\nMetadata of \"article_generation\" is not valid YAML. YAML: end of the stream or a document separator is expected (2:26)",
  ),
]
