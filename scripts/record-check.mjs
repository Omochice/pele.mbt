// Reads a CI check's log and writes the row it gives the coverage comment to
// _build/checks/<key>.json, for scripts/merge-checks.mjs to collect from every job.
// A log that is missing or holds no summary writes nothing, so the row shows that the check gave
// no result rather than a number the check never printed.
//
// Usage: node scripts/record-check.mjs <key> <log>

import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { CHECKS } from './ci-checks.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const [key, logPath] = process.argv.slice(2);
const check = CHECKS.find((c) => c.key === key);
if (!check || !logPath) {
  console.error(`usage: node scripts/record-check.mjs <${CHECKS.map((c) => c.key).join('|')}> <log>`);
  process.exit(1);
}

if (!existsSync(logPath)) {
  console.log(`no ${logPath}; ${key} gave no result`);
  process.exit(0);
}
const result = check.parse(readFileSync(logPath, 'utf8'));
if (!result) {
  console.log(`no summary in ${logPath}; ${key} gave no result`);
  process.exit(0);
}

const out = join(root, '_build/checks', `${key}.json`);
mkdirSync(dirname(out), { recursive: true });
writeFileSync(out, `${JSON.stringify(result)}\n`);
console.log(`${check.name}: ${result.value}${result.unit}`);
