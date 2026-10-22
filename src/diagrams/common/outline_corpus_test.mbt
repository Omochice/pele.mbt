// The corpora, fragments and expected hashes for outline_test.mbt, taken from pele v1.8.0: its loadCorpus, its oracle tests' FRAGMENTS, and its tokenize and parseOutline run on each source.

///|
/// The mindmap sources in the specs and documentation pele v1.8.0 ports, in the order its loadCorpus reads them.
let mindmap_corpus : Array[String] = [
  "when parsing a mindmap ", "mindmap\n    root", "MMP-2 should handle a hierarchical mindmap definition",
  "mindmap\n    root\n      child1\n      child2\n ", "mindmap\n    (root)", "MMP-4 should handle a deeper hierarchical mindmap definition",
  "mindmap\n    root\n      child1\n        leaf1\n      child2", "mindmap\n    root\n    fakeRoot",
  "mindmap\n          root\n        fakeRoot\n    realRootWrongPlace", "mindmap\n    root[The root]\n      ",
  "mindmap\n    root\n      theId(child1)", "mindmap\nroot\n      theId(child1)",
  "mindmap\n root((the root))\n ", "mindmap\n root)the root(\n", "mindmap\n root))the root((\n",
  "mindmap\n root{{the root}}\n", "mindmap\n    root[The root]\n    ::icon(bomb)\n    ",
  "mindmap\n    root[The root]\n    :::m-4 p-8\n    ", "mindmap\n    root[The root]\n    :::m-4 p-8\n    ::icon(bomb)\n    ",
  "mindmap\n    root[The root]\n    ::icon(bomb)\n    :::m-4 p-8\n    ", "mindmap\n    root[\"String containing []\"]\n",
  "mindmap\n    root[\"String containing []\"]\n      child1[\"String containing ()\"]\n",
  "mindmap\n  root(Root)\n    Child(Child)\n    :::hot\n      a(a)\n      b[New Stuff]",
  "MMP-20 should be possible to have meaningless empty rows in a mindmap abc124",
  "mindmap\n  root(Root)\n    Child(Child)\n      a(a)\n\n      b[New Stuff]", "MMP-21 should be possible to have comments in a mindmap",
  "mindmap\n  root(Root)\n    Child(Child)\n      a(a)\n\n      %% This is a comment\n      b[New Stuff]",
  "mindmap\n  root(Root)\n    Child(Child)\n      a(a) %% This is a comment\n      b[New Stuff]",
  "mindmap\nroot\n A\n \n\n B", "MMP-24 Handle rows above the mindmap declarations",
  "\n \nmindmap\nroot\n A\n \n\n B", "MMP-25 Handle rows above the mindmap declarations, no space",
  "\n\n\nmindmap\nroot\n A\n \n\n B", "mindmap\n  root((mindmap))\n    Origins\n      Long history\n      ::icon(fa fa-book)\n      Popularisation\n        British popular psychology author Tony Buzan\n    Research\n      On effectiveness<br/>and features\n      On Automatic creation\n        Uses\n            Creative techniques\n            Strategic planning\n            Argument mapping\n    Tools\n      Pen and paper\n      Mermaid\n\n",
  "mindmap\nRoot\n    A\n      B\n      C\n", "mindmap\n    id[I am a square]\n",
  "mindmap\n    id(I am a rounded square)\n", "mindmap\n    id((I am a circle))\n",
  "mindmap\n    id))I am a bang((\n", "mindmap\n    id)I am a cloud(\n", "mindmap\n    id{{I am a hexagon}}\n",
  "mindmap\n    I am the default shape\n", "mindmap\n    Root\n        A\n        ::icon(fa fa-book)\n        B(B)\n        ::icon(mdi mdi-skull-outline)\n",
  "mindmap\n    Root\n        A[A]\n        :::urgent large\n        B(B)\n        C\n",
  "mindmap\nRoot\n    A\n        B\n      C\n", "mindmap\n    id1[\"`**Root** with\na second line\nUnicode works too: 🤓`\"]\n      id2[\"`The dog in **the** hog... a *very long text* that wraps to a new line`\"]\n      id3[Regular labels still works]\n",
]

///|
/// The fragments pele's mindmap oracle test inserts into the corpus.
let mindmap_fragments : Array[String] = [
  " ", "  ", "    ", "\t", "\n", "\n\n", " \n", "\n ", "\r\n", "\r", "\u{2028}",
  "\u{a0}", "mindmap", "MindMap", "mindmap\n", "mindmapx", "%%", " %% c", "%%{",
  ":::", ":::a b", "::icon(", "::ICON(fa fa-x)", "::", ":", "(", ")", "((", "))",
  "[", "]", "{{", "}}", "{", "}", "(-", "-)", "-", "\"", "`", "\"`", "`\"", "\"\"",
  "\"a\"", "[\"a\"]", "[\"`a`\"]", "(a)", "((a))", "))a((", ")a(", "{{a}}", "[a]",
  "(a]", "[a)", "id", "root", "A", "é", "🤓", "@", "@{", "^", "<br/>", "**b**",
  "#", ";", ",", ".",
]

///|
/// How many of the mindmap corpus and its 5000 mutations are at most 4000 code units long, and the hash of pele's dumps of each hundred of them.
let mindmap_expected : (Int32, Array[String]) = (
  5046,
  [
    "4165e5cf", "d113d44e", "672b5d44", "22f2f540", "63f8f611", "c6eaf2b3", "77f4de9e",
    "134e453c", "dc10e400", "cb22d544", "9d6b83c0", "5649e324", "70619cc8", "b94183b1",
    "e1f34b9a", "304db0ae", "bac0626e", "98c8a751", "99ed7379", "104c3f89", "22fa1fbf",
    "0e5016b1", "a293f43e", "41bd17c7", "f728b212", "265e874f", "89ecb02b", "a64c2ff1",
    "d59055d9", "33629a83", "12eaa6cb", "249156b5", "39010b7f", "5a370866", "f62425d2",
    "0e072781", "633eebda", "36b7d7ab", "2cf22de3", "4a8a9389", "76145e6b", "438d3ec7",
    "93901d98", "48b5aa06", "35cb8381", "bf5cf20a", "bc1a51f1", "42364b97", "2ab5b346",
    "7f3dbdb7", "5ee44f40",
  ],
)

///|
/// The kanban sources in the specs and documentation pele v1.8.0 ports, in the order its loadCorpus reads them.
let kanban_corpus : Array[String] = [
  "when parsing a kanban ", "kanban\n    root", "KNBN-2 should handle a hierarchical kanban definition",
  "kanban\n    root\n      child1\n      child2\n ", "kanban\n    (root)", "KNBN-4 should not distinguish between deeper hierarchical levels in the kanban definition",
  "kanban\n    root\n      child1\n        leaf1\n      child2", "kanban\n    section1\n    section2",
  "kanban\n          root\n        fakeRoot\n    realRootWrongPlace", "kanban\n    root[The root]\n      ",
  "kanban\n    root\n      theId(child1)", "kanban\nroot\n      theId(child1)", "kanban\n    root[The root]\n    ::icon(bomb)\n    ",
  "kanban\n    root[The root]\n    :::m-4 p-8\n    ", "kanban\n    root[The root]\n    :::m-4 p-8\n    ::icon(bomb)\n    ",
  "kanban\n    root[The root]\n    ::icon(bomb)\n    :::m-4 p-8\n    ", "kanban\n    root[\"String containing []\"]\n",
  "kanban\n    root[\"String containing []\"]\n      child1[\"String containing ()\"]\n",
  "kanban\n  root(Root)\n    Child(Child)\n    :::hot\n      a(a)\n      b[New Stuff]",
  "KNBN-20 should be possible to have meaningless empty rows in a kanban abc124",
  "kanban\n  root(Root)\n    Child(Child)\n      a(a)\n\n      b[New Stuff]", "KNBN-21 should be possible to have comments in a kanban",
  "kanban\n  root(Root)\n    Child(Child)\n      a(a)\n\n      %% This is a comment\n      b[New Stuff]",
  "kanban\n  root(Root)\n    Child(Child)\n      a(a) %% This is a comment\n      b[New Stuff]",
  "kanban\nroot\n A\n \n\n B", "KNBN-24 Handle rows above the kanban declarations",
  "\n \nkanban\nroot\n A\n \n\n B", "KNBN-25 Handle rows above the kanban declarations, no space",
  "\n\n\nkanban\nroot\n A\n \n\n B", "kanban\n    root\n  ", "kanban\n        root@{ priority: high }\n    ",
  "kanban\n        root@{ assigned: knsv }\n    ", "kanban\n        root@{ icon: star }\n    ",
  "kanban\n        root@{\n          icon: star\n          assigned: knsv\n        }\n    ",
  "kanban\n        root@{ icon: star, assigned: knsv }\n    ", "kanban\n        root@{ icon: star, label: 'fix things' }\n    ",
  "kanban\n        root@{ ticket: MC-1234 }\n    ", "kanban\n  column1[Column Title]\n    task1[Task Description]\n",
  "kanban\ntodo[Todo]\n  id3[Update Database Function]@{ ticket: MC-2037, assigned: 'knsv', priority: 'High' }\n",
  "---\nconfig:\n  kanban:\n    ticketBaseUrl: 'https://mermaidchart.atlassian.net/browse/#TICKET#'\n---\nkanban\n  Todo\n    [Create Documentation]\n    docs[Create Blog about the new diagram]\n  [In progress]\n    id6[Create renderer so that it works in all cases. We also add some extra text here for testing purposes. And some more just for the extra flare.]\n  id9[Ready for deploy]\n    id8[Design grammar]@{ assigned: 'knsv' }\n  id10[Ready for test]\n    id4[Create parsing tests]@{ ticket: MC-2038, assigned: 'K.Sveidqvist', priority: 'High' }\n    id66[last item]@{ priority: 'Very Low', assigned: 'knsv' }\n  id11[Done]\n    id5[define getData]\n    id2[Title of diagram is more than 100 chars when user duplicates diagram with 100 char]@{ ticket: MC-2036, priority: 'Very High'}\n    id3[Update DB function]@{ ticket: MC-2037, assigned: knsv, priority: 'High' }\n\n  id12[Can't reproduce]\n    id3[Weird flickering in Firefox]\n",
]

///|
/// The fragments pele's kanban oracle test inserts into the corpus.
let kanban_fragments : Array[String] = [
  " ", "  ", "    ", "\t", "\n", "\n\n", " \n", "\n ", "\r\n", "\r", "\u{2028}",
  "\u{a0}", "kanban", "Kanban", "kanban\n", "kanbanx", "%%", " %% c", "%%{", ":::",
  ":::a b", "::icon(", "::ICON(fa fa-x)", "::", ":", "(", ")", "((", "))", "[", "]",
  "{{", "}}", "{", "}", "(-", "-)", "-", "\"", "`", "\"`", "`\"", "\"\"", "\"a\"",
  "[\"a\"]", "[\"`a`\"]", "(a)", "((a))", "))a((", ")a(", "{{a}}", "[a]", "(a]",
  "[a)", "id", "todo", "A", "é", "🤓", "@", "@{", "@{ ", " }", "@{}", "^", "@{ priority: high }",
  "@{ label: \"a\n  b\" }", "ticket: MC-1, assigned: 'k'", "a: \"", "\n  icon: star\n",
  "#", ";", ",", ".",
]

///|
/// How many of the kanban corpus and its 5000 mutations are at most 4000 code units long, and the hash of pele's dumps of each hundred of them.
let kanban_expected : (Int32, Array[String]) = (
  5040,
  [
    "8e20eb14", "cf350217", "5adb275f", "1dcb0842", "25db4404", "84f0d8fa", "aa6623f9",
    "8a9f55d3", "670723b8", "22d9ec08", "12e54a9b", "e00f81c6", "40c256e2", "5965f102",
    "1f8861c8", "09bef887", "8c37a12b", "665f779b", "032a98bf", "ad4bce79", "17d46d97",
    "1b957f55", "e97d518e", "e8cdcddc", "a4ba0349", "374e34cc", "37bdc8d3", "bbec2d32",
    "008be863", "36adaf03", "db828237", "f8a79c92", "d6f4fcb2", "ce0c8034", "b4a4531f",
    "d6e5e6c4", "d3dae065", "0d32d2b3", "ab88e0b9", "0beca3dc", "6cee5bb3", "7d5d0872",
    "bcbb03cc", "fe976b3f", "4fd65279", "c7bba8ea", "c189320e", "873825a2", "2757b285",
    "c15c63be", "4a262a7f",
  ],
)
