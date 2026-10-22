///|
/// Mermaid's name for its built-in icon pack.
/// Only `file` and `folder` are built in; every other icon name is offered to the host's icon resolver.
pub const BUILTIN_PACK : String = "mermaid-treeview"

///|
/// The outline of a built-in icon on a 24 by 24 grid, or `None` for any other name.
pub fn glyph(_name : String) -> String? {
  None
}

///|
/// Which icons a tree view shows.
pub(all) struct IconConfig {
  show_icons : Bool
  default_icon_pack : String
  /// Icon names by exact file name.
  filename_icons : Map[String, String]
  /// Icon names by extension, with or without the leading dot.
  extension_icons : Map[String, String]
}

///|
/// The icon the configured maps give a file name.
/// A file name wins over an extension, and extensions match in lower case.
pub fn detect_icon(
  _name : String,
  _filename_icons : Map[String, String],
  _extension_icons : Map[String, String],
) -> String? {
  None
}

///|
/// The qualified icon name for an entry, or `None` when it shows none.
/// An `icon()` annotation always wins; otherwise icons appear only with `show_icons`.
pub fn node_icon(
  _name : String,
  _node_type : NodeType,
  _icon : String?,
  _config : IconConfig,
) -> String? {
  None
}

///|
/// Reads the icon settings from the `treeView` section of the config.
pub fn icon_config(_config : @types.Config) -> IconConfig {
  {
    show_icons: false,
    default_icon_pack: "",
    filename_icons: {},
    extension_icons: {},
  }
}
