// The expected models and errors were taken from pele's parser and SeqDb.

///|
fn parsed(source : String) -> String {
  let db = @sequence.SeqDb::new()
  @sequence.parse_sequence(source, db) catch {
    @errors.PeleError(failure) => return "error: \{failure.message}"
  }
  dump(db)
}

///|
test "parses messages and notes" {
  inspect(
    parsed(
      "sequenceDiagram\nAlice->>Bob: Hello Bob, how are you?\nNote right of Bob: Bob thinks\nBob-->>Alice: I am good thanks!\nBob-xAlice: x\nAlice--)Bob: y\nBob->Alice: z\nAlice-->Bob: w",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=0 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Bob" kind=2 message="Bob thinks" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=1 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="Bob" to="Alice" kind=3 message="x" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from="Alice" to="Bob" kind=25 message="y" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from="Bob" to="Alice" kind=5 message="z" wrap=false activate=false placement=- central=0 numbering=-
      #|message 6 from="Alice" to="Bob" kind=6 message="w" wrap=false activate=false placement=- central=0 numbering=-
      #|note "Bob" placement=1 message="Bob thinks" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "parses every arrow" {
  inspect(
    parsed(
      "sequenceDiagram\nA-xB: a\nA--xB: b\nA-)B: c\nA--)B: d\nA<<->>B: e\nA<<-->>B: f\nA-|\\B: g\nA-|/B: h\nA-\\\\B: i\nA-//B: j\nA--|\\B: k\nA--|/B: l\nA--\\\\B: m\nA--//B: n\nA/|-B: o\nA\\|-B: p\nA//-B: q\nA\\\\-B: r\nA/|--B: s\nA\\|--B: t\nA//--B: u\nA\\\\--B: v",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="A" to="B" kind=3 message="a" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="A" to="B" kind=4 message="b" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="A" to="B" kind=24 message="c" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="A" to="B" kind=25 message="d" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from="A" to="B" kind=33 message="e" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from="A" to="B" kind=34 message="f" wrap=false activate=false placement=- central=0 numbering=-
      #|message 6 from="A" to="B" kind=41 message="g" wrap=false activate=false placement=- central=0 numbering=-
      #|message 7 from="A" to="B" kind=42 message="h" wrap=false activate=false placement=- central=0 numbering=-
      #|message 8 from="A" to="B" kind=43 message="i" wrap=false activate=false placement=- central=0 numbering=-
      #|message 9 from="A" to="B" kind=44 message="j" wrap=false activate=false placement=- central=0 numbering=-
      #|message 10 from="A" to="B" kind=51 message="k" wrap=false activate=false placement=- central=0 numbering=-
      #|message 11 from="A" to="B" kind=52 message="l" wrap=false activate=false placement=- central=0 numbering=-
      #|message 12 from="A" to="B" kind=53 message="m" wrap=false activate=false placement=- central=0 numbering=-
      #|message 13 from="A" to="B" kind=54 message="n" wrap=false activate=false placement=- central=0 numbering=-
      #|message 14 from="A" to="B" kind=45 message="o" wrap=false activate=false placement=- central=0 numbering=-
      #|message 15 from="A" to="B" kind=46 message="p" wrap=false activate=false placement=- central=0 numbering=-
      #|message 16 from="A" to="B" kind=47 message="q" wrap=false activate=false placement=- central=0 numbering=-
      #|message 17 from="A" to="B" kind=48 message="r" wrap=false activate=false placement=- central=0 numbering=-
      #|message 18 from="A" to="B" kind=55 message="s" wrap=false activate=false placement=- central=0 numbering=-
      #|message 19 from="A" to="B" kind=56 message="t" wrap=false activate=false placement=- central=0 numbering=-
      #|message 20 from="A" to="B" kind=57 message="u" wrap=false activate=false placement=- central=0 numbering=-
      #|message 21 from="A" to="B" kind=58 message="v" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "parses participants with aliases and config objects" {
  inspect(
    parsed(
      "sequenceDiagram\nparticipant A as Alice\nactor B as wrap: Bob\nparticipant C@{ \"type\": \"database\" }\nparticipant D@{ \"alias\": \"Inner\" } as Outer\nparticipant E @{ type: queue, alias: \"Store\" }\nparticipant F-G\nparticipant H #c\nA->>B: hi",
    ),
    content=(
      #|actor "A" name="A" description="Alice" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="Bob" wrap=true kind="actor" box=none prev="A" next="C" links={} properties={} details=-
      #|actor "C" name="C" description="C" wrap=false kind="database" box=none prev="B" next="D" links={} properties={} details=-
      #|actor "D" name="D" description="Outer" wrap=false kind="participant" box=none prev="C" next="E" links={} properties={} details=-
      #|actor "E" name="E" description="Store" wrap=false kind="queue" box=none prev="D" next="F-G" links={} properties={} details=-
      #|actor "F-G" name="F-G" description="F-G" wrap=false kind="participant" box=none prev="E" next="H #c" links={} properties={} details=-
      #|actor "H #c" name="H #c" description="H #c" wrap=false kind="participant" box=none prev="F-G" next=- links={} properties={} details=-
      #|message 0 from="A" to="B" kind=0 message="hi" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "reads keywords without regard to case" {
  inspect(
    parsed(
      "sequenceDiagram\n  PARTICIPANT Alice AS A\n  Alice->>BOB: hi\n  NOTE OVER Alice: n\n  LOOP x\n  Alice->>Alice: y\n  END",
    ),
    content=(
      #|actor "Alice" name="Alice" description="A" wrap=false kind="participant" box=none prev=- next="BOB" links={} properties={} details=-
      #|actor "BOB" name="BOB" description="BOB" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="BOB" kind=0 message="hi" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Alice" to="Alice" kind=2 message="n" wrap=false activate=false placement=2 central=0 numbering=-
      #|message 2 from=- to=- kind=10 message="x" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="Alice" to="Alice" kind=0 message="y" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from=- to=- kind=11 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|note "Alice","Alice" placement=2 message="n" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "parses activations" {
  inspect(
    parsed(
      "sequenceDiagram\nA->>+B: one\nA->>+B: two\nB-->>-A: three\nB-->>-A: four\nactivate A\ndeactivate A",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="A" to="B" kind=0 message="one" wrap=false activate=true placement=- central=0 numbering=-
      #|message 1 from="B" to=- kind=17 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="A" to="B" kind=0 message="two" wrap=false activate=true placement=- central=0 numbering=-
      #|message 3 from="B" to=- kind=17 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from="B" to="A" kind=1 message="three" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from="B" to=- kind=18 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 6 from="B" to="A" kind=1 message="four" wrap=false activate=false placement=- central=0 numbering=-
      #|message 7 from="B" to=- kind=18 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 8 from="A" to=- kind=17 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 9 from="A" to=- kind=18 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "parses central connections" {
  inspect(
    parsed(
      "sequenceDiagram\nA->>()B: to\nA()->>B: from\nA()->>()B: both\nA()--x()B: dotted",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="A" to="B" kind=0 message="to" wrap=false activate=true placement=- central=59 numbering=-
      #|message 1 from="B" to=- kind=59 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="A" to="B" kind=0 message="from" wrap=false activate=false placement=- central=60 numbering=-
      #|message 3 from="A" to=- kind=60 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from="A" to="B" kind=0 message="both" wrap=false activate=true placement=- central=61 numbering=-
      #|message 5 from="B" to=- kind=59 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 6 from="A" to=- kind=60 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 7 from="A" to="B" kind=4 message="dotted" wrap=false activate=true placement=- central=61 numbering=-
      #|message 8 from="B" to=- kind=59 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 9 from="A" to=- kind=60 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "parses blocks with their sections in order" {
  inspect(
    parsed(
      "sequenceDiagram\nloop Every minute\nA->>B: a\nend\nalt ok\nA->>B: b\nelse bad\nA->>B: c\nelse\nA->>B: d\nend\nopt maybe\nA->>B: e\nend\npar one\nA->>B: f\nand two\nA->>B: g\nend\npar_over three\nA->>B: h\nend\ncritical must\nA->>B: i\noption fail\nA->>B: j\nend\nbreak stop\nA->>B: k\nend\nrect rgb(1, 2, 3)\nrect\nA->>B: l\nend\nend",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from=- to=- kind=10 message="Every minute" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="A" to="B" kind=0 message="a" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from=- to=- kind=11 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from=- to=- kind=12 message="ok" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from="A" to="B" kind=0 message="b" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from=- to=- kind=13 message="bad" wrap=false activate=false placement=- central=0 numbering=-
      #|message 6 from="A" to="B" kind=0 message="c" wrap=false activate=false placement=- central=0 numbering=-
      #|message 7 from=- to=- kind=13 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 8 from="A" to="B" kind=0 message="d" wrap=false activate=false placement=- central=0 numbering=-
      #|message 9 from=- to=- kind=14 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 10 from=- to=- kind=15 message="maybe" wrap=false activate=false placement=- central=0 numbering=-
      #|message 11 from="A" to="B" kind=0 message="e" wrap=false activate=false placement=- central=0 numbering=-
      #|message 12 from=- to=- kind=16 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 13 from=- to=- kind=19 message="one" wrap=false activate=false placement=- central=0 numbering=-
      #|message 14 from="A" to="B" kind=0 message="f" wrap=false activate=false placement=- central=0 numbering=-
      #|message 15 from=- to=- kind=20 message="two" wrap=false activate=false placement=- central=0 numbering=-
      #|message 16 from="A" to="B" kind=0 message="g" wrap=false activate=false placement=- central=0 numbering=-
      #|message 17 from=- to=- kind=21 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 18 from=- to=- kind=32 message="three" wrap=false activate=false placement=- central=0 numbering=-
      #|message 19 from="A" to="B" kind=0 message="h" wrap=false activate=false placement=- central=0 numbering=-
      #|message 20 from=- to=- kind=21 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 21 from=- to=- kind=27 message="must" wrap=false activate=false placement=- central=0 numbering=-
      #|message 22 from="A" to="B" kind=0 message="i" wrap=false activate=false placement=- central=0 numbering=-
      #|message 23 from=- to=- kind=28 message="fail" wrap=false activate=false placement=- central=0 numbering=-
      #|message 24 from="A" to="B" kind=0 message="j" wrap=false activate=false placement=- central=0 numbering=-
      #|message 25 from=- to=- kind=29 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 26 from=- to=- kind=30 message="stop" wrap=false activate=false placement=- central=0 numbering=-
      #|message 27 from="A" to="B" kind=0 message="k" wrap=false activate=false placement=- central=0 numbering=-
      #|message 28 from=- to=- kind=31 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 29 from=- to=- kind=22 message="rgb(1, 2, 3)" wrap=false activate=false placement=- central=0 numbering=-
      #|message 30 from=- to=- kind=22 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 31 from="A" to="B" kind=0 message="l" wrap=false activate=false placement=- central=0 numbering=-
      #|message 32 from=- to=- kind=23 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 33 from=- to=- kind=23 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "parses nested alternatives" {
  inspect(
    parsed(
      "sequenceDiagram\nalt a\nalt b\nA->>B: x\nelse c\nA->>B: y\nend\nelse d\npar e\nB->>A: z\nand f\nend\nend",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from=- to=- kind=12 message="a" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from=- to=- kind=12 message="b" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="A" to="B" kind=0 message="x" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from=- to=- kind=13 message="c" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from="A" to="B" kind=0 message="y" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from=- to=- kind=14 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 6 from=- to=- kind=13 message="d" wrap=false activate=false placement=- central=0 numbering=-
      #|message 7 from=- to=- kind=19 message="e" wrap=false activate=false placement=- central=0 numbering=-
      #|message 8 from="B" to="A" kind=0 message="z" wrap=false activate=false placement=- central=0 numbering=-
      #|message 9 from=- to=- kind=20 message="f" wrap=false activate=false placement=- central=0 numbering=-
      #|message 10 from=- to=- kind=21 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 11 from=- to=- kind=14 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "parses boxes" {
  inspect(
    parsed(
      "sequenceDiagram\nbox Aqua Group\nparticipant A\nactor B\n\nend\nbox rgb(1, 2, 3)\nparticipant C\nend\nbox wrap: Plain\ndestroy C\nend\nA->>C: x",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box="Group" prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="actor" box="Group" prev="A" next="C" links={} properties={} details=-
      #|actor "C" name="C" description="C" wrap=false kind="participant" box=- prev="B" next=- links={} properties={} details=-
      #|box "Group" fill="Aqua" wrap=false actors="A","B"
      #|box - fill="rgb(1, 2, 3)" wrap=false actors="C"
      #|box "Plain" fill="transparent" wrap=true actors=
      #|message 0 from="A" to="C" kind=0 message="x" wrap=false activate=false placement=- central=0 numbering=-
      #|destroyed "C"=0
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "parses creations and destructions" {
  inspect(
    parsed(
      "sequenceDiagram\nA->>B: hi\ncreate participant C\nA->>C: make\ndestroy C\nC-xA: bye\ncreate actor D as Dee\nA->>D: x",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="A" next="C" links={} properties={} details=-
      #|actor "C" name="C" description="C" wrap=false kind="participant" box=none prev="B" next="D" links={} properties={} details=-
      #|actor "D" name="D" description="Dee" wrap=false kind="actor" box=none prev="C" next=- links={} properties={} details=-
      #|message 0 from="A" to="B" kind=0 message="hi" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="A" to="C" kind=0 message="make" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="C" to="A" kind=3 message="bye" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="A" to="D" kind=0 message="x" wrap=false activate=false placement=- central=0 numbering=-
      #|created "C"=1
      #|created "D"=3
      #|destroyed "C"=2
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "parses autonumber statements" {
  inspect(
    parsed(
      "sequenceDiagram\nautonumber\nA->>B: x\nautonumber 10 5\nB->>A: y\nautonumber off\nautonumber 1.5\nA->>B: z\nautonumber 10.01 .01\nA->>B: w",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from=- to=- kind=26 message="" wrap=false activate=false placement=- central=0 numbering=-,-,true
      #|message 1 from="A" to="B" kind=0 message="x" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from=- to=- kind=26 message="" wrap=false activate=false placement=- central=0 numbering=10,5,true
      #|message 3 from="B" to="A" kind=0 message="y" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from=- to=- kind=26 message="" wrap=false activate=false placement=- central=0 numbering=-,-,false
      #|message 5 from=- to=- kind=26 message="" wrap=false activate=false placement=- central=0 numbering=1.5,1,true
      #|message 6 from="A" to="B" kind=0 message="z" wrap=false activate=false placement=- central=0 numbering=-
      #|message 7 from=- to=- kind=26 message="" wrap=false activate=false placement=- central=0 numbering=10.01,0.01,true
      #|message 8 from="A" to="B" kind=0 message="w" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "parses notes beside and over participants" {
  inspect(
    parsed(
      "sequenceDiagram\nNote left of A: L\nNote right of B: wrap: R\nNote over A: O\nNote over A,B: AB\nnote over B , C: BC",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="A" next="C" links={} properties={} details=-
      #|actor "C" name="C" description="C" wrap=false kind="participant" box=none prev="B" next=- links={} properties={} details=-
      #|message 0 from="A" to="A" kind=2 message="L" wrap=false activate=false placement=0 central=0 numbering=-
      #|message 1 from="B" to="B" kind=2 message="R" wrap=true activate=false placement=1 central=0 numbering=-
      #|message 2 from="A" to="A" kind=2 message="O" wrap=false activate=false placement=2 central=0 numbering=-
      #|message 3 from="A" to="B" kind=2 message="AB" wrap=false activate=false placement=2 central=0 numbering=-
      #|message 4 from="B" to="C" kind=2 message="BC" wrap=false activate=false placement=2 central=0 numbering=-
      #|note "A" placement=0 message="L" wrap=false
      #|note "B" placement=1 message="R" wrap=true
      #|note "A","A" placement=2 message="O" wrap=false
      #|note "A","B" placement=2 message="AB" wrap=false
      #|note "B","C" placement=2 message="BC" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "parses participant menus" {
  inspect(
    parsed(
      "sequenceDiagram\nparticipant A\nlinks A: {\"Repo\": \"https://example.com/repo\"}\nlink A: Tests @ https://example.com/?a=1&b=2@x\nproperties A: {\"class\": \"external svc\"}\ndetails A: some-element",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next=- links={"Repo":"https://example.com/repo","Tests":"https://example.com/?a=1&b=2@x"} properties={"class":"external svc"} details="some-element"
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "parses titles and accessible text" {
  inspect(
    parsed(
      "sequenceDiagram\ntitle My title\naccTitle: T\naccDescr: D\nA->>B: x",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="A" to="B" kind=0 message="x" wrap=false activate=false placement=- central=0 numbering=-
      #|title="My title" accTitle="T" accDescr="D"
    ),
  )
}

///|
test "parses a legacy title and a multiline description" {
  inspect(
    parsed(
      "sequenceDiagram\ntitle: Legacy\naccDescr {\n  Two\n  lines\n}\nA->>B: x",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="A" to="B" kind=0 message="x" wrap=false activate=false placement=- central=0 numbering=-
      #|title="Legacy" accTitle=- accDescr="Two\nlines"
    ),
  )
}

///|
test "skips comments, semicolons, and blank lines" {
  inspect(
    parsed(
      "sequenceDiagram\n%% comment\nA->>B: x; B->>A: y\n\n\n# hash\nA->>B: z #c\n  \n",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="A" to="B" kind=0 message="x" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="B" to="A" kind=0 message="y" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="A" to="B" kind=0 message="z" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "parses a message with a trailing colon but no content" {
  inspect(
    parsed("sequenceDiagram\nAlice->Bob:\nBob->Alice:  "),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Alice" kind=5 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "parses names with spaces, dashes, and equals signs" {
  inspect(
    parsed(
      "sequenceDiagram\nparticipant Alice Smith\nparticipant a-b-c\nparticipant a=b\nAlice Smith->>a-b-c: x\na=b-->>Alice Smith: y",
    ),
    content=(
      #|actor "Alice Smith" name="Alice Smith" description="Alice Smith" wrap=false kind="participant" box=none prev=- next="a-b-c" links={} properties={} details=-
      #|actor "a-b-c" name="a-b-c" description="a-b-c" wrap=false kind="participant" box=none prev="Alice Smith" next="a=b" links={} properties={} details=-
      #|actor "a=b" name="a=b" description="a=b" wrap=false kind="participant" box=none prev="a-b-c" next=- links={} properties={} details=-
      #|message 0 from="Alice Smith" to="a-b-c" kind=0 message="x" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="a=b" to="Alice Smith" kind=1 message="y" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "rejects a message without text" {
  inspect(
    parsed("sequenceDiagram\n  Alice->>Bob\n"),
    content=(
      #|error: Parse error on line 2:
      #|  Alice->>Bob
      #|-------------^
      #|Expecting 'TXT', got 'NEWLINE'
    ),
  )
}

///|
test "rejects a participant without a name" {
  inspect(
    parsed("sequenceDiagram\n  participant\n"),
    content=(
      #|error: Lexical error on line 2. Unrecognized text.
      #|  participant
      #|-------------^
    ),
  )
}

///|
test "rejects an unclosed block" {
  inspect(
    parsed("sequenceDiagram\n  loop x\n  A->>B: y"),
    content=(
      #|error: Parse error on line 3:
      #|  A->>B: y
      #|----------^
      #|Expecting 'end', got '$end'
    ),
  )
}

///|
test "rejects an end without a block" {
  inspect(
    parsed("sequenceDiagram\nend"),
    content=(
      #|error: Parse error on line 2:
      #|end
      #|^
      #|Expecting 'NEWLINE', 'EOF', got 'end'
    ),
  )
}

///|
test "rejects else outside alt" {
  inspect(
    parsed("sequenceDiagram\nopt x\nelse y\nend"),
    content=(
      #|error: Parse error on line 3:
      #|else y
      #|^
      #|Expecting 'end', got 'else'
    ),
  )
}

///|
test "rejects text before the keyword" {
  inspect(
    parsed("A->>B: x"),
    content=(
      #|error: Parse error on line 1:
      #|A->>B: x
      #|^
      #|Expecting 'SD', got 'ACTOR'
    ),
  )
}

///|
test "rejects messages in a box" {
  inspect(
    parsed("sequenceDiagram\nbox x\nA->>B: y\nend"),
    content=(
      #|error: Parse error on line 3:
      #|A->>B: y
      #|^
      #|Expecting 'end', 'NEWLINE', 'participant', 'participant_actor', 'destroy', got 'ACTOR'
    ),
  )
}

///|
test "rejects create without a participant" {
  inspect(
    parsed("sequenceDiagram\ncreate A->>B: x"),
    content=(
      #|error: Parse error on line 2:
      #|create A->>B: x
      #|-------^
      #|Expecting 'participant', 'participant_actor', 'destroy', got 'ACTOR'
    ),
  )
}

///|
test "rejects a note without placement" {
  inspect(
    parsed("sequenceDiagram\nNote A: x"),
    content=(
      #|error: Parse error on line 2:
      #|Note A: x
      #|-----^
      #|Expecting 'over', 'left_of', 'right_of', got 'ACTOR'
    ),
  )
}

///|
test "rejects thousandths in autonumber" {
  inspect(
    parsed("sequenceDiagram\nautonumber 10.001\nA->>B: x"),
    content=(
      #|error: Parse error on line 2:
      #|autonumber 10.001
      #|-----------^
      #|Expecting 'NEWLINE', 'NUM', 'off', got 'ACTOR'
    ),
  )
}

///|
test "rejects an activation after a central connection" {
  inspect(
    parsed("sequenceDiagram\nA()-->>+B: x"),
    content=(
      #|error: Parse error on line 2:
      #|A()-->>+B: x
      #|-------^
      #|Expecting 'ACTOR', got '+'
    ),
  )
}

///|
test "rejects an unclosed config object" {
  inspect(
    parsed(
      "sequenceDiagram\nparticipant E@{ \"type\": \"entity\"\nE ->> E: process\n",
    ),
    content=(
      #|error: Parse error on line 3:
      #|E ->> E: process
      #|----------------^
      #|Expecting 'CONFIG_END', got '$end'
    ),
  )
}

///|
test "rejects deactivating an idle participant after parsing" {
  inspect(
    parsed("sequenceDiagram\nA->>B: x\ndeactivate B"),
    content=(
      #|error: Trying to inactivate an inactive participant (B)
    ),
  )
}

///|
test "reports a syntax error before a model error" {
  inspect(
    parsed("sequenceDiagram\nA->>B: x\ndeactivate B\nA->>"),
    content=(
      #|error: Parse error on line 4:
      #|A->>
      #|----^
      #|Expecting 'ACTOR', got 'NEWLINE'
    ),
  )
}

///|
test "rejects invalid YAML in a config object" {
  inspect(
    parsed("sequenceDiagram\nparticipant C@{ \"type\" \"control\" }\nC->>C: x"),
    content=(
      #|error: Config of participant "C" is not valid YAML. YAML: missed comma between flow collection entries
    ),
  )
}

///|
test "rejects an invalid name" {
  inspect(
    parsed(
      "sequenceDiagram\nparticipant X_AutoPublishable asAAAAAAAAAAAAA:AAAAAAAAAAAAA",
    ),
    content=(
      #|error: Parse error on line 2:
      #|participant X_AutoPublishable asAAAAAAAAAAAAA:AAAAAAAAAAAAA
      #|------------^
      #|Expecting 'ACTOR', got 'INVALID'
    ),
  )
}

///|
test "rejects a name with markup" {
  inspect(
    parsed("sequenceDiagram\nparticipant SAS MyService <br> service"),
    content=(
      #|error: Parse error on line 2:
      #|participant SAS MyService <br> service
      #|------------^
      #|Expecting 'ACTOR', got 'INVALID'
    ),
  )
}

///|
test "rejects a signal without an arrow" {
  inspect(
    parsed("sequenceDiagram\nA B: x"),
    content=(
      #|error: Parse error on line 2:
      #|A B: x
      #|---^
      #|Expecting 'SOLID_OPEN_ARROW', 'DOTTED_OPEN_ARROW', 'SOLID_ARROW', 'DOTTED_ARROW', 'SOLID_CROSS', 'DOTTED_CROSS', 'SOLID_POINT', 'DOTTED_POINT', got 'TXT'
    ),
  )
}

///|
test "skips invalid characters between statements" {
  inspect(
    parsed("sequenceDiagram\n>\nA->>B: x\n> <"),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="A" to="B" kind=0 message="x" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "accepts the link keyword as a name" {
  inspect(
    parsed("sequenceDiagram\nlink link: a @ b\nlink ->>B: x"),
    content=(
      #|actor "link" name="link" description="link" wrap=false kind="participant" box=none prev=- next="B" links={"a":"b"} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="link" next=- links={} properties={} details=-
      #|message 0 from="link" to="B" kind=0 message="x" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "the character before a comment is kept" {
  inspect(
    parsed("sequenceDiagram\n  A->>B:%% comment"),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="A" to="B" kind=0 message="%% comment" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
  assert_true(
    parsed("sequenceDiagram\n  autonumber 5%% comment").has_prefix("error: "),
  )
}

///|
test "a bare title is no title" {
  inspect(
    [
      parsed("sequenceDiagram\ntitle\nA->>B: Hi\nB->>A: Bye"),
      parsed("sequenceDiagram\ntitle: \nA->>B: Hi\nB->>A: Bye"),
      parsed("sequenceDiagram\n  title My title\n  A->>B: x"),
    ].join("\n---\n"),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="A" to="B" kind=0 message="Hi" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="B" to="A" kind=0 message="Bye" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
      #|---
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="A" to="B" kind=0 message="Hi" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="B" to="A" kind=0 message="Bye" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
      #|---
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="A" to="B" kind=0 message="x" wrap=false activate=false placement=- central=0 numbering=-
      #|title="My title" accTitle=- accDescr=-
    ),
  )
}
