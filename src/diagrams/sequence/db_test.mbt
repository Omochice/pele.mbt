// The expected models were taken from pele's SeqDb, given the same statements.

///|
fn model(
  statements : Array[@sequence.SeqStatement],
  wrap? : Bool,
  sequence_wrap~ : Bool = false,
) -> String {
  let db = @sequence.SeqDb::new(wrap?, sequence_wrap~)
  db.apply(statements) catch {
    @errors.PeleError(failure) => return "error: \{failure.message}"
  }
  dump(db)
}

///|
fn t(text : String, wrap? : Bool) -> @sequence.SeqText {
  { text, wrap, }
}

///|
fn p(
  actor : String,
  draw? : String,
  description? : @sequence.SeqText,
  config? : String,
) -> @sequence.SeqStatement {
  AddParticipant(actor~, draw~, description~, config~)
}

///|
fn message(
  from : String,
  to : String,
  msg : @sequence.SeqText,
  kind~ : Int32 = 0,
  activate~ : Bool = false,
  central? : Int32,
) -> @sequence.SeqStatement {
  AddMessage(
    from~,
    to~,
    signal_type=kind,
    msg~,
    activate~,
    central_connection=central,
  )
}

///|
fn messages() -> String {
  let db = @sequence.SeqDb::new()
  let texts = [
    "  plain  ", "wrap: a", ":wrap: b", "nowrap: c", ":nowrap:d", "wrap:", "Wrap: e",
    " wrap: f ",
  ]
  texts
  .map(text => {
    let parsed = db.parse_message(text)
    "\{quote(text)} => \{quote(parsed.text)} \{show_wrap(parsed.wrap)}"
  })
  .join("\n")
}

///|
fn boxes() -> String {
  let db = @sequence.SeqDb::new()
  let lines = [
    "Aqua Group One", "Group Two", "rgb(1, 2, 3)", "green Team", "Team green", "rgb(34, 56, 0) Group1",
    "hsl(120deg 50% 50% / 0.5) H", "rgb(1, 2) Bad", "transparent Aqua", "GrayText Disabled",
    "wrap: Wrapped title", "red wrap: W", "", "   ", "red", "rgb (1,2,3)x", "rgb(1,\n2,3) T",
    "hsla(1, 2%, 3%, 1)) x)", "nowrap:", "\u{e9}t\u{e9} x", "rgba  (1,2,3,1) Q",
  ]
  lines
  .map(line => {
    let data = db.parse_box_data(line)
    let text = match data.text {
      Some(text) => quote(text)
      None => "-"
    }
    "\{quote(line)} => \{text} \{quote(data.color)} \{show_wrap(data.wrap)}"
  })
  .join("\n")
}

///|
fn acc_titles() -> String {
  let db = @sequence.SeqDb::new()
  ["  title  ", "\n\tx"]
  .map(text => {
    db.set_acc_title(text)
    quote(db.acc_title.unwrap_or(""))
  })
  .join("\n")
}

///|
fn acc_descrs() -> String {
  let db = @sequence.SeqDb::new()
  ["a\n   b\n\n  c", "x\n\n\ny", " lead\n"]
  .map(text => {
    db.set_acc_description(text)
    quote(db.acc_descr.unwrap_or(""))
  })
  .join("\n")
}

///|
test "collects participants in order of mention and links neighbours" {
  inspect(
    model([
      p("A", draw="participant", description=t("Alice")),
      p("B"),
      p("A"),
      p("B"),
      message("A", "B", t("hi")),
      p("C", draw="actor"),
    ]),
    content=(
      #|actor "A" name="A" description="Alice" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="A" next="C" links={} properties={} details=-
      #|actor "C" name="C" description="C" wrap=false kind="actor" box=none prev="B" next=- links={} properties={} details=-
      #|message 0 from="A" to="B" kind=0 message="hi" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "replaces a redeclared participant where it stood" {
  inspect(
    model([
      p("A"),
      p("B"),
      p("A", draw="participant", description=t("Al", wrap=true)),
      p("B", draw="actor"),
    ]),
    content=(
      #|actor "A" name="A" description="Al" wrap=true kind="participant" box=none prev="B" next=- links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="A" next="A" links={} properties={} details=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "reads the kind and alias of a participant from its config object" {
  inspect(
    model([
      p(
        "D",
        draw="participant",
        config="\"type\": \"database\", \"alias\": \"Store\"",
      ),
      p(
        "E",
        draw="participant",
        description=t("Outer"),
        config="type: queue, alias: Inner",
      ),
      p("F", draw="actor", config="alias: \"x\"\n"),
      p("G", draw="participant", config="\"type\": nonsense"),
      p("H", draw="participant", config="\"type\": 12"),
    ]),
    content=(
      #|actor "D" name="D" description="Store" wrap=false kind="database" box=none prev=- next="E" links={} properties={} details=-
      #|actor "E" name="E" description="Outer" wrap=false kind="queue" box=none prev="D" next="F" links={} properties={} details=-
      #|actor "F" name="F" description="x" wrap=false kind="actor" box=none prev="E" next="G" links={} properties={} details=-
      #|actor "G" name="G" description="G" wrap=false kind="nonsense" box=none prev="F" next="H" links={} properties={} details=-
      #|actor "H" name="H" description="H" wrap=false kind="12" box=none prev="G" next=- links={} properties={} details=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "rejects a config object that is not valid YAML" {
  inspect(
    model([p("C", draw="participant", config="\"type\" \"control\"")]),
    content=(
      #|error: Config of participant "C" is not valid YAML. YAML: missed comma between flow collection entries
    ),
  )
}

///|
test "keeps a participant in the box it was declared in" {
  inspect(
    model([
      BoxStart({ text: Some("G"), color: "Aqua", wrap: None, }),
      p("A", draw="participant"),
      BoxEnd,
      p("A"),
      p("X"),
      BoxStart({ text: None, color: "transparent", wrap: Some(true), }),
      p("B", draw="participant"),
      p("B"),
      BoxEnd,
      p("B", draw="actor"),
    ]),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box="G" prev=- next="X" links={} properties={} details=-
      #|actor "X" name="X" description="X" wrap=false kind="participant" box=none prev="A" next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=- prev="X" next=- links={} properties={} details=-
      #|box "G" fill="Aqua" wrap=false actors="A"
      #|box - fill="transparent" wrap=true actors="B"
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "refuses a participant declared in two boxes" {
  inspect(
    model([
      BoxStart({ text: Some("One"), color: "red", wrap: None, }),
      p("A", draw="participant"),
      BoxEnd,
      BoxStart({ text: None, color: "red", wrap: None, }),
      p("A", draw="participant"),
      BoxEnd,
    ]),
    content=(
      #|error: A same participant should only be defined in one Box: A can't be in 'One' and in 'undefined' at the same time.
    ),
  )
}

///|
test "counts activations per participant" {
  inspect(
    model([
      p("A"),
      ActiveStart("A"),
      ActiveStart("A"),
      ActiveEnd("A"),
      CentralConnectionStart("A"),
      CentralConnectionReverseStart("B"),
      ActiveEnd("A"),
    ]),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next=- links={} properties={} details=-
      #|message 0 from="A" to=- kind=17 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="A" to=- kind=17 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from="A" to=- kind=18 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="A" to=- kind=59 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 4 from="B" to=- kind=60 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from="A" to=- kind=18 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "refuses to deactivate a participant that is not active" {
  inspect(
    model([p("A"), ActiveStart("A"), ActiveEnd("A"), ActiveEnd("A")]),
    content=(
      #|error: Trying to inactivate an inactive participant (A)
    ),
  )
}

///|
test "records where participants are created and destroyed" {
  inspect(
    model([
      p("A"),
      p("B"),
      message("A", "B", t("hi")),
      CreateParticipant(
        actor="C",
        draw=Some("participant"),
        description=None,
        config=None,
      ),
      p("A"),
      p("C"),
      message("A", "C", t("make"), activate=true, central=59),
      DestroyParticipant("C"),
      p("C"),
      p("A"),
      message("C", "A", t("bye"), kind=3),
      DestroyParticipant("B"),
      message("A", "B", t("end"), kind=3),
    ]),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="A" next="C" links={} properties={} details=-
      #|actor "C" name="C" description="C" wrap=false kind="participant" box=none prev="B" next=- links={} properties={} details=-
      #|message 0 from="A" to="B" kind=0 message="hi" wrap=false activate=false placement=- central=0 numbering=-
      #|message 1 from="A" to="C" kind=0 message="make" wrap=false activate=true placement=- central=59 numbering=-
      #|message 2 from="C" to="A" kind=3 message="bye" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from="A" to="B" kind=3 message="end" wrap=false activate=false placement=- central=0 numbering=-
      #|created "C"=1
      #|destroyed "C"=2
      #|destroyed "B"=3
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "refuses to create a participant that exists" {
  inspect(
    model([
      p("A"),
      CreateParticipant(
        actor="A",
        draw=Some("participant"),
        description=None,
        config=None,
      ),
    ]),
    content=(
      #|error: It is not possible to have actors with the same id, even if one is destroyed before the next is created. Use 'AS' aliases to simulate the behavior
    ),
  )
}

///|
test "refuses a creation without a message to the created participant" {
  inspect(
    model([
      CreateParticipant(
        actor="C",
        draw=Some("participant"),
        description=None,
        config=None,
      ),
      p("A"),
      p("B"),
      message("A", "B", t("x")),
    ]),
    content=(
      #|error: The created participant C does not have an associated creating message after its declaration. Please check the sequence diagram.
    ),
  )
}

///|
test "refuses a destruction without a message from or to the destroyed participant" {
  inspect(
    model([
      p("A"),
      p("B"),
      DestroyParticipant("B"),
      p("A"),
      p("C"),
      message("A", "C", t("x")),
    ]),
    content=(
      #|error: The destroyed participant B does not have an associated destroying message after its declaration. Please check the sequence diagram.
    ),
  )
}

///|
test "adds notes to the messages" {
  inspect(
    model([
      p("A"),
      AddNote(actors=["A"], placement=0, text=t("left")),
      p("A"),
      p("B"),
      AddNote(actors=["A", "B"], placement=2, text=t("over", wrap=true)),
      AddNote(actors=["B"], placement=1, text=t("right", wrap=false)),
    ]),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="B" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="A" to="A" kind=2 message="left" wrap=false activate=false placement=0 central=0 numbering=-
      #|message 1 from="A" to="B" kind=2 message="over" wrap=true activate=false placement=2 central=0 numbering=-
      #|message 2 from="B" to="B" kind=2 message="right" wrap=false activate=false placement=1 central=0 numbering=-
      #|note "A" placement=0 message="left" wrap=false
      #|note "A","B" placement=2 message="over" wrap=true
      #|note "B" placement=1 message="right" wrap=false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "stores participant links, properties, and details" {
  inspect(
    model([
      p("A"),
      AddLinks(
        "A",
        t("{\"Repo\": \"u\", \"b\": 1, \"2\": [1], \"1\": null, \"b\": true}"),
      ),
      AddLinks("A", t("not json")),
      AddALink("A", t("Tests @ https://x@y")),
      AddALink("A", t("NoAt")),
      AddALink("A", t("@lead")),
      AddProperties("A", t("{\"class\": \"c d\", \"icon\": \"@clock\"}")),
      AddProperties("A", t("\"ab\"")),
      AddProperties("A", t("[5, 6]")),
      AddProperties("A", t("7")),
      AddDetails("A", t("el")),
      AddLinks("Z", t("{\"a\": \"b\"}")),
    ]),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next=- links={"1":null,"2":[1],"Repo":"u","b":true,"Tests":"https://x@y","No":"NoAt","@lea":"lead"} properties={"class":"c d","icon":"@clock","0":5,"1":6} details="el"
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "adds numbering switches and block boundaries to the messages" {
  inspect(
    model([
      SequenceIndex(start=Some(10), step=Some(5), visible=true),
      BlockStart(10, t("x")),
      BlockEnd(11),
      BlockStart(12, t("a", wrap=true)),
      BlockStart(13, t("")),
      BlockEnd(14),
      SequenceIndex(start=None, step=None, visible=false),
    ]),
    content=(
      #|message 0 from=- to=- kind=26 message="" wrap=false activate=false placement=- central=0 numbering=10,5,true
      #|message 1 from=- to=- kind=10 message="x" wrap=false activate=false placement=- central=0 numbering=-
      #|message 2 from=- to=- kind=11 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 3 from=- to=- kind=12 message="a" wrap=true activate=false placement=- central=0 numbering=-
      #|message 4 from=- to=- kind=13 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 5 from=- to=- kind=14 message="" wrap=false activate=false placement=- central=0 numbering=-
      #|message 6 from=- to=- kind=26 message="" wrap=false activate=false placement=- central=0 numbering=-,-,false
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "takes the wrap of text without a prefix from the wrap setting" {
  inspect(
    model(
      [
        p("A", draw="participant", description=t("Al")),
        p("B", draw="participant", description=t("Bo", wrap=false)),
        message("A", "B", t("x")),
        AddNote(actors=["A"], placement=0, text=t("n")),
      ],
      wrap=true,
    ),
    content=(
      #|actor "A" name="A" description="Al" wrap=true kind="participant" box=none prev=- next="B" links={} properties={} details=-
      #|actor "B" name="B" description="Bo" wrap=false kind="participant" box=none prev="A" next=- links={} properties={} details=-
      #|message 0 from="A" to="B" kind=0 message="x" wrap=true activate=false placement=- central=0 numbering=-
      #|message 1 from="A" to="A" kind=2 message="n" wrap=true activate=false placement=0 central=0 numbering=-
      #|note "A" placement=0 message="n" wrap=true
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "takes the wrap of text from the sequence wrap setting" {
  inspect(
    model([p("A"), message("A", "A", t("x"))], sequence_wrap=true),
    content=(
      #|actor "A" name="A" description="A" wrap=true kind="participant" box=none prev=- next=- links={} properties={} details=-
      #|message 0 from="A" to="A" kind=0 message="x" wrap=true activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "prefers the wrap setting over the sequence wrap setting" {
  inspect(
    model([p("A"), message("A", "A", t("x"))], wrap=false, sequence_wrap=true),
    content=(
      #|actor "A" name="A" description="A" wrap=false kind="participant" box=none prev=- next=- links={} properties={} details=-
      #|message 0 from="A" to="A" kind=0 message="x" wrap=false activate=false placement=- central=0 numbering=-
      #|title=- accTitle=- accDescr=-
    ),
  )
}

///|
test "reads wrap and nowrap prefixes" {
  inspect(
    messages(),
    content=(
      #|"  plain  " => "plain" undefined
      #|"wrap: a" => "a" true
      #|":wrap: b" => "b" true
      #|"nowrap: c" => "c" false
      #|":nowrap:d" => "d" false
      #|"wrap:" => "" true
      #|"Wrap: e" => "Wrap: e" undefined
      #|" wrap: f " => "f" true
    ),
  )
}

///|
test "splits a box line into its fill and its title" {
  inspect(
    boxes(),
    content=(
      #|"Aqua Group One" => "Group One" "Aqua" undefined
      #|"Group Two" => "Group Two" "transparent" undefined
      #|"rgb(1, 2, 3)" => - "rgb(1, 2, 3)" undefined
      #|"green Team" => "Team" "green" undefined
      #|"Team green" => "Team green" "transparent" undefined
      #|"rgb(34, 56, 0) Group1" => "Group1" "rgb(34, 56, 0)" undefined
      #|"hsl(120deg 50% 50% / 0.5) H" => "H" "hsl(120deg 50% 50% / 0.5)" undefined
      #|"rgb(1, 2) Bad" => "rgb(1, 2) Bad" "transparent" undefined
      #|"transparent Aqua" => "Aqua" "transparent" undefined
      #|"GrayText Disabled" => "Disabled" "GrayText" undefined
      #|"wrap: Wrapped title" => "Wrapped title" "transparent" true
      #|"red wrap: W" => "W" "red" true
      #|"" => - "transparent" undefined
      #|"   " => - "transparent" undefined
      #|"red" => - "red" undefined
      #|"rgb (1,2,3)x" => "rgb (1,2,3)x" "transparent" undefined
      #|"rgb(1,\n2,3) T" => "T" "rgb(1,\n2,3)" undefined
      #|"hsla(1, 2%, 3%, 1)) x)" => "hsla(1, 2%, 3%, 1)) x)" "transparent" undefined
      #|"nowrap:" => - "transparent" false
      #|"été x" => "été x" "transparent" undefined
      #|"rgba  (1,2,3,1) Q" => "rgba  (1,2,3,1) Q" "transparent" undefined
    ),
  )
}

///|
test "trims leading space from the accessible title" {
  inspect(
    acc_titles(),
    content=(
      #|"title  "
      #|"x"
    ),
  )
}

///|
test "drops the indentation of accessible description lines" {
  inspect(
    acc_descrs(),
    content=(
      #|"a\nb\nc"
      #|"x\ny"
      #|" lead\n"
    ),
  )
}
