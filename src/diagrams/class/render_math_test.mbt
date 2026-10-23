///|
/// The viewBox and the content of the diagram drawn with a typesetter that knows `tall` and `x`.
fn math_class(source : String) -> (String, String) {
  let math = (tex : String, _ : Double) => {
    match tex {
      "tall" => Some(({ "svg": "<path/>", "width": 20, "height": 40 } : Json))
      "x" => Some({ "html": "x", "width": 9, "height": 8 })
      _ => None
    }
  }
  let options = { ..@types.RenderOptions::default(), math: Some(math), }
  let svg = (@core.render([@class.class], source, options) catch {
      @errors.PeleError(failure) => abort(failure.message)
    }).svg
  let view_box = @util.index_of(svg, "viewBox=\"") + 9
  let open = @util.index_of(
    svg,
    ">",
    from=@util.index_of(svg, "aria-roledescription"),
  )
  (
    @util.slice(svg, view_box, end=@util.index_of(svg, "\"", from=view_box)),
    @util.slice(svg, open + 1, end=svg.length() - 6),
  )
}

///|
test "annotations and cardinalities with math are laid out as labels" {
  let (view_box, body) = math_class(
    "classDiagram\n  class A {\n    <<$$tall$$>>\n  }\n  A \"$$tall$$\" --> \"1 $$x$$\" B",
  )
  inspect(view_box, content="0 0 80 280")
  inspect(
    body,
    content="<g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-relation\" data-id=\"id_A_B_1\"><path d=\"M40,112L40,205\"/><path class=\"pele-marker\" d=\"M40,212L36.64,204L43.36,204Z\" fill=\"var(--_l)\" stroke=\"none\"/></g></g><g class=\"pele-cardinalities\" font-size=\"13\" fill=\"var(--_m)\"><text class=\"pele-cardinality\" text-anchor=\"middle\" xml:space=\"preserve\"></text><svg class=\"pele-math\" x=\"49\" y=\"117\" width=\"20\" height=\"40\" overflow=\"visible\"><path/></svg><text class=\"pele-cardinality\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"49\" y=\"203.55\" text-anchor=\"start\">1 </tspan></text><foreignObject class=\"pele-math\" x=\"59.84\" y=\"195\" width=\"9\" height=\"8\" overflow=\"visible\"><div xmlns=\"http://www.w3.org/1999/xhtml\" style=\"display:flex;align-items:center;justify-content:center;width:100%;height:100%;font-size:13px;line-height:normal;white-space:nowrap\">x</div></foreignObject></g><g class=\"pele-nodes\"><g class=\"pele-node pele-class\" data-id=\"A\" transform=\"translate(40,60)\"><rect x=\"-32\" y=\"-52\" width=\"64\" height=\"104\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><path class=\"pele-divider\" d=\"M-32,32H32M-32,42H32\" fill=\"none\" stroke=\"var(--_b)\"/><text class=\"pele-annotation\" font-size=\"13\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"-17.54\" y=\"-17.45\" text-anchor=\"start\">«</tspan><tspan x=\"10\" y=\"-17.45\" text-anchor=\"start\">»</tspan></text><svg class=\"pele-math\" x=\"-10\" y=\"-42\" width=\"20\" height=\"40\" overflow=\"visible\" color=\"var(--_m)\"><path/></svg><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"17.6\">A</tspan></text></g><g class=\"pele-node pele-class\" data-id=\"B\" transform=\"translate(40,242)\"><rect x=\"-32\" y=\"-30\" width=\"64\" height=\"60\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><path class=\"pele-divider\" d=\"M-32,10H32M-32,20H32\" fill=\"none\" stroke=\"var(--_b)\"/><text class=\"pele-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"0\" y=\"-4.4\">B</tspan></text></g></g>",
  )
}
