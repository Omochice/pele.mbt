///|
/// The root element pele writes, with every alias a diagram may define.
const ROOT : String =
  #|<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10" style="max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_r:var(--pele-radius,4px);--_hw:var(--pele-heading-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)" fill="var(--_fg)">

///|
/// What `resolve_vars` makes of `body` inside pele's root element.
fn resolve_body(body : String, theme~ : Map[String, String] = {}) -> String {
  let out = @theme.resolve_vars(ROOT + body + "</svg>", theme)
  let start = out.find(">").unwrap() + 1
  out.view(start_offset=start, end_offset=out.length() - 6).to_owned()
}

///|
test "the root's aliases are inlined and their declarations dropped" {
  inspect(
    @theme.resolve_vars(ROOT + "</svg>", {}),
    content=(
      #|<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10" style="max-width:100%;height:auto;color:#1f1f1f;font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:sans-serif" fill="#1f1f1f"></svg>
    ),
  )
}

///|
test "an alias takes the theme's value over pele's fallback" {
  let body =
    #|<rect fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/>
  inspect(
    resolve_body(body),
    content=(
      #|<rect fill="#f3f3f3" stroke="#8a8a8a" style="rx:4px"/>
    ),
  )
  inspect(
    resolve_body(body, theme={ "surface": "#222", "radius": "0" }),
    content=(
      #|<rect fill="#222" stroke="#8a8a8a" style="rx:0"/>
    ),
  )
}

///|
test "a series color takes the theme's value over pele's fallback" {
  let body =
    #|<path fill="var(--pele-series-2,#f58518)"/>
  inspect(
    resolve_body(body),
    content=(
      #|<path fill="#f58518"/>
    ),
  )
  inspect(
    resolve_body(body, theme={ "series-2": "teal" }),
    content=(
      #|<path fill="teal"/>
    ),
  )
}

///|
test "a label on a fill the source sets takes the theme's color for that fill" {
  let body =
    #|<text fill="var(--pele-fg-on-light,#1f1f1f)">a</text><text fill="var(--pele-fg-on-dark,#fff)">b</text>
  inspect(
    resolve_body(body),
    content=(
      #|<text fill="#1f1f1f">a</text><text fill="#fff">b</text>
    ),
  )
  inspect(
    resolve_body(body, theme={ "fg-on-light": "#111", "fg-on-dark": "#eee" }),
    content=(
      #|<text fill="#111">a</text><text fill="#eee">b</text>
    ),
  )
}

///|
test "an alias of an alias resolves through both" {
  let body =
    #|<text font-family="var(--_fm)" font-weight="var(--_hw)">x</text>
  inspect(
    resolve_body(body),
    content=(
      #|<text font-family="monospace" font-weight="bold">x</text>
    ),
  )
  inspect(
    resolve_body(body, theme={
      "font-mono": "DejaVu Sans Mono",
      "heading-weight": "600",
    }),
    content=(
      #|<text font-family="DejaVu Sans Mono" font-weight="600">x</text>
    ),
  )
}

///|
test "references inside other functions are resolved in place" {
  inspect(
    resolve_body(
      (
        #|<text fill="none" stroke="color-mix(in srgb,var(--_a) 50%,var(--_bg))">t</text>
      ),
    ),
    content=(
      #|<text fill="none" stroke="color-mix(in srgb,#e6e6e6 50%,#fff)">t</text>
    ),
  )
}

///|
test "text and attributes that are not CSS are left alone" {
  let body =
    #|<g data-id="var(--_fg)" aria-label="var(--_fg)"><title>var(--_fg)</title><a href="https://x.test/var(--_fg)"><text class="var(--_fg)">var(--_fg)</text></a></g>
  inspect(resolve_body(body), content=body)
}

///|
test "a theme value is escaped for the attribute it lands in" {
  inspect(
    resolve_body(
      (
        #|<text style="font-family:var(--pele-font,sans-serif)">x</text>
      ),
      theme={ "font": "\"Fira Sans\", <sans-serif>" },
    ),
    content=(
      #|<text style="font-family:&quot;Fira Sans&quot;, &lt;sans-serif&gt;">x</text>
    ),
  )
}

///|
test "a theme value that would end its declaration is ignored" {
  let body =
    #|<rect fill="var(--_bg)" stroke="var(--_l)"/>
  inspect(
    resolve_body(body, theme={ "bg": "red;stroke:blue", "line": "}" }),
    content=(
      #|<rect fill="#fff" stroke="#1f1f1f"/>
    ),
  )
}

///|
test "a reference to an undefined property drops what holds it" {
  inspect(
    resolve_body(
      (
        #|<rect style="fill:var(--brand);stroke:var(--_c)" fill="var(--brand)" stroke="red"/>
      ),
    ),
    content=(
      #|<rect style="stroke:#5b7bd5" stroke="red"/>
    ),
  )
}

///|
test "properties that refer to each other take the reference's fallback" {
  inspect(
    @theme.resolve_vars(
      (
        #|<svg style="--a:var(--b);--b:var(--a);color:var(--a,red)"><g style="--c:1"/></svg>
      ),
      {},
    ),
    content=(
      #|<svg style="color:red"><g/></svg>
    ),
  )
}
