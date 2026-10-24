///|
#skip("slow: draws over 350 million code units")
test "a front matter title wrapped past what a StringBuilder grows to is drawn as pele draws it" {
  let title = "<".repeat(70000000)
  let rendered = @core.render(
    [@timeline.timeline],
    "---\ntitle: \{title}\n---\ntimeline\n  p : e\n",
    {
      ..@types.RenderOptions::default(),
      limit: Some(1.0 / 0.0),
      output_limit: Some(1.0 / 0.0),
    },
  )
  inspect(
    "\{rendered.svg.length()} wide \{rendered.width}",
    content="357774107 wide 334",
  )
}
