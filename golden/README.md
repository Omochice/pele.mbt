# Golden fixtures

The files in this directory are the reference outputs of pele v1.8.0, rendered from pele's own test corpus.
A port is correct when it reproduces every file here.
The directory is generated, so it MUST NOT be edited by hand.

## Layout

Each source text is stored under the diagram whose corpus it came from, as `golden/<diagram>/<id>.*`.
The `<id>` is the first 16 hex characters of the SHA-256 of the source text, so the same text appearing in several corpora is kept once per diagram.

- `<id>.mmd` is the exact source text.
- `<id>.svg` is the exact `svg` string, present only when rendering succeeded.
- `<id>.json` holds `type`, `mermaidType`, `width`, `height`, and `links` on success.
    On failure it holds a single `error` object with `name`, `code`, `message`, `type`, and `mermaidType`.

Errors are goldens too, because a port has to reject the same inputs with the same code and message.
`manifest.json` records the pele version and commit, the node version, the options, and per-diagram counts of total, ok, and error.
It contains no timestamps, so regeneration is byte-identical.

## Regenerating

The script reads the pinned pele checkout, so the submodule has to be initialised and built first.

```sh
git submodule update --init vendor/pele
(cd vendor/pele && npm ci && npm run build)
node scripts/gen-golden.mjs
```

The script deletes everything in `golden/` except this README and then rewrites it.
Corpus inputs are collected by a port of `loadCorpus` in `vendor/pele/tests/support/corpus.ts`, which takes string literals from `tests/compat/<diagram>/*.spec.{js,ts}` that match a per-diagram keyword and adds `tests/corpus/<diagram>-docs.json`.
`tests/corpus/agentflow-reference.json` is not included because its entries are objects rather than plain source strings.

## Pinned options

Every render uses the options recorded in `manifest.json`.
They are pele's own defaults, written out explicitly so that a change of default upstream cannot alter the goldens silently.
`now` is the exception: gantt charts read the current time by default, so it is fixed to 1767225600000 (2026-01-01T00:00:00Z).
`maxWidth`, `responsive`, `linkSchemes`, and `imageSchemes` are left unset because their defaults mean "undefined selects the built-in behavior" rather than a concrete value.
`measurer`, `icons`, `math`, and `config` are unset as well.
The default measurer falls back to pele's built-in metrics table when no canvas is available, and a port has to reproduce that table to match text widths.

## Number formatting

Every coordinate in the SVG output is formatted by `num()` in `vendor/pele/src/svg/builder.ts`.
It rounds to hundredths and drops trailing zeros, so a port has to reproduce it exactly, including its handling of negative values and zero, for a byte-exact comparison.
