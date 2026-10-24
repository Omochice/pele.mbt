import { execFileSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { join, resolve } from 'node:path';

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
 * The commit of the pele that peleRoot holds.
 * PELE_COMMIT is preferred because the store path `nix develop` gives is not a git checkout.
 * @returns {string} The full commit hash.
 */
export function peleCommit() {
  if (process.env.PELE_COMMIT) return process.env.PELE_COMMIT;
  if (existsSync(join(peleRoot, '.git'))) {
    return execFileSync('git', ['-C', peleRoot, 'rev-parse', 'HEAD'], { encoding: 'utf8' }).trim();
  }
  console.error(`PELE_COMMIT is not set and ${peleRoot} is not a git checkout, so the pele commit cannot be recorded. Set PELE_COMMIT to it.`);
  process.exit(1);
}
