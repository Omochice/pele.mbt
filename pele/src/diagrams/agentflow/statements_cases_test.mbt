// What pele makes of each agentflow input of its reference corpus, its documentation corpus, Mermaid's fixtures and the goldens.
// Generated from pele 1.8.0: a success is a hash of the dump written as `dump_statements` writes it.

///|
let statements_cases : Array[(String, String)] = [
  ("agentflow-beta TB\n  a --> b", "ok 43d7e1c4"),
  ("%% leading comment\nagentflow-beta TB\n  a --> b", "ok 43d7e1c4"),
  ("%% first\n%% second\n%% third\nagentflow-beta TB\n  a --> b", "ok 43d7e1c4"),
  ("agentflow-beta TB\n%% trailing header comment\n  a --> b", "ok 43d7e1c4"),
  ("agentflow-beta TB\n  a --> b\n%% mid comment\n  b --> c", "ok a9ec7eda"),
  (
    "agentflow-beta TB\n  a --> b\n%% first mid comment\n%% second mid comment\n  b --> c",
    "ok a9ec7eda",
  ),
  ("agentflow-beta TB\n  a --> b\n%% trailing comment", "ok 43d7e1c4"),
  ("agentflow-beta TB\n  a --> b\n%%no-space comment\n  b --> c", "ok a9ec7eda"),
  ("agentflow-beta TB\n  a --> b\n%%\n  b --> c", "ok a9ec7eda"),
  (
    "agentflow-beta TB\n  a[Plain %% not part of the label\nlabel]\n  b --> a", "ok 150dccf7",
  ),
  (
    "agentflow-beta TB\n  a(-ellipse %% not part of the label\nlabel-)\n  b --> a",
    "ok ee55ec70",
  ),
  (
    "agentflow-beta TB\n  a[/trap %% not part of the label\nlabel/]\n  b --> a",
    "ok 9b39a130",
  ),
  (
    "agentflow-beta TB\n%% before flow\nflow f1[\"Flow One\"]\n%% inside flow\n  a --> b\nend\n%% after flow",
    "ok 7db38583",
  ),
  (
    "agentflow-beta TB\n%% before connector\nconnector github[\"GitHub\"]\n%% after connector\n  a --> b",
    "ok 661bd122",
  ),
  (
    "agentflow-beta TB\n  flow A[\"Flow A\"]${viewA}\n    a1[\"Task A1\"]\n    a1 --> B\n  end\n  flow B[\"Flow B\"]${viewB}\n    b1[\"Task B1\"]\n    b1 --> A\n  end",
    "error syntax agentflow agentflow\nParse error on line 2:\n  flow A[\"Flow A\"]${viewA}\n------------------^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'EOF', 'SHAPE_DATA', got 'NODE_STRING'",
  ),
  ("agentflow-beta TB\n  a[\"A\"]\n  b[\"B\"]\n  a --> b", "ok e59667dc"),
  (
    "agentflow-beta TB\n  a[\"A\"]\n  b[\"B\"]\n  a ${operator} b", "error syntax agentflow agentflow\nParse error on line 4:\n  a ${operator} b\n----^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'EOF', got 'NODE_STRING'",
  ),
  (
    "agentflow-beta TB\n  a[\"A\"]\n  b[\"B\"]\n  c[\"C\"]\n  a --> b\n  b --x c",
    "ok 60e6308d",
  ),
  (
    "agentflow-beta TB\n  flow myFlow[\"My Flow\"]\n    a[\"Task A\"]\n    a --> myFlow\n  end",
    "ok 6e8703bd",
  ),
  (
    "agentflow-beta TB\n  flow outer[\"Outer\"]\n    flow inner[\"Inner\"]\n      b[\"Task B\"]\n      b --> inner\n    end\n  end",
    "ok de316c85",
  ),
  (
    "agentflow-beta TB\n  flow top[\"Top\"]\n    flow mid[\"Mid\"]\n      flow leafFlow[\"Leaf\"]\n        c[\"Task C\"]\n      end\n      m[\"Task M\"]\n      m --> mid\n    end\n  end",
    "ok 09c81a41",
  ),
  (
    "agentflow-beta TB\n  flow outer[\"Outer\"]\n    flow inner[\"Inner\"]\n      b[\"Task B\"]\n      b --> inner\n    end\n    a[\"Task A\"]\n    a --> outer\n  end",
    "ok 550e18ff",
  ),
  ("agentflow-beta TB\n  flow f[\"F\"]\n    a --> b\n  end", "ok f968c8f6"),
  ("agentflow-beta TB\n${body}\n", "ok 5ba715e1"),
  (
    "agentflow-beta\n\nglobal\n  A\nend\n\nflow\n A --> B --> C\nend", "ok e93dc0ce",
  ),
  (
    "agentflow-beta\n\nflow pipeline[\"Pipeline\"]\n  A --> B\nend\n\nglobal\n  A\nend",
    "ok b83da8b5",
  ),
  (
    "agentflow-beta\n\nglobal\n  A --> X\nend\n\nflow f[\"Flow\"]\n  A --> B\n  X --> B\nend",
    "ok 5d6d7911",
  ),
  (
    "agentflow-beta\n\nflow f[\"Flow\"]\n  global\n    A\n  end\n  A --> B\nend",
    "ok f859d373",
  ),
  (
    "agentflow-beta\n\nglobal\n  A[\"Shared input\"]\n  D{\"Decision\"}\nend\n\nflow f[\"Flow\"]\n  A --> B --> D\nend",
    "ok 57d4bbc4",
  ),
  (
    "agentflow-beta\n\nglobal\n  A\nend\n\nglobal\n  B\nend\n\nflow f[\"Flow\"]\n  A --> B --> C\nend",
    "ok a50842cc",
  ),
  (
    "agentflow-beta\n\nflow f[\"global settings\"]\n  a[\"a global thing\"] --> b\nend",
    "ok c7d20621",
  ),
  ("agentflow-beta TB\n  a[\"Alpha\"]\n  a --> b", "ok 92513bb1"),
  ("agentflow-beta TB\n  a[\"Alpha\"]\n  b[\"Beta\"]\n  a --> b", "ok 235f21bb"),
  ("agentflow-beta TB\n  a[\"Alpha\"]\n  b --> a", "ok 251cb7b5"),
  (
    "agentflow-beta TB\n  a[\"sq\"]\n  c{\"diamond\"}\n  d[/\"trap\"/]\n  f --> a",
    "ok bb4aa9ae",
  ),
  ("agentflow-beta TB\n  a --> b\n  b --> c\n  c --> d", "ok bad63f3a"),
  (
    "agentflow-beta TB\n  flow pipeline[\"Pipeline\"]\n    a --> b\n  end", "ok 6f2065d8",
  ),
  (
    "agentflow-beta TB\n  flow outer[\"Outer\"]\n    flow inner[\"Inner\"]\n      n1 --> n2\n    end\n  end",
    "ok c8474efb",
  ),
  ("agentflow-beta TB\n  a --> b\n  c --> d", "ok 559f1bca"),
  (
    "agentflow-beta TB\n  flow pipeline[\"Pipeline\"]\n    inner --> next\n  end",
    "ok 52a6fe52",
  ),
  ("agentflow-beta TB\n  flow p[\"P\"]\n    a --> b\n  end", "ok 036956ea"),
  ("agentflow-beta TB\n  c --> d", "ok 1dd13944"),
  (
    "agentflow-beta TB\n  a[\"First\"]\n  a[\"Second\"]\n  a --> b", "ok e5286e03",
  ),
  (
    "agentflow-beta TB\n  connectors[\"My group\"]\n  connectors --> b", "ok 8bbcb5f2",
  ),
  (
    "agentflow-beta TB\n  classDef highlight fill:#f9f,stroke:#333,stroke-width:2px\n  a:::highlight --> b\n  style a fill:#0f0\n  linkStyle 0 stroke:red,stroke-width:3px",
    "ok 5c13b5d8",
  ),
  (
    "agentflow-beta TB\n\n  flow f2[\"F2\"]\n    a --> b\n  end\n\n  flow f1[\"F1\"]\n    c --> d\n  end",
    "ok 2d2849a4",
  ),
  (
    "agentflow-beta TB\n  flow outer[\"Outer\"]\n    flow inner[\"Inner\"]\n      a --> b\n    end\n    c --> d\n  end",
    "ok 2494afb6",
  ),
  (
    "agentflow-beta TB\n  flow outer[\"Outer\"]\n    flow inner[\"Inner\"]\n      a[\"Alpha\"]\n    end\n  end",
    "ok a7d8129e",
  ),
  (
    "agentflow-beta TB\n  flow outer[\"Outer\"]\n    a[\"${wide}\"] --> b[\"B\"]\n  end",
    "ok fe449e08",
  ),
  ("agentflow-beta TB\n  plain[\"plain node\"]", "ok c1ca17fc"),
  ("agentflow-beta TB\n", "ok 91d43336"),
  (
    "agentflow-beta TB\n  research[\"Research\"]\n  research --> write", "ok 9da2da42",
  ),
  ("agentflow-beta LR\n  a --> b", "ok d227d11c"),
  ("agentflow-beta TB\n  a[\"Alpha\"]\n  a --> a", "ok fb5420f5"),
  (
    "agentflow-beta TB\n  a[\"Alpha\"]\n  b[\"Beta\"]\n  a --> b\n  b --> b", "ok 8928b679",
  ),
  ("agentflow-beta TB\n  flow pipeline\n    a --> b\n  end", "ok 76f1317c"),
  (
    "agentflow-beta TB\n  flow outer[\"Outer\"]\n    flow inner[\"Inner\"]\n      a --> b\n    end\n  end",
    "ok 605ade97",
  ),
  ("agentflow-beta TB\n  a --x b", "ok 959e9cc5"),
  ("agentflow-beta TB\n  a -.- b", "ok 961e4cef"),
  ("agentflow-beta TB\n  a -- yes --> b", "ok 72e68bad"),
  ("agentflow-beta TB\n  d{\"is_valid?\"}", "ok c3817079"),
  (
    "agentflow-beta TB\n  connector github[\"GitHub\"]\n  connector slack[\"Slack\"]",
    "ok dbc35945",
  ),
  ("agentflow-beta TB\n  a --> b & c", "ok 3edc6e54"),
  (
    "agentflow-beta TB\n      flow first[\"First\"]\n        a[\"a\"]\n      end\n      flow second[\"Second\"]\n        b[\"b\"]\n      end\n      flow third[\"Third\"]\n        c[\"c\"]\n      end\n    ",
    "ok 3131ae53",
  ),
  (
    "agentflow-beta TB\n      flow outer[\"Outer\"]\n        flow inner[\"Inner\"]\n          a[\"a\"]\n        end\n      end\n      flow sibling[\"Sibling\"]\n        b[\"b\"]\n      end\n    ",
    "ok b57ec756",
  ),
  (
    "agentflow-beta TB\n  flow A[\"Flow A\"]\n    a1[\"Task A1\"]\n    a1 --> B\n  end\n  flow B[\"Flow B\"]\n    b1[\"Task B1\"]\n    b1 --> A\n  end",
    "ok f2d8d19a",
  ),
  (
    "agentflow-beta TB\n  flow orphan[\"Orphan\"]\n    a[\"Alpha\"]", "error syntax agentflow agentflow\nParse error on line 4:\n\n^\nExpecting 'end', got '$end'",
  ),
  (
    "---\nconfig:\n  agentflow:\n    nodeSpacing: 70\n    rankSpacing: 70\n---\nagentflow-beta TB\n  a[\"A\"] --> b[\"B\"]\n",
    "ok e59667dc",
  ),
  (
    "%% A `flow` block with no `end`. The JISON parser raises, so no semantic model\n%% is produced and the outcome is `parse-error` rather than any diagnostic.\nagentflow-beta TB\n  flow orphan[\"Orphan\"]\n    a[\"Alpha\"]\n    b[\"Beta\"]\n    a --> b\n",
    "error syntax agentflow agentflow\nParse error on line 9:\n\n^\nExpecting 'end', got '$end'",
  ),
  (
    "agentflow-beta TB\n  flow )outer[\"Outer\"]\n    flow inner[\"Inner\"]\n      n1 --> n2\n    end\n  end",
    "error syntax agentflow agentflow\nLexical error on line 2. Unrecognized text.\n  flow )outer[\"Outer\"]\n-------^",
  ),
  (
    "agentflow-beta TB\n  a yesstyle a fill:red\n --> b", "error syntax agentflow agentflow\nParse error on line 2:\n  a yesstyle a fill:red\n----^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'EOF', got 'NODE_STRING'",
  ),
  (
    "agentflow-beta TB\n  flow A[\"Flow A\"]$ A\"]${viewA}\n    a1[\"Task A1\"]\n    a1 --> B\n  end\n  flow B[\"Flow B\"]${viewB}\n    b1[\"Task B1\"]\n    b1 --> A\n  end",
    "error syntax agentflow agentflow\nParse error on line 2:\n  flow A[\"Flow A\"]$ A\"]${viewA}\n------------------^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'EOF', 'SHAPE_DATA', got 'NODE_STRING'",
  ),
  (
    "agentflow-beta TB\n  flow outer[\"Outer\"]\n    flow inner[\"Inner\"]\n      b[\"Task B\"]\n      b --> inne\"]\nr\n    end\n  end",
    "error syntax agentflow agentflow\nLexical error on line 5. Unrecognized text.\n      b --> inne\"]\n-----------------^",
  ),
  (
    "agentflow-beta TB\n    a[[\"Alpha\"]\n  a --> b", "error syntax agentflow agentflow\nParse error on line 2:\n    a[[\"Alpha\"]\n--------------^\nExpecting 'SUBROUTINEEND', 'UNICODE_TEXT', 'TEXT', 'TAGSTART', got 'SQE'",
  ),
  (
    "agentflow-beta TB\n\n  flow f[\"F\"]\n    a --> b end", "error syntax agentflow agentflow\nParse error on line 4:\n    a --> b end\n------------^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'EOF', got 'end'",
  ),
  (
    "agentflow-beta TB\n  flow A[\"Flow A\"]\n    a1[\"Task A1\"]\n    a1 --> B\n  end\n  fe1@low B[\"Flow B\"]\n    b1[\"Task B1k B1\"]\n    b1 --> A\n  end",
    "error syntax agentflow agentflow\nParse error on line 6:\n  fe1@low B[\"Flow B\"]\n--^\nExpecting 'COMMENT', 'SEMI', 'NEWLINE', 'SPACE', 'EOF', 'flow', 'global', 'connector', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'STYLE', 'LINKSTYLE', 'CLASSDEF', 'CLASS', 'CLICK', 'NODE_STRING', got 'LINK_ID'",
  ),
  (
    "agentflow-beta TB\n  flow outer[\"Outer\"]\n    flow inn]er[\"Inner\"]\n --    a --> b\n    end\n    c --> d\n  end",
    "error syntax agentflow agentflow\nLexical error on line 3. Unrecognized text.\n    flow inn]er[\"Inner\"]\n------------^",
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
  ("agentflow-beta TB\n  a[\"Alphaha\"]\n  a --> a", "ok 7de8a784"),
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
    "agentflow-beta TB\n  connector github[\"GitHu & b\"]\n  connector slaic.\nagck[\"Slack\"]",
    "ok cb58c3e5",
  ),
]
