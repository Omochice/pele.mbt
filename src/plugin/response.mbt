///|
fn respond(source : String, options : String) -> (Int32, Json) {
  try {
    let result = @core.render(
      [
        @architecture.architecture, @c4.c4, @cynefin.cynefin, @er.er, @eventmodeling.eventmodeling,
        @flowchart.flowchart, @git.git, @info.info, @ishikawa.ishikawa, @journey.journey,
        @kanban.kanban, @mindmap.mindmap, @packet.packet, @pie.pie, @quadrant.quadrant,
        @radar.radar, @railroad.railroad, @requirement.requirement, @sankey.sankey,
        @sequence.sequence, @timeline.timeline, @treemap.treemap, @treeview.treeview,
        @venn.venn, @wardley.wardley, @xychart.xychart,
      ],
      source,
      decode_options(@json.parse(options)),
    )
    (0, success(result))
  } catch {
    @errors.PeleError(failure) => (1, pele_failure(failure))
    error => (1, foreign_failure(error))
  }
}

///|
fn success(result : @types.RenderResult) -> Json {
  let links : Array[Json] = result.links.map(link => {
    "id": Json(link.id),
    "href": Json(link.href),
    "internal": Json(link.internal),
  })
  {
    "svg": Json(result.svg),
    "width": Json(result.width),
    "height": Json(result.height),
    "links": Json::array(links),
    "type": Json(result.kind),
    "mermaidType": Json(result.mermaid_type),
  }
}

///|
fn optional(value : String?) -> Json {
  match value {
    Some(text) => Json(text)
    None => Json::null()
  }
}

///|
fn pele_failure(failure : @errors.Failure) -> Json {
  {
    "error": {
      "name": "PeleError",
      "code": Json(failure.code.to_string()),
      "message": Json(failure.message),
      "type": optional(failure.kind),
      "mermaidType": optional(failure.mermaid_type),
    },
  }
}

///|
/// Anything other than a `PeleError` comes from the options rather than the diagram, as pele
/// would throw a JavaScript error before reading the text.
fn foreign_failure(error : Error) -> Json {
  {
    "error": {
      "name": "TypeError",
      "code": Json::null(),
      "message": Json(error.to_string()),
      "type": Json::null(),
      "mermaidType": Json::null(),
    },
  }
}
