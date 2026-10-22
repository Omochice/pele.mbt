///|
/// Mermaid's documented shape names: the short name first, then its aliases.
let documented_shapes : Array[Array[String]] = [
  ["rect", "proc", "process", "rectangle", "squareRect"],
  ["rounded", "event", "roundedRect"],
  ["stadium", "terminal", "pill"],
  ["fr-rect", "subprocess", "subproc", "framed-rectangle", "subroutine"],
  ["cyl", "db", "database", "cylinder"],
  ["datastore", "data-store"],
  ["folder", "directory"],
  ["bucket"],
  ["console"],
  ["browser"],
  ["person"],
  ["circle", "circ"],
  ["bang"],
  ["cloud"],
  ["diam", "decision", "diamond", "question"],
  ["hex", "hexagon", "prepare"],
  ["lean-r", "lean-right", "in-out", "lean_right"],
  ["lean-l", "lean-left", "out-in", "lean_left"],
  ["trap-b", "priority", "trapezoid-bottom", "trapezoid"],
  ["trap-t", "manual", "trapezoid-top", "inv-trapezoid", "inv_trapezoid"],
  ["dbl-circ", "double-circle", "doublecircle"],
  ["text"],
  ["notch-rect", "card", "notched-rectangle"],
  ["lin-rect", "lined-rectangle", "lined-process", "lin-proc", "shaded-process"],
  ["sm-circ", "start", "small-circle", "stateStart"],
  ["fr-circ", "stop", "framed-circle", "stateEnd"],
  ["fork", "join", "forkJoin"],
  ["hourglass", "collate"],
  ["brace", "comment", "brace-l"],
  ["brace-r"],
  ["braces"],
  ["bolt", "com-link", "lightning-bolt"],
  ["doc", "document"],
  ["delay", "half-rounded-rectangle"],
  ["h-cyl", "das", "horizontal-cylinder"],
  ["lin-cyl", "disk", "lined-cylinder"],
  ["curv-trap", "curved-trapezoid", "display"],
  ["div-rect", "div-proc", "divided-rectangle", "divided-process"],
  ["tri", "extract", "triangle"],
  ["win-pane", "internal-storage", "window-pane"],
  ["f-circ", "junction", "filled-circle"],
  ["notch-pent", "loop-limit", "notched-pentagon"],
  ["flip-tri", "manual-file", "flipped-triangle"],
  ["sl-rect", "manual-input", "sloped-rectangle"],
  ["docs", "documents", "st-doc", "stacked-document"],
  ["st-rect", "procs", "processes", "stacked-rectangle"],
  ["bow-rect", "stored-data", "bow-tie-rectangle"],
  ["cross-circ", "summary", "crossed-circle"],
  ["tag-doc", "tagged-document"],
  ["tag-rect", "tagged-rectangle", "tag-proc", "tagged-process"],
  ["flag", "paper-tape"],
  ["odd", "rect_left_inv_arrow"],
  ["lin-doc", "lined-document"],
]

///|
/// Shapes Mermaid accepts by name without documenting them.
let internal_shapes : Array[String] = [
  "state", "choice", "note", "composite", "rectWithTitle", "labelRect", "block_arrow",
  "collapsedGroup", "iconSquare", "iconCircle", "icon", "iconRounded", "imageSquare",
  "anchor", "kanbanItem", "mindmapCircle", "defaultMindmapNode", "classBox", "erBox",
  "requirementBox", "usecaseActor", "usecaseActorHollow", "usecaseActorAwesome",
  "usecaseActorIcon", "usecaseBusiness", "usecaseEllipse", "usecaseJsonTable",
]

///|
/// Shapes produced by the bracket syntax, mapped to their documented names.
let syntax_shapes : Map[String, String] = {
  "square": "rect",
  "round": "rounded",
  "ellipse": "ellipse",
  "hexagon": "hex",
  "diamond": "diam",
}

///|
let canonical_names : Map[String, String] = {
  let names : Map[String, String] = Map([])
  for group in documented_shapes {
    for name in group {
      names[name] = group[0]
    }
  }
  for name in internal_shapes {
    names[name] = name
  }
  names
}

///|
/// Whether Mermaid accepts `name` as a shape in node data.
pub fn is_valid_shape(name : String) -> Bool {
  canonical_names.contains(name)
}

///|
/// The documented short name of a shape, `rect` for none or an unknown one.
pub fn canonical_shape(name : String?) -> String {
  guard name is Some(name) else { return "rect" }
  match syntax_shapes.get(name) {
    Some(shape) => shape
    None => canonical_names.get(name).unwrap_or("rect")
  }
}
