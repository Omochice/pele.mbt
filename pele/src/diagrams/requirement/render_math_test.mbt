///|
/// The viewBox and the content of the diagram drawn with a typesetter that knows `tall` and `x`.
fn math_requirement(source : String) -> (String, String) {
  let math = (tex : String, size : Double) => {
    match (tex, size) {
      ("tall", _) =>
        Some(({ "svg": "<path/>", "width": 20, "height": 40 } : Json))
      ("x", 14) => Some({ "html": "x", "width": 9, "height": 8 })
      _ => None
    }
  }
  let options = { ..@types.RenderOptions::default(), math: Some(math), }
  let svg = (@core.render([@requirement.requirement], source, options) catch {
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
test "field lines with math are centered on their own heights" {
  let (view_box, body) = math_requirement(
    "requirementDiagram\n  requirement \"N $$tall$$\" {\n    id: \"$$x$$\"\n    text: \"a $$tall$$ b<br>two\"\n  }",
  )
  inspect(
    view_box,
    content=(
      #|0 0 141 206
    ),
  )
  inspect(
    body,
    content=(
      #|<g class="pele-nodes"><g class="pele-node pele-requirement" data-id="N $$tall$$" transform="translate(70.19,103)"><rect x="-62.19" y="-95" width="124.38" height="190" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><text class="pele-stereotype" font-size="14" fill="var(--_m)" x="0" y="-69.6" text-anchor="middle">«Requirement»</text><text class="pele-label" font-size="16" font-weight="var(--_hw)" text-anchor="middle" xml:space="preserve"><tspan x="-18" y="-36.4" text-anchor="start">N </tspan></text><svg class="pele-math" x="-2" y="-62" width="20" height="40" overflow="visible"><path/></svg><path class="pele-divider" d="M-62.19,-10H62.19" stroke="var(--_b)"/><g class="pele-fields" font-size="14"><text class="pele-field" fill="var(--_m)" text-anchor="start" xml:space="preserve"><tspan x="-48.19" y="15.4">ID</tspan></text><text class="pele-value" text-anchor="middle" xml:space="preserve"></text><foreignObject class="pele-math" x="-8.96" y="6.5" width="9" height="8" overflow="visible"><div xmlns="http://www.w3.org/1999/xhtml" style="display:flex;align-items:center;justify-content:center;width:100%;height:100%;font-size:14px;line-height:normal;white-space:nowrap">x</div></foreignObject><text class="pele-field" fill="var(--_m)" text-anchor="start" xml:space="preserve"><tspan x="-48.19" y="38.4">Text</tspan></text><text class="pele-value" text-anchor="start" xml:space="preserve"><tspan x="-8.96" y="80.9">two</tspan></text><text class="pele-value" text-anchor="middle" xml:space="preserve"><tspan x="-8.96" y="49.9" text-anchor="start">a </tspan><tspan x="22.72" y="49.9" text-anchor="start"> b</tspan></text><svg class="pele-math" x="2.72" y="25" width="20" height="40" overflow="visible"><path/></svg></g></g></g>
    ),
  )
}
