// The inputs scripts/check-string-length.mjs renders, as [diagram, name, source, options].
// Each diagram that can repeat a long string many times has a source just past V8's longest
// string, the same as its skipped test in src/diagrams/<diagram>/string_length_test.mbt.
// The diagrams missing here cannot: README.md under golden/ says why for each.

const names = (prefix, count) => Array.from({ length: count }, (_, i) => `${prefix}${i}`);
const fill = `fill:#${'a'.repeat(50000)}`;
export const RAISED = { limit: Number.MAX_VALUE, outputLimit: Number.MAX_VALUE };

export const CASES = [
  [
    'flowchart',
    'edges under the default options',
    `graph TD\nlinkStyle default stroke:#${'a'.repeat(49000)}\n${names('a', 60).join(' & ')} <--> ${names('b', 61).join(' & ')}\n`,
    {},
  ],
  ['flowchart', 'nodes', `graph TD\nclassDef c ${fill}\n${names('n', 10700).map((name) => `${name}:::c`).join(';')}\n`, RAISED],
  [
    'flowchart',
    'nodes and edges only together',
    `graph TD\nclassDef default ${fill}\nlinkStyle default stroke:#${'a'.repeat(50000)}\n${names('n', 3600).join('-->')}\n`,
    RAISED,
  ],
  [
    'flowchart',
    'nodes drawn past what a doubling StringBuilder holds',
    `graph TD\nclassDef c ${fill}\n${names('n', 6000).map((name) => `${name}:::c`).join(';')}\n`,
    RAISED,
  ],
  ['class', 'styled classes', `classDiagram\nclassDef c ${fill}\n${names('C', 10700).map((name) => `class ${name}:::c`).join('\n')}\n`, RAISED],
];
