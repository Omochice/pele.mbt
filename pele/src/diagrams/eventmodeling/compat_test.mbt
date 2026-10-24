///|
const COMPLEX : String = "eventmodeling\ntf 01 cmd UpdateCartCommand\ntf 02 evt CartUpdatedEvent ->> 01 `jsobj`{ a: b }\ntf 03 rmo CartItemsReadModel ->> 02 [[CartItemsReadModel03]]\ntf 04 evt ProductDescriptionUpdatedEvent ->> 01 `jsobj`{ a: { c: d } }\ntf 05 evt ProductTitleUpdatedEvent ->> 01 { \"a\": { \"c\": true } }\ntf 06 evt ProductCountIncrementedEvent ->> 01 `json`\" { \"a\": { \"c\": true } } \"\n\ndata CartItemsReadModel03 {\n  { a: b }\n}\n\ndata NotAssignedData02 `jsobj` {\n  { a: {\n    d: true\n  }}\n}\n\ndata AnotherNotAssignedData06 {\n  a: 'abc'\n}\n\nnote 02 `md` {\n    # head 1\n    this is markdown note\n}\n\nnote 05 {\n  This is whatever <b>you</b> want\n  On multiple lines\n}\n\ngwt 01\n  given\n    evt CartUpdatedEvent\n    evt CartUpdatedEvent\n  when\n    evt ProductDescriptionUpdatedEvent\n    evt ProductTitleUpdatedEvent\n  then\n    evt ProductTitleUpdatedEvent\n\n\ngwt 03\n  given\n    evt CartUpdatedEvent\n    evt ProductTitleUpdatedEvent\n  then\n    evt ProductTitleUpdatedEvent\n    evt CartUpdatedEvent\n"

///|
test "a complex model keeps every frame, data block, note and specification" {
  let ast = @eventmodeling.read_event_model(COMPLEX)
  inspect(ast.frames.length(), content="6")
  inspect(ast.data_entities.length(), content="3")
  inspect(ast.note_entities.length(), content="2")
  inspect(ast.gwt_entities.length(), content="2")
}

///|
test "a frame may be written with the long keywords" {
  let ast = @eventmodeling.read_event_model(
    "eventmodeling\ntimeframe 01 event Start\n\n  ",
  )
  inspect(ast.frames.length(), content="1")
  inspect(ast.frames[0].name, content="01")
  inspect(ast.frames[0].model_entity_type, content="event")
  inspect(ast.frames[0].entity_identifier, content="Start")
}

///|
test "qualified names keep their dots" {
  let ast = @eventmodeling.read_event_model(
    "eventmodeling\n\ntimeframe 02 ui UI\ntf 01 evt Product.PriceChanged\ntf 03 evt Cart.ItemAdded\n\n  ",
  )
  inspect(ast.frames.length(), content="3")
  inspect(ast.frames[1].name, content="01")
  inspect(ast.frames[1].model_entity_type, content="evt")
  inspect(ast.frames[1].entity_identifier, content="Product.PriceChanged")
}

///|
test "both kinds of frames are read, the reset one marked" {
  let ast = @eventmodeling.read_event_model(
    "eventmodeling\n\ntf 02 ui UI\nresetframe 01 evt Product.PriceChanged\ntf 03 evt Cart.ItemAdded\n\n  ",
  )
  inspect(ast.frames.length(), content="3")
  inspect(ast.frames[0].reset, content="false")
  inspect(ast.frames[1].reset, content="true")
  inspect(ast.frames[1].entity_identifier, content="Product.PriceChanged")
}

///|
test "a frame may name several sources and carry data" {
  let ast = @eventmodeling.read_event_model(
    "eventmodeling\ntf 01 evt Start\ntf 02 evt End\nrf 03 readmodel ReadModel01 ->> 01 ->> 02 { a: true }\nrf 04 rmo ReadModel02 ->> 01 ->> 02\n  ",
  )
  inspect(ast.frames.length(), content="4")
  inspect(ast.frames[2].name, content="03")
  inspect(ast.frames[2].model_entity_type, content="readmodel")
  inspect(ast.frames[2].source_frames.length(), content="2")
  inspect(ast.frames[3].model_entity_type, content="rmo")
  inspect(ast.frames[3].source_frames.length(), content="2")
}

///|
test "every entity type and its long spelling is accepted" {
  let ast = @eventmodeling.read_event_model(
    "eventmodeling\ntf 01 ui UI\ntf 02 ui UI2\ntf 03 cmd Command\ntf 04 command Command2\ntf 05 evt Event\ntf 06 event Event2\ntf 07 pcr Processor\ntf 08 processor Processor2\ntf 09 rmo ReadModel\ntf 10 readmodel ReadModel2",
  )
  inspect(ast.frames.length(), content="10")
}

///|
test "a frame number reused by a reset frame is rejected, counting the comment lines" {
  for
    source in [
      "eventmodeling\n        tf 01 ui UI\n        tf 02 cmd Command\n        rf 01 evt Event",
      "eventmodeling\n        tf 01 ui UI\n        %% This comment occupies a source line.\n        rf 01 evt Event",
    ] {
    try {
      ignore(
        @eventmodeling.build_event_model(
          @eventmodeling.read_event_model(source),
          None,
        ),
      )
      fail("accepted")
    } catch {
      @errors.PeleError(failure) =>
        inspect(
          failure.message,
          content="Duplicate event modeling frame ID \"01\" on line 4",
        )
      error => fail("\{error}")
    }
  }
}

///|
test "explicit sources on a reset frame are kept and the previous frame is not inferred" {
  let model = @eventmodeling.build_event_model(
    @eventmodeling.read_event_model(
      "eventmodeling\n      tf 01 ui UI\n      tf 02 cmd Command\n      tf 03 evt Event\n      rf 04 rmo ReadModel ->> 03\n      rf 05 ui OtherUI",
    ),
    None,
  )
  let relations = model.relations.map(r => "\{r.source.id}>\{r.target.id}")
  inspect(relations.contains("03>04"), content="true")
  inspect(relations.contains("04>05"), content="false")
}
