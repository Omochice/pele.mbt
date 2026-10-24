///|
test "a radius alone in the style becomes an attribute" {
  inspect(
    @typst.hoist_radii(
      (
        #|<svg><rect x="0" style="rx:4px"/></svg>
      ),
    ),
    content=(
      #|<svg><rect x="0" rx="4px"/></svg>
    ),
  )
}

///|
test "a radius leaves the style's other declarations in place" {
  inspect(
    @typst.hoist_radii(
      (
        #|<svg><rect style="rx:4px;fill:red" stroke="blue"/></svg>
      ),
    ),
    content=(
      #|<svg><rect rx="4px" style="fill:red" stroke="blue"/></svg>
    ),
  )
}

///|
test "the style's radius wins over an attribute, as CSS does" {
  inspect(
    @typst.hoist_radii(
      (
        #|<svg><rect rx="2" width="5" style="rx:6px"/></svg>
      ),
    ),
    content=(
      #|<svg><rect rx="6px" width="5"/></svg>
    ),
  )
}

///|
test "the last radius in the style wins" {
  inspect(
    @typst.hoist_radii(
      (
        #|<svg><rect style="rx:4px;fill:red;rx:10"/><ellipse style="ry: 3 ;rx:2"/></svg>
      ),
    ),
    content=(
      #|<svg><rect rx="10" style="fill:red"/><ellipse ry="3" rx="2"/></svg>
    ),
  )
}

///|
test "styles without a radius and text are left alone" {
  let svg =
    #|<svg><text style="fill:red" data-id="rx:1">rx:1</text></svg>
  inspect(@typst.hoist_radii(svg), content=svg)
}
