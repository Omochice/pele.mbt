///|
fn svg(source : String, max_width? : Double) -> String {
  let options = { ..@types.RenderOptions::default(), max_width, }
  let result = @core.render([@packet.packet], source, options) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "\{result.width}x\{result.height} \{result.svg}"
}

///|
test "a box and a label per field, in rows of 32 bits, with a label shrunk to fit" {
  inspect(
    svg(
      "packet\n0-15: \"Source Port\"\n16-31: \"Destination Port\"\n32-47: \"Wide label that cannot fit\"\n48: \"URG\"",
    ),
    content="1035x113 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-packet\" viewBox=\"0 0 1035 113\" width=\"1035\" height=\"113\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"packet\"><g class=\"pele-packet-fields\" font-size=\"14\" text-anchor=\"middle\"><g class=\"pele-node\" data-id=\"0-15\"><rect x=\"8\" y=\"22\" width=\"507\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"261.5\" y=\"42.9\">Source Port</text></g><g class=\"pele-node\" data-id=\"16-31\"><rect x=\"520\" y=\"22\" width=\"507\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"773.5\" y=\"42.9\">Destination Port</text></g><g class=\"pele-node\" data-id=\"32-47\"><rect x=\"8\" y=\"73\" width=\"507\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"261.5\" y=\"93.9\">Wide label that cannot fit</text></g><g class=\"pele-node\" data-id=\"48-48\"><rect x=\"520\" y=\"73\" width=\"27\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"533.5\" y=\"92.15\" font-size=\"9\">URG</text></g></g><g class=\"pele-packet-bits\" font-size=\"10\" fill=\"var(--_m)\"><text x=\"8\" y=\"18\">0</text><text x=\"515\" y=\"18\" text-anchor=\"end\">15</text><text x=\"520\" y=\"18\">16</text><text x=\"1027\" y=\"18\" text-anchor=\"end\">31</text><text x=\"8\" y=\"69\">32</text><text x=\"515\" y=\"69\" text-anchor=\"end\">47</text><text x=\"533.5\" y=\"69\" text-anchor=\"middle\">48</text></g></svg>",
  )
}

///|
test "a descending bit order mirrors each row and puts the title under the fields" {
  inspect(
    svg(
      "---\nconfig:\n  packet:\n    bitsPerRow: 16\n    bitOrder: descending\n---\npacket\ntitle Tiny\n0-7: \"DATA\"\n8-11: \"TYPE\"\n12: \"EN\"\n13-15: \"RES\"\n16-19: \"NEXT\"",
    ),
    content="523x149 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-packet\" viewBox=\"0 0 523 149\" width=\"523\" height=\"149\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"packet\"><g class=\"pele-packet-fields\" font-size=\"14\" text-anchor=\"middle\"><g class=\"pele-node\" data-id=\"0-7\"><rect x=\"264\" y=\"22\" width=\"251\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"389.5\" y=\"42.9\">DATA</text></g><g class=\"pele-node\" data-id=\"8-11\"><rect x=\"136\" y=\"22\" width=\"123\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"197.5\" y=\"42.9\">TYPE</text></g><g class=\"pele-node\" data-id=\"12-12\"><rect x=\"104\" y=\"22\" width=\"27\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"117.5\" y=\"42.9\">EN</text></g><g class=\"pele-node\" data-id=\"13-15\"><rect x=\"8\" y=\"22\" width=\"91\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"53.5\" y=\"42.9\">RES</text></g><g class=\"pele-node\" data-id=\"16-19\"><rect x=\"392\" y=\"73\" width=\"123\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"453.5\" y=\"93.9\">NEXT</text></g></g><g class=\"pele-packet-bits\" font-size=\"10\" fill=\"var(--_m)\"><text x=\"264\" y=\"18\">7</text><text x=\"515\" y=\"18\" text-anchor=\"end\">0</text><text x=\"136\" y=\"18\">11</text><text x=\"259\" y=\"18\" text-anchor=\"end\">8</text><text x=\"117.5\" y=\"18\" text-anchor=\"middle\">12</text><text x=\"8\" y=\"18\">15</text><text x=\"99\" y=\"18\" text-anchor=\"end\">13</text><text x=\"392\" y=\"69\">19</text><text x=\"515\" y=\"69\" text-anchor=\"end\">16</text></g><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"261.5\" y=\"134.6\">Tiny</tspan></text></svg>",
  )
}

///|
test "showBits off leaves out the bit numbers and their room" {
  inspect(
    svg(
      "---\nconfig:\n  packet:\n    showBits: false\n---\npacket\n0-31: \"a\"",
    ),
    content="1035x48 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-packet\" viewBox=\"0 0 1035 48\" width=\"1035\" height=\"48\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"packet\"><g class=\"pele-packet-fields\" font-size=\"14\" text-anchor=\"middle\"><g class=\"pele-node\" data-id=\"0-31\"><rect x=\"8\" y=\"8\" width=\"1019\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"517.5\" y=\"28.9\">a</text></g></g></svg>",
  )
}

///|
test "a narrow host turns the packet to fit, wrapping labels and the title" {
  inspect(
    svg(
      "packet\ntitle A long packet title\n0-31: \"A fairly long label here\"\n32-39: \"ab\"",
      max_width=160,
    ),
    content="155x382 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-packet\" viewBox=\"0 0 155 382\" width=\"155\" height=\"382\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"packet\"><g class=\"pele-packet-fields\" font-size=\"14\" text-anchor=\"middle\"><g class=\"pele-node\" data-id=\"0-7\"><rect x=\"8\" y=\"22\" width=\"139\" height=\"52\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"77.5\" y=\"42.4\">A fairly long label</tspan><tspan x=\"77.5\" y=\"63.4\">here</tspan></text></g><g class=\"pele-node\" data-id=\"8-15\"><rect x=\"8\" y=\"93\" width=\"139\" height=\"52\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"77.5\" y=\"113.4\">A fairly long label</tspan><tspan x=\"77.5\" y=\"134.4\">here</tspan></text></g><g class=\"pele-node\" data-id=\"16-23\"><rect x=\"8\" y=\"164\" width=\"139\" height=\"52\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"77.5\" y=\"184.4\">A fairly long label</tspan><tspan x=\"77.5\" y=\"205.4\">here</tspan></text></g><g class=\"pele-node\" data-id=\"24-31\"><rect x=\"8\" y=\"235\" width=\"139\" height=\"52\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"77.5\" y=\"255.4\">A fairly long label</tspan><tspan x=\"77.5\" y=\"276.4\">here</tspan></text></g><g class=\"pele-node\" data-id=\"32-39\"><rect x=\"8\" y=\"306\" width=\"139\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"77.5\" y=\"326.9\" text-anchor=\"middle\">ab</text></g></g><g class=\"pele-packet-bits\" font-size=\"10\" fill=\"var(--_m)\"><text x=\"8\" y=\"18\">0</text><text x=\"147\" y=\"18\" text-anchor=\"end\">7</text><text x=\"8\" y=\"89\">8</text><text x=\"147\" y=\"89\" text-anchor=\"end\">15</text><text x=\"8\" y=\"160\">16</text><text x=\"147\" y=\"160\" text-anchor=\"end\">23</text><text x=\"8\" y=\"231\">24</text><text x=\"147\" y=\"231\" text-anchor=\"end\">31</text><text x=\"8\" y=\"302\">32</text><text x=\"147\" y=\"302\" text-anchor=\"end\">39</text></g><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"77.5\" y=\"367.6\">A long packet title</tspan></text></svg>",
  )
}

///|
test "an empty packet" {
  inspect(
    svg("packet"),
    content="16x16 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-packet\" viewBox=\"0 0 16 16\" width=\"16\" height=\"16\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"packet\"></svg>",
  )
}

///|
test "a packet with only a title" {
  inspect(
    svg("packet\ntitle Nothing yet"),
    content="104x40 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-packet\" viewBox=\"0 0 104 40\" width=\"104\" height=\"40\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"packet\"><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"52\" y=\"25.6\">Nothing yet</tspan></text></svg>",
  )
}

///|
test "accessible names are written" {
  inspect(
    svg("packet\naccTitle: Name\naccDescr: Text\n0-31: \"a\""),
    content="1035x62 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-packet\" viewBox=\"0 0 1035 62\" width=\"1035\" height=\"62\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"packet\" aria-labelledby=\"pele-title\" aria-describedby=\"pele-desc\"><title id=\"pele-title\">Name</title><desc id=\"pele-desc\">Text</desc><g class=\"pele-packet-fields\" font-size=\"14\" text-anchor=\"middle\"><g class=\"pele-node\" data-id=\"0-31\"><rect x=\"8\" y=\"22\" width=\"1019\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"517.5\" y=\"42.9\">a</text></g></g><g class=\"pele-packet-bits\" font-size=\"10\" fill=\"var(--_m)\"><text x=\"8\" y=\"18\">0</text><text x=\"1027\" y=\"18\" text-anchor=\"end\">31</text></g></svg>",
  )
}

///|
test "a label too long for even the smallest size is cut" {
  inspect(
    svg("packet\n0: \"Wide\"\n1: \"Extraordinarily long\"\n2-31: \"x\""),
    content="1035x62 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-packet\" viewBox=\"0 0 1035 62\" width=\"1035\" height=\"62\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"packet\"><g class=\"pele-packet-fields\" font-size=\"14\" text-anchor=\"middle\"><g class=\"pele-node\" data-id=\"0-0\"><rect x=\"8\" y=\"22\" width=\"27\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"21.5\" y=\"41.15\" font-size=\"9\">Wide</text></g><g class=\"pele-node\" data-id=\"1-1\"><rect x=\"40\" y=\"22\" width=\"27\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"53.5\" y=\"40.8\" font-size=\"8\">Extr…</text></g><g class=\"pele-node\" data-id=\"2-31\"><rect x=\"72\" y=\"22\" width=\"955\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"549.5\" y=\"42.9\">x</text></g></g><g class=\"pele-packet-bits\" font-size=\"10\" fill=\"var(--_m)\"><text x=\"21.5\" y=\"18\" text-anchor=\"middle\">0</text><text x=\"53.5\" y=\"18\" text-anchor=\"middle\">1</text><text x=\"72\" y=\"18\">2</text><text x=\"1027\" y=\"18\" text-anchor=\"end\">31</text></g></svg>",
  )
}

///|
test "unusable config is ignored" {
  inspect(
    svg(
      "---\nconfig:\n  packet:\n    bitsPerRow: -4\n    bitWidth: \"wide\"\n    rowHeight: 0\n    paddingX: 9999\n---\npacket\n0-15: \"a\"\n16-31: \"b\"",
    ),
    content="1009x62 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-packet\" viewBox=\"0 0 1009 62\" width=\"1009\" height=\"62\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"packet\"><g class=\"pele-packet-fields\" font-size=\"14\" text-anchor=\"middle\"><g class=\"pele-node\" data-id=\"0-15\"><rect x=\"8\" y=\"22\" width=\"481\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"248.5\" y=\"42.9\">a</text></g><g class=\"pele-node\" data-id=\"16-31\"><rect x=\"520\" y=\"22\" width=\"481\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"760.5\" y=\"42.9\">b</text></g></g><g class=\"pele-packet-bits\" font-size=\"10\" fill=\"var(--_m)\"><text x=\"8\" y=\"18\">0</text><text x=\"489\" y=\"18\" text-anchor=\"end\">15</text><text x=\"520\" y=\"18\">16</text><text x=\"1001\" y=\"18\" text-anchor=\"end\">31</text></g></svg>",
  )
}

///|
test "config sets the size of rows, bits, and gaps" {
  inspect(
    svg(
      "---\nconfig:\n  packet:\n    bitsPerRow: 8\n    bitWidth: 10\n    rowHeight: 80\n    paddingX: 20\n    paddingY: 30\n---\npacket\n0-7: \"a\"\n8-15: \"b\"\n16-23: \"c\"",
    ),
    content="87x358 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-packet\" viewBox=\"0 0 87 358\" width=\"87\" height=\"358\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"packet\"><g class=\"pele-packet-fields\" font-size=\"14\" text-anchor=\"middle\"><g class=\"pele-node\" data-id=\"0-7\"><rect x=\"8\" y=\"22\" width=\"71\" height=\"80\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"43.5\" y=\"66.9\">a</text></g><g class=\"pele-node\" data-id=\"8-15\"><rect x=\"8\" y=\"146\" width=\"71\" height=\"80\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"43.5\" y=\"190.9\">b</text></g><g class=\"pele-node\" data-id=\"16-23\"><rect x=\"8\" y=\"270\" width=\"71\" height=\"80\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"43.5\" y=\"314.9\">c</text></g></g><g class=\"pele-packet-bits\" font-size=\"10\" fill=\"var(--_m)\"><text x=\"8\" y=\"18\">0</text><text x=\"79\" y=\"18\" text-anchor=\"end\">7</text><text x=\"8\" y=\"142\">8</text><text x=\"79\" y=\"142\" text-anchor=\"end\">15</text><text x=\"8\" y=\"266\">16</text><text x=\"79\" y=\"266\" text-anchor=\"end\">23</text></g></svg>",
  )
}

///|
test "a field split over rows is repeated on each" {
  inspect(
    svg("packet\n0-10: \"test\"\n11-90: \"multiple\""),
    content="1035x164 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-packet\" viewBox=\"0 0 1035 164\" width=\"1035\" height=\"164\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"packet\"><g class=\"pele-packet-fields\" font-size=\"14\" text-anchor=\"middle\"><g class=\"pele-node\" data-id=\"0-10\"><rect x=\"8\" y=\"22\" width=\"347\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"181.5\" y=\"42.9\">test</text></g><g class=\"pele-node\" data-id=\"11-31\"><rect x=\"360\" y=\"22\" width=\"667\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"693.5\" y=\"42.9\">multiple</text></g><g class=\"pele-node\" data-id=\"32-63\"><rect x=\"8\" y=\"73\" width=\"1019\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"517.5\" y=\"93.9\">multiple</text></g><g class=\"pele-node\" data-id=\"64-90\"><rect x=\"8\" y=\"124\" width=\"859\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"437.5\" y=\"144.9\">multiple</text></g></g><g class=\"pele-packet-bits\" font-size=\"10\" fill=\"var(--_m)\"><text x=\"8\" y=\"18\">0</text><text x=\"355\" y=\"18\" text-anchor=\"end\">10</text><text x=\"360\" y=\"18\">11</text><text x=\"1027\" y=\"18\" text-anchor=\"end\">31</text><text x=\"8\" y=\"69\">32</text><text x=\"1027\" y=\"69\" text-anchor=\"end\">63</text><text x=\"8\" y=\"120\">64</text><text x=\"867\" y=\"120\" text-anchor=\"end\">90</text></g></svg>",
  )
}

///|
test "the front matter title is used without an own title" {
  inspect(
    svg("---\ntitle: From front matter\n---\npacket\n0-31: \"<b>&amp;</b> x\""),
    content="1035x98 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-packet\" viewBox=\"0 0 1035 98\" width=\"1035\" height=\"98\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"packet\"><g class=\"pele-packet-fields\" font-size=\"14\" text-anchor=\"middle\"><g class=\"pele-node\" data-id=\"0-31\"><rect x=\"8\" y=\"22\" width=\"1019\" height=\"32\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text x=\"517.5\" y=\"42.9\">&lt;b&gt;&amp;&lt;/b&gt; x</text></g></g><g class=\"pele-packet-bits\" font-size=\"10\" fill=\"var(--_m)\"><text x=\"8\" y=\"18\">0</text><text x=\"1027\" y=\"18\" text-anchor=\"end\">31</text></g><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"517.5\" y=\"83.6\">From front matter</tspan></text></svg>",
  )
}
