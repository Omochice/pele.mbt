///|
/// `raw` laid out at 16 under math that typesets `x^2` and `fill`.
fn styled_label(raw : String) -> @text.Label {
  let math = (tex : String, _ : Double) => {
    match tex {
      "x^2" => Some(({ "svg": "<path/>", "width": 20, "height": 12 } : Json))
      "fill" => Some({ "html": "<i>f</i>", "width": 9, "height": 10 })
      _ => None
    }
  }
  @text.with_math(Some(math), () => {
    @text.layout_label(Some(raw), false, @text.metrics_measurer, 16, 4000)
  })
}

///|
fn written(write : (@svg.Markup) -> Unit raise @errors.PeleError) -> String {
  let out = @svg.Markup::new()
  write(out) catch {
    _ => abort("unreachable")
  }
  out.to_string()
}

///|
test "the styled writers write what the string ones write under the escaped style" {
  let labels = [
    "plain", "a <b>bold</b> one", "two<br>lines", "a $$x^2$$ b", "fa:fa-x icon",
    "$$fill$$",
  ]
  let attrs = ["", " class=\"pele-label\"", " font-weight=\"var(--_hw)\""]
  let declarations = [
    [],
    ["color:red"],
    ["fill:#123", "color:a&b"],
    ["stroke:x", "opacity:0.5", "font-style:italic"],
    ["fill:none", "stroke:\"q\""],
  ]
  let icons : @types.IconResolver = name => {
    if name == "fa:fa-x" {
      Some("<path/>")
    } else {
      None
    }
  }
  for raw in labels {
    let label = styled_label(raw)
    for a in attrs {
      for list in declarations {
        let style = @svg.resolve_style(list)
        let css = @svg.resolve_raw_style(list)
        assert_eq(
          written(out => {
            @svg.write_label_styled(out, label, 3, 4, a, css.text, icons~)
          }),
          @svg.label_svg(label, 3, 4, a + style.text, icons~),
        )
        assert_eq(
          written(out => {
            @svg.write_label_with_id(
              out,
              label,
              3,
              4,
              a + " data-id=\"",
              "x&amp;<y>",
              "\"",
              css.text,
              icons~,
            )
          }),
          @svg.label_svg(
            label,
            3,
            4,
            a + " data-id=\"\{@svg.esc_text("x&amp;<y>")}\"" + style.text,
            icons~,
          ),
        )
      }
    }
  }
}

///|
/// `raw` laid out at 16 under math that typesets `x^2`.
fn label_of(raw : String) -> @text.Label {
  let math = (tex : String, _ : Double) => {
    match tex {
      "x^2" => Some(({ "svg": "<path/>", "width": 20, "height": 12 } : Json))
      _ => None
    }
  }
  @text.with_math(Some(math), () => {
    @text.layout_label(Some(raw), false, @text.metrics_measurer, 16, 200)
  })
}

///|
let id_samples : Array[String] = [
  "a", "", "a&b<c>\"d\u{1}", "#38;", "x font-weight=", "x font-style=", "x font-weight=\u{1}\u{2}",
  "font-weight=", " font-weight=x", "x fill=", "x style=", "var(--_w)",
]

///|
let label_samples : Array[String] = [
  "plain", "", "<b>bold</b>", "<i>it</i> and <b>b</b>", "one<br>two", "fa:fa-x a",
  "$$x^2$$ c", "a & b",
]

///|
test "an edge label is written with its id as write_edge_label writes it" {
  for raw in label_samples {
    let label = label_of(raw)
    for id in id_samples {
      let want = @svg.Markup::new()
      @svg.write_edge_label(want, id, label, 10, 20, " fill=\"red\"")
      let got = @svg.Markup::new()
      @svg.write_edge_label_with_id(got, id, label, 10, 20, " fill=\"red\"")
      assert_eq(got.to_string(), want.to_string())
    }
  }
}

///|
let attrs_samples : Array[String] = [
  "", " class=\"pele-section-label\"", " font-weight=\"bold\"", " fill=\"none\" stroke=\"red\"",
  " style=\"fill:red;opacity:0.5\"",
]

///|
test "a label with an id is written as write_label writes it with the id among its attributes" {
  let icons = (name : String) => {
    if name == "fa:fa-x" {
      Some("<path/>")
    } else {
      None
    }
  }
  for raw in label_samples {
    let label = label_of(raw)
    for attrs in attrs_samples {
      for after in ["\"", "\" fill=\"var(--_m)\"", "\" font-style=\"italic\""] {
        for id in id_samples {
          let want = @svg.Markup::new()
          @svg.write_label(
            want,
            label,
            10,
            20,
            attrs + " data-id=\"\{@svg.esc_text(id)}" + after,
            icons~,
          )
          let got = @svg.Markup::new()
          @svg.write_label_with_id(
            got,
            label,
            10,
            20,
            attrs + " data-id=\"",
            id,
            after,
            "",
            icons~,
          )
          assert_eq(got.to_string(), want.to_string())
        }
      }
    }
  }
}

///|
test "an id naming an alias puts the alias in the root's style as write_label does" {
  let label = label_of("<b>bold</b>")
  let document = (content : @svg.Markup) => {
    @svg.markup_document(
      "flowchart",
      10,
      10,
      16,
      @types.RenderOptions::default(),
      None,
      None,
      content,
    )
  }
  let want = @svg.Markup::new()
  @svg.write_label(want, label, 0, 0, " data-id=\"var(--_hw)\"")
  let got = @svg.Markup::new()
  @svg.write_label_with_id(
    got, label, 0, 0, " data-id=\"", "var(--_hw)", "\"", "",
  )
  assert_eq(document(got), document(want))
  assert_true(document(got).contains("--_hw:"))
}

///|
test "a styled edge label is written as write_edge_label writes it under the escaped style" {
  let declarations = [
    [],
    ["color:red"],
    ["fill:#123", "color:a&b"],
    ["stroke:x", "opacity:0.5", "font-style:italic"],
  ]
  for raw in label_samples {
    let label = label_of(raw)
    for list in declarations {
      let want = @svg.Markup::new()
      @svg.write_edge_label(
        want,
        "e&1",
        label,
        3,
        4,
        " fill=\"var(--_m)\"" + @svg.resolve_style(list).text,
      )
      let got = @svg.Markup::new()
      @svg.write_edge_label_with_id(
        got,
        "e&1",
        label,
        3,
        4,
        " fill=\"var(--_m)\"",
        css=@svg.resolve_raw_style(list).text,
      )
      assert_eq(got.to_string(), want.to_string())
    }
  }
}
