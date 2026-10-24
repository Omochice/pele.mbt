///|
fn quoted(value : String?) -> String {
  match value {
    Some(text) => text.escape()
    None => "-"
  }
}

///|
fn number_or_dash(value : Double?) -> String {
  match value {
    Some(n) => n.to_string()
    None => "-"
  }
}

///|
fn flow_text(flow : @wardley.Flow?) -> String {
  match flow {
    Some(Forward) => "\"forward\""
    Some(Backward) => "\"backward\""
    Some(Bidirectional) => "\"bidirectional\""
    None => "-"
  }
}

///|
/// The model of `src` in the form the expected outputs were taken from pele in, or the error.
fn model(src : String, title : String?) -> String {
  let m = @wardley.build_wardley(@wardley.parse_wardley(src), title) catch {
    @errors.PeleError(failure) => return failure.message
  }
  let lines = [
    "title=\{quoted(m.title)} accTitle=\{quoted(m.acc_title)} accDescr=\{quoted(m.acc_descr)}",
  ]
  if m.size is Some((width, height)) {
    lines.push("size \{width} \{height}")
  }
  let stages = match m.stages {
    Some(names) => names.map(s => s.escape()).join(",")
    None => "-"
  }
  let boundaries = match m.stage_boundaries {
    Some(edges) => edges.map(b => b.to_string()).join(",")
    None => "-"
  }
  lines.push("axes stages=\{stages} boundaries=\{boundaries}")
  for n in m.nodes {
    let in_pipeline = if n.in_pipeline { " inPipeline" } else { "" }
    let parent = if n.is_pipeline_parent { " parent" } else { "" }
    let inertia = if n.inertia { " inertia" } else { "" }
    let strategy = n.source_strategy.map(s => " " + s).unwrap_or("")
    lines.push(
      "node \{n.id.escape()} \{n.label.escape()} \{n.x} \{n.y} \{n.class_name.escape()} offset=\{number_or_dash(n.label_offset_x)},\{number_or_dash(n.label_offset_y)}\{in_pipeline}\{parent}\{inertia}\{strategy}",
    )
  }
  for l in m.links {
    let dashed = if l.dashed { " dashed" } else { "" }
    lines.push(
      "link \{l.source.escape()} \{l.target.escape()}\{dashed} \{flow_text(l.flow)} \{quoted(l.label)}",
    )
  }
  for t in m.trends {
    lines.push("trend \{t.node_id.escape()} \{t.target_x} \{t.target_y}")
  }
  for p in m.pipelines {
    lines.push(
      "pipeline \{p.node_id.escape()} [\{p.component_ids.map(id => id.escape()).join(",")}]",
    )
  }
  for a in m.annotations {
    lines.push("annotation \{a.number} \{a.x},\{a.y} \{a.text.escape()}")
  }
  for n in m.notes {
    lines.push("note \{n.text.escape()} \{n.x} \{n.y}")
  }
  for n in m.accelerators {
    lines.push("accelerator \{n.name.escape()} \{n.x} \{n.y}")
  }
  for n in m.deaccelerators {
    lines.push("deaccelerator \{n.name.escape()} \{n.x} \{n.y}")
  }
  if m.annotations_box is Some((x, y)) {
    lines.push("box \{x} \{y}")
  }
  lines.join("\n")
}

///|
fn check_models(cases : Array[(String, String?, String)]) -> Unit raise {
  for case in cases {
    let (src, title, expected) = case
    assert_eq(model(src, title), expected, msg=src)
  }
}

///|
test "nodes, links, trends, pipelines, and the rest in percentages" {
  check_models([
    (
      "wardley-beta\ntitle Tea Shop\nanchor Business [0.95, 0.63]\ncomponent Cup of Tea [0.79, 0.61]\ncomponent Kettle [0.43, 0.35]\ncomponent Power [0.10, 0.70]\nBusiness -> Cup of Tea\nCup of Tea -> Kettle\nKettle -> Power\nevolve Kettle 0.62\nevolve Power 0.89\nevolve Missing 0.5\nevolve Kettle 0.7\nnote \"Standardising power\" [0.30, 0.49]\n",
      None,
      "title=\"Tea Shop\" accTitle=- accDescr=-\naxes stages=- boundaries=-\nnode \"Business\" \"Business\" 63 95 \"anchor\" offset=-,-\nnode \"Cup of Tea\" \"Cup of Tea\" 61 79 \"component\" offset=-,-\nnode \"Kettle\" \"Kettle\" 35 43 \"component\" offset=-,-\nnode \"Power\" \"Power\" 70 10 \"component\" offset=-,-\nlink \"Business\" \"Cup of Tea\" - -\nlink \"Cup of Tea\" \"Kettle\" - -\nlink \"Kettle\" \"Power\" - -\ntrend \"Kettle\" 70 43\ntrend \"Power\" 89 10\nnote \"Standardising power\" 49 30",
    ),
    (
      "wardley-beta\nevolution Genesis / Concept -> Custom@0.5 / Emerging -> Product@0.9 -> Utility@1.0\ncomponent A [90.0, 80.0] (market) inertia\nanchor A [0.5, 0.5]\ncomponent A [0.4, 0.3] label [-10, 20]\nanchor B [0.1, 0.1]\ncomponent B [0.2, 0.2] label [5, -5] (buy)\nanchor B [0.3, 0.3]\n",
      None,
      "title=- accTitle=- accDescr=-\naxes stages=\"Genesis / Concept\",\"Custom / Emerging\",\"Product\",\"Utility\" boundaries=0.5,0.9,1\nnode \"A\" \"A\" 30 40 \"component\" offset=-10,20\nnode \"B\" \"B\" 20 20 \"component\" offset=5,-5 buy",
    ),
    (
      "wardley-beta\ncomponent Kettle [0.45, 0.57] (buy) inertia\ncomponent Water [0.8, 0.8]\npipeline Kettle {\n  component Campfire Kettle [0.35] label [-60, 35]\n  component Electric Kettle [0.53]\n}\nWater -> Electric Kettle\nCampfire Kettle -> Kettle\nKettle_Campfire Kettle -> Water\n",
      None,
      "title=- accTitle=- accDescr=-\naxes stages=- boundaries=-\nnode \"Kettle\" \"Kettle\" 56.99999999999999 45 \"component\" offset=-,- parent inertia buy\nnode \"Water\" \"Water\" 80 80 \"component\" offset=-,-\nnode \"Kettle_Campfire Kettle\" \"Campfire Kettle\" 35 45 \"pipeline-component\" offset=-60,35 inPipeline\nnode \"Kettle_Electric Kettle\" \"Electric Kettle\" 53 45 \"pipeline-component\" offset=-,- inPipeline\nlink \"Water\" \"Kettle_Electric Kettle\" - -\nlink \"Kettle_Campfire Kettle\" \"Kettle\" - -\nlink \"Kettle_Campfire Kettle\" \"Water\" - -\npipeline \"Kettle\" [\"Kettle_Campfire Kettle\",\"Kettle_Electric Kettle\"]",
    ),
    (
      "wardley-beta\ncomponent P [0.5, 0.5]\npipeline P {\n component x [0.2]\n}\npipeline P {\n component y [0.3]\n}\ncomponent Q [0.6, 0.6]\npipeline Q {\n component Q [0.4]\n}\ncomponent R [0.7, 0.7]\ncomponent R_x [0.1, 0.1]\npipeline R {\n component x [0.9] label [1, 2]\n}\n",
      None,
      "title=- accTitle=- accDescr=-\naxes stages=- boundaries=-\nnode \"P\" \"P\" 50 50 \"component\" offset=-,- parent\nnode \"Q\" \"Q\" 60 60 \"component\" offset=-,- parent\nnode \"R\" \"R\" 70 70 \"component\" offset=-,- parent\nnode \"R_x\" \"x\" 90 70 \"pipeline-component\" offset=1,2 inPipeline\nnode \"P_x\" \"x\" 20 50 \"pipeline-component\" offset=-,- inPipeline\nnode \"P_y\" \"y\" 30 50 \"pipeline-component\" offset=-,- inPipeline\nnode \"Q_Q\" \"Q\" 40 60 \"pipeline-component\" offset=-,- inPipeline\npipeline \"P\" [\"P_y\"]\npipeline \"Q\" [\"Q_Q\"]\npipeline \"R\" [\"R_x\"]",
    ),
    (
      "wardley-beta\ncomponent \"Mobile App\" [0.2, 0.4] (build) (inertia)\ncomponent API [0.3, 0.5]\n\"Mobile App\" +<> API; constraint\nAPI +> \"Mobile App\" +<\nAPI +'cash'<> \"Mobile App\"; ignored\nAPI +''> X; kept\nAPI -.-> X\nAPI --> X +>\nAPI +'a'< X\nAPI > X\nnote \"Check dependencies\" [0.25, 0.45]\nannotations [0.10, 0.90]\nannotations [0.5, 0.5]\nannotation 2,[0.60, 0.65] \"Critical component\"\nannotation 1,[60, 65] ''\naccelerator \"Cloud Native\" [0.20, 0.85]\ndeaccelerator \"Legacy Data\" [0.40, 0.35]\nsize [1200, 900]\nsize [0, 7]\n",
      None,
      "title=- accTitle=- accDescr=-\nsize 0 7\naxes stages=- boundaries=-\nnode \"Mobile App\" \"Mobile App\" 40 20 \"component\" offset=-,- inertia build\nnode \"API\" \"API\" 50 30 \"component\" offset=-,-\nlink \"Mobile App\" \"API\" \"bidirectional\" \"constraint\"\nlink \"API\" \"Mobile App\" \"forward\" -\nlink \"API\" \"Mobile App\" \"bidirectional\" \"cash\"\nlink \"API\" \"X\" \"forward\" \"\"\nlink \"API\" \"X\" dashed - -\nlink \"API\" \"X\" \"forward\" -\nlink \"API\" \"X\" \"backward\" \"a\"\nlink \"API\" \"X\" - -\nannotation 2 65,60 \"Critical component\"\nannotation 1 65,60 \"\"\nnote \"Check dependencies\" 45 25\naccelerator \"Cloud Native\" 85 20\ndeaccelerator \"Legacy Data\" 35 40\nbox 90 10",
    ),
  ])
}

///|
test "the front matter title is used when the map has none, and accessible texts lose their indents" {
  check_models([
    (
      "wardley-beta\naccTitle:   Acc\naccDescr {\n  multi\n    line\n\n  end\n}\n",
      Some("Front"),
      "title=\"Front\" accTitle=\"Acc\" accDescr=\"multi\\nline\\nend\"\naxes stages=- boundaries=-",
    ),
    (
      "wardley-beta\ntitle Own\naccTitle:\naccDescr:\n",
      Some("Front"),
      "title=\"Own\" accTitle=- accDescr=-\naxes stages=- boundaries=-",
    ),
    (
      "wardley-beta\nevolution A -> B\nevolution C@0.5 -> D\n",
      None,
      "title=- accTitle=- accDescr=-\naxes stages=\"C\",\"D\" boundaries=0.5",
    ),
  ])
}

///|
test "coordinates outside both ranges are rejected with Mermaid's messages" {
  check_models([
    (
      "wardley-beta\ncomponent A [150.5, 0.5]\n",
      None,
      "Component \"A\" visibility must be between 0-1 (decimal) or 0-100 (percentage). Received: 150.5",
    ),
    (
      "wardley-beta\ncomponent A [0.5, 101.0]\n",
      None,
      "Component \"A\" evolution must be between 0-1 (decimal) or 0-100 (percentage). Received: 101",
    ),
    (
      "wardley-beta\nanchor A [0.5, 999999999999999999999.0]\n",
      None,
      "Anchor \"A\" evolution must be between 0-1 (decimal) or 0-100 (percentage). Received: 1e+21",
    ),
    (
      "wardley-beta\npipeline Nope {\n component A [0.5]\n}\n",
      None,
      "Pipeline \"Nope\" must reference an existing component with coordinates.",
    ),
    (
      "wardley-beta\ncomponent P [0.5, 0.5]\npipeline P {\n component A [100.5]\n}\n",
      None,
      "Pipeline component \"A\" evolution must be between 0-1 (decimal) or 0-100 (percentage). Received: 100.5",
    ),
    (
      "wardley-beta\nnote \"n\" [0.5, 200.0]\n",
      None,
      "Note \"n\" evolution must be between 0-1 (decimal) or 0-100 (percentage). Received: 200",
    ),
    (
      "wardley-beta\ncomponent A [0.5, 0.5]\nevolve A 100.5\n",
      None,
      "Evolve target for \"A\" must be between 0-1 (decimal) or 0-100 (percentage). Received: 100.5",
    ),
    (
      "wardley-beta\nannotations [0.5, 101]\n",
      None,
      "Annotations box evolution must be between 0-1 (decimal) or 0-100 (percentage). Received: 101",
    ),
    (
      "wardley-beta\nannotation 3,[0.5, 101] \"x\"\n",
      None,
      "Annotation 3 evolution must be between 0-1 (decimal) or 0-100 (percentage). Received: 101",
    ),
    (
      "wardley-beta\naccelerator Go [0.5, 101.0]\n",
      None,
      "Accelerator \"Go\" evolution must be between 0-1 (decimal) or 0-100 (percentage). Received: 101",
    ),
    (
      "wardley-beta\ndeaccelerator Stop [101.0, 0.5]\n",
      None,
      "Deaccelerator \"Stop\" visibility must be between 0-1 (decimal) or 0-100 (percentage). Received: 101",
    ),
  ])
}

///|
test "building matches pele on the corpus and its mutations" {
  inspect(
    fnv1a(corpus_sources().map(src => model(src, None)).join("\n\n")),
    content="cec1f2bb",
  )
}
