///|
struct Recorder {
  calls : Array[String]
}

///|
fn type_label(value : @git.CommitType?) -> String {
  match value {
    Some(Normal) => "NORMAL"
    Some(Reverse) => "REVERSE"
    Some(Highlight) => "HIGHLIGHT"
    Some(Merge) => "MERGE"
    Some(CherryPick) => "CHERRY_PICK"
    None => "-"
  }
}

///|
fn direction_label(dir : @git.GitDirection) -> String {
  match dir {
    LR => "LR"
    TB => "TB"
    BT => "BT"
  }
}

///|
fn list_label(tags : Array[String]?) -> String {
  match tags {
    Some(list) => "[" + list.join(",") + "]"
    None => "-"
  }
}

///|
impl @git.GitDbParseProvider for Recorder with fn set_direction(self, dir) {
  self.calls.push("setDirection(\{direction_label(dir)})")
}

///|
impl @git.GitDbParseProvider for Recorder with fn commit(self, commit) {
  self.calls.push(
    "commit(id=\{commit.id.unwrap_or("-")} msg=\{commit.msg} type=\{type_label(Some(commit.commit_type))} tags=\{list_label(Some(commit.tags))})",
  )
}

///|
impl @git.GitDbParseProvider for Recorder with fn branch(self, branch) {
  self.calls.push("branch(name=\{branch.name} order=\{branch.order})")
}

///|
impl @git.GitDbParseProvider for Recorder with fn merge(self, merge) {
  self.calls.push(
    "merge(branch=\{merge.branch} id=\{merge.id} type=\{type_label(merge.commit_type)} tags=\{list_label(Some(merge.tags))})",
  )
}

///|
impl @git.GitDbParseProvider for Recorder with fn cherry_pick(self, pick) {
  self.calls.push(
    "cherryPick(id=\{pick.id.unwrap_or("-")} targetId=\{pick.target_id} parent=\{pick.parent.unwrap_or("-")} tags=\{list_label(pick.tags)})",
  )
}

///|
impl @git.GitDbParseProvider for Recorder with fn checkout(self, branch) {
  self.calls.push("checkout(\{branch})")
}

///|
fn statement_calls(statement : @git.StatementAst) -> String {
  let db = { calls: [], }
  @git.parse_statement(statement, db) catch {
    @errors.PeleError(failure) => return failure.message
  }
  db.calls.join("\n")
}

///|
test "a commit statement becomes a commit call" {
  inspect(
    statement_calls(
      Commit({
        id: Some("1"),
        message: Some("test"),
        tags: ["tag1", "tag2"],
        commit_type: Some(Normal),
      }),
    ),
    content="commit(id=1 msg=test type=NORMAL tags=[tag1,tag2])",
  )
}

///|
test "a commit with nothing written has an empty message and the normal type" {
  inspect(
    statement_calls(
      Commit({ id: None, message: None, tags: [], commit_type: None, }),
    ),
    content="commit(id=- msg= type=NORMAL tags=[])",
  )
}

///|
test "a branch statement becomes a branch call, in order zero unless it has one" {
  inspect(
    statement_calls(Branch({ name: "newBranch", order: Some(1), })),
    content="branch(name=newBranch order=1)",
  )
  inspect(
    statement_calls(Branch({ name: "plain", order: None, })),
    content="branch(name=plain order=0)",
  )
}

///|
test "a checkout statement becomes a checkout call" {
  inspect(
    statement_calls(Checkout({ branch: "newBranch", })),
    content="checkout(newBranch)",
  )
}

///|
test "a merge statement becomes a merge call" {
  inspect(
    statement_calls(
      Merge({
        branch: "newBranch",
        id: Some("1"),
        tags: ["tag1", "tag2"],
        commit_type: Some(Normal),
      }),
    ),
    content="merge(branch=newBranch id=1 type=NORMAL tags=[tag1,tag2])",
  )
}

///|
test "a merge with no id has an empty one and keeps no type" {
  inspect(
    statement_calls(
      Merge({ branch: "b", id: None, tags: [], commit_type: None, }),
    ),
    content="merge(branch=b id= type=- tags=[])",
  )
}

///|
test "a cherry-pick statement becomes a cherry-pick call with no target" {
  inspect(
    statement_calls(
      CherryPicking({
        id: Some("1"),
        tags: ["tag1", "tag2"],
        parent: Some("2"),
      }),
    ),
    content="cherryPick(id=1 targetId= parent=2 tags=[tag1,tag2])",
  )
}

///|
test "a cherry-pick with no tags asks for the default tag" {
  inspect(
    statement_calls(CherryPicking({ id: Some("1"), tags: [], parent: None, })),
    content="cherryPick(id=1 targetId= parent=- tags=-)",
  )
}

///|
test "a graph is handed over with its direction first and its statements in order" {
  let ast : @git.GitGraphAst = {
    dir: Some(TB),
    title: None,
    acc_title: None,
    acc_descr: None,
    statements: [
      Commit({
        id: Some("1"),
        message: Some("test"),
        tags: ["tag1", "tag2"],
        commit_type: Some(Normal),
      }),
      Branch({ name: "newBranch", order: Some(1), }),
      Merge({
        branch: "newBranch",
        id: Some("1"),
        tags: ["tag1", "tag2"],
        commit_type: Some(Normal),
      }),
      Checkout({ branch: "newBranch", }),
      CherryPicking({
        id: Some("1"),
        tags: ["tag1", "tag2"],
        parent: Some("2"),
      }),
    ],
  }
  let db = { calls: [], }
  @git.populate(ast, db) catch {
    @errors.PeleError(failure) => fail(failure.message)
  }
  inspect(
    db.calls.join("\n"),
    content=(
      #|setDirection(TB)
      #|commit(id=1 msg=test type=NORMAL tags=[tag1,tag2])
      #|branch(name=newBranch order=1)
      #|merge(branch=newBranch id=1 type=NORMAL tags=[tag1,tag2])
      #|checkout(newBranch)
      #|cherryPick(id=1 targetId= parent=2 tags=[tag1,tag2])
    ),
  )
}

///|
test "a graph with no direction does not set one" {
  let ast : @git.GitGraphAst = {
    dir: None,
    title: None,
    acc_title: None,
    acc_descr: None,
    statements: [],
  }
  let db = { calls: [], }
  @git.populate(ast, db) catch {
    @errors.PeleError(failure) => fail(failure.message)
  }
  inspect(db.calls.length(), content="0")
}
