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
