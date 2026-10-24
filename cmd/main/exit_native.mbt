///|
#cfg(any(target="native", target="llvm"))
extern "c" fn platform_exit(code : Int32) = "exit"

///|
#cfg(any(target="native", target="llvm"))
fn terminate(code : Int32) -> Unit {
  platform_exit(code)
}
