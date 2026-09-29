///|
fn cid_help() -> String {
  (
    $|Usage:
    $|  moonloom cid encode [--version 0|1] [--codec <name>] [--algorithm <name>] [--data-format text|base64|hex] <data>
    $|  moonloom cid decode <cid>
    $|  moonloom cid verify [--data-format text|base64|hex] <cid> <data>
    $|
    $|Defaults:
    $|  version=1, codec=raw, algorithm=sha2-256
  )
}

///|
fn cid_failure(err : @moonloom.MoonLoomError) -> CliResult {
  CliResult::failure(1, "moonloom: \{err.to_string()}")
}

///|
fn cid_json(
  value : @moonloom.Cid,
  text : String,
  algorithm_name : String,
) -> String {
  let codec_name = match value.codec_name() {
    Some(name) => name
    None => "unknown"
  }
  "{\"version\":" +
  json_uint64(value.version) +
  ",\"codec\":" +
  json_string(codec_name) +
  ",\"cid\":" +
  json_string(text) +
  ",\"hash_algorithm\":" +
  json_string(algorithm_name) +
  ",\"digest_base64\":" +
  json_string(base64_bytes(value.hash.digest)) +
  "}"
}

///|
fn run_cid_encode(args : ArrayView[String], json : Bool) -> CliResult {
  let parsed = match
    parse_options(args, ["version", "codec", "algorithm", "data-format"]) {
    Ok(value) => value
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let positional = parsed.1
  match require_positional_count(positional, 1, "CID content") {
    Ok(_) => ()
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let version = option_or(parsed.0, "version", "1")
  let codec_name = option_or(parsed.0, "codec", "raw")
  let algorithm_name = option_or(parsed.0, "algorithm", "sha2-256")
  let data_format = option_or(parsed.0, "data-format", "text")
  let data = match content_bytes(positional[0], data_format) {
    Ok(value) => value
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let algorithm = match @moonloom.HashAlgorithm::from_name(algorithm_name) {
    Some(value) => value
    None =>
      return CliResult::failure(
        2,
        "moonloom: \{InvalidValue("--algorithm", algorithm_name).to_string()}",
      )
  }
  let provider = @moonloom.sha2_provider()
  let cid = match version {
    "0" =>
      if codec_name != "dag-pb" {
        return CliResult::failure(
          2,
          "moonloom: \{InvalidValue("--codec", codec_name).to_string()}",
        )
      } else {
        match
          @moonloom.cid_v0_from_content(
            data,
            provider,
            @moonloom.Limits::default(),
          ) {
          Ok(value) => value
          Err(err) => return cid_failure(err)
        }
      }
    "1" => {
      let codec = match @moonloom.multicodec_code(codec_name) {
        Some(value) => value
        None =>
          return CliResult::failure(
            2,
            "moonloom: \{InvalidValue("--codec", codec_name).to_string()}",
          )
      }
      match
        @moonloom.cid_from_content(
          codec,
          algorithm,
          data,
          provider,
          @moonloom.Limits::default(),
        ) {
        Ok(value) => value
        Err(err) => return cid_failure(err)
      }
    }
    _ =>
      return CliResult::failure(
        2,
        "moonloom: \{InvalidValue("--version", version).to_string()}",
      )
  }
  let text = match cid.to_text() {
    Ok(value) => value
    Err(err) => return cid_failure(err)
  }
  if json {
    CliResult::success(cid_json(cid, text, algorithm_name))
  } else {
    CliResult::success(text)
  }
}

///|
fn run_cid_decode(args : ArrayView[String], json : Bool) -> CliResult {
  let parsed = match parse_options(args, []) {
    Ok(value) => value
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let positional = parsed.1
  match require_positional_count(positional, 1, "CID text") {
    Ok(_) => ()
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let value = match
    @moonloom.Cid::parse(positional[0], @moonloom.Limits::default()) {
    Ok(value) => value
    Err(err) => return cid_failure(err)
  }
  let text = match value.to_text() {
    Ok(value) => value
    Err(err) => return cid_failure(err)
  }
  let algorithm_name = match value.hash_algorithm() {
    Some(algorithm) => algorithm.name()
    None => "unknown"
  }
  if json {
    CliResult::success(cid_json(value, text, algorithm_name))
  } else {
    CliResult::success(
      (
        $|version: \{value.version}
        $|codec: \{match value.codec_name() { Some(name) => name; None => "unknown" }}
        $|cid: \{text}
        $|hash_algorithm: \{algorithm_name}
        $|digest_base64: \{base64_bytes(value.hash.digest)}
      ),
    )
  }
}

///|
fn run_cid_verify(args : ArrayView[String], json : Bool) -> CliResult {
  let parsed = match parse_options(args, ["data-format"]) {
    Ok(value) => value
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let positional = parsed.1
  match require_positional_count(positional, 2, "CID and content") {
    Ok(_) => ()
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  let value = match
    @moonloom.Cid::parse(positional[0], @moonloom.Limits::default()) {
    Ok(value) => value
    Err(err) => return cid_failure(err)
  }
  let data_format = option_or(parsed.0, "data-format", "text")
  let data = match content_bytes(positional[1], data_format) {
    Ok(value) => value
    Err(err) => return CliResult::failure(2, "moonloom: \{err.to_string()}")
  }
  match
    value.verify(data, @moonloom.sha2_provider(), @moonloom.Limits::default()) {
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
        CliResult::failure(1, "moonloom: content does not match CID")
      }
    Err(err) => cid_failure(err)
  }
}

///|
pub fn run_cid(invocation : CliInvocation) -> CliResult {
  if invocation.help || invocation.args.is_empty() {
    return CliResult::success(cid_help())
  }
  let action = invocation.args[0]
  let rest = invocation.args[1:]
  match action {
    "encode" => run_cid_encode(rest, invocation.json)
    "decode" => run_cid_decode(rest, invocation.json)
    "verify" => run_cid_verify(rest, invocation.json)
    _ => CliResult::failure(2, "moonloom: unknown cid action '\{action}'")
  }
}
