///|
/// Runs `run` with `icons` as the host's icon resolver for the labels it lays out.
pub fn[T] with_icons(
  icons : ((String) -> String?)?,
  run : () -> T raise?,
) -> T raise? {
  ignore(icons)
  run()
}
