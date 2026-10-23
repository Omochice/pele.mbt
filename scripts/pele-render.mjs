// Renders one source with pele's dist bundle and prints the outcome as JSON, in the shape of a
// golden's .json file plus `svg`.
//
// Usage: node scripts/pele-render.mjs < request.json
// The request is `{ "peleRoot": "<checkout with dist/>", "options": {...}, "text": "<source>" }`.
//
// How deep pele recurses before V8 runs out of stack depends on everything below render(): this
// module's own top level, and the arguments and environment, which sit at the top of the main
// thread's stack. So everything comes in on stdin, and a caller that wants a fixed reach runs this
// with an empty environment and nothing on the command line but this script's path.

import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

// gen-golden pins the same zone; setting it here rather than in the environment keeps it off the stack.
process.env.TZ = 'UTC';
const { peleRoot, options, text } = JSON.parse(readFileSync(0, 'utf8'));
const { render } = await import(pathToFileURL(join(peleRoot, 'dist/pele.js')).href);
let outcome;
try {
  const r = render(text, options);
  outcome = { svg: r.svg, type: r.type, mermaidType: r.mermaidType, width: r.width, height: r.height, links: r.links };
} catch (e) {
  outcome = { error: { name: e.name, code: e.code ?? null, message: String(e.message), type: e.type ?? null, mermaidType: e.mermaidType ?? null } };
}
process.stdout.write(JSON.stringify(outcome));
