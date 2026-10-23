///|
/// FNV-1a over UTF-16 code units, the hash under which pele's outcomes were taken.
fn fnv1a(text : String) -> String {
  let mut h : UInt32 = 0x811c9dc5U
  for i in 0..<text.length() {
    h = (h ^ text.unsafe_get(i).to_int().reinterpret_as_uint()) * 0x01000193U
  }
  let digits = "0123456789abcdef"
  let out = StringBuilder()
  for shift in [28, 24, 20, 16, 12, 8, 4, 0] {
    let d = ((h >> shift) & 0xfU).reinterpret_as_int()
    out.write_char(digits.get_char(d).unwrap())
  }
  out.to_string()
}

///|
/// What rendering gives, written as the generator of pele's outcomes writes them.
fn render_outcome(
  source : String,
  options~ : @types.RenderOptions = @types.RenderOptions::default(),
) -> String {
  let r = drawn(source, options~) catch {
    @errors.PeleError(failure) =>
      return "error \{failure.code.to_string()}\n\{failure.message}"
    error => return "foreign \{error}"
  }
  let links = r.links.map(l => "\{l.id}|\{l.href}|\{l.internal}").join(";")
  "ok \{r.width} \{r.height} \{links}\n\{r.svg}"
}

///|
fn hostile_sources(p : String) -> Array[String] {
  [
    "swimlane-beta TD\n  subgraph L[\"\{p}\"]\n    a\n  end",
    "swimlane-beta LR\n  subgraph L[\"\{p}\"]\n    a[\"\{p}\"] -- \"\{p}\" --> b\n  end",
    "swimlane-beta TD\n  subgraph \{p}\n    a\n  end",
    "swimlane-beta \{p}\n  a --> b",
    "swimlane-beta TD\n  subgraph L\n    a\n  end\n  style L \{p}\n  class L \{p}",
    "swimlane-beta LR\n  subgraph L\n    a\n  end\n  click a \"\{p}\" \"\{p}\"\n  L:::\{p}",
    "---\ntitle: \"\{p}\"\nconfig:\n  swimlane: \"\{p}\"\n---\nswimlane-beta TD\n  a",
    "swimlane-beta RL\n  subgraph L[\"`**\{p}**`\"]\n    a\n  end\n  accTitle: \{p}\n  accDescr: \{p}",
  ]
}

///|
test "hostile text in every position is drawn as pele draws it" {
  let outcomes = Array::makei(8, _ => [])
  for payload in hostile_payloads {
    for t, source in hostile_sources(payload) {
      outcomes[t].push(fnv1a(render_outcome(source)))
    }
  }
  let all = outcomes.flatten()
  assert_eq(all.length(), hostile_outcomes.length())
  let wrong = []
  for k, hash in all {
    if hash != hostile_outcomes[k] {
      let t = k / hostile_payloads.length()
      let p = k % hostile_payloads.length()
      wrong.push("template \{t} payload \{p}")
    }
  }
  inspect(wrong.join("\n"), content="")
}

///|
test "draws lane names that are object keys in pele as plain names" {
  for name in ["__proto__", "constructor", "toString", "hasOwnProperty"] {
    let svg = svg_of(
      "swimlane-beta TD\n  subgraph \{name}\n    a --> b\n  end\n  subgraph other\n    c\n  end\n  b --> c",
    )
    assert_eq(lanes(svg).length(), 2, msg=name)
    assert_false(svg.contains("[object"), msg=name)
  }
}

///|
test "draws Mermaid's documentation examples as pele draws them" {
  for example in docs_examples {
    let (source, natural, narrow) = example
    assert_eq(fnv1a(render_outcome(source)), natural, msg=source)
    assert_eq(
      fnv1a(render_outcome(source, options=options(max_width=480))),
      narrow,
      msg=source,
    )
  }
}

///|
fn lane_block(count : Int32, body : (Int32) -> String) -> String {
  let out = StringBuilder()
  for k in 0..<count {
    if k > 0 {
      out.write_string("\n")
    }
    out.write_string("  subgraph L\{k}\n\{body(k)}\n  end")
  }
  out.to_string()
}

///|
fn lines(
  count : Int32,
  line : (Int32) -> String,
  sep~ : String = "\n",
) -> String {
  let out = StringBuilder()
  for i in 0..<count {
    if i > 0 {
      out.write_string(sep)
    }
    out.write_string(line(i))
  }
  out.to_string()
}

///|
/// Renders without a size limit, and checks that the drawing has no number JavaScript could not write.
fn finishes(source : String) -> Unit raise {
  let options = { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), }
  let result = drawn(source, options~) catch {
    @errors.PeleError(_) => return
    error => raise error
  }
  assert_false(result.svg.contains("NaN"))
  assert_false(result.svg.contains("Infinity"))
}

///|
test "2,000 nodes in 20 lanes with 3,000 edges" {
  let src = StringBuilder()
  src.write_string("swimlane-beta TD\n")
  src.write_string(lane_block(20, k => lines(100, i => "    n\{k}_\{i}")))
  src.write_string("\n")
  let mut seed = 7
  // pele multiplies in doubles, which round past 2^53 before the mask, so the same edges come only from the same rounding.
  let next = (n : Int32) => {
    let v = seed.to_double() * 1103515245.0 + 12345.0
    seed = (v.to_int64() & 0x7fffffffL).to_int()
    seed % n
  }
  for _ in 0..<3000 {
    let a = next(20)
    let b = next(100)
    let c = next(20)
    let d = next(100)
    src.write_string("  n\{a}_\{b} --> n\{c}_\{d}\n")
  }
  finishes(src.to_string())
}

///|
test "one long chain that changes lane at every step" {
  let src = StringBuilder()
  src.write_string("swimlane-beta LR\n")
  src.write_string(lane_block(8, k => lines(250, i => "    n\{i * 8 + k}")))
  src.write_string("\n")
  for i in 0..<1999 {
    src.write_string("  n\{i} --> n\{i + 1}\n")
  }
  finishes(src.to_string())
}

///|
test "500 lanes" {
  finishes(
    "swimlane-beta TD\n" + lane_block(500, k => "    a\{k} --> b\{k}") + "\n",
  )
}

///|
test "edges that span 1,500 ranks" {
  let src = StringBuilder()
  src.write_string("swimlane-beta TD\n  subgraph A\n")
  for i in 0..<1500 {
    src.write_string("    a\{i} --> a\{i + 1}\n")
  }
  src.write_string("  end\n  subgraph B\n    b\n  end\n")
  for i in 0..<40 {
    src.write_string("  a0 --> a\{1500 - i}\n  b --> a\{1400 - i}\n")
  }
  finishes(src.to_string())
}

///|
test "3,000 labelled edges between two nodes" {
  finishes(
    "swimlane-beta TD\n  subgraph A\n    a\n  end\n  subgraph B\n    b\n  end\n" +
    "  a -- label --> b\n".repeat(3000),
  )
}

///|
test "3,000 self-loops" {
  finishes(
    "swimlane-beta TD\n  subgraph A\n    a\n  end\n" +
    "  a --> a\n".repeat(3000),
  )
}

///|
test "groups nested 2,000 deep in a lane" {
  finishes(
    "swimlane-beta TD\n  subgraph L\n" +
    lines(2000, i => "subgraph g\{i}\n", sep="") +
    "a --> b\n" +
    "end\n".repeat(2001),
  )
}

///|
test "1,000 edges between lanes themselves" {
  finishes(
    "swimlane-beta TD\n" +
    lane_block(20, k => "    a\{k}") +
    "\n" +
    lines(1000, i => "  L\{i % 20} --> L\{(i * 7 + 3) % 20}") +
    "\n",
  )
}

///|
test "a cycle through every node" {
  let src = StringBuilder()
  src.write_string("swimlane-beta RL\n")
  src.write_string(lane_block(10, k => lines(100, i => "    n\{k * 100 + i}")))
  src.write_string("\n")
  for i in 0..<1000 {
    let j = (i * 37 + 11) % 1000
    src.write_string("  n\{i} --> n\{j}\n  n\{j} --> n\{i}\n")
  }
  finishes(src.to_string())
}
