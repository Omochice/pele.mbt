// Reads the logs every CI job uploaded into one octocov custom metric set, so the coverage
// comment shows the checks as a single table.
// A check whose log is missing or holds no summary still gets a row, because a job that failed
// before its check printed a summary is what the table most needs to show, and octocov's custom
// metrics take only numbers, so the row carries 0 and says in its unit that there was no result.
//
// Usage: node scripts/merge-checks.mjs <logs dir> <out>

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
