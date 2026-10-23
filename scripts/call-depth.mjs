// Rewrites a wasm module so that it counts its own call depth, the way typst's interpreter does,
// and traps past a limit. V8 allows wasm a far deeper stack, so without this a plugin that would
// exhaust typst's call stack runs fine under node.
//
// Each defined function keeps its index but becomes a wrapper that raises the depth, traps past
// the limit, calls the original body (moved to a new index) and lowers the depth again. Calls,
// exports, tables and the start function all reach the wrappers without being touched.

/**
 * The most nested calls typst 0.15's interpreter runs in a plugin, counting the exported function:
 * a probe that recursed 998 times below its export ran, and one that recursed 999 times trapped.
 */
export const TYPST_CALL_DEPTH = 1000;

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

function u32(value) {
  const out = [];
  do {
    let byte = value & 0x7f;
    value >>>= 7;
    if (value !== 0) byte |= 0x80;
    out.push(byte);
  } while (value !== 0);
  return out;
}

// Pieces are byte arrays or buffers; a module is too large to spread into one array.
function section(id, ...pieces) {
  const body = Buffer.concat(pieces.map((piece) => Buffer.from(piece)));
  return Buffer.concat([Buffer.from([id, ...u32(body.length)]), body]);
}

function sections(bytes) {
  const list = [];
  let at = 8;
  while (at < bytes.length) {
    const id = bytes[at];
    const [size, start] = readU32(bytes, at + 1);
    list.push({ id, body: bytes.subarray(start, start + size) });
    at = start + size;
  }
  return list;
}

function paramCounts(body) {
  const counts = [];
  let [count, at] = readU32(body, 0);
  for (let i = 0; i < count; i++) {
    if (body[at] !== 0x60) throw new Error('only plain function types are supported');
    let params;
    [params, at] = readU32(body, at + 1);
    counts.push(params);
    at += params;
    let results;
    [results, at] = readU32(body, at);
    at += results;
  }
  return counts;
}

function skipLimits(body, at) {
  const flags = body[at];
  [, at] = readU32(body, at + 1);
  if (flags & 1) [, at] = readU32(body, at);
  return at;
}

function importCounts(body) {
  let functions = 0;
  let globals = 0;
  let [count, at] = readU32(body, 0);
  for (let i = 0; i < count; i++) {
    for (let name = 0; name < 2; name++) {
      let length;
      [length, at] = readU32(body, at);
      at += length;
    }
    const kind = body[at++];
    if (kind === 0) {
      functions++;
      [, at] = readU32(body, at);
    } else if (kind === 1) at = skipLimits(body, at + 1);
    else if (kind === 2) at = skipLimits(body, at);
    else if (kind === 3) {
      globals++;
      at += 2;
    } else throw new Error(`unsupported import kind ${kind}`);
  }
  return { functions, globals };
}

const I32 = 0x7f;

/**
 * Rewrites the module bytes to count call depth.
 * @param {Uint8Array} bytes a wasm module without GC types or tail calls
 * @param {number} limit the most frames a call may stack up, counting the export called
 * @returns {Uint8Array} a module that traps with `unreachable` past `limit` frames and exports the
 *   deepest depth reached as the mutable global `call_depth_max`
 * @throws {Error} when the module uses a construct this rewrite does not handle
 */
export function countCallDepth(bytes, limit) {
  const list = sections(bytes);
  const find = (id) => list.find((s) => s.id === id);
  const params = paramCounts(find(1).body);
  const imported = find(2) ? importCounts(find(2).body) : { functions: 0, globals: 0 };
  const [defined, typesAt] = readU32(find(3).body, 0);
  const typeOf = [];
  for (let i = 0, at = typesAt; i < defined; i++) {
    let type;
    [type, at] = readU32(find(3).body, at);
    typeOf.push(type);
  }
  const definedGlobals = find(6) ? readU32(find(6).body, 0)[0] : 0;
  const depth = imported.globals + definedGlobals;
  const deepest = depth + 1;

  const wrappers = typeOf.map((type, i) => {
    const inner = imported.functions + defined + i;
    const raise = [0x23, ...u32(depth), 0x41, 1, 0x6a, 0x24, ...u32(depth)];
    const record = [0x23, ...u32(depth), 0x23, ...u32(deepest), 0x4b, 0x04, 0x40, 0x23, ...u32(depth), 0x24, ...u32(deepest), 0x0b];
    const guard = [0x23, ...u32(depth), 0x41, ...signed(limit), 0x4b, 0x04, 0x40, 0x00, 0x0b];
    const forward = Array.from({ length: params[type] }, (_, p) => [0x20, ...u32(p)]).flat();
    const lower = [0x23, ...u32(depth), 0x41, 1, 0x6b, 0x24, ...u32(depth)];
    const body = [0, ...raise, ...record, ...guard, ...forward, 0x10, ...u32(inner), ...lower, 0x0b];
    return [...u32(body.length), ...body];
  });

  const [, codeAt] = readU32(find(10).body, 0);
  const originals = find(10).body.subarray(codeAt);
  const counter = [I32, 1, 0x41, 0, 0x0b];

  const out = [bytes.subarray(0, 8)];
  let globalsWritten = false;
  const writeGlobals = () => {
    if (globalsWritten) return;
    globalsWritten = true;
    const old = find(6);
    const rest = old ? old.body.subarray(readU32(old.body, 0)[1]) : [];
    out.push(section(6, u32(definedGlobals + 2), rest, counter, counter));
  };
  for (const { id, body } of list) {
    if (id === 3) out.push(section(3, u32(defined * 2), typeOf.flatMap(u32), typeOf.flatMap(u32)));
    else if (id === 6) writeGlobals();
    else if (id === 7) {
      if (!find(6)) writeGlobals();
      const [count, at] = readU32(body, 0);
      const name = Buffer.from('call_depth_max');
      out.push(section(7, u32(count + 1), body.subarray(at), u32(name.length), name, [3, ...u32(deepest)]));
    } else if (id === 10) out.push(section(10, u32(defined * 2), wrappers.flat(), originals));
    else out.push(section(id, body));
  }
  return new Uint8Array(Buffer.concat(out));
}

function signed(value) {
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
