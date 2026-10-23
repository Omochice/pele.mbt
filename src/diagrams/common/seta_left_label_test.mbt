///|
fn left_written(
  write : (@svg.Markup) -> Unit raise @errors.PeleError,
) -> String {
  let out = @svg.Markup::new()
  write(out) catch {
    _ => abort("unreachable")
  }
  out.to_string()
}

///|
test "a styled left label writes what write_left_label writes under the escaped style" {
  for raw in ["plain", "a <b>bold</b> one", "two<br>lines", "fa:fa-x icon"] {
    let label = @text.layout_label(
      Some(raw),
      false,
      @text.metrics_measurer,
      16,
      4000,
    )
    for
      attrs in ["", " class=\"pele-cluster-label\" font-weight=\"var(--_hw)\""] {
      for list in [[], ["color:a&b"], ["font-style:italic", "color:red"]] {
        assert_eq(
          left_written(out => {
            @common.write_left_label_styled(
              out,
              label,
              2,
              3,
              attrs,
              @svg.resolve_raw_style(list).text,
            )
          }),
          left_written(out => {
            @common.write_left_label(
              out,
              label,
              2,
              3,
              attrs + @svg.resolve_style(list).text,
            )
          }),
        )
      }
    }
  }
}
