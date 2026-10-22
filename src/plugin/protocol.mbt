///|
fn write_args(ptr : Int32) = "typst_env" "wasm_minimal_protocol_write_args_to_buffer"

///|
fn send_result(ptr : Int32, len : Int32) = "typst_env" "wasm_minimal_protocol_send_result_to_host"

///|
#borrow(b)
extern "wasm" fn bytes_addr(b : Bytes) -> Int32 =
  #|(func (param i32) (result i32) (local.get 0))

///|
/// Renders Mermaid text for typst, following the wasm-minimal-protocol.
/// The arguments are the UTF-8 Mermaid source and a JSON object of pele's render options.
/// Returns 0 with a JSON result, or 1 with a JSON `error` object in pele's shape.
pub fn render(source_len : Int32, options_len : Int32) -> Int32 {
  let args = Bytes::make(source_len + options_len, 0)
  write_args(bytes_addr(args))
  let source = @utf8.decode_lossy(args[0:source_len])
  let options = @utf8.decode_lossy(args[source_len:source_len + options_len])
  let (status, body) = respond(source, options)
  let out = @utf8.encode(body.stringify())
  send_result(bytes_addr(out), out.length())
  status
}
