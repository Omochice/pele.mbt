// Mermaid's state parser specs are run through `spec_cases`; the expectations were taken from pele's parseState.

///|
/// What parsing `source` into a fresh model gives: its dump, or the error with its position.
/// A model whose graph cannot be built is still dumped, as the parser has finished with it.
fn parsed(source : String) -> String {
  let db = @state.StateDb::new()
  ignore(@state.parse_state(source, db)) catch {
    @errors.PeleError(failure) if failure.code is Semantic =>
      return "ok\n" + model_dump(db)
    @errors.PeleError(failure) =>
      return "error \{failure.code.to_string()} \{failure.line}:\{failure.column}\n\{failure.message}"
  }
  "ok\n" + model_dump(db)
}

///|
test "every source of Mermaid's state parser specs reads as pele reads it" {
  let wrong = []
  for case in spec_cases {
    let (source, expected) = case
    let actual = parsed(source)
    if actual != expected {
      wrong.push(
        "\{source.escape()}: \{actual.escape()} instead of \{expected.escape()}",
      )
    }
  }
  inspect(wrong.join("\n"), content="")
}

///|
test "exposes the parsed model" {
  inspect(
    parsed(
      "stateDiagram-v2\ndirection LR\n [*] --> a\n a --> b : go\n classDef c fill:red\n class a c\n click a \"https://example.com\" \"tip\"\n",
    ),
    content=(
      #|ok
      #|dir "LR"
      #|dir "LR"
      #|relation descr=-
      #|  state "root_start" type="default" descr="" start=true
      #|  state "a" type="default" descr=""
      #|relation descr="go"
      #|  state "a" type="default" descr=""
      #|  state "b" type="default" descr=""
      #|classDef "c" "fill:red"
      #|class "a" "c"
      #|click "a" "\"https://example.com\"" "\"tip\""
      #|state "root_start" id="root_start" type="default" descriptions=[] classes=[] styles=[] textStyles=[]
      #|state "a" id="a" type="default" descriptions=[] classes=["c"] styles=[] textStyles=[]
      #|state "b" id="b" type="default" descriptions=[] classes=[] styles=[] textStyles=[]
      #|rel "root_start" "a" ""
      #|rel "a" "b" "go"
      #|classDef "c" id="c" styles=["fill:red"] textStyles=[]
      #|link "a" "\"https://example.com\"" "\"tip\""
    ),
  )
}

///|
test "rejects a chain of transitions" {
  inspect(
    parsed("stateDiagram-v2\na --> b --> c"),
    content=(
      #|error syntax 2:9
      #|Parse error on line 2:
      #|a --> b --> c
      #|--------^
      #|Expecting '$end', 'NL', 'ID', 'HIDE_EMPTY', 'scale', 'COMPOSIT_STATE', 'STATE_DESCR', 'FORK', 'JOIN', 'CHOICE', 'CONCURRENT', 'note', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'CLICK', 'classDef', 'style', 'class', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'EDGE_STATE', got '-->'
    ),
  )
}

///|
test "rejects classDef default" {
  inspect(
    parsed("stateDiagram-v2\nclassDef default fill:red"),
    content=(
      #|error syntax 2:10
      #|Parse error on line 2:
      #|classDef default fill:red
      #|---------^
      #|Expecting 'CLASSDEF_ID', got 'DEFAULT_CLASSDEF_ID'
    ),
  )
}

///|
test "rejects an unclosed composite" {
  inspect(
    parsed("stateDiagram-v2\nstate A {\n x --> y"),
    content=(
      #|error syntax 3:9
      #|Parse error on line 3:
      #| x --> y
      #|--------^
      #|Expecting 'STRUCT_STOP', 'NL', 'ID', 'HIDE_EMPTY', 'scale', 'COMPOSIT_STATE', 'STATE_DESCR', 'FORK', 'JOIN', 'CHOICE', 'CONCURRENT', 'note', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'CLICK', 'classDef', 'style', 'class', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'EDGE_STATE', got '$end'
    ),
  )
}

///|
test "rejects a closing brace at the root" {
  inspect(
    parsed("stateDiagram-v2\na\n}\n"),
    content=(
      #|ok
      #|dir "TB"
      #|state "a" type="default" descr=""
      #|state "}" type="default" descr=""
      #|state "a" id="a" type="default" descriptions=[] classes=[] styles=[] textStyles=[]
      #|state "}" id="}" type="default" descriptions=[] classes=[] styles=[] textStyles=[]
    ),
  )
}

///|
test "reports scale without width as unrecognized text" {
  inspect(
    parsed("stateDiagram-v2\nscale 350\n a --> b"),
    content=(
      #|error syntax 2:10
      #|Lexical error on line 2. Unrecognized text.
      #|scale 350
      #|---------^
    ),
  )
}

///|
test "rejects text before the keyword" {
  inspect(
    parsed("foo\nstateDiagram-v2\na"),
    content=(
      #|error syntax 1:1
      #|Parse error on line 1:
      #|foo
      #|^
      #|Expecting 'NL', 'SD', got 'ID'
    ),
  )
}

///|
test "accepts blank lines before the keyword" {
  inspect(
    parsed("\n\nstateDiagram\na"),
    content=(
      #|ok
      #|dir "TB"
      #|state "a" type="default" descr=""
      #|state "a" id="a" type="default" descriptions=[] classes=[] styles=[] textStyles=[]
    ),
  )
}

///|
test "accepts the keyword alone" {
  inspect(
    parsed("stateDiagram-v2"),
    content=(
      #|error syntax 1:1
      #|Parse error on line 1:
      #|stateDiagram-v2
      #|^
      #|Expecting 'NL', 'SD', got 'ID'
    ),
  )
}

///|
test "rejects a click with no target" {
  inspect(
    parsed("stateDiagram-v2\nclick a\n"),
    content=(
      #|error syntax 2:8
      #|Parse error on line 2:
      #|click a
      #|-------^
      #|Expecting 'STRING', 'HREF', got 'NL'
    ),
  )
}

///|
test "rejects a click without a line end" {
  inspect(
    parsed("stateDiagram-v2\nclick a \"u\" \"t\""),
    content=(
      #|ok
      #|dir "TB"
      #|click "a" "\"u\"" "\"t\""
      #|link "a" "\"u\"" "\"t\""
    ),
  )
}

///|
test "reads both forms of click" {
  inspect(
    parsed(
      "stateDiagram-v2\nclick a \"u\" \"t\"\nclick b href \"v\"\nclick [*]:::c \"w\" \"x\"\n",
    ),
    content=(
      #|ok
      #|dir "TB"
      #|click "a" "\"u\"" "\"t\""
      #|click "b" "\"v\"" ""
      #|click "[*]" "\"w\"" "\"x\""
      #|link "a" "\"u\"" "\"t\""
      #|link "b" "\"v\"" ""
      #|link "[*]" "\"w\"" "\"x\""
    ),
  )
}

///|
test "rejects a floating note without its alias" {
  inspect(
    parsed("stateDiagram-v2\nnote \"x\"\n"),
    content=(
      #|error syntax 2:9
      #|Parse error on line 2:
      #|note "x"
      #|--------^
      #|Expecting 'AS', got 'NOTE_TEXT'
    ),
  )
}

///|
test "reports a note with no position as unrecognized text" {
  inspect(
    parsed("stateDiagram-v2\nnote over a\n"),
    content=(
      #|error syntax 2:6
      #|Lexical error on line 2. Unrecognized text.
      #|note over a
      #|-----^
    ),
  )
}

///|
test "drops the first character of a note with no space before its colon" {
  inspect(
    parsed("stateDiagram-v2\nnote right of a:text\nnote left of b : text\n"),
    content=(
      #|ok
      #|dir "TB"
      #|state "a" type=- descr=- note="right of":"ext"
      #|state "b" type=- descr=- note="left of":"text"
      #|state "a" id="a" type="default" descriptions=[] classes=[] styles=[] textStyles=[] note="right of":"ext"
      #|state "b" id="b" type="default" descriptions=[] classes=[] styles=[] textStyles=[] note="left of":"text"
    ),
  )
}

///|
test "reads a multiline note" {
  inspect(
    parsed("stateDiagram-v2\nnote left of a\n  first\n  second\nend note\n"),
    content=(
      #|ok
      #|dir "TB"
      #|state "a" type=- descr=- note="left of":"first\n  second"
      #|state "a" id="a" type="default" descriptions=[] classes=[] styles=[] textStyles=[] note="left of":"first\n  second"
    ),
  )
}

///|
test "keeps the text of statements that change nothing" {
  inspect(
    parsed(
      "stateDiagram-v2\nstate lonely\nhide empty description\nscale 350 width\nnote \"floating\" as n\n a --> b",
    ),
    content=(
      #|ok
      #|dir "TB"
      #|text "lonely"
      #|text "hide empty description"
      #|text "scale "
      #|text "note "
      #|relation descr=-
      #|  state "a" type="default" descr=""
      #|  state "b" type="default" descr=""
      #|state "a" id="a" type="default" descriptions=[] classes=[] styles=[] textStyles=[]
      #|state "b" id="b" type="default" descriptions=[] classes=[] styles=[] textStyles=[]
      #|rel "a" "b" ""
    ),
  )
}

///|
test "drops a statement whose text is the grammar's blank line" {
  inspect(
    parsed("stateDiagram-v2\nstate nl\naccTitle: nl\n"),
    content=(
      #|ok
      #|dir "TB"
      #|accTitle "nl"
    ),
  )
}

///|
test "splits an alias with colons into a title and one description" {
  inspect(
    parsed(
      "stateDiagram-v2\nstate \"x\" as a:b:c\nstate \" y \" as d\nstate \"z\" as e {\n}\n",
    ),
    content=(
      #|ok
      #|dir "TB"
      #|state "a" type="default" descr=["x","b"]
      #|state "d" type="default" descr="y"
      #|state "e" type="default" descr="z" {
      #|}
      #|state "a" id="a" type="default" descriptions=["x","b"] classes=[] styles=[] textStyles=[]
      #|state "d" id="d" type="default" descriptions=["y"] classes=[] styles=[] textStyles=[]
      #|state "e" id="e" type="default" descriptions=["z"] classes=[] styles=[] textStyles=[] doc=0
    ),
  )
}

///|
test "reads descriptions with and without the colon's space" {
  inspect(
    parsed("stateDiagram-v2\na : one\na:two\na :  three  \n"),
    content=(
      #|ok
      #|dir "TB"
      #|state "a" type="default" descr="one"
      #|state "a" type="default" descr="two"
      #|state "a" type="default" descr="three"
      #|state "a" id="a" type="default" descriptions=["one","two","three"] classes=[] styles=[] textStyles=[]
    ),
  )
}

///|
test "reads stereotypes" {
  inspect(
    parsed(
      "stateDiagram-v2\nstate f <<fork>>\nstate j [[join]]\nstate c <<choice>>\n",
    ),
    content=(
      #|ok
      #|dir "TB"
      #|state "f" type="fork" descr=-
      #|state "j" type="join" descr=-
      #|state "c" type="choice" descr=-
      #|state "f" id="f" type="fork" descriptions=[] classes=[] styles=[] textStyles=[]
      #|state "j" id="j" type="join" descriptions=[] classes=[] styles=[] textStyles=[]
      #|state "c" id="c" type="choice" descriptions=[] classes=[] styles=[] textStyles=[]
    ),
  )
}

///|
test "reads a stereotype given after the state's first use" {
  inspect(
    parsed("stateDiagram-v2\na --> c\nstate c <<choice>>\n"),
    content=(
      #|ok
      #|dir "TB"
      #|relation descr=-
      #|  state "a" type="default" descr=""
      #|  state "c" type="default" descr=""
      #|state "c" type="choice" descr=-
      #|state "a" id="a" type="default" descriptions=[] classes=[] styles=[] textStyles=[]
      #|state "c" id="c" type="default" descriptions=[] classes=[] styles=[] textStyles=[]
      #|rel "a" "c" ""
    ),
  )
}

///|
test "reads regions inside a composite" {
  inspect(
    parsed(
      "stateDiagram-v2\nstate A {\n [*] --> a1\n --\n [*] --> b1\n --\n [*] --> c1\n }",
    ),
    content=(
      #|ok
      #|dir "TB"
      #|state "A" type="default" descr="" {
      #|  state "divider-id-1" type="divider" descr=- {
      #|    relation descr=-
      #|      state "divider-id-1_start" type="default" descr="" start=true
      #|      state "a1" type="default" descr=""
      #|  }
      #|  state "divider-id-2" type="divider" descr=- {
      #|    relation descr=-
      #|      state "divider-id-2_start" type="default" descr="" start=true
      #|      state "b1" type="default" descr=""
      #|  }
      #|  state "divider-id-3" type="divider" descr=- {
      #|    relation descr=-
      #|      state "divider-id-3_start" type="default" descr="" start=true
      #|      state "c1" type="default" descr=""
      #|  }
      #|}
      #|state "A" id="A" type="default" descriptions=[] classes=[] styles=[] textStyles=[] doc=3
    ),
  )
}

///|
test "reads a composite that ends with a divider" {
  inspect(
    parsed("stateDiagram-v2\nstate A {\n x\n --\n y\n --\n }"),
    content=(
      #|ok
      #|dir "TB"
      #|state "A" type="default" descr="" {
      #|  state "divider-id-1" type="divider" descr=- {
      #|    state "x" type="default" descr=""
      #|  }
      #|  state "divider-id-2" type="divider" descr=- {
      #|    state "y" type="default" descr=""
      #|  }
      #|}
      #|state "A" id="A" type="default" descriptions=[] classes=[] styles=[] textStyles=[] doc=2
    ),
  )
}

///|
test "reads nested composites and their directions" {
  inspect(
    parsed(
      "stateDiagram-v2\nstate A {\n direction LR\n state B {\n direction BT\n x\n }\n}\ndirection RL\n",
    ),
    content=(
      #|ok
      #|dir "RL"
      #|state "A" type="default" descr="" {
      #|  dir "LR"
      #|  state "B" type="default" descr="" {
      #|    dir "BT"
      #|    state "x" type="default" descr=""
      #|  }
      #|}
      #|dir "RL"
      #|state "A" id="A" type="default" descriptions=[] classes=[] styles=[] textStyles=[] doc=2
    ),
  )
}

///|
test "reads accessibility statements" {
  inspect(
    parsed(
      "stateDiagram-v2\naccTitle: The title\naccDescr: The description\naccDescr {\n several\n   lines\n }\n",
    ),
    content=(
      #|ok
      #|dir "TB"
      #|accTitle "The title"
      #|accDescr "several\nlines"
      #|text "The title"
      #|text "The description"
      #|text "several\n   lines"
    ),
  )
}

///|
test "reads class statements and styles" {
  inspect(
    parsed(
      "stateDiagram-v2\nclassDef hot fill:#f00,color:white,font-weight:bold\nclassDef cool stroke:#00f\na:::cool --> b\nclass b hot\nstyle c fill:#0f0,stroke-width:4px\nb --> c\nstate G {\n g1\n}\nclass G cool\nclass x,y hot\n",
    ),
    content=(
      #|ok
      #|dir "TB"
      #|classDef "hot" "fill:#f00,color:white,font-weight:bold"
      #|classDef "cool" "stroke:#00f"
      #|relation descr=-
      #|  state "a" type="default" descr="" classes=["cool"]
      #|  state "b" type="default" descr=""
      #|class "b" "hot"
      #|style "c" "fill:#0f0,stroke-width:4px"
      #|relation descr=-
      #|  state "b" type="default" descr=""
      #|  state "c" type="default" descr=""
      #|state "G" type="default" descr="" {
      #|  state "g1" type="default" descr=""
      #|}
      #|class "G" "cool"
      #|class "x,y" "hot"
      #|state "a" id="a" type="default" descriptions=[] classes=["cool"] styles=[] textStyles=[]
      #|state "b" id="b" type="default" descriptions=[] classes=["hot"] styles=[] textStyles=[]
      #|state "c" id="c" type="default" descriptions=[] classes=[] styles=["fill:#0f0","stroke-width:4px"] textStyles=[]
      #|state "G" id="G" type="default" descriptions=[] classes=["cool"] styles=[] textStyles=[] doc=1
      #|state "x" id="x" type="default" descriptions=[] classes=["hot"] styles=[] textStyles=[]
      #|state "y" id="y" type="default" descriptions=[] classes=["hot"] styles=[] textStyles=[]
      #|rel "a" "b" ""
      #|rel "b" "c" ""
      #|classDef "hot" id="hot" styles=["fill:#f00","color:white","font-weight:bold"] textStyles=["fill:white"]
      #|classDef "cool" id="cool" styles=["stroke:#00f"] textStyles=[]
    ),
  )
}

///|
test "reads class shorthand on start and end states" {
  inspect(
    parsed("stateDiagram-v2\n[*]:::c --> b:::d\nb --> [*]:::e\n"),
    content=(
      #|ok
      #|dir "TB"
      #|relation descr=-
      #|  state "root_start" type="default" descr="" start=true classes=["c"]
      #|  state "b" type="default" descr="" classes=["d"]
      #|relation descr=-
      #|  state "b" type="default" descr=""
      #|  state "root_end" type="default" descr="" start=false classes=["e"]
      #|state "root_start" id="root_start" type="default" descriptions=[] classes=["c"] styles=[] textStyles=[]
      #|state "b" id="b" type="default" descriptions=[] classes=["d"] styles=[] textStyles=[]
      #|state "root_end" id="root_end" type="default" descriptions=[] classes=["e"] styles=[] textStyles=[]
      #|rel "root_start" "b" ""
      #|rel "b" "root_end" ""
    ),
  )
}

///|
test "rejects a class shorthand with no class" {
  inspect(
    parsed("stateDiagram-v2\na::: --> b\n"),
    content=(
      #|error syntax 2:6
      #|Parse error on line 2:
      #|a::: --> b
      #|-----^
      #|Expecting 'ID', got '-->'
    ),
  )
}

///|
test "rejects a state name of two words" {
  inspect(
    parsed("stateDiagram-v2\nstate two words {\n a\n }"),
    content=(
      #|error syntax 2:7
      #|Error: State name must be a single word. Found: "two words {"
    ),
  )
}

///|
test "rejects a composite region divider at the root" {
  inspect(
    parsed("stateDiagram-v2\na\n--\nb\n"),
    content=(
      #|error syntax 3:1
      #|Parse error on line 3:
      #|--
      #|^
      #|Expecting '$end', 'NL', 'ID', 'HIDE_EMPTY', 'scale', 'COMPOSIT_STATE', 'STATE_DESCR', 'FORK', 'JOIN', 'CHOICE', 'CONCURRENT', 'note', 'acc_title', 'acc_descr', 'acc_descr_multiline_value', 'CLICK', 'classDef', 'style', 'class', 'direction_tb', 'direction_bt', 'direction_rl', 'direction_lr', 'EDGE_STATE', got 'INVALID'
    ),
  )
}

///|
test "reads a state with no description and a self transition" {
  inspect(
    parsed("stateDiagram-v2\na --> a\na --> a : again\n"),
    content=(
      #|ok
      #|dir "TB"
      #|relation descr=-
      #|  state "a" type="default" descr=""
      #|  state "a" type="default" descr=""
      #|relation descr="again"
      #|  state "a" type="default" descr=""
      #|  state "a" type="default" descr=""
      #|state "a" id="a" type="default" descriptions=[] classes=[] styles=[] textStyles=[]
      #|rel "a" "a" ""
      #|rel "a" "a" "again"
    ),
  )
}

///|
test "rejects an empty style statement" {
  inspect(
    parsed("stateDiagram-v2\nstyle -a\n"),
    content=(
      #|error syntax 2:7
      #|Lexical error on line 2. Unrecognized text.
      #|style -a
      #|------^
    ),
  )
}

///|
test "reads names that are object keys in JavaScript as plain names" {
  inspect(
    parsed(
      "stateDiagram-v2\n__proto__ --> constructor\nconstructor --> toString\nclass __proto__ constructor\nclassDef constructor fill:red\nstate \"x\" as hasOwnProperty:polluted\n",
    ),
    content=(
      #|ok
      #|dir "TB"
      #|relation descr=-
      #|  state "__proto__" type="default" descr=""
      #|  state "constructor" type="default" descr=""
      #|relation descr=-
      #|  state "constructor" type="default" descr=""
      #|  state "toString" type="default" descr=""
      #|class "__proto__" "constructor"
      #|classDef "constructor" "fill:red"
      #|state "hasOwnProperty" type="default" descr=["x","polluted"]
      #|state "__proto__" id="__proto__" type="default" descriptions=[] classes=["constructor"] styles=[] textStyles=[]
      #|state "constructor" id="constructor" type="default" descriptions=[] classes=[] styles=[] textStyles=[]
      #|state "toString" id="toString" type="default" descriptions=[] classes=[] styles=[] textStyles=[]
      #|state "hasOwnProperty" id="hasOwnProperty" type="default" descriptions=["x","polluted"] classes=[] styles=[] textStyles=[]
      #|rel "__proto__" "constructor" ""
      #|rel "constructor" "toString" ""
      #|classDef "constructor" id="constructor" styles=["fill:red"] textStyles=[]
    ),
  )
}
