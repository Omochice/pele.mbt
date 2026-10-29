// Ported from pele v1.8.0, tests/compat/sequence/sequenceDiagram.spec.js and keywordActors.spec.ts, which port Mermaid's specs.
// Each test parses a diagram of a spec case and compares the whole model with the one pele builds from it.
// The cases pele skips, and those that check the pixel positions of Mermaid's renderer, are left out, as tests/compat/sequence/SKIPPED.md lists them.

///|
/// The model of `source` as the spec adapter's `Diagram.fromText` builds it.
fn spec_parsed(source : String) -> String {
  let db = @sequence.SeqDb::new()
  @sequence.parse_sequence(@preprocess.encode_entities(source) + "\n", db) catch {
    @errors.PeleError(failure) => return "error: \{failure.message}"
  }
  dump(db)
}

///|
test "should not have duplicated messages" {
  inspect(
    spec_parsed(
      "\n        sequenceDiagram\n        Alice->Bob:Hello Bob, how are you?\n        Bob-->Alice: I am good thanks!",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse actor ()->>() actor syntax as CENTRAL_CONNECTION_DUAL" {
  inspect(
    spec_parsed(
      "\n        sequenceDiagram\n        participant Alice\n        participant Bob\n        Alice ()->>() Bob: Hello Bob, how are you?\n      ",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=0 message="Hello Bob, how are you?" wrap=false activate=true placement=- central=61 numbering=-
      #|message 1 from="Bob" to=- kind=59 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Alice" to=- kind=60 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse actor ()-->>() actor syntax as CENTRAL_CONNECTION_DUAL" {
  inspect(
    spec_parsed(
      "\n        sequenceDiagram\n        participant Alice\n        participant Bob\n        Alice ()-->>() Bob: Hello Bob, how are you?\n      ",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=1 message="Hello Bob, how are you?" wrap=false activate=true placement=- central=61 numbering=-
      #|message 1 from="Bob" to=- kind=59 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Alice" to=- kind=60 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse actor ->>() actor syntax as CENTRAL_CONNECTION" {
  inspect(
    spec_parsed(
      "\n        sequenceDiagram\n        participant Alice\n        participant Bob\n        Alice ->>() Bob: Hello Bob, how are you?\n      ",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=0 message="Hello Bob, how are you?" wrap=false activate=true placement=- central=59 numbering=-
      #|message 1 from="Bob" to=- kind=59 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse actor ()-->> actor syntax as CENTRAL_CONNECTION_REVERSE" {
  inspect(
    spec_parsed(
      "\n        sequenceDiagram\n        participant Alice\n        participant Bob\n        Alice ()-->> Bob: Hello Bob, how are you?\n      ",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=1 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=60 numbering=-
      #|message 1 from="Alice" to=- kind=60 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse actor ()->> actor syntax as CENTRAL_CONNECTION_REVERSE" {
  inspect(
    spec_parsed(
      "\n        sequenceDiagram\n        participant Alice\n        participant Bob\n        Alice ()->> Bob: Hello Bob, how are you?\n      ",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=0 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=60 numbering=-
      #|message 1 from="Alice" to=- kind=60 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse actor ()<<-->>() actor syntax as CENTRAL_CONNECTION_DUAL" {
  inspect(
    spec_parsed(
      "\n        sequenceDiagram\n        participant Alice\n        participant Bob\n        Alice ()<<-->>() Bob: Hello Bob, how are you?\n      ",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=34 message="Hello Bob, how are you?" wrap=false activate=true placement=- central=61 numbering=-
      #|message 1 from="Bob" to=- kind=59 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Alice" to=- kind=60 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse actor ()<<->>() actor syntax as CENTRAL_CONNECTION_DUAL" {
  inspect(
    spec_parsed(
      "\n        sequenceDiagram\n        participant Alice\n        participant Bob\n        Alice ()<<->>() Bob: Hello Bob, how are you?\n      ",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=33 message="Hello Bob, how are you?" wrap=false activate=true placement=- central=61 numbering=-
      #|message 1 from="Bob" to=- kind=59 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Alice" to=- kind=60 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle multiple central connection types in one diagram" {
  inspect(
    spec_parsed(
      "\n        sequenceDiagram\n        participant Alice\n        participant Bob\n        participant Charlie\n        Alice ()->>() Bob: Message 1\n        Bob ()-->> Charlie: Message 2\n        Charlie ()<<-->>() Alice: Message 3\n      ",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next="Charlie" links={} properties={} details=-
      #|actor "Charlie" name="Charlie" description="Charlie" wrap=false kind="participant" box=none prev="Bob" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=0 message="Message 1" wrap=false activate=true placement=- central=61 numbering=-
      #|message 1 from="Bob" to=- kind=59 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Alice" to=- kind=60 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="Bob" to="Charlie" kind=1 message="Message 2" wrap=false activate=false placement=- central=60 numbering=-
      #|message 4 from="Bob" to=- kind=60 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from="Charlie" to="Alice" kind=34 message="Message 3" wrap=false activate=true placement=- central=61 numbering=-
      #|message 6 from="Alice" to=- kind=59 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 7 from="Charlie" to=- kind=60 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle central connections with different arrow types" {
  inspect(
    spec_parsed(
      "\n        sequenceDiagram\n        participant Alice\n        participant Bob\n        Alice ()-x() Bob: Cross message\n        Alice ()--x() Bob: Dotted cross message\n      ",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=3 message="Cross message" wrap=false activate=true placement=- central=61 numbering=-
      #|message 1 from="Bob" to=- kind=59 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Alice" to=- kind=60 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="Alice" to="Bob" kind=4 message="Dotted cross message" wrap=false activate=true placement=- central=61 numbering=-
      #|message 4 from="Bob" to=- kind=59 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from="Alice" to=- kind=60 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should not break existing parsing without central connections" {
  inspect(
    spec_parsed(
      "\n        sequenceDiagram\n        participant Alice\n        participant Bob\n        Alice ->> Bob: Normal message\n        Bob -->> Alice: Normal dotted message\n        Alice -x Bob: Normal cross message\n      ",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=0 message="Normal message" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Alice" kind=1 message="Normal dotted message" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Alice" to="Bob" kind=3 message="Normal cross message" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle a sequenceDiagram definition" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nAlice->Bob:Hello Bob, how are you?\nNote right of Bob: Bob thinks\nBob-->Alice: I am good thanks!",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Bob" kind=2 message="Bob thinks" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|note "Bob" placement=1 message="Bob thinks" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should show sequence numbers when autonumber is enabled" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nautonumber\nAlice->Bob:Hello Bob, how are you?\nNote right of Bob: Bob thinks\nBob-->Alice: I am good thanks!",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from=- to=- kind=26 message="" wrap=false activate=false placement=- central=0 numbering=-,-,true
      #|message 1 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Bob" to="Bob" kind=2 message="Bob thinks" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 3 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|note "Bob" placement=1 message="Bob thinks" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should allow sequence numbers to have decimals up to the hundredths place" {
  inspect(
    spec_parsed(
      "\n        sequenceDiagram\n        autonumber 10.1 .01\n        Alice->Bob:Hello Bob, how are you?\n        Note right of Bob: Bob thinks\n        Bob-->Alice: I am good thanks!\n      ",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from=- to=- kind=26 message="" wrap=false activate=false placement=- central=0 numbering=10.1,0.01,true
      #|message 1 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Bob" to="Bob" kind=2 message="Bob thinks" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 3 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|note "Bob" placement=1 message="Bob thinks" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should not allow sequence numbers to have decimals to the thousandths place or greater" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      autonumber 10.001\n      Alice->Bob:Hello Bob, how are you?\n      Note right of Bob: Bob thinks\n      Bob-->Alice: I am good thanks!\n    ",
    ),
    content=(
      #|error: Parse error on line 3:
      #|      autonumber 10.001
      #|-----------------^
      #|Expecting 'NEWLINE', 'NUM', 'off', got 'ACTOR'
    ),
  )
}

///|
test "should handle a sequenceDiagram definition with a title:" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\ntitle: Diagram Title\nAlice->Bob:Hello Bob, how are you?\nNote right of Bob: Bob thinks\nBob-->Alice: I am good thanks!",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Bob" kind=2 message="Bob thinks" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|note "Bob" placement=1 message="Bob thinks" wrap=false
      #|title="Diagram Title" accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle a sequenceDiagram definition with a title without a :" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\ntitle Diagram Title\nAlice->Bob:Hello Bob, how are you?\nNote right of Bob: Bob thinks\nBob-->Alice: I am good thanks!",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Bob" kind=2 message="Bob thinks" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|note "Bob" placement=1 message="Bob thinks" wrap=false
      #|title="Diagram Title" accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle a sequenceDiagram definition with a accessibility title and description (accDescr)" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\ntitle: Diagram Title\naccTitle: This is the title\naccDescr: Accessibility Description\nAlice->Bob:Hello Bob, how are you?\n",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|title="Diagram Title" accTitle="This is the title" accDescr="Accessibility Description"
    ),
  )
}

///|
test "should handle a sequenceDiagram definition with a accessibility title and multiline description (accDescr)" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\naccTitle: This is the title\naccDescr {\nAccessibility\nDescription\n}\nAlice->Bob:Hello Bob, how are you?\n",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle="This is the title" accDescr="Accessibility\nDescription"
    ),
  )
}

///|
test "should space in actor names" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nAlice->Bob:Hello Bob, how are - you?\nBob-->Alice: I am good thanks!",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are - you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle dashes in actor names" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nAlice-in-Wonderland->Bob:Hello Bob, how are - you?\nBob-->Alice-in-Wonderland:I am good thanks!",
    ),
    content=(
      #|actor "Alice-in-Wonderland" name="Alice-in-Wonderland" description="Alice-in-Wonderland" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice-in-Wonderland" next=- links={} properties={} details=-
      #|message 0 from="Alice-in-Wonderland" to="Bob" kind=5 message="Hello Bob, how are - you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Alice-in-Wonderland" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle dashes in participant names" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nparticipant Alice-in-Wonderland\nparticipant Bob\nAlice-in-Wonderland->Bob:Hello Bob, how are - you?\nBob-->Alice-in-Wonderland:I am good thanks!",
    ),
    content=(
      #|actor "Alice-in-Wonderland" name="Alice-in-Wonderland" description="Alice-in-Wonderland" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice-in-Wonderland" next=- links={} properties={} details=-
      #|message 0 from="Alice-in-Wonderland" to="Bob" kind=5 message="Hello Bob, how are - you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Alice-in-Wonderland" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle equals in participant names" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nparticipant Alice=Wonderland\nparticipant Bob\nAlice=Wonderland->Bob:Hello Bob, how are - you?\nBob-->Alice=Wonderland:I am good thanks!",
    ),
    content=(
      #|actor "Alice=Wonderland" name="Alice=Wonderland" description="Alice=Wonderland" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice=Wonderland" next=- links={} properties={} details=-
      #|message 0 from="Alice=Wonderland" to="Bob" kind=5 message="Hello Bob, how are - you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Alice=Wonderland" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should alias participants" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nparticipant A as Alice\nparticipant B as Bob\nA->B:Hello Bob, how are you?\nB-->A: I am good thanks!",
    ),
    content=(
      #|actor "A" name="A" description="Alice" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="Bob" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="A" to="B" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="B" to="A" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should alias a mix of actors and participants apa12" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\n  actor Alice as Alice2\n  actor Bob\n  participant John as John2\n  participant Mandy\n  Alice->>Bob: Hi Bob\n  Bob->>Alice: Hi Alice\n  Alice->>John: Hi John\n  John->>Mandy: Hi Mandy\n  Mandy ->>Joan: Hi Joan",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice2" wrap=false kind="actor" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="actor" box=none prev="Alice" next="John" links={} properties={} details=-
      #|actor "John" name="John" description="John2" wrap=false kind="participant" box=none prev="Bob" next="Mandy" links={} properties={} details=-
      #|actor "Mandy" name="Mandy" description="Mandy" wrap=false kind="participant" box=none prev="John" next="Joan" links={} properties={} details=-
      #|actor "Joan" name="Joan" description="Joan" wrap=false kind="participant" box=none prev="Mandy" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=0 message="Hi Bob" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Alice" kind=0 message="Hi Alice" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Alice" to="John" kind=0 message="Hi John" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="John" to="Mandy" kind=0 message="Hi Mandy" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from="Mandy" to="Joan" kind=0 message="Hi Joan" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should alias actors apa13" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nactor A as Alice\nactor B as Bob\nA->B:Hello Bob, how are you?\nB-->A: I am good thanks!",
    ),
    content=(
      #|actor "A" name="A" description="Alice" wrap=false kind="actor" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="Bob" wrap=false kind="actor" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="A" to="B" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="B" to="A" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle in async messages" {
  inspect(
    spec_parsed("\nsequenceDiagram\nAlice-xBob:Hello Bob, how are you?"),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=3 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle in async dotted messages" {
  inspect(
    spec_parsed("\nsequenceDiagram\nAlice--xBob:Hello Bob, how are you?"),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=4 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle in sync messages" {
  inspect(
    spec_parsed("\nsequenceDiagram\nAlice-)Bob:Hello Bob, how are you?"),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=24 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle in sync dotted messages" {
  inspect(
    spec_parsed("\nsequenceDiagram\nAlice--)Bob:Hello Bob, how are you?"),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=25 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle in arrow messages" {
  inspect(
    spec_parsed("\nsequenceDiagram\nAlice->>Bob:Hello Bob, how are you?"),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=0 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle in arrow messages again" {
  inspect(
    spec_parsed("\nsequenceDiagram\nAlice<<->>Bob:Hello Bob, how are you?"),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=33 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle bidirectional dotted arrow messages" {
  inspect(
    spec_parsed(
      "\n    sequenceDiagram\n    Alice<<-->>Bob:Hello Bob, how are you?",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=34 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle actor activation" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nAlice-->>Bob:Hello Bob, how are you?\nactivate Bob\nBob-->>Alice:Hello Alice, I'm fine and  you?\ndeactivate Bob",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=1 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to=- kind=17 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=1 message="Hello Alice, I'm fine and  you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="Bob" to=- kind=18 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle actor one line notation activation" {
  inspect(
    spec_parsed(
      "\n    sequenceDiagram\n    Alice-->>+Bob:Hello Bob, how are you?\n    Bob-->>- Alice:Hello Alice, I'm fine and  you?",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=1 message="Hello Bob, how are you?" wrap=false activate=true placement=- central=0 numbering=-
      #|message 1 from="Bob" to=- kind=17 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=1 message="Hello Alice, I'm fine and  you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="Bob" to=- kind=18 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle stacked activations" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      Alice-->>+Bob:Hello Bob, how are you?\n      Bob-->>+Carol:Carol, let me introduce Alice?\n      Bob-->>- Alice:Hello Alice, please meet Carol?\n      Carol->>- Bob:Oh Bob, I'm so happy to be here!",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next="Carol" links={} properties={} details=-
      #|actor "Carol" name="Carol" description="Carol" wrap=false kind="participant" box=none prev="Bob" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=1 message="Hello Bob, how are you?" wrap=false activate=true placement=- central=0 numbering=-
      #|message 1 from="Bob" to=- kind=17 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Bob" to="Carol" kind=1 message="Carol, let me introduce Alice?" wrap=false activate=true placement=- central=0 numbering=-
      #|message 3 from="Carol" to=- kind=17 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from="Bob" to="Alice" kind=1 message="Hello Alice, please meet Carol?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from="Bob" to=- kind=18 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 6 from="Carol" to="Bob" kind=0 message="Oh Bob, I'm so happy to be here!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 7 from="Carol" to=- kind=18 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle fail parsing when activating an inactive participant" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      participant user as End User\n      participant Server as Server\n      participant System as System\n      participant System2 as System2\n\n      user->>+Server: Test\n      user->>+Server: Test2\n      user->>System: Test\n      Server->>-user: Test\n      Server->>-user: Test2\n\n      %% The following deactivation of Server will fail\n      Server->>-user: Test3",
    ),
    content=(
      #|error: Trying to inactivate an inactive participant (Server)
    ),
  )
}

///|
test "should handle comments in a sequenceDiagram" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      Alice->Bob: Hello Bob, how are you?\n      %% Comment\n      Note right of Bob: Bob thinks\n      Bob-->Alice: I am good thanks!",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Bob" kind=2 message="Bob thinks" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|note "Bob" placement=1 message="Bob thinks" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle new lines in a sequenceDiagram" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      Alice->Bob: Hello Bob, how are you?\n\n      %% Comment\n      Note right of Bob: Bob thinks\n      Bob-->Alice: I am good thanks!\n      ",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Bob" kind=2 message="Bob thinks" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|note "Bob" placement=1 message="Bob thinks" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle semicolons" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram;Alice->Bob: Hello Bob, how are you?;Note right of Bob: Bob thinks;Bob-->Alice: I am good thanks!;",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Bob" kind=2 message="Bob thinks" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|note "Bob" placement=1 message="Bob thinks" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle one leading space in lines in a sequenceDiagram" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\n Alice->Bob: Hello Bob, how are you?\n\n%% Comment\nNote right of Bob: Bob thinks\nBob-->Alice: I am good thanks!",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Bob" kind=2 message="Bob thinks" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|note "Bob" placement=1 message="Bob thinks" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle several leading spaces in lines in a sequenceDiagram" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\n   Alice->Bob: Hello Bob, how are you?\n\n%% Comment\nNote right of Bob: Bob thinks\nBob-->Alice: I am good thanks!",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Bob" kind=2 message="Bob thinks" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|note "Bob" placement=1 message="Bob thinks" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle several leading spaces in lines in a sequenceDiagram again" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nparticipant Alice\nparticipant Bob\nAlice->John: Hello John, how are you?\n    loop Healthcheck\nJohn->John: Fight against hypochondria\n end\nNote right of John: Rational thoughts<br/>prevail...\n    John-->Alice: Great!\n    John->Bob: How about you?\nBob-->John: Jolly good!",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next="John" links={} properties={} details=-
      #|actor "John" name="John" description="John" wrap=false kind="participant" box=none prev="Bob" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="John" kind=5 message="Hello John, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from=- to=- kind=10 message="Healthcheck" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="John" to="John" kind=5 message="Fight against hypochondria" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from=- to=- kind=11 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from="John" to="John" kind=2 message="Rational thoughts<br/>prevail..." wrap=false activate=false placement=1 central=0 numbering=-
      #|message 5 from="John" to="Alice" kind=6 message="Great!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 6 from="John" to="Bob" kind=5 message="How about you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 7 from="Bob" to="John" kind=6 message="Jolly good!" wrap=false activate=false placement=- central=0 numbering=-
      #|note "John" placement=1 message="Rational thoughts<br/>prevail..." wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle different line breaks" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nparticipant 1 as multiline<br>text\nparticipant 2 as multiline<br/>text\nparticipant 3 as multiline<br />text\nparticipant 4 as multiline<br \t/>text\n1->>2: multiline<br>text\nnote right of 2: multiline<br>text\n2->>3: multiline<br/>text\nnote right of 3: multiline<br/>text\n3->>4: multiline<br />text\nnote right of 4: multiline<br />text\n4->>1: multiline<br \t/>text\nnote right of 1: multiline<br \t/>text\n",
    ),
    content=(
      #|actor "1" name="1" description="multiline<br>text" wrap=false kind="participant" box=none prev=- next="2" links={} properties={} details=-
      #|actor "2" name="2" description="multiline<br/>text" wrap=false kind="participant" box=none prev="1" next="3" links={} properties={} details=-
      #|actor "3" name="3" description="multiline<br />text" wrap=false kind="participant" box=none prev="2" next="4" links={} properties={} details=-
      #|actor "4" name="4" description="multiline<br \t/>text" wrap=false kind="participant" box=none prev="3" next=- links={} properties={} details=-
      #|message 0 from="1" to="2" kind=0 message="multiline<br>text" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="2" to="2" kind=2 message="multiline<br>text" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 2 from="2" to="3" kind=0 message="multiline<br/>text" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="3" to="3" kind=2 message="multiline<br/>text" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 4 from="3" to="4" kind=0 message="multiline<br />text" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from="4" to="4" kind=2 message="multiline<br />text" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 6 from="4" to="1" kind=0 message="multiline<br \t/>text" wrap=false activate=false placement=- central=0 numbering=-
      #|message 7 from="1" to="1" kind=2 message="multiline<br \t/>text" wrap=false activate=false placement=1 central=0 numbering=-
      #|note "2" placement=1 message="multiline<br>text" wrap=false
      #|note "3" placement=1 message="multiline<br/>text" wrap=false
      #|note "4" placement=1 message="multiline<br />text" wrap=false
      #|note "1" placement=1 message="multiline<br \t/>text" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle notes and messages without wrap specified" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nparticipant 1\nparticipant 2\nparticipant 3\nparticipant 4\n1->>2: single-line text\nnote right of 2: single-line text\n2->>3:nowrap: single-line text\nnote right of 3:nowrap: single-line text\n3->>4: multiline<br/>text\nnote right of 4: multiline<br/>text\n4->>1:nowrap: multiline<br/>text\nnote right of 1:nowrap: multiline<br/>text\n",
    ),
    content=(
      #|actor "1" name="1" description="1" wrap=false kind="participant" box=none prev=- next="2" links={} properties={} details=-
      #|actor "2" name="2" description="2" wrap=false kind="participant" box=none prev="1" next="3" links={} properties={} details=-
      #|actor "3" name="3" description="3" wrap=false kind="participant" box=none prev="2" next="4" links={} properties={} details=-
      #|actor "4" name="4" description="4" wrap=false kind="participant" box=none prev="3" next=- links={} properties={} details=-
      #|message 0 from="1" to="2" kind=0 message="single-line text" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="2" to="2" kind=2 message="single-line text" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 2 from="2" to="3" kind=0 message="single-line text" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="3" to="3" kind=2 message="single-line text" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 4 from="3" to="4" kind=0 message="multiline<br/>text" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from="4" to="4" kind=2 message="multiline<br/>text" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 6 from="4" to="1" kind=0 message="multiline<br/>text" wrap=false activate=false placement=- central=0 numbering=-
      #|message 7 from="1" to="1" kind=2 message="multiline<br/>text" wrap=false activate=false placement=1 central=0 numbering=-
      #|note "2" placement=1 message="single-line text" wrap=false
      #|note "3" placement=1 message="single-line text" wrap=false
      #|note "4" placement=1 message="multiline<br/>text" wrap=false
      #|note "1" placement=1 message="multiline<br/>text" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle notes and messages with wrap specified" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nparticipant 1\nparticipant 2\nparticipant 3\nparticipant 4\n1->>2:wrap: single-line text\nnote right of 2:wrap: single-line text\n2->>3:wrap: multiline<br/>text\nnote right of 3:wrap: multiline<br/>text\n",
    ),
    content=(
      #|actor "1" name="1" description="1" wrap=false kind="participant" box=none prev=- next="2" links={} properties={} details=-
      #|actor "2" name="2" description="2" wrap=false kind="participant" box=none prev="1" next="3" links={} properties={} details=-
      #|actor "3" name="3" description="3" wrap=false kind="participant" box=none prev="2" next="4" links={} properties={} details=-
      #|actor "4" name="4" description="4" wrap=false kind="participant" box=none prev="3" next=- links={} properties={} details=-
      #|message 0 from="1" to="2" kind=0 message="single-line text" wrap=true activate=false placement=- central=0 numbering=-
      #|message 1 from="2" to="2" kind=2 message="single-line text" wrap=true activate=false placement=1 central=0 numbering=-
      #|message 2 from="2" to="3" kind=0 message="multiline<br/>text" wrap=true activate=false placement=- central=0 numbering=-
      #|message 3 from="3" to="3" kind=2 message="multiline<br/>text" wrap=true activate=false placement=1 central=0 numbering=-
      #|note "2" placement=1 message="single-line text" wrap=true
      #|note "3" placement=1 message="multiline<br/>text" wrap=true
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle notes and messages with nowrap or line breaks" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nparticipant 1\nparticipant 2\n1->>2: single-line text\nnote right of 2: single-line text\n",
    ),
    content=(
      #|actor "1" name="1" description="1" wrap=false kind="participant" box=none prev=- next="2" links={} properties={} details=-
      #|actor "2" name="2" description="2" wrap=false kind="participant" box=none prev="1" next=- links={} properties={} details=-
      #|message 0 from="1" to="2" kind=0 message="single-line text" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="2" to="2" kind=2 message="single-line text" wrap=false activate=false placement=1 central=0 numbering=-
      #|note "2" placement=1 message="single-line text" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle notes over a single actor" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nAlice->Bob: Hello Bob, how are you?\nNote over Bob: Bob thinks\n",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Bob" kind=2 message="Bob thinks" wrap=false activate=false placement=2 central=0 numbering=-
      #|note "Bob","Bob" placement=2 message="Bob thinks" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle notes over multiple actors" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nAlice->Bob: Hello Bob, how are you?\nNote over Alice,Bob: confusion\nNote over Bob,Alice: resolution\n",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Alice" to="Bob" kind=2 message="confusion" wrap=false activate=false placement=2 central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=2 message="resolution" wrap=false activate=false placement=2 central=0 numbering=-
      #|note "Alice","Bob" placement=2 message="confusion" wrap=false
      #|note "Bob","Alice" placement=2 message="resolution" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle loop statements" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nAlice->Bob: Hello Bob, how are you?\n\n%% Comment\nNote right of Bob: Bob thinks\nloop Multiple happy responses\n\nBob-->Alice: I am good thanks!\nend",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Bob" kind=2 message="Bob thinks" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 2 from=- to=- kind=10 message="Multiple happy responses" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from=- to=- kind=11 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|note "Bob" placement=1 message="Bob thinks" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should add a rect around sequence" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n        Alice->Bob: Hello Bob, how are you?\n        %% Comment\n        rect rgb(200, 255, 200)\n        Note right of Bob: Bob thinks\n        Bob-->Alice: I am good thanks\n        end\n    ",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from=- to=- kind=22 message="rgb(200, 255, 200)" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Bob" to="Bob" kind=2 message="Bob thinks" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 3 from="Bob" to="Alice" kind=6 message="I am good thanks" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from=- to=- kind=23 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|note "Bob" placement=1 message="Bob thinks" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should allow for nested rects" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n        Alice->Bob: Hello Bob, how are you?\n        %% Comment\n        rect rgb(200, 255, 200)\n        rect rgb(0, 0, 0)\n        Note right of Bob: Bob thinks\n        end\n        Bob-->Alice: I am good thanks\n        end\n    ",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from=- to=- kind=22 message="rgb(200, 255, 200)" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from=- to=- kind=22 message="rgb(0, 0, 0)" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="Bob" to="Bob" kind=2 message="Bob thinks" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 4 from=- to=- kind=23 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from="Bob" to="Alice" kind=6 message="I am good thanks" wrap=false activate=false placement=- central=0 numbering=-
      #|message 6 from=- to=- kind=23 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|note "Bob" placement=1 message="Bob thinks" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle opt statements" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nAlice->Bob: Hello Bob, how are you?\n\n%% Comment\nNote right of Bob: Bob thinks\nopt Perhaps a happy response\n\nBob-->Alice: I am good thanks!\nend",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Bob" kind=2 message="Bob thinks" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 2 from=- to=- kind=15 message="Perhaps a happy response" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from=- to=- kind=16 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|note "Bob" placement=1 message="Bob thinks" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle alt statements" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nAlice->Bob: Hello Bob, how are you?\n\n%% Comment\nNote right of Bob: Bob thinks\nalt isWell\n\nBob-->Alice: I am good thanks!\nelse isSick\nBob-->Alice: Feel sick...\nend",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Bob" kind=2 message="Bob thinks" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 2 from=- to=- kind=12 message="isWell" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from=- to=- kind=13 message="isSick" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from="Bob" to="Alice" kind=6 message="Feel sick..." wrap=false activate=false placement=- central=0 numbering=-
      #|message 6 from=- to=- kind=14 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|note "Bob" placement=1 message="Bob thinks" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle alt statements with multiple elses" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nAlice->Bob: Hello Bob, how are you?\n\n%% Comment\nNote right of Bob: Bob thinks\nalt isWell\n\nBob-->Alice: I am good thanks!\nelse isSick\nBob-->Alice: Feel sick...\nelse default\nBob-->Alice: :-)\nend",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Bob" kind=2 message="Bob thinks" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 2 from=- to=- kind=12 message="isWell" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from=- to=- kind=13 message="isSick" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from="Bob" to="Alice" kind=6 message="Feel sick..." wrap=false activate=false placement=- central=0 numbering=-
      #|message 6 from=- to=- kind=13 message="default" wrap=false activate=false placement=- central=0 numbering=-
      #|message 7 from="Bob" to="Alice" kind=6 message=":-)" wrap=false activate=false placement=- central=0 numbering=-
      #|message 8 from=- to=- kind=14 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|note "Bob" placement=1 message="Bob thinks" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle critical statements without options" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\n    critical Establish a connection to the DB\n        Service-->DB: connect\n    end",
    ),
    content=(
      #|actor "Service" name="Service" description="Service" wrap=false kind="participant" box=none prev=- next="DB" links={} properties={} details=-
      #|actor "DB" name="DB" description="DB" wrap=false kind="participant" box=none prev="Service" next=- links={} properties={} details=-
      #|message 0 from=- to=- kind=27 message="Establish a connection to the DB" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Service" to="DB" kind=6 message="connect" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from=- to=- kind=29 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle critical statements with options" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\n    critical Establish a connection to the DB\n        Service-->DB: connect\n    option Network timeout\n        Service-->Service: Log error\n    option Credentials rejected\n        Service-->Service: Log different error\n    end",
    ),
    content=(
      #|actor "Service" name="Service" description="Service" wrap=false kind="participant" box=none prev=- next="DB" links={} properties={} details=-
      #|actor "DB" name="DB" description="DB" wrap=false kind="participant" box=none prev="Service" next=- links={} properties={} details=-
      #|message 0 from=- to=- kind=27 message="Establish a connection to the DB" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Service" to="DB" kind=6 message="connect" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from=- to=- kind=28 message="Network timeout" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="Service" to="Service" kind=6 message="Log error" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from=- to=- kind=28 message="Credentials rejected" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from="Service" to="Service" kind=6 message="Log different error" wrap=false activate=false placement=- central=0 numbering=-
      #|message 6 from=- to=- kind=29 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle break statements" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\n    Consumer-->API: Book something\n    API-->BookingService: Start booking process\n    break when the booking process fails\n        API-->Consumer: show failure\n    end\n    API-->BillingService: Start billing process",
    ),
    content=(
      #|actor "Consumer" name="Consumer" description="Consumer" wrap=false kind="participant" box=none prev=- next="API" links={} properties={} details=-
      #|actor "API" name="API" description="API" wrap=false kind="participant" box=none prev="Consumer" next="BookingService" links={} properties={} details=-
      #|actor "BookingService" name="BookingService" description="BookingService" wrap=false kind="participant" box=none prev="API" next="BillingService" links={} properties={} details=-
      #|actor "BillingService" name="BillingService" description="BillingService" wrap=false kind="participant" box=none prev="BookingService" next=- links={} properties={} details=-
      #|message 0 from="Consumer" to="API" kind=6 message="Book something" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="API" to="BookingService" kind=6 message="Start booking process" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from=- to=- kind=30 message="when the booking process fails" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="API" to="Consumer" kind=6 message="show failure" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from=- to=- kind=31 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from="API" to="BillingService" kind=6 message="Start billing process" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle par statements a sequenceDiagram" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\npar Parallel one\nAlice->>Bob: Hello Bob, how are you?\nBob-->>Alice: I am good thanks!\nand Parallel two\nAlice->>Bob: Are you OK?\nBob-->>Alice: Fine!\nand Parallel three\nAlice->>Bob: What do you think about it?\nBob-->>Alice: It's good!\nend",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from=- to=- kind=19 message="Parallel one" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Alice" to="Bob" kind=0 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=1 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from=- to=- kind=20 message="Parallel two" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from="Alice" to="Bob" kind=0 message="Are you OK?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from="Bob" to="Alice" kind=1 message="Fine!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 6 from=- to=- kind=20 message="Parallel three" wrap=false activate=false placement=- central=0 numbering=-
      #|message 7 from="Alice" to="Bob" kind=0 message="What do you think about it?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 8 from="Bob" to="Alice" kind=1 message="It's good!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 9 from=- to=- kind=21 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "it should handle par_over statements" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\npar_over Parallel overlap\nAlice ->> Bob: Message\nNote left of Alice: Alice note\nNote right of Bob: Bob note\nend",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from=- to=- kind=32 message="Parallel overlap" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Alice" to="Bob" kind=0 message="Message" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Alice" to="Alice" kind=2 message="Alice note" wrap=false activate=false placement=0 central=0 numbering=-
      #|message 3 from="Bob" to="Bob" kind=2 message="Bob note" wrap=false activate=false placement=1 central=0 numbering=-
      #|message 4 from=- to=- kind=21 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|note "Alice" placement=0 message="Alice note" wrap=false
      #|note "Bob" placement=1 message="Bob note" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle special characters in signals" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nAlice->Bob: Hello Bob, how are you?\nNote right of Bob: -:<>,;# comment",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Bob" kind=2 message="-:<>," wrap=false activate=false placement=1 central=0 numbering=-
      #|note "Bob" placement=1 message="-:<>," wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle special characters in loop" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nAlice->Bob: Hello Bob, how are you?\nloop -:<>,;# comment\nBob-->Alice: I am good thanks!\nend",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from=- to=- kind=10 message="-:<>," wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from=- to=- kind=11 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle special characters in opt" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nAlice->Bob: Hello Bob, how are you?\nopt -:<>,;# comment\nBob-->Alice: I am good thanks!\nend",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from=- to=- kind=15 message="-:<>," wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from=- to=- kind=16 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle special characters in alt" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nAlice->Bob: Hello Bob, how are you?\nalt -:<>,;# comment\nBob-->Alice: I am good thanks!\nelse ,<>:-#; comment\nBob-->Alice: I am good thanks!\nend",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from=- to=- kind=12 message="-:<>," wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from=- to=- kind=13 message=",<>:-" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from=- to=- kind=14 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle special characters in par" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nAlice->Bob: Hello Bob, how are you?\npar -:<>,;# comment\nBob-->Alice: I am good thanks!\nand ,<>:-#; comment\nBob-->Alice: I am good thanks!\nend",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from=- to=- kind=19 message="-:<>," wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from=- to=- kind=20 message=",<>:-" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from=- to=- kind=21 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle no-label loop" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nAlice->Bob: Hello Bob, how are you?\nloop\nBob-->Alice: I am good thanks!\nend",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from=- to=- kind=10 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from=- to=- kind=11 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle no-label opt" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nAlice->Bob: Hello Bob, how are you?\nopt # comment\nBob-->Alice: I am good thanks!\nend",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from=- to=- kind=15 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from=- to=- kind=16 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle no-label alt" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nAlice->Bob: Hello Bob, how are you?\nalt;Bob-->Alice: I am good thanks!\nelse # comment\nBob-->Alice: I am good thanks!\nend",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from=- to=- kind=12 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from=- to=- kind=13 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from=- to=- kind=14 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle no-label par" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nAlice->Bob: Hello Bob, how are you?\npar;Bob-->Alice: I am good thanks!\nand # comment\nBob-->Alice: I am good thanks!\nend",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from=- to=- kind=19 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from=- to=- kind=20 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from=- to=- kind=21 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle links" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nparticipant a as Alice\nparticipant b as Bob\nparticipant c as Charlie\nlinks a: { \"Repo\": \"https://repo.contoso.com/\", \"Dashboard\": \"https://dashboard.contoso.com/\" }\nlinks b: { \"Dashboard\": \"https://dashboard.contoso.com/\" }\nlinks a: { \"On-Call\": \"https://oncall.contoso.com/?svc=alice\" }\nlink a: Endpoint @ https://alice.contoso.com\nlink a: Swagger @ https://swagger.contoso.com\nlink a: Tests @ https://tests.contoso.com/?svc=alice@contoso.com\n",
    ),
    content=(
      #|actor "a" name="a" description="Alice" wrap=false kind="participant" box=none prev=- next="b" links={"Repo":"https://repo.contoso.com/","Dashboard":"https://dashboard.contoso.com/","On-Call":"https://oncall.contoso.com/?svc=alice","Endpoint":"https://alice.contoso.com","Swagger":"https://swagger.contoso.com","Tests":"https://tests.contoso.com/?svc=alice@contoso.com"} properties={} details=-
      #|actor "b" name="b" description="Bob" wrap=false kind="participant" box=none prev="a" next="c" links={"Dashboard":"https://dashboard.contoso.com/"} properties={} details=-
      #|actor "c" name="c" description="Charlie" wrap=false kind="participant" box=none prev="b" next=- links={} properties={} details=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle properties EXPERIMENTAL: USE WITH CAUTION" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nparticipant a as Alice\nparticipant b as Bob\nparticipant c as Charlie\nproperties a: {\"class\": \"internal-service-actor\", \"icon\": \"@clock\"}\nproperties b: {\"class\": \"external-service-actor\", \"icon\": \"@computer\"}\n",
    ),
    content=(
      #|actor "a" name="a" description="Alice" wrap=false kind="participant" box=none prev=- next="b" links={} properties={"class":"internal-service-actor","icon":"@clock"} details=-
      #|actor "b" name="b" description="Bob" wrap=false kind="participant" box=none prev="a" next="c" links={} properties={"class":"external-service-actor","icon":"@computer"} details=-
      #|actor "c" name="c" description="Charlie" wrap=false kind="participant" box=none prev="b" next=- links={} properties={} details=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle box" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nbox green Group 1\nparticipant a as Alice\nparticipant b as Bob\nend\nparticipant c as Charlie\nlinks a: { \"Repo\": \"https://repo.contoso.com/\", \"Dashboard\": \"https://dashboard.contoso.com/\" }\nlinks b: { \"Dashboard\": \"https://dashboard.contoso.com/\" }\nlinks a: { \"On-Call\": \"https://oncall.contoso.com/?svc=alice\" }\nlink a: Endpoint @ https://alice.contoso.com\nlink a: Swagger @ https://swagger.contoso.com\nlink a: Tests @ https://tests.contoso.com/?svc=alice@contoso.com\n",
    ),
    content=(
      #|actor "a" name="a" description="Alice" wrap=false kind="participant" box="Group 1" prev=- next="b" links={"Repo":"https://repo.contoso.com/","Dashboard":"https://dashboard.contoso.com/","On-Call":"https://oncall.contoso.com/?svc=alice","Endpoint":"https://alice.contoso.com","Swagger":"https://swagger.contoso.com","Tests":"https://tests.contoso.com/?svc=alice@contoso.com"} properties={} details=-
      #|actor "b" name="b" description="Bob" wrap=false kind="participant" box="Group 1" prev="a" next="c" links={"Dashboard":"https://dashboard.contoso.com/"} properties={} details=-
      #|actor "c" name="c" description="Charlie" wrap=false kind="participant" box=none prev="b" next=- links={} properties={} details=-
      #|box "Group 1" fill="green" wrap=false actors="a","b"
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle box without color" {
  inspect(
    spec_parsed(
      "\n  sequenceDiagram\n  box Group 1\n  participant a as Alice\n  participant b as Bob\n  end\n  participant c as Charlie\n  links a: { \"Repo\": \"https://repo.contoso.com/\", \"Dashboard\": \"https://dashboard.contoso.com/\" }\n  links b: { \"Dashboard\": \"https://dashboard.contoso.com/\" }\n  links a: { \"On-Call\": \"https://oncall.contoso.com/?svc=alice\" }\n  link a: Endpoint @ https://alice.contoso.com\n  link a: Swagger @ https://swagger.contoso.com\n  link a: Tests @ https://tests.contoso.com/?svc=alice@contoso.com\n  ",
    ),
    content=(
      #|actor "a" name="a" description="Alice" wrap=false kind="participant" box="Group 1" prev=- next="b" links={"Repo":"https://repo.contoso.com/","Dashboard":"https://dashboard.contoso.com/","On-Call":"https://oncall.contoso.com/?svc=alice","Endpoint":"https://alice.contoso.com","Swagger":"https://swagger.contoso.com","Tests":"https://tests.contoso.com/?svc=alice@contoso.com"} properties={} details=-
      #|actor "b" name="b" description="Bob" wrap=false kind="participant" box="Group 1" prev="a" next="c" links={"Dashboard":"https://dashboard.contoso.com/"} properties={} details=-
      #|actor "c" name="c" description="Charlie" wrap=false kind="participant" box=none prev="b" next=- links={} properties={} details=-
      #|box "Group 1" fill="transparent" wrap=false actors="a","b"
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle box without description" {
  inspect(
    spec_parsed(
      "\n  sequenceDiagram\n  box aqua\n  participant a as Alice\n  participant b as Bob\n  end\n  participant c as Charlie\n  links a: { \"Repo\": \"https://repo.contoso.com/\", \"Dashboard\": \"https://dashboard.contoso.com/\" }\n  links b: { \"Dashboard\": \"https://dashboard.contoso.com/\" }\n  links a: { \"On-Call\": \"https://oncall.contoso.com/?svc=alice\" }\n  link a: Endpoint @ https://alice.contoso.com\n  link a: Swagger @ https://swagger.contoso.com\n  link a: Tests @ https://tests.contoso.com/?svc=alice@contoso.com\n  ",
    ),
    content=(
      #|actor "a" name="a" description="Alice" wrap=false kind="participant" box=- prev=- next="b" links={"Repo":"https://repo.contoso.com/","Dashboard":"https://dashboard.contoso.com/","On-Call":"https://oncall.contoso.com/?svc=alice","Endpoint":"https://alice.contoso.com","Swagger":"https://swagger.contoso.com","Tests":"https://tests.contoso.com/?svc=alice@contoso.com"} properties={} details=-
      #|actor "b" name="b" description="Bob" wrap=false kind="participant" box=- prev="a" next="c" links={"Dashboard":"https://dashboard.contoso.com/"} properties={} details=-
      #|actor "c" name="c" description="Charlie" wrap=false kind="participant" box=none prev="b" next=- links={} properties={} details=-
      #|box - fill="aqua" wrap=false actors="a","b"
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle simple actor creation" {
  inspect(
    spec_parsed(
      "\n  sequenceDiagram\n  participant a as Alice\n  a ->>b: Hello Bob?\n  create participant c\n  b-->>c: Hello c!\n  c ->> b: Hello b?\n  create actor d as Donald\n  a ->> d: Hello Donald?\n  ",
    ),
    content=(
      #|actor "a" name="a" description="Alice" wrap=false kind="participant" box=none prev=- next="b" links={} properties={} details=-
      #|actor "b" name="b" description="b" wrap=false kind="participant" box=none prev="a" next="c" links={} properties={} details=-
      #|actor "c" name="c" description="c" wrap=false kind="participant" box=none prev="b" next="d" links={} properties={} details=-
      #|actor "d" name="d" description="Donald" wrap=false kind="actor" box=none prev="c" next=- links={} properties={} details=-
      #|message 0 from="a" to="b" kind=0 message="Hello Bob?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="b" to="c" kind=1 message="Hello c!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="c" to="b" kind=0 message="Hello b?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="a" to="d" kind=0 message="Hello Donald?" wrap=false activate=false placement=- central=0 numbering=-
      #|created "c"=1
      #|created "d"=3
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle simple actor destruction" {
  inspect(
    spec_parsed(
      "\n  sequenceDiagram\n  participant a as Alice\n  a ->>b: Hello Bob?\n  destroy a\n  b-->>a: Hello Alice!\n  b ->> c: Where is Alice?\n  destroy c\n  b ->> c: Where are you?\n  ",
    ),
    content=(
      #|actor "a" name="a" description="Alice" wrap=false kind="participant" box=none prev=- next="b" links={} properties={} details=-
      #|actor "b" name="b" description="b" wrap=false kind="participant" box=none prev="a" next="c" links={} properties={} details=-
      #|actor "c" name="c" description="c" wrap=false kind="participant" box=none prev="b" next=- links={} properties={} details=-
      #|message 0 from="a" to="b" kind=0 message="Hello Bob?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="b" to="a" kind=1 message="Hello Alice!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="b" to="c" kind=0 message="Where is Alice?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="b" to="c" kind=0 message="Where are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|destroyed "a"=1
      #|destroyed "c"=3
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle the creation and destruction of the same actor" {
  inspect(
    spec_parsed(
      "\n  sequenceDiagram\n  a ->>b: Hello Bob?\n  create participant c\n  b ->>c: Hello c!\n  c ->> b: Hello b?\n  destroy c\n  b ->> c : Bye c !\n  ",
    ),
    content=(
      #|actor "a" name="a" description="a" wrap=false kind="participant" box=none prev=- next="b" links={} properties={} details=-
      #|actor "b" name="b" description="b" wrap=false kind="participant" box=none prev="a" next="c" links={} properties={} details=-
      #|actor "c" name="c" description="c" wrap=false kind="participant" box=none prev="b" next=- links={} properties={} details=-
      #|message 0 from="a" to="b" kind=0 message="Hello Bob?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="b" to="c" kind=0 message="Hello c!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="c" to="b" kind=0 message="Hello b?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="b" to="c" kind=0 message="Bye c !" wrap=false activate=false placement=- central=0 numbering=-
      #|created "c"=1
      #|destroyed "c"=3
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle same actor with different whitespace properly" {
  inspect(
    spec_parsed(
      "\nsequenceDiagram\nparticipant Alice\nparticipant Alice\nparticipant Alice\n",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next=- links={} properties={} details=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should increment the sequence number with a decimal in the hundredths place" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      autonumber 10.01 .01\n      Alice->Bob:Hello Bob, how are you?\n      Bob-->Alice: I am good thanks!\n      Alice-->Bob: Have a good day!\n    ",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from=- to=- kind=26 message="" wrap=false activate=false placement=- central=0 numbering=10.01,0.01,true
      #|message 1 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="Alice" to="Bob" kind=6 message="Have a good day!" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should increment the sequence number with a decimal in the tenths place" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      autonumber 10.1 .1\n      Alice->Bob:Hello Bob, how are you?\n      Bob-->Alice: I am good thanks!\n      Alice-->Bob: Have a good day!\n    ",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from=- to=- kind=26 message="" wrap=false activate=false placement=- central=0 numbering=10.1,0.1,true
      #|message 1 from="Alice" to="Bob" kind=5 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=6 message="I am good thanks!" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="Alice" to="Bob" kind=6 message="Have a good day!" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse a message with a trailing colon but no content" {
  inspect(
    spec_parsed("\nsequenceDiagram\nAlice->>Bob:\nBob->>Alice:Got it!\n"),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="participant" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="participant" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=0 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Alice" kind=0 message="Got it!" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "1 should parse " {
  inspect(
    spec_parsed(
      "\n    sequenceDiagram\n    actor Bob\n    actor Alice\n        Bob -|\\ Alice: Hello Alice, how are you?\n        Bob -|/ Alice: Hello Alice, how are you?\n        Bob -// Alice: Hello Alice, how are you?\n        Bob -\\\\ Alice: Hello Alice, how are you?\n        \n        Bob \\|- Alice: Hello Alice, how are you?\n        Bob /|- Alice: Hello Alice, how are you?\n        Bob //- Alice: Hello Alice, how are you?\n        Bob \\\\- Alice: Hello Alice, how are you?        \n    ",
    ),
    content=(
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="actor" box=none prev=- next="Alice" links={} properties={} details=-
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="actor" box=none prev="Bob" next=- links={} properties={} details=-
      #|message 0 from="Bob" to="Alice" kind=41 message="Hello Alice, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Alice" kind=42 message="Hello Alice, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Bob" to="Alice" kind=44 message="Hello Alice, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="Bob" to="Alice" kind=43 message="Hello Alice, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from="Bob" to="Alice" kind=46 message="Hello Alice, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from="Bob" to="Alice" kind=45 message="Hello Alice, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 6 from="Bob" to="Alice" kind=47 message="Hello Alice, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|message 7 from="Bob" to="Alice" kind=48 message="Hello Alice, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "2 should parse " {
  inspect(
    spec_parsed(
      "\n    sequenceDiagram\n    actor Bob\n    actor Alice\n      Alice ()<<->>() Bob: hey?\n    ",
    ),
    content=(
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="actor" box=none prev=- next="Alice" links={} properties={} details=-
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="actor" box=none prev="Bob" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=33 message="hey?" wrap=false activate=true placement=- central=61 numbering=-
      #|message 1 from="Bob" to=- kind=59 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Alice" to=- kind=60 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse participants with different quote styles and whitespace" {
  inspect(
    spec_parsed(
      "\n  sequenceDiagram\n      participant Alice@{ \"type\" : \"database\" }\n      participant Bob@{ \"type\" : \"database\" }\n      participant Carl@{ type: \"database\" }\n      participant David@{ \"type\" : 'database' }\n      participant Eve@{ type: 'database' }\n      participant Favela@{ \"type\" : \"database\"    }\n      Bob->>+Alice: Hi Alice\n      Alice->>+Bob: Hi Bob\n    ",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="database" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="database" box=none prev="Alice" next="Carl" links={} properties={} details=-
      #|actor "Carl" name="Carl" description="Carl" wrap=false kind="database" box=none prev="Bob" next="David" links={} properties={} details=-
      #|actor "David" name="David" description="David" wrap=false kind="database" box=none prev="Carl" next="Eve" links={} properties={} details=-
      #|actor "Eve" name="Eve" description="Eve" wrap=false kind="database" box=none prev="David" next="Favela" links={} properties={} details=-
      #|actor "Favela" name="Favela" description="Favela" wrap=false kind="database" box=none prev="Eve" next=- links={} properties={} details=-
      #|message 0 from="Bob" to="Alice" kind=0 message="Hi Alice" wrap=false activate=true placement=- central=0 numbering=-
      #|message 1 from="Alice" to=- kind=17 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Alice" to="Bob" kind=0 message="Hi Bob" wrap=false activate=true placement=- central=0 numbering=-
      #|message 3 from="Bob" to=- kind=17 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse a participant config object separated from the name by whitespace" {
  inspect(
    spec_parsed(
      "\n  sequenceDiagram\n      participant Gina@{ \"type\" : \"database\" }\n      participant Harry @{ \"type\" : \"database\" }\n    ",
    ),
    content=(
      #|actor "Gina" name="Gina" description="Gina" wrap=false kind="database" box=none prev=- next="Harry" links={} properties={} details=-
      #|actor "Harry" name="Harry" description="Harry" wrap=false kind="database" box=none prev="Gina" next=- links={} properties={} details=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse mixed participant types with extended syntax" {
  inspect(
    spec_parsed(
      "\n    sequenceDiagram\n        participant lead\n        participant dsa@{ \"type\" : \"queue\" }\n        API->>+Database: getUserb\n        Database-->>-API: userb\n        dsa --> Database: hello\n",
    ),
    content=(
      #|actor "lead" name="lead" description="lead" wrap=false kind="participant" box=none prev=- next="dsa" links={} properties={} details=-
      #|actor "dsa" name="dsa" description="dsa" wrap=false kind="queue" box=none prev="lead" next="API" links={} properties={} details=-
      #|actor "API" name="API" description="API" wrap=false kind="participant" box=none prev="dsa" next="Database" links={} properties={} details=-
      #|actor "Database" name="Database" description="Database" wrap=false kind="participant" box=none prev="API" next=- links={} properties={} details=-
      #|message 0 from="API" to="Database" kind=0 message="getUserb" wrap=false activate=true placement=- central=0 numbering=-
      #|message 1 from="Database" to=- kind=17 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="Database" to="API" kind=1 message="userb" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="Database" to=- kind=18 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from="dsa" to="Database" kind=6 message="hello" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse hyphenated names with an attached config object" {
  inspect(
    spec_parsed(
      "\n    sequenceDiagram\n        actor lead-actor@{ \"type\" : \"database\" }\n        participant order-svc@{ \"type\" : \"queue\" }\n        actor kebab-case@{ \"type\" : \"control\" } as Kebab-Cased\n        participant web-ui@{ \"type\" : \"entity\" } as Web UI\n    ",
    ),
    content=(
      #|actor "lead-actor" name="lead-actor" description="lead-actor" wrap=false kind="database" box=none prev=- next="order-svc" links={} properties={} details=-
      #|actor "order-svc" name="order-svc" description="order-svc" wrap=false kind="queue" box=none prev="lead-actor" next="kebab-case" links={} properties={} details=-
      #|actor "kebab-case" name="kebab-case" description="Kebab-Cased" wrap=false kind="control" box=none prev="order-svc" next="web-ui" links={} properties={} details=-
      #|actor "web-ui" name="web-ui" description="Web UI" wrap=false kind="entity" box=none prev="kebab-case" next=- links={} properties={} details=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should fail for malformed JSON in participant definition" {
  inspect(
    spec_parsed(
      "\n    sequenceDiagram\n      participant D@{ \"type: \"entity\" }\n      participant E@{ \"type\": \"dat\n      abase }\n  ",
    ),
    content=(
      #|error: Config of participant "D" is not valid YAML. YAML: missed comma between flow collection entries
    ),
  )
}

///|
test "should fail for missing colon separator" {
  inspect(
    spec_parsed(
      "\n    sequenceDiagram\n      participant C@{ \"type\" \"control\" }\n      C ->> C: action\n  ",
    ),
    content=(
      #|error: Config of participant "C" is not valid YAML. YAML: missed comma between flow collection entries
    ),
  )
}

///|
test "should fail for missing closing brace" {
  inspect(
    spec_parsed(
      "\n    sequenceDiagram\n      participant E@{ \"type\": \"entity\"\n      E ->> E: process\n  ",
    ),
    content=(
      #|error: Parse error on line 4:
      #|      E ->> E: process
      #|----------------------^
      #|Expecting 'CONFIG_END', got '$end'
    ),
  )
}

///|
test "should parse boundary participant" {
  inspect(
    spec_parsed(
      "\n          sequenceDiagram\n          participant boundary@{ \"type\" : \"boundary\" }\n          boundary->boundary: test\n      ",
    ),
    content=(
      #|actor "boundary" name="boundary" description="boundary" wrap=false kind="boundary" box=none prev=- next=- links={} properties={} details=-
      #|message 0 from="boundary" to="boundary" kind=5 message="test" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse control participant" {
  inspect(
    spec_parsed(
      "\n        sequenceDiagram\n         participant C@{ \"type\" : \"control\" }\n        C->C: test\n        ",
    ),
    content=(
      #|actor "C" name="C" description="C" wrap=false kind="control" box=none prev=- next=- links={} properties={} details=-
      #|message 0 from="C" to="C" kind=5 message="test" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse entity participant" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      participant E@{ \"type\" : \"entity\" }\n      E->E: test\n      ",
    ),
    content=(
      #|actor "E" name="E" description="E" wrap=false kind="entity" box=none prev=- next=- links={} properties={} details=-
      #|message 0 from="E" to="E" kind=5 message="test" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse database participant" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      participant D@{ \"type\" : \"database\" }\n      D->D: test\n      ",
    ),
    content=(
      #|actor "D" name="D" description="D" wrap=false kind="database" box=none prev=- next=- links={} properties={} details=-
      #|message 0 from="D" to="D" kind=5 message="test" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse collections participant" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      participant L@{ \"type\" : \"collections\" }\n      L->L: test\n      ",
    ),
    content=(
      #|actor "L" name="L" description="L" wrap=false kind="collections" box=none prev=- next=- links={} properties={} details=-
      #|message 0 from="L" to="L" kind=5 message="test" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse queue participant" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      participant Q@{ \"type\" : \"queue\" }\n      Q->Q: test \n      ",
    ),
    content=(
      #|actor "Q" name="Q" description="Q" wrap=false kind="queue" box=none prev=- next=- links={} properties={} details=-
      #|message 0 from="Q" to="Q" kind=5 message="test" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse actor participant" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      participant A@{ \"type\" : \"queue\" }\n      A->A: test\n      ",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="queue" box=none prev=- next=- links={} properties={} details=-
      #|message 0 from="A" to="A" kind=5 message="test" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse participant participant" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      participant P@{ \"type\" : \"database\" }\n      P->P: test\n      ",
    ),
    content=(
      #|actor "P" name="P" description="P" wrap=false kind="database" box=none prev=- next=- links={} properties={} details=-
      #|message 0 from="P" to="P" kind=5 message="test" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse boundary using actor keyword" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n        participant Alice@{ \"type\" : \"collections\" }\n        participant Bob@{ \"type\" : \"control\" }\n        Alice->>Bob: Hello Bob, how are you?\n      ",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Alice" wrap=false kind="collections" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Bob" wrap=false kind="control" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=0 message="Hello Bob, how are you?" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse control using participant keyword" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      participant C@{ \"type\" : \"control\" }\n      C->C: test\n      ",
    ),
    content=(
      #|actor "C" name="C" description="C" wrap=false kind="control" box=none prev=- next=- links={} properties={} details=-
      #|message 0 from="C" to="C" kind=5 message="test" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle fail parsing when alias token causes conflicts in participant definition" {
  inspect(
    spec_parsed(
      "\n        sequenceDiagram\n        participant SAS MyServiceWithMoreThan20Chars <br> service decription\n       ",
    ),
    content=(
      #|error: Parse error on line 3:
      #|        participant SAS MyServiceWithMoreThan20Chars <br> service decription
      #|--------------------^
      #|Expecting 'ACTOR', got 'INVALID'
    ),
  )
}

///|
test "should not hang when \"as\" is used without a space before the alias text" {
  inspect(
    spec_parsed(
      "\n          sequenceDiagram\n          participant X_AutoPublishable asAAAAAAAAAAAAA:AAAAAAAAAAAAA\n        ",
    ),
    content=(
      #|error: Parse error on line 3:
      #|          participant X_AutoPublishable asAAAAAAAAAAAAA:AAAAAAAAAAAAA
      #|----------------------^
      #|Expecting 'ACTOR', got 'INVALID'
    ),
  )
}

///|
test "should parse participant with stereotype and alias" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      participant Alice@{ \"type\" : \"boundary\" } as Public API\n      participant Bob@{ \"type\" : \"control\" } as Controller\n      Alice->>Bob: Request\n      Bob-->>Alice: Response\n      ",
    ),
    content=(
      #|actor "Alice" name="Alice" description="Public API" wrap=false kind="boundary" box=none prev=- next="Bob" links={} properties={} details=-
      #|actor "Bob" name="Bob" description="Controller" wrap=false kind="control" box=none prev="Alice" next=- links={} properties={} details=-
      #|message 0 from="Alice" to="Bob" kind=0 message="Request" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Bob" to="Alice" kind=1 message="Response" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse actor with stereotype and alias" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      actor A@{ \"type\" : \"database\" } AS Database Server\n      actor B@{ \"type\" : \"queue\" } as Message Queue\n      A->>B: Send message\n      ",
    ),
    content=(
      #|actor "A" name="A" description="Database Server" wrap=false kind="database" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="Message Queue" wrap=false kind="queue" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="A" to="B" kind=0 message="Send message" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse participant with stereotype and simple alias" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      participant API@{ \"type\" : \"boundary\" } AS Public API\n      API->>API: test\n      ",
    ),
    content=(
      #|actor "API" name="API" description="Public API" wrap=false kind="boundary" box=none prev=- next=- links={} properties={} details=-
      #|message 0 from="API" to="API" kind=0 message="test" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse participant with inline alias in config object" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      participant API@{ \"type\" : \"boundary\", \"alias\": \"Public API\" }\n      participant Auth@{ \"type\" : \"control\", \"alias\": \"Auth Controller\" }\n      API->>Auth: Request\n      Auth-->>API: Response\n      ",
    ),
    content=(
      #|actor "API" name="API" description="Public API" wrap=false kind="boundary" box=none prev=- next="Auth" links={} properties={} details=-
      #|actor "Auth" name="Auth" description="Auth Controller" wrap=false kind="control" box=none prev="API" next=- links={} properties={} details=-
      #|message 0 from="API" to="Auth" kind=0 message="Request" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="Auth" to="API" kind=1 message="Response" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should parse actor with inline alias in config object" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      actor U@{ \"type\" : \"actor\", \"alias\": \"End User\" }\n      actor DB@{ \"type\" : \"database\", \"alias\": \"User Database\" }\n      U->>DB: Query\n      DB-->>U: Result\n      ",
    ),
    content=(
      #|actor "U" name="U" description="End User" wrap=false kind="actor" box=none prev=- next="DB" links={} properties={} details=-
      #|actor "DB" name="DB" description="User Database" wrap=false kind="database" box=none prev="U" next=- links={} properties={} details=-
      #|message 0 from="U" to="DB" kind=0 message="Query" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="DB" to="U" kind=1 message="Result" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should prioritize external alias over inline alias" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      participant API@{ \"type\" : \"boundary\", \"alias\": \"Internal Name\" } as External Name\n      API->>API: test\n      ",
    ),
    content=(
      #|actor "API" name="API" description="External Name" wrap=false kind="boundary" box=none prev=- next=- links={} properties={} details=-
      #|message 0 from="API" to="API" kind=0 message="test" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle participant with only inline alias (no type)" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      participant API@{ \"alias\": \"Public API\" }\n      API->>API: test\n      ",
    ),
    content=(
      #|actor "API" name="API" description="Public API" wrap=false kind="participant" box=none prev=- next=- links={} properties={} details=-
      #|message 0 from="API" to="API" kind=0 message="test" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "should handle mixed inline and external alias syntax" {
  inspect(
    spec_parsed(
      "\n      sequenceDiagram\n      participant A@{ \"type\" : \"boundary\", \"alias\": \"Service A\" }\n      participant B@{ \"type\" : \"control\" } as Service B\n      participant C@{ \"type\" : \"database\" }\n      A->>B: Request\n      B->>C: Query\n      ",
    ),
    content=(
      #|actor "A" name="A" description="Service A" wrap=false kind="boundary" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="Service B" wrap=false kind="control" box=none prev="A" next="C" links={} properties={} details=-
      #|actor "C" name="C" description="C" wrap=false kind="database" box=none prev="B" next=- links={} properties={} details=-
      #|message 0 from="A" to="B" kind=0 message="Request" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="B" to="C" kind=0 message="Query" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "keyword actors: accepts Link as a message recipient (the reported case)" {
  inspect(
    spec_parsed(
      "sequenceDiagram\n    participant A\n    participant Link as Channel\n    A->>Link: message",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="Link" links={} properties={} details=-
      #|actor "Link" name="Link" description="Channel" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="A" to="Link" kind=0 message="message" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "keyword actors: accepts Link as a message sender" {
  inspect(
    spec_parsed(
      "sequenceDiagram\n    participant A\n    participant Link as Channel\n    Link->>A: message",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="Link" links={} properties={} details=-
      #|actor "Link" name="Link" description="Channel" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="Link" to="A" kind=0 message="message" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "keyword actors: accepts Link as a sender with spaces around the arrow" {
  inspect(
    spec_parsed(
      "sequenceDiagram\n    participant A\n    participant Link as Channel\n    Link  -->>A: message",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="Link" links={} properties={} details=-
      #|actor "Link" name="Link" description="Channel" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="Link" to="A" kind=1 message="message" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "keyword actors: accepts Link as a recipient with a space before the colon" {
  inspect(
    spec_parsed(
      "sequenceDiagram\n    participant A\n    participant Link as Channel\n    A->>Link : message",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="Link" links={} properties={} details=-
      #|actor "Link" name="Link" description="Channel" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="A" to="Link" kind=0 message="message" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "keyword actors: keeps the original spelling of the participant id" {
  inspect(
    spec_parsed(
      "sequenceDiagram\n    participant A\n    participant LINK as Channel\n    A->>LINK: message",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="LINK" links={} properties={} details=-
      #|actor "LINK" name="LINK" description="Channel" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="A" to="LINK" kind=0 message="message" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "keyword actors: does not treat the word link inside a message as a directive" {
  inspect(
    spec_parsed(
      "sequenceDiagram\n    participant A\n    participant B\n    A->>B: see the link page",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="A" to="B" kind=0 message="see the link page" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "keyword actors: parses a link statement" {
  inspect(
    spec_parsed(
      "sequenceDiagram\n    participant A\n    link A: Help @ https://example.com",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next=- links={"Help":"https://example.com"} properties={} details=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "keyword actors: parses a link statement with a space before the colon" {
  inspect(
    spec_parsed(
      "sequenceDiagram\n    participant A\n    link A : Help @ https://example.com",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next=- links={"Help":"https://example.com"} properties={} details=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "keyword actors: parses a links statement" {
  inspect(
    spec_parsed(
      "sequenceDiagram\n    participant A\n    links A: {\"help\": \"https://example.com\"}",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next=- links={"help":"https://example.com"} properties={} details=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "keyword actors: parses a properties statement" {
  inspect(
    spec_parsed(
      "sequenceDiagram\n    participant A\n    properties A: {\"color\": \"red\"}",
    ),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next=- links={} properties={"color":"red"} details=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}
