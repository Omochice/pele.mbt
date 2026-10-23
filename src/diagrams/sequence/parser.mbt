///|
const SIGNAL_TOKENS : String = "'SOLID_OPEN_ARROW', 'DOTTED_OPEN_ARROW', 'SOLID_ARROW', 'DOTTED_ARROW', 'SOLID_CROSS', 'DOTTED_CROSS', 'SOLID_POINT', 'DOTTED_POINT'"

///|
/// The message kind an arrow token stands for, or -1.
fn signal_kind(kind : Tok) -> Int32 {
  match kind {
    SolidOpenArrow => SOLID_OPEN
    DottedOpenArrow => DOTTED_OPEN
    SolidArrow => SOLID
    DottedArrow => DOTTED
    BidirectionalSolidArrow => BIDIRECTIONAL_SOLID
    BidirectionalDottedArrow => BIDIRECTIONAL_DOTTED
    SolidCross => SOLID_CROSS
    DottedCross => DOTTED_CROSS
    SolidPoint => SOLID_POINT
    DottedPoint => DOTTED_POINT
    SolidArrowTop => SOLID_TOP
    SolidArrowBottom => SOLID_BOTTOM
    StickArrowTop => STICK_TOP
    StickArrowBottom => STICK_BOTTOM
    SolidArrowTopDotted => SOLID_TOP_DOTTED
    SolidArrowBottomDotted => SOLID_BOTTOM_DOTTED
    StickArrowTopDotted => STICK_TOP_DOTTED
    StickArrowBottomDotted => STICK_BOTTOM_DOTTED
    SolidArrowTopReverse => SOLID_ARROW_TOP_REVERSE
    SolidArrowBottomReverse => SOLID_ARROW_BOTTOM_REVERSE
    StickArrowTopReverse => STICK_ARROW_TOP_REVERSE
    StickArrowBottomReverse => STICK_ARROW_BOTTOM_REVERSE
    SolidArrowTopReverseDotted => SOLID_ARROW_TOP_REVERSE_DOTTED
    SolidArrowBottomReverseDotted => SOLID_ARROW_BOTTOM_REVERSE_DOTTED
    StickArrowTopReverseDotted => STICK_ARROW_TOP_REVERSE_DOTTED
    StickArrowBottomReverseDotted => STICK_ARROW_BOTTOM_REVERSE_DOTTED
    _ => -1
  }
}

///|
priv enum BlockKind {
  Top
  InBox
  InLoop
  InRect
  InOpt
  InBreak
  InAlt
  InPar(Int32)
  InCritical
}

///|
/// A participant statement before `create` may turn it into a creation.
priv struct Declared {
  actor : String
  draw : String?
  description : SeqText?
  config : String?
  destroy : Bool
}

///|
/// Parses a sequence diagram into `db`, as Mermaid's grammar does.
/// Raises `PeleError` for text the grammar or the model rejects.
/// The grammar nests the statements of a block in lists the model walks in order.
/// A block's start statement depends only on its own line, so the statements are kept in one list in that order instead.
pub fn parse_sequence(src : String, db : SeqDb) -> Unit raise @errors.PeleError {
  let { types, texts, starts, } = tokenize(src)
  let statements : Array[SeqStatement] = []
  let mut i = 0
  fn fail(expected : String) -> @errors.PeleError {
    let kind = types[i]
    if kind is Error {
      return @errors.syntax_error("sequence", src, starts[i], "", lexical=true)
    }
    @errors.syntax_error(
      "sequence",
      src,
      starts[i],
      "Expecting \{expected}, got '\{kind.name()}'",
    )
  }

  fn expect(kind : Tok) -> String raise @errors.PeleError {
    if types[i].name() != kind.name() || types[i] is Error {
      raise fail("'\{kind.name()}'")
    }
    let text = texts[i]
    i += 1
    text
  }

  fn actor() -> String raise @errors.PeleError {
    if !(types[i] is (Actor | Link)) {
      raise fail("'ACTOR'")
    }
    let text = texts[i]
    i += 1
    text
  }

  fn mention(name : String) -> SeqStatement {
    AddParticipant(actor=name, draw=None, description=None, config=None)
  }

  fn text2() -> SeqText raise @errors.PeleError {
    db.parse_message(@util.slice(@util.trim(expect(Txt)), 1))
  }

  fn participant() -> Declared raise @errors.PeleError {
    let kind = types[i]
    i += 1
    if kind is Destroy {
      let name = actor()
      expect(Newline) |> ignore
      return {
        actor: name,
        draw: None,
        description: None,
        config: None,
        destroy: true,
      }
    }
    let name = actor()
    let mut config = None
    if types[i] is ConfigStart && types[i - 1] is Actor {
      i += 1
      let content = expect(ConfigContent)
      expect(ConfigEnd) |> ignore
      config = Some(@util.trim(content))
    }
    let draw = if kind is Participant { "participant" } else { "actor" }
    let mut description = None
    if types[i] is As {
      i += 1
      let aliased = expect(RestOfLine)
      expect(Newline) |> ignore
      description = Some(db.parse_message(aliased))
    } else if types[i] is Newline {
      i += 1
    } else {
      raise fail("'AS', 'NEWLINE'")
    }
    { actor: name, draw: Some(draw), description, config, destroy: false, }
  }

  fn declared(node : Declared) -> SeqStatement {
    if node.destroy {
      DestroyParticipant(node.actor)
    } else {
      AddParticipant(
        actor=node.actor,
        draw=node.draw,
        description=node.description,
        config=node.config,
      )
    }
  }

  fn signal(from : String) -> Unit raise @errors.PeleError {
    let mut central_from = false
    if types[i] is Central {
      central_from = true
      i += 1
    }
    let signal_type = signal_kind(types[i])
    if signal_type < 0 {
      raise fail(SIGNAL_TOKENS)
    }
    i += 1
    let mark = types[i]
    if mark is Central || (!central_from && mark is (Plus | Minus)) {
      i += 1
    }
    let to = actor()
    let msg = text2()
    statements.push(mention(from))
    statements.push(mention(to))
    if central_from {
      let dual = mark is Central
      statements.push(
        AddMessage(
          from~,
          to~,
          signal_type~,
          msg~,
          activate=dual,
          central_connection=Some(
            if dual {
              CENTRAL_CONNECTION_DUAL
            } else {
              CENTRAL_CONNECTION_REVERSE
            },
          ),
        ),
      )
      if dual {
        statements.push(CentralConnectionStart(to))
      }
      statements.push(CentralConnectionReverseStart(from))
    } else if mark is Plus {
      statements.push(
        AddMessage(
          from~,
          to~,
          signal_type~,
          msg~,
          activate=true,
          central_connection=None,
        ),
      )
      statements.push(ActiveStart(to))
    } else if mark is Minus {
      statements.push(
        AddMessage(
          from~,
          to~,
          signal_type~,
          msg~,
          activate=false,
          central_connection=None,
        ),
      )
      statements.push(ActiveEnd(from))
    } else if mark is Central {
      statements.push(
        AddMessage(
          from~,
          to~,
          signal_type~,
          msg~,
          activate=true,
          central_connection=Some(CENTRAL_CONNECTION),
        ),
      )
      statements.push(CentralConnectionStart(to))
    } else {
      statements.push(
        AddMessage(
          from~,
          to~,
          signal_type~,
          msg~,
          activate=false,
          central_connection=None,
        ),
      )
    }
  }

  fn menu(
    make : (String, SeqText) -> SeqStatement,
  ) -> Unit raise @errors.PeleError {
    i += 1
    let who = actor()
    let text = text2()
    statements.push(mention(who))
    statements.push(make(who, text))
  }

  fn note() -> Unit raise @errors.PeleError {
    i += 1
    let kind = types[i]
    if kind is Over {
      i += 1
      let first = actor()
      let mut ids = [first, first]
      let mut second = None
      if types[i] is Comma {
        i += 1
        let other = actor()
        second = Some(other)
        ids = [first, other]
      }
      let text = text2()
      statements.push(mention(first))
      if second is Some(other) {
        statements.push(mention(other))
      }
      statements.push(AddNote(actors=ids, placement=OVER, text~))
      return
    }
    if !(kind is (LeftOf | RightOf)) {
      raise fail("'over', 'left_of', 'right_of'")
    }
    i += 1
    let who = actor()
    let placement = if kind is LeftOf { LEFTOF } else { RIGHTOF }
    let text = text2()
    statements.push(mention(who))
    statements.push(AddNote(actors=[who], placement~, text~))
  }

  fn autonumber() -> Unit raise @errors.PeleError {
    i += 1
    let mut start = None
    let mut step = None
    let mut visible = true
    if types[i] is Num {
      start = Some(@util.to_number(texts[i]))
      i += 1
      if types[i] is Num {
        step = Some(@util.to_number(texts[i]))
        i += 1
      } else {
        step = Some(1.0)
      }
    } else if types[i] is Off {
      i += 1
      visible = false
    }
    if !(types[i] is Newline) {
      raise fail("'NEWLINE', 'NUM', 'off'")
    }
    i += 1
    statements.push(SequenceIndex(start~, step~, visible~))
  }

  fn close(kind : BlockKind) -> Unit {
    let end = match kind {
      InBox => BoxEnd
      InLoop => BlockEnd(LOOP_END)
      InRect => BlockEnd(RECT_END)
      InOpt => BlockEnd(OPT_END)
      InBreak => BlockEnd(BREAK_END)
      InAlt => BlockEnd(ALT_END)
      InPar(_) => BlockEnd(PAR_END)
      InCritical | Top => BlockEnd(CRITICAL_END)
    }
    statements.push(end)
  }

  while types[i] is Newline {
    i += 1
  }
  expect(Sd) |> ignore
  let stack : Array[BlockKind] = []
  let mut frame : BlockKind = Top
  while true {
    let kind = types[i]
    if frame is InBox {
      match kind {
        Participant | ParticipantActor | Destroy =>
          statements.push(declared(participant()))
        Newline => i += 1
        EndKw => {
          i += 1
          close(frame)
          frame = stack.unsafe_pop()
        }
        _ =>
          raise fail(
            "'end', 'NEWLINE', 'participant', 'participant_actor', 'destroy'",
          )
      }
      continue
    }
    match kind {
      Newline | Invalid => i += 1
      Participant | ParticipantActor | Destroy =>
        statements.push(declared(participant()))
      Create => {
        i += 1
        if !(types[i] is (Participant | ParticipantActor | Destroy)) {
          raise fail("'participant', 'participant_actor', 'destroy'")
        }
        let node = participant()
        statements.push(
          CreateParticipant(
            actor=node.actor,
            draw=node.draw,
            description=node.description,
            config=node.config,
          ),
        )
      }
      Actor => {
        signal(actor())
        expect(Newline) |> ignore
      }
      Link => {
        if types[i + 1] is (Actor | Link) {
          menu((who, text) => AddALink(who, text))
        } else {
          signal(actor())
        }
        expect(Newline) |> ignore
      }
      Links => {
        menu((who, text) => AddLinks(who, text))
        expect(Newline) |> ignore
      }
      Properties => {
        menu((who, text) => AddProperties(who, text))
        expect(Newline) |> ignore
      }
      Details => {
        menu((who, text) => AddDetails(who, text))
        expect(Newline) |> ignore
      }
      Note => {
        note()
        expect(Newline) |> ignore
      }
      Autonumber => autonumber()
      Activate | Deactivate => {
        i += 1
        let who = actor()
        expect(Newline) |> ignore
        statements.push(
          if kind is Activate {
            ActiveStart(who)
          } else {
            ActiveEnd(who)
          },
        )
      }
      Title | LegacyTitle => {
        let skip = if kind is Title { 6 } else { 7 }
        db.set_diagram_title(@util.slice(texts[i], skip))
        i += 1
      }
      AccTitle => {
        i += 1
        db.set_acc_title(@util.trim(expect(AccTitleValue)))
      }
      AccDescr => {
        i += 1
        db.set_acc_description(@util.trim(expect(AccDescrValue)))
      }
      AccDescrMultilineValue => {
        db.set_acc_description(@util.trim(texts[i]))
        i += 1
      }
      Loop | Rect | Opt | Break | Alt | Par | ParOver | Critical | Box => {
        i += 1
        let text = expect(RestOfLine)
        stack.push(frame)
        let block : BlockKind = match kind {
          Loop => InLoop
          Rect => InRect
          Opt => InOpt
          Break => InBreak
          Alt => InAlt
          Par => InPar(PAR_START)
          ParOver => InPar(PAR_OVER_START)
          Critical => InCritical
          _ => InBox
        }
        frame = block
        let message = db.parse_message(text)
        statements.push(
          match block {
            InBox => BoxStart(db.parse_box_data(text))
            InLoop => BlockStart(LOOP_START, message)
            InRect => BlockStart(RECT_START, message)
            InOpt => BlockStart(OPT_START, message)
            InBreak => BlockStart(BREAK_START, message)
            InAlt => BlockStart(ALT_START, message)
            InPar(start) => BlockStart(start, message)
            InCritical | Top => BlockStart(CRITICAL_START, message)
          },
        )
      }
      Else | And | Option => {
        let fits = match (kind, frame) {
          (Else, InAlt) | (And, InPar(_)) | (Option, InCritical) => true
          _ => false
        }
        if !fits {
          raise fail("'end'")
        }
        i += 1
        let text = expect(RestOfLine)
        let divider = match kind {
          Else => ALT_ELSE
          And => PAR_AND
          _ => CRITICAL_OPTION
        }
        statements.push(BlockStart(divider, db.parse_message(text)))
      }
      EndKw => {
        if frame is Top {
          raise fail("'NEWLINE', 'EOF'")
        }
        i += 1
        close(frame)
        frame = stack.unsafe_pop()
      }
      End => {
        if !(frame is Top) {
          raise fail("'end'")
        }
        db.apply(statements)
        return
      }
      _ => raise fail("'NEWLINE', 'ACTOR', 'participant', 'note', 'end'")
    }
  }
}
