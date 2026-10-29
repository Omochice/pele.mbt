///|
fn frame_line(frame : @eventmodeling.EmFrame) -> String {
  let out = StringBuilder()
  out.write_string(
    "\{if frame.reset { "rf" } else { "tf" }} \{frame.name} \{frame.model_entity_type} \{frame.entity_identifier}",
  )
  for source in frame.source_frames {
    out.write_string(" ->> \{source}")
  }
  if frame.data_reference is Some(reference) {
    out.write_string(" [[\{reference}]]")
  }
  if frame.data_type is Some(type_) {
    out.write_string(" `\{type_}`")
  }
  if frame.data_inline_value is Some(inline) {
    out.write_string(" <\{inline}>")
  }
  out.to_string()
}

///|
fn frames_of(source : String) -> String {
  @eventmodeling.read_event_model(source).frames.map(frame_line).join("\n") catch {
    @errors.PeleError(failure) => failure.message
  }
}

///|
fn message_of(source : String) -> String {
  try {
    ignore(@eventmodeling.read_event_model(source))
    "accepted"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()} \{failure.line}:\{failure.column} \{failure.message}"
  }
}

///|
test "frames of every entity type and spelling are read in order" {
  inspect(
    frames_of(
      "eventmodeling\n    tf 01 ui UI\n    timeframe 02 command A\n    rf 03 event B\n    resetframe 04 pcr C\n    tf 05 processor D\n    tf 06 rmo E\n    tf 07 readmodel F\n    tf 08 cmd G\n    tf 09 evt H\n",
    ),
    content=(
      #|tf 01 ui UI
      #|tf 02 command A
      #|rf 03 event B
      #|rf 04 pcr C
      #|tf 05 processor D
      #|tf 06 rmo E
      #|tf 07 readmodel F
      #|tf 08 cmd G
      #|tf 09 evt H
    ),
  )
}

///|
test "a frame keeps its offset in the source" {
  let ast = @eventmodeling.read_event_model(
    "eventmodeling\ntf 01 ui UI\ntf 02 cmd RunAction\ntf 03 evt ActionExecuted",
  )
  inspect(
    ast.frames.map(frame => frame.offset.to_string()).join(","),
    content="14,26,46",
  )
}

///|
test "qualified names join their parts with dots" {
  inspect(
    frames_of("eventmodeling\ntf 01 cmd Inventory.AddItem\ntf 02 evt A.b.c\n"),
    content=(
      #|tf 01 cmd Inventory.AddItem
      #|tf 02 evt A.b.c
    ),
  )
  inspect(
    message_of("eventmodeling\ntf 01 evt A."),
    content="syntax 2:13 Parse error on line 2:\ntf 01 evt A.\n------------^\nExpecting token of type 'EM_ID' but found end of input.",
  )
}

///|
test "sources, data references and inline data follow the name" {
  inspect(
    frames_of(
      "eventmodeling\ntf 04 evt ItemChanged ->> 02 ->> 03\ntf 05 evt B [[Data]]\ntf 06 cmd C `json` { \"a\": 1 }\ntf 07 evt D \"text\"\ntf 08 evt E 'q'\ntf 09 evt F ->> 01 [[D]] { x }\n",
    ),
    content=(
      #|tf 04 evt ItemChanged ->> 02 ->> 03
      #|tf 05 evt B [[Data]]
      #|tf 06 cmd C `json` <{ "a": 1 }>
      #|tf 07 evt D <"text">
      #|tf 08 evt E <'q'>
      #|tf 09 evt F ->> 01 [[D]] <{ x }>
    ),
  )
}

///|
test "inline data runs to the last closing character on its line" {
  inspect(
    frames_of(
      "eventmodeling\ntf 01 evt A { a } b }\ntf 02 evt B { a }{ b }\ntf 03 evt C \"x\" \"y\"\n",
    ),
    content=(
      #|tf 01 evt A <{ a } b }>
      #|tf 02 evt B <{ a }{ b }>
      #|tf 03 evt C <"x" "y">
    ),
  )
}

///|
test "data blocks end at the first closing brace that starts a line and ends it" {
  let ast = @eventmodeling.read_event_model(
    "eventmodeling\ntf 01 evt A\ndata D `json` {\n  x: 1\n  }\n}\nnote 01 `md` {\n  hi\n}\n",
  )
  inspect(
    ast.data_entities
    .map(data => {
      "\{data.name} \{shown(data.data_type)} \{quote(data.data_block_value)}"
    })
    .join("\n"),
    content=(
      #|D "json" "{\n  x: 1\n  }\n}\n"
    ),
  )
  inspect(
    ast.note_entities
    .map(note => {
      "\{note.source_frame} \{shown(note.data_type)} \{quote(note.data_block_value)}"
    })
    .join("\n"),
    content=(
      #|01 "md" "{\n  hi\n}\n"
    ),
  )
}

///|
test "a data block may be empty, or hold a blank line" {
  let empty = @eventmodeling.read_event_model("eventmodeling\ndata D {\n}")
  inspect(quote(empty.data_entities[0].data_block_value), content="\"{\\n}\"")
  let blank = @eventmodeling.read_event_model(
    "eventmodeling\ndata D {\n\n}\ntf 01 evt A [[ D ]]",
  )
  inspect(
    quote(blank.data_entities[0].data_block_value),
    content="\"{\\n\\n}\\n\"",
  )
  inspect(
    frames_of("eventmodeling\ndata D {\n\n}\ntf 01 evt A [[ D ]]"),
    content="tf 01 evt A [[D]]",
  )
}

///|
test "a data block that is not closed on a line of its own is a lexical error" {
  inspect(
    message_of("eventmodeling\ndata D {\na\n}\n}\ntf 01 evt A"),
    content="syntax 5:1 Lexical error on line 5. Unrecognized text.\n}\n^",
  )
  inspect(
    message_of("eventmodeling\nnote 01 {\nx\n}x"),
    content="syntax 2:9 Lexical error on line 2. Unrecognized text.\nnote 01 {\n--------^",
  )
  inspect(
    message_of("eventmodeling\ntf 01 evt A {"),
    content="syntax 2:13 Lexical error on line 2. Unrecognized text.\ntf 01 evt A {\n------------^",
  )
}

///|
test "entities, notes and specifications are collected" {
  let ast = @eventmodeling.read_event_model(
    "eventmodeling\nentity Foo.Bar\nentity Baz\ntf 01 evt A\ngwt 01\n given\n  evt A\n  evt B\n when\n  cmd C\n then\n  evt D\ngwt 02 given evt A then evt B\n",
  )
  inspect(ast.model_entities.join(","), content="Foo.Bar,Baz")
  inspect(
    ast.gwt_entities
    .map(gwt => {
      "\{gwt.source_frame} given=\{gwt.given.join(",")} when=\{gwt.when_.join(",")} then=\{gwt.then_.join(",")}"
    })
    .join("\n"),
    content=(
      #|01 given=A,B when=C then=D
      #|02 given=A when= then=B
    ),
  )
}

///|
test "a specification needs a given and a then" {
  inspect(
    message_of("eventmodeling\ngwt 01 given evt A"),
    content="syntax 2:19 Parse error on line 2:\ngwt 01 given evt A\n------------------^\nExpecting token of type 'then' but found end of input.",
  )
  inspect(
    message_of("eventmodeling\ngwt 01 given evt A when cmd B then"),
    content="syntax 2:35 Parse error on line 2:\ngwt 01 given evt A when cmd B then\n----------------------------------^\nExpecting an entity type but found end of input.",
  )
}

///|
test "a title, an accessible title and description are read after an identifier" {
  let ast = @eventmodeling.read_event_model(
    "eventmodeling title Checkout\ntf 01 ui A accTitle: Acc\ntf 02 cmd B accDescr: Described",
  )
  inspect(shown(ast.title), content="\" title Checkout\"")
  inspect(shown(ast.acc_title), content="\" accTitle: Acc\"")
  inspect(shown(ast.acc_descr), content="\" accDescr: Described\"")
}

///|
test "a name may start with title" {
  let source = "eventmodeling\ntf 01 ui titles\ntf 02 cmd title_x\nentity titles\n"
  inspect(frames_of(source), content="tf 01 ui titles\ntf 02 cmd title_x")
  inspect(
    @eventmodeling.read_event_model(source).model_entities.join(","),
    content="titles",
  )
  inspect(
    message_of("eventmodeling\ntf 01 evt title\n"),
    content="syntax 2:10 Parse error on line 2:\ntf 01 evt title\n---------^\nExpecting token of type 'EM_ID' but found ` title`.",
  )
}

///|
test "a title at the start of a line is an identifier, as in Mermaid" {
  inspect(
    message_of("eventmodeling\ntitle T"),
    content="syntax 2:1 Parse error on line 2:\ntitle T\n^\nExpecting a frame, an entity, a data block, a note, or a specification but found `title`.",
  )
  inspect(
    message_of("eventmodeling\n  title T\n  accTitle: x %% y\n"),
    content="syntax 3:11 Lexical error on line 3. Unrecognized text.\n  accTitle: x %% y\n----------^",
  )
}

///|
test "a braced description that is not closed leaves its brace unreadable" {
  inspect(
    message_of("eventmodeling\ntf 01 evt A\n  accDescr {\n  accDescr: ok"),
    content="syntax 3:12 Lexical error on line 3. Unrecognized text.\n  accDescr {\n-----------^",
  )
}

///|
test "braced descriptions end at the first closing brace" {
  let ast = @eventmodeling.read_event_model(
    "eventmodeling\ntf 01 evt A accDescr {\n a\n }\ntf 02 evt B\n",
  )
  inspect(shown(ast.acc_descr), content="\" accDescr {\\n a\\n }\"")
  inspect(ast.frames.length().to_string(), content="2")
}

///|
test "keywords end where an identifier would go on" {
  inspect(
    message_of("eventmodeling\ntfx 01 evt A"),
    content="syntax 2:1 Parse error on line 2:\ntfx 01 evt A\n^\nExpecting a frame, an entity, a data block, a note, or a specification but found `tfx`.",
  )
  inspect(
    message_of("eventmodeling\ntf 01 events A"),
    content="syntax 2:7 Parse error on line 2:\ntf 01 events A\n------^\nExpecting an entity type but found `events`.",
  )
  inspect(
    message_of("eventmodeling\ntf 01 evt data"),
    content="syntax 2:11 Parse error on line 2:\ntf 01 evt data\n----------^\nExpecting token of type 'EM_ID' but found `data`.",
  )
  inspect(
    message_of("eventmodeling x"),
    content="syntax 1:15 Parse error on line 1:\neventmodeling x\n--------------^\nExpecting a frame, an entity, a data block, a note, or a specification but found `x`.",
  )
}

///|
test "a frame number has at most three digits" {
  inspect(
    message_of("eventmodeling\ntf 1234 evt A"),
    content="syntax 2:7 Parse error on line 2:\ntf 1234 evt A\n------^\nExpecting an entity type but found `4`.",
  )
}

///|
test "a data type is one of the known names between backticks" {
  inspect(
    message_of("eventmodeling\ntf 01 evt A `x` { a }"),
    content="syntax 2:14 Parse error on line 2:\ntf 01 evt A `x` { a }\n-------------^\nExpecting a data type but found `x`.",
  )
  inspect(
    message_of("eventmodeling\ntf 01 evt A `json { a }"),
    content="syntax 2:19 Parse error on line 2:\ntf 01 evt A `json { a }\n------------------^\nExpecting token of type '`' but found `{ a }`.",
  )
}

///|
test "a source needs a frame number" {
  inspect(
    message_of("eventmodeling\ntf 01 evt A\ntf 02 evt B ->>"),
    content="syntax 3:16 Parse error on line 3:\ntf 02 evt B ->>\n---------------^\nExpecting token of type 'EM_FID' but found end of input.",
  )
}

///|
test "the end of input is reported before trailing comments and blank lines" {
  inspect(
    message_of("eventmodeling\ntf 01 cmd\n%% a comment line\n\n"),
    content="syntax 2:10 Parse error on line 2:\ntf 01 cmd\n---------^\nExpecting token of type 'EM_ID' but found end of input.",
  )
}

///|
test "comments are skipped wherever whitespace is" {
  inspect(
    frames_of("eventmodeling\ntf 01 evt A /* c */ // d\n%% e"),
    content="tf 01 evt A",
  )
  inspect(
    message_of("eventmodeling\ntf 01 evt A\n/* unclosed"),
    content="syntax 3:1 Lexical error on line 3. Unrecognized text.\n/* unclosed\n^",
  )
}

///|
test "text no token starts with is a lexical error" {
  inspect(
    message_of("eventmodeling\ntf 01 evt A \u{201c}q\u{201d}"),
    content="syntax 2:13 Lexical error on line 2. Unrecognized text.\ntf 01 evt A \u{201c}q\u{201d}\n------------^",
  )
}
