///|
fn label(value : String?) -> String {
  match value {
    Some(text) => text.escape()
    None => "-"
  }
}

///|
fn dump(source : String) -> String {
  let db = @venn.parse_venn(source) catch {
    @errors.PeleError(failure) =>
      return "\{failure.code.to_string()}: \{failure.message}"
  }
  let subsets = db.subsets.map(s => {
    "\{s.sets.join("|")}:\{s.size}:\{label(s.label)}"
  })
  let texts = db.text_nodes.map(t => {
    "\{t.sets.join("|")}/\{t.id}:\{label(t.label)}"
  })
  let styles = db.styles.map(s => {
    let declared = []
    for key, value in s.styles {
      declared.push("\{key}=\{value}")
    }
    "\{s.targets.join("|")}{\{declared.join(";")}}"
  })
  "title=\{label(db.title)} subsets=[\{subsets.join(", ")}] texts=[\{texts.join(", ")}] styles=[\{styles.join(", ")}]"
}

///|
test "sets get 10 and an overlap 10 over the square of its sets" {
  inspect(
    dump(
      "venn-beta\n          title foo bar\n          set A\n          set B\n          union A,B\n      ",
    ),
    content="title=\"foo bar\" subsets=[A:10:-, B:10:-, A|B:2.5:-] texts=[] styles=[]",
  )
  inspect(
    dump("venn-beta\nset A\nset B\nset C\nunion A,B,C"),
    content="title=- subsets=[A:10:-, B:10:-, C:10:-, A|B|C:1.1111111111111112:-] texts=[] styles=[]",
  )
}

///|
test "labels are read in brackets, quoted or not" {
  inspect(
    dump("venn-beta\nset A[\"Alpha\"]\nset B[Beta]\nunion A,B[\"AB\"]"),
    content="title=- subsets=[A:10:\"Alpha\", B:10:\"Beta\", A|B:2.5:\"AB\"] texts=[] styles=[]",
  )
}

///|
test "sizes follow a colon" {
  inspect(
    dump(
      "venn-beta\nset A[\"Alpha\"]:20\nset B:12\nset C:30\nunion A,B[\"AB\"]:5.3\nunion C,A,B:1",
    ),
    content="title=- subsets=[A:20:\"Alpha\", B:12:-, C:30:-, A|B:5.3:\"AB\", A|B|C:1:-] texts=[] styles=[]",
  )
  inspect(
    dump("venn-beta\nset A:+.5\nset B:-5"),
    content="title=- subsets=[A:0.5:-, B:-5:-] texts=[] styles=[]",
  )
}

///|
test "indented texts belong to the set before them" {
  inspect(
    dump(
      "venn-beta\n          set A[\"Frontend\"]\n            text A1\n            text A2\n          set B[\"Backend\"]\n            text B1\n          union A,B[\"APIs\"]\n      ",
    ),
    content="title=- subsets=[A:10:\"Frontend\", B:10:\"Backend\", A|B:2.5:\"APIs\"] texts=[A/A1:-, A/A2:-, B/B1:-] styles=[]",
  )
}

///|
test "a text statement names its sets" {
  inspect(
    dump(
      "venn-beta\nset A\nset B\ntext A,B t1[\"one\"]\ntext B \"two\"\ntext A 3",
    ),
    content="title=- subsets=[A:10:-, B:10:-] texts=[A|B/t1:\"one\", B/two:-, A/3:-] styles=[]",
  )
}

///|
test "texts with labels, including a comma" {
  inspect(
    dump(
      "venn-beta\n set A\n   text A1[\"foo bar\"]\n set B\n   text B1[\"hello, world\"]\n union A,B\n   text AB1[\"shared note\"]",
    ),
    content="title=- subsets=[A:10:-, B:10:-, A|B:2.5:-] texts=[A/A1:\"foo bar\", B/B1:\"hello, world\", A|B/AB1:\"shared note\"] styles=[]",
  )
}

///|
test "styles list their declarations" {
  inspect(
    dump(
      "venn-beta\nset A\nset B\nunion A,B\nstyle A fill:#ff6b6b, color:#333\nstyle A,B color:red\nstyle B fill:rgb(255, 0, 128)\nstyle A fill:rgba(255, 0, 128, 0.5)",
    ),
    content="title=- subsets=[A:10:-, B:10:-, A|B:2.5:-] texts=[] styles=[A{fill=#ff6b6b;color=#333}, A|B{color=red}, B{fill=rgb(255, 0, 128)}, A{fill=rgba(255, 0, 128, 0.5)}]",
  )
  inspect(
    dump(
      "venn-beta\nset A\nstyle A stroke:\"dashed red\", stroke-width:2 px, x:#fff 5 a",
    ),
    content="title=- subsets=[A:10:-] texts=[] styles=[A{stroke=dashed red;stroke-width=2 px;x=#fff 5 a}]",
  )
}

///|
test "quoted identifiers lose their quotes and are sorted" {
  inspect(
    dump("venn-beta\nset \"Foo Bar\"\nset Buz\nunion \"Foo Bar\",Buz"),
    content="title=- subsets=[Foo Bar:10:-, Buz:10:-, Buz|Foo Bar:2.5:-] texts=[] styles=[]",
  )
}

///|
test "keywords ignore case and comments are skipped" {
  inspect(
    dump(
      "\n\n  VENN-BETA\n%% comment\n  SET A %% trailing\n  Set B:5\n\n   \n  UNION A,B\n    TEXT t\nSTYLE A FILL:Red\nTITLE Shout",
    ),
    content="title=\"Shout\" subsets=[A:10:-, B:5:-, A|B:2.5:-] texts=[A|B/t:-] styles=[A{FILL=Red}]",
  )
}

///|
test "the character before a comment is kept" {
  inspect(
    dump("venn-beta\nset A%% note\nset B:5%% note\nunion A,B%% note"),
    content=(
      #|title=- subsets=[A:10:-, B:5:-, A|B:2.5:-] texts=[] styles=[]
    ),
  )
}

///|
test "a text after an unindented statement does not continue the set" {
  inspect(
    dump("venn-beta\nset A\ntext A x\n  text y"),
    content="syntax: Parse error on line 4:\n  text y\n--------^\nExpecting 'NUMERIC', 'IDENTIFIER', 'STRING', got 'EOF'",
  )
}

///|
test "a set takes a single identifier" {
  inspect(
    dump("venn-beta\n        set A,B\n    "),
    content="syntax: Parse error on line 2:\n        set A,B\n-------------^\nExpecting 'EOF', 'NEWLINE', 'TITLE', 'SET', 'UNION', 'TEXT', 'INDENT_TEXT', 'STYLE', got 'COMMA'",
  )
}

///|
test "a union needs several known sets" {
  inspect(
    dump("venn-beta\n        union A\n    "),
    content="semantic: union requires multiple identifiers",
  )
  inspect(
    dump("venn-beta\n        set Foo\n        union Foo,Buz\n    "),
    content="semantic: unknown set identifier: Buz",
  )
}

///|
test "an indented text with no set before it is a plain keyword" {
  inspect(
    dump("venn-beta\n  text x"),
    content="syntax: Parse error on line 2:\n  text x\n--------^\nExpecting 'NUMERIC', 'IDENTIFIER', 'STRING', got 'EOF'",
  )
}

///|
test "a lexical error is reported as one" {
  inspect(
    dump("venn-beta\nset A[unclosed"),
    content="syntax: Lexical error on line 2. Unrecognized text.\nset A[unclosed\n-----^",
  )
}
