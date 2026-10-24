///|
/// A git graph ready to be drawn.
pub(all) struct GitModel {
  title : String?
  acc_title : String?
  acc_descr : String?
  direction : GitDirection
  /// Keyed by commit id, in the order the ids first appeared.
  commits : Map[String, GitCommit]
  /// The id of each branch's latest commit, or `None` while the branch has none.
  branches : Map[String, String?]
  /// Branch names in drawing order: by `order`, then by creation.
  lanes : Array[String]
  current_branch : String
  head : GitCommit?
  warnings : Array[String]
}

///|
fn non_empty(value : String?) -> String? {
  match value {
    Some("") => None
    _ => value
  }
}

///|
/// Does what `text.replace(/\n\s+/g, '\n')` does.
fn join_indented_lines(text : String) -> String {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    @util.write_range(out, text, i, i + 1)
    if @util.code_at(text, i) == '\n'.to_int() &&
      @util.is_space(@util.code_at(text, i + 1)) {
      i += 1
      while @util.is_space(@util.code_at(text, i)) {
        i += 1
      }
    } else {
      i += 1
    }
  }
  out.to_string()
}

///|
fn fail(message : String) -> Unit raise @errors.PeleError {
  raise @errors.pele_error(message, code=Semantic, kind="gitGraph")
}

///|
/// 0x9e3779b1 as a signed 32-bit integer, so that wrapping multiplication equals `Math.imul`.
const ID_STEP : Int32 = -1640531535

///|
/// The first seven hex digits of the 32 bits.
fn hex7(bits : UInt32) -> String {
  let out = StringBuilder()
  for i in 0..<7 {
    let nibble = ((bits >> (28 - 4 * i)) & 15U).reinterpret_as_int()
    out.write_char("0123456789abcdef"[nibble].unsafe_to_char())
  }
  out.to_string()
}

///|
priv struct Builder {
  commits : Map[String, GitCommit]
  branches : Map[String, String?]
  orders : Map[String, Double]
  warnings : Array[String]
  mut head : GitCommit?
  mut current : String
  mut direction : GitDirection
  mut seq : Int32
}

///|
/// Mermaid appends seven random hex digits to the sequence number.
/// These digits are derived from the sequence number instead, so the same text always gives the same ids.
fn Builder::next_id(self : Builder) -> String {
  let mut salt = self.seq + 1
  while true {
    let id = "\{self.seq}-\{hex7((salt * ID_STEP).reinterpret_as_uint())}"
    if !self.commits.contains(id) {
      return id
    }
    salt += ID_STEP
  }
  ""
}

///|
fn Builder::add(self : Builder, commit : GitCommit) -> Unit {
  self.head = Some(commit)
  self.commits.set(commit.id, commit)
  self.branches.set(self.current, Some(commit.id))
}

///|
fn Builder::tip(self : Builder, branch : String) -> GitCommit? {
  match self.branches.get(branch) {
    Some(Some(id)) => self.commits.get(id)
    _ => None
  }
}

///|
fn Builder::do_checkout(
  self : Builder,
  branch : String,
) -> Unit raise @errors.PeleError {
  if !self.branches.contains(branch) {
    fail(
      "Trying to checkout branch which is not yet created. (Help try using \"branch \{branch}\")",
    )
  }
  self.current = branch
  self.head = self.tip(branch)
}

///|
fn Builder::parents_of_head(self : Builder) -> Array[String] {
  match self.head {
    Some(head) => [head.id]
    None => []
  }
}

///|
impl GitDbParseProvider for Builder with fn set_direction(self, dir) {
  self.direction = dir
}

///|
impl GitDbParseProvider for Builder with fn commit(self, commit) {
  let id = match commit.id {
    Some(id) if id != "" => id
    _ => self.next_id()
  }
  let made : GitCommit = {
    id,
    message: commit.msg,
    seq: self.seq,
    commit_type: commit.commit_type,
    tags: commit.tags.copy(),
    parents: self.parents_of_head(),
    branch: self.current,
    custom_type: None,
    custom_id: false,
  }
  self.seq += 1
  if self.commits.contains(made.id) {
    self.warnings.push("Commit ID \{made.id} already exists")
  }
  self.add(made)
}

///|
impl GitDbParseProvider for Builder with fn branch(self, branch) {
  if self.branches.contains(branch.name) {
    fail(
      "Trying to create an existing branch. (Help: Either use a new name if you want create a new branch or try using \"checkout \{branch.name}\")",
    )
  }
  self.branches.set(branch.name, self.head.map(head => head.id))
  self.orders.set(branch.name, branch.order)
  self.do_checkout(branch.name)
}

///|
impl GitDbParseProvider for Builder with fn merge(self, merge) {
  let other = merge.branch
  let current = self.current
  let current_commit = self.tip(current)
  let other_commit = self.tip(other)
  if current_commit is Some(c) && other_commit is Some(_) && c.branch == other {
    fail("Cannot merge branch '\{other}' into itself.")
  }
  if current == other {
    fail("Incorrect usage of \"merge\". Cannot merge a branch to itself")
  }
  guard current_commit is Some(current_commit) else {
    fail(
      "Incorrect usage of \"merge\". Current branch (\{current})has no commits",
    )
    return
  }
  if !self.branches.contains(other) {
    fail(
      "Incorrect usage of \"merge\". Branch to be merged (\{other}) does not exist",
    )
  }
  guard other_commit is Some(other_commit) else {
    fail(
      "Incorrect usage of \"merge\". Branch to be merged (\{other}) has no commits",
    )
    return
  }
  if current_commit.id == other_commit.id {
    fail("Incorrect usage of \"merge\". Both branches have same head")
  }
  if merge.id != "" && self.commits.contains(merge.id) {
    fail(
      "Incorrect usage of \"merge\". Commit with id:\{merge.id} already exists, use different custom id",
    )
  }
  let id = if merge.id != "" { merge.id } else { self.next_id() }
  let parents = match self.head {
    Some(head) => [head.id, other_commit.id]
    None => []
  }
  let made : GitCommit = {
    id,
    message: "merged branch \{other} into \{current}",
    seq: self.seq,
    commit_type: Merge,
    tags: merge.tags.copy(),
    parents,
    branch: current,
    custom_type: merge.commit_type,
    custom_id: merge.id != "",
  }
  self.seq += 1
  self.add(made)
}

///|
impl GitDbParseProvider for Builder with fn cherry_pick(self, pick) {
  let source = match pick.id {
    Some(id) if id != "" => self.commits.get(id)
    _ => None
  }
  guard source is Some(source) else {
    fail(
      "Incorrect usage of \"cherryPick\". Source commit id should exist and provided",
    )
    return
  }
  let parent = match pick.parent {
    Some("") => None
    other => other
  }
  if parent is Some(parent) && !source.parents.contains(parent) {
    fail(
      "Invalid operation: The specified parent commit is not an immediate parent of the cherry-picked commit.",
    )
  }
  if source.commit_type is Merge && parent is None {
    fail(
      "Incorrect usage of cherry-pick: If the source commit is a merge commit, an immediate parent commit must be specified.",
    )
  }
  if pick.target_id != "" && self.commits.contains(pick.target_id) {
    return
  }
  if source.branch == self.current {
    fail(
      "Incorrect usage of \"cherryPick\". Source commit is already on current branch",
    )
  }
  guard self.tip(self.current) is Some(_) else {
    fail(
      "Incorrect usage of \"cherry-pick\". Current branch (\{self.current})has no commits",
    )
    return
  }
  let id = self.next_id()
  let parents = match self.head {
    Some(head) => [head.id, source.id]
    None => []
  }
  let tags = match pick.tags {
    Some(tags) => tags.filter(tag => tag != "")
    None => {
      let via = match (source.commit_type, parent) {
        (Merge, Some(parent)) => "|parent:\{parent}"
        _ => ""
      }
      ["cherry-pick:\{source.id}\{via}"]
    }
  }
  let made : GitCommit = {
    id,
    message: "cherry-picked \{source.message} into \{self.current}",
    seq: self.seq,
    commit_type: CherryPick,
    tags,
    parents,
    branch: self.current,
    custom_type: None,
    custom_id: false,
  }
  self.seq += 1
  self.add(made)
}

///|
impl GitDbParseProvider for Builder with fn checkout(self, branch) {
  self.do_checkout(branch)
}

///|
fn config_section(config : @types.Config) -> Map[String, Json] {
  match config.get("gitGraph") {
    Some(Object(section)) => section
    _ => {}
  }
}

///|
/// Plays the statements of a graph on a database of commits and branches.
/// `title` is the front matter title, used when the graph has none.
/// Raises a semantic `PeleError` for a statement that Mermaid rejects.
pub fn build_git(
  ast : GitGraphAst,
  config : @types.Config,
  title : String?,
) -> GitModel raise @errors.PeleError {
  let section = config_section(config)
  let main_name = match section.get("mainBranchName") {
    Some(String(name)) => name
    _ => "main"
  }
  let main_order = match section.get("mainBranchOrder") {
    Some(Number(order, ..)) => order
    _ => 0
  }
  let builder : Builder = {
    commits: {},
    branches: {},
    orders: {},
    warnings: [],
    head: None,
    current: main_name,
    direction: LR,
    seq: 0,
  }
  builder.branches.set(main_name, None)
  builder.orders.set(main_name, main_order)
  populate(ast, builder)
  let ranked = []
  let mut index = 0
  for name, order in builder.orders {
    ranked.push((name, order, index))
    index += 1
  }
  ranked.sort_by((a, b) => {
    let d = a.1 - b.1
    if d > 0 {
      1
    } else if d < 0 {
      -1
    } else {
      a.2.compare(b.2)
    }
  })
  {
    title: match non_empty(ast.title) {
      Some(_) as own => own
      None => title
    },
    acc_title: non_empty(ast.acc_title).map(@util.trim_start),
    acc_descr: non_empty(ast.acc_descr).map(join_indented_lines),
    direction: builder.direction,
    commits: builder.commits,
    branches: builder.branches,
    lanes: ranked.map(entry => entry.0),
    current_branch: builder.current,
    head: builder.head,
    warnings: builder.warnings,
  }
}
