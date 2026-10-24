///|
const PAD_X : Double = 10

///|
const PAD_Y : Double = 8

///|
const FACE : Double = 11

///|
const DOT : Double = 5

///|
const EYES : String = "<circle cx=\"-3.6\" cy=\"-2.8\" r=\"1.3\"/><circle cx=\"3.6\" cy=\"-2.8\" r=\"1.3\"/>"

///|
/// A face looks happy above a score of 3 and sad below it; a score that is not a number is neutral.
fn mood_of(score : Double) -> String {
  if score > 3.0 {
    "happy"
  } else if score < 3.0 {
    "sad"
  } else {
    "neutral"
  }
}

///|
fn mouth(mood : String) -> String {
  match mood {
    "happy" => "M-5,2A6,6 0 0 0 5,2"
    "neutral" => "M-4.5,4.5H4.5"
    _ => "M-5,6.5A6,6 0 0 1 5,6.5"
  }
}

///|
fn face(x : Double, y : Double, mood : String) -> String {
  "<g class=\"pele-face pele-face-\{mood}\" transform=\"translate(\{@svg.num(x)},\{@svg.num(y)})\">" +
  "<circle r=\"\{FACE}\" fill=\"var(--_bg)\" stroke=\"var(--_l)\"/>" +
  "<g fill=\"var(--_l)\">\{EYES}</g>" +
  "<path d=\"\{mouth(mood)}\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"/>" +
  "</g>"
}

///|
/// Everyone named on a task who has a name.
/// `Task: 5:` names an actor with no name; Mermaid gives it a dot and an empty legend row, which are left out here.
fn named(people : Array[String]) -> Array[String] {
  people.filter(name => name != "")
}
