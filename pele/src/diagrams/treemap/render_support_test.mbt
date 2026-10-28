///|
fn drawn(
  source : String,
  max_width? : Double,
  padding? : Double,
  font_size? : Double,
) -> @types.RenderResult {
  let options = {
    ..@types.RenderOptions::default(),
    max_width,
    padding,
    font_size,
  }
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
  let at = rect_at(svg, id)
  let number = key => @util.parse_float(quoted_after(svg, "\{key}=\"", from=at))
  (number("x"), number("y"), number("width"), number("height"))
}

///|
/// Where the rect drawn for the node named `id` starts, past any tooltip ahead of it.
fn rect_at(svg : String, id : String) -> Int32 {
  @util.index_of(svg, "<rect ", from=@util.index_of(svg, "data-id=\"\{id}\">"))
}

///|
/// The contents of the text elements in `markup`.
fn texts_in(markup : String) -> Array[String] {
  let texts = []
  let mut from = 0
  while true {
    let at = @util.index_of(markup, "<text", from~)
    if at < 0 {
      break
    }
    let start = @util.index_of(markup, ">", from=at) + 1
    let end = @util.index_of(markup, "</text>", from=start)
    texts.push(@util.slice(markup, start, end~))
    from = end
  }
  texts
}

///|
/// A box drawn for a node, by the node's name.
struct Drawn {
  id : String
  x : Double
  y : Double
  w : Double
  h : Double
}

///|
/// Every box drawn, in the order it is drawn.
fn drawn_boxes(svg : String) -> Array[Drawn] {
  let boxes = []
  let mut from = 0
  while true {
    let at = @util.index_of(svg, "data-id=\"", from~)
    if at < 0 {
      break
    }
    let id = quoted_after(svg, "data-id=\"", from=at)
    let (x, y, w, h) = box_of(svg, id)
    boxes.push({ id, x, y, w, h, })
    from = at + 1
  }
  boxes
}

///|
/// The narrowest space between two boxes side by side or one above the other, or infinity.
/// Boxes too thin to keep a gap are left out.
fn smallest_gap(boxes : Array[Drawn]) -> Double {
  let mut least = @double.infinity
  for a in boxes {
    for b in boxes {
      if @util.js_min(@util.js_min(a.w, a.h), @util.js_min(b.w, b.h)) < 8 {
        continue
      }
      if a.y < b.y + b.h && b.y < a.y + a.h && b.x >= a.x + a.w {
        least = @util.js_min(least, b.x - a.x - a.w)
      }
      if a.x < b.x + b.w && b.x < a.x + a.w && b.y >= a.y + a.h {
        least = @util.js_min(least, b.y - a.y - a.h)
      }
    }
  }
  least
}

///|
/// Six top-level sections, each of eight sections holding one section of eight leaves.
fn deep_tree() -> String {
  let source = StringBuilder()
  source.write_string("treemap\n")
  for i in 0..<6 {
    source.write_string("\"top \{i}\"\n")
    for j in 0..<8 {
      source.write_string("  \"mid \{i}.\{j}\"\n    \"inner \{i}.\{j}\"\n")
      for k in 0..<8 {
        let n = 1 + (i * 64 + j * 8 + k) % 37
        source.write_string("      \"leaf \{i}.\{j}.\{k}\": \{n * n * n}\n")
      }
    }
  }
  source.to_string()
}

///|
let budget : String = "treemap-beta\n\"Budget\"\n    \"Operations\"\n        \"Salaries\": 700000\n        \"Equipment\": 200000\n        \"Supplies\": 100000\n    \"Marketing\"\n        \"Advertising\": 400000\n        \"Events\": 100000"

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
