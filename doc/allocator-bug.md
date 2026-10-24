# Allocator bug

moonc 0.10.17 links into a wasm module a TLSF allocator ported from AssemblyScript's, which can give a request of 512 MiB or more a free block smaller than the request.
Its `searchBlock` rounds a request up to the next size class only below 536870910 bytes, since rounding the largest requests would pass its table of classes, and looks a larger request up in its own class, whose blocks span 32 MiB.
`malloc` then splits the block it finds as if it were large enough, writing the header of a free block past it, and whatever is written into the request overwrites the live blocks that follow.
The port makes such requests whenever a string reaches 2^28 code units: the SVG of a drawing that long, its JSON answer once it passes 512 MiB, and a source of that many characters with every copy the parser makes of it.
A git graph whose branch is named by 140M characters drew an SVG of the right length with garbage near its end, a name of 270M characters has answered with a short SVG where pele fails, and a sequence diagram with a front matter title of 70M `<` once answered with one code unit changed; how much is overwritten depends on what the heap holds, so the same input can pass one run and fail the next.
The program below, built with `moon build --target wasm` in debug or release and run under node's WASI, shows it in a fresh heap.

```moonbit
fn main {
  // 605000000 and 630000000 bytes fall in the same size class, [603979776, 637534208).
  let a : FixedArray[Byte] = FixedArray::make(605000000, 0)
  let after : FixedArray[Byte] = FixedArray::make(16, 7)
  let filler : FixedArray[Byte] = FixedArray::make(64000000, 7)
  println("a \{a.length()}")
  let b : FixedArray[Byte] = FixedArray::make(630000000, 1)
  println("after[0] = \{after[0]}, filler[0] = \{filler[0]} (7 expected)")
}
```

It prints `after[0] = b'\x01', filler[0] = b'\x01'`, because `a` is freed after its last use and `b` is given its block, so filling `b` overwrites the blocks after it.
Without `filler`, the split writes past the end of memory and `malloc` traps with "memory access out of bounds" where it should have grown the memory.
This is a bug in MoonBit's runtime, to be reported upstream with the program above.

`scripts/allocator.mjs` mends the allocator in the built plugin, since no option of moonc replaces it.
It raises the bound below which `searchBlock` and `growMemory` round a request up to 1040187393 bytes, the highest at which rounding up by as much as 2^25 - 1 bytes stays below 2^30, the first size past the table, and lowers the largest request `prepareSize` lets through from 1073741820 to 1040187388 bytes, so that a request too large to round traps rather than corrupting memory.
No block can therefore pass 1040187380 bytes, 32 MiB less than before, which the port reaches only with a source of more than 520 million characters, near V8's longest string.
`scripts/build-typst.mjs` writes the mended plugin to `typst/plugin.wasm`, and `scripts/plugin-host.mjs` mends the plugin it loads, so every check runs the allocator typst runs; both fail when the allocator's code is not as expected, as after an upgrade of moonc, which then has to be checked for the same bug.
The git graph cases "a branch named by 140M a, drawn into a block of 512 MiB or more" and "a branch named by 270M a, read into a block of 512 MiB or more" check the mended plugin, and the first fails without the mend.

`moon test` runs the allocator unmended, so the tests that hold a string of 2^28 code units or more are skipped, and `scripts/check-string-length.mjs` checks the same inputs through the mended plugin.
The Gantt test "an axis label formatted past what a doubling StringBuilder holds is drawn as pele draws it" shows why: its drawing of 273001582 code units comes out exactly 2^20 code units short under the unmended allocator, in a fresh instance of the plugin built in debug or release alike, and matches pele once the allocator is mended.
