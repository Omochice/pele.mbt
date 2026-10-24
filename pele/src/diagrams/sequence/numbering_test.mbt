// The expected numbers were taken from pele's numberMessages.

///|
fn numbers(source : String, always~ : Bool) -> String {
  let db = @sequence.SeqDb::new()
  @sequence.parse_sequence(source, db) catch {
    @errors.PeleError(failure) => return "error: \{failure.message}"
  }
  let numbering = @sequence.number_messages(db.messages, always)
  let index = numbering.index.map(n => n.to_string()).join(",")
  let shown = numbering.shown.map(s => s.to_string()).join(",")
  "index=\{index}\nshown=\{shown}\nvisible=\{numbering.visible}"
}

///|
test "numbers nothing without autonumber" {
  inspect(
    numbers(
      "sequenceDiagram\nA->>B: one\nB-->>A: two\nA->>A: three",
      always=false,
    ),
    content=(
      #|index=1,2,3
      #|shown=false,false,false
      #|visible=false
    ),
  )
}

///|
test "numbers every message line when the config says so" {
  inspect(
    numbers(
      "sequenceDiagram\nA->>B: one\nNote over A: n\nB-->>A: two",
      always=true,
    ),
    content=(
      #|index=1,NaN,2
      #|shown=true,false,true
      #|visible=false
    ),
  )
}

///|
test "numbers from autonumber on, past notes and activations" {
  inspect(
    numbers(
      "sequenceDiagram\nA->>B: zero\nautonumber\nA->>+B: one\nNote over A: n\nB-->>-A: two\nloop x\nA-xB: three\nend\nA<<->>B: four\nA-|\\B: five",
      always=false,
    ),
    content=(
      #|index=1,NaN,2,NaN,NaN,3,NaN,NaN,4,NaN,5,6
      #|shown=false,false,true,false,false,true,false,false,true,false,true,true
      #|visible=true
    ),
  )
}

///|
test "numbers with a start and a step" {
  inspect(
    numbers(
      "sequenceDiagram\nautonumber 10 5\nA->>B: one\nB-->>A: two\nautonumber 3\nA->>B: three",
      always=false,
    ),
    content=(
      #|index=NaN,10,15,NaN,3
      #|shown=false,true,true,false,true
      #|visible=true
    ),
  )
}

///|
test "numbers in hundredths without drift" {
  inspect(
    numbers(
      "sequenceDiagram\nautonumber 10.01 .01\nA->>B: a\nA->>B: b\nA->>B: c\nautonumber 0.1 0.2\nA->>B: d\nA->>B: e\nA->>B: f",
      always=false,
    ),
    content=(
      #|index=NaN,10.01,10.02,10.03,NaN,0.1,0.3,0.5
      #|shown=false,true,true,true,false,true,true,true
      #|visible=true
    ),
  )
}

///|
test "keeps counting while numbers are hidden" {
  inspect(
    numbers(
      "sequenceDiagram\nautonumber\nA->>B: one\nautonumber off\nB-->>A: two\nautonumber\nA->>B: three",
      always=false,
    ),
    content=(
      #|index=NaN,1,NaN,2,NaN,3
      #|shown=false,true,false,false,false,true
      #|visible=true
    ),
  )
}

///|
test "keeps the counter for a start of zero" {
  inspect(
    numbers(
      "sequenceDiagram\nA->>B: one\nautonumber 0 0\nA->>B: two\nA->>B: three",
      always=false,
    ),
    content=(
      #|index=1,NaN,2,3
      #|shown=false,false,true,true
      #|visible=true
    ),
  )
}
