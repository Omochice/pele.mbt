// Mends the TLSF allocator that moonc 0.10.17 links into a wasm module, which can hand a request
// of 512 MiB or more a smaller free block, so that whatever is written into it overwrites the
// live blocks past it.
// The allocator, ported from AssemblyScript's, rounds a request up to the next size class only
// below 536870910 bytes, because rounding the largest requests up would pass its table of
// classes; above that it searches the request's own class, whose blocks may be up to 32 MiB
// smaller than the request.
// This raises the bound to round below to the highest one whose rounding stays in the table, and
// makes the allocator trap rather than search for anything past it.
// doc/allocator-bug.md shows the failure in a few lines of MoonBit.

/**
 * The bound below which the allocator rounds a request up, and in which the rounding of a block
 * of the top class, up to 2^25 - 1 bytes, still stays below 2^30, its first class past the table.
 */
const ROUNDED_BELOW = 2 ** 30 - 2 ** 25 + 1;

/** The most bytes a request may ask for, which the allocator aligns to a size below `ROUNDED_BELOW`. */
const LARGEST_REQUEST = 2 ** 30 - 2 ** 25 - 4;

const I32_CONST = 0x41;
const I32_LT_U = 0x49;
const I32_GT_U = 0x4b;

function sleb(value) {
  const out = [];
  for (;;) {
    const byte = value & 0x7f;
    value >>= 7;
    if ((value === 0 && !(byte & 0x40)) || (value === -1 && byte & 0x40)) {
      out.push(byte);
      return out;
    }
    out.push(byte | 0x80);
  }
}

function readU32(bytes, at) {
  let value = 0;
  let shift = 0;
  let byte;
  do {
    byte = bytes[at++];
    value |= (byte & 0x7f) << shift;
    shift += 7;
  } while (byte & 0x80);
  return [value >>> 0, at];
}

function codeSection(bytes) {
  let at = 8;
  while (at < bytes.length) {
    const id = bytes[at];
    const [size, start] = readU32(bytes, at + 1);
    if (id === 10) return [start, start + size];
    at = start + size;
  }
  throw new Error('the module has no code section');
}

// Replacements keep the length of each encoding, so no size in the module changes.
const REWRITES = [
  {
    what: 'the bound below which searchBlock and growMemory round a request up',
    from: [I32_CONST, ...sleb(536870910), I32_LT_U],
    to: [I32_CONST, ...sleb(ROUNDED_BELOW), I32_LT_U],
    count: 2,
  },
  {
    what: 'the largest request prepareSize lets through',
    from: [I32_CONST, ...sleb(1073741820), I32_GT_U],
    to: [I32_CONST, ...sleb(LARGEST_REQUEST), I32_GT_U],
    count: 1,
  },
];

function occurrences(bytes, [start, end], pattern) {
  const found = [];
  const needle = Buffer.from(pattern);
  for (let at = bytes.indexOf(needle, start); at >= 0 && at + needle.length <= end; at = bytes.indexOf(needle, at + 1)) {
    found.push(at);
  }
  return found;
}

/**
 * Mends the allocator of a module moonc built.
 * @param {Buffer} bytes the module, which is left as it is.
 * @returns {Buffer} a copy of the module with the allocator mended.
 * @throws {Error} when the module's allocator is not the one this mends, as after a moonc upgrade.
 */
export function fixAllocator(bytes) {
  const out = Buffer.from(bytes);
  const code = codeSection(out);
  for (const { what, from, to, count } of REWRITES) {
    if (from.length !== to.length) throw new Error(`the rewrite of ${what} changes its length`);
    const found = occurrences(out, code, from);
    if (found.length !== count) {
      throw new Error(
        `expected ${what} ${count} times in the plugin's code, found it ${found.length} times; see doc/allocator-bug.md`,
      );
    }
    for (const at of found) out.set(to, at);
  }
  return out;
}
