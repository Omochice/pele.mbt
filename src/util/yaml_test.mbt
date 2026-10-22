///|
fn yaml(source : String) -> String {
  @util.parse_yaml(source).stringify() catch {
    @util.YamlError(message) => "error: \{message}"
  }
}

///|
test "flow mappings agree with js-yaml" {
  inspect(yaml("{\n shape: rounded \n}"), content="{\"shape\":\"rounded\"}")
  inspect(
    yaml("{\nshape: rounded , label: \"DD\"\n}"),
    content="{\"shape\":\"rounded\",\"label\":\"DD\"}",
  )
  inspect(
    yaml("{\n label: \"This is }\", other: \"clock\"\n}"),
    content="{\"label\":\"This is }\",\"other\":\"clock\"}",
  )
  inspect(
    yaml(
      "{\n animate: true, animation: fast, w: 100, h: 50.5, x: null, y: ~\n}",
    ),
    content="{\"animate\":true,\"animation\":\"fast\",\"w\":100,\"h\":50.5,\"x\":null,\"y\":null}",
  )
  inspect(
    yaml(
      "{\n label: 'single quoted', icon: \"fa:fa-user\", form: circle, pos: t \n}",
    ),
    content="{\"label\":\"single quoted\",\"icon\":\"fa:fa-user\",\"form\":\"circle\",\"pos\":\"t\"}",
  )
  inspect(
    yaml("{\n a: [1, 2, three], b: {c: d, e: [f]}\n}"),
    content="{\"a\":[1,2,\"three\"],\"b\":{\"c\":\"d\",\"e\":[\"f\"]}}",
  )
  inspect(yaml("{\n}"), content="{}")
  inspect(yaml("{\n a: 1, # comment\n b: 2\n}"), content="{\"a\":1,\"b\":2}")
}

///|
test "block mappings agree with js-yaml" {
  inspect(
    yaml("\n        shape: circle\n        other: \"clock\"\n     \n"),
    content="{\"shape\":\"circle\",\"other\":\"clock\"}",
  )
  inspect(
    yaml(
      "\n        label: \"This is a<br/>multiline string\"\n        other: \"clock\"\n",
    ),
    content="{\"label\":\"This is a<br/>multiline string\",\"other\":\"clock\"}",
  )
  inspect(
    yaml(
      "title: Hello world\nconfig:\n  theme: dark\n  flowchart:\n    curve: linear\n    htmlLabels: false\n",
    ),
    content="{\"title\":\"Hello world\",\"config\":{\"theme\":\"dark\",\"flowchart\":{\"curve\":\"linear\",\"htmlLabels\":false}}}",
  )
  inspect(
    yaml("title: \"Quoted: title\"\ndisplayMode: compact\n"),
    content="{\"title\":\"Quoted: title\",\"displayMode\":\"compact\"}",
  )
  inspect(
    yaml(
      "config:\n  themeVariables:\n    primaryColor: \"#ff0000\"\n    fontSize: 16px\n  look: handDrawn # trailing comment\n",
    ),
    content="{\"config\":{\"themeVariables\":{\"primaryColor\":\"#ff0000\",\"fontSize\":\"16px\"},\"look\":\"handDrawn\"}}",
  )
  inspect(
    yaml("key with spaces: plain value\nurl: http://example.com/a#b\n"),
    content="{\"key with spaces\":\"plain value\",\"url\":\"http://example.com/a#b\"}",
  )
  inspect(
    yaml("multi: this is\n  continued on the next line\nnext: 1\n"),
    content="{\"multi\":\"this is continued on the next line\",\"next\":1}",
  )
  inspect(
    yaml("a: {\n  b: 1,\n  c: [2,\n    3]\n}\nd: \"two\n  lines\"\ne: 5\n"),
    content="{\"a\":{\"b\":1,\"c\":[2,3]},\"d\":\"two lines\",\"e\":5}",
  )
  inspect(
    yaml("__proto__: 1\nb:\n  __proto__: {x: 1}\n"),
    content="{\"__proto__\":1,\"b\":{\"__proto__\":{\"x\":1}}}",
  )
}

///|
test "block scalars agree with js-yaml" {
  inspect(
    yaml(
      "\n        label: |\n          This is a\n          multiline string\n        other: \"clock\"\n     \n",
    ),
    content="{\"label\":\"This is a\\nmultiline string\\n\",\"other\":\"clock\"}",
  )
  inspect(
    yaml(
      "\n        label: >\n          folded\n          text\n\n          second paragraph\n        other: 1\n",
    ),
    content="{\"label\":\"folded text\\nsecond paragraph\\n\",\"other\":1}",
  )
}

///|
test "sequences agree with js-yaml" {
  inspect(
    yaml("list:\n  - a\n  - b: 1\n    c: 2\n  - [x, y]\nempty:\n"),
    content="{\"list\":[\"a\",{\"b\":1,\"c\":2},[\"x\",\"y\"]],\"empty\":null}",
  )
  inspect(yaml("- 1\n- 2\n"), content="[1,2]")
}

///|
test "scalars follow the JSON schema" {
  inspect(
    yaml(
      "a: 0x1f\nb: -12\nc: 1e3\nd: .5\ne: \"12\"\nf: True\ng: FALSE\nh: Null\n",
    ),
    content="{\"a\":31,\"b\":-12,\"c\":1000,\"d\":0.5,\"e\":\"12\",\"f\":true,\"g\":false,\"h\":null}",
  )
  inspect(yaml("just a scalar"), content="\"just a scalar\"")
  inspect(yaml("# only a comment\n"), content="null")
  inspect(yaml(""), content="null")
}

///|
test "absurd nesting is refused" {
  inspect(
    yaml("{ a: " + "[".repeat(20000) + " }"),
    content="error: YAML: nesting is too deep",
  )
}

///|
test "an unterminated flow mapping is rejected" {
  inspect(
    yaml("{ a: 1"),
    content="error: YAML: unexpected end of the stream within a flow collection",
  )
}
