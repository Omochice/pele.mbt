///|
fn model_of(
  source : String,
  title? : String,
) -> @eventmodeling.EventModelingModel raise @errors.PeleError {
  @eventmodeling.build_event_model(
    @eventmodeling.read_event_model(source),
    title,
  )
}

///|
fn failure_of(source : String) -> String {
  ignore(model_of(source)) catch {
    @errors.PeleError(failure) =>
      return "\{failure.code.to_string()} \{failure.kind.unwrap_or("-")} \{failure.line} \{failure.message}"
  }
  "accepted"
}

///|
fn relations_of(source : String) -> String raise @errors.PeleError {
  model_of(source).relations
  .map(relation => "\{relation.source.id}>\{relation.target.id}")
  .join(",")
}

///|
fn lanes_of(source : String) -> String raise @errors.PeleError {
  model_of(source).lanes.map(lane => "\{lane.index} \{lane.label}").join("\n")
}

///|
const BASIC : String = "eventmodeling\ntf 01 ui CartUI\ntf 02 cmd AddItem\ntf 03 evt ItemAdded\n"

///|
test "a lane per kind of entity, in the order top to bottom, and a box per frame" {
  let model = model_of(BASIC)
  inspect(
    lanes_of(BASIC),
    content=(
      #|0 UI/Automation
      #|100 Command/Read Model
      #|200 Events
    ),
  )
  inspect(
    model.boxes
    .map(box => "\{box.id} \{box.entity} \{box.name} \{box.lane.index}")
    .join("\n"),
    content=(
      #|01 CartUI CartUI 0
      #|02 AddItem AddItem 100
      #|03 ItemAdded ItemAdded 200
    ),
  )
  inspect(relations_of(BASIC), content="01>02,02>03")
}

///|
test "a processor shares the lane of a UI and a read model that of a command" {
  inspect(
    lanes_of(
      "eventmodeling\ntf 01 ui A\ntf 02 cmd B\ntf 03 evt C\ntf 04 rmo D\ntf 05 pcr E\n",
    ),
    content=(
      #|0 UI/Automation
      #|100 Command/Read Model
      #|200 Events
    ),
  )
  let model = model_of(
    "eventmodeling\ntf 01 ui A\ntf 02 command B\ntf 03 event C\ntf 04 readmodel D\ntf 05 processor E\n",
  )
  inspect(
    model.boxes.map(box => box.lane.index.to_string()).join(","),
    content="0,100,200,100,0",
  )
}

///|
test "a relation is inferred from the nearest earlier frame in another lane" {
  inspect(
    relations_of(
      "eventmodeling\ntf 01 evt A\ntf 02 evt B\ntf 03 rmo C\ntf 04 rmo D\n",
    ),
    content="02>03,02>04",
  )
  inspect(
    relations_of("eventmodeling\ntf 01 ui A\ntf 02 ui B\ntf 03 ui C\n"),
    content="",
  )
}

///|
test "a reset frame stops the inferred flow and explicit sources are followed" {
  inspect(
    relations_of(
      "eventmodeling\ntf 01 ui A\ntf 02 cmd B\nrf 03 evt C\ntf 04 pcr D\n",
    ),
    content="01>02,03>04",
  )
  inspect(
    relations_of("eventmodeling\ntf 01 evt A\ntf 02 ui B\nrf 03 rmo C ->> 01\n"),
    content="01>02,01>03",
  )
  inspect(
    relations_of(
      "eventmodeling\nrf 02 evt A\nrf 03 evt B\ntf 01 rmo C ->> 03 ->> 02 ->> 09\n",
    ),
    content="02>01,03>01",
  )
  inspect(
    relations_of("eventmodeling\ntf 01 evt A ->> 02\ntf 02 cmd B\n"),
    content="01>02",
  )
}

///|
test "sources connect in frame order, once each, and a frame may name itself" {
  inspect(
    relations_of(
      "eventmodeling\ntf 01 evt A\ntf 02 ui B\ntf 03 cmd C ->> 01 ->> 02 ->> 01\n",
    ),
    content="01>02,01>03,02>03",
  )
  inspect(relations_of("eventmodeling\ntf 01 evt A ->> 01\n"), content="01>01")
}

///|
test "lanes are told apart by what they are, not by their number" {
  let source = StringBuilder()
  source.write_string("eventmodeling\n")
  for i in 1..<=100 {
    let zeros = if i < 10 { "00" } else if i < 100 { "0" } else { "" }
    source.write_string("tf \{zeros}\{i} ui n\{i}.A\n")
  }
  source.write_string("tf 101 cmd B\n")
  let model = model_of(source.to_string())
  inspect(model.boxes[99].lane.index, content="100")
  inspect(model.boxes[100].lane.index, content="100")
  let last = model.relations[model.relations.length() - 1]
  inspect("\{last.source.id}>\{last.target.id}", content="100>101")
}

///|
test "each namespace has a lane within its group, shared by its frames" {
  let source = "eventmodeling\ntf 01 cmd Cart.Add\ntf 02 evt Cart.Added\ntf 03 cmd Cart.Remove\ntf 04 evt Other.Seen\ntf 05 evt Plain\ntf 06 evt a.b.c\n"
  inspect(
    lanes_of(source),
    content=(
      #|101 C/RM: Cart
      #|200 Events
      #|201 Stream: Cart
      #|202 Stream: Other
    ),
  )
  inspect(
    model_of(source).boxes
    .map(box => "\{box.name} \{box.lane.index} \{shown(box.scope)}")
    .join("\n"),
    content=(
      #|Add 101 "Cart"
      #|Added 201 "Cart"
      #|Remove 101 "Cart"
      #|Seen 202 "Other"
      #|Plain 200 none
      #|a.b.c 200 none
    ),
  )
  inspect(relations_of(source), content="01>02,02>03,03>04,04>05,04>06")
}

///|
test "namespaces number the lanes of each group from its own first number" {
  inspect(
    lanes_of(
      "eventmodeling\ntf 01 ui a.A\ntf 02 ui b.B\ntf 03 ui C\ntf 04 ui d.D\ntf 05 cmd d.D\ntf 06 cmd e.D\ntf 07 evt f.D\ntf 08 rmo g.D\ntf 09 pcr h.D\n",
    ),
    content=(
      #|0 UI/Automation
      #|1 UI/A: a
      #|2 UI/A: b
      #|3 UI/A: d
      #|4 UI/A: h
      #|101 C/RM: d
      #|102 C/RM: e
      #|103 C/RM: g
      #|201 Stream: f
    ),
  )
}

///|
test "data is taken from a block, which wins over inline data, or from the frame" {
  let model = model_of(
    "eventmodeling\ntf 01 cmd A { productId: 7 }\ntf 02 evt B [[Payload]] { ignored: true }\ntf 03 evt C \"{ \"a\": 1 }\"\ntf 04 evt D [[Missing]]\ntf 05 evt E {x}\ndata Payload {\n  description: string\n    nested: true\n}\n",
  )
  inspect(
    model.boxes.map(box => shown(box.data)).join("\n"),
    content=(
      #|"productId: 7"
      #|"description: string\n  nested: true"
      #|"\"a\": 1"
      #|none
      #|"x"
    ),
  )
}

///|
test "a block is read from its braces, without the indentation its lines share" {
  let model = model_of(
    "eventmodeling\ntf 01 evt A [[D]]\ndata D {\n\ta\n  b\n}\ndata D {\n second\n}\n",
  )
  inspect(shown(model.boxes[0].data), content="\"a\\n b\"")
  let spaced = model_of(
    "eventmodeling\ntf 01 evt A [[D]]\ndata D {\n\n   x\n y  \n\n}\n",
  )
  inspect(shown(spaced.boxes[0].data), content="\"  x\\ny\"")
  let blank = model_of("eventmodeling\ntf 01 evt A \"a\"\ntf 02 evt B ''\n")
  inspect(
    blank.boxes.map(box => shown(box.data)).join(","),
    content="\"a\",\"\"",
  )
}

///|
test "the data type of a frame is kept" {
  let model = model_of(
    "eventmodeling\ntf 01 evt A `json` { x }\ntf 02 evt B { y }\n",
  )
  inspect(
    model.boxes.map(box => shown(box.data_type)).join(","),
    content="\"json\",none",
  )
}

///|
test "entities, notes and specifications are collected" {
  let model = model_of(
    "eventmodeling\ntf 01 cmd Update\ntf 02 evt Updated\nentity Updated\nnote 02 `md` {\n  first line\n  second line\n}\ngwt 01\n given\n  evt Updated\n  evt Other\n when\n  cmd Update\n then\n  evt Updated\ngwt 02 given evt A then evt B\n",
  )
  inspect(model.entities.join(","), content="Updated")
  inspect(
    model.notes
    .map(note => "\{note.frame} \{shown(note.data_type)} \{quote(note.text)}")
    .join("\n"),
    content=(
      #|02 "md" "first line\nsecond line"
    ),
  )
  inspect(
    model.specifications
    .map(spec => {
      "\{spec.frame} given=\{spec.given.join(",")} when=\{spec.when_.join(",")} then=\{spec.then_.join(",")}"
    })
    .join("\n"),
    content=(
      #|01 given=Updated,Other when=Update then=Updated
      #|02 given=A when= then=B
    ),
  )
}

///|
test "titles are read the way the grammar allows them, and the front matter title is the fallback" {
  let model = model_of(
    "eventmodeling title Checkout\ntf 01 ui A accTitle: Acc\ntf 02 cmd B accDescr: Described\n",
    title="Front",
  )
  inspect(shown(model.title), content="\"Checkout\"")
  inspect(shown(model.acc_title), content="\"Acc\"")
  inspect(shown(model.acc_descr), content="\"Described\"")
  inspect(
    shown(model_of("eventmodeling\ntf 01 ui A\n", title="Front").title),
    content="\"Front\"",
  )
  inspect(
    shown(model_of("eventmodeling title\ntf 01 ui A\n", title="Front").title),
    content="\"Front\"",
  )
  inspect(shown(model_of("eventmodeling\ntf 01 ui A\n").title), content="none")
}

///|
test "runs of blanks collapse in titles, and braced descriptions lose their indentation" {
  let model = model_of(
    "eventmodeling title   a    b  c\ntf 01 ui A accTitle:   x    y \ntf 02 cmd B accDescr {\n   one\n     two   three\n\n\n   four\n }\n",
  )
  inspect(shown(model.title), content="\"a b c\"")
  inspect(shown(model.acc_title), content="\"x y\"")
  inspect(shown(model.acc_descr), content="\"one\\ntwo three\\nfour\"")
}

///|
test "a frame number may not be used twice, even by a reset frame" {
  inspect(
    failure_of(
      "eventmodeling\n  tf 01 ui UI\n  %% a comment line\n  rf 01 evt Event\n",
    ),
    content="semantic eventmodeling 4 Duplicate event modeling frame ID \"01\" on line 4",
  )
  inspect(
    failure_of(
      "eventmodeling\ntf 01 ui A\ntf 02 cmd B\ntf 03 cmd C\ntf 04 cmd D\ntf 01 evt E\n",
    ),
    content="semantic eventmodeling 6 Duplicate event modeling frame ID \"01\" on line 6",
  )
}

///|
test "a model with no frames is empty" {
  let model = model_of("eventmodeling")
  inspect(model.boxes.length(), content="0")
  inspect(model.lanes.length(), content="0")
  inspect(model.relations.length(), content="0")
}
