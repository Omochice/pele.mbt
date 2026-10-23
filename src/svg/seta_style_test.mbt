///|
test "style_contains finds in the raw CSS what searching the escaped attribute finds" {
  let declarations = [
    ["fill:red"],
    ["stroke:red", "fill:blue"],
    ["stroke:a&fill:b"],
    ["stroke:a<fill:b"],
    ["stroke:a\"fill:b"],
    ["stroke:a\u{1}fill:b"],
    ["stroke:x;", "fill:y"],
    ["color:red"],
    [],
  ]
  for list in declarations {
    let escaped = @svg.resolve_style(list)
    let raw = @svg.resolve_raw_style(list)
    for needle in ["\"fill:", ";fill:", "fill", "&amp;", " style=\"", ""] {
      assert_eq(
        @svg.style_contains(raw.shape, needle),
        escaped.shape.contains(needle),
      )
      assert_eq(
        @svg.style_contains(raw.text, needle),
        escaped.text.contains(needle),
      )
    }
  }
}

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
test "the styled shapes and markers write what the string ones write under the escaped style" {
  let declarations = [[], ["fill:a&b", "stroke:c"], ["stroke:x", "rx:3"]]
  for list in declarations {
    let style = @svg.resolve_style(list)
    let css = @svg.resolve_raw_style(list)
    for shape in ["rect", "rounded", "cyl", "person", "diamond", "circle"] {
      assert_eq(
        written(out => {
          @svg.write_shape_styled(
            out,
            shape,
            40,
            30,
            " fill=\"var(--_s)\"",
            css.shape,
            " stroke=\"x\"",
            css.line,
          )
        }),
        @svg.draw_shape(
          shape,
          40,
          30,
          " fill=\"var(--_s)\"" + style.shape,
          " stroke=\"x\"" + style.line,
        ),
      )
    }
    assert_eq(
      written(out => @svg.write_rounded_style(out, css.shape)),
      @svg.rounded(style.shape),
    )
    assert_eq(written(out => @svg.write_style(out, css.text)), style.text)
  }
  for kind in ["arrow_point", "arrow_circle", "arrow_cross", "none"] {
    assert_eq(
      written(out => @svg.write_marker_esc(out, kind, 1, 2, 0, 1, "a&\"b")),
      @svg.marker(kind, 1, 2, 0, 1, @svg.esc("a&\"b")),
    )
  }
}
