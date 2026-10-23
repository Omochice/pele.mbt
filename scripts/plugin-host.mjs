// Hosts the wasm plugin the way typst does, through the wasm-minimal-protocol.

import { existsSync, readFileSync } from 'node:fs';

/**
 * Compiles the plugin and checks that it needs nothing typst does not provide.
 * @param {string} wasmPath
 * @returns {{ call: (source: Buffer, optionBytes: Buffer) => { code: number, result: string } }}
 *   `call` gives the plugin's status code and result text, and throws when the plugin traps.
 * @throws {Error} when the plugin is not built or imports more than typst_env.
 */
export function loadPlugin(wasmPath) {
  if (!existsSync(wasmPath)) throw new Error(`missing ${wasmPath}; run \`moon build --target wasm --release\` first`);
  const module = new WebAssembly.Module(readFileSync(wasmPath));
  const foreign = WebAssembly.Module.imports(module).filter((i) => i.module !== 'typst_env');
  if (foreign.length > 0) throw new Error(`the plugin imports more than typst_env: ${JSON.stringify(foreign)}`);

  // A fresh instance per call, because a trapped instance is left in an undefined state.
  function call(source, optionBytes) {
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
    const code = instance.exports.render(source.length, optionBytes.length);
    return { code, result };
  }

  return { call };
}
