///|
const HEAD : String = "eventmodeling\n"

///|
fn big(source : String) -> Result[@types.RenderResult, @errors.Failure] {
  let options = { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), }
  Ok(@core.render([@eventmodeling.eventmodeling], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
}

///|
fn repeat_lines(count : Int32, line : (Int32) -> String) -> String {
  let out = StringBuilder()
  for i in 0..<count {
    out.write_string(line(i))
  }
  out.to_string()
}

///|
fn frame_id(i : Int32) -> String {
  let n = (i % 1000).to_string()
  "0".repeat(3 - n.length()) + n
}

///|
let kinds : Array[String] = ["ui", "cmd", "evt", "rmo", "pcr"]

///|
test "inputs that make a naive scanner rescan the text are read in one pass" {
  let n = 50000
  let cases = [
    HEAD + repeat_lines(1000, i => "tf \{frame_id(i)} \{kinds[i % 5]} E\{i}\n"),
    HEAD + repeat_lines(1000, i => "tf \{frame_id(i)} evt E\{i}\n"),
    HEAD + repeat_lines(1000, i => "tf \{frame_id(i)} evt N\{i}.E\n"),
    HEAD +
    repeat_lines(1000, i => {
      let sources = StringBuilder()
      for k in 0..<@cmp.minimum(i, 9) {
        sources.write_string(" ->> \{frame_id(i - k - 1)}")
      }
      "tf \{frame_id(i)} evt E\{i}\{sources.to_string()}\n"
    }),
    HEAD + "tf 001 cmd A\ntf 002 evt B" + " ->> 001".repeat(9000) + "\n",
    HEAD + "tf 01 evt A\n".repeat(5000),
    HEAD +
    repeat_lines(500, i => "tf \{frame_id(i)} evt E\{i} [[D\{i}]]\n") +
    repeat_lines(500, i => "data D\{i} {\n  a: \{i}\n  b: true\n}\n"),
    HEAD + "tf 01 evt A [[D]]\ndata D {\n" + "a: 1\n".repeat(10000) + "}\n",
    HEAD + "tf 01 evt A { " + "x".repeat(n) + " }\n",
    HEAD + "tf 01 evt A " + "{".repeat(n / 2) + "}".repeat(n / 2) + "\n",
    HEAD +
    "tf 01 evt A\n" +
    repeat_lines(1000, i => {
      "note 01 {\n n\{i}\n}\ngwt 01 given evt A then evt B\n"
    }),
    HEAD +
    "tf 01 evt A\ngwt 01 given" +
    " evt A".repeat(5000) +
    " then" +
    " evt B".repeat(5000) +
    "\n",
    HEAD + "tf 01 evt " + "a.".repeat(10000) + "z\n",
    HEAD + "tf 01 evt " + "a".repeat(n) + "\n",
    HEAD + "tf 01 evt A {\n".repeat(n / 14),
    HEAD + "data D {\n" + "}x\n".repeat(n / 3),
    HEAD + ("{".repeat(99) + "\n").repeat(n / 100),
    HEAD + "tf 01 evt A " + "\"".repeat(n),
    HEAD + "tf 01 evt A '\n".repeat(n / 14),
    HEAD + "/*" + " x\n".repeat(n / 3),
    HEAD + "/* ".repeat(n / 3),
    HEAD + "// c\n".repeat(n / 5),
    HEAD + "%% c\n".repeat(n / 5),
    HEAD + "tf 01 evt A accDescr {\n".repeat(n / 23),
    HEAD + ("x" + " ".repeat(90) + "accDescr ").repeat(n / 100),
    HEAD + "a title b\n".repeat(n / 10),
    HEAD + "x %%{\n".repeat(n / 6),
    HEAD + "x\n---\n".repeat(n / 6),
    HEAD + " \n\t".repeat(n / 3),
    HEAD + "tf " + "1".repeat(n),
    HEAD + "tfevtuidatanote".repeat(n / 15),
  ]
  for source in cases {
    match big(source) {
      Ok(result) => inspect(result.svg.length() > 0, content="true")
      Err(failure) =>
        inspect(failure.code is (Syntax | Semantic | Limit), content="true")
    }
  }
}

///|
test "source over the default limit is refused" {
  let options = @types.RenderOptions::default()
  try {
    ignore(
      @core.render(
        [@eventmodeling.eventmodeling],
        HEAD + "tf 01 evt A\n".repeat(5000),
        options,
      ),
    )
    fail("accepted")
  } catch {
    @errors.PeleError(failure) =>
      inspect(failure.message.contains("limit of 50000"), content="true")
    error => fail("\{error}")
  }
}

///|
test "names that are object keys in pele are plain names" {
  for
    key in ["__proto__", "constructor", "toString", "hasOwnProperty", "valueOf"] {
    let source = "eventmodeling\ntf 01 cmd \{key}.\{key} [[\{key}]]\ntf 02 evt \{key}\ndata \{key} {\n x\n}\nentity \{key}\ngwt 01 given evt \{key} then evt \{key}\n"
    match big(source) {
      Ok(result) => {
        inspect(result.svg.contains("[object"), content="false")
        inspect(result.svg.contains(">x</tspan>"), content="true")
      }
      Err(failure) => fail(failure.message)
    }
  }
}

///|
test "hostile text is escaped in every position" {
  let payload = "<script>alert(1)</script>\"'&"
  let sources = [
    "eventmodeling\ntf 01 cmd A { \{payload} }",
    "eventmodeling\ntf 01 evt A \"\{payload}\"",
    "eventmodeling\ntf 01 evt A '\{payload}'",
    "eventmodeling\ntf 01 rmo A `json`{ \"k\": \"\{payload}\" }",
    "eventmodeling\ntf 01 evt A [[D]]\ndata D {\n  \{payload}\n}\n",
    "eventmodeling\ntf 01 evt A\nnote 01 {\n  \{payload}\n}\n",
    "eventmodeling\ntf 01 evt A\nnote 01 `html` {\n  <div>\{payload}</div>\n}\n",
    "eventmodeling title \{payload}\ntf 01 ui A",
    "eventmodeling accTitle: \{payload}\ntf 01 ui A accDescr: \{payload}",
    "eventmodeling accDescr {\n \{payload}\n}\ntf 01 ui A",
    "eventmodeling\ntf 01 ui \{payload}",
    "eventmodeling\ntf 01 ui A.\{payload}",
    "eventmodeling\ntf 01 evt A\ngwt 01 given evt \{payload} then evt B",
    "eventmodeling\n/* \{payload} */\ntf 01 ui A // \{payload}\n",
  ]
  for source in sources {
    for width in [None, Some(300.0)] {
      let options = { ..@types.RenderOptions::default(), max_width: width, }
      try {
        let result = @core.render(
          [@eventmodeling.eventmodeling],
          source,
          options,
        )
        inspect(result.svg.contains("<script>"), content="false")
        inspect(result.svg.contains("<div>"), content="false")
      } catch {
        @errors.PeleError(failure) =>
          inspect(failure.code is (Syntax | Semantic), content="true")
        error => fail("\{error}")
      }
    }
  }
}
