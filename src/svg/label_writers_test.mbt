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
