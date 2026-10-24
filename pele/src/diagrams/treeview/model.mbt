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
  mut count : Int32
}

///|
/// Mermaid's treeView database: entries arrive in source order with their indentation.
pub struct TreeViewDb {
  mut count : Int32
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
  while level <= self.stack[self.stack.length() - 1].level {
    self.stack.pop() |> ignore
  }
  let node = {
    id: self.count,
    level,
    name,
    node_type,
    icon,
    css_class,
    description,
    children: [],
  }
  self.count += 1
  self.stack[self.stack.length() - 1].children.push(node)
  self.stack.push(node)
}

///|
fn non_empty(value : String?) -> String? {
  match value {
    Some("") => None
    _ => value
  }
}

///|
/// Adds the entries of `ast` to `db`.
pub fn populate(ast : TreeViewAst, db : TreeViewDb) -> Unit {
  for node in ast.nodes {
    let is_directory = node.name.has_suffix("/")
    let name = if is_directory {
      @util.slice(node.name, 0, end=node.name.length() - 1)
    } else {
      node.name
    }
    let icon = node.icon_annotation.map(raw => {
      if raw == "" {
        "none"
      } else {
        raw
      }
    })
    db.add_node(
      node.indent.unwrap_or(0),
      name,
      if is_directory {
        Directory
      } else {
        File
      },
      css_class?=non_empty(node.class_annotation),
      icon?,
      description?=non_empty(node.desc_annotation),
    )
  }
}

///|
/// Reads the source to a syntax tree, accepting box-drawing input.
/// Errors name lines of the original text.
pub fn read_treeview(source : String) -> TreeViewAst raise @errors.PeleError {
  let { text, line_map, } = preprocess_box_drawing(source)
  parse_treeview(text) catch {
    @errors.PeleError(failure) as error => {
      if line_map.is_empty() {
        raise error
      }
      let head = @util.index_of(failure.message, "\n")
      let message = if head == -1 {
        remap_error_lines(failure.message, line_map)
      } else {
        remap_error_lines(@util.slice(failure.message, 0, end=head), line_map) +
        @util.slice(failure.message, head)
      }
      raise @errors.PeleError({
        ..failure,
        message,
        line: line_map.get(failure.line).unwrap_or(failure.line),
      })
    }
  }
}

///|
/// Does what `text.replace(/\n\s+/g, '\n')` does.
fn join_indented_lines(text : String) -> String {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    @util.write_range(out, text, i, i + 1)
    if @util.code_at(text, i) == '\n'.to_int() &&
      @util.is_space(@util.code_at(text, i + 1)) {
      i += 1
      while @util.is_space(@util.code_at(text, i)) {
        i += 1
      }
    } else {
      i += 1
    }
  }
  out.to_string()
}

///|
/// Builds the model of a tree view.
/// `title` is the front matter title, used when the tree view has none.
pub fn build_treeview(ast : TreeViewAst, title : String?) -> TreeViewModel {
  let db = TreeViewDb::new()
  populate(ast, db)
  {
    title: match non_empty(ast.title) {
      Some(_) as own => own
      None => title
    },
    acc_title: non_empty(ast.acc_title).map(@util.trim_start),
    acc_descr: non_empty(ast.acc_descr).map(join_indented_lines),
    root: db.root,
    count: db.count,
  }
}
