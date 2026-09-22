///|
pub const CLI_VERSION : String = "0.1.0"

///|
pub(all) enum TopLevelCommand {
  Help
  Version
  Multibase
  Multihash
  Cid
  Multiaddr
} derive(Eq, @debug.Debug)

///|
pub fn TopLevelCommand::name(self : TopLevelCommand) -> String {
  match self {
    Help => "help"
    Version => "version"
    Multibase => "multibase"
    Multihash => "multihash"
    Cid => "cid"
    Multiaddr => "multiaddr"
  }
}

///|
pub(all) struct CliInvocation {
  command : TopLevelCommand
  args : Array[String]
  json : Bool
  help : Bool
} derive(Eq, @debug.Debug)

///|
pub(all) enum CliError {
  UnknownCommand(String)
  UnknownOption(String)
  MissingArgument(String)
  InvalidValue(String, String)
} derive(Eq, @debug.Debug)

///|
pub impl Show for CliError with fn output(self, logger) {
  match self {
    UnknownCommand(name) => logger.write_string("unknown command '\{name}'")
    UnknownOption(name) => logger.write_string("unknown option '\{name}'")
    MissingArgument(name) =>
      logger.write_string("missing argument for '\{name}'")
    InvalidValue(name, value) =>
      logger.write_string("invalid value '\{value}' for '\{name}'")
  }
}

///|
pub(all) struct CliResult {
  exit_code : Int
  stdout : String
  stderr : String
} derive(Eq, @debug.Debug)

///|
pub fn CliResult::success(stdout : String) -> CliResult {
  { exit_code: 0, stdout, stderr: "", }
}

///|
pub fn CliResult::failure(code : Int, stderr : String) -> CliResult {
  { exit_code: code, stdout: "", stderr, }
}

///|
pub fn help_text() -> String {
  (
    $|MoonLoom - self-describing content addressing for MoonBit
    $|
    $|Usage:
    $|  moonloom <command> [options] [arguments]
    $|
    $|Commands:
    $|  multibase   Encode and decode Multibase text
    $|  multihash   Hash and inspect Multihash values
    $|  cid         Create, inspect, and verify CIDs
    $|  multiaddr   Parse and encode Multiaddr values
    $|  version     Print the CLI version
    $|  help        Show this help
    $|
    $|Global options:
    $|  --json      Emit machine-readable output
    $|  --help, -h  Show help
  )
}

///|
pub fn parse_invocation(
  args : ArrayView[String],
) -> Result[CliInvocation, CliError] {
  let positional : Array[String] = []
  let mut json = false
  let mut help = false
  let mut command_seen = false
  for arg in args {
    match arg {
      "--json" => json = true
      "--help" | "-h" => help = true
      _ =>
        if arg.has_prefix("-") && !command_seen {
          return Err(UnknownOption(arg))
        } else {
          positional.push(arg)
          command_seen = true
        }
    }
  }
  if positional.is_empty() {
    return Ok({ command: Help, args: [], json, help, })
  }
  let command_name = positional[0]
  let command = match command_name {
    "help" => Help
    "version" => Version
    "multibase" => Multibase
    "multihash" => Multihash
    "cid" => Cid
    "multiaddr" => Multiaddr
    _ => return Err(UnknownCommand(command_name))
  }
  let rest : Array[String] = Array(capacity=positional.length() - 1)
  for index in 1..<positional.length() {
    rest.push(positional[index])
  }
  Ok({ command, args: rest, json, help, })
}

///|
pub fn run(args : ArrayView[String]) -> CliResult {
  let invocation = match parse_invocation(args) {
    Ok(value) => value
    Err(err) =>
      return CliResult::failure(
        2,
        "moonloom: \{err.to_string()}\n\n" + help_text(),
      )
  }
  match invocation.command {
    Help => CliResult::success(help_text())
    Version => CliResult::success("moonloom " + CLI_VERSION)
    Multibase => run_multibase(invocation)
    Multihash => run_multihash(invocation)
    Cid => run_cid(invocation)
    Multiaddr => run_multiaddr(invocation)
  }
}

///|
pub extend TopLevelCommand with Eq::{not_equal, equal}

///|
pub extend TopLevelCommand with @debug.Debug::{to_repr}

///|
pub extend CliInvocation with Eq::{not_equal, equal}

///|
pub extend CliInvocation with @debug.Debug::{to_repr}

///|
pub extend CliError with Eq::{not_equal, equal}

///|
pub extend CliError with @debug.Debug::{to_repr}

///|
pub extend CliError with Show::{to_string, output}

///|
pub extend CliResult with Eq::{not_equal, equal}

///|
pub extend CliResult with @debug.Debug::{to_repr}
