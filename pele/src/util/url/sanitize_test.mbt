///|
/// Pairs of a click target and what `sanitizeUrl` makes of it, from pele 1.12.0.
/// Each answer also agrees with @braintree/sanitize-url, which Mermaid applies to click targets,
/// apart from the percent escapes pele keeps.
let sanitized : Array[(String, String)] = [
  ("https://example.com", "https://example.com/"),
  ("http://EXAMPLE.com/Path?q=1#frag", "http://example.com/Path?q=1#frag"),
  ("click.html", "click.html"),
  ("./relative/path", "./relative/path"),
  ("/absolute/path", "/absolute/path"),
  ("mailto:someone@example.com", "mailto:someone@example.com"),
  (
    "obsidian://open?vault=Notes&file=Idea", "obsidian://open?vault=Notes&file=Idea",
  ),
  ("javascript:alert(1)", "about:blank"),
  ("JaVaScRiPt:alert(1)", "about:blank"),
  ("  javascript:alert(1)", "about:blank"),
  ("java\u{a}script:alert(1)", "about:blank"),
  ("jav&#x09;ascript:alert(1)", "about:blank"),
  ("&#106;avascript:alert(1)", "about:blank"),
  ("data:text/html,<script>alert(1)</script>", "about:blank"),
  ("vbscript:msgbox(1)", "about:blank"),
  ("javascript&colon;alert(1)", "about:blank"),
  ("%6A%61%76%61%73%63%72%69%70%74:alert(1)", "about:blank"),
  ("https://example.com/a b", "https://example.com/a%20b"),
  ("http://", "about:blank"),
  ("ftp://example.com/file", "ftp://example.com/file"),
  ("www.example.com", "www.example.com"),
  ("C:\\Users\\file.txt", "C:/Users/file.txt"),
  ("\\\\server\\share", "\\\\server\\share"),
  ("note name with spaces", "note name with spaces"),
  ("#heading", "#heading"),
  ("?query=1", "?query=1"),
  ("", "about:blank"),
  ("about:blank", "about:blank"),
  ("tel:+123456", "tel:+123456"),
  ("https://example.com/%E0%A4%A", "https://example.com/%E0%A4%A"),
  ("&#0x6A;avascript:alert(1)", "about:blank"),
  ("&#1e2;", "d"),
  ("&#65536;x", "x"),
  ("&#65601x", "about:blank"),
  ("&#Infinity;a", "a"),
  ("&NewLine;javascript:alert(1)", "about:blank"),
  ("&TAB;x", "x"),
  ("a\\nb", "ab"),
  ("a%5Cnb", "ab"),
  ("a\\%6Eb", "ab"),
  ("a%5c%72b", "ab"),
  ("%2525252541", "%2525252541"),
  (
    "%25252525252525252525252525252525252525252525252525252525252525252525252525252525",
    "%25252525252525252525252525252525252525252525252525252525252525252525252525252525",
  ),
  ("x%%%%", "x%%%%"),
  ("%C0%AF", "%C0%AF"),
  ("%ED%A0%80", "%ED%A0%80"),
  ("%F4%90%80%80", "%F4%90%80%80"),
  ("%E2%82", "%E2%82"),
  ("%e2%82%ac", "%e2%82%ac"),
  (" %20http://x ", "about:blank"),
  ("http:x", "http://x/"),
  ("http:/x", "http://x/"),
  ("http:\\\\x", "http://x/"),
  (
    "HTTP://EXAMPLE.com/A/./b/../c/%2e%2E/d?Q=1 2#F 3", "http://example.com/A/d?Q=1%202#F%203",
  ),
  ("http://a@b@c/", "http://a%40b@c/"),
  ("http://a@/", "about:blank"),
  ("http://0x7f.1/", "http://127.0.0.1/"),
  ("http://127.0.0.1./", "http://127.0.0.1/"),
  ("http://1.2.3.4.5/", "about:blank"),
  ("http://999999999/", "http://59.154.201.255/"),
  ("http://4294967296/", "about:blank"),
  ("http://08/", "about:blank"),
  ("http://0x/", "http://0.0.0.0/"),
  ("http://a.0x1g/", "http://a.0x1g/"),
  ("http://a.1/", "about:blank"),
  ("http://XN--LS8H.la/", "http://xn--ls8h.la/"),
  ("http://\u{c9}XAMPLE.com/", "http://xn--xample-9ua.com/"),
  ("http://m\u{fc}ller.de/", "http://xn--mller-kva.de/"),
  ("http://a%2541.com/", "about:blank"),
  ("http://a%252.com/", "about:blank"),
  ("http://a b/", "about:blank"),
  ("http://a<b/", "about:blank"),
  ("http://a^b/", "about:blank"),
  ("http://a|b/", "about:blank"),
  ("http://x/\u{e9}?\u{e9}#\u{e9}", "http://x/%C3%A9?%C3%A9#%C3%A9"),
  (
    "http://x/'\"<>^`{}|?'\"<>^`{}|#'\"<>^`{}|", "http://x/'%22%3C%3E%5E%60%7B%7D|?%27%22%3C%3E^`{}|#'%22%3C%3E^%60{}|",
  ),
  ("http://x/a%252/b", "http://x/a%252/b"),
  ("http://x/..", "http://x/"),
  ("http://x/a/..", "http://x/"),
  ("http://x/a/.", "http://x/a/"),
  ("http://x/.%252e/", "http://x/.%252e/"),
  ("http://[1]/", "about:blank"),
  ("http://a..b/", "http://a..b/"),
  ("http://.a/", "http://.a/"),
  ("http://a./", "http://a./"),
  ("http://x?y", "http://x/?y"),
  ("http://x#y", "http://x/#y"),
  ("http://x/a\\b", "http://x/a/b"),
  ("https://www.github.com", "https://www.github.com/"),
  ("Https://Www.GitHub.com/Foo", "https://www.github.com/Foo"),
  ("http://x\u{2028}y:z", "about:blank"),
  ("foo\u{2028}http:x", "about:blank"),
  ("a:b:c", "a:b:c"),
  (":a", ":a"),
  ("x&colon;y:z", "x&colon;y:z"),
  (".\u{2028}javascript:x", ".\u{2028}javascript:x"),
  ("\u{a0}javascript:x", "about:blank"),
  ("https://example.com/\u{e9}", "https://example.com/%C3%A9"),
  ("ht%74p://x", "about:blank"),
  ("mailto:A@B.c", "mailto:A@B.c"),
  ("MAILTO:a@b", "MAILTO:a@b"),
  ("tel:1", "tel:1"),
  ("file:///etc/passwd", "file:///etc/passwd"),
  ("//server/share", "//server/share"),
  ("\\\\server", "\\\\server"),
  ("data&colon;x", "about:blank"),
  ("vbscript&colon;x", "about:blank"),
  ("xjavascript:x", "xjavascript:x"),
  ("-javascript:x", "about:blank"),
  ("!!data:x", "about:blank"),
  ("a&#58;b", "a:b"),
  ("&#x;", "about:blank"),
  ("&#;", "&#;"),
  ("&#a", "about:blank"),
]

///|
test "click targets are sanitized as pele 1.12.0 does" {
  let wrong = []
  for pair in sanitized {
    let (url, expected) = pair
    let actual = @url.sanitize_url(url)
    if actual != expected {
      wrong.push(
        "\{url.escape()} gave \{actual.escape()}, not \{expected.escape()}",
      )
    }
  }
  inspect(wrong.join("\n"), content="")
}

///|
test "percent escapes are kept" {
  for
    url in [
      "obsidian://open?vault=V&file=A%26B%23C", "https://example.com/?q=a%26b", "mailto:a@example.com?subject=a%20b",
      "Note%20name", "./a%23b.html",
    ] {
    assert_eq(@url.sanitize_url(url), url)
  }
}

///|
test "percent escapes cannot hide a scheme or a network path" {
  inspect(
    @url.sanitize_url("%6A%61%76%61%73%63%72%69%70%74:alert(1)"),
    content="about:blank",
  )
  let options = @types.RenderOptions::default()
  for
    url in [
      "fi%6ce:///etc/passwd", "%2F%2Fevil.example/share", "obs%69dian://open",
    ] {
    assert_eq(@url.link_url(@url.sanitize_url(url), options), None)
  }
}

///|
test "lone surrogates, U+FFFE and U+FFFF are stripped before the scheme is checked" {
  let lone = (c : Int32) => String::from_array([c.unsafe_to_char()])
  inspect(@url.sanitize_url("http://x/" + lone(0xd800)), content="http://x/")
  inspect(
    @url.sanitize_url("java" + lone(0xdc00) + "script:alert(1)"),
    content="about:blank",
  )
  inspect(
    @url.sanitize_url("java\u{fffe}script:alert(1)"),
    content="about:blank",
  )
  inspect(
    @url.sanitize_url("file\u{ffff}:///etc/passwd"),
    content="file:///etc/passwd",
  )
  inspect(
    @url.sanitize_url("http://x/\u{1f600}"),
    content="http://x/%F0%9F%98%80",
  )
}
