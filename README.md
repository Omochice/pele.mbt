# pele.mbt

A MoonBit port of [pele](https://github.com/obsidianmd/pele).
pele renders Mermaid diagrams to SVG.

The port draws the same SVG as pele byte for byte, or fails with the same error.

A typst package runs the port as a WebAssembly plugin.

[CONTRIBUTING.md](CONTRIBUTING.md) describes how to work on it.

## Layout

The code lives in two directories.

- `pele/` is the MoonBit library.
- `typst/` builds the plugin, and `typst/package/` is the [typst package](typst/package/README.md).

## License

The port is licensed under the zlib License in [LICENSE](LICENSE).

It is derived from pele.
pele's MIT License is kept in [LICENSE-PELE](LICENSE-PELE).
