///|
#cfg(target="js")
extern "js" fn platform_exit(code : Int32) -> Unit =
  #| function(code) {
  #|   if (typeof process !== "undefined" && typeof process.exit === "function") {
  #|     process.exit(code);
  #|   }
  #| }

///|
#cfg(target="js")
fn terminate(code : Int32) -> Unit {
  platform_exit(code)
}
