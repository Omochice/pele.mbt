///|
test "icon_svg draws an empty square named after the icon" {
  inspect(
    @common.icon_svg("fa:fa-car", 10, -2.5, 24),
    content="<svg class=\"pele-icon\" data-icon=\"fa:fa-car\" x=\"10\" y=\"-2.5\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"></svg>",
  )
  inspect(
    @common.icon_svg("a&b<\"c\">'", 0.125, 1.0 / 3, 13.335),
    content="<svg class=\"pele-icon\" data-icon=\"a&amp;b&lt;&quot;c&quot;&gt;'\" x=\"0.13\" y=\"0.33\" width=\"13.34\" height=\"13.34\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"></svg>",
  )
}

///|
test "icon_svg draws what the host has for the icon before its own drawing" {
  let icons = (name : String) => {
    match name {
      "car" => Some("<path id=\"car\"/>")
      "blank" => Some("")
      _ => None
    }
  }
  inspect(
    @common.icon_svg("car", 0, 0, 24, icons~, drawing="<circle/>"),
    content="<svg class=\"pele-icon\" data-icon=\"car\" x=\"0\" y=\"0\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path id=\"car\"/></svg>",
  )
  inspect(
    @common.icon_svg("blank", 0, 0, 24, icons~, drawing="<circle/>"),
    content="<svg class=\"pele-icon\" data-icon=\"blank\" x=\"0\" y=\"0\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"></svg>",
  )
  inspect(
    @common.icon_svg("other", 0, 0, 24, icons~, drawing="<circle/>"),
    content="<svg class=\"pele-icon\" data-icon=\"other\" x=\"0\" y=\"0\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><circle/></svg>",
  )
}

///|
test "icon_svg matches pele over names, positions and sizes" {
  let outputs = []
  let names = [
    "",
    "fa:fa-car",
    "a&b<\"c\">'",
    "mdi:home",
    String::from_array(['\u{1}', 'x', (0xd800).unsafe_to_char()]),
  ]
  for name in names {
    for x in [0.0, -1.5, 12.345, 1.0e21, 0.1 + 0.2] {
      for y in [0.0, 3.005, -7] {
        for side in [0.0, 24, 13.335] {
          outputs.push(@common.icon_svg(name, x, y, side))
        }
      }
    }
  }
  assert_eq(outputs.length(), 225)
  assert_eq(fnv1a(outputs.join("\n")), "772371a2")
}
