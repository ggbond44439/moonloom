///|
fn multibase_help() -> String {
  (
    $|Usage:
    $|  moonloom multibase encode [--base <name>] <text>
    $|  moonloom multibase decode <multibase-text>
    $|
    $|Supported bases:
    $|  base16, base16upper, base32, base32upper, base32pad,
    $|  base32padupper, base58btc, base64, base64pad, base64url, base64urlpad
  )
}

///|
fn run_multibase_encode(args : ArrayView[String], json : Bool) -> CliResult {
  let parsed = match parse_options(args, ["base"]) {
    Ok(value) => value
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let options = parsed.0
  let positional = parsed.1
  match require_positional_count(positional, 1, "multibase encode data") {
    Ok(_) => ()
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let base_name = option_or(options, "base", "base32")
  let base = match @moonloom.Base::from_name(base_name) {
    Some(value) => value
    None =>
      return CliResult::failure(
        2,
        "moonloom: \{InvalidValue("--base", base_name).to_string()}",
      )
  }
  let data = @utf8.encode(positional[0])
  match @moonloom.multibase_encode(base, data) {
    Ok(value) =>
      if json {
        CliResult::success(
          "{\"base\":" +
          json_string(base.name()) +
          ",\"value\":" +
          json_string(value) +
          "}",
        )
      } else {
        CliResult::success(value)
      }
    Err(err) => CliResult::failure(1, "moonloom: \{err.to_string()}")
  }
}

///|
fn run_multibase_decode(args : ArrayView[String], json : Bool) -> CliResult {
  let parsed = match parse_options(args, []) {
    Ok(value) => value
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let positional = parsed.1
  match require_positional_count(positional, 1, "multibase decode text") {
    Ok(_) => ()
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let decoded = match
    @moonloom.multibase_decode(positional[0], @moonloom.Limits::default()) {
    Ok(value) => value
    Err(err) => return CliResult::failure(1, "moonloom: \{err.to_string()}")
  }
  if json {
    CliResult::success(
      "{\"base\":" +
      json_string(decoded.base.name()) +
      ",\"data_base64\":" +
      json_string(base64_bytes(decoded.data)) +
      "}",
    )
  } else {
    let plain = @utf8.decode(decoded.data) catch {
      _ => hex_bytes(decoded.data)
    }
    CliResult::success(plain)
  }
}

///|
pub fn run_multibase(invocation : CliInvocation) -> CliResult {
  if invocation.help || invocation.args.is_empty() {
    return CliResult::success(multibase_help())
  }
  let action = invocation.args[0]
  let rest = invocation.args[1:]
  match action {
    "encode" => run_multibase_encode(rest, invocation.json)
    "decode" => run_multibase_decode(rest, invocation.json)
    _ => CliResult::failure(2, "moonloom: unknown multibase action '\{action}'")
  }
}
