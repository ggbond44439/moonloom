///|
fn multiaddr_help() -> String {
  (
    $|Usage:
    $|  moonloom multiaddr parse <text>
    $|  moonloom multiaddr encode <text>
    $|  moonloom multiaddr decode [--format base64|hex] <data>
    $|
    $|Defaults:
    $|  decode format=base64
  )
}

///|
fn multiaddr_failure(err : @moonloom.MoonLoomError) -> CliResult {
  CliResult::failure(1, "moonloom: \{err.to_string()}")
}

///|
fn multiaddr_json(value : String, bytes : Bytes) -> String {
  "{\"multiaddr\":" +
  json_string(value) +
  ",\"binary_base64\":" +
  json_string(base64_bytes(bytes)) +
  ",\"binary_hex\":" +
  json_string(hex_bytes(bytes)) +
  "}"
}

///|
fn run_multiaddr_parse(args : ArrayView[String], json : Bool) -> CliResult {
  let parsed = match parse_options(args, []) {
    Ok(value) => value
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let positional = parsed.1
  match require_positional_count(positional, 1, "multiaddr text") {
    Ok(_) => ()
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let value = match
    @moonloom.Multiaddr::parse(positional[0], @moonloom.Limits::default()) {
    Ok(value) => value
    Err(err) => return multiaddr_failure(err)
  }
  let text = match value.to_text() {
    Ok(value) => value
    Err(err) => return multiaddr_failure(err)
  }
  let bytes = match value.to_bytes(@moonloom.Limits::default()) {
    Ok(value) => value
    Err(err) => return multiaddr_failure(err)
  }
  if json {
    CliResult::success(multiaddr_json(text, bytes))
  } else {
    CliResult::success(text)
  }
}

///|
fn run_multiaddr_encode(args : ArrayView[String], json : Bool) -> CliResult {
  let parsed = match parse_options(args, []) {
    Ok(value) => value
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let positional = parsed.1
  match require_positional_count(positional, 1, "multiaddr text") {
    Ok(_) => ()
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let value = match
    @moonloom.Multiaddr::parse(positional[0], @moonloom.Limits::default()) {
    Ok(value) => value
    Err(err) => return multiaddr_failure(err)
  }
  let text = match value.to_text() {
    Ok(value) => value
    Err(err) => return multiaddr_failure(err)
  }
  let bytes = match value.to_bytes(@moonloom.Limits::default()) {
    Ok(value) => value
    Err(err) => return multiaddr_failure(err)
  }
  if json {
    CliResult::success(multiaddr_json(text, bytes))
  } else {
    CliResult::success(hex_bytes(bytes))
  }
}

///|
fn decode_multiaddr_input(
  input : String,
  format : String,
) -> Result[Bytes, CliError] {
  match format {
    "base64" => {
      let bytes = @base64.decode(input, ignore_whitespace=false) catch {
        _ => return Err(InvalidValue("--format", format))
      }
      Ok(bytes)
    }
    "hex" =>
      match
        @moonloom.multibase_decode("f" + input, @moonloom.Limits::default()) {
        Ok(value) => Ok(value.data)
        Err(_) => Err(InvalidValue("--format", format))
      }
    _ => Err(InvalidValue("--format", format))
  }
}

///|
fn run_multiaddr_decode(args : ArrayView[String], json : Bool) -> CliResult {
  let parsed = match parse_options(args, ["format"]) {
    Ok(value) => value
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let positional = parsed.1
  match require_positional_count(positional, 1, "multiaddr binary data") {
    Ok(_) => ()
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let format = option_or(parsed.0, "format", "base64")
  let bytes = match decode_multiaddr_input(positional[0], format) {
    Ok(value) => value
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let value = match
    @moonloom.Multiaddr::parse_bytes(bytes, @moonloom.Limits::default()) {
    Ok(value) => value
    Err(err) => return multiaddr_failure(err)
  }
  let text = match value.to_text() {
    Ok(value) => value
    Err(err) => return multiaddr_failure(err)
  }
  if json {
    CliResult::success(multiaddr_json(text, bytes))
  } else {
    CliResult::success(text)
  }
}

///|
pub fn run_multiaddr(invocation : CliInvocation) -> CliResult {
  if invocation.help || invocation.args.is_empty() {
    return CliResult::success(multiaddr_help())
  }
  let action = invocation.args[0]
  let rest = invocation.args[1:]
  match action {
    "parse" => run_multiaddr_parse(rest, invocation.json)
    "encode" => run_multiaddr_encode(rest, invocation.json)
    "decode" => run_multiaddr_decode(rest, invocation.json)
    _ => CliResult::failure(2, "moonloom: unknown multiaddr action '\{action}'")
  }
}
