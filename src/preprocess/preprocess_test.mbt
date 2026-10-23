///|
test "comment lines are removed but directives are kept" {
  inspect(
    @preprocess.cleanup_comments("%% one\ngraph TD\n  %% two\n  A --> B\n"),
    content="graph TD\n  A --> B\n",
  )
  inspect(
    @preprocess.cleanup_comments("%%{init: {}}%%\ngraph TD"),
    content="%%{init: {}}%%\ngraph TD",
  )
}

///|
test "front matter gives the title and config" {
  let result = @preprocess.preprocess(
    "---\ntitle: My chart\nconfig:\n  flowchart:\n    curve: linear\n---\ngraph TD\n  A",
  )
  inspect(result.title.unwrap_or("none"), content="My chart")
  inspect(
    Json::object(result.config).stringify(),
    content="{\"flowchart\":{\"curve\":\"linear\"}}",
  )
  inspect(result.text, content="graph TD\n  A")
  inspect(result.line_offset, content="6")
}

///|
test "front matter gives pie its text position and donut hole" {
  let result = @preprocess.preprocess(
    "---\nconfig:\n  pie:\n    textPosition: 0.5\n    donutHole: 0.2\n    highlightSlice: Potassium\n  themeVariables:\n    pieOuterStrokeWidth: \"5px\"\n---\npie showData\n    \"Iron\" :  5\n",
  )
  inspect(
    Json::object(result.config).stringify(),
    content="{\"pie\":{\"textPosition\":0.5,\"donutHole\":0.2,\"highlightSlice\":\"Potassium\"},\"themeVariables\":{\"pieOuterStrokeWidth\":\"5px\"}}",
  )
  inspect(result.text, content="pie showData\n    \"Iron\" :  5\n")
}

///|
test "a title that is not a string is written as JavaScript would" {
  inspect(
    @preprocess.preprocess("---\ntitle: 42\n---\npie").title.unwrap_or("none"),
    content="42",
  )
}

///|
test "front matter that is not valid YAML is a syntax error" {
  let message = try {
    @preprocess.preprocess("---\na: [1\n---\npie") |> ignore
    "read"
  } catch {
    @errors.PeleError(failure) =>
      "\{failure.code.to_string()}: \{failure.message}"
  }
  inspect(
    message,
    content="syntax: Front matter is not valid YAML. YAML: unexpected end of the stream within a flow collection",
  )
}

///|
test "init directives are merged over front matter and removed" {
  let result = @preprocess.preprocess(
    "---\nconfig:\n  flowchart:\n    curve: linear\n    rankSpacing: 10\n---\n%%{init: {'flowchart': {'rankSpacing': 99}}}%%\ngraph TD\n  A",
  )
  inspect(
    Json::object(result.config).stringify(),
    content="{\"flowchart\":{\"curve\":\"linear\",\"rankSpacing\":99}}",
  )
  inspect(result.text, content="graph TD\n  A")
}

///|
test "an init directive nested thousands deep is applied as JSON.parse reads it" {
  let depth = 3000
  let deep = "{\"a\":".repeat(depth) + "1" + "}".repeat(depth)
  let result = @preprocess.preprocess(
    "%%{init: {\"x\": \{deep}, \"theme\": \"dark\"}}%%\ngraph TD\nA",
  )
  let mut levels = 0
  let mut value = result.config.get("x")
  while value is Some(Object(object)) {
    levels += 1
    value = object.get("a")
  }
  inspect(levels, content="3000")
  inspect(value.map_or("none", json => json.stringify()), content="1")
  result.config.remove("x")
  inspect(
    Json::object(result.config).stringify(),
    content="{\"theme\":\"dark\"}",
  )
}

///|
/// `n` objects nested under the key "a", around the number 1.
fn nested_objects(n : Int32) -> String {
  "{\"a\":".repeat(n) + "1" + "}".repeat(n)
}

///|
/// The value as JSON, with each value under the key "a" written as the number of objects nested in it.
fn outline(value : Json) -> Json {
  guard value is Object(fields) else { return value }
  let out = Map([])
  for key, item in fields {
    out[key] = if key == "a" {
      let mut levels = 0
      let mut inner = Some(item)
      while inner is Some(Object(object)) {
        levels += 1
        inner = object.get("a")
      }
      Json::number(levels.to_double())
    } else {
      outline(item)
    }
  }
  Json::object(out)
}

///|
test "an init directive nested deeper than pele's merge reaches applies only the keys before it" {
  let config = (n : Int32) => {
    outline(
      Json::object(
        @preprocess.preprocess(
          "%%{init: {\"before\": 1, \"x\": \{nested_objects(n)}, \"after\": 2}}%%\ngraph TD\nA",
        ).config,
      ),
    ).stringify()
  }
  inspect(config(4467), content="{\"before\":1,\"x\":{\"a\":4466},\"after\":2}")
  inspect(config(4468), content="{\"before\":1}")
}

///|
test "a merge past pele's reach keeps what it merged into existing objects" {
  let config = (n : Int32) => {
    outline(
      Json::object(
        @preprocess.preprocess(
          "%%{init: {\"x\": {\"k\": 1}}}%%\n" +
          "%%{init: {\"x\": {\"k\": 2, \"a\": \{nested_objects(n)}, \"z\": 3}, \"after\": 4}}%%\n" +
          "%%{init: {\"later\": 5}}%%\ngraph TD\nA",
        ).config,
      ),
    ).stringify()
  }
  inspect(
    config(4466),
    content="{\"x\":{\"k\":2,\"a\":4466,\"z\":3},\"after\":4,\"later\":5}",
  )
  inspect(config(4467), content="{\"x\":{\"k\":2},\"later\":5}")
}

///|
test "config cannot set unsafe keys" {
  let result = @preprocess.preprocess(
    "%%{init: {\"__proto__\": {\"polluted\": true}, \"theme\": \"dark\"}}%%\ngraph TD\nA",
  )
  inspect(
    Json::object(result.config).stringify(),
    content="{\"theme\":\"dark\"}",
  )
}

///|
test "line endings and attribute quotes are normalized" {
  inspect(
    @preprocess.preprocess("graph TD\r\nA[\"<span class=\"x\">hi</span>\"]\r").text,
    content="graph TD\nA[\"<span class='x'>hi</span>\"]\n",
  )
}

///|
test "entity codes are hidden as Mermaid hides them" {
  let cases = [
    ("style A fill:#f9f,stroke:#333;", "style A fill:#f9f,stroke:#333"),
    (
      "style A fill:#f9f;stroke:#333;\nB --> C;", "style A fill:\u{fb02}\u{b0}f9f\u{b6}\u{df}stroke:#333\nB --> C;",
    ),
    (
      "classDef green fill:#9f6,stroke:#333,stroke-width:2px;", "classDef green fill:#9f6,stroke:#333,stroke-width:2px",
    ),
    (
      "A[\"a #35; b #quot;c#quot;\"]", "A[\"a \u{fb02}\u{b0}\u{b0}35\u{b6}\u{df} b \u{fb02}\u{b0}quot\u{b6}\u{df}c\u{fb02}\u{b0}quot\u{b6}\u{df}\"]",
    ),
    ("style A color: #fff;", "style A color: \u{fb02}\u{b0}fff\u{b6}\u{df}"),
    ("style A fill:red;", "style A fill:red;"),
    (
      "mystyle x:#1; classDef y:#2; z;", "mystyle x:\u{fb02}\u{b0}\u{b0}1\u{b6}\u{df} classDef y:#2 z",
    ),
    ("style a:#b\n;", "style a:#b\n;"),
    ("style a b :c#d e;f;g", "style a b :c#d e;fg"),
    ("#;# ; #a ;#a;", "#;# ; #a ;\u{fb02}\u{b0}a\u{b6}\u{df}"),
  ]
  for case in cases {
    let (text, expected) = case
    assert_eq(@preprocess.encode_entities(text), expected)
  }
}
