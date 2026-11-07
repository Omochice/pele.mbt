///|
test "render recognizes a diagram type without being given it" {
  let result = @pele.render("graph TD\n  A --> B")
  inspect(result.kind, content="flowchart")
  inspect(result.svg.has_prefix("<svg"), content="true")
}

///|
test "render passes the given options to pele" {
  let message = try {
    let _ = @pele.render("graph TD\n  A --> B", options={
      ..@types.RenderOptions::default(),
      limit: Some(1.0),
    })
    "rendered"
  } catch {
    @errors.PeleError(failure) => failure.message
  }
  inspect(
    message,
    content="Diagram source is longer than the limit of 1 characters.",
  )
}
