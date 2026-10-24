///|
test "ids are sorted by code units, not by length" {
  let ids = ["Viable", "Desirable", "Feasible"]
  sort_ids(ids)
  inspect(ids.join(","), content="Desirable,Feasible,Viable")
  let mixed = ["b", "B", "a", "ab", "é", "Z"]
  sort_ids(mixed)
  inspect(mixed.join(","), content="B,Z,a,ab,b,é")
}

///|
test "keys are JSON arrays of the ids" {
  inspect(key_of(["A"]), content="A")
  inspect(key_of(["A", "B"]), content="[\"A\",\"B\"]")
  inspect(
    key_of(["a\"b", "c\\d", "e\nf", "\u{1}"]),
    content="[\"a\\\"b\",\"c\\\\d\",\"e\\nf\",\"\\u0001\"]",
  )
  inspect(sorted_key(["B", "A"]), content="[\"A\",\"B\"]")
}
