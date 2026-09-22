///|
test "CLI parses global options and known commands" {
  let invocation = match
    @cli.parse_invocation(["multibase", "--json", "encode"]) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(invocation.command, @cli.Multibase)
  assert_eq(invocation.json, true)
  assert_eq(invocation.args, ["encode"])
}

///|
test "CLI defaults to help and supports explicit version" {
  assert_eq(@cli.run([]).exit_code, 0)
  assert_true(@cli.run([]).stdout.has_prefix("MoonLoom"))
  assert_eq(@cli.run(["version"]).stdout, "moonloom 0.1.0")
}

///|
test "CLI reports unknown commands and options without panicking" {
  let unknown_command = @cli.run(["missing"])
  assert_eq(unknown_command.exit_code, 2)
  assert_true(unknown_command.stderr.has_prefix("moonloom: unknown command"))
  let unknown_option = @cli.run(["--wat"])
  assert_eq(unknown_option.exit_code, 2)
  assert_true(unknown_option.stderr.has_prefix("moonloom: unknown option"))
}

///|
test "CLI reports not-yet-implemented commands deterministically" {
  let result = @cli.run(["cid", "decode", "bafy"])
  assert_eq(result.exit_code, 3)
  assert_eq(result.stdout, "")
  assert_eq(result.stderr, "moonloom: command 'cid' is not implemented yet")
}

///|
test "Multibase CLI encodes, decodes, and emits JSON" {
  assert_eq(@cli.run(["multibase", "encode", "hello"]).stdout, "bnbswy3dp")
  assert_eq(
    @cli.run(["multibase", "encode", "--base", "base16", "hello"]).stdout,
    "f68656c6c6f",
  )
  assert_eq(
    @cli.run(["multibase", "encode", "--json", "hello"]).stdout,
    "{\"base\":\"base32\",\"value\":\"bnbswy3dp\"}",
  )
  assert_eq(@cli.run(["multibase", "decode", "bnbswy3dp"]).stdout, "hello")
  assert_eq(
    @cli.run(["multibase", "decode", "--json", "bnbswy3dp"]).stdout,
    "{\"base\":\"base32\",\"data_base64\":\"aGVsbG8=\"}",
  )
  assert_eq(
    @cli.run(["multibase", "encode", "--base", "invalid", "hello"]).exit_code,
    2,
  )
}

///|
test "Multihash CLI creates, inspects, and verifies values" {
  let digest = @cli.run(["multihash", "digest", "hello"])
  assert_eq(digest.exit_code, 0)
  assert_true(digest.stdout.has_prefix("z"))
  assert_eq(
    @cli.run(["multihash", "inspect", "--json", digest.stdout]).stdout,
    "{\"code\":18,\"algorithm\":\"sha2-256\",\"multihash\":\"" +
    digest.stdout +
    "\",\"digest_base64\":\"LPJNul+wow4m6DsqxbninhsWHlwfp0JecwQzYpOLmCQ=\"}",
  )
  assert_eq(
    @cli.run(["multihash", "verify", digest.stdout, "hello"]).stdout,
    "match",
  )
  assert_eq(
    @cli.run(["multihash", "verify", digest.stdout, "world"]).exit_code,
    1,
  )
  assert_eq(
    @cli.run(["multihash", "verify", "--json", digest.stdout, "world"]).stdout,
    "{\"match\":false}",
  )
}
