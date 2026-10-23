///|
/// What the plugin answers, before it is written as JSON.
priv enum Reply {
  /// A drawing, whose SVG is rewritten for typst under the theme, when there is one, as it is written.
  Drawn(@types.RenderResult, Map[String, String]?)
  /// A failure, as the JSON object that reports it.
  Failed(Json)
}

///|
fn reply(source : String, options : String) -> Reply {
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
    Drawn(result, decode_theme(options))
  } catch {
    @errors.PeleError(failure) => Failed(pele_failure(failure))
    @util.JsonError(message, _) =>
      Failed(foreign_failure("SyntaxError", message))
    error => Failed(foreign_failure("TypeError", error.to_string()))
  }
}

///|
/// The most bytes the plugin answers with.
/// typst reads the answer from one block of the plugin's memory, and wasm's allocator, as
/// scripts/allocator.mjs mends it, gives no block over 1040187380 bytes, so the limit is set in
/// round figures below that.
const RESPONSE_LIMIT : Int32 = 1000000000

///|
/// The reply as UTF-8 JSON, with the status the plugin returns: 0 for a drawing and 1 for a failure.
/// A drawing whose answer would be longer than `limit` bytes fails as a limit error instead.
/// The SVG is counted and then written straight into the answer, through the theme when there
/// is one, so that it is held only once however long it is.
fn encode(
  reply : Reply,
  limit~ : Int32 = RESPONSE_LIMIT,
) -> (Int32, FixedArray[Byte]) {
  let (result, theme) = match reply {
    Drawn(result, theme) => (result, theme)
    Failed(json) => return (1, @utf8.encode(json.stringify()).to_fixedarray())
  }
  let write_svg = (out : &Logger) => {
    match theme {
      Some(theme) => @typst.write_drawable(result.svg, theme, out)
      None => out.write_string(result.svg)
    }
  }
  let shell = success({ ..result, svg: "", }).stringify()
  let opening = "{\"svg\":\""
  guard shell.has_prefix(opening + "\"") else {
    abort("a drawing's JSON does not open with its SVG")
  }
  let head = @utf8.encode(opening)
  let tail = @utf8.encode(@util.slice(shell, opening.length()))
  let counter = JsonText::counter()
  write_svg(counter)
  counter.finish()
  let total = head.length().to_int64() + counter.at + tail.length().to_int64()
  if total > limit.to_int64() {
    let failure = pele_failure({
      message: "Diagram output is longer than the typst plugin can return: its JSON response would pass the plugin's limit of \{limit} bytes.",
      code: Limit,
      kind: Some(result.kind),
      mermaid_type: Some(result.mermaid_type),
      line: 0,
      column: 0,
      snippet: "",
    })
    return (1, @utf8.encode(failure.stringify()).to_fixedarray())
  }
  let out : FixedArray[Byte] = FixedArray::make(total.to_int(), 0)
  out.blit_from_bytes(0, head, 0, head.length())
  let writer = JsonText::writer(out, head.length())
  write_svg(writer)
  writer.finish()
  out.blit_from_bytes(writer.at.to_int(), tail, 0, tail.length())
  (0, out)
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
