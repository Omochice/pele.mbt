///|
fn drawn(
  source : String,
  max_width? : Double,
  padding? : Double,
) -> @types.RenderResult {
  let options = { ..@types.RenderOptions::default(), max_width, padding, }
  @core.render([@treemap.treemap], source, options) catch {
    @errors.PeleError(_) => panic()
  }
}

///|
fn svg(source : String, max_width? : Double) -> String {
  let options = { ..@types.RenderOptions::default(), max_width, }
  let result = @core.render([@treemap.treemap], source, options) catch {
    @errors.PeleError(failure) => return failure.message
  }
  "\{result.width}x\{result.height} \{result.svg}"
}

///|
/// The text between `before` and the next `"`, searched from `from`.
fn quoted_after(svg : String, before : String, from~ : Int32 = 0) -> String {
  let at = @util.index_of(svg, before, from~)
  if at < 0 {
    return ""
  }
  let start = at + before.length()
  @util.slice(svg, start, end=@util.index_of(svg, "\"", from=start))
}

///|
/// The box drawn for the node named `id`, as `x y width height`.
fn box_of(svg : String, id : String) -> (Double, Double, Double, Double) {
  let at = @util.index_of(svg, "data-id=\"\{id}\"><rect ")
  let number = key => @util.parse_float(quoted_after(svg, "\{key}=\"", from=at))
  (number("x"), number("y"), number("width"), number("height"))
}

///|
fn count(text : String, part : String) -> Int32 {
  let mut n = 0
  let mut from = 0
  while true {
    let at = @util.index_of(text, part, from~)
    if at < 0 {
      break
    }
    n += 1
    from = at + part.length()
  }
  n
}
