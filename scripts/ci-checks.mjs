// The CI checks whose results the coverage comment tables, in the order of its rows.
// octocov's custom metrics hold a number per row, so each check reads the number that tells
// whether it passed from its log, and puts the rest of its summary into the unit printed after it.

function match(pattern, log) {
  const found = pattern.exec(log);
  return found && found.slice(1).map(Number);
}

function moonTest(log) {
  const counts = match(/^Total tests: (\d+), passed: (\d+), failed: (\d+)\./m, log);
  return counts && { value: counts[1], unit: `/${counts[0]}` };
}

function plugin(log) {
  const counts = match(/^total (\d+)\/(\d+) passed, (\d+) failed, (\d+) trapped$/m, log);
  return counts && { value: counts[0], unit: `/${counts[1]}, ${counts[3]} trapped` };
}

function fuzz(log) {
  const counts = match(/^total (\d+) cases, (\d+) mismatched/m, log);
  return counts && { value: counts[0], unit: ` cases, ${counts[1]} mismatched` };
}

/**
 * Each check's metric key, which also names its log, the row name, and how its log is read.
 * `parse` returns null when the log holds no summary, as when the check stopped early.
 */
export const CHECKS = [
  { key: 'moon-test', name: 'moon test', parse: moonTest },
  { key: 'golden', name: 'check-golden', parse: plugin },
  { key: 'stress', name: 'check-stress', parse: plugin },
  { key: 'fuzz', name: 'fuzz (--count 500)', parse: fuzz },
];
