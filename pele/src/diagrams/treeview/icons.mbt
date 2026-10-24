///|
/// Mermaid's name for its built-in icon pack.
/// Only `file` and `folder` are built in; every other icon name is offered to the host's icon resolver.
pub const BUILTIN_PACK : String = "mermaid-treeview"

///|
const FOLDER : String = "M3 6.5A1.5 1.5 0 0 1 4.5 5h4.6l2.4 2.5h8A1.5 1.5 0 0 1 21 9v9a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 18z"

///|
const FILE : String = "M6.5 3h7L19 8.5v11a1.5 1.5 0 0 1-1.5 1.5h-11A1.5 1.5 0 0 1 5 19.5v-15A1.5 1.5 0 0 1 6.5 3zM13.5 3v5.5H19"

///|
/// The outline of a built-in icon on a 24 by 24 grid, or `None` for any other name.
pub fn glyph(name : String) -> String? {
  match name {
    "folder" => Some(FOLDER)
    "file" => Some(FILE)
    _ => None
  }
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
  name : String,
  filename_icons : Map[String, String],
  extension_icons : Map[String, String],
) -> String? {
  match filename_icons.get(name) {
    Some(by_name) if by_name != "" => return Some(by_name)
    _ => ()
  }
  let dot = @util.last_index_of(name, ".")
  if dot > 0 {
    let extension = @util.slice(name, dot).to_lower()
    match extension_icons.get(extension) {
      Some(_) as found => found
      None => extension_icons.get(@util.slice(extension, 1))
    }
  } else {
    None
  }
}

///|
fn qualify_icon(icon : String, default_icon_pack : String) -> String {
  if icon.contains(":") {
    icon
  } else if glyph(icon) is Some(_) || default_icon_pack == "" {
    "\{BUILTIN_PACK}:\{icon}"
  } else {
    "\{default_icon_pack}:\{icon}"
  }
}

///|
/// The qualified icon name for an entry, or `None` when it shows none.
/// An `icon()` annotation always wins; otherwise icons appear only with `show_icons`.
pub fn node_icon(
  name : String,
  node_type : NodeType,
  icon : String?,
  config : IconConfig,
) -> String? {
  match icon {
    Some("none") => return None
    Some(icon) if icon != "" =>
      return Some(qualify_icon(icon, config.default_icon_pack))
    _ => ()
  }
  if !config.show_icons {
    return None
  }
  if node_type is File {
    match detect_icon(name, config.filename_icons, config.extension_icons) {
      Some("none") => return None
      Some(detected) if detected != "" =>
        return Some(qualify_icon(detected, config.default_icon_pack))
      _ => ()
    }
  }
  match node_type {
    Directory => Some("\{BUILTIN_PACK}:folder")
    File => Some("\{BUILTIN_PACK}:file")
  }
}

///|
/// The string values of a JSON object; any other value reads as no map.
fn string_map(value : Json?) -> Map[String, String] {
  let map = Map([])
  if value is Some(Object(entries)) {
    for key, entry in entries {
      if entry is String(text) {
        map[key] = text
      }
    }
  }
  map
}

///|
/// Reads the icon settings from the `treeView` section of the config.
pub fn icon_config(config : @types.Config) -> IconConfig {
  guard config.get("treeView") is Some(Object(section)) else {
    return {
      show_icons: false,
      default_icon_pack: "",
      filename_icons: Map([]),
      extension_icons: Map([]),
    }
  }
  {
    show_icons: section.get("showIcons").map(@util.js_truthy).unwrap_or(false),
    default_icon_pack: match section.get("defaultIconPack") {
      Some(String(pack)) => pack
      _ => ""
    },
    filename_icons: string_map(section.get("filenameIcons")),
    extension_icons: string_map(section.get("extensionIcons")),
  }
}
