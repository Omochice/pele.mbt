# Testing

The port is correct when it answers every input as pele v1.12.0 does, so every check below compares the port with pele's own output rather than with expectations written by hand.
The checks differ in where the inputs come from and in how far past ordinary sizes they go.

## Prerequisites

Every check is run from the repository root.
The flake's default development shell, entered with `nix develop`, provides `moon`, node 24 and `typst`.

The checks that load the plugin read `_build/wasm/release/build/Omochice/pele-typst/plugin/plugin.wasm`, so the plugin has to be built first.

```sh
moon build --target wasm --release
```

The checks that render through pele import its built bundle, `dist/pele.js`, from the checkout that `PELE_ROOT` names.
The development shell builds the pele commit pinned as the flake's `pele` input and sets `PELE_ROOT` to it, so pele needs no fetching or building by hand.
`scripts/check-stress.mjs` and `scripts/fuzz.mjs` also read pele's `tests/` from that checkout, and every script stops with an error naming `nix develop` when `PELE_ROOT` is unset.
Without Nix, `PELE_ROOT` has to name a checkout of that commit built with `npm ci && npm run build`.

The scripts that render through pele pin `TZ=UTC` themselves, as the goldens are made, so no time zone has to be set by hand.
Gantt reads a date-only value as UTC midnight but floors its axis ticks to local midnight, so without that pin pele's output would depend on the machine's time zone.

## moon test

`moon test` runs the unit tests and the tests that pin pele's behavior in each package under `pele/src/` and `typst/src/`.
`moon.work` at the repository root makes the library under `pele/` and the plugin under `typst/` members of one workspace, so moon run from the root checks, tests and builds both.
Both `moon.mod` files name wasm as the preferred target, so no target has to be given.
`pele/src/diagrams/flowchart/golden_cases_test.mbt` is generated, as [Regenerating](#regenerating) describes, and holds for every flowchart golden source what pele's `parse()` makes of it.

### Skipped tests

90 tests are marked `#skip`, all but three of them in the `string_length_test.mbt` of each diagram under `pele/src/diagrams/`.
The argument of each `#skip` states why, and the reasons are the two below.

- Every one is slow, because it lexes, escapes or draws tens to hundreds of millions of code units, as an input past what a doubling `StringBuilder` holds takes.
- 9 of them also hold a string of 2^28 code units or more, which `moon test` cannot check because it runs the allocator moonc links in unmended, as [the allocator bug](allocator-bug.md) describes.

`scripts/check-string-length.mjs` checks the same inputs instead, through the plugin with its allocator mended: most cases in `scripts/string-length-cases.mjs` are the same as a test in a diagram's `string_length_test.mbt`.
The three skipped tests outside the diagrams, two in `pele/src/svg/escape_test.mbt` and one in `typst/src/theme/drawable_test.mbt`, cover the escape writers and the theme's rewrite of a style, which that check reaches through whole diagrams and through the theme typst sends.

## Golden fixtures

`scripts/check-golden.mjs` renders every golden source through the plugin under every profile in `golden/manifest.json` and compares each result with pele's output byte for byte, errors included.
It holds the plugin to typst's call depth, through `scripts/call-depth.mjs`, so a source that would trap in typst fails here too, and it reports the deepest call it saw.

```sh
node scripts/check-golden.mjs
node scripts/check-golden.mjs --profile narrow flowchart sequence
```

`--profile` keeps only the named profile and may be repeated, and each positional argument keeps one diagram.
A diagram missing from its list of ported diagrams is reported as skipped rather than failed.
The check needs no pele checkout, since the goldens hold pele's output.

[golden/README.md](../golden/README.md) describes the fixtures' layout, the pinned option profiles and the JSON forms of the callback options.

### Regenerating

The goldens are regenerated with `node scripts/gen-golden.mjs` from a built pele checkout, as [golden/README.md](../golden/README.md#regenerating) describes.
`pele/src/diagrams/flowchart/golden_cases_test.mbt` is generated from the goldens and pele's `parse()`, so it is regenerated after them.

```sh
node scripts/gen-golden.mjs
node scripts/gen-flowchart-golden-test.mjs
```

`node scripts/gen-flowchart-golden-test.mjs --dumps <dir>` also writes each success's full dump to `<dir>/<id>.txt` for comparing by eye.

## Fuzzing

`scripts/fuzz.mjs` is a seeded differential fuzzer.
The goldens hold only the sources of pele's corpus, so it mutates them the way pele's own oracle tests do and compares pele and the plugin on inputs neither was written against.
Each mutation is rendered under every golden profile and under random option sets, and for each kind of mismatch the first case is shrunk to a smaller source and fewer options that still disagree.

```sh
node scripts/fuzz.mjs [--seed n] [--count n] [--variations n] [--jobs n] [--out file.json] [--no-shrink] [diagram ...]
```

The defaults are seed 1, 1000 sources per diagram, one random option set, and one worker fewer than the available parallelism.
A run makes `count * (profiles + variations)` comparisons per diagram, and a seed gives the same cases and the same report whatever `--jobs` is.

## pele's stress tests

`scripts/check-stress.mjs` feeds the inputs of pele's stress tests through the plugin and through pele, and checks that the plugin never traps and ends in the same outcome: success, or a `PeleError` of the same code.
The inputs add up to tens of megabytes, so they are not stored but rebuilt on every run by loading each test file of pele with its imports replaced by recorders.

```sh
node scripts/check-stress.mjs [--typst [--jobs <n>]] [--stack-sizes <kb>,<kb>...] [filter ...]
```

A filter keeps the tests whose `<file> > <name>` contains it.
By default the plugin runs under node, rewritten to trap past the call frames typst's interpreter allows, and the deepest inputs are listed.
`--typst` runs it under `typst compile` itself, `$TYPST` or `typst` on `PATH`, which is slow but confirms that emulation.
`--stack-sizes` computes pele's outcomes again under each given V8 stack size and reports every input whose outcome depends on it, since a `RangeError` from a deep stack is how pele reports nesting as a limit.

## String length

`scripts/check-string-length.mjs` renders each case of `scripts/string-length-cases.mjs`, whose drawings are hundreds of millions of code units long, through pele and through the plugin.
[Checking against pele](output-ceiling.md#checking-against-pele) describes what it checks, and [Output ceiling](output-ceiling.md) why those lengths matter.

```sh
NODE_OPTIONS=--max-old-space-size=20480 node scripts/check-string-length.mjs [diagram ...]
```

Each case makes pele and the plugin produce hundreds of millions of characters, so a case takes half a minute or more, and the plugin may grow its memory to 4 GiB.
pele itself runs out of node's default heap on some cases, so the check is run under `NODE_OPTIONS=--max-old-space-size=20480`.
Each case builds its source only when the check reaches it, so naming one diagram holds only that diagram's cases, one at a time.

## typst

`scripts/build-typst.mjs` builds the plugin in release, mends its allocator, and writes it to `typst/package/plugin.wasm`, which is not tracked.
`scripts/check-typst.mjs` then compiles every document under `typst/package/examples` and `typst/package/tests` with `$TYPST`, or `typst` on `PATH`.

```sh
node scripts/build-typst.mjs
node scripts/check-typst.mjs
```

A document passes when it compiles without an error or a warning, and a test named `*.fail.typ` passes when it fails with the message its first line names after `// error:`.
`moon` is taken from `$MOON`, or from `PATH`.

## Supporting scripts

The modules below are not run on their own but shared by the checks above, or run only when what they generate has to change.

- `scripts/plugin-host.mjs` hosts the plugin as typst does, through the wasm-minimal-protocol, with its allocator mended as `typst/package/plugin.wasm` ships it, and refuses a plugin that imports anything typst does not provide.
- `scripts/allocator.mjs` mends the allocator moonc links in, as [the allocator bug](allocator-bug.md) describes.
- `scripts/call-depth.mjs` rewrites the plugin to count its own call depth and trap past typst's limit, since V8 allows wasm a far deeper stack.
- `scripts/plugin-options.mjs` turns the plugin's JSON forms of `icons`, `math` and `measurer` back into pele's callbacks, and is the reference for what that data means.
- `scripts/string-length-cases.mjs` holds the inputs of the string length check.
- `scripts/gen-letters.mjs` writes `pele/src/util/letters.mbt`, the code points of `[\p{L}\p{N}]` as the running node sees them, because pele checks font names with that class and MoonBit's core library has no Unicode property tables.
