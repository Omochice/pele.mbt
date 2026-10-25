///|
fn svg(source : String, max_width? : Double) -> String {
  let options = { ..@types.RenderOptions::default(), max_width, }
  let result = @core.render([@venn.venn], source, options) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "\{result.width}x\{result.height} \{result.svg}"
}

///|
test "renders two sets and their overlap" {
  inspect(
    svg("venn-beta\nset A\nset B\nunion A,B"),
    content="343x216 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-venn\" viewBox=\"0 0 343 216\" width=\"343\" height=\"216\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"venn\"><g class=\"pele-venn-sets\"><circle class=\"pele-venn-set\" data-id=\"A\" cx=\"108\" cy=\"108\" r=\"100\" fill=\"var(--pele-series-1,#4c78a8)\" fill-opacity=\"0.2\" stroke=\"var(--pele-series-1,#4c78a8)\"/><circle class=\"pele-venn-set\" data-id=\"B\" cx=\"234.94\" cy=\"108\" r=\"100\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.2\" stroke=\"var(--pele-series-2,#f58518)\"/></g><g class=\"pele-venn-labels\"><g class=\"pele-venn-region\" data-id=\"A\"><text class=\"pele-label\" x=\"71.54\" y=\"110.81\" text-anchor=\"middle\">A</text></g><g class=\"pele-venn-region\" data-id=\"B\"><text class=\"pele-label\" x=\"271.41\" y=\"110.81\" text-anchor=\"middle\">B</text></g></g></svg>",
  )
}

///|
test "renders styles" {
  inspect(
    svg(
      "venn-beta\nset A\n  text A1[\"React\"]\nset B\nunion A,B[\"AB\"]\nstyle A fill:#ff6b6b, stroke-width:3\nstyle A,B color:#333\nstyle A1 color:red\nstyle B fill-opacity:0.5\nstyle A stroke:black",
    ),
    content="343x216 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-venn\" viewBox=\"0 0 343 216\" width=\"343\" height=\"216\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"venn\"><g class=\"pele-venn-sets\"><circle class=\"pele-venn-set\" data-id=\"A\" cx=\"108\" cy=\"108\" r=\"100\" fill=\"var(--pele-series-1,#4c78a8)\" fill-opacity=\"0.2\" stroke=\"var(--pele-series-1,#4c78a8)\" style=\"fill:#ff6b6b;stroke-width:3;stroke:black;\"/><circle class=\"pele-venn-set\" data-id=\"B\" cx=\"234.94\" cy=\"108\" r=\"100\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.2\" stroke=\"var(--pele-series-2,#f58518)\" style=\"fill-opacity:0.5;\"/></g><g class=\"pele-venn-labels\"><g class=\"pele-venn-region\" data-id=\"A\"><text class=\"pele-label\" x=\"71.54\" y=\"100.81\" text-anchor=\"middle\">A</text><text class=\"pele-venn-text\" data-id=\"A1\" font-size=\"13\" fill=\"var(--_m)\" style=\"fill:red;\" x=\"71.54\" y=\"121.76\" text-anchor=\"middle\">React</text></g><g class=\"pele-venn-region\" data-id=\"B\"><text class=\"pele-label\" x=\"271.41\" y=\"110.81\" text-anchor=\"middle\">B</text></g><g class=\"pele-venn-region\" data-id=\"A|B\"><text class=\"pele-label\" font-size=\"14\" style=\"fill:#333;\" x=\"171.47\" y=\"112.9\" text-anchor=\"middle\">AB</text></g></g></svg>",
  )
}

///|
test "renders overlap fill" {
  inspect(
    svg(
      "venn-beta\nset A\nset B\nset C\nunion A,B[\"ab\"]\nunion A,B,C[\"abc\"]\nstyle A,B fill:gold\nstyle A,B,C fill:#333",
    ),
    content="343x326 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-venn\" viewBox=\"0 0 343 326\" width=\"343\" height=\"326\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"venn\"><g class=\"pele-venn-sets\"><circle class=\"pele-venn-set\" data-id=\"A\" cx=\"108\" cy=\"108\" r=\"100\" fill=\"var(--pele-series-1,#4c78a8)\" fill-opacity=\"0.2\" stroke=\"var(--pele-series-1,#4c78a8)\"/><circle class=\"pele-venn-set\" data-id=\"B\" cx=\"234.94\" cy=\"108\" r=\"100\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.2\" stroke=\"var(--pele-series-2,#f58518)\"/><circle class=\"pele-venn-set\" data-id=\"C\" cx=\"171.47\" cy=\"217.93\" r=\"100\" fill=\"var(--pele-series-3,#54a24b)\" fill-opacity=\"0.2\" stroke=\"var(--pele-series-3,#54a24b)\"/></g><g class=\"pele-venn-overlaps\"><path class=\"pele-venn-overlap\" data-id=\"A|B\" d=\"M171.47,30.72A100,100 0 0 1 171.47,185.28A100,100 0 0 1 171.47,30.72Z\" fill=\"none\" style=\"fill:gold;\"/><path class=\"pele-venn-overlap\" data-id=\"A|B|C\" d=\"M136.28,124.33A100,100 0 0 1 206.66,124.33A100,100 0 0 1 171.47,185.28A100,100 0 0 1 136.28,124.33Z\" fill=\"none\" style=\"fill:#333;\"/></g><g class=\"pele-venn-labels\"><g class=\"pele-venn-region\" data-id=\"A\"><text class=\"pele-label\" x=\"74.63\" y=\"94.33\" text-anchor=\"middle\">A</text></g><g class=\"pele-venn-region\" data-id=\"B\"><text class=\"pele-label\" x=\"268.31\" y=\"94.33\" text-anchor=\"middle\">B</text></g><g class=\"pele-venn-region\" data-id=\"C\"><text class=\"pele-label\" x=\"171.47\" y=\"262.07\" text-anchor=\"middle\">C</text></g><g class=\"pele-venn-region\" data-id=\"A|B\"><text class=\"pele-label\" font-size=\"14\" x=\"171.47\" y=\"90.23\" text-anchor=\"middle\">ab</text></g><g class=\"pele-venn-region\" data-id=\"A|B|C\"><text class=\"pele-label\" font-size=\"14\" x=\"171.47\" y=\"149.54\" text-anchor=\"middle\">abc</text></g></g></svg>",
  )
}

///|
test "renders title" {
  inspect(
    svg("venn-beta\ntitle \"Team overlap\"\nset A"),
    content="216x252 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-venn\" viewBox=\"0 0 216 252\" width=\"216\" height=\"252\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"venn\"><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"108\" y=\"25.6\">Team overlap</tspan></text><g class=\"pele-venn-sets\"><circle class=\"pele-venn-set\" data-id=\"A\" cx=\"108\" cy=\"144\" r=\"100\" fill=\"var(--pele-series-1,#4c78a8)\" fill-opacity=\"0.2\" stroke=\"var(--pele-series-1,#4c78a8)\"/></g><g class=\"pele-venn-labels\"><g class=\"pele-venn-region\" data-id=\"A\"><text class=\"pele-label\" x=\"108\" y=\"149.6\" text-anchor=\"middle\">A</text></g></g></svg>",
  )
}

///|
test "renders empty" {
  inspect(
    svg("venn-beta\n"),
    content="16x16 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-venn\" viewBox=\"0 0 16 16\" width=\"16\" height=\"16\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"venn\"><g class=\"pele-venn-sets\"></g></svg>",
  )
}

///|
test "renders wrapped" {
  inspect(
    svg(
      "venn-beta\nset A[\"A very long label for a set that goes on and on\"]\nset B\nunion A,B[\"An intersection with a long label\"]",
    ),
    content=(
      #|540x337 <svg xmlns="http://www.w3.org/2000/svg" class="pele pele-venn" viewBox="0 0 540 337" width="540" height="337" style="max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)" fill="var(--_fg)" role="graphics-document document" aria-roledescription="venn"><g class="pele-venn-sets"><circle class="pele-venn-set" data-id="A" cx="168" cy="168" r="160" fill="var(--pele-series-1,#4c78a8)" fill-opacity="0.2" stroke="var(--pele-series-1,#4c78a8)"/><circle class="pele-venn-set" data-id="B" cx="371.11" cy="168" r="160" fill="var(--pele-series-2,#f58518)" fill-opacity="0.2" stroke="var(--pele-series-2,#f58518)"/></g><g class="pele-venn-labels"><g class="pele-venn-region" data-id="A"><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="109.66" y="158.64">A very long label for a set</tspan><tspan x="109.66" y="179.64">that goes on and on</tspan></text></g><g class="pele-venn-region" data-id="B"><text class="pele-label" x="429.45" y="169.14" text-anchor="middle">B</text></g><g class="pele-venn-region" data-id="A|B"><text class="pele-label" font-size="14" text-anchor="middle" xml:space="preserve"><tspan x="269.55" y="163.9">An intersection</tspan><tspan x="269.55" y="181.9">with a long label</tspan></text></g></g></svg>
    ),
  )
}

///|
test "renders front matter title" {
  inspect(
    svg("---\ntitle: From the front matter\n---\nvenn-beta\nset A"),
    content="216x252 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-venn\" viewBox=\"0 0 216 252\" width=\"216\" height=\"252\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"venn\"><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"108\" y=\"25.6\">From the front matter</tspan></text><g class=\"pele-venn-sets\"><circle class=\"pele-venn-set\" data-id=\"A\" cx=\"108\" cy=\"144\" r=\"100\" fill=\"var(--pele-series-1,#4c78a8)\" fill-opacity=\"0.2\" stroke=\"var(--pele-series-1,#4c78a8)\"/></g><g class=\"pele-venn-labels\"><g class=\"pele-venn-region\" data-id=\"A\"><text class=\"pele-label\" x=\"108\" y=\"149.6\" text-anchor=\"middle\">A</text></g></g></svg>",
  )
}

///|
test "renders escaped" {
  inspect(
    svg(
      "venn-beta\ntitle <img src=x onerror=alert(1)>\nset \"<script>a&b</script>\"\n  text \"</text><script>alert(1)</script>\"\nset B[<svg onload=alert(1)>]\nstyle B fill:\"url(javascript:alert(1))\", stroke:\"red' onload='alert(1)\"",
    ),
    content="431x252 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-venn\" viewBox=\"0 0 431 252\" width=\"431\" height=\"252\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_tw:var(--pele-title-weight,bold);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"venn\"><text class=\"pele-title\" font-weight=\"var(--_tw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"215.5\" y=\"25.6\"> </tspan></text><g class=\"pele-venn-sets\"><circle class=\"pele-venn-set\" data-id=\"&lt;script&gt;a&amp;b&lt;/script&gt;\" cx=\"108\" cy=\"144\" r=\"100\" fill=\"var(--pele-series-1,#4c78a8)\" fill-opacity=\"0.2\" stroke=\"var(--pele-series-1,#4c78a8)\"/><circle class=\"pele-venn-set\" data-id=\"B\" cx=\"323\" cy=\"144\" r=\"100\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.2\" stroke=\"var(--pele-series-2,#f58518)\" style=\"stroke:red' onload='alert(1);\"/></g><g class=\"pele-venn-labels\"><g class=\"pele-venn-region\" data-id=\"&lt;script&gt;a&amp;b&lt;/script&gt;\"><text class=\"pele-label\" x=\"108\" y=\"139.6\" text-anchor=\"middle\">a&amp;b</text><text class=\"pele-venn-text\" data-id=\"&lt;/text&gt;&lt;script&gt;alert(1)&lt;/script&gt;\" font-size=\"13\" fill=\"var(--_m)\" x=\"108\" y=\"160.55\" text-anchor=\"middle\">alert(1)</text></g><g class=\"pele-venn-region\" data-id=\"B\"><text class=\"pele-label\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"323\" y=\"149.6\"> </tspan></text></g></g></svg>",
  )
}

///|
test "renders last statement wins" {
  inspect(
    svg("venn-beta\nset A[\"first\"]:10\nset B:10\nset A[\"second\"]:40"),
    content="331x216 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-venn\" viewBox=\"0 0 331 216\" width=\"331\" height=\"216\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"venn\"><g class=\"pele-venn-sets\"><circle class=\"pele-venn-set\" data-id=\"A\" cx=\"108\" cy=\"108\" r=\"100\" fill=\"var(--pele-series-1,#4c78a8)\" fill-opacity=\"0.2\" stroke=\"var(--pele-series-1,#4c78a8)\"/><circle class=\"pele-venn-set\" data-id=\"B\" cx=\"273\" cy=\"108\" r=\"50\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.2\" stroke=\"var(--pele-series-2,#f58518)\"/></g><g class=\"pele-venn-labels\"><g class=\"pele-venn-region\" data-id=\"A\"><text class=\"pele-label\" x=\"108\" y=\"113.6\" text-anchor=\"middle\">second</text></g><g class=\"pele-venn-region\" data-id=\"B\"><text class=\"pele-label\" x=\"273\" y=\"113.6\" text-anchor=\"middle\">B</text></g></g></svg>",
  )
}

///|
test "renders texts and orphans" {
  inspect(
    svg(
      "venn-beta\nset A[\"Frontend\"]\n  text A1[\"React\"]\n  text A2\nset B\nunion A,B[\"Shared\"]\n  text AB1[\"OpenAPI\"]\ntext A,B orphan\n",
    ),
    content="413x259 <svg xmlns=\"http://www.w3.org/2000/svg\" class=\"pele pele-venn\" viewBox=\"0 0 413 259\" width=\"413\" height=\"259\" style=\"max-width:100%;height:auto;--_bg:var(--pele-bg,#fff);--_fg:var(--pele-fg,#1f1f1f);--_m:var(--pele-muted,#6e6e6e);--_l:var(--pele-line,#1f1f1f);--_s:var(--pele-surface,#f3f3f3);--_a:var(--pele-surface-alt,#e6e6e6);--_b:var(--pele-border,#8a8a8a);--_c:var(--pele-accent,#5b7bd5);color:var(--_fg);--_fm:var(--pele-font-mono,monospace);font:16px sans-serif;letter-spacing:normal;word-spacing:normal;text-transform:none;direction:ltr;font-family:var(--pele-font,sans-serif)\" fill=\"var(--_fg)\" role=\"graphics-document document\" aria-roledescription=\"venn\"><g class=\"pele-venn-sets\"><circle class=\"pele-venn-set\" data-id=\"A\" cx=\"129.34\" cy=\"129.34\" r=\"121.34\" fill=\"var(--pele-series-1,#4c78a8)\" fill-opacity=\"0.2\" stroke=\"var(--pele-series-1,#4c78a8)\"/><circle class=\"pele-venn-set\" data-id=\"B\" cx=\"283.36\" cy=\"129.34\" r=\"121.34\" fill=\"var(--pele-series-2,#f58518)\" fill-opacity=\"0.2\" stroke=\"var(--pele-series-2,#f58518)\"/></g><g class=\"pele-venn-labels\"><g class=\"pele-venn-region\" data-id=\"A\"><text class=\"pele-label\" x=\"85.09\" y=\"111.55\" text-anchor=\"middle\">Frontend</text><text class=\"pele-venn-text\" data-id=\"A1\" font-size=\"13\" fill=\"var(--_m)\" x=\"85.09\" y=\"132.5\" text-anchor=\"middle\">React</text><text class=\"pele-venn-text\" data-id=\"A2\" font-size=\"13\" fill=\"var(--_m)\" x=\"85.09\" y=\"152.5\" text-anchor=\"middle\">A2</text></g><g class=\"pele-venn-region\" data-id=\"B\"><text class=\"pele-label\" x=\"327.61\" y=\"131.55\" text-anchor=\"middle\">B</text></g><g class=\"pele-venn-region\" data-id=\"A|B\"><text class=\"pele-label\" font-size=\"14\" x=\"206.35\" y=\"114.24\" text-anchor=\"middle\">Shared</text><text class=\"pele-venn-text\" data-id=\"AB1\" font-size=\"13\" fill=\"var(--_m)\" x=\"206.35\" y=\"134.39\" text-anchor=\"middle\">OpenAPI</text><text class=\"pele-venn-text\" data-id=\"orphan\" font-size=\"13\" fill=\"var(--_m)\" x=\"206.35\" y=\"154.39\" text-anchor=\"middle\">orphan</text></g></g></svg>",
  )
}
