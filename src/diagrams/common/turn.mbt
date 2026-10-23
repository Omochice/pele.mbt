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
  let down = draw(true)
  if down.width < across.width {
    down
  } else {
    across
  }
}

///|
/// Whether a flow direction runs across rather than down.
pub fn runs_across(direction : String?) -> Bool {
  direction is Some("LR" | "RL")
}
