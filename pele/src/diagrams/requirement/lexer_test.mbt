// The expected streams are what pele v1.8.0's tokenize gives for the same text.

///|
fn tokens_of(src : String) -> String {
  let tokens = @requirement.tokenize(src)
  let out = []
  for i, kind in tokens.types {
    let text = tokens.texts[i]
    out.push(
      "\{@requirement.token_names[kind]}@\{tokens.starts[i]}" +
      (if text == "" { "" } else { "=" + text.escape() }),
    )
  }
  out.join(" ")
}

///|
/// The tokens of a text as type@start=text, joined as the generator of the hashes below joins them.
fn raw_tokens(src : String) -> String {
  let tokens = @requirement.tokenize(src)
  let out = []
  for i, kind in tokens.types {
    out.push("\{kind}@\{tokens.starts[i]}=\{tokens.texts[i]}")
  }
  out.join("\u{1}")
}

///|
/// FNV-1a over UTF-16 code units, the hash under which the expected outputs below were taken from pele.
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
/// Every string of exactly `length` pieces drawn from `pieces`, in lexicographic order of piece indices.
fn strings_over(pieces : Array[String], length : Int32) -> Array[String] {
  let mut out = [""]
  for _ in 0..<length {
    let next = []
    for prefix in out {
      for piece in pieces {
        next.push(prefix + piece)
      }
    }
    out = next
  }
  out
}

///|
test "tokens match pele for every string of up to four lexical pieces" {
  let pieces = [
    " ", "\n", "\r", ":", "a", "-", ">", "<", "{", "}", "\"", ",", "%", "style",
    "direction", "lr", "accDescr", "title",
  ]
  let expected = ["6f287e9c", "d4c5e81c", "657ceaef", "52c2a45b", "55febc37"]
  for length in 0..<=4 {
    let outputs = strings_over(pieces, length).map(raw_tokens)
    assert_eq(
      fnv1a(outputs.join("\u{2}")),
      expected[length],
      msg="length \{length}",
    )
  }
}

///|
test "reads a requirement body with keywords in any case" {
  inspect(
    tokens_of(
      "requirementDiagram\nRequirement A {\nID: x\nRISK: HIGH\nVerifyMethod: Test\n}\n",
    ),
    content="RD@0=\"requirementDiagram\" NEWLINE@18=\"\\n\" REQUIREMENT@19=\"Requirement\" unqString@31=\"A\" STRUCT_START@33=\"{\" NEWLINE@34=\"\\n\" ID@35=\"ID\" COLONSEP@37=\":\" unqString@39=\"x\" NEWLINE@40=\"\\n\" RISK@41=\"RISK\" COLONSEP@45=\":\" HIGH_RISK@47=\"HIGH\" NEWLINE@51=\"\\n\" VERIFYMTHD@52=\"VerifyMethod\" COLONSEP@64=\":\" VERIFY_TEST@66=\"Test\" NEWLINE@70=\"\\n\" STRUCT_STOP@71=\"}\" NEWLINE@72=\"\\n\" EOF@73 $end@73",
  )
}

///|
test "reads quoted names, unquoted strings and both arrows" {
  inspect(
    tokens_of(
      "requirementDiagram\nelement \"x y\" {\ntype: t\ndocRef: d\n}\na - contains -> b\nb <- traces - c\n",
    ),
    content="RD@0=\"requirementDiagram\" NEWLINE@18=\"\\n\" ELEMENT@19=\"element\" qString@28=\"x y\" STRUCT_START@33=\"{\" NEWLINE@34=\"\\n\" TYPE@35=\"type\" COLONSEP@39=\":\" unqString@41=\"t\" NEWLINE@42=\"\\n\" DOCREF@43=\"docRef\" COLONSEP@49=\":\" unqString@51=\"d\" NEWLINE@52=\"\\n\" STRUCT_STOP@53=\"}\" NEWLINE@54=\"\\n\" unqString@55=\"a\" LINE@57=\"-\" CONTAINS@59=\"contains\" END_ARROW_R@68=\"->\" unqString@71=\"b\" NEWLINE@72=\"\\n\" unqString@73=\"b\" END_ARROW_L@75=\"<-\" TRACES@78=\"traces\" LINE@85=\"-\" unqString@87=\"c\" NEWLINE@88=\"\\n\" EOF@89 $end@89",
  )
}

///|
test "reads style statements up to the end of their line" {
  inspect(
    tokens_of(
      "requirementDiagram\nstyle a,b fill:#f9f,stroke-width:4px\nclassDef c color:red;\nclass a c\na:::c,d\n",
    ),
    content="RD@0=\"requirementDiagram\" NEWLINE@18=\"\\n\" STYLE@19=\"style\" ALPHA@25=\"a\" COMMA@26=\",\" ALPHA@27=\"b\" ALPHA@29=\"fill\" COLON@33=\":\" BRKT@34=\"#\" ALPHA@35=\"f9f\" COMMA@38=\",\" ALPHA@39=\"stroke\" MINUS@45=\"-\" ALPHA@46=\"width\" COLON@51=\":\" ALPHA@52=\"4px\" CLASSDEF@56=\"classDef\" ALPHA@65=\"c\" ALPHA@67=\"color\" COLON@72=\":\" ALPHA@73=\"red\" SEMICOLON@76=\";\" CLASS@78=\"class\" ALPHA@84=\"a\" ALPHA@86=\"c\" unqString@88=\"a\" STYLE_SEPARATOR@89=\":::\" unqString@92=\"c\" COMMA@93=\",\" unqString@94=\"d\" NEWLINE@95=\"\\n\" EOF@96 $end@96",
  )
  inspect(
    tokens_of("requirementDiagram\nstyle a fill:\"x\" ,%-\n"),
    content="RD@0=\"requirementDiagram\" NEWLINE@18=\"\\n\" STYLE@19=\"style\" ALPHA@25=\"a\" ALPHA@27=\"fill\" COLON@31=\":\" qString@33=\"x\" COMMA@36=\",\" PERCENT@37=\"%\" MINUS@38=\"-\" EOF@40 $end@40",
  )
}

///|
test "reads accessible titles and descriptions" {
  inspect(
    tokens_of(
      "accTitle: t \naccDescr: d\naccDescr {\n x\n}\nrequirementDiagram\n",
    ),
    content="acc_title@0=\"accTitle: \" acc_title_value@10=\"t \" NEWLINE@12=\"\\n\" acc_descr@13=\"accDescr: \" acc_descr_value@23=\"d\" NEWLINE@24=\"\\n\" acc_descr_multiline_value@37=\"x\\n\" NEWLINE@40=\"\\n\" RD@41=\"requirementDiagram\" NEWLINE@59=\"\\n\" EOF@60 $end@60",
  )
}

///|
test "a line holding a direction statement anywhere is one token" {
  inspect(
    tokens_of(
      "requirementDiagram\ndirection LR\nfoo direction tb bar\n  direction\n RL\n",
    ),
    content="RD@0=\"requirementDiagram\" NEWLINE@18=\"\\n\" direction_lr@19=\"direction LR\" NEWLINE@31=\"\\n\" direction_tb@32=\"foo direction tb bar\" NEWLINE@52=\"\\n\" direction_rl@53=\"  direction\\n RL\" NEWLINE@68=\"\\n\" EOF@69 $end@69",
  )
  inspect(
    tokens_of(
      "requirementDiagram\na direction LR direction TB\nx direction BT\ndirection RL",
    ),
    content="RD@0=\"requirementDiagram\" NEWLINE@18=\"\\n\" direction_tb@19=\"a direction LR direction TB\" NEWLINE@46=\"\\n\" direction_bt@47=\"x direction BT\" NEWLINE@61=\"\\n\" direction_rl@62=\"direction RL\" EOF@74 $end@74",
  )
}

///|
test "reads titles and skips comments" {
  inspect(
    tokens_of("requirementDiagram\ntitle My diagram\ntitle\n# c\n%% d\n"),
    content="RD@0=\"requirementDiagram\" NEWLINE@18=\"\\n\" title@19=\"title My diagram\" NEWLINE@35=\"\\n\" unqString@36=\"title\" NEWLINE@41=\"\\n\" NEWLINE@45=\"\\n\" NEWLINE@50=\"\\n\" EOF@51 $end@51",
  )
}

///|
test "takes a run of line breaks as one newline" {
  inspect(
    tokens_of("requirementDiagram\r\n\r\nrequirement a {\r\n}\r\n"),
    content="RD@0=\"requirementDiagram\" NEWLINE@18=\"\\r\\n\\r\\n\" REQUIREMENT@22=\"requirement\" unqString@34=\"a\" STRUCT_START@36=\"{\" NEWLINE@37=\"\\r\\n\" STRUCT_STOP@39=\"}\" NEWLINE@40=\"\\r\\n\" EOF@42 $end@42",
  )
}

///|
test "stops at text no rule matches" {
  inspect(
    tokens_of("requirementDiagram\na < b\n"),
    content="RD@0=\"requirementDiagram\" NEWLINE@18=\"\\n\" unqString@19=\"a\" INVALID@21",
  )
  inspect(
    tokens_of("requirementDiagram\na = b\n"),
    content="RD@0=\"requirementDiagram\" NEWLINE@18=\"\\n\" unqString@19=\"a\" INVALID@21",
  )
  inspect(
    tokens_of("requirementDiagram\nstyle a stroke-width:1.5px\n"),
    content="RD@0=\"requirementDiagram\" NEWLINE@18=\"\\n\" STYLE@19=\"style\" ALPHA@25=\"a\" ALPHA@27=\"stroke\" MINUS@33=\"-\" ALPHA@34=\"width\" COLON@39=\":\" ALPHA@40=\"1\" INVALID@41",
  )
}

///|
test "ends an unclosed string or description with an empty token" {
  inspect(
    tokens_of("requirementDiagram\nelement \"unclosed"),
    content="RD@0=\"requirementDiagram\" NEWLINE@18=\"\\n\" ELEMENT@19=\"element\" qString@28=\"unclosed\" qString@36 $end@36",
  )
  inspect(
    tokens_of("requirementDiagram\naccDescr {\n unclosed"),
    content="RD@0=\"requirementDiagram\" NEWLINE@18=\"\\n\" acc_descr_multiline_value@31=\"unclosed\" acc_descr_multiline_value@39 $end@39",
  )
  inspect(
    tokens_of("requirementDiagram\naccTitle:"),
    content="RD@0=\"requirementDiagram\" NEWLINE@18=\"\\n\" acc_title@19=\"accTitle:\" acc_title_value@28 $end@28",
  )
}

///|
test "an unquoted string runs to a stop character and is trimmed" {
  inspect(
    tokens_of("requirementDiagram\nreq_with_a_very_long_name_x y : z\n"),
    content="RD@0=\"requirementDiagram\" NEWLINE@18=\"\\n\" unqString@19=\"req_with_a_very_long_name_x y\" COLONSEP@49=\":\" unqString@51=\"z\" NEWLINE@52=\"\\n\" EOF@53 $end@53",
  )
  inspect(
    tokens_of("requirementDiagram\n  element   b  c {\n}\n"),
    content="RD@0=\"requirementDiagram\" NEWLINE@18=\"\\n\" ELEMENT@21=\"element\" unqString@31=\"b  c\" STRUCT_START@36=\"{\" NEWLINE@37=\"\\n\" STRUCT_STOP@38=\"}\" NEWLINE@39=\"\\n\" EOF@40 $end@40",
  )
}
