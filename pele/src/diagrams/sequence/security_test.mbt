// Ported from pele v1.8.0, tests/render/sequence-security.test.ts and tests/support/inert.ts, with a hash of what pele's render gives each case.
// pele also checks that every drawing is inert markup; matching pele's drawing byte for byte carries that over.

///|
/// FNV-1a over UTF-16 code units, the hash under which the outcomes were taken from pele.
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
/// The text as `JSON.stringify` writes a string.
fn json_string(text : String) -> String {
  let out = StringBuilder()
  out.write_char('"')
  let hex = (c : Int32) => {
    let digits = "0123456789abcdef"
    let s = StringBuilder()
    for shift in [12, 8, 4, 0] {
      s.write_char(digits.get_char((c >> shift) & 0xf).unwrap())
    }
    "\\u" + s.to_string()
  }
  for i in 0..<text.length() {
    let c = text.unsafe_get(i).to_int()
    let next = if i + 1 < text.length() {
      text.unsafe_get(i + 1).to_int()
    } else {
      -1
    }
    let prev = if i > 0 { text.unsafe_get(i - 1).to_int() } else { -1 }
    match c {
      34 => out.write_string("\\\"")
      92 => out.write_string("\\\\")
      8 => out.write_string("\\b")
      12 => out.write_string("\\f")
      10 => out.write_string("\\n")
      13 => out.write_string("\\r")
      9 => out.write_string("\\t")
      _ if c < 0x20 => out.write_string(hex(c))
      _ if c >= 0xd800 && c <= 0xdbff && !(next >= 0xdc00 && next <= 0xdfff) =>
        out.write_string(hex(c))
      _ if c >= 0xdc00 && c <= 0xdfff && !(prev >= 0xd800 && prev <= 0xdbff) =>
        out.write_string(hex(c))
      _ => @util.write_range(out, text, i, i + 1)
    }
  }
  out.write_char('"')
  out.to_string()
}

///|
/// What rendering gives, written as the generator of the outcomes writes pele's.
fn outcome(source : String, options? : @types.RenderOptions) -> String {
  let options = options.unwrap_or(@types.RenderOptions::default())
  let result = Ok(@core.render([@sequence.sequence], source, options)) catch {
    @errors.PeleError(failure) => Err(failure)
  }
  match result {
    Ok(r) => {
      let links = r.links.map(l => "\{l.id}|\{l.href}|\{l.internal}").join(";")
      "ok \{r.width} \{r.height} \{links}\n\{r.svg}"
    }
    Err(failure) => "error \{failure.code.to_string()}\n\{failure.message}"
  }
}

///|
test "hostile text in every position is drawn as pele draws it" {
  let wrong = []
  let mut k = 0
  for t, template in hostile_templates {
    for p, payload in hostile_payloads {
      if fnv1a(outcome(template(payload))) != hostile_outcomes[k] {
        wrong.push("template \{t} payload \{p}")
      }
      k += 1
    }
  }
  inspect(k == hostile_outcomes.length(), content="true")
  inspect(wrong.join("\n"), content="")
}

///|
test "hostile option values are drawn as pele draws them" {
  let source = "sequenceDiagram\n  accTitle: t\n  accDescr: d\n  autonumber\n  A->>+B: x\n  Note over A: n\n  B-->>-A: y"
  let wrong = []
  for p, payload in hostile_payloads {
    let named = {
      ..@types.RenderOptions::default(),
      id_prefix: Some(payload),
      font_family: Some(payload),
    }
    let settings = {
      ..@types.RenderOptions::default(),
      config: Some({
        "sequence": {
          "messageAlign": Json::string(payload),
          "width": Json::string(payload),
          "mirrorActors": Json::string(payload),
        },
      }),
    }
    if fnv1a(outcome(source, options=named)) != hostile_option_outcomes[2 * p] {
      wrong.push("payload \{p} as the id prefix and font")
    }
    if fnv1a(outcome(source, options=settings)) !=
      hostile_option_outcomes[2 * p + 1] {
      wrong.push("payload \{p} as sequence settings")
    }
  }
  inspect(wrong.join("\n"), content="")
}

///|
test "extreme numbers in the config are drawn as pele draws them" {
  let source = "sequenceDiagram\n  box B\n  participant A\n  end\n  A->>C: x\n  Note over A,C: n\n  loop l\n  C->>C: y\n  end"
  let values : Array[Json] = [
    Json::number(1.0 / 0.0),
    Json::number(-1.0 / 0.0),
    Json::number(-1),
    Json::number(0),
    Json::number(1.0e308),
    Json::number(1.0e-308),
    Json::string("12"),
    Json::null(),
  ]
  let hashes = values.map(value => {
    let sequence : Json = {
      "width": value,
      "height": value,
      "actorMargin": value,
      "messageMargin": value,
      "noteMargin": value,
      "boxMargin": value,
    }
    let options = {
      ..@types.RenderOptions::default(),
      config: Some({ "sequence": sequence }),
    }
    fnv1a(outcome(source, options~))
  })
  hashes.push(
    fnv1a(
      outcome(
        "sequenceDiagram\n  autonumber " +
        "9".repeat(400) +
        " " +
        "9".repeat(400) +
        "\n  A->>B: x\n  B->>A: y",
      ),
    ),
  )
  inspect(hashes == extreme_outcomes, content="true")
}

///|
test "never emits a link for participant menus" {
  let svg = outcome(
    "sequenceDiagram\n  participant A\n  link A: x @ javascript:alert(1)\n  links A: {\"y\": \"javascript:alert(1)\"}\n  A->>B: hi",
  )
  inspect(svg.contains("javascript"), content="false")
  inspect(svg.contains("<a"), content="false")
}

///|
test "passes colors through the style filter" {
  let svg = outcome(
    "sequenceDiagram\n  rect url(javascript:alert(1))\n  A->>B: hi\n  end\n  rect red\n  B->>A: yo\n  end",
  )
  inspect(svg.contains("url("), content="false")
  inspect(svg.contains("style=\"rx:var(--_r);fill:red;\""), content="true")
}

///|
test "keeps prototype names as plain keys" {
  inspect(
    outcome(
      "sequenceDiagram\n  participant __proto__\n  participant constructor\n  __proto__->>constructor: toString\n  Note over __proto__,constructor: hasOwnProperty",
    ).has_prefix("ok "),
    content="true",
  )
  let db = @sequence.SeqDb::new()
  @sequence.parse_sequence(
    "sequenceDiagram\n  participant A\n  links A: {\"__proto__\": \"x\", \"toString\": \"y\"}",
    db,
  )
  let keys = []
  for key, _ in db.actors.get("A").unwrap().links {
    keys.push(key)
  }
  inspect(keys.join(","), content="__proto__,toString")
}

///|
/// Each template as a function of its payload, with `json_string` where pele writes `JSON.stringify(p)`.
let hostile_templates : Array[(String) -> String] = [
  p => "sequenceDiagram\n  participant " + p + "\n  A->>B: x",
  p => "sequenceDiagram\n  actor " + p + "\n  A->>B: x",
  p => "sequenceDiagram\n  participant A as " + p + "\n  A->>B: x",
  p => "sequenceDiagram\n  actor A as " + p + "\n  A->>B: x",
  p => {
    "sequenceDiagram\n  participant A@{ \"type\": " +
    json_string(p) +
    " }\n  A->>B: x"
  },
  p => {
    "sequenceDiagram\n  participant A@{ \"type\": \"database\", \"alias\": " +
    json_string(p) +
    " }\n  A->>B: x"
  },
  p => {
    "sequenceDiagram\n  participant A@{ " +
    json_string(p) +
    ": \"x\", \"alias\": \"y\" }\n  A->>B: x"
  },
  p => "sequenceDiagram\n  participant A@{ " + p + " }\n  A->>B: x",
  p => {
    "sequenceDiagram\n  participant A@{ \"type\": \"queue\" } as " +
    p +
    "\n  A->>B: x"
  },
  p => "sequenceDiagram\n  " + p + "->>B: x",
  p => "sequenceDiagram\n  A->>" + p + ": x",
  p => "sequenceDiagram\n  A->>B: " + p,
  p => {
    "sequenceDiagram\n  A->>B: wrap: " +
    p +
    " and some more words to wrap around the corner of the label"
  },
  p => "sequenceDiagram\n  A->>A: " + p,
  p => "sequenceDiagram\n  A-x+B: " + p + "\n  B--)-A: " + p,
  p => "sequenceDiagram\n  A()->>()B: " + p,
  p => "sequenceDiagram\n  A " + p + " B: x",
  p => "sequenceDiagram\n  Note left of A: " + p,
  p => "sequenceDiagram\n  Note right of A: " + p,
  p => "sequenceDiagram\n  Note over A,B: " + p,
  p => "sequenceDiagram\n  Note over " + p + ": x",
  p => "sequenceDiagram\n  Note over A: wrap: " + p,
  p => "sequenceDiagram\n  loop " + p + "\n  A->>B: x\n  end",
  p => {
    "sequenceDiagram\n  alt " +
    p +
    "\n  A->>B: x\n  else " +
    p +
    "\n  B->>A: y\n  end"
  },
  p => "sequenceDiagram\n  opt " + p + "\n  A->>B: x\n  end",
  p => {
    "sequenceDiagram\n  par " +
    p +
    "\n  A->>B: x\n  and " +
    p +
    "\n  B->>A: y\n  end"
  },
  p => "sequenceDiagram\n  par_over " + p + "\n  A->>B: x\n  end",
  p => {
    "sequenceDiagram\n  critical " +
    p +
    "\n  A->>B: x\n  option " +
    p +
    "\n  B->>A: y\n  end"
  },
  p => "sequenceDiagram\n  break " + p + "\n  A->>B: x\n  end",
  p => "sequenceDiagram\n  rect " + p + "\n  A->>B: x\n  end",
  p => "sequenceDiagram\n  rect rgb(0, 0, 0)" + p + "\n  A->>B: x\n  end",
  p => "sequenceDiagram\n  box " + p + "\n  participant A\n  end\n  A->>B: x",
  p => {
    "sequenceDiagram\n  box red " + p + "\n  participant A\n  end\n  A->>B: x"
  },
  p => {
    "sequenceDiagram\n  box rgb(1, 2, 3)" +
    p +
    "\n  participant A\n  end\n  A->>B: x"
  },
  p => {
    "sequenceDiagram\n  box rgb(" +
    p +
    ") T\n  participant A\n  end\n  A->>B: x"
  },
  p => "sequenceDiagram\n  title " + p + "\n  A->>B: x",
  p => "sequenceDiagram\n  title: " + p + "\n  A->>B: x",
  p => {
    "sequenceDiagram\n  accTitle: " + p + "\n  accDescr: " + p + "\n  A->>B: x"
  },
  p => "sequenceDiagram\n  accDescr {\n " + p + "\n }\n  A->>B: x",
  p => {
    "sequenceDiagram\n  participant A\n  links A: {" +
    json_string(p) +
    ": " +
    json_string(p) +
    "}\n  A->>B: x"
  },
  p => "sequenceDiagram\n  participant A\n  links A: " + p + "\n  A->>B: x",
  p => {
    "sequenceDiagram\n  participant A\n  link A: " +
    p +
    " @ " +
    p +
    "\n  A->>B: x"
  },
  p => {
    "sequenceDiagram\n  participant A\n  link A: Docs @ " + p + "\n  A->>B: x"
  },
  p => {
    "sequenceDiagram\n  participant A\n  properties A: {\"class\": " +
    json_string(p) +
    ", " +
    json_string(p) +
    ": " +
    json_string(p) +
    "}\n  A->>B: x"
  },
  p => "sequenceDiagram\n  participant A\n  properties A: " + p + "\n  A->>B: x",
  p => "sequenceDiagram\n  participant A\n  details A: " + p + "\n  A->>B: x",
  p => "sequenceDiagram\n  autonumber " + p + "\n  A->>B: x",
  p => "sequenceDiagram\n  autonumber\n  A->>B: " + p + "\n  A->>A: " + p,
  p => {
    "sequenceDiagram\n  A->>B: x\n  create participant " +
    p +
    "\n  A->>" +
    p +
    ": y"
  },
  p => {
    "sequenceDiagram\n  A->>B: x\n  create actor C as " +
    p +
    "\n  A->>C: y\n  destroy C\n  C-xA: " +
    p
  },
  p => "sequenceDiagram\n  activate " + p + "\n  A->>B: x",
  p => "sequenceDiagram\n  A->>B: x\n  %% " + p + "\n  B->>A: y # " + p,
  p => "sequenceDiagram " + p + "\n  A->>B: x",
  p => {
    "---\ntitle: " +
    json_string(p) +
    "\nconfig:\n  sequence:\n    messageAlign: " +
    json_string(p) +
    "\n    noteAlign: " +
    json_string(p) +
    "\n---\nsequenceDiagram\n  A->>B: x"
  },
  p => {
    "%%{init: {\"sequence\": {\"width\": " +
    json_string(p) +
    ", \"actorMargin\": " +
    json_string(p) +
    ", \"mirrorActors\": " +
    json_string(p) +
    ", \"messageFontFamily\": " +
    json_string(p) +
    "}, \"themeVariables\": {\"fontFamily\": " +
    json_string(p) +
    "}}}%%\nsequenceDiagram\n  A->>B: x"
  },
]

///|
let hostile_payloads : Array[String] = [
  "<script>alert(1)</script>", "\"><script>alert(1)</script>", "<img src=x onerror=alert(1)>",
  "<svg onload=alert(1)>", "<a href=\"javascript:alert(1)\">x</a>", "<foreignObject><iframe src=javascript:alert(1)></iframe></foreignObject>",
  "</text></g></svg><script>alert(1)</script>", "javascript:alert(1)", "JaVaScRiPt:alert(1)",
  " javascript:alert(1)", "jav&#x09;ascript:alert(1)", "data:text/html,<script>alert(1)</script>",
  "vbscript:msgbox(1)", "' onload='alert(1)", "\" onmouseover=\"alert(1)", "x\" onclick=\"alert(1)\" y=\"",
  "#60;script#62;alert(1)#60;/script#62;", "#106;avascript:alert(1)", "#34; onload=#34;alert(1)",
  "url#40;javascript:alert#40;1#41;#41;", "red#59;background:url#40;//evil.example/x#41;",
  "&lt;script&gt;alert(1)&lt;/script&gt;", "&#60;script&#62;", "url(javascript:alert(1))",
  "expression(alert(1))", "red;background:url(//evil.example/x)", "red\" onload=\"alert(1)",
  "]]><script>alert(1)</script>", "--><script>alert(1)</script>", "\u{0}\u{1}\u{8}\u{b}\u{1f}",
  "u\u{1}rl(//evil.example/x)", "__proto__", "constructor", "toString", "hasOwnProperty",
  "{{7*7}}", "${alert(1)}", "%0ajavascript:alert(1)", "file:///etc/passwd", "//evil.example/share",
  "\\\\evil.example\\share", "smb://evil.example/share", "obsidian://open?vault=x",
  "\\\"><script>",
]

///|
/// The hash of the outcome for every template with every payload, template by template.
let hostile_outcomes : Array[String] = [
  "d63712fb", "d16c30ef", "352186f8", "26885a90", "e6cad240", "4e82abe6", "22fbb680",
  "4f72e435", "0be4da55", "4c2da510", "d1fdf515", "feb415a8", "4a577081", "15eb3f25",
  "f1cfbe00", "e89ecc14", "44f79d68", "e4036375", "bb59e284", "b20658dd", "c8794b89",
  "a93598bc", "13abfa94", "85c5282d", "7517be0e", "909f6d33", "1260adb7", "9c7d9fc5",
  "b6978125", "4e5300a8", "31f7f146", "1d215d00", "fb67b2d7", "7460da4e", "9f29005d",
  "22f6ce17", "35cbd180", "ad42402f", "c576fa54", "b1e24ea8", "d2126437", "37b0d4da",
  "5a7619fb", "5655ea09", "b07b2bc5", "72efeaa1", "b5ec2bae", "30d6853e", "328aa38e",
  "6a77c5ec", "05ad2426", "f5926a37", "cb7490d7", "0b53dd96", "8dfc19af", "615d57d6",
  "bec5ff8b", "1e4f977e", "61694228", "f1d868a6", "9d1a5b1e", "cdb55377", "7b03a78e",
  "e264b9a7", "7f0ede23", "df74e4e6", "72a9a5ef", "677e8187", "f0472a46", "f89dea35",
  "b2c20cd4", "7449a48f", "a1077bcf", "d0f17f04", "3ebec6c2", "3990fa53", "848dfe38",
  "aa624624", "b239ebec", "3fcee11d", "3aeb92fe", "5dba3491", "29fa0f4a", "66b52711",
  "1c77b0ae", "272e3c58", "6c667af5", "363c9f7b", "f0f2d080", "5ec71e2c", "6617d55d",
  "8c157792", "f9b2b7ad", "0b5a9f0f", "22dc2dd3", "2ae24f49", "e78b503c", "2ae24f49",
  "f323c3d6", "1fb4fa45", "87dea487", "aa94a73a", "d1b93de6", "bcad3a6c", "2181ee9c",
  "2ae24f49", "fb6fbce4", "2f13ed86", "8784743c", "82104644", "02a5e369", "2f13ed86",
  "3f359dc5", "ab7e1089", "f3a6a1f4", "28dcffb6", "482b7e68", "186db50d", "e1302cb5",
  "bc63bffe", "bf0c0fd0", "a11be473", "bcccf382", "272cb9a5", "476035f6", "7825db13",
  "31bfc37f", "bb01dfdf", "22350a19", "dba520b9", "3061973f", "c27b8365", "dc6586ac",
  "675be03d", "27b27b76", "cbbfba64", "5646e2fe", "900f6aa3", "0b324e00", "76af4f79",
  "7d0a875d", "76af4f79", "3e32b48b", "da5dead0", "b6f27ce5", "f3b453c2", "456edf3f",
  "ef0f0402", "07cc90f8", "76af4f79", "8ad1b7fe", "a0f555c9", "7e7b066c", "d3b06986",
  "663ce9eb", "a0f555c9", "b15a6b18", "f21d1203", "db71e9c4", "6f571a04", "bb9b5004",
  "04a55d72", "a03caf02", "4a7fe2b1", "4d9c4570", "883af3f3", "934bb2d8", "d3cb7a1e",
  "f963feb6", "1df9633a", "c03e1f1b", "1dc329c8", "b749920e", "f58477ba", "98ba3b89",
  "309698aa", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "f5b8c10b", "53a4fab0", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "8f0c4093", "394c01a2", "44696951", "0ade786b",
  "6c0926ed", "664a3844", "e74e76a7", "5bf1ddc6", "b42d6ece", "5bf1ddc6", "3f057430",
  "178c7fff", "cac8018a", "3d61ea39", "18bece5c", "35f967e9", "76c7597b", "5bf1ddc6",
  "d511acdd", "05fd1df2", "78a519df", "76c7597b", "0a2daff0", "05fd1df2", "0c3065e7",
  "78a519df", "d1563497", "7203d8b3", "f38474ab", "865b137d", "114da165", "d6c63fe2",
  "9f1a0feb", "a0f518a0", "2da1a17b", "3835d847", "a3b78e24", "eb9b175d", "28340794",
  "a595db1f", "9f309bc5", "b1f15639", "51c8d0a2", "cae206a1", "4bc4ad69", "4bc4ad69",
  "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69",
  "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69",
  "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69",
  "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69",
  "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69", "eb23a6be", "326e8203",
  "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69", "4bc4ad69",
  "3d6669e9", "59e52169", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "ffd454d6",
  "ffd454d6", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "072a4b42", "21261ef2", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "a318cb02", "0ef0fc64", "7128d7d1", "e37ec9e6", "4eb0a423",
  "b685e819", "33fe791a", "09dfe6c4", "43ab701a", "09dfe6c4", "21ce7410", "09f583e8",
  "e8670ee5", "300f7a44", "44df54fe", "dff49256", "d8e7ddea", "09dfe6c4", "3cd14a8d",
  "74de8ad1", "3aabdaf0", "75b4c7b7", "9128d157", "74de8ad1", "91be5453", "3c99df36",
  "421cdf27", "da09dc6a", "f994d1da", "6dd7f60b", "ed6f228b", "bd155ce7", "ee0a510a",
  "30e4ed14", "96e8a7a4", "09414e52", "1aebb0a0", "d18d4e8e", "b60c4bb3", "9730e199",
  "1bdae9e9", "d05b41b8", "bba0cac5", "1144925b", "748ef43d", "cba9dd37", "55c7eb32",
  "a1fa920d", "3c4a1bc9", "b96bca63", "f38ff2d5", "1d54f3b7", "2a830417", "22b0f366",
  "af5de11f", "8d84dc42", "7f702b8f", "ea3ca77d", "84e13504", "9d96bf2f", "aedcfc34",
  "7417f7ee", "e043a59f", "34530e77", "a6d6c773", "fbe34fbe", "aecc13fe", "0c51e9d5",
  "0a58ea87", "420baf68", "ff7edb48", "32868790", "0cf386f9", "36d8c7d0", "8bdd50a5",
  "0de39a6d", "7830973d", "047e66ca", "9d1c01f6", "4bad7b38", "43c002eb", "ef40d049",
  "e839b1f2", "2395ee32", "5346133d", "b1c7270d", "63cd1617", "03e5818e", "9d1d40fe",
  "77b3412a", "0210b1b9", "71df3a17", "a6bb3b53", "60c0229f", "fb2c158d", "3cd48416",
  "d3095147", "3cd48416", "7fed97d7", "6f8cfbe7", "c924a501", "831806ac", "9c102258",
  "db6b1d28", "565e4f65", "3cd48416", "97653015", "96504f24", "95b8cbc8", "586fb0b7",
  "8b2809c2", "96504f24", "3f35ab2f", "255e63e5", "4f88fafc", "33bdfbf5", "7dc76976",
  "07a8c4fb", "06e2a32b", "332678b0", "7d915a4d", "c92ab6a5", "599634d1", "01c01cbe",
  "57d04b98", "d708d674", "c8b03381", "26e6a577", "238230a2", "419a11da", "0fa811c2",
  "63991420", "0e546031", "285bd65f", "6b8ed5a5", "ef2622cc", "3d6669e9", "5c4a71a6",
  "2c067c0a", "540e1ea3", "22ed03a8", "540e1ea3", "7e4b96d3", "4b79ecf3", "5d95d2cc",
  "2200b950", "fd0bfc73", "1f7a6aa9", "9264df44", "540e1ea3", "63a74fe5", "67d13c77",
  "c3d39466", "8a8986fe", "7a8dce29", "67d13c77", "30d7c300", "2d2ad763", "74025bf8",
  "a46b6695", "7377a015", "6b8ed5a5", "b58eb7ca", "16b126df", "51d068ad", "48107e85",
  "4ba4c096", "818092cf", "7a95a4b9", "92c81b50", "c0a49ce4", "3d1c4e77", "4f83b91c",
  "ef6790a1", "d0f4df12", "b3638807", "69fd94c5", "348843b2", "8e044b0b", "5a546787",
  "223685e1", "848346e2", "6fa319ae", "9bcd255b", "64deb9a1", "9bcd255b", "2510989b",
  "e0448c51", "f8cfd3e1", "748ef5fc", "52535663", "9e9bc3f0", "6d754e1d", "9bcd255b",
  "d17892f2", "9850068d", "b4a43f52", "c729b5b3", "92db058b", "9850068d", "0a519834",
  "e64e7464", "ca3d8bb3", "e52dcf5f", "1140c51f", "8e044b0b", "1ac3404c", "d057bd85",
  "3d0a43e7", "b7442dcd", "d34ca445", "eb4feaad", "8d6e487b", "63e6cd6b", "28e5a954",
  "78880b1b", "7a2de7b8", "5b6ae6e5", "81656daf", "907cdeb8", "da369deb", "5dac8684",
  "acda14c8", "35812b9c", "8b174fbe", "c9bd0555", "cd1214a8", "50ea493f", "28eec542",
  "50ea493f", "245065cb", "89d24bc5", "55bc7375", "5a7b4ad3", "978deba8", "c11edb1a",
  "486cb2d2", "50ea493f", "f9a5de7d", "85a0222b", "aa0fb0dd", "2bbbeaed", "aee47ee0",
  "85a0222b", "bee32490", "2094217c", "e5409783", "523e7d2c", "36161834", "acda14c8",
  "162eaf3c", "7e0792c7", "41694b59", "607c6d28", "74a84b83", "e6b3abeb", "e8468ab4",
  "901289e9", "37ff0fe7", "6ddda07e", "acbaa1c3", "64957968", "fda1206f", "0dc47616",
  "95f406c6", "292d74f2", "79a4219d", "155582fc", "b6e81bb2", "f788d3c6", "04857193",
  "fed6fe3e", "7b77e64c", "fed6fe3e", "3d6c99af", "ff563155", "f654d998", "de8048eb",
  "d0359e9e", "10b03123", "7bff9920", "fed6fe3e", "b5cf1561", "b6156031", "1158262b",
  "fa43da53", "4c338c16", "b6156031", "798dc6cb", "6144d076", "8fd45f77", "279fe3ce",
  "0290ed4e", "79a4219d", "2ac909a7", "0c7506b6", "0258358a", "7de96b96", "9dbc108a",
  "96b6bf76", "810aad92", "8c16d940", "458b52d7", "9ad92594", "4c30e788", "8edb17e3",
  "c1bd3182", "a0687b56", "a9be9734", "ce82e44e", "97df04b6", "180a15e6", "6c7c1c36",
  "761a4941", "0b25369e", "1232d712", "5f1fbb77", "1232d712", "792232a8", "f696d4f3",
  "6ff7f558", "b0d59873", "46a08bf7", "62c32cca", "08ce1e34", "1232d712", "98ec3b15",
  "fa67e233", "68d26220", "db3c9b6c", "84b69a4c", "fa67e233", "51b17f8b", "9302305d",
  "91a20300", "8c35e5a1", "100549df", "97df04b6", "2b2998a7", "b247b1dc", "1973f87f",
  "e6e4beec", "9c0c3266", "24b31da0", "5ed09f4d", "8651c5cf", "4c40ddc7", "55f922da",
  "446dbd19", "95bdc6bd", "b80d8d27", "92c8e5e0", "5675a186", "7bf03497", "0fa56ea1",
  "6a9ca31d", "25e37b0d", "46c22bf3", "4d2a7aa1", "844d541f", "ee4d717f", "fd3166f8",
  "b1b69907", "d93d3f50", "7cf1064d", "e5fc891c", "42c82c3c", "bb1ef745", "9c785d8e",
  "7c198fbc", "fb1ce8e6", "920b2ef5", "d4d998f1", "6b03da72", "c5cc0bd5", "57ee250b",
  "7e5bc6f3", "d845bc9e", "ac1d4b4e", "3d5eed1a", "c725f73c", "750a9082", "ce294484",
  "a0dc3de3", "0f1a634b", "9935a2d8", "7b4f6e41", "a333a919", "331b058b", "77c876a6",
  "d40181b4", "a64b1a58", "17f1525b", "6457440f", "bbb340f3", "ef9ed23e", "52bdd29f",
  "487880ed", "30da2d59", "35bce5af", "d288d274", "390787dd", "9eba3b5c", "dc4e888c",
  "e2ef3c69", "dc4e888c", "253a01d5", "4c8728e9", "7cdd2f3d", "918636c7", "8d54cc04",
  "abb84444", "54460aca", "dc4e888c", "58adda2a", "018fdfba", "f29910e9", "c05626d0",
  "4c6049bd", "018fdfba", "d4ed79f0", "cafc7417", "ab78e680", "81851788", "0f180331",
  "494f07d0", "84b69234", "0e2208d4", "a920e9ce", "9d1dfa1d", "504131a9", "36d10685",
  "58de4156", "3a2ce0ae", "7297945f", "64ddb58d", "bb9769d0", "0334a0ba", "f74073fc",
  "47aedfce", "bf40223f", "fad934db", "14e31ecb", "1df5b12a", "3b02a5e2", "c6657b09",
  "cf4ad0e0", "cca6576a", "aacc77b7", "cca6576a", "2af7bea3", "e457e75b", "f4ff99ed",
  "7f2808a7", "29690eab", "87976208", "f7f7acde", "cca6576a", "05173c22", "e59c728d",
  "e77f5d69", "762ab010", "a077196a", "e59c728d", "2c140805", "6a673b3d", "f7bf8842",
  "46d5943b", "71755c26", "9b8f3dba", "746bce5f", "ac75d5ab", "8caa00d9", "bbc7103d",
  "d8a33061", "e00f508b", "5895151b", "c5f14a84", "8b1d9293", "99d63877", "e98d0ab6",
  "0c456944", "f84ac262", "72609824", "fedc2de5", "19ee27ab", "146b6ffc", "110b08ac",
  "31dcc86d", "470c3d55", "6acda384", "b37db09c", "5d18d1dd", "b37db09c", "08f98868",
  "5ec59e94", "88fe0913", "36ca9bab", "dc8369ad", "5687a0c4", "06a02920", "b37db09c",
  "25deb371", "15606d51", "fecc4ed4", "ded5286b", "3d34a9ad", "15606d51", "b3d21884",
  "f968a11e", "744fa54b", "06102779", "beb27339", "f2e53e31", "0a74a452", "1cdd0b7b",
  "4c7cc171", "f5f5abd9", "aa3f4cc2", "cb57297b", "1551f8bd", "e8d1b211", "4b1f4993",
  "b76e80e5", "a2e2eaf2", "597fe8ff", "7930d8d1", "56f2cb23", "4f9692a0", "56417af4",
  "6fad1177", "0080a0fd", "7794e109", "4dc877e5", "b18b138b", "4ff6352f", "b748138c",
  "4ff6352f", "71b72d33", "e82b0cd5", "57c3bb22", "74151cb7", "ded18b2a", "084d91a2",
  "7fd2127a", "4ff6352f", "ff2630f2", "d6d6082d", "f0d9b647", "12c3138d", "2f992d8a",
  "d6d6082d", "7c7632af", "438c7eb3", "13456d80", "4c34179b", "0772b69c", "d56cf1ad",
  "31b3ed2b", "aa38f65b", "868cb9b9", "c1b8f1b0", "4258c053", "039b300d", "76be19c4",
  "9c714ff6", "8ada0ab6", "1322d29d", "9ad172dc", "4f7b85a6", "51636add", "608d0372",
  "213e8e15", "1c19e73e", "3f3338b6", "43436bfa", "c0009f5c", "cb2b05ac", "c6bad44f",
  "0ed38651", "0f3bbc06", "0ed38651", "43e0f89d", "b86b4a9f", "ec1c5945", "37b6f08e",
  "2cb9eb0f", "4df408b1", "2463ec64", "0ed38651", "da5c9428", "98c2b744", "ade824fa",
  "4e1cf21b", "995fd2d4", "98c2b744", "565b86eb", "0ed25ca6", "0fbc10e3", "377d6dbb",
  "c60f52ee", "db0ae96b", "300b76c1", "fcd0dd66", "56620ae3", "70941820", "24d02037",
  "157c1106", "d95c25a7", "10f767f3", "4d964dda", "43bac737", "e7e2e7f6", "905fb52d",
  "79bc6d95", "7b1d42a4", "3dc80735", "7dc884ad", "22821039", "d00eca0d", "f7600af1",
  "a0f0dd11", "f8b86831", "e7fe1024", "59bc7ac5", "e7fe1024", "bf1f1653", "b7214684",
  "8356ad28", "76df58ce", "9a6c1e04", "f6737df5", "6685280b", "e7fe1024", "fd84fbfd",
  "388f0da3", "9816e505", "462013f4", "6a4564f8", "388f0da3", "a15e0cd5", "cad5b431",
  "c6b5c8fd", "5600032c", "f62a5a20", "22821039", "27e6eab1", "c0b3a6a7", "4c7a7afb",
  "7a371193", "ea1d514a", "f15add21", "79b4c7d1", "3e3b0ce5", "81275b76", "9e0f60be",
  "d5dc82e1", "f3aba59d", "979fe256", "bc352e5e", "345d1ba1", "f0c3eca1", "fb25ee72",
  "e1ef7c61", "b4781057", "cf35225a", "7c36445e", "f230fbfd", "9a519f36", "f230fbfd",
  "837116eb", "ff349ec4", "0ff5b592", "91f07e38", "dbe52207", "56b16c17", "64e137c3",
  "f230fbfd", "dda8c3de", "c95b663e", "fc601e46", "1c214cb2", "c8cec7de", "c95b663e",
  "87b2ec64", "ef02331d", "88806b8f", "ce70c0fd", "30ce79c1", "fb25ee72", "9d50dcba",
  "39832dd9", "1ba743c1", "bf3b89e4", "51d0bf29", "aa5ea39c", "c07bae82", "263f6483",
  "7817e931", "e37987d3", "17a7add1", "3ab85bf7", "d41edd33", "09cd46f9", "d21b3ff3",
  "350e9b0b", "46757178", "b10e609b", "338cd569", "ca61672f", "628f35b4", "6a300c31",
  "2c5a4e31", "6a300c31", "a1eea6ea", "c6871674", "5e61a63e", "4732289f", "ce98bea2",
  "39db8c49", "66f38f2f", "6a300c31", "122dd41d", "05519d3d", "94dc085f", "b3ee25b0",
  "aa8f2f27", "05519d3d", "0250b840", "83a1f1af", "fbb2a25f", "2b8c297e", "89113f27",
  "46757178", "cf107eee", "9fde9f18", "dcb91430", "c7e4f60f", "47b27175", "0f5bd531",
  "62b28f8f", "1f0d2b08", "9aeb4b52", "339b1c42", "639bfb35", "48377bc5", "e88a8d64",
  "25121771", "bc0461f9", "08c22116", "77e8b2c3", "2060ebdf", "f65fb3f1", "28a66d38",
  "7c2ac8df", "d12bdee6", "c371c199", "d12bdee6", "174fbea9", "713afebf", "8a5fcb1f",
  "68d02066", "6b157e57", "47d8bcb6", "197c0cc3", "d12bdee6", "a2670efc", "8081af80",
  "7318c488", "cdfdc52a", "ae49367b", "8081af80", "a9766e5b", "d8d3fc95", "b6af17bc",
  "ab9970b0", "542fa5d9", "77e8b2c3", "f300c653", "3e8df17f", "39d39f26", "fe19e4fc",
  "15dacd3b", "e284fa15", "0c93d3de", "a1d4eb6d", "f2aa2a52", "91911509", "81641689",
  "425dc9eb", "7338fbb9", "629689d8", "7b116726", "d9847f34", "9d76a1c3", "377aa7fb",
  "ab2e3b58", "5647baa8", "d3d67d63", "ae559518", "b3de6a05", "ae559518", "2e517071",
  "94f3f556", "37b4876f", "834a2da7", "3f0f9d31", "06168b80", "cbd63dd6", "ae559518",
  "11a5536a", "e222ce43", "d3b10522", "1e249530", "0d48aa99", "e222ce43", "e4f79377",
  "e4d7658d", "39bfcec3", "8136af65", "bdf10e9c", "9d76a1c3", "1538a34f", "e70767e1",
  "8516fc6c", "3d64b9ab", "36fa3ce8", "d8efdf18", "b234ee1b", "f50bbb65", "bc6a3569",
  "1282534d", "d3fdadd2", "69d236c6", "e9c40432", "1eb3a704", "b7197ce8", "2396f1f4",
  "73aa87ce", "9a88d936", "42c19a4a", "768b3784", "d8ccc787", "ce4cf933", "3789abf0",
  "ce4cf933", "df7a4514", "26f7f40a", "6ad7ac7a", "5f88b09f", "5037dbeb", "0a0d1a37",
  "fec03717", "ce4cf933", "9d4fdc73", "daa2452c", "92d3b20c", "23aa2be3", "c4249045",
  "daa2452c", "cd04b666", "16db1222", "eb830e3c", "722d93bb", "dd7d4ce2", "73aa87ce",
  "871ab9ca", "d4f8f174", "a4e7547c", "18ec7045", "efdaa7f2", "2272559e", "258d1c26",
  "469e4393", "466d3399", "cb331c5b", "8f5acfcd", "b4473a14", "0327ef92", "fa97ac9a",
  "b09c78f8", "f1c698b5", "57b3ee8a", "97671d4c", "266f6e0a", "fa45a7ea", "e37abac3",
  "cc7f17c6", "8493b060", "cc7f17c6", "2d86ce83", "20f45f27", "1e3f062c", "a6228048",
  "335a9102", "f1865ed8", "5fa52e7e", "cc7f17c6", "7559e819", "5bec9c00", "e9de4809",
  "31d733f4", "ccefd450", "5bec9c00", "b7c9d69c", "8cde6517", "9b6b110a", "a9f5cf3a",
  "dd8f55a9", "57b3ee8a", "b366f7c2", "d1804f86", "a85e80c6", "d778eb8b", "6a88b41b",
  "6c5416f4", "664e798d", "725e5531", "579e8228", "a6455215", "cbc6acfa", "62afbb7b",
  "5fd9a5bd", "0e952eb7", "2f9d18c2", "2f9d18c2", "2f9d18c2", "2f9d18c2", "2f9d18c2",
  "2f9d18c2", "2f9d18c2", "2f9d18c2", "2f9d18c2", "2f9d18c2", "388ea52e", "2f9d18c2",
  "d0937c5f", "a83c8d6e", "0756461f", "6ed438c8", "4130f36d", "49172ab7", "0e8a2000",
  "2f9d18c2", "8c66d1af", "fcec413c", "87a6fe3f", "2f9d18c2", "2f9d18c2", "c7962cb9",
  "75436025", "2f9d18c2", "2f9d18c2", "2f9d18c2", "2f9d18c2", "71909076", "6b932140",
  "e04d71b0", "869f141f", "2f9d18c2", "2f9d18c2", "2f9d18c2", "66393036", "c36ff9e0",
  "2f9d18c2", "f5bab370", "d1b0dac7", "2f9d18c2", "2f9d18c2", "2f9d18c2", "2f9d18c2",
  "2f9d18c2", "2f9d18c2", "2f9d18c2", "2f9d18c2", "2f9d18c2", "2f9d18c2", "2f9d18c2",
  "633d6e00", "2f9d18c2", "8c8c1285", "748b91e4", "7a81d281", "f88f77ba", "00a469ff",
  "669ffa75", "91b01776", "2f9d18c2", "29e54195", "b8f28232", "22823ccd", "2f9d18c2",
  "2f9d18c2", "f9a0141b", "b7df86cb", "2f9d18c2", "2f9d18c2", "2f9d18c2", "2f9d18c2",
  "385580b4", "bd976a0a", "d96a5bb2", "acb60911", "2f9d18c2", "2f9d18c2", "2f9d18c2",
  "6e2602ec", "c452ebda", "2f9d18c2", "a264da5e", "5df4a36d", "2f9d18c2", "ff1286d7",
  "8306ba17", "21941aba", "987f2aab", "77f92a8e", "47fb4726", "a3099998", "b2ffb33e",
  "1318ccba", "b2ffb33e", "310777d1", "28978417", "52f7a44f", "27556c2e", "c9202903",
  "644bb495", "893e3bbb", "b2ffb33e", "e1c48b6d", "2c9e1176", "0dfd0388", "61e31ea1",
  "67516734", "2c9e1176", "16fb7b67", "6c35de39", "f2f5ff36", "b6227843", "c4337b83",
  "6ad2fc24", "f541fcbb", "e93d90e4", "a0682c55", "0edfa080", "2612d611", "57e1aaa4",
  "27a744c4", "fbdf14ec", "5c3612fb", "4f105934", "5bb3a850", "d0de7694", "a5c73db9",
  "6b7d82d6", "408d2c2a", "d370d3ce", "ae3eeee5", "f2ef69fe", "16930df7", "2c81eae5",
  "69421ee5", "dff539ad", "696000b1", "dff539ad", "93f68710", "ba264110", "80ee03d6",
  "f93cc8bd", "eb4b907e", "eb596dce", "cb9cacba", "dff539ad", "f2f5ff36", "1bb749f7",
  "84cf4a82", "f406982c", "26f4d623", "1bb749f7", "f9d7f154", "16f7d6f2", "01383485",
  "3cef1622", "62aed222", "f9be35b3", "ab58b81e", "b16fd825", "13d12200", "1a4d0977",
  "ce641120", "d81c0419", "2dde10b5", "c7bfe1d1", "8b77a334", "de8e223d", "0f54b0a3",
  "a150f7c1", "e42f8936", "f34d8f0b", "bd5f2a15", "c147f24a", "dce6a6c3", "f311c34b",
  "60d94912", "1e0c5125", "e65eca4d", "1b9379db", "7528a2c6", "b05d21c4", "6dcf1763",
  "5078ff79", "2b5325d4", "2592e31c", "5bd76251", "40328b2b", "2c857a83", "1b9379db",
  "c7e3f867", "c1bfccd2", "8a14f24b", "12482113", "57b01a1c", "23596844", "0660faec",
  "edd41727", "83c88db2", "91099818", "4fd4a8cc", "9783f610", "67b64140", "590c7690",
  "7c65333d", "71563bfc", "c3622355", "cfaee8b0", "7e500353", "58cc5897", "bfb10dc3",
  "03b11a6c", "b845974c", "ebaeadc4", "ac3e3969", "0e435346", "bdbe90ef", "4c5c1b98",
  "c62140eb", "f0cd0588", "c44ff31a", "be1d3df0", "0090cf54", "83b13383", "c05b29ab",
  "0c0d2fcb", "2ceb6af4", "0ab2f582", "c8cdddf3", "763dc97d", "7bb12c63", "f3b3ad12",
  "18d007dc", "83b13383", "264188d7", "71a8d16f", "d16a3249", "faf13ba7", "4e5d956b",
  "71a8d16f", "14c1c9bf", "97068b29", "83507f9e", "91a9c8e4", "1904e03f", "a0f2ceec",
  "23a1c091", "39ec6b98", "93b25e63", "209c1708", "9350c91c", "98f1b9f1", "b4b500ed",
  "873b03cc", "ed87aa62", "97594195", "a26a1abb", "92f5d7d7", "5a8585c6", "e5a33b86",
  "af26d76a", "a38aa2e8", "3d6669e9", "2a017695", "bfe62658", "c45197ae", "e29bfafc",
  "5e437be7", "089a03c7", "5e437be7", "248c2441", "06448fad", "0b83ce8b", "ec51939c",
  "efb1c40a", "aa1a105d", "c85270be", "5e437be7", "33a04d92", "4d6cf8bf", "ab19433f",
  "c4cf4e73", "94e93db2", "4d6cf8bf", "b02f3fef", "0b725174", "dcbe455b", "0a088676",
  "81d77d56", "3d6669e9", "b4f575a7", "e276ad12", "0b0327d0", "fbdd16a2", "38e7483f",
  "b2cfb68e", "3b7f2e28", "a6344519", "8fc83e84", "66e07226", "23d850ef", "5dc97526",
  "79730201", "54ce54fe", "af26d76a", "a38aa2e8", "3d6669e9", "2a017695", "bfe62658",
  "c45197ae", "e29bfafc", "5e437be7", "089a03c7", "5e437be7", "248c2441", "06448fad",
  "0b83ce8b", "ec51939c", "efb1c40a", "aa1a105d", "c85270be", "5e437be7", "33a04d92",
  "4d6cf8bf", "ab19433f", "4ce1d424", "94e93db2", "4d6cf8bf", "b02f3fef", "2154904d",
  "dcbe455b", "0a088676", "81d77d56", "3d6669e9", "b4f575a7", "e276ad12", "0b0327d0",
  "fbdd16a2", "38e7483f", "b2cfb68e", "3b7f2e28", "a6344519", "8fc83e84", "66e07226",
  "23d850ef", "5dc97526", "79730201", "54ce54fe", "4421ff17", "16489e23", "8e11ac51",
  "fd79b0cb", "111c1d2f", "7f236483", "393424c9", "a843d8f7", "5a356eb7", "a843d8f7",
  "d7dc236b", "30fcd4b3", "4b928751", "94e12737", "86ae5057", "87010c7f", "4421ff17",
  "a843d8f7", "2c1e262b", "02b20249", "92962151", "4421ff17", "d10dcf23", "02b20249",
  "e5d20d85", "92962151", "84e99ad3", "b87b3f5f", "ce4939ff", "1f054843", "cebb2b6f",
  "647b7d77", "323676a7", "9c3b262f", "82e8d865", "269685f7", "8ac1110f", "d4f58c49",
  "8c2e87b7", "536a2daf", "85534609", "41406fc3", "353e376f", "e28dae47", "51cff11a",
  "2726216c", "e52ec4a4", "d828f1e0", "f99ea515", "b227a5ab", "6f4af434", "e3f5331a",
  "ab461dba", "e3f5331a", "4d588e94", "ab0c710b", "64cf0270", "0e883b3d", "d5dcfb20",
  "51171c1b", "51cff11a", "e3f5331a", "6650e337", "1b07abbc", "8b411544", "51cff11a",
  "388b032b", "1b07abbc", "dc3cadb8", "8b411544", "cc56497a", "c662bbea", "d41b656a",
  "0afbbce7", "28dc0966", "ad654225", "295e0b53", "dfa68273", "d129ab30", "13011f64",
  "271bc6da", "eabc7186", "5e766a45", "af0fcc73", "f4602fac", "c69edda3", "674c6638",
  "a02eff5f", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "32ec893a", "3d6669e9", "3d6669e9", "3d6669e9", "a60bdd77", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "a744ddc9", "3d6669e9", "3d6669e9", "3d6669e9",
  "773cc04c", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "266e5c98", "3d6669e9",
  "3d6669e9", "3d6669e9", "07b2abf5", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "288439c5", "3d6669e9", "3d6669e9", "3d6669e9", "cb5a66c4", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "48eefa57", "48eefa57", "dba98ddf", "58b88a91", "52e1b72b",
  "2e40c5d1", "3491cd29", "8c6f0af1", "25ef12b1", "8c6f0af1", "07c4e863", "da6d031d",
  "2b5e22c1", "c958af81", "8aadfa6b", "376693ab", "09411feb", "a365c107", "1796d4a1",
  "e4bcf3dd", "870149f1", "d9a1a143", "6c00fa2d", "a63ea62d", "45fb3e85", "9614deca",
  "28db065d", "48eefa57", "cee446dd", "3d6669e9", "edf6b29f", "e6c28c29", "0052be59",
  "2e9a0b15", "34ca9d8d", "b3c69399", "bd37fbe7", "51686b21", "505c6281", "e5ae2685",
  "e5ae2685", "85962b5d", "71ad0c23", "b365abd9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "5c2a1126", "3d6669e9", "3d6669e9",
  "3d6669e9", "394e3105", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "f70cddf2",
  "3d6669e9", "3d6669e9", "3d6669e9", "3dfa12e7", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "23b99d0d", "bb852fdf", "1d3c5812", "de1b53fc", "e7228270", "49700f34",
  "b965c1ce", "8edac005", "08967ea5", "d8b26892", "9d74a80d", "1d7084dc", "1829f4bf",
  "fc4c5164", "aa5c24d1", "fcf181fe", "7a75f559", "c824509f", "a37289c6", "ff29b45b",
  "14a485ef", "b1131421", "2e04f75f", "8692b823", "763f41c7", "9b2c7e4b", "3685d555",
  "ea8a51c7", "19e47805", "f18ac68d", "26c5e4b4", "98e43ca4", "ee27762a", "37fa0712",
  "e48549db", "89a76d14", "3ef52506", "98dac39c", "f34c87ec", "8220feec", "25f54fc1",
  "26506b9e", "852c1847", "f38c5253", "120025b8", "e4774d69", "c46a46aa", "00250f4a",
  "77286494", "a641ab71", "baaeebc8", "570878af", "f3d70674", "570878af", "5e237c95",
  "65ad9966", "1e353fe7", "f2f4c46c", "8d35eae4", "a9a9cf6e", "c0f667de", "570878af",
  "e9ec2733", "9c57ce8c", "701ad3f8", "7c78bcd5", "c05f2bc4", "9c57ce8c", "3e9ddb9b",
  "78771844", "6e08ca6f", "5188a11d", "948ceb87", "c46a46aa", "23a9a931", "9235157b",
  "9aeed4f2", "ee5ce82b", "541348d1", "e46c53e6", "f64d131c", "a441beb2", "4b56cb44",
  "b43aa52e", "15d772d8", "48704f32", "f74d5f71", "5905186a", "e77cd4f9", "4000ec09",
  "e50502d2", "bafa5df4", "ed8c94b8", "8fa37bac", "3128c5ee", "b95f27a3", "d9b77b03",
  "1fb0ca6c", "3dddaf7b", "3c5119aa", "70a855a9", "0395cd6c", "9c95462e", "9c4bea5a",
  "c9679a54", "073d6f49", "acfdd9bb", "3c000725", "e63318f9", "95cfb17e", "c6670027",
  "f5af2e1d", "500390d0", "5b19188b", "0dd29816", "fef99821", "c851d9a1", "c8c3ec76",
  "106e7f54", "1b162bdc", "545328be", "ff7b5036", "2a1797e4", "74f0e987", "63c8da8d",
  "91849b8b", "e83eaa5a", "580fa88c", "aa204705", "46282478", "3ec7b9a1", "2ef0a0df",
  "fdf7adcd", "44c28e43", "98eb57ca", "83c8ccdf", "84bc5500", "489b6bed", "7b9e2e2c",
  "f22625de", "5eb9420b", "f22625de", "b65a6fa0", "995e9b91", "c0d8e237", "6b3b253c",
  "2e1e1f8d", "58609384", "419564d9", "f22625de", "69dbad78", "1da9a95a", "5917e7bb",
  "884d6876", "d66fe4bb", "1da9a95a", "7af3b29e", "6d19a7ed", "810a42e8", "1a786d34",
  "3234aa86", "9fb30b15", "9cb55506", "dc916355", "d616c865", "bb90af35", "955753e9",
  "33439d59", "f5694e3e", "5ed12e8a", "853206b1", "abc42931", "f6ed13bd", "ae9eb1f5",
  "09a4ee69", "6df629a3", "69b26d20", "4995d29c", "8c37c071", "a622d701", "e9e50851",
  "0512d02b", "ee6ec059", "1c7375fe", "c3d2a45e", "1f478f29", "12275c66", "4e013379",
  "ef8861c2", "3a3d60f5", "3a3d60f5", "3a3d60f5", "3a3d60f5", "e8936cce", "3a3d60f5",
  "19fb234e", "5fdebc7a", "021df223", "3a3d60f5", "74831f0e", "3a3d60f5", "6009a1e2",
  "3a3d60f5", "04d9ae96", "a9a479b6", "3a3d60f5", "3a3d60f5", "3a3d60f5", "3a3d60f5",
  "3a3d60f5", "3a3d60f5", "3a3d60f5", "3a3d60f5", "a4d5710c", "1a7d642d", "3a3d60f5",
  "3a3d60f5", "015ac1e7", "1554b6c0", "6ffdc882", "b8fa9d75", "b8fa9d75", "b8fa9d75",
  "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75",
  "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75",
  "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75",
  "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75",
  "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75",
  "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75", "b8fa9d75", "f48f3fb3",
  "2366f029", "42641b90", "dea1bc91", "4c3563b9", "072f9c31", "91bb0783", "87793d5d",
  "68d651bd", "1719ebba", "b0e65d15", "c3b42a4c", "0e4060eb", "bba48a96", "b64a70ac",
  "9b6f00bf", "af46b28a", "7ebbcd0e", "ab4b7a08", "6a456ccb", "2c8d6db7", "020db7b4",
  "fe477f41", "de9c6631", "de1db0fb", "b7cffdc4", "6a281736", "c5e0576c", "df4fa425",
  "85e80b86", "ddaceb26", "bf24ee01", "06a015d9", "d5414bca", "89437ff1", "0f772553",
  "7f5038d1", "3d6669e9", "970205c8", "2440619a", "9dbc44cb", "bae21a57", "4751a355",
  "644ccbf0", "af26d76a", "a38aa2e8", "3d6669e9", "2a017695", "bfe62658", "c45197ae",
  "e29bfafc", "5e437be7", "089a03c7", "5e437be7", "de0cc84c", "06448fad", "0b83ce8b",
  "ec51939c", "efb1c40a", "aa1a105d", "7e39b503", "a8ddee59", "62e6a06b", "5c1effe8",
  "628b8317", "c85270be", "94d79e5c", "4d6cf8bf", "b02f3fef", "ab19433f", "dcbe455b",
  "0a088676", "81d77d56", "3d6669e9", "b4f575a7", "e276ad12", "0b0327d0", "fbdd16a2",
  "38e7483f", "b2cfb68e", "3b7f2e28", "a6344519", "8fc83e84", "66e07226", "23d850ef",
  "5dc97526", "79730201", "54ce54fe", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
  "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9", "3d6669e9",
]

///|
/// The hash of the outcome for every payload as the id prefix and font, then as sequence settings, payload by payload.
let hostile_option_outcomes : Array[String] = [
  "c6f158bd", "2e5cf491", "24d904c1", "2e5cf491", "8e81f27b", "2e5cf491", "e1ae4849",
  "2e5cf491", "f9be3447", "2e5cf491", "eef7c441", "2e5cf491", "d7329c3b", "2e5cf491",
  "a82702c5", "2e5cf491", "7b24d685", "2e5cf491", "ace32dd7", "2e5cf491", "86fcbc31",
  "2e5cf491", "24e14391", "2e5cf491", "112c3183", "2e5cf491", "638ed805", "2e5cf491",
  "401b6d85", "2e5cf491", "94579a97", "2e5cf491", "0d2caad1", "2e5cf491", "dc98e21b",
  "2e5cf491", "23664919", "2e5cf491", "58e9bfb7", "2e5cf491", "5000de77", "2e5cf491",
  "c9aca5ed", "2e5cf491", "7550ccef", "2e5cf491", "daa8bdcb", "2e5cf491", "171265cf",
  "2e5cf491", "118eee53", "2e5cf491", "b4a9d0c9", "2e5cf491", "83bd2ddd", "2e5cf491",
  "e9578dbd", "2e5cf491", "2e85a4c1", "2e5cf491", "62c2742d", "2e5cf491", "264c361c",
  "2e5cf491", "16ddbc16", "2e5cf491", "a9a91708", "2e5cf491", "a087a729", "2e5cf491",
  "af6099e3", "2e5cf491", "d33966eb", "2e5cf491", "76b0ed1f", "2e5cf491", "6224130d",
  "2e5cf491", "6202f871", "2e5cf491", "4c34307b", "2e5cf491", "90df7449", "2e5cf491",
  "bffff1d9", "2e5cf491", "c93fd1f3", "2e5cf491",
]

///|
/// The hash of the outcome for each extreme setting value, then for an enormous autonumber start.
let extreme_outcomes : Array[String] = [
  "f10f7983", "f10f7983", "f10f7983", "9a124f74", "f10f7983", "9a124f74", "f10f7983",
  "f10f7983", "86331143",
]
