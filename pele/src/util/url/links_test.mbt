///|
fn shown(value : String?) -> String {
  match value {
    Some(text) => text.escape()
    None => "-"
  }
}

///|
let link_options : Array[@types.RenderOptions] = [
  @types.RenderOptions::default(),
  { ..@types.RenderOptions::default(), links: Some(false), },
  { ..@types.RenderOptions::default(), link_schemes: Some(["obsidian"]), },
  { ..@types.RenderOptions::default(), images: Some(false), },
  { ..@types.RenderOptions::default(), image_schemes: Some(["data"]), },
]

///|
fn allowed(url : String) -> String {
  let links = link_options.map(o => shown(@url.link_url(url, o))).join(" ")
  let images = link_options.map(o => shown(@url.image_url(url, o))).join(" ")
  "\{links} | \{images}"
}

///|
test "entity codes are read before a URL is sanitized" {
  inspect(@url.safe_url("&#106;avascript:x"), content="about:blank")
  inspect(@url.safe_url("a &amp; b"), content="a & b")
  inspect(@url.safe_url("https://x/?a=1&amp;b=2"), content="https://x/?a=1&b=2")
  inspect(@url.safe_url("https&#58;//x"), content="https://x/")
  inspect(@url.safe_url("&lt;b&gt;"), content="<b>")
}

///|
test "links and images keep relative URLs and the schemes the host allows" {
  inspect(
    allowed("https://x/"),
    content="\"https://x/\" - - \"https://x/\" \"https://x/\" | \"https://x/\" \"https://x/\" \"https://x/\" - -",
  )
  inspect(
    allowed("HTTP://x"),
    content="\"HTTP://x\" - - \"HTTP://x\" \"HTTP://x\" | \"HTTP://x\" \"HTTP://x\" \"HTTP://x\" - -",
  )
  inspect(
    allowed("mailto:a@b"),
    content="\"mailto:a@b\" - - \"mailto:a@b\" \"mailto:a@b\" | - - - - -",
  )
  inspect(
    allowed("tel:1"),
    content="\"tel:1\" - - \"tel:1\" \"tel:1\" | - - - - -",
  )
  inspect(allowed("ftp://x"), content="- - - - - | - - - - -")
  inspect(
    allowed("obsidian://open"),
    content="- - \"obsidian://open\" - - | - - - - -",
  )
  inspect(
    allowed("rel/path"),
    content="\"rel/path\" - \"rel/path\" \"rel/path\" \"rel/path\" | \"rel/path\" \"rel/path\" \"rel/path\" - \"rel/path\"",
  )
  inspect(
    allowed("#frag"),
    content="\"#frag\" - \"#frag\" \"#frag\" \"#frag\" | \"#frag\" \"#frag\" \"#frag\" - \"#frag\"",
  )
  inspect(allowed("data:x"), content="- - - - - | - - - - \"data:x\"")
  inspect(allowed("a+b.c-d:e"), content="- - - - - | - - - - -")
}

///|
test "a URL that only looks like it has a scheme is relative" {
  inspect(
    allowed("a b:c"),
    content="\"a b:c\" - \"a b:c\" \"a b:c\" \"a b:c\" | \"a b:c\" \"a b:c\" \"a b:c\" - \"a b:c\"",
  )
  inspect(
    allowed("1a:b"),
    content="\"1a:b\" - \"1a:b\" \"1a:b\" \"1a:b\" | \"1a:b\" \"1a:b\" \"1a:b\" - \"1a:b\"",
  )
}

///|
test "network paths are refused" {
  inspect(allowed("//server/x"), content="- - - - - | - - - - -")
  inspect(allowed("\\\\server"), content="- - - - - | - - - - -")
  inspect(allowed("\\/x"), content="- - - - - | - - - - -")
}

///|
test "a linked shape is wrapped in an anchor and recorded" {
  let links : Array[@types.LinkInfo] = []
  let options = @types.RenderOptions::default()
  inspect(
    @url.linked("<rect/>", "https://x/?a=1&b=\"2\"", "A", links, options),
    content="<a href=\"https://x/?a=1&amp;b=&quot;2&quot;\" rel=\"noopener\"><rect/></a>",
  )
  inspect(
    @url.linked("<rect/>", "ftp://x", "B", links, options),
    content="<rect/>",
  )
  inspect(
    @url.linked(
      "<rect/>",
      "https://x/",
      "C",
      links,
      { ..options, link_rel: Some(""), },
      attrs=" target=\"_blank\"",
    ),
    content="<a href=\"https://x/\" target=\"_blank\"><rect/></a>",
  )
  inspect(
    links.map(l => "\{l.id} \{l.href} \{l.internal}").join("\n"),
    content=(
      #|A https://x/?a=1&b="2" false
      #|C https://x/ false
    ),
  )
}

///|
test "the rel attribute defaults to noopener and can be left out" {
  let options = @types.RenderOptions::default()
  inspect(@url.rel_attr(options), content=" rel=\"noopener\"")
  inspect(
    @url.rel_attr({ ..options, link_rel: Some("a\"b"), }),
    content=" rel=\"a&quot;b\"",
  )
  inspect(@url.rel_attr({ ..options, link_rel: Some(""), }), content="")
}

///|
test "a link start is written as link_start makes it, recording the same link" {
  let options = [
    @types.RenderOptions::default(),
    { ..@types.RenderOptions::default(), links: Some(false), },
    { ..@types.RenderOptions::default(), link_rel: Some(""), },
  ]
  for option in options {
    for url in ["https://x/?a=1&b=<2>", "javascript:x", "a&\"b", ""] {
      let want_links = []
      let want = @url.link_start(
        url,
        "id",
        want_links,
        option,
        attrs=" target=\"_blank\"",
      )
      let got_links = []
      let out = @svg.Markup::new()
      let written = @url.write_link_start(
        out,
        url,
        "id",
        got_links,
        option,
        attrs=" target=\"_blank\"",
      )
      assert_eq(written, want is Some(_))
      assert_eq(out.to_string(), want.unwrap_or(""))
      assert_eq(got_links.length(), want_links.length())
      for i, link in got_links {
        assert_eq(link.href, want_links[i].href)
        assert_eq(link.id, want_links[i].id)
      }
    }
  }
}
