// Hosts the wasm plugin the way typst does, through the wasm-minimal-protocol.

import { existsSync, readFileSync } from 'node:fs';
import { countCallDepth } from './call-depth.mjs';

/**
 * Compiles the plugin and checks that it needs nothing typst does not provide.
 * @param {string} wasmPath
 * @param {{ callDepthLimit?: number }} [options] with `callDepthLimit`, the plugin traps past that
 *   many call frames as it would in typst, and each call reports the deepest it went.
 * @returns {{ call: (source: Buffer, optionBytes: Buffer) => { code: number, result: string, depth?: number } }}
 *   `call` gives the status code and result text of the `render` export, or of the export named by its third argument, and throws when the plugin traps.
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
    let result;
    const memory = () => new Uint8Array(instance.exports.memory.buffer);
    instance = new WebAssembly.Instance(module, {
      typst_env: {
        wasm_minimal_protocol_write_args_to_buffer: (ptr) => memory().set(args, ptr),
        wasm_minimal_protocol_send_result_to_host: (ptr, len) => {
          result = Buffer.from(memory().slice(ptr, ptr + len)).toString('utf8');
        },
      },
    });
    const code = instance.exports[entry](source.length, optionBytes.length);
    return { code, result, depth: instance.exports.call_depth_max?.value };
  }

  return { call, exported: WebAssembly.Module.exports(module).map((e) => e.name) };
}
