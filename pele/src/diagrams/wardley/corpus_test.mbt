///|
/// Mermaid's documentation examples, from pele's corpus.
let docs : Array[String] = [
  "wardley-beta\ntitle Tea Shop Value Chain\n\nanchor Business [0.95, 0.63]\ncomponent Cup of Tea [0.79, 0.61]\ncomponent Tea [0.63, 0.81]\ncomponent Hot Water [0.52, 0.80]\ncomponent Kettle [0.43, 0.35]\ncomponent Power [0.10, 0.70]\n\nBusiness -> Cup of Tea\nCup of Tea -> Tea\nCup of Tea -> Hot Water\nHot Water -> Kettle\nKettle -> Power\n\nevolve Kettle 0.62\nevolve Power 0.89\n\nnote \"Standardising power allows Kettles to evolve faster\" [0.30, 0.49]\n",
  "wardley-beta\ntitle Your Map Title\nsize [1100, 600]\n", "wardley-beta\ntitle Coordinate Examples\n\ncomponent Infrastructure [0.30, 0.20]        %% Low visibility, low evolution\ncomponent Product [0.70, 0.60]               %% High visibility, mid evolution\ncomponent User Need [0.90, 0.95]             %% High visibility, high evolution\n",
  "wardley-beta\ntitle Components\n\ncomponent API [0.60, 0.70]\ncomponent Database [0.40, 0.85] label [-50, 10]\ncomponent \"Custom Service\" [0.55, 0.35]\n",
  "wardley-beta\ntitle Hyphenated Names\n\ncomponent real-time processing [0.55, 0.40]\ncomponent end-user [0.90, 0.95]\n\nend-user -> real-time processing\n",
  "wardley-beta\ntitle Anchors\n\nanchor Customer [0.90, 0.95]\nanchor Business [0.85, 0.90]\n\ncomponent Service [0.70, 0.75]\n\nCustomer -> Service\nBusiness -> Service\n",
  "wardley-beta\ntitle Inertia\n\ncomponent Legacy System [0.45, 0.40] (inertia)\ncomponent New Platform [0.65, 0.45]\n\nLegacy System -> New Platform\n",
  "wardley-beta\ntitle Sourcing Strategy\n\nanchor Customer [0.80, 0.95]\ncomponent Custom App [0.45, 0.85] (build)\ncomponent Off-the-shelf Tool [0.85, 0.65] (buy)\ncomponent Managed Service [0.60, 0.40] (outsource)\ncomponent Cloud Platform [0.95, 0.25] (market)\n\nCustomer -> Custom App\nCustom App -> Off-the-shelf Tool\nCustom App -> Managed Service\nOff-the-shelf Tool -> Cloud Platform\n",
  "wardley-beta\ntitle Link Types\n\ncomponent User [0.90, 0.95]\ncomponent App [0.75, 0.75]\ncomponent API [0.60, 0.60]\ncomponent Cache [0.65, 0.45]\ncomponent Database [0.15, 0.80]\n\nUser -> App\nApp +> API\nAPI -> Database\nAPI +<> Cache\nCache +'backup'> Database\n",
  "wardley-beta\ntitle Evolution\n\ncomponent Database [0.40, 0.50]\ncomponent API [0.55, 0.60]\n\nDatabase -> API\n\nevolve Database 0.75\nevolve API 0.80\n",
  "wardley-beta\ntitle Pipeline Evolution\n\ncomponent Database [0.40, 0.60]\n\npipeline Database {\n  component \"File System\" [0.25]\n  component \"SQL DB\" [0.50]\n  component \"NoSQL\" [0.70]\n  component \"Cloud DB\" [0.85]\n}\n",
  "wardley-beta\ntitle Custom Stages\n\nevolution Unmodelled -> Divergent -> Convergent -> Modelled\n\ncomponent Raw Data [0.15, 0.20]\ncomponent Analysis [0.45, 0.50]\ncomponent Reports [0.75, 0.70]\n",
  "wardley-beta\ntitle Dual Label Stages\n\nevolution Genesis / Concept -> Custom / Emerging -> Product / Converging -> Commodity / Accepted\n\ncomponent Novel Idea [0.05, 0.20]\ncomponent Custom Solution [0.35, 0.50]\ncomponent Product [0.65, 0.70]\ncomponent Utility [0.95, 0.90]\n",
  "wardley-beta\ntitle Custom Widths\n\nevolution Genesis@0.2 -> Custom@0.4 -> Product@0.75 -> Commodity@1.0\n\ncomponent Novel [0.75, 0.15]\ncomponent Bespoke [0.70, 0.35]\ncomponent Product [0.65, 0.65]\ncomponent Utility [0.60, 0.90]\n",
  "wardley-beta\ntitle Notes\n\ncomponent API [0.60, 0.70]\ncomponent Database [0.40, 0.50]\n\nAPI -> Database\n\nnote \"Critical decision point\" [0.65, 0.55]\nnote \"High risk area\" [0.40, 0.35]\n",
  "wardley-beta\ntitle Annotations\n\ncomponent API [0.60, 0.70]\ncomponent Cache [0.50, 0.55]\ncomponent Database [0.40, 0.40]\n\nAPI -> Cache\nCache -> Database\n\nannotations [0.10, 0.90]\nannotation 1,[0.60, 0.65] \"Critical component\"\nannotation 2,[0.50, 0.50] \"Performance layer\"\nannotation 3,[0.40, 0.35] \"Data persistence\"\n",
  "wardley-beta\ntitle Forces\n\ncomponent Legacy [0.20, 0.85]\ncomponent Modern [0.55, 0.60]\ncomponent AI [0.70, 0.35]\n\nLegacy -> Modern\nModern -> AI\n\naccelerator \"AI Adoption\" [0.55, 0.25]\ndeaccelerator \"Legacy Constraints\" [0.15, 0.75]\n",
  "wardley-beta\ntitle Custom Size\nsize [800, 1000]\n", "wardley-beta\ntitle Software Platform Strategy\nsize [1100, 800]\n\nevolution Genesis@0.25 -> Custom@0.5 -> Product@0.75 -> Commodity@1.0\n\nanchor Customer [0.90, 0.95]\n\ncomponent \"Mobile App\" [0.80, 0.85] (build)\ncomponent \"Web App\" [0.75, 0.80] label [-60, 10] (build)\ncomponent \"API Gateway\" [0.70, 0.65] (buy)\ncomponent \"Auth Service\" [0.60, 0.55] (outsource)\ncomponent \"Database\" [0.50, 0.45] (buy) (inertia)\ncomponent \"Cloud Platform\" [0.30, 0.95] (market)\n\nCustomer -> \"Mobile App\"\nCustomer -> \"Web App\"\n\"Mobile App\" -> \"API Gateway\"\n\"Web App\" -> \"API Gateway\"\n\"API Gateway\" -> \"Auth Service\"\n\"API Gateway\" -> \"Database\"\n\"Database\" -> \"Cloud Platform\"\n\nevolve \"API Gateway\" 0.85\nevolve \"Database\" 0.75\n\naccelerator \"Cloud Native\" [0.20, 0.85]\ndeaccelerator \"Legacy Data\" [0.45, 0.35]\n\nannotations [0.10, 0.20]\nannotation 1,[0.78, 0.82] \"User touchpoints\"\nannotation 2,[0.70, 0.60] \"Integration layer\"\nannotation 3,[0.50, 0.40] \"Data persistence\"\n\nnote \"Build mobile-first experience\" [0.85, 0.90]\nnote \"Migrate to cloud-native database\" [0.60, 0.50]\n",
]

///|
/// Seeds pele's oracle test writes so that each part of the grammar is covered.
let valid : Array[String] = [
  "wardley-beta", "wardley-beta title T\n", "\n\nwardley-beta\naccTitle: A\naccDescr {\n multi\n line\n}\ntitle T\n",
  "wardley-beta\nsize [800, 600]\nevolution \"A b\"@0.25 / c -> B@0.5 -> C_1@0.75 / \"d e\" -> D@1.0\n",
  "wardley-beta\ncomponent A [0.5, 0.5] label [-10, 5] (build) (inertia)\ncomponent B [0.1, 0.9] inertia\ncomponent \"C d\" [0.3, 0.3] (market)\n",
  "wardley-beta\ncomponent A [0.5, 0.5] label [10, -5] (inertia)\ncomponent _b [0.1, 0.9] (buy) inertia\ncomponent _9 [0.3, 0.3] (outsource)\n",
  "wardley-beta\ncomponent A [0.5, 0.5]\npipeline A {\n\n  component X [0.2] label [1, -2]\n\n  component \"Y z\" [0.8]\n}\n",
  "wardley-beta\nA -> B\nA --> B\nA -.-> B; dashed\n", "wardley-beta\nA +> B\nA +< B\nA +<> B\n",
  "wardley-beta\nA +'text'> B\nA +'t'< B\nA +''<> B; label\n", "wardley-beta\n\"A\" \"B\"\n_1 _2\nA > B\nA->B\nfoo-bar->baz\n",
  "wardley-beta\nA +> B +<; both\nA +< -> B +>\n\"x y\" -.-> 'z'\n", "wardley-beta\nannotations [0.1, 90]\nannotation 1,[0.5, 50] \"one\"\nannotation 0,[1, 0] 'two'\nnote \"n\" [0.2, 0.3]\n",
  "wardley-beta\naccelerator \"Go\" [0.5, 0.5]\ndeaccelerator Slow down [0.1, 0.2]\nevolve A 0.9\nevolve \"B c\" 0.10\n",
  "wardley-beta\r\ncomponent A [0.5, 0.5]\r\nA->B\r\n", "---\ntitle: x\n---\nwardley-beta\ncomponent A [0.5, 0.5] %% trailing\n",
  "wardley-beta\n---\nx\n---\nA->B\n",
]

///|
/// Seeds pele's oracle test expects Mermaid's grammar to reject.
let invalid : Array[String] = [
  "wardley-beta\ncomponent market [0.1, 0.2]\n", "wardley-beta\ncomponent labelled thing [0.1, 0.2]\n",
  "wardley-beta\n1 2\n", "wardley-beta\nA B\n", "wardley-beta\ncomponent A [1, 2]\n",
  "wardley-beta\nevolution A / b@0.5 -> B\n", "wardley-beta\ncomponent A [0.5, 0.5] (inertia) (buy)\n",
]

///|
/// Pieces the mutator inserts, from pele's oracle test.
let fragments : Array[String] = [
  "wardley-beta", "wardley-beta\n", "title", "title ", "accTitle: ", "accDescr: ",
  "accDescr {", "}", "{", "[", "]", "(", ")", ",", "@", "/", "-", "--", "---", "->",
  "-->", "-.->", ">", "+>", "+<", "+<>", "+'x'>", "+'y'<", "+'z'<>", "+'", "'", "\"",
  "\"a b\"", "'c'", ";", "; note", ";x", "size", "size [800, 600]", "evolution",
  "evolution A -> B", "anchor", "component", "component A [0.5, 0.5]", "label", "label [-10, 5]",
  "inertia", "(inertia)", "evolve", "evolve A 0.9", "pipeline", "pipeline A {\n",
  "note", "annotations", "annotation", "annotation 1,[0.5, 0.5] \"t\"", "accelerator",
  "deaccelerator", "build", "buy", "outsource", "market", "(buy)", "0.5", "0", "1",
  "12", "1.", ".5", "05", "1.5", "100", "0.50", "\n", "\r\n", "\r", " ", "\t", "%%",
  "%% c", "%%{init: {}}%%", "---\n", "x", "A", "B", "a-b", "A B", "_", "9", "é",
  "#35;", "&", "\\", "Tea", "Kettle", " -> ", " --> ", " -.-> ", " +> ", " +<> ",
  "\nA -> B", "\nA --> B; l",
]

///|
/// pele's seeded generator: a linear congruential sequence of fractions in [0, 1).
fn random(seed : UInt32) -> () -> Double {
  let mut state = seed
  () => {
    state = state * 1664525U + 1013904223U
    state.to_double() / 4294967296.0
  }
}

///|
/// pele's mutator: one to three random insertions, deletions, splices, repeats, or replacements.
fn mutator(
  corpus : Array[String],
  pieces : Array[String],
  rnd : () -> Double,
) -> () -> String {
  let below = (n : Int32) => (rnd() * n.to_double()).floor().to_int()
  () => {
    let mut s = corpus[below(corpus.length())]
    let edits = 1 + below(3)
    for _ in 0..<edits {
      let pos = below(s.length() + 1)
      let r = rnd()
      if r < 0.35 {
        s = @util.slice(s, 0, end=pos) +
          pieces[below(pieces.length())] +
          @util.slice(s, pos)
      } else if r < 0.6 {
        s = @util.slice(s, 0, end=pos) + @util.slice(s, pos + 1 + below(3))
      } else if r < 0.75 {
        let other = corpus[below(corpus.length())]
        let from = below(other.length())
        s = @util.slice(s, 0, end=pos) +
          @util.slice(other, from, end=from + below(20)) +
          @util.slice(s, pos)
      } else if r < 0.9 {
        s = @util.slice(s, 0, end=pos) +
          @util.slice(s, pos, end=pos + below(6)) +
          @util.slice(s, pos)
      } else {
        s = @util.slice(s, 0, end=pos) +
          pieces[below(pieces.length())] +
          @util.slice(s, pos + 1)
      }
    }
    s
  }
}

///|
/// The seeds and 2,000 mutations of them, as pele's oracle test makes them.
fn corpus_sources() -> Array[String] {
  let seeds = [..docs, ..valid, ..invalid]
  let next = mutator(seeds, fragments, random(17))
  let sources = [..seeds]
  for _ in 0..<2000 {
    sources.push(next())
  }
  sources
}

///|
test "the mutated corpus is the one pele makes" {
  inspect(fnv1a(corpus_sources().join("\n\n")), content="21b1c343")
}

///|
test "parsing matches pele on the corpus and its mutations" {
  inspect(fnv1a(corpus_sources().map(ast).join("\n\n")), content="56bd93d1")
}
