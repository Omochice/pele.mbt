///|
test "parse_generic_types turns tilde pairs into angle brackets" {
  inspect(@common.parse_generic_types("List~int~"), content="List<int>")
  inspect(@common.parse_generic_types("Map~K,V~"), content="Map<K,V>")
  inspect(
    @common.parse_generic_types("Array~Array~string~~"),
    content="Array<Array<string>>",
  )
  inspect(@common.parse_generic_types("a~b"), content="a~b")
  inspect(@common.parse_generic_types("plain"), content="plain")
}

///|
test "parse_generic_types keeps Mermaid's quirks around commas" {
  let cases = [
    ("~a,b~,~c,d~", "<c,d>"),
    ("~,~,~", "<,>"),
    ("a~,~b", "a<,>b"),
    ("~a~,~b~", "<a>,<b>"),
    ("~~,~~", "<>,<>"),
    ("A~B~,~C", "A<B>,~C"),
    ("~,", "~,"),
    (",~", ",~"),
    ("~a,b,c~", "~a,b,c~"),
    ("x~a~,b~", "x<a>,b~"),
    ("~~~", "~<>"),
    ("~~~~~", "~<<>>"),
    ("List~~T~~", "List<<T>>"),
    ("\u{1f408}~a~", "\u{1f408}<a>"),
  ]
  for case in cases {
    let (input, expected) = case
    assert_eq(@common.parse_generic_types(input), expected, msg=input)
  }
}

///|
test "parse_generic_types matches pele on every string of up to eight tildes, commas, letters and spaces" {
  let expected = [
    "811c9dc5", "cdd402e8", "e595b3af", "7820b271", "608d49fb", "cfb8011d", "9aa2fc29",
    "4ccfb3ad", "11d74503",
  ]
  for length, hash in expected {
    let outputs = strings_over(["~", ",", "a", " "], length).map(
      @common.parse_generic_types,
    )
    assert_eq(fnv1a(outputs.join("\n")), hash, msg="length \{length}")
  }
}

///|
test "parse_generic_types stays fast on long runs of commas and tildes" {
  let commas = @common.parse_generic_types("~" + ",".repeat(50000) + "~")
  assert_eq(commas.length(), 50002)
  assert_eq(fnv1a(commas), "9166c6cd")
  let nested = @common.parse_generic_types(
    "a~".repeat(25000) + ",".repeat(1000) + "~b".repeat(25000),
  )
  assert_eq(nested.length(), 101000)
  assert_eq(fnv1a(nested), "cff4ce8d")
}
