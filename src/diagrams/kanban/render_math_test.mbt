///|
/// The viewBox and the content of the board drawn with a typesetter that knows `wide` and `tall`.
fn math_board(source : String) -> (String, String) {
  let math = (tex : String, size : Double) => {
    match (tex, size) {
      ("wide", 16) =>
        Some(({ "svg": "<g/>", "width": 300, "height": 10 } : Json))
      ("wide", 14) => Some({ "svg": "<g/>", "width": 250, "height": 10 })
      ("tall", _) => Some({ "svg": "<path/>", "width": 20, "height": 40 })
      _ => None
    }
  }
  let options = { ..@types.RenderOptions::default(), math: Some(math), }
  let svg = (@core.render([@kanban.kanban], source, options) catch {
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
test "columns widen for math and lines with math are placed by their heights" {
  let (view_box, body) = math_board(
    "kanban\n  todo[\"$$wide$$ $$tall$$\"]\n    t1[\"a $$tall$$<br>b\"]\n    t2[\"x\"]@{ ticket: \"$$tall$$\", assigned: \"$$wide$$\" }",
  )
  inspect(view_box, content="0 0 360 290")
  inspect(
    body,
    content="<g class=\"pele-cluster pele-column\" data-id=\"todo\" transform=\"translate(8,8)\"><rect width=\"344\" height=\"274\" fill=\"var(--_s)\" style=\"rx:var(--_r)\"/><text class=\"pele-cluster-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"></text><svg class=\"pele-math\" x=\"12\" y=\"15\" width=\"300\" height=\"10\" overflow=\"visible\"><g/></svg><text class=\"pele-cluster-label\" font-weight=\"var(--_hw)\" text-anchor=\"middle\" xml:space=\"preserve\"></text><svg class=\"pele-math\" x=\"12\" y=\"34\" width=\"20\" height=\"40\" overflow=\"visible\"><path/></svg><text class=\"pele-count\" x=\"332\" y=\"24.9\" text-anchor=\"end\" font-size=\"14\" fill=\"var(--_m)\">2</text><g class=\"pele-node pele-card\" data-id=\"t1\" transform=\"translate(8,84)\" font-size=\"14\"><rect width=\"328\" height=\"85\" fill=\"var(--_bg)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" text-anchor=\"middle\" xml:space=\"preserve\"><tspan x=\"10\" y=\"36.9\" text-anchor=\"start\">a </tspan></text><svg class=\"pele-math\" x=\"21.68\" y=\"12\" width=\"20\" height=\"40\" overflow=\"visible\"><path/></svg><text class=\"pele-label\" x=\"10\" y=\"69.4\">b</text></g><g class=\"pele-node pele-card\" data-id=\"t2\" transform=\"translate(8,177)\" font-size=\"14\"><rect width=\"328\" height=\"89\" fill=\"var(--_bg)\" stroke=\"var(--_b)\" style=\"rx:var(--_r)\"/><text class=\"pele-label\" x=\"10\" y=\"25.4\">x</text><text class=\"pele-ticket\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"></text><svg class=\"pele-math\" x=\"10\" y=\"37\" width=\"20\" height=\"40\" overflow=\"visible\" color=\"var(--_m)\"><path/></svg><text class=\"pele-assigned\" fill=\"var(--_m)\" text-anchor=\"middle\" xml:space=\"preserve\"></text><svg class=\"pele-math\" x=\"68\" y=\"63.5\" width=\"250\" height=\"10\" overflow=\"visible\" color=\"var(--_m)\"><g/></svg></g></g>",
  )
}
