///|
/// Mermaid's default maxTextSize.
const DEFAULT_LIMIT : Double = 50000

///|
/// Mermaid has no limit on its output, but a source within the limit can still describe a
/// drawing of many megabytes.
const DEFAULT_OUTPUT_LIMIT : Double = 4000000

///|
/// `A & B --> C & D` multiplies, so a few kilobytes of source can ask for millions of edges.
const DEFAULT_MAX_EDGES : Double = 5000

///|
/// The drawing the diagram answers with, refused when the port does not hold it.
/// Only this drawing is refused, because a diagram drawn more than once to fit the host may have
/// measured a drawing the port does not hold and gone on to a narrower one, as pele does.
fn held(rendered : @types.Rendered) -> @types.Rendered raise @errors.PeleError {
  guard @svg.is_held_document(rendered.svg) else {
    raise @svg.too_large_to_hold()
  }
  rendered
}

///|
/// Gives an error from a diagram the type it was detected as, unless it names one already.
fn[T] tag_errors(
  found : @detect.Detected,
  run : () -> T raise @errors.PeleError,
) -> T raise @errors.PeleError {
  run() catch {
    @errors.PeleError(failure) =>
      raise @errors.PeleError({
        ..failure,
        message: @text.written_codes(failure.message),
        snippet: @text.written_codes(failure.snippet),
        kind: if failure.kind is None {
          Some(found.kind)
        } else {
          failure.kind
        },
        mermaid_type: if failure.mermaid_type is None {
          Some(found.mermaid_type)
        } else {
          failure.mermaid_type
        },
      })
  }
}

///|
/// Finds an offset of the parsed text in `text` as written, with its line breaks normalized and the
/// line break added for parsing.
/// The preprocessing edits are recorded only once a position is asked for, as errors are rare.
fn in_source(text : String, keep_comments : Bool) -> (Int32) -> (String, Int32) {
  let mut steps : Array[Array[@errors.Edit]]? = None
  let mut source = ""
  at => {
    let recorded = match steps {
      Some(recorded) => recorded
      None => {
        let recorded = []
        // The text was preprocessed once already, so it cannot fail now.
        let pre = @preprocess.preprocess(text, steps=recorded) catch {
          _ => abort("preprocessing failed the second time")
        }
        @preprocess.encode_entities(
          if keep_comments {
            pre.with_comments
          } else {
            @preprocess.cleanup_comments(pre.with_comments, steps=recorded)
          },
          steps=recorded,
        )
        |> ignore
        source = @util.normalize_line_breaks(text) + "\n"
        steps = Some(recorded)
        recorded
      }
    }
    (source, @errors.input_offset(recorded, at))
  }
}

///|
/// The host's config with the text's own front matter and directives over it.
fn merged_config(extra : @types.Config?, own : @types.Config) -> @types.Config {
  guard extra is Some(extra) else { return own }
  let config : @types.Config = Map([])
  for key, value in extra {
    config[key] = value
  }
  for key, value in own {
    config[key] = value
  }
  config
}

///|
/// Whether the diagram's config section asks for its natural width.
fn fixed_width(config : @types.Config, section : String) -> Bool {
  guard config.get(section) is Some(Object(fields)) else { return false }
  fields.get("useMaxWidth") is Some(False)
}

///|
/// Renders Mermaid text to SVG with the given diagram types.
/// Raises `PeleError` for text pele rejects.
pub fn render(
  diagrams : ArrayView[@types.Diagram],
  source : String,
  options : @types.RenderOptions,
) -> @types.RenderResult raise @errors.PeleError {
  let limit = options.limit.unwrap_or(DEFAULT_LIMIT)
  if source.length().to_double() > limit {
    raise @errors.pele_error(
      "Diagram source is longer than the limit of \{limit} characters.",
      code=Limit,
    )
  }
  let pre = @preprocess.preprocess(source)
  guard @detect.detect_diagram(pre.text) is Some(found) else {
    raise @errors.pele_error(
      "No diagram type detected for the given text.",
      code=UnsupportedDiagram,
    )
  }
  guard diagrams.iter().find_first(d => d.kind == found.kind) is Some(diagram) else {
    raise @errors.pele_error(
      "Diagram type \"\{found.kind}\" is not supported yet.",
      code=UnsupportedDiagram,
      kind=found.kind,
      mermaid_type=found.mermaid_type,
    )
  }
  let config = merged_config(options.config, pre.config)
  let text = if diagram.keep_comments { pre.with_comments } else { pre.text }
  let max_edges = options.max_edges.unwrap_or(DEFAULT_MAX_EDGES).to_int()
  let encoded = @preprocess.encode_entities(text) + "\n"
  let parsed = tag_errors(found, () => {
    @errors.locating_in(
      { parsed: encoded, find: in_source(source, diagram.keep_comments), },
      () => {
        (diagram.parse)(encoded, config, pre.title, pre.line_offset, {
          max_edges,
        })
      },
    )
  })
  let responsive = options.responsive.unwrap_or(
    !fixed_width(config, diagram.section.unwrap_or(found.kind)),
  )
  // The resolver sees names as the author meant them, with entity codes turned into their
  // characters, as `data-icon` in the SVG does.
  let icons = options.icons.map(resolve => {
    (name : String) => resolve(@text.decode_entities(name))
  })
  let rendered = tag_errors(found, () => {
    @text.with_math(if diagram.math { options.math } else { None }, () => {
      @text.with_icons(icons, () => {
        (parsed.render)(config, {
          ..options,
          responsive: Some(responsive),
          icons,
        })
      })
    })
  })
  let output_limit = options.output_limit.unwrap_or(DEFAULT_OUTPUT_LIMIT)
  // pele refuses a drawing past its output limit however long it is, so the port's own limit
  // stands only for a drawing the output limit allows.
  if @svg.document_length(rendered.svg).to_double() > output_limit {
    raise @errors.pele_error(
      "Diagram output is longer than the limit of \{output_limit} characters.",
      code=Limit,
      kind=found.kind,
      mermaid_type=found.mermaid_type,
    )
  }
  let rendered = tag_errors(found, () => held(rendered))
  {
    kind: found.kind,
    mermaid_type: found.mermaid_type,
    svg: rendered.svg,
    width: rendered.width,
    height: rendered.height,
    links: rendered.links.map(link => {
      ..link,
      id: @text.decode_entities(link.id),
    }),
  }
}
