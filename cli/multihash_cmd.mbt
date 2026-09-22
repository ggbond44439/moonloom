///|
fn multihash_help() -> String {
  (
    $|Usage:
    $|  moonloom multihash digest [--algorithm sha2-256|sha2-512] <text>
    $|  moonloom multihash inspect <multibase-multihash>
    $|  moonloom multihash verify <multibase-multihash> <text>
  )
}

///|
fn multihash_error(err : @moonloom.MoonLoomError) -> CliResult {
  CliResult::failure(1, "moonloom: \{err.to_string()}")
}

///|
fn multihash_digest(
  data : String,
  algorithm_name : String,
) -> Result[@moonloom.Multihash, @moonloom.MoonLoomError] {
  let algorithm = match @moonloom.HashAlgorithm::from_name(algorithm_name) {
    Some(value) => value
    None => return Err(@moonloom.UnsupportedHashAlgorithm(algorithm_name))
  }
  let provider = @moonloom.sha2_provider()
  match provider.hash(algorithm, @utf8.encode(data)) {
    Ok(digest) =>
      @moonloom.Multihash::create(
        algorithm,
        digest,
        @moonloom.Limits::default(),
      )
    Err(err) => Err(err)
  }
}

///|
fn run_multihash_digest(args : ArrayView[String], json : Bool) -> CliResult {
  let parsed = match parse_options(args, ["algorithm"]) {
    Ok(value) => value
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let positional = parsed.1
  match require_positional_count(positional, 1, "multihash digest data") {
    Ok(_) => ()
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let algorithm_name = option_or(parsed.0, "algorithm", "sha2-256")
  let value = match multihash_digest(positional[0], algorithm_name) {
    Ok(value) => value
    Err(err) => return multihash_error(err)
  }
  let text = match value.to_text_canonical() {
    Ok(value) => value
    Err(err) => return multihash_error(err)
  }
  if json {
    CliResult::success(
      "{\"algorithm\":" +
      json_string(algorithm_name) +
      ",\"multihash\":" +
      json_string(text) +
      ",\"digest_base64\":" +
      json_string(base64_bytes(value.digest)) +
      "}",
    )
  } else {
    CliResult::success(text)
  }
}

///|
fn run_multihash_inspect(args : ArrayView[String], json : Bool) -> CliResult {
  let parsed = match parse_options(args, []) {
    Ok(value) => value
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let positional = parsed.1
  match require_positional_count(positional, 1, "multihash text") {
    Ok(_) => ()
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let value = match
    @moonloom.Multihash::from_text(positional[0], @moonloom.Limits::default()) {
    Ok(value) => value
    Err(err) => return multihash_error(err)
  }
  let text = match value.to_text_canonical() {
    Ok(value) => value
    Err(err) => return multihash_error(err)
  }
  let algorithm_name = match value.algorithm() {
    Some(algorithm) => algorithm.name()
    None => "unknown"
  }
  if json {
    CliResult::success(
      "{\"code\":" +
      json_uint64(value.code) +
      ",\"algorithm\":" +
      json_string(algorithm_name) +
      ",\"multihash\":" +
      json_string(text) +
      ",\"digest_base64\":" +
      json_string(base64_bytes(value.digest)) +
      "}",
    )
  } else {
    CliResult::success(
      (
        $|algorithm: \{algorithm_name}
        $|code: \{value.code}
        $|multihash: \{text}
        $|digest_base64: \{base64_bytes(value.digest)}
      ),
    )
  }
}

///|
fn run_multihash_verify(args : ArrayView[String], json : Bool) -> CliResult {
  let parsed = match parse_options(args, []) {
    Ok(value) => value
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let positional = parsed.1
  match require_positional_count(positional, 2, "multihash and data") {
    Ok(_) => ()
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let value = match
    @moonloom.Multihash::from_text(positional[0], @moonloom.Limits::default()) {
    Ok(value) => value
    Err(err) => return multihash_error(err)
  }
  match
    value.verify(
      @utf8.encode(positional[1]),
      @moonloom.sha2_provider(),
      @moonloom.Limits::default(),
    ) {
    Ok(_) =>
      if json {
        CliResult::success("{\"match\":" + json_bool(true) + "}")
      } else {
        CliResult::success("match")
      }
    Err(@moonloom.HashMismatch) =>
      if json {
        {
          exit_code: 1,
          stdout: "{\"match\":" + json_bool(false) + "}",
          stderr: "",
        }
      } else {
        CliResult::failure(1, "moonloom: hash mismatch")
      }
    Err(err) => multihash_error(err)
  }
}

///|
pub fn run_multihash(invocation : CliInvocation) -> CliResult {
  if invocation.help || invocation.args.is_empty() {
    return CliResult::success(multihash_help())
  }
  let action = invocation.args[0]
  let rest = invocation.args[1:]
  match action {
    "digest" => run_multihash_digest(rest, invocation.json)
    "inspect" => run_multihash_inspect(rest, invocation.json)
    "verify" => run_multihash_verify(rest, invocation.json)
    _ => CliResult::failure(2, "moonloom: unknown multihash action '\{action}'")
  }
}
