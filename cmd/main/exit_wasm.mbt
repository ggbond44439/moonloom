///|
#cfg(any(target="wasm", target="wasm-gc"))
fn platform_exit(code : Int32) -> Unit = "__moonbit_sys_unstable" "exit"

///|
#cfg(any(target="wasm", target="wasm-gc"))
fn terminate(code : Int32) -> Unit {
  platform_exit(code)
}
