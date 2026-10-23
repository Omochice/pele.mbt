///|
fn text_of(out : FixedArray[Byte]) -> String {
  @utf8.decode_lossy(Bytes::from_array(out[:]))
}

///|
/// The status the plugin returns for `source` under `options`, with the JSON it answers with.
fn respond(source : String, options : String) -> (Int32, Json) {
  let (status, out) = encode(reply(source, options))
  let json = @util.parse_json(text_of(out)) catch {
    @util.JsonError(message, _) =>
      abort("the plugin answered with text that is not JSON: \{message}")
  }
  (status, json)
}

///|
test "takes options nested thousands deep, as pele takes any object" {
  let depth = 3000
  let deep = "{\"a\":".repeat(depth) + "1" + "}".repeat(depth)
  let (status, _) = respond(
    "graph TD\nA-->B",
    "{\"config\": {\"x\": \{deep}}, \"idPrefix\": \"deep\"}",
  )
  inspect(status, content="0")
}

///|
test "options that are not JSON fail as JSON.parse fails on them" {
  let (status, body) = respond("graph TD\nA-->B", "not json")
  inspect(status, content="1")
  inspect(
    body.stringify(),
    content="{\"error\":{\"name\":\"SyntaxError\",\"code\":null,\"message\":\"Unexpected token 'o', \\\"not json\\\" is not valid JSON\",\"type\":null,\"mermaidType\":null}}",
  )
}

///|
test "a failure's answer is the JSON of its error, with its escapes and characters outside ASCII" {
  let source = "graph TD\nA[\"quote \\\" back \\\\ tab\tend \u{1} é 日本 😀\"]-->"
  let (status, out) = encode(reply(source, "{}"))
  inspect(status, content="1")
  guard reply(source, "{}") is Refused(failure) else { abort("not refused") }
  inspect(failure.message.contains("\t"), content="true")
  assert_eq(
    Bytes::from_array(out[:]),
    @utf8.encode(pele_failure(failure).stringify()),
  )
}
