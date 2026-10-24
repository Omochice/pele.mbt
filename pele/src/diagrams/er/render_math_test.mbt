///|
/// The viewBox and the content of the diagram drawn with a typesetter that knows `tall` and `x`.
fn math_er(source : String) -> (String, String) {
  let math = (tex : String, _ : Double) => {
    match tex {
      "tall" => Some(({ "svg": "<path/>", "width": 20, "height": 40 } : Json))
      "x" => Some({ "html": "x", "width": 9, "height": 8 })
      _ => None
    }
  }
  let options = { ..@types.RenderOptions::default(), math: Some(math), }
  let svg = (@core.render([@er.er], source, options) catch {
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
test "attribute cells with math draw it next to their text" {
  let (view_box, body) = math_er(
    "erDiagram\n  \"E $$tall$$\" {\n    string a \"c $$x$$ d\"\n  }\n  \"E $$tall$$\" ||--o{ B : \"r $$x$$\"",
  )
  inspect(view_box, content="0 0 146 245")
  inspect(
    body,
    content="<g class=\"pele-edges\" fill=\"none\" stroke=\"var(--_l)\" stroke-linecap=\"round\"><g class=\"pele-edge pele-er-identifying\" data-id=\"id_entity-E $$tall$$-0_entity-B-1_0\"><path d=\"M72.79,100L72.79,189\"/><path class=\"pele-marker\" d=\"M67.79,106L77.79,106M67.79,110L77.79,110\"/><path class=\"pele-marker\" d=\"M78.79,189L72.79,179L66.79,189\"/><circle class=\"pele-marker\" cx=\"72.79\" cy=\"175\" r=\"3.5\" fill=\"var(--_bg)\"/></g></g><g class=\"pele-edge-labels\" font-size=\"14\"><g class=\"pele-edge-label\" data-id=\"id_entity-E $$tall$$-0_entity-B-1_0\"><rect x=\"60.01\" y=\"134\" width=\"25.55\" height=\"21\" rx=\"3\" fill=\"var(--_bg)\"/><text text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"64.01\" y=\"149.4\" text-anchor=\"start\">r </tspan></text><foreignObject class=\"pele-math\" x=\"72.57\" y=\"140.5\" width=\"9\" height=\"8\" overflow=\"visible\"><div xmlns=\"http://www.w3.org/1999/xhtml\" style=\"display:flex;align-items:center;justify-content:center;width:100%;height:100%;font-size:14px;line-height:normal;white-space:nowrap\">x</div></foreignObject></g></g><g class=\"pele-nodes\"><g class=\"pele-node pele-entity\" data-id=\"E $$tall$$\" transform=\"translate(72.79,54)\"><rect x=\"-64.79\" y=\"-46\" width=\"129.58\" height=\"92\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><g class=\"pele-er-stripes\" fill=\"var(--_bg)\"><rect x=\"-64.79\" width=\"129.58\" y=\"16\" height=\"30\" style=\"rx:var(--_r)\"/><rect x=\"-64.79\" width=\"129.58\" y=\"16\" height=\"15\"/></g><path class=\"pele-er-divider\" d=\"M-64.79,16H64.79\" stroke=\"var(--_b)\"/><rect x=\"-64.79\" y=\"-46\" width=\"129.58\" height=\"92\" fill=\"none\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"-17.56\" y=\"-9.4\" text-anchor=\"start\">E </tspan></text><svg class=\"pele-math\" x=\"-2.44\" y=\"-35\" width=\"20\" height=\"40\" overflow=\"visible\"><path/></svg><g class=\"pele-er-attributes\" font-size=\"14\"><text class=\"pele-er-type\" fill=\"var(--_m)\" x=\"-52.79\" y=\"35.9\">string</text><text class=\"pele-er-name\" x=\"-2.56\" y=\"35.9\">a</text><text class=\"pele-er-comment\" fill=\"var(--_m)\" xml:space=\"preserve\"></text><text class=\"pele-er-comment\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"21.22\" y=\"35.9\" text-anchor=\"start\">c </tspan><tspan x=\"41.11\" y=\"35.9\" text-anchor=\"start\"> d</tspan></text><foreignObject class=\"pele-math\" x=\"32.11\" y=\"27\" width=\"9\" height=\"8\" overflow=\"visible\" color=\"var(--_m)\"><div xmlns=\"http://www.w3.org/1999/xhtml\" style=\"display:flex;align-items:center;justify-content:center;width:100%;height:100%;font-size:14px;line-height:normal;white-space:nowrap\">x</div></foreignObject></g></g><g class=\"pele-node pele-entity\" data-id=\"B\" transform=\"translate(72.79,213)\"><rect x=\"-48\" y=\"-24\" width=\"96\" height=\"48\" fill=\"var(--_s)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"0\" y=\"5.6\" text-anchor=\"middle\">B</text></g></g>",
  )
}
