///|
fn kind_name(commit_type : @git.CommitType) -> String {
  match commit_type {
    Normal => "NORMAL"
    Reverse => "REVERSE"
    Highlight => "HIGHLIGHT"
    Merge => "MERGE"
    CherryPick => "CHERRY_PICK"
  }
}

///|
/// Whether the id is one the builder made up: the commit's number and seven hex digits.
fn is_generated(commit : @git.GitCommit) -> Bool {
  let prefix = "\{commit.seq}-"
  if commit.id.length() != prefix.length() + 7 || !commit.id.has_prefix(prefix) {
    return false
  }
  for i in prefix.length()..<commit.id.length() {
    if !@util.is_hex(@util.code_at(commit.id, i)) {
      return false
    }
  }
  true
}

///|
/// Generated ids differ from text to text in nothing but their digits, so they are shown by their number.
fn label(model : @git.GitModel, id : String) -> String {
  match model.commits.get(id) {
    Some(commit) if is_generated(commit) => "#\{commit.seq}"
    _ => id
  }
}

///|
fn direction_name(dir : @git.GitDirection) -> String {
  match dir {
    LR => "LR"
    TB => "TB"
    BT => "BT"
  }
}

///|
fn describe(model : @git.GitModel) -> String {
  let lines = []
  let head = match model.head {
    Some(commit) => label(model, commit.id)
    None => "-"
  }
  let acc_descr = match model.acc_descr {
    Some(text) => text.escape()
    None => "-"
  }
  lines.push(
    "dir=\{direction_name(model.direction)} current=\{model.current_branch} head=\{head} lanes=\{model.lanes.join(",")} title=\{model.title.unwrap_or("-")} accTitle=\{model.acc_title.unwrap_or("-")} accDescr=\{acc_descr}",
  )
  let tips = []
  for name, tip in model.branches {
    tips.push("\{name}->\{tip.map(id => label(model, id)).unwrap_or("-")}")
  }
  lines.push("branches: " + tips.join(", "))
  for _, commit in model.commits {
    let custom = match commit.custom_type {
      Some(t) => "/" + kind_name(t)
      None => ""
    }
    let custom_id = if commit.custom_id { " custom-id" } else { "" }
    let parents = commit.parents.map(id => label(model, id)).join(",")
    lines.push(
      "\{label(model, commit.id)} seq=\{commit.seq} \{commit.branch} \{kind_name(commit.commit_type)}\{custom}\{custom_id} parents=[\{parents}] tags=[\{commit.tags.join(",")}] msg=\{commit.message.escape()}",
    )
  }
  lines.push("warnings=[" + model.warnings.map(w => w.escape()).join(",") + "]")
  lines.join("\n")
}

///|
fn dump(source : String, config~ : Json = {}) -> String {
  let config : @types.Config = match config {
    Object(fields) => fields
    _ => {}
  }
  let model = @git.build_git(@git.parse_git(source), config, None) catch {
    @errors.PeleError(failure) =>
      return "ERR \{failure.code.to_string()} \{failure.kind.unwrap_or("null")} \{failure.message.escape()}"
  }
  describe(model)
}

///|
test "a graph starts on main, runs left to right unless told otherwise, and holds the commits it is given" {
  inspect(
    dump("gitGraph:\n commit\n"),
    content=(
      #|dir=LR current=main head=#0 lanes=main title=- accTitle=- accDescr=-
      #|branches: main->#0
      #|#0 seq=0 main NORMAL parents=[] tags=[] msg=""
      #|warnings=[]
    ),
  )
  inspect(
    dump("gitGraph TB:\ncommit\n"),
    content=(
      #|dir=TB current=main head=#0 lanes=main title=- accTitle=- accDescr=-
      #|branches: main->#0
      #|#0 seq=0 main NORMAL parents=[] tags=[] msg=""
      #|warnings=[]
    ),
  )
  inspect(
    dump("gitGraph BT:\ncommit\n"),
    content=(
      #|dir=BT current=main head=#0 lanes=main title=- accTitle=- accDescr=-
      #|branches: main->#0
      #|#0 seq=0 main NORMAL parents=[] tags=[] msg=""
      #|warnings=[]
    ),
  )
  inspect(
    dump("gitGraph:\ncommit\ncommit\ncommit\n"),
    content=(
      #|dir=LR current=main head=#2 lanes=main title=- accTitle=- accDescr=-
      #|branches: main->#2
      #|#0 seq=0 main NORMAL parents=[] tags=[] msg=""
      #|#1 seq=1 main NORMAL parents=[#0] tags=[] msg=""
      #|#2 seq=2 main NORMAL parents=[#1] tags=[] msg=""
      #|warnings=[]
    ),
  )
}

///|
test "a checkout moves the head to the tip of a branch, which has none until it is given a commit" {
  inspect(
    dump("gitGraph:\nbranch new\ncheckout new\n"),
    content=(
      #|dir=LR current=new head=- lanes=main,new title=- accTitle=- accDescr=-
      #|branches: main->-, new->-
      #|warnings=[]
    ),
  )
  inspect(
    dump("gitGraph:\nbranch new\ncheckout new\ncommit\ncommit\n"),
    content=(
      #|dir=LR current=new head=#1 lanes=main,new title=- accTitle=- accDescr=-
      #|branches: main->-, new->#1
      #|#0 seq=0 new NORMAL parents=[] tags=[] msg=""
      #|#1 seq=1 new NORMAL parents=[#0] tags=[] msg=""
      #|warnings=[]
    ),
  )
  inspect(
    dump("gitGraph:\ncommit\nbranch testBranch\nswitch testBranch\ncommit\n"),
    content=(
      #|dir=LR current=testBranch head=#1 lanes=main,testBranch title=- accTitle=- accDescr=-
      #|branches: main->#0, testBranch->#1
      #|#0 seq=0 main NORMAL parents=[] tags=[] msg=""
      #|#1 seq=1 testBranch NORMAL parents=[#0] tags=[] msg=""
      #|warnings=[]
    ),
  )
}

///|
test "a commit takes its clauses as written, and a bare string is its message" {
  inspect(
    dump("gitGraph:\ncommit \"a commit\"\n"),
    content=(
      #|dir=LR current=main head=#0 lanes=main title=- accTitle=- accDescr=-
      #|branches: main->#0
      #|#0 seq=0 main NORMAL parents=[] tags=[] msg="a commit"
      #|warnings=[]
    ),
  )
  inspect(
    dump(
      "gitGraph:\n commit id:\"1111\" type:REVERSE tag: \"test tag\" msg:\"test msg\"\n",
    ),
    content=(
      #|dir=LR current=main head=1111 lanes=main title=- accTitle=- accDescr=-
      #|branches: main->1111
      #|1111 seq=0 main REVERSE parents=[] tags=[test tag] msg="test msg"
      #|warnings=[]
    ),
  )
  inspect(
    dump("gitGraph:\n commit type: HIGHLIGHT\n commit tag: \"t\" tag: \"u\"\n"),
    content=(
      #|dir=LR current=main head=#1 lanes=main title=- accTitle=- accDescr=-
      #|branches: main->#1
      #|#0 seq=0 main HIGHLIGHT parents=[] tags=[] msg=""
      #|#1 seq=1 main NORMAL parents=[#0] tags=[t,u] msg=""
      #|warnings=[]
    ),
  )
  inspect(
    dump(
      "gitGraph:\n commit id:\"1111\" tag: \"test tag\"\n commit type:NORMAL\n",
    ),
    content=(
      #|dir=LR current=main head=#1 lanes=main title=- accTitle=- accDescr=-
      #|branches: main->#1
      #|1111 seq=0 main NORMAL parents=[] tags=[test tag] msg=""
      #|#1 seq=1 main NORMAL parents=[1111] tags=[] msg=""
      #|warnings=[]
    ),
  )
}

///|
test "a branch starts at the head, becomes the current one, and is drawn in the order it was made unless it has an order" {
  inspect(
    dump(
      "gitGraph:\ncommit\nbranch b1\ncheckout b1\ncommit\ncommit\nbranch b2\n",
    ),
    content=(
      #|dir=LR current=b2 head=#2 lanes=main,b1,b2 title=- accTitle=- accDescr=-
      #|branches: main->#0, b1->#2, b2->#2
      #|#0 seq=0 main NORMAL parents=[] tags=[] msg=""
      #|#1 seq=1 b1 NORMAL parents=[#0] tags=[] msg=""
      #|#2 seq=2 b1 NORMAL parents=[#1] tags=[] msg=""
      #|warnings=[]
    ),
  )
  inspect(
    dump(
      "gitGraph:\n commit\n branch \"branch\"\n checkout \"branch\"\n commit\n checkout main\n merge \"branch\"\n",
    ),
    content=(
      #|dir=LR current=main head=#2 lanes=main,branch title=- accTitle=- accDescr=-
      #|branches: main->#2, branch->#1
      #|#0 seq=0 main NORMAL parents=[] tags=[] msg=""
      #|#1 seq=1 branch NORMAL parents=[#0] tags=[] msg=""
      #|#2 seq=2 main MERGE parents=[#0,#1] tags=[] msg="merged branch branch into main"
      #|warnings=[]
    ),
  )
  inspect(
    dump("gitGraph:\n commit\n branch azAZ_-./test\n"),
    content=(
      #|dir=LR current=azAZ_-./test head=#0 lanes=main,azAZ_-./test title=- accTitle=- accDescr=-
      #|branches: main->#0, azAZ_-./test->#0
      #|#0 seq=0 main NORMAL parents=[] tags=[] msg=""
      #|warnings=[]
    ),
  )
  inspect(
    dump(
      "gitGraph:\n commit\n branch branch01\n branch checkout02\n branch cherry-pick03\n branch branch/example-branch\n branch merge/test_merge\n branch A\n",
    ),
    content=(
      #|dir=LR current=A head=#0 lanes=main,branch01,checkout02,cherry-pick03,branch/example-branch,merge/test_merge,A title=- accTitle=- accDescr=-
      #|branches: main->#0, branch01->#0, checkout02->#0, cherry-pick03->#0, branch/example-branch->#0, merge/test_merge->#0, A->#0
      #|#0 seq=0 main NORMAL parents=[] tags=[] msg=""
      #|warnings=[]
    ),
  )
  inspect(
    dump(
      "gitGraph:\n commit\n branch test1 order: 3\n branch test2 order: 2\n branch test3 order: 1\n",
    ),
    content=(
      #|dir=LR current=test3 head=#0 lanes=main,test3,test2,test1 title=- accTitle=- accDescr=-
      #|branches: main->#0, test1->#0, test2->#0, test3->#0
      #|#0 seq=0 main NORMAL parents=[] tags=[] msg=""
      #|warnings=[]
    ),
  )
  inspect(
    dump(
      "gitGraph:\n commit\n branch test1 order: 1\n branch test2\n branch test3\n",
    ),
    content=(
      #|dir=LR current=test3 head=#0 lanes=main,test2,test3,test1 title=- accTitle=- accDescr=-
      #|branches: main->#0, test1->#0, test2->#0, test3->#0
      #|#0 seq=0 main NORMAL parents=[] tags=[] msg=""
      #|warnings=[]
    ),
  )
  inspect(
    dump("gitGraph\n branch b order: 99999999999999999999999999\n branch c\n"),
    content=(
      #|dir=LR current=c head=- lanes=main,c,b title=- accTitle=- accDescr=-
      #|branches: main->-, b->-, c->-
      #|warnings=[]
    ),
  )
}

///|
test "the main branch takes its name and its place from the config" {
  inspect(
    dump(
      "gitGraph\n commit\n branch b1\n commit\n branch b2 order: 3\n commit\n branch b3 order: 1\n commit\n",
      config={ "gitGraph": { "mainBranchName": "trunk", "mainBranchOrder": 2 } },
    ),
    content=(
      #|dir=LR current=b3 head=#3 lanes=b1,b3,trunk,b2 title=- accTitle=- accDescr=-
      #|branches: trunk->#0, b1->#1, b2->#2, b3->#3
      #|#0 seq=0 trunk NORMAL parents=[] tags=[] msg=""
      #|#1 seq=1 b1 NORMAL parents=[#0] tags=[] msg=""
      #|#2 seq=2 b2 NORMAL parents=[#1] tags=[] msg=""
      #|#3 seq=3 b3 NORMAL parents=[#2] tags=[] msg=""
      #|warnings=[]
    ),
  )
  inspect(
    dump("gitGraph\n commit\n branch b\n commit\n", config={
      "gitGraph": { "mainBranchName": 1, "mainBranchOrder": "x" },
    }),
    content=(
      #|dir=LR current=b head=#1 lanes=main,b title=- accTitle=- accDescr=-
      #|branches: main->#0, b->#1
      #|#0 seq=0 main NORMAL parents=[] tags=[] msg=""
      #|#1 seq=1 b NORMAL parents=[#0] tags=[] msg=""
      #|warnings=[]
    ),
  )
}

///|
test "a merge has the head and the tip of the other branch as parents, and its own message" {
  inspect(
    dump(
      "gitGraph:\ncommit\nbranch newbranch\ncheckout newbranch\ncommit\ncommit\nmerge main\n",
    ),
    content=(
      #|dir=LR current=newbranch head=#3 lanes=main,newbranch title=- accTitle=- accDescr=-
      #|branches: main->#0, newbranch->#3
      #|#0 seq=0 main NORMAL parents=[] tags=[] msg=""
      #|#1 seq=1 newbranch NORMAL parents=[#0] tags=[] msg=""
      #|#2 seq=2 newbranch NORMAL parents=[#1] tags=[] msg=""
      #|#3 seq=3 newbranch MERGE parents=[#2,#0] tags=[] msg="merged branch main into newbranch"
      #|warnings=[]
    ),
  )
  inspect(
    dump(
      "gitGraph:\ncommit\nbranch newbranch\ncheckout newbranch\ncommit\ncommit\ncheckout main\ncommit\nmerge newbranch\n",
    ),
    content=(
      #|dir=LR current=main head=#4 lanes=main,newbranch title=- accTitle=- accDescr=-
      #|branches: main->#4, newbranch->#2
      #|#0 seq=0 main NORMAL parents=[] tags=[] msg=""
      #|#1 seq=1 newbranch NORMAL parents=[#0] tags=[] msg=""
      #|#2 seq=2 newbranch NORMAL parents=[#1] tags=[] msg=""
      #|#3 seq=3 main NORMAL parents=[#0] tags=[] msg=""
      #|#4 seq=4 main MERGE parents=[#3,#2] tags=[] msg="merged branch newbranch into main"
      #|warnings=[]
    ),
  )
  inspect(
    dump(
      "gitGraph:\n commit\n branch testBranch\n checkout testBranch\n commit\n checkout main\n merge testBranch tag: \"merge-tag\"\n",
    ),
    content=(
      #|dir=LR current=main head=#2 lanes=main,testBranch title=- accTitle=- accDescr=-
      #|branches: main->#2, testBranch->#1
      #|#0 seq=0 main NORMAL parents=[] tags=[] msg=""
      #|#1 seq=1 testBranch NORMAL parents=[#0] tags=[] msg=""
      #|#2 seq=2 main MERGE parents=[#0,#1] tags=[merge-tag] msg="merged branch testBranch into main"
      #|warnings=[]
    ),
  )
  inspect(
    dump(
      "gitGraph:\n commit\n branch testBranch\n switch testBranch\n commit\n commit\n switch main\n merge testBranch\n",
    ),
    content=(
      #|dir=LR current=main head=#3 lanes=main,testBranch title=- accTitle=- accDescr=-
      #|branches: main->#3, testBranch->#2
      #|#0 seq=0 main NORMAL parents=[] tags=[] msg=""
      #|#1 seq=1 testBranch NORMAL parents=[#0] tags=[] msg=""
      #|#2 seq=2 testBranch NORMAL parents=[#1] tags=[] msg=""
      #|#3 seq=3 main MERGE parents=[#0,#2] tags=[] msg="merged branch testBranch into main"
      #|warnings=[]
    ),
  )
}

///|
test "a merge may be given an id, a tag and a type, and is then worth a label" {
  inspect(
    dump(
      "gitGraph:\n commit\n branch testBranch\n checkout testBranch\n commit\n checkout main\n merge testBranch tag: \"merge-tag\" id: \"2-222\"\n branch testBranch2\n checkout testBranch2\n commit\n checkout main\n merge testBranch2 id: \"4-444\" tag: \"merge-tag2\" type:HIGHLIGHT\n branch testBranch3\n checkout testBranch3\n commit\n checkout main\n merge testBranch3 id: \"6-666\"\n",
    ),
    content=(
      #|dir=LR current=main head=6-666 lanes=main,testBranch,testBranch2,testBranch3 title=- accTitle=- accDescr=-
      #|branches: main->6-666, testBranch->#1, testBranch2->#3, testBranch3->#5
      #|#0 seq=0 main NORMAL parents=[] tags=[] msg=""
      #|#1 seq=1 testBranch NORMAL parents=[#0] tags=[] msg=""
      #|2-222 seq=2 main MERGE custom-id parents=[#0,#1] tags=[merge-tag] msg="merged branch testBranch into main"
      #|#3 seq=3 testBranch2 NORMAL parents=[2-222] tags=[] msg=""
      #|4-444 seq=4 main MERGE/HIGHLIGHT custom-id parents=[2-222,#3] tags=[merge-tag2] msg="merged branch testBranch2 into main"
      #|#5 seq=5 testBranch3 NORMAL parents=[4-444] tags=[] msg=""
      #|6-666 seq=6 main MERGE custom-id parents=[4-444,#5] tags=[] msg="merged branch testBranch3 into main"
      #|warnings=[]
    ),
  )
}

///|
test "a cherry-pick copies a commit of another branch and tags it with its source unless told otherwise" {
  inspect(
    dump(
      "gitGraph\n commit id: \"ZERO\"\n branch develop\n commit id:\"A\"\n checkout main\n cherry-pick id:\"A\"\n",
    ),
    content=(
      #|dir=LR current=main head=#2 lanes=main,develop title=- accTitle=- accDescr=-
      #|branches: main->#2, develop->A
      #|ZERO seq=0 main NORMAL parents=[] tags=[] msg=""
      #|A seq=1 develop NORMAL parents=[ZERO] tags=[] msg=""
      #|#2 seq=2 main CHERRY_PICK parents=[ZERO,A] tags=[cherry-pick:A] msg="cherry-picked  into main"
      #|warnings=[]
    ),
  )
  inspect(
    dump(
      "gitGraph\n commit id: \"ZERO\"\n branch develop\n commit id:\"A\"\n checkout main\n cherry-pick id:\"A\" tag:\"MyTag\"\n",
    ),
    content=(
      #|dir=LR current=main head=#2 lanes=main,develop title=- accTitle=- accDescr=-
      #|branches: main->#2, develop->A
      #|ZERO seq=0 main NORMAL parents=[] tags=[] msg=""
      #|A seq=1 develop NORMAL parents=[ZERO] tags=[] msg=""
      #|#2 seq=2 main CHERRY_PICK parents=[ZERO,A] tags=[MyTag] msg="cherry-picked  into main"
      #|warnings=[]
    ),
  )
  inspect(
    dump(
      "gitGraph\n commit id: \"ZERO\"\n branch develop\n commit id:\"A\"\n checkout main\n cherry-pick id:\"A\" tag:\"\"\n",
    ),
    content=(
      #|dir=LR current=main head=#2 lanes=main,develop title=- accTitle=- accDescr=-
      #|branches: main->#2, develop->A
      #|ZERO seq=0 main NORMAL parents=[] tags=[] msg=""
      #|A seq=1 develop NORMAL parents=[ZERO] tags=[] msg=""
      #|#2 seq=2 main CHERRY_PICK parents=[ZERO,A] tags=[] msg="cherry-picked  into main"
      #|warnings=[]
    ),
  )
  inspect(
    dump(
      "gitGraph\n commit id:\"z\"\n branch b\n commit id:\"a\"\n checkout main\n commit\n cherry-pick id:\"a\" parent:\"\"\n",
    ),
    content=(
      #|dir=LR current=main head=#3 lanes=main,b title=- accTitle=- accDescr=-
      #|branches: main->#3, b->a
      #|z seq=0 main NORMAL parents=[] tags=[] msg=""
      #|a seq=1 b NORMAL parents=[z] tags=[] msg=""
      #|#2 seq=2 main NORMAL parents=[z] tags=[] msg=""
      #|#3 seq=3 main CHERRY_PICK parents=[#2,a] tags=[cherry-pick:a] msg="cherry-picked  into main"
      #|warnings=[]
    ),
  )
}

///|
test "a cherry-picked merge commit names the parent it follows" {
  inspect(
    dump(
      "gitGraph\n commit id: \"ZERO\"\n branch feature\n branch release\n checkout feature\n commit id: \"A\"\n commit id: \"B\"\n checkout main\n merge feature id: \"M\"\n checkout release\n cherry-pick id: \"M\" parent:\"B\"\n",
    ),
    content=(
      #|dir=LR current=release head=#4 lanes=main,feature,release title=- accTitle=- accDescr=-
      #|branches: main->M, feature->B, release->#4
      #|ZERO seq=0 main NORMAL parents=[] tags=[] msg=""
      #|A seq=1 feature NORMAL parents=[ZERO] tags=[] msg=""
      #|B seq=2 feature NORMAL parents=[A] tags=[] msg=""
      #|M seq=3 main MERGE custom-id parents=[ZERO,B] tags=[] msg="merged branch feature into main"
      #|#4 seq=4 release CHERRY_PICK parents=[ZERO,M] tags=[cherry-pick:M|parent:B] msg="cherry-picked merged branch feature into main into release"
      #|warnings=[]
    ),
  )
  inspect(
    dump(
      "gitGraph\n commit id: \"ZERO\"\n branch feature\n branch release\n checkout feature\n commit id: \"A\"\n commit id: \"B\"\n checkout main\n merge feature id: \"M\"\n checkout release\n commit id: \"C\"\n cherry-pick id: \"M\" tag: \"v2.1:ZERO\" parent:\"ZERO\"\n commit id: \"D\"\n",
    ),
    content=(
      #|dir=LR current=release head=D lanes=main,feature,release title=- accTitle=- accDescr=-
      #|branches: main->M, feature->B, release->D
      #|ZERO seq=0 main NORMAL parents=[] tags=[] msg=""
      #|A seq=1 feature NORMAL parents=[ZERO] tags=[] msg=""
      #|B seq=2 feature NORMAL parents=[A] tags=[] msg=""
      #|M seq=3 main MERGE custom-id parents=[ZERO,B] tags=[] msg="merged branch feature into main"
      #|C seq=4 release NORMAL parents=[ZERO] tags=[] msg=""
      #|#5 seq=5 release CHERRY_PICK parents=[C,M] tags=[v2.1:ZERO] msg="cherry-picked merged branch feature into main into release"
      #|D seq=6 release NORMAL parents=[#5] tags=[] msg=""
      #|warnings=[]
    ),
  )
  inspect(
    dump(
      "gitGraph\n commit id: \"ZERO\"\n branch feature\n branch release\n checkout feature\n commit id: \"A\"\n commit id: \"B\"\n checkout main\n merge feature id: \"M\"\n checkout release\n commit id: \"C\"\n cherry-pick id:\"M\" parent: \"ZERO\" tag:\"\"\n commit id: \"D\"\n cherry-pick id:\"M\" tag:\"\" parent: \"B\"\n",
    ),
    content=(
      #|dir=LR current=release head=#7 lanes=main,feature,release title=- accTitle=- accDescr=-
      #|branches: main->M, feature->B, release->#7
      #|ZERO seq=0 main NORMAL parents=[] tags=[] msg=""
      #|A seq=1 feature NORMAL parents=[ZERO] tags=[] msg=""
      #|B seq=2 feature NORMAL parents=[A] tags=[] msg=""
      #|M seq=3 main MERGE custom-id parents=[ZERO,B] tags=[] msg="merged branch feature into main"
      #|C seq=4 release NORMAL parents=[ZERO] tags=[] msg=""
      #|#5 seq=5 release CHERRY_PICK parents=[C,M] tags=[] msg="cherry-picked merged branch feature into main into release"
      #|D seq=6 release NORMAL parents=[#5] tags=[] msg=""
      #|#7 seq=7 release CHERRY_PICK parents=[D,M] tags=[] msg="cherry-picked merged branch feature into main into release"
      #|warnings=[]
    ),
  )
}

///|
test "names that are object keys in pele are plain names" {
  inspect(
    dump(
      "gitGraph\n commit id:\"__proto__\"\n branch __proto__\n checkout __proto__\n commit\n checkout main\n merge __proto__\n",
    ),
    content=(
      #|dir=LR current=main head=#2 lanes=main,__proto__ title=- accTitle=- accDescr=-
      #|branches: main->#2, __proto__->#1
      #|__proto__ seq=0 main NORMAL parents=[] tags=[] msg=""
      #|#1 seq=1 __proto__ NORMAL parents=[__proto__] tags=[] msg=""
      #|#2 seq=2 main MERGE parents=[__proto__,#1] tags=[] msg="merged branch __proto__ into main"
      #|warnings=[]
    ),
  )
  inspect(
    dump(
      "gitGraph\n commit id:\"constructor\"\n branch constructor\n checkout constructor\n commit\n checkout main\n merge constructor\n",
    ),
    content=(
      #|dir=LR current=main head=#2 lanes=main,constructor title=- accTitle=- accDescr=-
      #|branches: main->#2, constructor->#1
      #|constructor seq=0 main NORMAL parents=[] tags=[] msg=""
      #|#1 seq=1 constructor NORMAL parents=[constructor] tags=[] msg=""
      #|#2 seq=2 main MERGE parents=[constructor,#1] tags=[] msg="merged branch constructor into main"
      #|warnings=[]
    ),
  )
}

///|
test "a repeated commit id replaces the earlier commit in place and warns" {
  inspect(
    dump("gitGraph\n commit id:\"a\"\n commit id:\"b\"\n commit id:\"a\"\n"),
    content=(
      #|dir=LR current=main head=a lanes=main title=- accTitle=- accDescr=-
      #|branches: main->a
      #|a seq=2 main NORMAL parents=[b] tags=[] msg=""
      #|b seq=1 main NORMAL parents=[a] tags=[] msg=""
      #|warnings=["Commit ID a already exists"]
    ),
  )
  inspect(
    dump(
      "gitGraph\n commit id:\"initial commit\"\n commit id:\"work on first release\"\n branch v1-rc\n checkout v1-rc\n commit id:\"working on MDR\"\n checkout main\n commit id:\"working on MDR\"\n",
    ),
    content=(
      #|dir=LR current=main head=working on MDR lanes=main,v1-rc title=- accTitle=- accDescr=-
      #|branches: main->working on MDR, v1-rc->working on MDR
      #|initial commit seq=0 main NORMAL parents=[] tags=[] msg=""
      #|work on first release seq=1 main NORMAL parents=[initial commit] tags=[] msg=""
      #|working on MDR seq=3 main NORMAL parents=[work on first release] tags=[] msg=""
      #|warnings=["Commit ID working on MDR already exists"]
    ),
  )
}

///|
test "generated ids are numbered by the order of the commits" {
  inspect(
    dump(
      "gitGraph\n commit\n commit\n branch b\n commit\n checkout main\n commit\n merge b\n",
    ),
    content=(
      #|dir=LR current=main head=#4 lanes=main,b title=- accTitle=- accDescr=-
      #|branches: main->#4, b->#2
      #|#0 seq=0 main NORMAL parents=[] tags=[] msg=""
      #|#1 seq=1 main NORMAL parents=[#0] tags=[] msg=""
      #|#2 seq=2 b NORMAL parents=[#1] tags=[] msg=""
      #|#3 seq=3 main NORMAL parents=[#1] tags=[] msg=""
      #|#4 seq=4 main MERGE parents=[#3,#2] tags=[] msg="merged branch b into main"
      #|warnings=[]
    ),
  )
}

///|
test "the title and accessible texts of the graph are kept without their indentation" {
  inspect(
    dump(
      "gitGraph\n title  T \n accTitle:   at\n accDescr {\n   multi\n    line\n }\n commit\n",
    ),
    content=(
      #|dir=LR current=main head=#0 lanes=main title=T accTitle=at accDescr="multi\nline"
      #|branches: main->#0
      #|#0 seq=0 main NORMAL parents=[] tags=[] msg=""
      #|warnings=[]
    ),
  )
  inspect(
    dump(
      "gitGraph:\n accTitle: This is a title\n accDescr: This is a description\n commit\n",
    ),
    content=(
      #|dir=LR current=main head=#0 lanes=main title=- accTitle=This is a title accDescr="This is a description"
      #|branches: main->#0
      #|#0 seq=0 main NORMAL parents=[] tags=[] msg=""
      #|warnings=[]
    ),
  )
}

///|
test "what Mermaid rejects is rejected with its message" {
  inspect(
    dump("gitGraph\n commit\n branch main\n"),
    content=(
      #|ERR semantic gitGraph "Trying to create an existing branch. (Help: Either use a new name if you want create a new branch or try using \"checkout main\")"
    ),
  )
  inspect(
    dump("gitGraph\n commit\n branch testBranch\n commit\n branch testBranch\n"),
    content=(
      #|ERR semantic gitGraph "Trying to create an existing branch. (Help: Either use a new name if you want create a new branch or try using \"checkout testBranch\")"
    ),
  )
  inspect(
    dump("gitGraph\n commit\n checkout nope\n"),
    content=(
      #|ERR semantic gitGraph "Trying to checkout branch which is not yet created. (Help try using \"branch nope\")"
    ),
  )
  inspect(
    dump("gitGraph\n commit\n branch b\n merge b\n"),
    content=(
      #|ERR semantic gitGraph "Incorrect usage of \"merge\". Cannot merge a branch to itself"
    ),
  )
  inspect(
    dump("gitGraph\n commit\n branch b\n merge main\n"),
    content=(
      #|ERR semantic gitGraph "Cannot merge branch 'main' into itself."
    ),
  )
  inspect(
    dump("gitGraph\n merge b\n"),
    content=(
      #|ERR semantic gitGraph "Incorrect usage of \"merge\". Current branch (main)has no commits"
    ),
  )
  inspect(
    dump("gitGraph\n commit\n merge b\n"),
    content=(
      #|ERR semantic gitGraph "Incorrect usage of \"merge\". Branch to be merged (b) does not exist"
    ),
  )
  inspect(
    dump("gitGraph\n branch b\n checkout main\n commit\n merge b\n"),
    content=(
      #|ERR semantic gitGraph "Incorrect usage of \"merge\". Branch to be merged (b) has no commits"
    ),
  )
  inspect(
    dump("gitGraph\n commit\n branch b\n checkout main\n merge b\n"),
    content=(
      #|ERR semantic gitGraph "Incorrect usage of \"merge\". Both branches have same head"
    ),
  )
  inspect(
    dump(
      "gitGraph\n commit id:\"a\"\n branch b\n commit\n checkout main\n commit\n merge b id:\"a\"\n",
    ),
    content=(
      #|ERR semantic gitGraph "Incorrect usage of \"merge\". Commit with id:a already exists, use different custom id"
    ),
  )
  inspect(
    dump("gitGraph\n commit\n cherry-pick id:\"nope\"\n"),
    content=(
      #|ERR semantic gitGraph "Incorrect usage of \"cherryPick\". Source commit id should exist and provided"
    ),
  )
  inspect(
    dump("gitGraph\n commit\n cherry-pick\n"),
    content=(
      #|ERR semantic gitGraph "Incorrect usage of \"cherryPick\". Source commit id should exist and provided"
    ),
  )
  inspect(
    dump("gitGraph\n commit id:\"a\"\n cherry-pick id:\"a\"\n"),
    content=(
      #|ERR semantic gitGraph "Incorrect usage of \"cherryPick\". Source commit is already on current branch"
    ),
  )
  inspect(
    dump(
      "gitGraph\n branch b\n commit id:\"a\"\n checkout main\n cherry-pick id:\"a\"\n",
    ),
    content=(
      #|ERR semantic gitGraph "Incorrect usage of \"cherry-pick\". Current branch (main)has no commits"
    ),
  )
  inspect(
    dump(
      "gitGraph\n commit id:\"z\"\n branch b\n commit id:\"a\"\n checkout main\n commit\n cherry-pick id:\"a\" parent:\"q\"\n",
    ),
    content=(
      #|ERR semantic gitGraph "Invalid operation: The specified parent commit is not an immediate parent of the cherry-picked commit."
    ),
  )
  inspect(
    dump(
      "gitGraph\n commit\n branch b\n commit\n checkout main\n commit\n merge b id:\"m\"\n checkout b\n cherry-pick id:\"m\"\n",
    ),
    content=(
      #|ERR semantic gitGraph "Incorrect usage of cherry-pick: If the source commit is a merge commit, an immediate parent commit must be specified."
    ),
  )
  inspect(
    dump(
      "gitGraph\n commit\n branch b\n commit\n checkout main\n commit\n merge b id:\"m\"\n checkout b\n cherry-pick id:\"m\" parent:\"\"\n",
    ),
    content=(
      #|ERR semantic gitGraph "Incorrect usage of cherry-pick: If the source commit is a merge commit, an immediate parent commit must be specified."
    ),
  )
  inspect(
    dump("gitGraph\n commit\n branch main\n", config={
      "gitGraph": { "mainBranchName": "main" },
    }),
    content=(
      #|ERR semantic gitGraph "Trying to create an existing branch. (Help: Either use a new name if you want create a new branch or try using \"checkout main\")"
    ),
  )
}

///|
test "generated ids are Mermaid's shape: the number of the commit and seven hex digits derived from it" {
  let model = @git.build_git(
    @git.parse_git("gitGraph\ncommit\ncommit\ncommit id:\"x\"\ncommit\n"),
    {},
    None,
  )
  inspect(
    model.commits.keys().collect().join(","),
    content="0-9e3779b,1-3c6ef36,x,3-78dde6c",
  )
}

///|
test "a generated id never replaces a commit that already has it" {
  let model = @git.build_git(
    @git.parse_git("gitGraph\ncommit id:\"1-3c6ef36\"\ncommit\n"),
    {},
    None,
  )
  inspect(
    model.commits.keys().collect().join(","),
    content="1-3c6ef36,1-3c55bfc",
  )
  inspect(model.warnings.length(), content="0")
}
