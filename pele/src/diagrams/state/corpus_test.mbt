// pele v1.10.0's state corpus (tests/support/corpus.ts: the strings of Mermaid's state specs and the samples of Mermaid's docs), with a hash of what pele's render gives each source.

///|
test "renders every corpus input as pele does, the same way each time" {
  let wrong = []
  let mut rendered = 0
  for case in corpus_cases {
    let (source, expected) = case
    let outcome = render_outcome(source)
    if outcome.has_prefix("ok ") {
      rendered += 1
    }
    if fnv1a(outcome) != expected {
      wrong.push(source.escape())
    } else if render_outcome(source) != outcome {
      wrong.push("not repeatable: \{source.escape()}")
    }
  }
  inspect(wrong.join("\n"), content="")
  inspect(rendered > 80, content="true")
}

///|
/// Each source with the hash of what pele gives it.
let corpus_cases : Array[(String, String)] = [
  ("stateDiagram-v2\n        state valid { X }", "526f36e0"),
  ("stateDiagram-v2\n        state invalid syntax { Y }", "674fbcc4"),
  (
    "stateDiagram-v2\n        state invalid syntax with more than 2 words { Z }",
    "d9da0237",
  ),
  (
    "stateDiagram-v2\n        state \"Small State 1\" as namedState1", "3ad6f06b",
  ),
  ("stateDiagram-v2\n        namedState1 : Small State 1", "3ad6f06b"),
  ("stateDiagram-v2\n        namedState1:Small State 1", "3ad6f06b"),
  (
    "stateDiagram-v2\n      assemble\n      assemblies\n      state assemble\n      state assemblies\n      ",
    "51801aba",
  ),
  ("stateDiagram-v2\n      state \"as\" as as\n      ", "96668866"),
  (
    "stateDiagram-v2\n        state \"Small State 1\" as namedState1\n        %% Notice that this is named \"Big State 1\" with an \"as\"\n        state \"Big State 1\" as bigState1 {\n            bigState1InternalState\n        }\n        namedState1 --> bigState1: should point to \\nBig State 1 container\n\n        state \"Small State 2\" as namedState2\n        %% Notice that bigState2 does not have a name; no \"as\"\n        state bigState2 {\n            bigState2InternalState\n        }\n        namedState2 --> bigState2: should point to \\nbigState2 container",
    "6aeb8e6b",
  ),
  (
    "stateDiagram-v2\n        state \"Big State 1\" as bigState1 {\n            state \"inner state 1\" as inner1\n            inner2: inner state 2\n            inner1 --> inner2\n        }",
    "ca184360",
  ),
  (
    "stateDiagram-v2\n        locked --> pending : recoverable error (ex: timeout)",
    "68585643",
  ),
  ("stateDiagram-v2\n        A --> B : info: key: value", "c6279be8"),
  ("stateDiagram-v2\n        myState : status: active", "6b67cd45"),
  ("\nstateDiagram-v2\n[*] --> ${prop}\n${prop} --> [*]", "37605066"),
  (
    "stateDiagram-v2\n      State1\n      note right of State1\n        this sentence contains send note inside the note text\n      end note\n      State1 --> State2",
    "55273387",
  ),
  (
    "stateDiagram-v2\n      State1\n      note right of State1\n        this sentence contains end note as part of the note text\n      end note\n      State1 --> State2",
    "21fd7d31",
  ),
  ("stateDiagram-v2\n classDef exampleClass background:#bbb;", "46d88381"),
  (
    "stateDiagram-v2\n classDef exampleClass background:#bbb, font-weight:bold, font-style:italic;",
    "46d88381",
  ),
  (
    "stateDiagram-v2\n classDef exampleStyleClass background:#bbb,border:1.5px solid red;",
    "46d88381",
  ),
  (
    "stateDiagram-v2\n classDef exampleStyleClass background:  #bbb,border:1.5px solid red;",
    "46d88381",
  ),
  (
    "stateDiagram-v2\n classDef __proto__ background:#bbb,border:1.5px solid red;\n classDef constructor background:#bbb,border:1.5px solid red;",
    "46d88381",
  ),
  ("stateDiagram-v2\n", "46d88381"),
  ("stateDiagram-v2\n\n", "46d88381"),
  (
    "stateDiagram-v2\n        id1\n        style id1 background:#bbb", "a26d353e",
  ),
  (
    "stateDiagram-v2\n        id1\n        id2\n        style id1,id2 background:#bbb",
    "adb9e94d",
  ),
  (
    "stateDiagram-v2\n        id1\n        id2\n        style id1,id2 background:#bbb, font-weight:bold, font-style:italic;",
    "62afa46e",
  ),
  (
    "stateDiagram-v2\n      [*] --> Boot\n      state Boot {\n        [*] --> Firmware\n        state Kernel {\n          [*] --> Scheduler\n          state Drivers {\n            [*] --> Probe\n          }\n        }\n      }\n      Boot --> Running\n      state Running {\n        [*] --> Serving\n      }\n    ",
    "a26ade4b",
  ),
  (
    "stateDiagram-v2\n      state Outer {\n        [*] --> Inner\n        Inner --> Done\n      }\n    ",
    "7abc9310",
  ),
  (
    "stateDiagram-v2\n      state Active {\n        [*] --> NumLockOff\n        --\n        [*] --> CapsLockOff\n        --\n        [*] --> ScrollLockOff\n      }\n    ",
    "4cba898b",
  ),
  (
    "stateDiagram-v2\n      state First {\n        [*] --> A\n      }\n      state Second {\n        [*] --> B\n      }\n    ",
    "2e48f1bc",
  ),
  (
    "stateDiagram-v2\n      state First {\n        [*] --> A\n        --\n        [*] --> C\n      }\n      state Second {\n        [*] --> B\n      }\n    ",
    "740cd928",
  ),
  (
    "stateDiagram-v2\n      classDef pinned fill:#111827,stroke:#F59E0B\n      state Active {\n        [*] --> A\n        --\n        [*] --> B\n      }\n      class Active pinned\n    ",
    "76128403",
  ),
  (
    "stateDiagram-v2\n      state First {\n        [*] --> A\n        --\n        [*] --> B\n      }\n      state Second {\n        [*] --> C\n        --\n        [*] --> D\n      }\n    ",
    "93e95899",
  ),
  (
    "stateDiagram-v2\n      classDef pinned fill:#111827,stroke:#F59E0B\n      state First {\n        [*] --> A\n      }\n      state Second {\n        [*] --> B\n      }\n      state Third {\n        [*] --> C\n      }\n      class Second pinned\n    ",
    "693a8cca",
  ),
  (
    "stateDiagram-v2\n      state First {\n        [*] --> A\n      }\n      state Second {\n        [*] --> B\n      }\n      style Second fill:#111827\n    ",
    "5e349ee8",
  ),
  (
    "stateDiagram-v2\n      [*] --> Loop\n      state Loop {\n        [*] --> Spin\n      }\n      Loop --> Loop\n      Loop --> Exit\n      state Exit {\n        [*] --> Bye\n      }\n    ",
    "d3e6ba6d",
  ),
  (
    "\n      stateDiagram-v2\n      [*] --> State1\n      State1 --> [*]\n      ",
    "57d07e9a",
  ),
  (
    "stateDiagram-v2\n\n      State1 : this is another string\n      [*] --> State1\n      State1 --> [*]\n      ",
    "8135a42a",
  ),
  (
    "stateDiagram-v2\n\n      accDescr: a simple description of the diagram\n      State1 : this is another string\n      [*] --> State1\n      State1 --> [*]\n      ",
    "9776f40c",
  ),
  (
    "stateDiagram-v2\n\n      accTitle: a simple title of the diagram\n      State1 : this is another string\n      [*] --> State1\n      State1 --> [*]\n      ",
    "3f8a9f3c",
  ),
  (
    "stateDiagram-v2\n\n      [*] --> State1\n      State1 --> [*]\n      State1 : this is a string\n      State1 : this is another string\n\n      State1 --> State2\n      State2 --> [*]\n      ",
    "1a3b663f",
  ),
  (
    "stateDiagram-v2\n\n      hide empty description\n      [*] --> State1\n      State1 --> [*]\n      State1 : this is a string\n      State1 : this is another string\n\n      State1 --> State2\n      State2 --> [*]\n      ",
    "1a3b663f",
  ),
  ("stateDiagram-v2\n      assemble\n      state assemble\n      ", "23dc62c1"),
  (
    "stateDiagram-v2\n      assemblies\n      state assemblies\n      ", "125af9f6",
  ),
  (
    "\n          stateDiagram-v2\n          [*] --> State1\n          State1 --> State2 : Transition 1\n          State1 --> State3 : Transition 2\n          State1 --> State4 : Transition 3\n          State1 --> [*]\n        ",
    "a4f1152b",
  ),
  (
    "stateDiagram-v2\n\n      scale 350 width\n      [*] --> State1\n      State1 --> [*]\n      State1 : this is a string with - in it\n      State1 : this is another string\n\n      State1 --> State2\n      State2 --> [*]\n      ",
    "7d5e07b1",
  ),
  (
    "stateDiagram-v2\n\n      scale 350 width\n      [*] --> State1 : This is the description with - in it\n      State1 --> [*]\n      ",
    "13e62566",
  ),
  (
    "stateDiagram-v2\n\n      scale 350 width\n      [*] --> State1 : This is the description +-!\n      State1 --> [*]\n      ",
    "3b2ef976",
  ),
  (
    "stateDiagram-v2\n\n      state Configuring {\n        [*] --> NewValueSelection\n        NewValueSelection --> NewValuePreview : EvNewValue\n        NewValuePreview --> NewValueSelection : EvNewValueRejected\n        NewValuePreview --> NewValueSelection : EvNewValueSaved1\n      }\n      ",
    "458549a3",
  ),
  (
    "stateDiagram-v2\n\n      state Configuring {\n        [*] --> NewValueSelection\n        NewValueSelection --> NewValuePreview : EvNewValue\n        NewValuePreview --> NewValueSelection : EvNewValueRejected\n        NewValuePreview --> NewValueSelection : EvNewValueSaved\n\n        state NewValuePreview {\n          State1 --> State2\n        }\n      }\n      ",
    "0c1e5f8a",
  ),
  (
    "stateDiagram-v2\n\n      scale 350 width\n      [*] --> NotShooting\n\n      state NotShooting {\n        [*] --> Idle\n        Idle --> Configuring : EvConfig\n        Configuring --> Idle : EvConfig\n      }\n\n      state Configuring {\n        [*] --> NewValueSelection\n        NewValueSelection --> NewValuePreview : EvNewValue\n        NewValuePreview --> NewValueSelection : EvNewValueRejected\n        NewValuePreview --> NewValueSelection : EvNewValueSaved\n\n        state NewValuePreview {\n          State1 --> State2\n        }\n      }\n      ",
    "67731b63",
  ),
  (
    "stateDiagram-v2\n\n      state \"Long state description\" as state1\n      ",
    "ff9cbc20",
  ),
  (
    "stateDiagram-v2\n      state \"Not Shooting State\" as NotShooting {\n        state \"Idle mode\" as Idle\n        state \"Configuring mode\" as Configuring\n        [*] --> Idle\n        Idle --> Configuring : EvConfig\n        Configuring --> Idle : EvConfig\n      }\n      ",
    "1fde81ba",
  ),
  (
    "stateDiagram-v2\n\n      scale 600 width\n\n      [*] --> State1\n      State1 --> State2 : Succeeded\n      State1 --> [*] : Aborted\n      State2 --> State3 : Succeeded\n      State2 --> [*] : Aborted\n      state State3 {\n        state \"Accumulate Enough Data\nLong State Name\" as long1\n        long1 : Just a test\n        [*] --> long1\n        long1 --> long1 : New Data\n        long1 --> ProcessData : Enough Data\n      }\n      State3 --> State3 : Failed\n      State3 --> [*] : Succeeded / Save Result\n      State3 --> [*] : Aborted\n      ",
    "1e6b943b",
  ),
  (
    "stateDiagram-v2\n\n      state fork_state <<fork>>\n      [*] --> fork_state\n      fork_state --> State2\n      fork_state --> State3\n\n      state join_state <<join>>\n      State2 --> join_state\n      State3 --> join_state\n      join_state --> State4\n      State4 --> [*]\n      ",
    "3ea67d6f",
  ),
  (
    "stateDiagram-v2\n\n      [*] --> Active\n\n      state Active {\n        [*] --> NumLockOff\n        NumLockOff --> NumLockOn : EvNumLockPressed\n        NumLockOn --> NumLockOff : EvNumLockPressed\n        --\n        [*] --> CapsLockOff\n        CapsLockOff --> CapsLockOn : EvCapsLockPressed\n        CapsLockOn --> CapsLockOff : EvCapsLockPressed\n        --\n        [*] --> ScrollLockOff\n        ScrollLockOff --> ScrollLockOn : EvCapsLockPressed\n        ScrollLockOn --> ScrollLockOff : EvCapsLockPressed\n      }\n      ",
    "9bed13f9",
  ),
  (
    "stateDiagram-v2\n\n      [*] --> Active\n\n      state Active {\n        [*] --> NumLockOff\n        --\n        [*] --> CapsLockOff\n        --\n        [*] --> ScrollLockOff\n      }\n      ",
    "bb0ed910",
  ),
  (
    "stateDiagram-v2\n\n    //     [*] -up-> First\n    //     First -right-> Second\n    //     Second --> Third\n    //     Third -left-> Last\n    //   ",
    "48aa7009",
  ),
  (
    "stateDiagram-v2\n\n      [*] --> Active\n      Active --> Inactive\n\n      note left of Active : this is a short<br/>note\n\n      note right of Inactive\n      A note can also\n      be defined on\n      several lines\n      end note\n      ",
    "ba6d1da9",
  ),
  (
    "stateDiagram-v2\n      State1\n      note right of State1\n      Line1<br>Line2<br/>Line3<br />Line4<br\t/>Line5\n      end note\n      ",
    "4b8a1a6b",
  ),
  (
    "stateDiagram-v2\n      foo: bar\n      note \"This is a floating note\" as N1\n      ",
    "1d30ab55",
  ),
  (
    "stateDiagram-v2\n      state foo\n      note \"This is a floating note\" as N1\n      ",
    "46d88381",
  ),
  (
    "stateDiagram-v2\n      [*] --> NotShooting\n\n      state \"Not Shooting State\" as NotShooting {\n        state \"Idle mode\" as Idle\n        state \"Configuring mode\" as Configuring\n        [*] --> Idle\n        Idle --> Configuring : EvConfig\n        Configuring --> Idle : EvConfig\n      }\n\n      note right of NotShooting : This is a note on a composite state\n      ",
    "5244b3fd",
  ),
  (
    "\n          stateDiagram-v2\n            state Active {\n              Idle\n            }\n            Inactive --> Idle: ACT\n            Active --> Active: LOG\n        ",
    "d5f3b625",
  ),
  (
    "\n        stateDiagram\n          [*] --> Still\n          Still --> [*]\n        ",
    "e50b2cfd",
  ),
  (
    "\n        stateDiagram\n          direction LR\n          [*] --> Still\n          Still --> [*]\n        ",
    "485d1ce7",
  ),
  (
    "\n      stateDiagram\n        [*] --> State1\n        State1 --> [*]\n      ",
    "57d07e9a",
  ),
  (
    "stateDiagram\n\n          State1 : this is another string\n          [*] --> State1\n          State1 --> [*]\n      ",
    "8135a42a",
  ),
  (
    "stateDiagram\n\n          accDescr: a simple description of the diagram\n          State1 : this is another string\n          [*] --> State1\n          State1 --> [*]\n      ",
    "9776f40c",
  ),
  (
    "stateDiagram\n\n          accDescr {\n             a simple description of the diagram\n            using multiple lines\n          }\n          State1 : this is another string\n          [*] --> State1\n          State1 --> [*]\n      ",
    "6d858c93",
  ),
  (
    "stateDiagram\n\n          accTitle: a simple title of the diagram\n          State1 : this is another string\n          [*] --> State1\n          State1 --> [*]\n      ",
    "3f8a9f3c",
  ),
  (
    "stateDiagram\n\n        [*] --> State1\n        State1 --> [*]\n        State1 : this is a string\n        State1 : this is another string\n\n        State1 --> State2\n        State2 --> [*]\n      ",
    "1a3b663f",
  ),
  (
    "stateDiagram\n\n        hide empty description\n        [*] --> State1\n        State1 --> [*]\n        State1 : this is a string\n        State1 : this is another string\n\n        State1 --> State2\n        State2 --> [*]\n      ",
    "1a3b663f",
  ),
  ("stateDiagram\n      assemble\n      state assemble\n      ", "23dc62c1"),
  ("stateDiagram\n      assemblies\n      state assemblies\n      ", "125af9f6"),
  ("stateDiagram\n      state \"as\" as as\n      ", "96668866"),
  (
    "stateDiagram\n\n        scale 350 width\n        [*] --> State1\n        State1 --> [*]\n        State1 : this is a string with - in it\n        State1 : this is another string\n\n        State1 --> State2\n        State2 --> [*]\n      ",
    "7d5e07b1",
  ),
  (
    "stateDiagram\n\n        scale 350 width\n        [*] --> State1 : This is the description with - in it\n        State1 --> [*]\n      ",
    "13e62566",
  ),
  (
    "stateDiagram\n\n        scale 350 width\n        [*] --> State1 : This is the description +-!\n        State1 --> [*]\n      ",
    "3b2ef976",
  ),
  (
    "stateDiagram\n\n        state Configuring {\n          [*] --> NewValueSelection\n          NewValueSelection --> NewValuePreview : EvNewValue\n          NewValuePreview --> NewValueSelection : EvNewValueRejected\n          NewValuePreview --> NewValueSelection : EvNewValueSaved1\n        }\n      ",
    "458549a3",
  ),
  (
    "stateDiagram\n\n        state Configuring {\n          [*] --> NewValueSelection\n          NewValueSelection --> NewValuePreview : EvNewValue\n          NewValuePreview --> NewValueSelection : EvNewValueRejected\n          NewValuePreview --> NewValueSelection : EvNewValueSaved\n\n          state NewValuePreview {\n          State1 --> State2\n          }\n        }\n      ",
    "0c1e5f8a",
  ),
  (
    "stateDiagram\n\n        scale 350 width\n        [*] --> NotShooting\n\n        state NotShooting {\n          [*] --> Idle\n          Idle --> Configuring : EvConfig\n          Configuring --> Idle : EvConfig\n        }\n\n        state Configuring {\n          [*] --> NewValueSelection\n          NewValueSelection --> NewValuePreview : EvNewValue\n          NewValuePreview --> NewValueSelection : EvNewValueRejected\n          NewValuePreview --> NewValueSelection : EvNewValueSaved\n\n          state NewValuePreview {\n          State1 --> State2\n          }\n        }\n      ",
    "67731b63",
  ),
  (
    "stateDiagram\n\n        state \"Long state description\" as state1\n        ",
    "ff9cbc20",
  ),
  (
    "stateDiagram\n      state \"Not Shooting State\" as NotShooting {\n        state \"Idle mode\" as Idle\n        state \"Configuring mode\" as Configuring\n        [*] --> Idle\n        Idle --> Configuring : EvConfig\n        Configuring --> Idle : EvConfig\n      }\n        ",
    "1fde81ba",
  ),
  (
    "stateDiagram\n\n        scale 600 width\n\n        [*] --> State1\n        State1 --> State2 : Succeeded\n        State1 --> [*] : Aborted\n        State2 --> State3 : Succeeded\n        State2 --> [*] : Aborted\n        state State3 {\n          state \"Accumulate Enough Data\nLong State Name\" as long1\n          long1 : Just a test\n          [*] --> long1\n          long1 --> long1 : New Data\n          long1 --> ProcessData : Enough Data\n        }\n        State3 --> State3 : Failed\n        State3 --> [*] : Succeeded / Save Result\n        State3 --> [*] : Aborted\n      ",
    "1e6b943b",
  ),
  (
    "stateDiagram\n\n        state fork_state <<fork>>\n        [*] --> fork_state\n        fork_state --> State2\n        fork_state --> State3\n\n        state join_state <<join>>\n        State2 --> join_state\n        State3 --> join_state\n        join_state --> State4\n        State4 --> [*]\n      ",
    "3ea67d6f",
  ),
  (
    "stateDiagram\n\n        [*] --> Active\n\n        state Active {\n          [*] --> NumLockOff\n          NumLockOff --> NumLockOn : EvNumLockPressed\n          NumLockOn --> NumLockOff : EvNumLockPressed\n          --\n          [*] --> CapsLockOff\n          CapsLockOff --> CapsLockOn : EvCapsLockPressed\n          CapsLockOn --> CapsLockOff : EvCapsLockPressed\n          --\n          [*] --> ScrollLockOff\n          ScrollLockOff --> ScrollLockOn : EvCapsLockPressed\n          ScrollLockOn --> ScrollLockOff : EvCapsLockPressed\n        }\n      ",
    "9bed13f9",
  ),
  (
    "stateDiagram\n\n        [*] --> Active\n\n        state Active {\n          [*] --> NumLockOff\n          --\n          [*] --> CapsLockOff\n          --\n          [*] --> ScrollLockOff\n        }\n      ",
    "bb0ed910",
  ),
  (
    "stateDiagram\n\n    //     [*] -up-> First\n    //     First -right-> Second\n    //     Second --> Third\n    //     Third -left-> Last\n    //   ",
    "48aa7009",
  ),
  (
    "stateDiagram\n\n        [*] --> Active\n        Active --> Inactive\n\n        note left of Active : this is a short<br/>note\n\n        note right of Inactive\n          A note can also\n          be defined on\n          several lines\n        end note\n      ",
    "ba6d1da9",
  ),
  (
    "stateDiagram\n        State1\n        note right of State1\n          Line1<br>Line2<br/>Line3<br />Line4<br\t/>Line5\n        end note\n      ",
    "4b8a1a6b",
  ),
  (
    "stateDiagram\n        foo: bar\n        note \"This is a floating note\" as N1\n      ",
    "1d30ab55",
  ),
  (
    "stateDiagram\n\n        state foo\n        note \"This is a floating note\" as N1\n      ",
    "46d88381",
  ),
  (
    "stateDiagram\n\n        [*] --> NotShooting\n\n        state \"Not Shooting State\" as NotShooting {\n          state \"Idle mode\" as Idle\n          state \"Configuring mode\" as Configuring\n          [*] --> Idle\n          Idle --> Configuring : EvConfig\n          Configuring --> Idle : EvConfig\n        }\n\n        note right of NotShooting : This is a note on a composite state\n      ",
    "5244b3fd",
  ),
  (
    "stateDiagram\n\n      [*] --> \"Order Submitted\"\n      if \"Payment Accepted\" then\n        -->[yes] \"Pack products\"\n        --> \"Send parcel\"\n        -right-> (*)\n      else\n        ->[no] \"Send error message\"\n        -->[Cancel Order] [*]\n      endif\n        }\n\n        note right of NotShooting : This is a note on a composite state\n      ",
    "c200773e",
  ),
  (
    "stateDiagram-v2\n    [*] --> Active\n    Active --> Idle\n    note right of Active\n      A note\n    end note\n  ",
    "fa6bbdcc",
  ),
  (
    "\n  stateDiagram-v2\n  state Composite {\n    A --> B\n  }\n  note right of Composite : hello\n  ",
    "2ba514d2",
  ),
  (
    "---\ntitle: Simple sample\n---\nstateDiagram-v2\n    [*] --> Still\n    Still --> [*]\n\n    Still --> Moving\n    Moving --> Still\n    Moving --> Crash\n    Crash --> [*]\n",
    "c1fe1e4e",
  ),
  (
    "stateDiagram\n    [*] --> Still\n    Still --> [*]\n\n    Still --> Moving\n    Moving --> Still\n    Moving --> Crash\n    Crash --> [*]\n",
    "1090d425",
  ),
  (
    "stateDiagram-v2\n  [*] --> Draft\n  Draft --> Submitted : submit\n  state Review {\n    [*] --> Screening\n    Screening --> Decision\n  }\n  Submitted --> Review\n  Review --> Published : approved\n  Review --> Draft : rejected\n  Published --> [*]\n",
    "3d13dbbb",
  ),
  (
    "---\nconfig:\n  theme: default\n  look: classic\n  layout: dagre\n---\nstateDiagram-v2\n  [*] --> Draft\n  Draft --> Submitted : submit\n  state Review {\n    [*] --> Screening\n    Screening --> Decision\n  }\n  Submitted --> Review\n  Review --> Published : approved\n  Review --> Draft : rejected\n  Published --> [*]\n",
    "3d13dbbb",
  ),
  ("stateDiagram-v2\n    stateId\n", "0113e56c"),
  (
    "stateDiagram-v2\n    state \"This is a state description\" as s2\n", "40a9a551",
  ),
  ("stateDiagram-v2\n    s2 : This is a state description\n", "40a9a551"),
  ("stateDiagram-v2\n    s1 --> s2\n", "f983c5fd"),
  ("stateDiagram-v2\n    s1 --> s2: A transition\n", "f1b41324"),
  ("stateDiagram-v2\n    [*] --> s1\n    s1 --> [*]\n", "a6e3ca9d"),
  (
    "stateDiagram-v2\n    [*] --> First\n    state First {\n        [*] --> second\n        second --> [*]\n    }\n\n    [*] --> NamedComposite\n    NamedComposite: Another Composite\n    state NamedComposite {\n        [*] --> namedSimple\n        namedSimple --> [*]\n        namedSimple: Another simple\n    }\n",
    "eeac0ae0",
  ),
  (
    "stateDiagram-v2\n    [*] --> First\n\n    state First {\n        [*] --> Second\n\n        state Second {\n            [*] --> second\n            second --> Third\n\n            state Third {\n                [*] --> third\n                third --> [*]\n            }\n        }\n    }\n",
    "952612cb",
  ),
  (
    "stateDiagram-v2\n    [*] --> First\n    First --> Second\n    First --> Third\n\n    state First {\n        [*] --> fir\n        fir --> [*]\n    }\n    state Second {\n        [*] --> sec\n        sec --> [*]\n    }\n    state Third {\n        [*] --> thi\n        thi --> [*]\n    }\n",
    "f5b3555a",
  ),
  (
    "stateDiagram-v2\n    state if_state <<choice>>\n    [*] --> IsPositive\n    IsPositive --> if_state\n    if_state --> False: if n < 0\n    if_state --> True : if n >= 0\n",
    "a3550755",
  ),
  (
    "   stateDiagram-v2\n    state fork_state <<fork>>\n      [*] --> fork_state\n      fork_state --> State2\n      fork_state --> State3\n\n      state join_state <<join>>\n      State2 --> join_state\n      State3 --> join_state\n      join_state --> State4\n      State4 --> [*]\n",
    "3ea67d6f",
  ),
  (
    "    stateDiagram-v2\n        State1: The state with a note\n        note right of State1\n            Important information! You can write\n            notes.\n        end note\n        State1 --> State2\n        note left of State2 : This is the note to the left.\n",
    "22abb447",
  ),
  (
    "stateDiagram-v2\n    [*] --> Active\n\n    state Active {\n        [*] --> NumLockOff\n        NumLockOff --> NumLockOn : EvNumLockPressed\n        NumLockOn --> NumLockOff : EvNumLockPressed\n        --\n        [*] --> CapsLockOff\n        CapsLockOff --> CapsLockOn : EvCapsLockPressed\n        CapsLockOn --> CapsLockOff : EvCapsLockPressed\n        --\n        [*] --> ScrollLockOff\n        ScrollLockOff --> ScrollLockOn : EvScrollLockPressed\n        ScrollLockOn --> ScrollLockOff : EvScrollLockPressed\n    }\n",
    "44c4da31",
  ),
  (
    "stateDiagram\n    direction LR\n    [*] --> A\n    A --> B\n    B --> C\n    state B {\n      direction LR\n      a --> b\n    }\n    B --> D\n",
    "ad9da2bc",
  ),
  (
    "stateDiagram-v2\n    [*] --> Still\n    Still --> [*]\n%% this is a comment\n    Still --> Moving\n    Moving --> Still %% another comment\n    Moving --> Crash\n    Crash --> [*]\n",
    "1090d425",
  ),
  (
    "   stateDiagram\n   direction TB\n\n   accTitle: This is the accessible title\n   accDescr: This is an accessible description\n\n   classDef notMoving fill:white\n   classDef movement font-style:italic\n   classDef badBadEvent fill:#f00,color:white,font-weight:bold,stroke-width:2px,stroke:yellow\n\n   [*]--> Still\n   Still --> [*]\n   Still --> Moving\n   Moving --> Still\n   Moving --> Crash\n   Crash --> [*]\n\n   class Still notMoving\n   class Moving, Crash movement\n   class Crash badBadEvent\n   class end badBadEvent\n",
    "4c9f181f",
  ),
  (
    "stateDiagram\n   direction TB\n\n   accTitle: This is the accessible title\n   accDescr: This is an accessible description\n\n   classDef notMoving fill:white\n   classDef movement font-style:italic;\n   classDef badBadEvent fill:#f00,color:white,font-weight:bold,stroke-width:2px,stroke:yellow\n\n   [*] --> Still:::notMoving\n   Still --> [*]\n   Still --> Moving:::movement\n   Moving --> Still\n   Moving --> Crash:::movement\n   Crash:::badBadEvent --> [*]\n",
    "4c9f181f",
  ),
  (
    "stateDiagram\n    classDef yourState font-style:italic,font-weight:bold,fill:white\n\n    yswsii: Your state with spaces in it\n    [*] --> yswsii:::yourState\n    [*] --> SomeOtherState\n    SomeOtherState --> YetAnotherState\n    yswsii --> YetAnotherState\n    YetAnotherState --> [*]\n",
    "744c601f",
  ),
]
