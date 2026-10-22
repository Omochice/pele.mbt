///|
/// A section, which has children that may be none, or a leaf, which has a value.
pub(all) struct TreemapNode {
  name : String
  children : Array[TreemapNode]?
  value : Double?
  class_selector : String?
  css_compiled_styles : Array[String]?
}

///|
/// A row of the treemap with its indentation, before it is placed in the hierarchy.
pub(all) struct TreemapItem {
  level : Int32
  name : String
  leaf : Bool
  value : Double?
  class_selector : String?
  css_compiled_styles : Array[String]?
}

///|
/// A treemap ready to be laid out.
pub(all) struct TreemapModel {
  title : String?
  acc_title : String?
  acc_descr : String?
  roots : Array[TreemapNode]
  /// The declarations of each class, in the order the classes were first defined.
  classes : Map[String, Array[String]]
}

///|
/// Places each row under the nearest section above it that is indented less.
pub fn build_hierarchy(items : Array[TreemapItem]) -> Array[TreemapNode] {
  let roots = []
  let stack : Array[(TreemapNode, Int32)] = []
  for item in items {
    let node = {
      name: item.name,
      children: if item.leaf {
        None
      } else {
        Some([])
      },
      value: if item.leaf {
        item.value
      } else {
        None
      },
      class_selector: item.class_selector,
      css_compiled_styles: item.css_compiled_styles,
    }
    while stack.length() > 0 && stack[stack.length() - 1].1 >= item.level {
      stack.pop() |> ignore
    }
    if stack.is_empty() {
      roots.push(node)
    } else {
      stack[stack.length() - 1].0.children.unwrap().push(node)
    }
    if !item.leaf {
      stack.push((node, item.level))
    }
  }
  roots
}

///|
/// Builds the hierarchy of a treemap, with each class's declarations given to the rows that use it.
/// `title` is the front matter title, used when the treemap has none.
pub fn build_treemap(ast : TreemapAst, title : String?) -> TreemapModel {
  let items = []
  for row in ast.rows {
    if row is Item(indent, found) {
      let (name, leaf, value, class_selector) = match found {
        Section(name, selector) => (name, false, None, selector)
        Leaf(name, value, selector) => (name, true, Some(value), selector)
      }
      items.push({
        level: indent.unwrap_or(0),
        name,
        leaf,
        value,
        class_selector,
        css_compiled_styles: None,
      })
    }
  }
  {
    title,
    acc_title: None,
    acc_descr: None,
    roots: build_hierarchy(items),
    classes: {},
  }
}
