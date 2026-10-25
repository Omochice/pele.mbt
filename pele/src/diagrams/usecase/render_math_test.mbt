///|
/// The viewBox and the content of the diagram drawn with a typesetter that knows `tall`.
fn math_usecase(source : String) -> (String, String) {
  let math = (tex : String, _ : Double) => {
    match tex {
      "tall" => Some(({ "svg": "<path/>", "width": 20, "height": 40 } : Json))
      _ => None
    }
  }
  let options = { ..@types.RenderOptions::default(), math: Some(math), }
  let svg = (@core.render([@usecase.usecase], source, options) catch {
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
test "a wrapped JSON value places each line by its own height" {
  let (view_box, body) = math_usecase(
    "usecase-beta\n  json Payload@{\"k\":\"a $$tall$$ b c d e f g h i j k l m n o p q r s t u v w x y z aa bb cc dd ee ff gg hh\"}",
  )
  inspect(
    view_box,
    content=(
      #|0 0 316 118
    ),
  )
  inspect(
    body,
    content=(
      #|<g class="pele-nodes"><g class="pele-node pele-json usecase-json-table" data-id="Payload" transform="translate(157.84,59)"><rect x="-149.84" y="-51" width="299.68" height="102" fill="var(--_s)" stroke="var(--_b)" style="rx:var(--_r)"/><path class="pele-json-lines" d="M-149.84,-19H149.84M-122.84,-19V51" fill="none" stroke="var(--_b)"/><text class="pele-label" font-weight="var(--_hw)" text-anchor="middle" xml:space="preserve"><tspan x="0" y="-29.4">Payload</tspan></text><g font-size="14"><text class="pele-json-key" fill="var(--_m)" x="-136.34" y="20.9" text-anchor="middle">k</text><text class="pele-json-value" text-anchor="middle" xml:space="preserve"><tspan x="-112.84" y="11.9" text-anchor="start">a </tspan><tspan x="-81.16" y="11.9" text-anchor="start"> b c d e f g h i j k l m n o p q r s t u v</tspan></text><svg class="pele-math" x="-101.16" y="-13" width="20" height="40" overflow="visible"><path/></svg><text class="pele-json-value" x="-18.28" y="42.9" text-anchor="middle">w x y z aa bb cc dd ee ff gg hh</text></g></g></g>
    ),
  )
}
