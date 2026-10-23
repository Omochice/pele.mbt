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
  // pele draws this between the port's hold limit and V8's longest string, so the port returns its
  // own limit error: the one intentional, platform-imposed difference from pele.
  [
    'flowchart',
    'edges pele draws past the port but under V8',
    `graph LR\nclassDef c ${fill}\n${names('n', 10600).map((name) => `${name}:::c`).join('-->')}\n`,
    { ...RAISED, maxEdges: 1000000000, maxWidth: 300 },
  ],
  ['swimlane', 'styled nodes in a lane', `swimlane-beta TB\nclassDef c ${fill}\nsubgraph L\n${names('n', 10700).map((name) => `${name}:::c`).join('\n')}\nend\n`, RAISED],
  ['class', 'styled classes', `classDiagram\nclassDef c ${fill}\n${names('C', 10700).map((name) => `class ${name}:::c`).join('\n')}\n`, RAISED],
  ['state', 'styled states', `stateDiagram-v2\nclassDef c ${fill}\n${names('S', 10700).map((name) => `[*] --> ${name}:::c`).join('\n')}\n`, RAISED],
  ['er', 'styled entities', `erDiagram\nclassDef c ${fill}\n${names('E', 10700).map((name) => `${name}:::c {}`).join('\n')}\n`, RAISED],
  ['block', 'styled blocks', `block-beta\nclassDef c ${fill};\n${names('B', 10700).map((name) => `${name}\nclass ${name} c`).join('\n')}\n`, RAISED],
  ['agentflow', 'styled agents', `agentflow-beta TB\nclassDef c ${fill}\n${names('a', 10700).map((name) => `${name}:::c`).join('\n')}\n`, RAISED],
  ['requirement', 'styled elements', `requirementDiagram\nclassDef c ${fill}\n${names('e', 10700).map((name) => `element ${name}:::c {\n}`).join('\n')}\n`, RAISED],
  // Leaves too small to draw are left out, so the fill is longer than elsewhere rather than the leaves more.
  ['treemap', 'styled leaves', `treemap-beta\n${names('L', 9000).map((name) => `"${name}": 1:::cc`).join('\n')}\nclassDef cc fill:#${'a'.repeat(60000)};\n`, RAISED],
  ['usecase', 'styled use cases', `usecase-beta\nclassDef c ${fill}\n${names('U', 10700).map((name) => `${name}("x"):::c`).join('\n')}\n`, RAISED],
];
