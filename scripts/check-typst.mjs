// Compiles the typst package's examples and tests with the typst CLI.
// A document passes when it compiles without an error or a warning; a test named *.fail.typ
// passes when it fails with the text its first line names after `// error:`.
//
// Usage: node scripts/check-typst.mjs
// Run scripts/build-typst.mjs first. The typst binary is taken from $TYPST, or from PATH.

import { spawnSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, readdirSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { basename, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const packageDir = join(root, 'typst/package');
const typst = process.env.TYPST ?? 'typst';

if (!existsSync(join(packageDir, 'plugin.wasm'))) {
  console.error('missing typst/package/plugin.wasm; run `node scripts/build-typst.mjs` first');
  process.exit(1);
}

const documents = ['examples', 'tests']
  .filter((dir) => existsSync(join(packageDir, dir)))
  .flatMap((dir) =>
  readdirSync(join(packageDir, dir))
    .filter((f) => f.endsWith('.typ'))
    .sort()
    .map((f) => join(packageDir, dir, f)),
);

function expectedError(file) {
  const first = readFileSync(file, 'utf8').split('\n', 1)[0];
  const match = /^\/\/ error: (.+)$/.exec(first);
  if (!match) throw new Error(`${file} names no expected error on its first line`);
  return match[1];
}

function check(file, out) {
  const run = spawnSync(
    typst,
    ['compile', '--root', packageDir, '--diagnostic-format', 'short', file, join(out, `${basename(file, '.typ')}.pdf`)],
    { encoding: 'utf8' },
  );
  if (run.error) {
    console.error(`cannot run ${typst}: ${run.error.message}`);
    process.exit(1);
  }
  const diagnostics = run.stderr.trim();
  if (file.endsWith('.fail.typ')) {
    if (run.status === 0) return 'compiled, but was expected to fail';
    const expected = expectedError(file);
    return diagnostics.includes(expected) ? undefined : `expected an error with ${JSON.stringify(expected)}, got\n${diagnostics}`;
  }
  if (run.status !== 0) return diagnostics;
  return /warning/i.test(diagnostics) ? diagnostics : undefined;
}

const out = mkdtempSync(join(tmpdir(), 'pele-typst-'));
let failed = 0;
try {
  for (const file of documents) {
    const problem = check(file, out);
    const name = file.slice(packageDir.length + 1);
    if (problem === undefined) {
      console.log(`PASS ${name}`);
    } else {
      failed++;
      console.log(`FAIL ${name}: ${problem}`);
    }
  }
} finally {
  rmSync(out, { recursive: true, force: true });
}
console.log(`\n${documents.length - failed}/${documents.length} passed`);
process.exitCode = failed > 0 ? 1 : 0;
