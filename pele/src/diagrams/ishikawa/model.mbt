///|
/// A line of an Ishikawa outline with the lines nested under it.
pub(all) struct IshikawaNode {
  text : String
  children : Array[IshikawaNode]
}

///|
/// The root is the effect; its children are the categories of causes, theirs the causes, and so on.
pub(all) struct IshikawaModel {
  title : String?
  root : IshikawaNode?
}
