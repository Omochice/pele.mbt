///|
fn respond(source : String, options : String) -> (Int32, Json) {
  try {
    let options = @util.parse_json(options)
    let result = @core.render(
      [
        @agentflow.agentflow, @architecture.architecture, @block.block, @c4.c4, @class.class,
        @cynefin.cynefin, @er.er, @eventmodeling.eventmodeling, @flowchart.flowchart,
        @gantt.gantt, @git.git, @info.info, @ishikawa.ishikawa, @journey.journey,
        @kanban.kanban, @mindmap.mindmap, @packet.packet, @pie.pie, @quadrant.quadrant,
        @radar.radar, @railroad.railroad, @requirement.requirement, @sankey.sankey,
        @sequence.sequence, @state.state, @swimlane.swimlane, @timeline.timeline,
        @treemap.treemap, @treeview.treeview, @usecase.usecase, @venn.venn, @wardley.wardley,
        @xychart.xychart,
      ],
      source,
      decode_options(options),
    )
    let svg = match decode_theme(options) {
      Some(theme) => {
        let out = StringBuilder()
        @typst.write_drawable(result.svg, theme, out)
        out.to_string()
      }
      None => result.svg
    }
    (0, success({ ..result, svg, }))
  } catch {
    @errors.PeleError(failure) => (1, pele_failure(failure))
    @util.JsonError(message, _) => (1, foreign_failure("SyntaxError", message))
    error => (1, foreign_failure("TypeError", error.to_string()))
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
/// Options that are not JSON fail as `JSON.parse` fails on them.
fn foreign_failure(name : String, message : String) -> Json {
  {
    "error": {
      "name": Json(name),
      "code": Json::null(),
      "message": Json(message),
      "type": Json::null(),
      "mermaidType": Json::null(),
    },
  }
}
