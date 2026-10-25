///|
/// The viewBox and the content of the mind map drawn at `max_width` with a typesetter that knows `tall`.
fn math_mindmap(source : String, max_width : Double) -> (String, String) {
  let math = (tex : String, _ : Double) => {
    match tex {
      "tall" => Some(({ "svg": "<path/>", "width": 20, "height": 40 } : Json))
      _ => None
    }
  }
  let options = {
    ..@types.RenderOptions::default(),
    max_width: Some(max_width),
    math: Some(math),
  }
  let svg = (@core.render([@mindmap.mindmap], source, options) catch {
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
test "an outline places each line of a text node by its own height" {
  let (view_box, body) = math_mindmap(
    "mindmap\n  root\n    x $$tall$$<br>y", 150,
  )
  inspect(
    view_box,
    content=(
      #|0 0 96 149
    ),
  )
  inspect(
    body,
    content=(
      #|<g transform="translate(8,8)"><g class="pele-branch pele-section-0"><g class="pele-edges" fill="none" stroke="var(--pele-series-1,#4c78a8)" stroke-width="1.5"><path class="pele-edge" d="M20,48V92.5Q20,100.5 28,100.5H28"/></g><g class="pele-node pele-shape-text" data-id="x $$tall$$&lt;br&gt;y" transform="translate(50.22,100.5)"><text class="pele-label" text-anchor="middle" xml:space="preserve"><tspan x="-16.22" y="-4.9" text-anchor="start">x </tspan></text><svg class="pele-math" x="-3.78" y="-30.5" width="20" height="40" overflow="visible"><path/></svg><text class="pele-label" x="-12.22" y="27.6" text-anchor="middle">y</text></g></g><g class="pele-node pele-shape-stadium pele-root" data-id="root" transform="translate(39.78,24)"><rect x="-39.78" y="-24" width="79.57" height="48" rx="24" fill="var(--_s)" stroke="var(--_b)"/><text class="pele-label" x="0" y="5.6" text-anchor="middle">root</text></g></g>
    ),
  )
}
