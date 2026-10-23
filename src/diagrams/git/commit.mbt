///|
/// What a commit is drawn as.
/// Merges and cherry-picks are made by those statements, never written as a type.
pub(all) enum CommitType {
  Normal
  Reverse
  Highlight
  Merge
  CherryPick
}

///|
/// Mermaid's number for the type, which orders the types and names the class of a drawn commit.
pub fn CommitType::index(self : CommitType) -> Int32 {
  match self {
    Normal => 0
    Reverse => 1
    Highlight => 2
    Merge => 3
    CherryPick => 4
  }
}

///|
/// A commit of the graph.
pub(all) struct GitCommit {
  id : String
  message : String
  /// The order the commit was made in.
  seq : Int32
  commit_type : CommitType
  tags : Array[String]
  /// The ids of the commits it follows: the one before it on its branch, then the one merged or picked.
  parents : Array[String]
  branch : String
  /// The type a merge was written with, which it is drawn as.
  custom_type : CommitType?
  /// Whether a merge was given its id, which makes it worth a label.
  custom_id : Bool
}
