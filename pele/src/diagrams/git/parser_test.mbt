///|
fn quoted(value : String?) -> String {
  match value {
    Some(text) => text.escape()
    None => "-"
  }
}

///|
fn type_name(value : @git.CommitTypeName?) -> String {
  match value {
    Some(Normal) => "NORMAL"
    Some(Reverse) => "REVERSE"
    Some(Highlight) => "HIGHLIGHT"
    None => "-"
  }
}

///|
fn tag_list(tags : Array[String]) -> String {
  "[" + tags.map(tag => tag.escape()).join(",") + "]"
}

///|
fn statement(statement : @git.StatementAst) -> String {
  match statement {
    Commit(c) =>
      "commit id=\{quoted(c.id)} msg=\{quoted(c.message)} tags=\{tag_list(c.tags)} type=\{type_name(c.commit_type)}"
    Branch(b) =>
      "branch \{b.name.escape()} order=\{b.order.map(order => order.to_string()).unwrap_or("-")}"
    Merge(m) =>
      "merge \{m.branch.escape()} id=\{quoted(m.id)} tags=\{tag_list(m.tags)} type=\{type_name(m.commit_type)}"
    Checkout(c) => "checkout \{c.branch.escape()}"
    CherryPicking(c) =>
      "cherry-pick id=\{quoted(c.id)} tags=\{tag_list(c.tags)} parent=\{quoted(c.parent)}"
  }
}

///|
fn direction(dir : @git.GitDirection?) -> String {
  match dir {
    Some(LR) => "LR"
    Some(TB) => "TB"
    Some(BT) => "BT"
    None => "-"
  }
}

///|
fn ast(source : String) -> String {
  let ast = @git.parse_git(source) catch {
    @errors.PeleError(failure) => return failure.message
  }
  let header = "dir=\{direction(ast.dir)} title=\{quoted(ast.title)} accTitle=\{quoted(ast.acc_title)} accDescr=\{quoted(ast.acc_descr)}"
  [header, ..ast.statements.map(statement)].join("\n")
}

///|
test "a commit takes its clauses in any order, the last of a kind winning but for tags" {
  inspect(
    ast(
      "gitGraph\n  commit id:\"1\" msg:\"Fix bug\" tag:\"v1.2\" type:NORMAL\n",
    ),
    content=(
      #|dir=- title=- accTitle=- accDescr=-
      #|commit id="1" msg="Fix bug" tags=["v1.2"] type=NORMAL
    ),
  )
  inspect(
    ast(
      "gitGraph\n commit \"m\" \"n\" id:\"a\" id:\"b\" tag:\"t\" tag:\"u\" type:HIGHLIGHT\n",
    ),
    content=(
      #|dir=- title=- accTitle=- accDescr=-
      #|commit id="b" msg="n" tags=["t","u"] type=HIGHLIGHT
    ),
  )
}

///|
test "a commit with no clause has no id, message or type" {
  inspect(
    ast("gitGraph\n  commit\n  commit type:REVERSE\n"),
    content=(
      #|dir=- title=- accTitle=- accDescr=-
      #|commit id=- msg=- tags=[] type=-
      #|commit id=- msg=- tags=[] type=REVERSE
    ),
  )
}

///|
test "strings are unescaped and may be single quoted" {
  inspect(
    ast("gitGraph\n commit id: 'x\\ty' msg: \"q\\\"q\"\n"),
    content=(
      #|dir=- title=- accTitle=- accDescr=-
      #|commit id="x\ty" msg="q\"q" tags=[] type=-
    ),
  )
}

///|
test "a branch reads its name, which may be quoted, and its order" {
  inspect(
    ast(
      "gitGraph\n branch \"quoted name\"\n branch a-\n branch a..b/c.d\n checkout 1.0.1\n switch main\n",
    ),
    content=(
      #|dir=- title=- accTitle=- accDescr=-
      #|branch "quoted name" order=-
      #|branch "a-" order=-
      #|branch "a..b/c.d" order=-
      #|checkout "1.0.1"
      #|checkout "main"
    ),
  )
  inspect(
    ast("gitGraph\n branch b order:0\n"),
    content=(
      #|dir=- title=- accTitle=- accDescr=-
      #|branch "b" order=0
    ),
  )
}

///|
test "a keyword that starts a longer name is part of that name" {
  inspect(
    ast("gitGraph\n commit\n branch commits\n checkout TBD\n merge LRU\n"),
    content=(
      #|dir=- title=- accTitle=- accDescr=-
      #|commit id=- msg=- tags=[] type=-
      #|branch "commits" order=-
      #|checkout "TBD"
      #|merge "LRU" id=- tags=[] type=-
    ),
  )
  inspect(
    ast("gitGraph\n branch order\n branch type\n"),
    content=(
      #|dir=- title=- accTitle=- accDescr=-
      #|branch "order" order=-
      #|branch "type" order=-
    ),
  )
}

///|
test "a merge reads its clauses" {
  inspect(
    ast("gitGraph\n merge main id:\"a\" tag:\"t\" type:REVERSE\n"),
    content=(
      #|dir=- title=- accTitle=- accDescr=-
      #|merge "main" id="a" tags=["t"] type=REVERSE
    ),
  )
}

///|
test "a cherry-pick keeps an empty tag" {
  inspect(
    ast("gitGraph\n cherry-pick id:\"a\" tag:\"\" parent:\"b\"\n"),
    content=(
      #|dir=- title=- accTitle=- accDescr=-
      #|cherry-pick id="a" tags=[""] parent="b"
    ),
  )
}

///|
test "the header may carry a direction and a colon" {
  inspect(
    ast("gitGraph TB:\n commit \"a\" id:\"b\" tag:\"t\"\n"),
    content=(
      #|dir=TB title=- accTitle=- accDescr=-
      #|commit id="b" msg="a" tags=["t"] type=-
    ),
  )
  inspect(ast("gitGraph LR:\n"), content="dir=LR title=- accTitle=- accDescr=-")
  inspect(
    ast("gitGraph BT :\n commit"),
    content=(
      #|dir=BT title=- accTitle=- accDescr=-
      #|commit id=- msg=- tags=[] type=-
    ),
  )
  inspect(
    ast("gitGraph TB:commit\n"),
    content=(
      #|dir=TB title=- accTitle=- accDescr=-
      #|commit id=- msg=- tags=[] type=-
    ),
  )
  inspect(
    ast("gitGraph:\ncommit"),
    content=(
      #|dir=- title=- accTitle=- accDescr=-
      #|commit id=- msg=- tags=[] type=-
    ),
  )
}

///|
test "a direction without its colon is not part of the header" {
  inspect(
    ast("gitGraph LR\n"),
    content=(
      #|Parse error on line 1:
      #|gitGraph LR
      #|---------^
      #|Expecting a statement, a title, or a line break but found `LR`.
    ),
  )
}

///|
test "titles and accessible texts are read" {
  inspect(
    ast(
      "gitGraph\n title  A   title \n accTitle:  Acc  \n accDescr: Desc\n commit\n",
    ),
    content=(
      #|dir=- title="A title" accTitle="Acc" accDescr="Desc"
      #|commit id=- msg=- tags=[] type=-
    ),
  )
  inspect(
    ast(
      "gitGraph\n  accDescr {\n    Detailed description\n    across multiple lines\n  }\n  commit\n",
    ),
    content=(
      #|dir=- title=- accTitle=- accDescr="Detailed description\nacross multiple lines"
      #|commit id=- msg=- tags=[] type=-
    ),
  )
}

///|
test "blank lines, comments, and front matter around the graph are skipped" {
  inspect(
    ast("\n\n gitGraph \n\n commit\n\n"),
    content=(
      #|dir=- title=- accTitle=- accDescr=-
      #|commit id=- msg=- tags=[] type=-
    ),
  )
  inspect(
    ast("gitGraph:\n %% comment\n commit %% c\n"),
    content=(
      #|dir=- title=- accTitle=- accDescr=-
      #|commit id=- msg=- tags=[] type=-
    ),
  )
  inspect(
    ast("---\ntitle: x\n---\ngitGraph\n commit\n"),
    content=(
      #|dir=- title=- accTitle=- accDescr=-
      #|commit id=- msg=- tags=[] type=-
    ),
  )
}

///|
test "a statement, in order, as a complex graph has them" {
  let source = "\n        gitGraph TB:\n        accTitle: Complex Example\n        commit id:\"init\" type:NORMAL\n        branch feature\n        commit id:\"feat1\" msg:\"Add feature\"\n        checkout main\n        merge feature tag:\"v1.0\"\n        cherry-pick id:\"feat1\" tag:\"critical fix\"\n      "
  inspect(
    ast(source),
    content=(
      #|dir=TB title=- accTitle="Complex Example" accDescr=-
      #|commit id="init" msg=- tags=[] type=NORMAL
      #|branch "feature" order=-
      #|commit id="feat1" msg="Add feature" tags=[] type=-
      #|checkout "main"
      #|merge "feature" id=- tags=["v1.0"] type=-
      #|cherry-pick id="feat1" tags=["critical fix"] parent=-
    ),
  )
}

///|
test "unknown clauses and a bad order are syntax errors" {
  inspect(
    ast("gitGraph\n commit unknown:\"oops\"\n"),
    content=(
      #|Parse error on line 2:
      #| commit unknown:"oops"
      #|--------^
      #|Expecting a line break or the end of input but found `unknown`.
    ),
  )
  inspect(
    ast("gitGraph\n  branch feature order:xyz\n"),
    content=(
      #|Parse error on line 2:
      #|  branch feature order:xyz
      #|-----------------------^
      #|Expecting token of type 'INT' but found `xyz`.
    ),
  )
  inspect(
    ast("gitGraph\n commit type:bogus\n"),
    content=(
      #|Parse error on line 2:
      #| commit type:bogus
      #|-------------^
      #|Expecting NORMAL, REVERSE, or HIGHLIGHT but found `bogus`.
    ),
  )
  inspect(
    ast("gitGraph\n commit id:\n"),
    content=(
      #|Parse error on line 2:
      #| commit id:
      #|-----------^
      #|Expecting token of type 'STRING' but found `
      #|`.
    ),
  )
}

///|
test "an order is an integer that does not run into a dot or another digit" {
  inspect(
    ast("gitGraph\n branch b order: 01\n"),
    content=(
      #|Parse error on line 2:
      #| branch b order: 01
      #|------------------^
      #|Expecting a line break or the end of input but found `1`.
    ),
  )
  inspect(
    ast("gitGraph\n branch b order: 1.5\n"),
    content=(
      #|Parse error on line 2:
      #| branch b order: 1.5
      #|-----------------^
      #|Expecting token of type 'INT' but found `1.5`.
    ),
  )
  inspect(
    ast("gitGraph\n branch b order: 12.5\n"),
    content=(
      #|Parse error on line 2:
      #| branch b order: 12.5
      #|------------------^
      #|Expecting a line break or the end of input but found `2.5`.
    ),
  )
}

///|
test "text before the header is rejected" {
  inspect(
    ast("commit\n"),
    content=(
      #|Parse error on line 1:
      #|commit
      #|^
      #|Expecting token of type 'gitGraph' but found `commit`.
    ),
  )
  inspect(
    ast("gitGraphx\n"),
    content=(
      #|Parse error on line 1:
      #|gitGraphx
      #|^
      #|Expecting token of type 'gitGraph' but found `gitGraphx`.
    ),
  )
  inspect(
    ast("gitGraph\n bogus\n"),
    content=(
      #|Parse error on line 2:
      #| bogus
      #|-^
      #|Expecting a statement, a title, or a line break but found `bogus`.
    ),
  )
}

///|
test "a clause may not run into the next statement" {
  inspect(
    ast("gitGraph\n commit id:\"a\"commit\n"),
    content=(
      #|Parse error on line 2:
      #| commit id:"a"commit
      #|--------------^
      #|Expecting a line break or the end of input but found `commit`.
    ),
  )
}

///|
test "a branch name may start with title" {
  inspect(
    ast(
      "gitGraph\n commit\n branch titles\n commit\n branch title/x\n commit\n checkout main\n merge titles\n branch title-2.0\n branch title1\n",
    ),
    content=(
      #|dir=- title=- accTitle=- accDescr=-
      #|commit id=- msg=- tags=[] type=-
      #|branch "titles" order=-
      #|commit id=- msg=- tags=[] type=-
      #|branch "title/x" order=-
      #|commit id=- msg=- tags=[] type=-
      #|checkout "main"
      #|merge "titles" id=- tags=[] type=-
      #|branch "title-2.0" order=-
      #|branch "title1" order=-
    ),
  )
  inspect(
    ast("gitGraph\n commit\n branch title.v2\n checkout title.v2"),
    content=(
      #|dir=- title=- accTitle=- accDescr=-
      #|commit id=- msg=- tags=[] type=-
      #|branch "title.v2" order=-
      #|checkout "title.v2"
    ),
  )
  inspect(
    ast("gitGraph\n commit\n branch title.\n"),
    content=(
      #|Lexical error on line 3. Unrecognized text.
      #| branch title.
      #|-------------^
    ),
  )
}

///|
test "an accDescr block with no closing brace ends the lexing" {
  inspect(
    ast("gitGraph\n accDescr {\n commit\n"),
    content=(
      #|Lexical error on line 2. Unrecognized text.
      #| accDescr {
      #|----------^
    ),
  )
}
