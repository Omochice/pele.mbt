# Documentation

These files describe how the port is checked against pele and where it knowingly stops following it, apart from the golden fixtures, which [golden/README.md](../golden/README.md) describes, and the typst package, which [typst/README.md](../typst/README.md) describes.

- [testing.md](testing.md) lists every check, what it verifies, and how to run it.
- [output-ceiling.md](output-ceiling.md) describes the longest SVG the port draws and how it follows V8's limits on strings, arrays and regular expressions.
- [allocator-bug.md](allocator-bug.md) describes the bug in the allocator moonc 0.10.17 links in and how the built plugin is mended.
- [known-constraints.md](known-constraints.md) lists the enormous inputs on which the port still differs from pele or cannot be compared with it.
