///|
/// A diagram type, as pele names it and as Mermaid reports it.
pub(all) struct Detected {
  kind : String
  mermaid_type : String
}

///|
fn ascii_lower(c : Int32) -> Int32 {
  if c >= 65 && c <= 90 {
    c + 32
  } else {
    c
  }
}

///|
/// Where `word` ends when it follows the leading whitespace of `text`, or -1.
/// Case is folded for ASCII only, as a non-unicode `/i` regex does.
fn keyword_end(
  text : String,
  word : String,
  ignore_case~ : Bool = false,
) -> Int32 {
  let mut i = 0
  while @util.is_space(@util.code_at(text, i)) {
    i += 1
  }
  for k in 0..<word.length() {
    let c = @util.code_at(text, i + k)
    let w = word.unsafe_get(k).to_int()
    let same = if ignore_case {
      ascii_lower(c) == ascii_lower(w)
    } else {
      c == w
    }
    if !same {
      return -1
    }
  }
  i + word.length()
}

///|
fn starts(word : String, ignore_case~ : Bool = false) -> (String) -> Bool {
  text => keyword_end(text, word, ignore_case~) >= 0
}

///|
/// The keyword followed by a `\b`, which after a word character means a non-word one or the end.
fn starts_word(word : String, ignore_case~ : Bool = false) -> (String) -> Bool {
  text => {
    let end = keyword_end(text, word, ignore_case~)
    end >= 0 && !@util.is_word(@util.code_at(text, end))
  }
}

///|
fn c4(text : String) -> Bool {
  ["C4Context", "C4Container", "C4Component", "C4Dynamic", "C4Deployment"]
  .iter()
  .any(word => keyword_end(text, word) >= 0)
}

///|
fn cynefin(text : String) -> Bool {
  let end = keyword_end(text, "cynefin-beta")
  if end < 0 {
    return false
  }
  let c = @util.code_at(text, end)
  c == -1 || c == 58 || @util.is_space(c)
}

///|
fn usecase(text : String) -> Bool {
  let end = keyword_end(text, "usecase-beta")
  if end < 0 {
    return false
  }
  let c = @util.code_at(text, end)
  c == -1 || @util.is_space(c)
}

///|
/// Mermaid's detectors, in the order Mermaid registers them. The first match wins.
let detectors : Array[(String, String, (String) -> Bool)] = [
  ("flowchart", "flowchart-elk", starts("flowchart-elk")),
  ("mindmap", "mindmap", starts("mindmap")),
  ("architecture", "architecture", starts("architecture")),
  ("agentflow", "agentflow", starts_word("agentflow-beta")),
  ("c4", "c4", c4),
  ("kanban", "kanban", starts("kanban")),
  ("class", "classDiagram", starts("classDiagram")),
  ("er", "er", starts("erDiagram")),
  ("gantt", "gantt", starts("gantt")),
  ("info", "info", starts("info")),
  ("pie", "pie", starts("pie")),
  ("requirement", "requirement", starts("requirement")),
  ("sequence", "sequence", starts("sequenceDiagram")),
  ("swimlane", "swimlane", starts_word("swimlane-beta")),
  (
    "flowchart",
    "flowchart-v2",
    text => starts("graph")(text) || starts("flowchart")(text),
  ),
  ("timeline", "timeline", starts("timeline")),
  ("gitGraph", "gitGraph", starts("gitGraph")),
  ("state", "stateDiagram", starts("stateDiagram")),
  ("journey", "journey", starts("journey")),
  ("quadrantChart", "quadrantChart", starts("quadrantChart")),
  ("sankey", "sankey", starts("sankey")),
  ("packet", "packet", starts("packet")),
  ("xychart", "xychart", starts("xychart")),
  ("block", "block", starts("block")),
  ("eventmodeling", "eventmodeling", starts("eventmodeling")),
  ("treeView", "treeView", starts("treeView-beta")),
  ("radar", "radar", starts("radar-beta")),
  // `ishikawa(-beta)?\b` backtracks to `ishikawa` before `-`, so the suffix never matters.
  ("ishikawa", "ishikawa", starts_word("ishikawa", ignore_case=true)),
  ("treemap", "treemap", starts("treemap")),
  ("railroad", "railroad", starts("railroad-beta", ignore_case=true)),
  ("railroad", "railroadEbnf", starts("railroad-ebnf-beta", ignore_case=true)),
  ("railroad", "railroadAbnf", starts("railroad-abnf-beta", ignore_case=true)),
  ("railroad", "railroadPeg", starts("railroad-peg-beta", ignore_case=true)),
  ("venn", "venn", starts("venn-beta")),
  ("wardley", "wardley", starts("wardley-beta", ignore_case=true)),
  ("cynefin", "cynefin", cynefin),
  ("usecase", "usecase", usecase),
]

///|
/// Finds the diagram type that text with comments and front matter removed declares.
pub fn detect_diagram(cleaned : String) -> Detected? {
  for detector in detectors {
    let (kind, mermaid_type, matches) = detector
    if matches(cleaned) {
      return Some({ kind, mermaid_type, })
    }
  }
  None
}
