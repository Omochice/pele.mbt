# pele

A MoonBit port of [pele](https://github.com/obsidianmd/pele), which renders Mermaid diagrams to SVG.

The port draws the same SVG as pele byte for byte, or fails with the same error.

## Usage

```sh
moon add Omochice/pele
```

`@pele.render` recognizes every diagram type.

```moonbit
let source =
  #|graph TD
  #|  A --> B
let result = @pele.render(source)
println(result.svg)
```

`@pele` used in the above example requires import in `moon.pkg`.

```text
import {
  "Omochice/pele",
}
```

### Picking diagram types

Linking every diagram type makes a program larger, which matters for a wasm build.
`@core.render` recognizes only the diagram types it is given.\
Each type is the value of the same name in its package under `Omochice/pele/diagrams/`.

```moonbit
let source =
  #|graph TD
  #|  A --> B
let result = @core.render(
  [@flowchart.flowchart, @pie.pie],
  source,
  @types.RenderOptions::default(),
)
println(result.svg)
```

`@core`, `@types`, `@flowchart` and `@pie` used in the above example each require import in `moon.pkg`.

```text
import {
  "Omochice/pele/core",
  "Omochice/pele/diagrams/flowchart",
  "Omochice/pele/diagrams/pie",
  "Omochice/pele/types",
}
```

## License

The port is licensed under the zlib License in [LICENSE](https://github.com/Omochice/pele.mbt/blob/main/LICENSE).

It is derived from pele.
pele's MIT License is kept in [LICENSE-PELE](https://github.com/Omochice/pele.mbt/blob/main/LICENSE-PELE).
