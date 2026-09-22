///|
fn main {
  let raw_args = @env.args()
  let args : Array[String] = []
  for index in 1..<raw_args.length() {
    args.push(raw_args[index])
  }
  let result = @cli.run(args)
  if result.stdout != "" {
    println(result.stdout)
  }
  if result.stderr != "" {
    eprintln(result.stderr)
  }
  if result.exit_code != 0 {
    panic()
  }
}
