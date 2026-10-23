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
