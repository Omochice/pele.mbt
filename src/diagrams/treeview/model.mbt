///|
/// Whether an entry is a file or, when its name ends with a slash, a directory.
pub(all) enum NodeType {
  File
  Directory
}

///|
/// An entry of the tree.
pub(all) struct TreeNode {
  id : Int32
  level : Int32
  name : String
  node_type : NodeType
  /// An icon name as written (`pack:name`, `file`, `folder`), or `none` to hide the icon.
  icon : String?
  css_class : String?
  description : String?
  children : Array[TreeNode]
}

///|
/// A tree view ready to be drawn.
pub(all) struct TreeViewModel {
  title : String?
  acc_title : String?
  acc_descr : String?
  /// A directory named `/` at level -1 that holds the top-level entries.
  root : TreeNode
  count : Int32
}

///|
/// Mermaid's treeView database: entries arrive in source order with their indentation.
pub struct TreeViewDb {
  count : Int32
  root : TreeNode
  stack : Array[TreeNode]
}

///|
/// An empty database with only the root.
pub fn TreeViewDb::new() -> TreeViewDb {
  let root = {
    id: 0,
    level: -1,
    name: "/",
    node_type: Directory,
    icon: None,
    css_class: None,
    description: None,
    children: [],
  }
  { count: 1, root, stack: [root], }
}

///|
/// Adds an entry below the nearest earlier entry that is indented less.
pub fn TreeViewDb::add_node(
  self : TreeViewDb,
  level : Int32,
  name : String,
  node_type : NodeType,
  css_class? : String,
  icon? : String,
  description? : String,
) -> Unit {
  ignore((self, level, name, node_type, css_class, icon, description))
}

///|
/// Adds the entries of `ast` to `db`.
pub fn populate(ast : TreeViewAst, db : TreeViewDb) -> Unit {
  ignore((ast, db))
}

///|
/// Reads the source to a syntax tree, accepting box-drawing input.
/// Errors name lines of the original text.
pub fn read_treeview(source : String) -> TreeViewAst raise @errors.PeleError {
  parse_treeview(source)
}

///|
/// Builds the model of a tree view.
/// `title` is the front matter title, used when the tree view has none.
pub fn build_treeview(ast : TreeViewAst, title : String?) -> TreeViewModel {
  let db = TreeViewDb::new()
  populate(ast, db)
  { title, acc_title: None, acc_descr: None, root: db.root, count: db.count, }
}
