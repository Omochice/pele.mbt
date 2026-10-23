// Hosts the wasm plugin the way typst does, through the wasm-minimal-protocol.

import { existsSync, readFileSync } from 'node:fs';
import { countCallDepth } from './call-depth.mjs';

/**
 * Compiles the plugin and checks that it needs nothing typst does not provide.
 * @param {string} wasmPath
 * @param {{ callDepthLimit?: number }} [options] with `callDepthLimit`, the plugin traps past that
 *   many call frames as it would in typst, and each call reports the deepest it went.
 * @returns {{ call: (source: Buffer, optionBytes: Buffer) => { code: number, result: string, bytes: Buffer, memory: number, depth?: number } }}
 *   `call` gives the status code and result text of the `render` export, or of the export named by its third argument, and throws when the plugin traps.
 *   The result is also given as its bytes, which is the only form of an answer longer than V8's longest string, and the text is decoded from them when it is first read.
 *   `memory` is the size the plugin's memory grew to, which is the most it held at once, as wasm memory never shrinks.
 *   `exported` lists the names the plugin exports.
 * @throws {Error} when the plugin is not built or imports more than typst_env.
 */
export function loadPlugin(wasmPath, { callDepthLimit } = {}) {
  if (!existsSync(wasmPath)) throw new Error(`missing ${wasmPath}; run \`moon build --target wasm --release\` first`);
  let bytes = readFileSync(wasmPath);
  if (callDepthLimit !== undefined) bytes = countCallDepth(bytes, callDepthLimit);
  const module = new WebAssembly.Module(bytes);
  const foreign = WebAssembly.Module.imports(module).filter((i) => i.module !== 'typst_env');
  if (foreign.length > 0) throw new Error(`the plugin imports more than typst_env: ${JSON.stringify(foreign)}`);

  // A fresh instance per call, because a trapped instance is left in an undefined state.
  function call(source, optionBytes, entry = 'render') {
    const args = Buffer.concat([source, optionBytes]);
    let instance;
    let bytes;
    const memory = () => new Uint8Array(instance.exports.memory.buffer);
    // An i32 reaches JavaScript signed, so an address past 2 GiB arrives negative and has to be read
    // back as the unsigned offset typst takes it for.
    instance = new WebAssembly.Instance(module, {
      typst_env: {
        wasm_minimal_protocol_write_args_to_buffer: (ptr) => memory().set(args, ptr >>> 0),
        wasm_minimal_protocol_send_result_to_host: (ptr, len) => {
          bytes = Buffer.from(memory().slice(ptr >>> 0, (ptr >>> 0) + (len >>> 0)));
        },
      },
    });
    const code = instance.exports[entry](source.length, optionBytes.length);
    let result;
    return {
      code,
      bytes,
      get result() {
        result ??= bytes.toString('utf8');
        return result;
      },
      memory: instance.exports.memory.buffer.byteLength,
      depth: instance.exports.call_depth_max?.value,
    };
  }

  return { call, exported: WebAssembly.Module.exports(module).map((e) => e.name) };
}
