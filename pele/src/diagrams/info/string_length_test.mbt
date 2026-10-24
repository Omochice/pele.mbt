///|
fn options() -> @types.RenderOptions {
  { ..@types.RenderOptions::default(), limit: Some(1.0 / 0.0), }
}

///|
#skip("slow: draws over 300 million code units")
test "a title longer than a doubling StringBuilder holds is drawn" {
  let title = "&".repeat(60000000)
  let svg = @core.render([@info.info], "info\ntitle \{title}\n", options()).svg
  inspect(svg.length(), content="300000962")
}

///|
#skip("slow: draws over 300 million code units")
test "an accessible description longer than a doubling StringBuilder holds is drawn" {
  let descr = "&".repeat(60000000)
  let svg = @core.render([@info.info], "info\naccDescr: \{descr}\n", options()).svg
  inspect(svg.length(), content="300000827")
}

///|
#skip("slow, and moon test runs wasm's allocator unmended, which can give a block of 512 MiB or more a smaller one; check-string-length checks it through the mended plugin")
test "a title of 2^28 or more plain letters is drawn" {
  let title = "a".repeat(270000000)
  let svg = @core.render([@info.info], "info\ntitle \{title}\n", {
      ..options(),
      output_limit: Some(1.0 / 0.0),
    }).svg
  inspect(svg.length(), content="270000966")
}
