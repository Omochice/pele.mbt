# Documentation

These files describe how the port is checked against pele and where it knowingly stops following it, apart from the golden fixtures, which [golden/README.md](../golden/README.md) describes, and the typst package, which [typst/package/README.md](../typst/package/README.md) describes.

- [testing.md](testing.md) lists every check, what it verifies, and how to run it.
- [output-ceiling.md](output-ceiling.md) describes the limits the port has of its own as a wasm plugin, chief among them the longest SVG it draws.
- [allocator-bug.md](allocator-bug.md) describes the bug in the allocator moonc 0.10.17 links in and how the built plugin is mended.
- [known-constraints.md](known-constraints.md) lists the enormous inputs on which the port differs from pele, on purpose where pele fails only on V8's limits, or cannot be compared with it.
