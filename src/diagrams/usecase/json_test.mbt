// The expected values and messages were taken from pele, whose messages are V8's.

///|
/// The value with object keys in the order they were written and numbers as JavaScript prints
/// them, or the message, line and column of the error.
fn json(text : String) -> String {
  let entries = @usecase.parse_ordered_json(text, () => (3, 5)) catch {
    @errors.PeleError(failure) =>
      return "\{failure.message} @\{failure.line}:\{failure.column}"
  }
  show(@usecase.JsonValue::JsonObject(entries))
}

///|
test "parse_ordered_json: values in the order they were written" {
  inspect(
    json(
      "{\"2\": \"second\", \"1\": \"first\", \"b\": [1, -0, 2.5e3, 1E400, true, false, null], \"a\": {\"z\": {}, \"y\": []}}",
    ),
    content="{\"2\":\"second\",\"1\":\"first\",\"b\":[1,0,2500,Infinity,true,false,null],\"a\":{\"z\":{},\"y\":[]}}",
  )
  inspect(
    json("{\"k\": {\"a\": {\"x\": 1}}, \"j\": 0, \"k\": {\"b\": 2}}"),
    content="{\"k\":{\"b\":2},\"j\":0}",
  )
  inspect(
    json(
      "{\"s\": \"\\\"\\\\\\/\\b\\f\\n\\r\\t\\u0041\\uD83D\\uDE00\", \"__proto__\": 1, \"a~/b\": 2}",
    ),
    content="{\"s\":\"\\\"\\\\/\\b\\f\\n\\r\\tA😀\",\"__proto__\":1,\"a~/b\":2}",
  )
  inspect(
    json("{ \t\r\n\"a\" \n: \r\n[ ] , \"b\" : { } }"),
    content="{\"a\":[],\"b\":{}}",
  )
  inspect(
    json(
      "{\"n\": [0, -1, 1.5, 123456789012345678901234567890, 1e-7, 0.1, 1e21]}",
    ),
    content="{\"n\":[0,-1,1.5,1.2345678901234568e+29,1e-7,0.1,1e+21]}",
  )
}

///|
test "parse_ordered_json: errors in V8's words, located in the diagram" {
  inspect(
    json("{\"a\":}"),
    content="Invalid JSON: Unexpected token '}', \"{\"a\":}\" is not valid JSON (line 3, column 10) @3:10",
  )
  inspect(
    json("{\"a\" 1}"),
    content="Invalid JSON: Expected ':' after property name in JSON at position 5 (line 1 column 6) (line 3, column 10) @3:10",
  )
  inspect(
    json("{\"a\":1"),
    content="Invalid JSON: Expected ',' or '}' after property value in JSON at position 6 (line 1 column 7) (line 3, column 11) @3:11",
  )
  inspect(
    json("{"),
    content="Invalid JSON: Expected property name or '}' in JSON at position 1 (line 1 column 2) (line 3, column 6) @3:6",
  )
  inspect(
    json("{,}"),
    content="Invalid JSON: Expected property name or '}' in JSON at position 1 (line 1 column 2) (line 3, column 6) @3:6",
  )
  inspect(
    json("{\"a\":1,}"),
    content="Invalid JSON: Expected double-quoted property name in JSON at position 7 (line 1 column 8) (line 3, column 12) @3:12",
  )
  inspect(
    json("{\"a\":1 \"b\":2}"),
    content="Invalid JSON: Expected ',' or '}' after property value in JSON at position 7 (line 1 column 8) (line 3, column 12) @3:12",
  )
  inspect(
    json("{\"a\":tru}"),
    content="Invalid JSON: Unexpected token '}', \"{\"a\":tru}\" is not valid JSON (line 3, column 13) @3:13",
  )
  inspect(
    json("{\"a\":tru1}"),
    content="Invalid JSON: Unexpected number in JSON at position 8 (line 1 column 9) (line 3, column 13) @3:13",
  )
  inspect(
    json("{\"a\":tr\"}"),
    content="Invalid JSON: Unexpected string in JSON at position 7 (line 1 column 8) (line 3, column 12) @3:12",
  )
  inspect(
    json("{\"a\":01}"),
    content="Invalid JSON: Unexpected number in JSON at position 6 (line 1 column 7) (line 3, column 11) @3:11",
  )
  inspect(
    json("{\"a\":-}"),
    content="Invalid JSON: No number after minus sign in JSON at position 6 (line 1 column 7) (line 3, column 11) @3:11",
  )
  inspect(
    json("{\"a\":-x}"),
    content="Invalid JSON: No number after minus sign in JSON at position 6 (line 1 column 7) (line 3, column 11) @3:11",
  )
  inspect(
    json("{\"a\":1.}"),
    content="Invalid JSON: Unterminated fractional number in JSON at position 7 (line 1 column 8) (line 3, column 12) @3:12",
  )
  inspect(
    json("{\"a\":1.e5}"),
    content="Invalid JSON: Unterminated fractional number in JSON at position 7 (line 1 column 8) (line 3, column 12) @3:12",
  )
  inspect(
    json("{\"a\":1e}"),
    content="Invalid JSON: Exponent part is missing a number in JSON at position 7 (line 1 column 8) (line 3, column 12) @3:12",
  )
  inspect(
    json("{\"a\":1e+}"),
    content="Invalid JSON: Exponent part is missing a number in JSON at position 8 (line 1 column 9) (line 3, column 13) @3:13",
  )
  inspect(
    json("{\"a\":\"\\x\"}"),
    content="Invalid JSON: Bad escaped character in JSON at position 7 (line 1 column 8) (line 3, column 12) @3:12",
  )
  inspect(
    json("{\"a\":\"\\u12G4\"}"),
    content="Invalid JSON: Bad Unicode escape in JSON at position 10 (line 1 column 11) (line 3, column 15) @3:15",
  )
  inspect(
    json("{\"a\":\"\t\"}"),
    content="Invalid JSON: Bad control character in string literal in JSON at position 6 (line 1 column 7) (line 3, column 11) @3:11",
  )
  inspect(
    json("{\"a\":\"é\\é\"}"),
    content="Invalid JSON: Bad escaped character in JSON at position 8 (line 1 column 9) (line 3, column 13) @3:13",
  )
  inspect(
    json("{\"a\":[1 2]}"),
    content="Invalid JSON: Expected ',' or ']' after array element in JSON at position 8 (line 1 column 9) (line 3, column 13) @3:13",
  )
  inspect(
    json("{\"a\":[1,]}"),
    content="Invalid JSON: Unexpected token ']', \"{\"a\":[1,]}\" is not valid JSON (line 3, column 13) @3:13",
  )
  inspect(
    json("{\"a\":[}"),
    content="Invalid JSON: Unexpected token '}', \"{\"a\":[}\" is not valid JSON (line 3, column 11) @3:11",
  )
  inspect(
    json("{\"a\":1}}"),
    content="Invalid JSON: Unexpected non-whitespace character after JSON at position 7 (line 1 column 8) (line 3, column 12) @3:12",
  )
  inspect(
    json("{\"a\":1} x"),
    content="Invalid JSON: Unexpected non-whitespace character after JSON at position 8 (line 1 column 9) (line 3, column 13) @3:13",
  )
}

///|
test "parse_ordered_json: errors on later lines and with context" {
  inspect(
    json("{\r\n\"a\":\r\n}"),
    content="Invalid JSON: Unexpected token '}', \"{\r\n\"a\":\r\n}\" is not valid JSON (line 5, column 1) @5:1",
  )
  inspect(
    json("{\r\"a\":\r}"),
    content="Invalid JSON: Unexpected token '}', \"{\r\"a\":\r}\" is not valid JSON (line 5, column 1) @5:1",
  )
  inspect(
    json("{\n\n\"a\":\n  x}"),
    content="Invalid JSON: Unexpected token 'x', \"{\n\n\"a\":\n  x}\" is not valid JSON (line 6, column 3) @6:3",
  )
  inspect(
    json(
      "{\"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\": x, \"bbbbbbbbbbbbbbbbbbbbb\": 1}",
    ),
    content="Invalid JSON: Unexpected token 'x', ...\"aaaaaaa\": x, \"bbbbbb\"... is not valid JSON (line 3, column 42) @3:42",
  )
  inspect(
    json("{\"aaaaaaaaaaaaaaaaaaaaaa\": 1, \"b\": x}"),
    content="Invalid JSON: Unexpected token 'x', ...\": 1, \"b\": x}\" is not valid JSON (line 3, column 40) @3:40",
  )
  inspect(
    json("{\"a\":xxxxxxxxxxxxxxxx}"),
    content="Invalid JSON: Unexpected token 'x', \"{\"a\":xxxxxxxxxx\"... is not valid JSON (line 3, column 10) @3:10",
  )
  inspect(
    json("{\"a\":\"\\"),
    content="Invalid JSON: Unexpected end of JSON input (line 3, column 12) @3:12",
  )
  inspect(
    json("{\"a\":\"\\u"),
    content="Invalid JSON: Bad Unicode escape in JSON at position 8 (line 1 column 9) (line 3, column 13) @3:13",
  )
  inspect(
    json("{\"a\":t"),
    content="Invalid JSON: Unexpected end of JSON input (line 3, column 11) @3:11",
  )
  inspect(
    json("{\"a\" :"),
    content="Invalid JSON: Unexpected end of JSON input (line 3, column 11) @3:11",
  )
  inspect(
    json("{\r\n\"a\" 1}"),
    content="Invalid JSON: Expected ':' after property name in JSON at position 7 (line 2 column 5) (line 4, column 5) @4:5",
  )
  inspect(
    json("{\r\"a\" 1}"),
    content="Invalid JSON: Expected ':' after property name in JSON at position 6 (line 2 column 5) (line 4, column 5) @4:5",
  )
  inspect(
    json("{\n\r\"a\" 1}"),
    content="Invalid JSON: Expected ':' after property name in JSON at position 7 (line 3 column 5) (line 5, column 5) @5:5",
  )
  inspect(
    json("{\"a\":\n\r\n1 2}"),
    content="Invalid JSON: Expected ',' or '}' after property value in JSON at position 10 (line 3 column 3) (line 5, column 3) @5:3",
  )
  inspect(
    json("{\"a\":\"\\日\"}"),
    content="Invalid JSON: Unexpected token '日', \"{\"a\":\"\\日\"}\" is not valid JSON (line 3, column 12) @3:12",
  )
  inspect(
    json("{\"a\":日}"),
    content="Invalid JSON: Unexpected token '日', \"{\"a\":日}\" is not valid JSON (line 3, column 10) @3:10",
  )
  inspect(
    json("{\"a\":\""),
    content="Invalid JSON: Unterminated string in JSON at position 6 (line 1 column 7) (line 3, column 11) @3:11",
  )
  inspect(
    json("{\"a"),
    content="Invalid JSON: Unterminated string in JSON at position 3 (line 1 column 4) (line 3, column 8) @3:8",
  )
  inspect(
    json("{\"a\":nul}"),
    content="Invalid JSON: Unexpected token '}', \"{\"a\":nul}\" is not valid JSON (line 3, column 13) @3:13",
  )
  inspect(
    json("{\"a\":1,,}"),
    content="Invalid JSON: Expected double-quoted property name in JSON at position 7 (line 1 column 8) (line 3, column 12) @3:12",
  )
  inspect(
    json("{'a':1}"),
    content="Invalid JSON: Expected property name or '}' in JSON at position 1 (line 1 column 2) (line 3, column 6) @3:6",
  )
  inspect(
    json("{\"a\":true false}"),
    content="Invalid JSON: Expected ',' or '}' after property value in JSON at position 10 (line 1 column 11) (line 3, column 15) @3:15",
  )
  inspect(
    json("{\"a\":{\"b\":1]}"),
    content="Invalid JSON: Expected ',' or '}' after property value in JSON at position 11 (line 1 column 12) (line 3, column 16) @3:16",
  )
  inspect(
    json("{\"a\" : 1 ,"),
    content="Invalid JSON: Expected double-quoted property name in JSON at position 10 (line 1 column 11) (line 3, column 15) @3:15",
  )
}
