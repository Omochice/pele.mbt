///|
fn entry(
  source : String,
  config : Map[String, Json],
  title : String?,
  max_edges : Int32,
) -> String {
  let db = @flowchart.parse_model(source, config, title, { max_edges, }) catch {
    @errors.PeleError(failure) => {
      let kind = failure.kind.unwrap_or("-")
      return "error \{failure.code.to_string()} \{kind} \{failure.message}"
    }
  }
  dump(db)
}

///|
let subgraph_source : String = "graph LR\nsubgraph S\nA\nend\n"

///|
test "the title from front matter becomes the model's title" {
  inspect(
    entry(subgraph_source, {}, Some("My title"), 10),
    content=(
      #|dir "LR"
      #|title "My title"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|subgraph "S" title="S" lt=text dir=- nodes=["A"] classes=[] metadata=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
}

///|
test "subgraphs take the chart's direction only when inheritDir is true" {
  inspect(
    entry(subgraph_source, { "flowchart": { "inheritDir": true } }, None, 10),
    content=(
      #|dir "LR"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|subgraph "S" title="S" lt=text dir="LR" nodes=["A"] classes=[] metadata=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
  inspect(
    entry(
      subgraph_source,
      { "flowchart": { "inheritDir": "true" } },
      Some(""),
      10,
    ),
    content=(
      #|dir "LR"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|subgraph "S" title="S" lt=text dir=- nodes=["A"] classes=[] metadata=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
}

///|
test "more edges than maxEdges is a limit error" {
  inspect(
    entry("graph TD\nA-->B-->C-->D\n", {}, None, 2),
    content="error limit flowchart Edge limit exceeded. 2 edges found, but the limit is 2.",
  )
  inspect(
    entry("graph TD\nA & B --> C & D & E\n", {}, None, 4),
    content="error limit flowchart Edge limit exceeded. 4 edges found, but the limit is 4.",
  )
}

///|
test "exactly maxEdges edges are allowed" {
  inspect(
    entry("graph TD\nA & B --> C & D\n", {}, None, 4),
    content=(
      #|dir "TB"
      #|node "A" text="A" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "B" text="B" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "C" text="C" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|node "D" text="D" lt=text type=- styles=[] classes=[] dir=- props={} link=- target=- icon=- form=- pos=- img=- constraint=- w=- h=-
      #|edge "A" "C" id="L_A_C_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "A" "D" id="L_A_D_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "B" "C" id="L_B_C_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|edge "B" "D" id="L_B_D_0" user=false type="arrow_point" text="" lt=text stroke="normal" length=1 style=- classes=[] interpolate=- animate=- animation=-
      #|defaultStyle=- defaultInterpolate=-
    ),
  )
}
