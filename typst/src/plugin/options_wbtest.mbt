///|
/// The icon resolver the plugin builds from the options written as `json`.
fn icons_of(json : String) -> @types.IconResolver? {
  let options = @util.parse_json(json) catch {
    _ => abort("invalid JSON: \{json}")
  }
  decode_options(options).icons
}

///|
test "an icons object answers each name with its string fragment" {
  guard icons_of(
      "{\"icons\":{\"fa:fa-car\":\"<path/>\",\"empty\":\"\",\"number\":1,\"none\":null}}",
    )
    is Some(resolve) else {
    fail("an object installs a resolver")
  }
  assert_eq(resolve("fa:fa-car"), Some("<path/>"))
  assert_eq(resolve("empty"), Some(""))
  assert_eq(resolve("number"), None)
  assert_eq(resolve("none"), None)
  assert_eq(resolve("missing"), None)
}

///|
test "an empty icons object still installs a resolver" {
  guard icons_of("{\"icons\":{}}") is Some(resolve) else {
    fail("an empty object installs a resolver")
  }
  assert_eq(resolve("fa:fa-car"), None)
}

///|
test "icon names that look like object members are ordinary names" {
  guard icons_of("{\"icons\":{\"__proto__\":\"<path/>\"}}") is Some(resolve) else {
    fail("an object installs a resolver")
  }
  assert_eq(resolve("__proto__"), Some("<path/>"))
  assert_eq(resolve("constructor"), None)
}

///|
test "icons that are not an object install no resolver" {
  assert_eq(icons_of("{\"icons\":[\"fa:fa-car\"]}") is None, true)
  assert_eq(icons_of("{\"icons\":\"fa:fa-car\"}") is None, true)
  assert_eq(icons_of("{\"icons\":null}") is None, true)
  assert_eq(icons_of("{}") is None, true)
}

///|
/// The `monospace` option the plugin reads from the options written as `json`.
fn monospace_of(json : String) -> Array[String]? {
  let options = @util.parse_json(json) catch {
    _ => abort("invalid JSON: \{json}")
  }
  decode_options(options).monospace
}

///|
test "monospace is read as the list of parts it names" {
  assert_eq(monospace_of("{\"monospace\":[\"members\"]}"), Some(["members"]))
  assert_eq(
    monospace_of("{\"monospace\":[\"attributes\",\"members\"]}"),
    Some(["attributes", "members"]),
  )
  assert_eq(monospace_of("{\"monospace\":[]}"), Some([]))
}

///|
test "monospace that is not a list lists no part" {
  assert_eq(monospace_of("{\"monospace\":\"members\"}"), None)
  assert_eq(monospace_of("{\"monospace\":{\"members\":true}}"), None)
  assert_eq(monospace_of("{\"monospace\":true}"), None)
  assert_eq(monospace_of("{\"monospace\":null}"), None)
  assert_eq(monospace_of("{}"), None)
}
