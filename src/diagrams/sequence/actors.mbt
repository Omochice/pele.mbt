///|
const PAD_Y : Double = 10

///|
const GLYPH : Double = 34

///|
const GLYPH_GAP : Double = 4

///|
const STACK : Double = 5

///|
const CAP : Double = 6

///|
const SHAPE : String = " fill=\"var(--_s)\" stroke=\"var(--_b)\""

///|
const STROKE : String = " fill=\"none\" stroke=\"var(--_b)\""

///|
/// The size of a participant's drawing.
pub(all) struct ActorSize {
  w : Double
  h : Double
}

///|
/// The kind a participant is drawn as: the type it was given when pele draws that type, and `participant` otherwise.
pub fn actor_kind(kind : String) -> String {
  match kind {
    "participant"
    | "actor"
    | "boundary"
    | "control"
    | "entity"
    | "database"
    | "collections"
    | "queue" => kind
    _ => "participant"
  }
}

///|
/// Whether a kind is a figure that stands above its label, rather than a shape that holds it.
pub fn is_figure(kind : String) -> Bool {
  kind is ("actor" | "boundary" | "control" | "entity" | "database")
}

///|
/// The size of a participant of `kind` labelled `label`, at least `min_w` by `min_h` when it holds its label.
pub fn actor_size(
  kind : String,
  label : @text.Label,
  min_w : Double,
  min_h : Double,
  padding_x~ : Double = 16,
) -> ActorSize {
  if is_figure(kind) {
    return {
      w: @util.js_max(40, label.width + 8),
      h: GLYPH + (if label.height > 0 { GLYPH_GAP + label.height } else { 0 }),
    }
  }
  let extra = match kind {
    "collections" => STACK
    "queue" => 2 * CAP
    _ => 0
  }
  {
    w: @util.js_max(min_w, label.width + 2 * padding_x) + extra,
    h: @util.js_max(min_h, label.height + 2 * PAD_Y) +
    (if kind == "collections" { STACK } else { 0 }),
  }
}

///|
fn figure(kind : String, cx : Double, top : Double) -> String {
  let x = @svg.num(cx)
  let y = (dy : Double) => @svg.num(top + dy)
  let n = @svg.num
  match kind {
    "actor" =>
      "<circle cx=\"\{x}\" cy=\"\{y(7)}\" r=\"6\"\{SHAPE}/>" +
      "<path d=\"M\{x},\{y(13)}V\{y(24)}M\{n(cx - 10)},\{y(17)}H\{n(cx + 10)}M\{n(cx - 8)},\{y(34)}L\{x},\{y(24)}L\{n(cx + 8)},\{y(34)}\"\{STROKE}/>"
    "boundary" =>
      "<path d=\"M\{n(cx - 19)},\{y(6)}V\{y(28)}M\{n(cx - 19)},\{y(17)}H\{n(cx - 8)}\"\{STROKE}/>" +
      "<circle cx=\"\{n(cx + 3)}\" cy=\"\{y(17)}\" r=\"11\"\{SHAPE}/>"
    "control" =>
      "<circle cx=\"\{x}\" cy=\"\{y(21)}\" r=\"11\"\{SHAPE}/>" +
      "<path d=\"M\{n(cx + 5)},\{y(5)}L\{n(cx - 1)},\{y(10)}L\{n(cx + 5)},\{y(15)}\"\{STROKE}/>"
    "entity" =>
      "<circle cx=\"\{x}\" cy=\"\{y(15)}\" r=\"11\"\{SHAPE}/>" +
      "<path d=\"M\{n(cx - 11)},\{y(30)}H\{n(cx + 11)}\"\{STROKE}/>"
    _ => {
      let l = n(cx - 14)
      let r = n(cx + 14)
      "<path d=\"M\{l},\{y(7)}V\{y(27)}A14,5 0 0 0 \{r},\{y(27)}V\{y(7)}A14,5 0 0 0 \{l},\{y(7)}Z\"\{SHAPE}/>" +
      "<path d=\"M\{l},\{y(7)}A14,5 0 0 0 \{r},\{y(7)}\"\{STROKE}/>"
    }
  }
}

///|
/// Draws a participant whose bounding box has its top center at (`cx`, `top`), with `icons` drawing the icons in its label.
/// Aborts where the drawing would be longer than V8 allows, which `write_actor` reports instead.
pub fn draw_actor(
  kind : String,
  cx : Double,
  top : Double,
  size : ActorSize,
  label : @text.Label,
  icons? : @types.IconResolver,
) -> String {
  let out = @svg.Markup::new()
  write_actor(out, kind, cx, top, size, label, icons?) catch {
    _ => abort("participant markup longer than V8's longest string")
  }
  out.to_string()
}

///|
/// Writes a participant to `out` as `draw_actor` draws it, with its label written piece by piece.
/// Raises pele's `limit` error when the markup would be longer than V8 allows.
pub fn write_actor(
  out : @svg.Markup,
  kind : String,
  cx : Double,
  top : Double,
  size : ActorSize,
  label : @text.Label,
  icons? : @types.IconResolver,
) -> Unit raise @errors.PeleError {
  let n = @svg.num
  let { w, h, } = size
  let text = " class=\"pele-label\""
  if is_figure(kind) {
    out.write(figure(kind, cx, top))
    @svg.write_label(
      out,
      label,
      cx,
      top + GLYPH + GLYPH_GAP + label.height / 2,
      text,
      icons?,
    )
    return
  }
  let left = cx - w / 2
  if kind == "collections" {
    let bw = w - STACK
    let bh = h - STACK
    out.write(
      "<rect x=\"\{n(left + STACK)}\" y=\"\{n(top)}\" width=\"\{n(bw)}\" height=\"\{n(bh)}\"\{SHAPE}\{@svg.ROUNDED}/>" +
      "<rect x=\"\{n(left)}\" y=\"\{n(top + STACK)}\" width=\"\{n(bw)}\" height=\"\{n(bh)}\"\{SHAPE}\{@svg.ROUNDED}/>",
    )
    @svg.write_label(
      out,
      label,
      left + bw / 2,
      top + STACK + bh / 2,
      text,
      icons?,
    )
    return
  }
  if kind == "queue" {
    let l = n(left + CAP)
    let r = n(left + w - CAP)
    let b = n(top + h)
    let ry = n(h / 2)
    out.write(
      "<path d=\"M\{l},\{n(top)}H\{r}A\{CAP},\{ry} 0 0 1 \{r},\{b}H\{l}A\{CAP},\{ry} 0 0 1 \{l},\{n(top)}Z\"\{SHAPE}/>" +
      "<path d=\"M\{r},\{n(top)}A\{CAP},\{ry} 0 0 0 \{r},\{b}\"\{STROKE}/>",
    )
    @svg.write_label(out, label, cx - CAP / 2, top + h / 2, text, icons?)
    return
  }
  out.write(
    "<rect x=\"\{n(left)}\" y=\"\{n(top)}\" width=\"\{n(w)}\" height=\"\{n(h)}\"\{SHAPE}\{@svg.ROUNDED}/>",
  )
  @svg.write_label(out, label, cx, top + h / 2, text, icons?)
}
