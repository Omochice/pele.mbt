///|
/// The host's icons for the render in progress.
/// A label leaves room for an icon only when the host has one by that name, and layout has to
/// know that before anything is drawn, so it is set around a render rather than passed down.
let icon_resolver : Ref[((String) -> String?)?] = { val: None, }

///|
/// Runs `run` with `icons` as the host's icon resolver for the labels it lays out.
pub fn[T] with_icons(
  icons : ((String) -> String?)?,
  run : () -> T raise?,
) -> T raise? {
  let outer = icon_resolver.val
  icon_resolver.val = icons
  defer {
    icon_resolver.val = outer
  }
  run()
}

///|
/// The drawing the host has for the icon `name`, empty when it has none or no resolver is set.
pub fn icon_markup(name : String) -> String {
  // pele caches each answer for the render; a resolver here only reads data, so asking again is as good.
  match icon_resolver.val {
    Some(resolve) => resolve(name).unwrap_or("")
    None => ""
  }
}
