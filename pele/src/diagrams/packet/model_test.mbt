///|
fn model(source : String, config~ : @types.Config = {}) -> String {
  let built = @packet.build_packet(
    @packet.parse_packet(source + "\n"),
    config,
    Some("front"),
  ) catch {
    @errors.PeleError(failure) =>
      return "\{failure.code.to_string()}: \{failure.message} \{failure.kind.unwrap_or("null")}"
  }
  let rows = built.rows.map(row => {
    row.map(b => "\{b.start}-\{b.end}/\{b.bits}:\{b.label}").join(" ")
  })
  "title=\{built.title.unwrap_or("-")} acc=\{built.acc_title.unwrap_or("-")}|\{built.acc_descr.unwrap_or("-")} perRow=\{built.bits_per_row} rows=\{rows.join(" // ")}"
}

///|
fn with_packet(options : Json) -> @types.Config {
  { "packet": options }
}

///|
test "a bare packet has no rows" {
  inspect(model("packet"), content="title=front acc=-|- perRow=32 rows=")
}

///|
test "fields keep their bit counts within a row" {
  inspect(
    model("packet\n0-10: \"test\"\n11: \"single\""),
    content="title=front acc=-|- perRow=32 rows=0-10/11:test 11-11/1:single",
  )
  inspect(
    model("packet\n+8: \"byte\"\n+16: \"word\""),
    content="title=front acc=-|- perRow=32 rows=0-7/8:byte 8-23/16:word",
  )
}

///|
test "a field is split at the end of a row" {
  inspect(
    model("packet\n0-10: \"test\"\n11-90: \"multiple\""),
    content="title=front acc=-|- perRow=32 rows=0-10/11:test 11-31/20:multiple // 32-63/31:multiple // 64-90/26:multiple",
  )
  inspect(
    model("packet\n0-16: \"test\"\n17-63: \"multiple\""),
    content="title=front acc=-|- perRow=32 rows=0-16/17:test 17-31/14:multiple // 32-63/31:multiple",
  )
}

///|
test "the title, accTitle, and accDescr are tidied" {
  inspect(
    model(
      "packet\ntitle own\naccTitle:   spaced\naccDescr {\n  a\n    b\n}\n0: \"x\"",
    ),
    content="title=own acc=spaced|a\nb perRow=32 rows=0-0/1:x",
  )
}

///|
test "fields that do not follow each other are rejected" {
  inspect(
    model("packet\n0-16: \"test\"\n18-20: \"error\""),
    content="semantic: Packet block 18 - 20 is not contiguous. It should start from 17. packet",
  )
  inspect(
    model("packet\n+16: \"test\"\n18-20: \"error\""),
    content="semantic: Packet block 18 - 20 is not contiguous. It should start from 16. packet",
  )
  inspect(
    model("packet\n0-16: \"test\"\n18: \"error\""),
    content="semantic: Packet block 18 - 18 is not contiguous. It should start from 17. packet",
  )
  inspect(
    model("packet\n0-16: \"test\"\n17: \"good\"\n19: \"error\""),
    content="semantic: Packet block 19 - 19 is not contiguous. It should start from 18. packet",
  )
}

///|
test "a range that ends before it starts and a zero bit count are rejected" {
  inspect(
    model("packet\n0-16: \"test\"\n25-20: \"error\""),
    content="semantic: Packet block 25 - 20 is invalid. End must be greater than start. packet",
  )
  inspect(
    model("packet\n+0: \"test\""),
    content="semantic: Packet block 0 is invalid. Cannot have a zero bit field. packet",
  )
}

///|
test "bitsPerRow sets the width of a row" {
  inspect(
    model(
      "packet\n+4: \"a\"\n+8: \"b\"",
      config=with_packet({ "bitsPerRow": 8 }),
    ),
    content="title=front acc=-|- perRow=8 rows=0-3/4:a 4-7/3:b // 8-11/3:b",
  )
}

///|
test "bitsPerRow is floored, and falls back when unusable" {
  inspect(
    model("packet", config=with_packet({ "bitsPerRow": 8.9 })),
    content="title=front acc=-|- perRow=8 rows=",
  )
  inspect(
    model("packet", config=with_packet({ "bitsPerRow": -4 })),
    content="title=front acc=-|- perRow=32 rows=",
  )
  inspect(
    model("packet", config=with_packet({ "bitsPerRow": "wide" })),
    content="title=front acc=-|- perRow=32 rows=",
  )
  inspect(
    model("packet", config=with_packet({ "bitsPerRow": 99999 })),
    content="title=front acc=-|- perRow=4096 rows=",
  )
  inspect(
    model("packet", config={ "packet": "text" }),
    content="title=front acc=-|- perRow=32 rows=",
  )
}

///|
test "packet_option clamps to its range" {
  let config = with_packet({ "a": 5, "b": 0, "c": 1000, "d": null })
  inspect(@packet.packet_option(config, "a", 7, 1, 400), content="5")
  inspect(@packet.packet_option(config, "b", 7, 1, 400), content="7")
  inspect(@packet.packet_option(config, "b", 7, 0, 400), content="0")
  inspect(@packet.packet_option(config, "c", 7, 1, 400), content="400")
  inspect(@packet.packet_option(config, "d", 7, 1, 400), content="7")
  inspect(@packet.packet_option(config, "missing", 7, 1, 400), content="7")
}

///|
test "rows stop at ten thousand, as Mermaid's do" {
  let built = @packet.build_packet(
    @packet.parse_packet("packet\n+20000: \"a\"\n+1: \"b\"\n"),
    with_packet({ "bitsPerRow": 1 }),
    None,
  )
  inspect(built.rows.length(), content="10000")
}

///|
test "a field of more bits than a number holds still fills the rows" {
  let built = @packet.build_packet(
    @packet.parse_packet("packet\n+" + "9".repeat(400) + ": \"x\"\n+1: \"y\"\n"),
    {},
    None,
  )
  inspect(built.rows.length(), content="10000")
}
