import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

/** The built pele checkout whose dist/, tests/ and package.json the scripts read. */
export const peleRoot = resolve(process.env.PELE_ROOT ?? join(root, 'vendor/pele'));
