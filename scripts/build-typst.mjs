// Builds the wasm plugin and copies it into the typst package, which loads it from its own
// directory, with the allocator moonc links into it mended (see scripts/allocator.mjs).
//
// Usage: node scripts/build-typst.mjs
// The moon binary is taken from $MOON, or from PATH.

import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { fixAllocator } from './allocator.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const moon = process.env.MOON ?? 'moon';

const build = spawnSync(moon, ['build', '--target', 'wasm', '--release'], { cwd: root, stdio: 'inherit' });
if (build.error) {
  console.error(`cannot run ${moon}: ${build.error.message}`);
  process.exit(1);
}
if (build.status !== 0) process.exit(build.status ?? 1);

const target = join(root, 'typst/package/plugin.wasm');
writeFileSync(target, fixAllocator(readFileSync(join(root, '_build/wasm/release/build/Omochice/pele-typst/plugin/plugin.wasm'))));
console.log(`copied the plugin, with its allocator mended, to ${target}`);
