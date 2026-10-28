///|
/// The version the diagram prints.
/// pele reads it from package.json at build time, so it must follow the pele release being ported.
const VERSION : String = "1.12.0"

///|
fn render_info(
  model : InfoModel,
  options : @types.RenderOptions,
) -> @types.Rendered raise @errors.PeleError {
  let size = options.font_size.unwrap_or(16)
  let measurer = options.text_measurer()
  let pad = options.padding.unwrap_or(8)
  let title = @text.layout_label(
    model.title,
    false,
    measurer,
    size,
    4000,
    base=@text.STYLE_BOLD,
  )
  let title_height = if title.height > 0 { title.height + 8 } else { 0 }
  let text = @text.layout_label(
    Some("Pele v\{VERSION}"),
    false,
    measurer,
    size,
    4000,
  )
  let width = (@cmp.maximum(title.width, text.width) + 2 * pad).ceil()
  let height = (title_height + text.height + 2 * pad).ceil()
  let content = @svg.Markup::new()
  @svg.write_label(
    content,
    title,
    width / 2,
    pad + title.height / 2,
    " class=\"pele-title\" font-weight=\"var(--_tw)\"",
  )
  @svg.write_label(
    content,
    text,
    width / 2,
    pad + title_height + text.height / 2,
    " class=\"pele-version\" fill=\"var(--_m)\"",
  )
  {
    svg: @svg.markup_document(
      "info",
      width,
      height,
      size,
      options,
      model.acc_title,
      model.acc_descr,
      content,
    ),
    width,
    height,
    links: [],
  }
}
