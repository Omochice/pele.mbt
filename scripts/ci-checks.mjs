// The CI checks whose results the coverage comment tables, in the order of its rows.
// octocov's custom metrics hold a number per row, so each check reads the number that tells
// whether it passed from its log, and puts the rest of its summary into the unit printed after it.

function match(pattern, log) {
  const found = pattern.exec(log);
  return found && found.slice(1).map(Number);
}

function moonCheck(log) {
  if (/^Finished\. /m.test(log)) return { value: 0, unit: ' diagnostics' };
  const counts = match(/^Failed with (\d+) warnings?, (\d+) errors?\./m, log);
  return counts && { value: counts[0] + counts[1], unit: ' diagnostics' };
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

function typst(log) {
  const counts = match(/^(\d+)\/(\d+) passed$/m, log);
  return counts && { value: counts[0], unit: `/${counts[1]}` };
}

/** Reads `git status --porcelain`, which lists one changed file per line. */
function changedFiles(log) {
  return { value: log.split('\n').filter((line) => line.trim() !== '').length, unit: ' files changed' };
}

/**
 * Each check's metric key, which also names its log, the row name, and how its log is read.
 * `parse` returns null when the log holds no summary, as when the check stopped early.
 */
export const CHECKS = [
  { key: 'moon-check', name: 'moon check --deny-warn', parse: moonCheck },
  { key: 'moon-test', name: 'moon test', parse: moonTest },
  { key: 'golden', name: 'check-golden', parse: plugin },
  { key: 'stress', name: 'check-stress', parse: plugin },
  { key: 'fuzz', name: 'fuzz (--count 500)', parse: fuzz },
  { key: 'typst', name: 'typst', parse: typst },
  { key: 'generated', name: 'golden regeneration', parse: changedFiles },
  { key: 'nix-fmt', name: 'nix fmt', parse: changedFiles },
];
