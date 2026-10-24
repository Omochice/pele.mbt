# Known constraints

The port still differs from pele, or cannot be compared with it, on the inputs below, each of tens to hundreds of millions of characters.
On the first seven the plugin traps, by refusing an allocation or running out of memory, where pele draws the diagram or fails it with a `limit` error; the first six were each rendered through pele and through the plugin to confirm it.
They are accepted as constraints rather than reproduced, because each would need another part of the port to be rebuilt around pieces.

- A `classDef` or `style` value of about 270 million plain letters in a flowchart, class, state, ER, block or agentflow diagram, which pele draws: `resolve_style` and `resolve_raw_style` in `src/svg/` lowercase it with `lower_ascii` in `src/svg/style.mbt` into a doubling `StringBuilder`, which needs more than the largest block wasm's allocator gives.
- A kanban card label of about 270 million plain letters, which pele fails as nested too deeply: the plugin traps before the card's lines, each written into `Markup` on its own, add up to that length.
- A label that typesets math under a style or an id of 2^28 code units or more, which pele fails as nested too deeply: `write_label_styled` and `write_label_with_id` give the math its color from their attributes made into one string.
- An option string of 2^28 code units or more, such as a single host icon drawing, which pele draws: the plugin reads its options with `JsonReader::string` in `src/util/json.mbt` into a doubling `StringBuilder`, and `icon_svg` in `src/diagrams/common/icon.mbt`, which the tree view and the architecture's `icon_slot` draw icons with, makes the icon one string as well.
- An ER attribute type of about 70 million `~`, which pele draws as an SVG of 280 million code units: `@text.layout_label` lays the attribute's label out from a source of 280 million code units.
- A source of more than 2^27 tokens in a lexer other than agentflow's, such as a class diagram of 134 million commas: pele fails as nested too deeply on its 2^27 + 1st token, while the port runs out of memory before it gets there.
- A use case label for which `literal` in `src/diagrams/usecase/render.mbt` makes a string between about 480 million code units and V8's longest string, which wasm cannot allocate where V8 can.
- pele's arrays of one element per character, `split('')` in `generics.ts`, `Array.from` in `literal-label.ts` and the spread in `sequence/db.ts`, fail past 2^27 elements, and the port is not shown to fail where they do, since no case reaches them.
- `moon test` runs the allocator unmended, as [the allocator bug](allocator-bug.md) describes, so its tests of 2^28 code units or more are skipped and `scripts/check-string-length.mjs` checks the same inputs instead.
- A journey task or a timeline event of about 270 million characters, and a timeline event or a quadrant label of a hundred million, run pele itself out of node's heap, so there is no outcome of pele's to compare the port with.
