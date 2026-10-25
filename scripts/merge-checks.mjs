// Usage: node scripts/merge-checks.mjs <logs dir> <out>
//
// A check without a summary still gets a row, since a failed job is what the table most needs to show.
// octocov's custom metrics take only numbers, so that row carries 0 and says in its unit that there was no result.

import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { CHECKS } from './ci-checks.mjs';

const [logsDir, out] = process.argv.slice(2);
if (!logsDir || !out) {
  console.error('usage: node scripts/merge-checks.mjs <logs dir> <out>');
  process.exit(1);
}

const metrics = CHECKS.map(({ key, name, parse }) => {
  const log = join(logsDir, `${key}.log`);
  const result = existsSync(log) && parse(readFileSync(log, 'utf8'));
  return { key, name, ...(result || { value: 0, unit: ' (no result)' }) };
});

mkdirSync(dirname(out), { recursive: true });
writeFileSync(out, `${JSON.stringify({ key: 'checks', name: 'Checks', metrics }, null, 2)}\n`);
for (const m of metrics) console.log(`${m.name}: ${m.value}${m.unit}`);
