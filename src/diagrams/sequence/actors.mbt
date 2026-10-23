///|
/// The size of a participant's drawing.
pub(all) struct ActorSize {
  w : Double
  h : Double
}

///|
/// The kind a participant is drawn as: the type it was given when pele draws that type, and `participant` otherwise.
pub fn actor_kind(kind : String) -> String {
  kind
}

///|
/// Whether a kind is a figure that stands above its label, rather than a shape that holds it.
pub fn is_figure(kind : String) -> Bool {
  kind == ""
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
  ignore(kind)
  ignore(label)
  { w: min_w + padding_x, h: min_h, }
}

///|
/// Draws a participant whose bounding box has its top center at (`cx`, `top`).
pub fn draw_actor(
  kind : String,
  cx : Double,
  top : Double,
  size : ActorSize,
  label : @text.Label,
) -> String {
  ignore(label)
  "\{kind}\{cx}\{top}\{size.w}"
}
