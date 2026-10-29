///|
fn limit_failure(limit : Int32) -> String {
  "{\"error\":{\"name\":\"PeleError\",\"code\":\"limit\",\"message\":\"Diagram output is longer than the typst plugin can return: its JSON response would pass the plugin's limit of \{limit} bytes.\",\"type\":\"flowchart\",\"mermaidType\":\"flowchart-v2\"}}"
}

///|
test "an answer longer than the plugin's limit fails as a limit error that names the limit" {
  let (_, whole) = encode(reply("graph TD\nA-->B", "{}"))
  let size = whole.length()
  let (status, out) = encode(reply("graph TD\nA-->B", "{}"), limit=size - 1)
  inspect(status, content="1")
  assert_eq(text_of(out), limit_failure(size - 1))
  let (status, out) = encode(reply("graph TD\nA-->B", "{}"), limit=size)
  inspect(status, content="0")
  assert_eq(text_of(out), text_of(whole))
}

///|
test "the limit holds the svg as the theme rewrites it" {
  let plain = "{\"theme\":{}}"
  let long = "{\"theme\":{\"surface\":\"#\{"a".repeat(1000)}\"}}"
  let (_, short_answer) = encode(reply("graph TD\nA-->B", plain))
  let (_, long_answer) = encode(reply("graph TD\nA-->B", long))
  inspect(long_answer.length() > short_answer.length() + 1000, content="true")
  let (status, out) = encode(
    reply("graph TD\nA-->B", long),
    limit=long_answer.length() - 1,
  )
  inspect(status, content="1")
  assert_eq(text_of(out), limit_failure(long_answer.length() - 1))
}

///|
test "the answer is the JSON of the drawing, with its escapes and characters outside ASCII" {
  let source = "graph TD\nA[\"quote #quot; back \\\\ tab\tend é 日本 😀\"]-->B"
  for options in ["{}", "{\"theme\":{}}"] {
    let (status, out) = encode(reply(source, options))
    inspect(status, content="0")
    guard reply(source, options) is Drawn(result, theme) else {
      abort("not drawn")
    }
    let svg = match theme {
      Some(theme) => {
        let rewritten = StringBuilder()
        @theme.write_drawable(result.svg, theme, rewritten)
        rewritten.to_string()
      }
      None => result.svg
    }
    assert_eq(
      Bytes::from_array(out[:]),
      @utf8.encode(success({ ..result, svg, }).stringify()),
    )
  }
}

///|
test "a failure is answered as the JSON of its error" {
  let (status, out) = encode(reply("graph TD\nA-->", "{}"))
  inspect(status, content="1")
  inspect(
    text_of(out),
    content=(
      #|{"error":{"name":"PeleError","code":"syntax","message":"Parse error on line 2:\nA-->\n----^\nExpecting 'NODE_STRING', got 'EOF'","type":"flowchart","mermaidType":"flowchart-v2"}}
    ),
  )
}

///|
test "wasm's allocator gives a single block as large as the plugin's limit" {
  let block : FixedArray[Byte] = FixedArray::make(RESPONSE_LIMIT, b'\x01')
  inspect(block[RESPONSE_LIMIT - 1], content="b'\\x01'")
}

///|
test "a failure whose answer is longer than the plugin's limit fails as a limit error tagged as the failure" {
  let (_, whole) = encode(reply("graph TD\nA-->", "{}"))
  let size = whole.length()
  let (status, out) = encode(reply("graph TD\nA-->", "{}"), limit=size - 1)
  inspect(status, content="1")
  assert_eq(text_of(out), limit_failure(size - 1))
  let (status, out) = encode(reply("graph TD\nA-->", "{}"), limit=size)
  inspect(status, content="1")
  assert_eq(text_of(out), text_of(whole))
}
