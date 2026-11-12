///|
const BREAKPOINT : Double = 640

///|
/// Draws a diagram that can run across or down: across, and down instead when the host allows it,
/// the width it has is under the breakpoint, across does not fit, and down is narrower.
pub fn turn_to_fit(
  options : @types.RenderOptions,
  draw : (Bool) -> @types.Rendered raise?,
) -> @types.Rendered raise? {
  let across = draw(false)
  guard options.auto_direction != Some(false) &&
    options.max_width is Some(available) &&
    available > 0 &&
    across.width > available else {
    return across
  }
  let breakpoint = match options.direction_breakpoint {
    Some(b) if b > 0 => b
    _ => BREAKPOINT
  }
  if available >= breakpoint {
    return across
  }
  // The drawing across is not held while the one down is drawn, but drawn again when it is the one kept.
  // Held, it stands beside the pieces of the drawing down and the string made of them, which outgrows wasm's memory for a drawing near the hold limit.
  let across_width = across.width
  let down = draw(true)
  if down.width < across_width {
    down
  } else {
    draw(false)
  }
}

///|
/// Whether a flow direction runs across rather than down.
pub fn runs_across(direction : String?) -> Bool {
  direction is Some("LR" | "RL")
}
