///|
/// A drawable piece of a grammar rule.
pub(all) enum RailroadNode {
  Terminal(String)
  NonTerminal(String)
  Special(String)
  Sequence(Array[RailroadNode])
  Choice(Array[RailroadNode])
  Optional(RailroadNode)
  /// `max` is infinity when the count has no upper bound.
  Repetition(element~ : RailroadNode, min~ : Double, max~ : Double)
}

///|
pub(all) struct RailroadRule {
  name : String
  definition : RailroadNode
}

///|
/// Which of Mermaid's four grammars the text was written in.
pub(all) enum Notation {
  Railroad
  Ebnf
  Abnf
  Peg
}

///|
pub(all) struct RailroadModel {
  notation : Notation
  title : String?
  acc_title : String?
  acc_descr : String?
  /// Every rule in source order. A name defined twice appears twice.
  rules : Array[RailroadRule]
}
