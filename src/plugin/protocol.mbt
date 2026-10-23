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
  answer(source_len, options_len)
}

///|
/// Renders as `render` does, but returns 0 for a failure too, with the same JSON `error` object.
/// typst cannot catch a plugin's error, so a caller that wants to report the failure itself reads it from here.
pub fn try_render(source_len : Int32, options_len : Int32) -> Int32 {
  ignore(answer(source_len, options_len))
  0
}

///|
/// Reads the host's arguments, sends it the JSON response and returns the response's status.
fn answer(source_len : Int32, options_len : Int32) -> Int32 {
  let args = Bytes::make(source_len + options_len, 0)
  write_args(bytes_addr(args))
  let source = @utf8.decode_lossy(args[0:source_len])
  let options = @utf8.decode_lossy(args[source_len:source_len + options_len])
  let (status, body) = respond(source, options)
  let out = @utf8.encode(body.stringify())
  sent.val = out
  send_result(bytes_addr(out), out.length())
  status
}

///|
/// The last result sent to the host.
/// Without a reference past the call, `out` is freed between taking its address and the host reading it, and the allocator's bookkeeping overwrites its last bytes.
let sent : Ref[Bytes] = { val: b"", }
