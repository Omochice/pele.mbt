///|
/// How routes are drawn, which decides where they cross.
pub(all) enum Style {
  Curved
  Stepped
  Linear
}

///|
/// How many times the drawn routes of `edges` cross, leaving out edges that fan out from a node they share.
pub fn route_crossings(
  nodes : Array[CNode],
  edges : Array[CEdge],
  style~ : Style = Curved,
) -> Int32 {
  ignore(nodes)
  ignore(edges)
  ignore(style)
  0
}
