///|
fn config(
  show_icons~ : Bool = false,
  pack~ : String = "",
  filenames~ : Map[String, String] = {},
  extensions~ : Map[String, String] = {},
) -> @treeview.IconConfig {
  {
    show_icons,
    default_icon_pack: pack,
    filename_icons: filenames,
    extension_icons: extensions,
  }
}

///|
fn icon_of(
  name : String,
  node_type : @treeview.NodeType,
  icon? : String,
  config~ : @treeview.IconConfig = config(),
) -> String {
  @treeview.node_icon(name, node_type, icon, config).unwrap_or("-")
}

///|
fn detect(
  name : String,
  filenames~ : Map[String, String] = {},
  extensions~ : Map[String, String] = {},
) -> String {
  @treeview.detect_icon(name, filenames, extensions).unwrap_or("-")
}

///|
test "the built-in pack has the file and folder glyphs only" {
  inspect(@treeview.BUILTIN_PACK, content="mermaid-treeview")
  inspect(
    ["file", "folder", "react"]
    .map(name => (@treeview.glyph(name) is None).to_string())
    .join(","),
    content="false,false,true",
  )
}

///|
test "no icon is detected without configured maps" {
  inspect(@treeview.detect_icon("utils.ts", {}, {}).unwrap_or("-"), content="-")
}

///|
test "file names and extensions are matched from the maps" {
  inspect(
    detect("Dockerfile", filenames={ "Dockerfile": "docker" }),
    content="docker",
  )
  inspect(
    detect("utils.ts", extensions={ ".ts": "typescript" }),
    content="typescript",
  )
  inspect(
    detect("utils.ts", extensions={ "ts": "typescript" }),
    content="typescript",
  )
  inspect(
    detect("APP.TS", extensions={ ".ts": "typescript" }),
    content="typescript",
  )
  inspect(
    detect("tsconfig.json", filenames={ "tsconfig.json": "tsconfig" }, extensions={
      ".json": "json",
    }),
    content="tsconfig",
  )
  inspect(
    detect("component.spec.ts", extensions={ ".ts": "typescript" }),
    content="typescript",
  )
  inspect(detect(".bashrc", extensions={ "bashrc": "console" }), content="-")
}

///|
test "an explicit icon wins over every setting" {
  inspect(icon_of("a.ts", File, icon="none"), content="-")
  inspect(
    icon_of(
      "src",
      Directory,
      icon="none",
      config=config(show_icons=true, pack="logos"),
    ),
    content="-",
  )
  inspect(icon_of("a.ts", File, icon="logos:react"), content="logos:react")
  inspect(
    icon_of("a.ts", File, icon="logos:react", config=config(show_icons=true)),
    content="logos:react",
  )
}

///|
test "an unprefixed icon belongs to the built-in pack or to the default pack" {
  inspect(
    icon_of("a.ts", File, icon="file", config=config(pack="logos")),
    content="mermaid-treeview:file",
  )
  inspect(
    icon_of("a.ts", File, icon="folder"),
    content="mermaid-treeview:folder",
  )
  inspect(
    icon_of("a.ts", File, icon="react", config=config(pack="logos")),
    content="logos:react",
  )
  inspect(icon_of("a.ts", File, icon="react"), content="mermaid-treeview:react")
}

///|
test "without an explicit icon, icons appear only with show_icons" {
  inspect(icon_of("utils.ts", File), content="-")
  inspect(icon_of("src", Directory, config=config(pack="logos")), content="-")
  inspect(
    icon_of("utils.ts", File, config=config(show_icons=true)),
    content="mermaid-treeview:file",
  )
  inspect(
    icon_of("src", Directory, config=config(show_icons=true)),
    content="mermaid-treeview:folder",
  )
  inspect(
    icon_of("utils.ts", File, config=config(show_icons=true, pack="logos")),
    content="mermaid-treeview:file",
  )
}

///|
test "detection maps choose the icon of a file when icons are shown" {
  inspect(
    icon_of(
      "utils.ts",
      File,
      config=config(show_icons=true, pack="material-icon-theme", extensions={
        ".ts": "typescript",
      }),
    ),
    content="material-icon-theme:typescript",
  )
  inspect(
    icon_of(
      "utils.ts",
      File,
      config=config(show_icons=true, extensions={
        ".ts": "logos:typescript-icon",
      }),
    ),
    content="logos:typescript-icon",
  )
  inspect(
    icon_of(
      "utils.ts",
      File,
      config=config(extensions={ ".ts": "logos:typescript-icon" }),
    ),
    content="-",
  )
  inspect(
    icon_of(
      "notes.txt",
      File,
      config=config(show_icons=true, extensions={ ".txt": "none" }),
    ),
    content="-",
  )
  inspect(
    icon_of(
      "notes.txt",
      File,
      config=config(show_icons=true, pack="material-icon-theme", filenames={
        "notes.txt": "folder",
      }),
    ),
    content="mermaid-treeview:folder",
  )
  inspect(
    icon_of(
      "data.xyz",
      File,
      config=config(show_icons=true, extensions={ ".ts": "typescript" }),
    ),
    content="mermaid-treeview:file",
  )
  inspect(
    icon_of(
      "dir.ts",
      Directory,
      config=config(show_icons=true, extensions={ ".ts": "typescript" }),
    ),
    content="mermaid-treeview:folder",
  )
}

///|
test "the icon settings are read from the treeView section of the config" {
  let read = (text : String) => {
    let c = @treeview.icon_config({
      "treeView": @json.parse(text) catch {
        _ => Json::null()
      },
    })
    let sort = (m : Map[String, String]) => {
      m.iter().map(p => "\{p.0}=\{p.1}").collect().join(",")
    }
    "\{c.show_icons} [\{c.default_icon_pack}] {\{sort(c.filename_icons)}} {\{sort(c.extension_icons)}}"
  }
  inspect(read("{}"), content="false [] {} {}")
  inspect(
    read(
      "{\"showIcons\": 1, \"defaultIconPack\": \"material\", \"filenameIcons\": {\"Dockerfile\": \"docker\", \"x\": 3}, \"extensionIcons\": {\".ts\": \"typescript\"}}",
    ),
    content="true [material] {Dockerfile=docker} {.ts=typescript}",
  )
  inspect(
    read(
      "{\"showIcons\": 0, \"defaultIconPack\": 3, \"filenameIcons\": [\"a\"]}",
    ),
    content="false [] {} {}",
  )
  inspect(@treeview.icon_config({}).show_icons, content="false")
}
