// The expected graphs were taken from pele's buildStateGraph, through its parser.

///|
/// What parsing `source` into a fresh model gives: the graph built from it, or the error with its position.
fn graph_of(source : String) -> String {
  let db = @state.StateDb::new()
  ignore(@state.parse_state(source, db)) catch {
    @errors.PeleError(failure) =>
      return "error \{failure.code.to_string()} \{failure.line}:\{failure.column}\n\{failure.message}"
  }
  "ok\n" + graph_dump(db.graph)
}

///|
test "every source of Mermaid's state specs resolves into the graph pele builds" {
  let wrong = []
  for case in spec_graphs {
    let (source, expected) = case
    let actual = graph_of(source)
    if actual != expected {
      wrong.push(
        "\{source.escape()}: \{actual.escape()} instead of \{expected.escape()}",
      )
    }
  }
  inspect(wrong.join("\n"), content="")
}

///|
test "rejects a composite with description lines" {
  inspect(
    graph_of("stateDiagram-v2\nstate A {\n x\n }\n A : one\n A : two"),
    content=(
      #|error semantic 0:0
      #|Group nodes can only have label. Remove the additional description for node [A]
    ),
  )
}

///|
test "gives start and end states their own shapes in each composite" {
  inspect(
    graph_of(
      "stateDiagram-v2\n[*] --> a\n a --> [*]\n state a {\n [*] --> b\n b --> [*]\n }",
    ),
    content=(
      #|ok
      #|node "root_start" shape="stateStart" label="root_start" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "a" shape="roundedWithTitle" label="a" description=[] classes=" statediagram-state statediagram-cluster statediagram-cluster-alt" compiled=[] styles=[] type="group" group=true parent=- dir="TB" position=- noteFor=- color=0
      #|node "root_end" shape="stateEnd" label="root_end" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "a_start" shape="stateStart" label="a_start" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="a" dir=- position=- noteFor=- color=-
      #|node "b" shape="rect" label="b" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="a" dir=- position=- noteFor=- color=-
      #|node "a_end" shape="stateEnd" label="a_end" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="a" dir=- position=- noteFor=- color=-
      #|edge "edge0" "root_start" "a" "" "transition" -
      #|edge "edge1" "a" "root_end" "" "transition" -
      #|edge "edge2" "a_start" "b" "" "transition" -
      #|edge "edge3" "b" "a_end" "" "transition" -
    ),
  )
}

///|
test "puts each note in a group of its own beside its state" {
  inspect(
    graph_of(
      "stateDiagram-v2\na --> b\n note right of a : on the right\n note left of b\n first line\n second line\n end note",
    ),
    content=(
      #|ok
      #|node "a" shape="rect" label="a" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "b" shape="rect" label="b" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "a----parent" shape="noteGroup" label="on the right" description=[] classes=" statediagram-state" compiled=[] styles=[] type="group" group=true parent=- dir=- position="right of" noteFor=- color=-
      #|node "a----note-1" shape="note" label="on the right" description=[] classes="statediagram-note" compiled=[] styles=[] type="node" group=false parent="a----parent" dir=- position="right of" noteFor="a" color=-
      #|node "b----parent" shape="noteGroup" label="first line\n second line" description=[] classes=" statediagram-state" compiled=[] styles=[] type="group" group=true parent=- dir=- position="left of" noteFor=- color=-
      #|node "b----note-2" shape="note" label="first line\n second line" description=[] classes="statediagram-note" compiled=[] styles=[] type="node" group=false parent="b----parent" dir=- position="left of" noteFor="b" color=-
      #|edge "edge0" "a" "b" "" "transition" -
      #|edge "a-a----note-1" "a" "a----note-1" "" "transition note-edge" dashed
      #|edge "b----note-2-b" "b----note-2" "b" "" "transition note-edge" dashed
    ),
  )
}

///|
test "puts a note on a composite" {
  inspect(
    graph_of(
      "stateDiagram-v2\nstate A {\n x --> y\n }\n note right of A : about A",
    ),
    content=(
      #|ok
      #|node "A" shape="roundedWithTitle" label="A" description=[] classes=" statediagram-state statediagram-cluster statediagram-cluster-alt" compiled=[] styles=[] type="group" group=true parent=- dir="TB" position=- noteFor=- color=0
      #|node "x" shape="rect" label="x" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="A" dir=- position=- noteFor=- color=-
      #|node "y" shape="rect" label="y" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="A" dir=- position=- noteFor=- color=-
      #|node "A----parent" shape="noteGroup" label="about A" description=[] classes=" statediagram-state statediagram-cluster statediagram-cluster-alt" compiled=[] styles=[] type="group" group=true parent=- dir=- position="right of" noteFor=- color=-
      #|node "A----note-1" shape="note" label="about A" description=[] classes="statediagram-note" compiled=[] styles=[] type="node" group=false parent="A----parent" dir=- position="right of" noteFor="A" color=-
      #|edge "edge0" "x" "y" "" "transition" -
      #|edge "A-A----note-1" "A" "A----note-1" "" "transition note-edge" dashed
    ),
  )
}

///|
test "moves a state into the last composite that mentions it" {
  inspect(
    graph_of("stateDiagram-v2\nstate A {\n a1\n }\n state B {\n b1 --> a1\n }"),
    content=(
      #|ok
      #|node "A" shape="roundedWithTitle" label="A" description=[] classes=" statediagram-state statediagram-cluster statediagram-cluster-alt" compiled=[] styles=[] type="group" group=true parent=- dir="TB" position=- noteFor=- color=0
      #|node "a1" shape="rect" label="a1" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="B" dir=- position=- noteFor=- color=-
      #|node "B" shape="roundedWithTitle" label="B" description=[] classes=" statediagram-state statediagram-cluster statediagram-cluster-alt" compiled=[] styles=[] type="group" group=true parent=- dir="TB" position=- noteFor=- color=1
      #|node "b1" shape="rect" label="b1" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="B" dir=- position=- noteFor=- color=-
      #|edge "edge0" "b1" "a1" "" "transition" -
    ),
  )
}

///|
test "compiles class styles and keeps style statements apart" {
  inspect(
    graph_of(
      "stateDiagram-v2\nclassDef hot fill:#f00,color:white,font-weight:bold\n classDef cool stroke:#00f\n a:::cool --> b\n class b hot\n style c fill:#0f0,stroke-width:4px\n b --> c\n state G {\n g1\n }\n class G cool\n class b hot,cool\n class b missing",
    ),
    content=(
      #|ok
      #|node "a" shape="rect" label="a" description=[] classes="cool statediagram-state" compiled=["stroke:#00f"] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "b" shape="rect" label="b" description=[] classes="hot hot,cool missing statediagram-state" compiled=["fill:#f00","color:white","font-weight:bold"] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "c" shape="rect" label="c" description=[] classes=" statediagram-state" compiled=[] styles=["fill:#0f0","stroke-width:4px"] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "G" shape="roundedWithTitle" label="G" description=[] classes="cool statediagram-state statediagram-cluster statediagram-cluster-alt" compiled=["stroke:#00f"] styles=[] type="group" group=true parent=- dir="TB" position=- noteFor=- color=-
      #|node "g1" shape="rect" label="g1" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="G" dir=- position=- noteFor=- color=-
      #|edge "edge0" "a" "b" "" "transition" -
      #|edge "edge1" "b" "c" "" "transition" -
    ),
  )
}

///|
test "shapes stereotypes and described states" {
  inspect(
    graph_of(
      "stateDiagram-v2\nstate c <<choice>>\n state f <<fork>>\n state j [[join]]\n [*] --> f\n f --> x\n x --> j\n j --> c\n c --> p : yes\n s1 : Title\n s1 : first\n s1 : second\n state \"Long\" as s2\n s3 : only",
    ),
    content=(
      #|ok
      #|node "c" shape="choice" label="c" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "f" shape="fork" label="f" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "j" shape="join" label="j" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "root_start" shape="stateStart" label="root_start" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "x" shape="rect" label="x" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "p" shape="rect" label="p" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "s1" shape="rectWithTitle" label="Title" description=["first","second"] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "s2" shape="rect" label="Long" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "s3" shape="rect" label="only" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|edge "edge0" "root_start" "f" "" "transition" -
      #|edge "edge1" "f" "x" "" "transition" -
      #|edge "edge2" "x" "j" "" "transition" -
      #|edge "edge3" "j" "c" "" "transition" -
      #|edge "edge4" "c" "p" "yes" "transition" -
    ),
  )
}

///|
test "gives a composite a title and description shape" {
  inspect(
    graph_of(
      "stateDiagram-v2\nstate \"Title\" as A {\n x\n }\n state B {\n y\n }\n B : only one",
    ),
    content=(
      #|ok
      #|node "A" shape="roundedWithTitle" label="Title" description=[] classes=" statediagram-state statediagram-cluster statediagram-cluster-alt" compiled=[] styles=[] type="group" group=true parent=- dir="TB" position=- noteFor=- color=0
      #|node "x" shape="rect" label="x" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="A" dir=- position=- noteFor=- color=-
      #|node "B" shape="roundedWithTitle" label="only one" description=[] classes=" statediagram-state statediagram-cluster statediagram-cluster-alt" compiled=[] styles=[] type="group" group=true parent=- dir="TB" position=- noteFor=- color=1
      #|node "y" shape="rect" label="y" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="B" dir=- position=- noteFor=- color=-
    ),
  )
}

///|
test "shares a composite's palette slot with its regions" {
  inspect(
    graph_of(
      "stateDiagram-v2\nstate A {\n a1\n --\n b1\n }\n state B {\n state C {\n c1\n --\n c2\n }\n }\n classDef k fill:red\n state D {\n d\n }\n class D k",
    ),
    content=(
      #|ok
      #|node "A" shape="roundedWithTitle" label="A" description=[] classes=" statediagram-state statediagram-cluster statediagram-cluster-alt" compiled=[] styles=[] type="group" group=true parent=- dir="TB" position=- noteFor=- color=0
      #|node "divider-id-1" shape="divider" label="" description=[] classes=" statediagram-state statediagram-cluster " compiled=[] styles=[] type="group" group=true parent="A" dir="TB" position=- noteFor=- color=0
      #|node "a1" shape="rect" label="a1" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="divider-id-1" dir=- position=- noteFor=- color=-
      #|node "divider-id-3" shape="divider" label="" description=[] classes=" statediagram-state statediagram-cluster " compiled=[] styles=[] type="group" group=true parent="A" dir="TB" position=- noteFor=- color=0
      #|node "b1" shape="rect" label="b1" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="divider-id-3" dir=- position=- noteFor=- color=-
      #|node "B" shape="roundedWithTitle" label="B" description=[] classes=" statediagram-state statediagram-cluster statediagram-cluster-alt" compiled=[] styles=[] type="group" group=true parent=- dir="TB" position=- noteFor=- color=1
      #|node "C" shape="roundedWithTitle" label="C" description=[] classes=" statediagram-state statediagram-cluster " compiled=[] styles=[] type="group" group=true parent="B" dir="TB" position=- noteFor=- color=2
      #|node "divider-id-2" shape="divider" label="" description=[] classes=" statediagram-state statediagram-cluster statediagram-cluster-alt" compiled=[] styles=[] type="group" group=true parent="C" dir="TB" position=- noteFor=- color=2
      #|node "c1" shape="rect" label="c1" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="divider-id-2" dir=- position=- noteFor=- color=-
      #|node "divider-id-4" shape="divider" label="" description=[] classes=" statediagram-state statediagram-cluster statediagram-cluster-alt" compiled=[] styles=[] type="group" group=true parent="C" dir="TB" position=- noteFor=- color=2
      #|node "c2" shape="rect" label="c2" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="divider-id-4" dir=- position=- noteFor=- color=-
      #|node "D" shape="roundedWithTitle" label="D" description=[] classes="k statediagram-state statediagram-cluster statediagram-cluster-alt" compiled=["fill:red"] styles=[] type="group" group=true parent=- dir="TB" position=- noteFor=- color=-
      #|node "d" shape="rect" label="d" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="D" dir=- position=- noteFor=- color=-
    ),
  )
}

///|
test "alternates cluster classes with depth" {
  inspect(
    graph_of(
      "stateDiagram-v2\nstate A {\n state B {\n state C {\n x\n }\n }\n }",
    ),
    content=(
      #|ok
      #|node "A" shape="roundedWithTitle" label="A" description=[] classes=" statediagram-state statediagram-cluster statediagram-cluster-alt" compiled=[] styles=[] type="group" group=true parent=- dir="TB" position=- noteFor=- color=0
      #|node "B" shape="roundedWithTitle" label="B" description=[] classes=" statediagram-state statediagram-cluster " compiled=[] styles=[] type="group" group=true parent="A" dir="TB" position=- noteFor=- color=1
      #|node "C" shape="roundedWithTitle" label="C" description=[] classes=" statediagram-state statediagram-cluster statediagram-cluster-alt" compiled=[] styles=[] type="group" group=true parent="B" dir="TB" position=- noteFor=- color=2
      #|node "x" shape="rect" label="x" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="C" dir=- position=- noteFor=- color=-
    ),
  )
}

///|
test "takes a composite's direction from its last direction statement" {
  inspect(
    graph_of(
      "stateDiagram-v2\nstate A {\n direction LR\n x\n direction BT\n }\n state B {\n y\n }",
    ),
    content=(
      #|ok
      #|node "A" shape="roundedWithTitle" label="A" description=[] classes=" statediagram-state statediagram-cluster statediagram-cluster-alt" compiled=[] styles=[] type="group" group=true parent=- dir="BT" position=- noteFor=- color=0
      #|node "x" shape="rect" label="x" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="A" dir=- position=- noteFor=- color=-
      #|node "B" shape="roundedWithTitle" label="B" description=[] classes=" statediagram-state statediagram-cluster statediagram-cluster-alt" compiled=[] styles=[] type="group" group=true parent=- dir="TB" position=- noteFor=- color=1
      #|node "y" shape="rect" label="y" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="B" dir=- position=- noteFor=- color=-
    ),
  )
}

///|
test "merges a note's group into a state of the same name" {
  inspect(
    graph_of(
      "stateDiagram-v2\nnote right of a : n\nstate \"x\" as a----parent\nstate \"y\" as a----note-0\nstate \"w\" as b\nnote left of b : m\nstate \"v\" as b----note-1",
    ),
    content=(
      #|ok
      #|node "a----parent" shape="rect" label="x" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position="right of" noteFor=- color=-
      #|node "a----note-0" shape="rect" label="y" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="a----parent" dir=- position="right of" noteFor="a" color=-
      #|node "a" shape=- label="a" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "b" shape="rect" label="w" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "b----parent" shape="noteGroup" label="m" description=[] classes=" statediagram-state" compiled=[] styles=[] type="group" group=true parent=- dir=- position="left of" noteFor=- color=-
      #|node "b----note-1" shape="rect" label="v" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="b----parent" dir=- position="left of" noteFor="b" color=-
      #|edge "a-a----note-0" "a" "a----note-0" "" "transition note-edge" dashed
      #|edge "b----note-1-b" "b----note-1" "b" "" "transition note-edge" dashed
    ),
  )
}

///|
test "skips the ids Mermaid's sanitizer empties" {
  inspect(
    graph_of("stateDiagram-v2\nstate \"x\" as </choice>\na --> b"),
    content=(
      #|ok
      #|node "a" shape="rect" label="a" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "b" shape="rect" label="b" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|edge "edge0" "a" "b" "" "transition" -
    ),
  )
}

///|
test "numbers edges and notes with one counter" {
  inspect(
    graph_of(
      "stateDiagram-v2\na --> b\nnote right of a : n1\nb --> c : go\nnote left of c : n2\nnote right of a : n3",
    ),
    content=(
      #|ok
      #|node "a" shape="rect" label="a" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "b" shape="rect" label="b" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "a----parent" shape="noteGroup" label="n3" description=[] classes=" statediagram-state" compiled=[] styles=[] type="group" group=true parent=- dir=- position="right of" noteFor=- color=-
      #|node "a----note-1" shape="note" label="n1" description=[] classes="statediagram-note" compiled=[] styles=[] type="node" group=false parent="a----parent" dir=- position="right of" noteFor="a" color=-
      #|node "c" shape="rect" label="c" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "c----parent" shape="noteGroup" label="n2" description=[] classes=" statediagram-state" compiled=[] styles=[] type="group" group=true parent=- dir=- position="left of" noteFor=- color=-
      #|node "c----note-3" shape="note" label="n2" description=[] classes="statediagram-note" compiled=[] styles=[] type="node" group=false parent="c----parent" dir=- position="left of" noteFor="c" color=-
      #|node "a----note-4" shape="note" label="n3" description=[] classes="statediagram-note" compiled=[] styles=[] type="node" group=false parent="a----parent" dir=- position="right of" noteFor="a" color=-
      #|edge "edge0" "a" "b" "" "transition" -
      #|edge "a-a----note-1" "a" "a----note-1" "" "transition note-edge" dashed
      #|edge "edge2" "b" "c" "go" "transition" -
      #|edge "c----note-3-c" "c----note-3" "c" "" "transition note-edge" dashed
      #|edge "a-a----note-4" "a" "a----note-4" "" "transition note-edge" dashed
    ),
  )
}

///|
test "keeps a stereotype given after the first use as a plain state" {
  inspect(
    graph_of("stateDiagram-v2\na --> c\n state c <<choice>>"),
    content=(
      #|ok
      #|node "a" shape="rect" label="a" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "c" shape="rect" label="c" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|edge "edge0" "a" "c" "" "transition" -
    ),
  )
}

///|
test "labels transitions, including those to self and across composite borders" {
  inspect(
    graph_of(
      "stateDiagram-v2\nstate A {\n in1 --> in2 : inner\n in2 --> in2 : again\n }\n out --> in1 : cross\n A --> A : whole\n A --> in1 : enter\n in2 --> A : leave",
    ),
    content=(
      #|ok
      #|node "A" shape="roundedWithTitle" label="A" description=[] classes=" statediagram-state statediagram-cluster statediagram-cluster-alt" compiled=[] styles=[] type="group" group=true parent=- dir="TB" position=- noteFor=- color=0
      #|node "in1" shape="rect" label="in1" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="A" dir=- position=- noteFor=- color=-
      #|node "in2" shape="rect" label="in2" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent="A" dir=- position=- noteFor=- color=-
      #|node "out" shape="rect" label="out" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|edge "edge0" "in1" "in2" "inner" "transition" -
      #|edge "edge1" "in2" "in2" "again" "transition" -
      #|edge "edge2" "out" "in1" "cross" "transition" -
      #|edge "edge3" "A" "A" "whole" "transition" -
      #|edge "edge4" "A" "in1" "enter" "transition" -
      #|edge "edge5" "in2" "A" "leave" "transition" -
    ),
  )
}

///|
test "draws composites that contain each other" {
  inspect(
    graph_of(
      "stateDiagram-v2\nstate a0{\nstate a1{\n}\n}\nstate a1{\nstate a0{\n}\n}\n",
    ),
    content=(
      #|ok
      #|node "a0" shape="roundedWithTitle" label="a0" description=[] classes=" statediagram-state statediagram-cluster statediagram-cluster-alt" compiled=[] styles=[] type="group" group=true parent="a1" dir="TB" position=- noteFor=- color=0
      #|node "a1" shape="roundedWithTitle" label="a1" description=[] classes=" statediagram-state statediagram-cluster " compiled=[] styles=[] type="group" group=true parent="a0" dir="TB" position=- noteFor=- color=1
    ),
  )
}

///|
test "reads a composite named root" {
  inspect(
    graph_of("stateDiagram-v2\nstate root {\n a --> b\n}\nroot --> root\n"),
    content=(
      #|ok
      #|node "a" shape="rect" label="a" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "b" shape="rect" label="b" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|edge "edge0" "a" "b" "" "transition" -
      #|edge "edge1" "root" "root" "" "transition" -
    ),
  )
}

///|
test "reads a note on a start state" {
  inspect(
    graph_of("stateDiagram-v2\n[*] --> a\nnote right of [*] : x\n"),
    content=(
      #|ok
      #|node "root_start" shape="stateStart" label="root_start" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "a" shape="rect" label="a" description=[] classes=" statediagram-state" compiled=[] styles=[] type=- group=false parent=- dir=- position=- noteFor=- color=-
      #|node "root_start----parent" shape="noteGroup" label="x" description=[] classes=" statediagram-state" compiled=[] styles=[] type="group" group=true parent=- dir=- position="right of" noteFor=- color=-
      #|node "root_start----note-1" shape="note" label="x" description=[] classes="statediagram-note" compiled=[] styles=[] type="node" group=false parent="root_start----parent" dir=- position="right of" noteFor="root_start" color=-
      #|edge "edge0" "root_start" "a" "" "transition" -
      #|edge "root_start-root_start----note-1" "root_start" "root_start----note-1" "" "transition note-edge" dashed
    ),
  )
}
