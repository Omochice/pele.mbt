import { readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

if (!process.env.PELE_ROOT) {
  console.error(
    'PELE_ROOT is not set. Run this inside `nix develop`, which builds the pinned pele and sets PELE_ROOT, ' +
      'or set PELE_ROOT to a built checkout of the pele commit pinned in flake.lock.'
  );
  process.exit(1);
}

/** The built pele checkout whose dist/, tests/ and package.json the scripts read, named by PELE_ROOT. */
export const peleRoot = resolve(process.env.PELE_ROOT);

/**
 * The pele commit flake.lock pins, which PELE_ROOT is expected to hold.
 * @returns {string} The full commit hash.
 */
export function peleCommit() {
  const lock = join(dirname(fileURLToPath(import.meta.url)), '..', 'flake.lock');
  return JSON.parse(readFileSync(lock, 'utf8')).nodes.pele.locked.rev;
}
