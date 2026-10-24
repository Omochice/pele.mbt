///|
/// Draws a chart whose plot can be any width so that the whole diagram fits the width the host
/// has. What surrounds the plot (labels, a legend) is only known once it is drawn, so the plot
/// gives up the overflow and is drawn again. `draw` is told whether the chart did not fit at its
/// own width, for a chart that then arranges itself differently.
pub fn fit_width(
  options : @types.RenderOptions,
  natural : Double,
  least : Double,
  draw : (Double, Bool) -> @types.Rendered raise?,
) -> @types.Rendered raise? {
  let mut result = draw(natural, false)
  guard options.max_width is Some(available) &&
    available > 0 &&
    result.width > available else {
    return result
  }
  let floor = if least < natural { least } else { natural }
  let mut plot = natural
  result = draw(plot, true)
  for round = 0
      round < 3 && result.width > available && plot > floor
      round = round + 1 {
    let shrunk = plot - (result.width - available)
    plot = if floor > shrunk { floor } else { shrunk }
    result = draw(plot, true)
  }
  result
}

///|
/// The width a title may take before it wraps.
pub fn title_room(options : @types.RenderOptions) -> Double {
  match options.max_width {
    Some(available) if available > 0 => {
      let room = available - 2 * options.padding.unwrap_or(8)
      if room > 80 {
        room
      } else {
        80
      }
    }
    _ => 4000
  }
}

///|
/// The width of a chart that is drawn to a set width: its own, or the host's when that is smaller.
/// `around` is what the chart adds outside that width, and `least` is how narrow it may be made.
pub fn cap_width(
  options : @types.RenderOptions,
  natural : Double,
  least : Double,
  around~ : Double = 0,
) -> Double {
  match options.max_width {
    Some(available) if available > 0 =>
      @util.js_max(
        @util.js_min(least, natural),
        @util.js_min(natural, available - around),
      )
    _ => natural
  }
}
