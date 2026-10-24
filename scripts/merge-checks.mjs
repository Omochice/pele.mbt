// Collects the rows scripts/record-check.mjs wrote in every CI job into one octocov custom
// metric set, so the coverage comment shows the checks as a single table.
// A check whose row is missing still gets one, naming its job's result, because a job that
// failed before its check printed a summary is what the table most needs to show.
//
// Usage: NEEDS=<the workflow's toJSON(needs)> node scripts/merge-checks.mjs <rows dir> <out>

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { CHECKS } from './ci-checks.mjs';

const [rowsDir, out] = process.argv.slice(2);
if (!rowsDir || !out) {
  console.error('usage: node scripts/merge-checks.mjs <rows dir> <out>');
  process.exit(1);
}
const needs = JSON.parse(process.env.NEEDS ?? '{}');

const metrics = CHECKS.map(({ key, name, job }) => {
  const row = join(rowsDir, `${key}.json`);
  if (existsSync(row)) return { key, name, ...JSON.parse(readFileSync(row, 'utf8')) };
  return { key, name, value: 0, unit: ` (no result; ${job} ${needs[job]?.result ?? 'did not run'})` };
});

writeFileSync(out, `${JSON.stringify({ key: 'checks', name: 'Checks', metrics }, null, 2)}\n`);
for (const m of metrics) console.log(`${m.name}: ${m.value}${m.unit}`);
