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
test "Multiaddr CLI parses, encodes, decodes, and emits JSON" {
  assert_eq(
    @cli.run(["multiaddr", "parse", "/ip6/2001:0db8::1/tcp/80"]).stdout,
    "/ip6/2001:db8::1/tcp/80",
  )
  assert_eq(
    @cli.run(["multiaddr", "encode", "/ip4/127.0.0.1/tcp/8080"]).stdout,
    "047f000001061f90",
  )
  assert_eq(
    @cli.run(["multiaddr", "parse", "--json", "/ip4/127.0.0.1/tcp/8080"]).stdout,
    "{\"multiaddr\":\"/ip4/127.0.0.1/tcp/8080\",\"binary_base64\":\"BH8AAAEGH5A=\",\"binary_hex\":\"047f000001061f90\"}",
  )
  assert_eq(
    @cli.run(["multiaddr", "decode", "BH8AAAEGH5A="]).stdout,
    "/ip4/127.0.0.1/tcp/8080",
  )
  assert_eq(
    @cli.run(["multiaddr", "decode", "--format", "hex", "047f000001061f90"]).stdout,
    "/ip4/127.0.0.1/tcp/8080",
  )
  assert_eq(
    @cli.run(["multiaddr", "decode", "--format", "hex", "zz"]).exit_code,
    2,
  )
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

///|
test "CID CLI creates canonical CIDv1 and CIDv0 values" {
  let v1 = @cli.run(["cid", "encode", "hello"])
  assert_eq(v1.exit_code, 0)
  assert_eq(
    v1.stdout,
    "bafkreibm6jg3ux5qumhcn2b3flc3tyu6dmlb4xa7u5bf44yegnrjhc4yeq",
  )
  let v0 = @cli.run([
    "cid", "encode", "--version", "0", "--codec", "dag-pb", "hello",
  ])
  assert_eq(v0.stdout, "QmRN6wdp1S2A5EtjW9A3M1vKSBuQQGcgvuhoMUoEz4iiT5")
  assert_eq(@cli.run(["cid", "encode", "--version", "0", "hello"]).exit_code, 2)
}

///|
test "CID CLI emits structured results and verifies content" {
  let encoded = @cli.run(["cid", "encode", "--json", "hello"])
  assert_eq(
    encoded.stdout,
    "{\"version\":1,\"codec\":\"raw\",\"cid\":\"bafkreibm6jg3ux5qumhcn2b3flc3tyu6dmlb4xa7u5bf44yegnrjhc4yeq\",\"hash_algorithm\":\"sha2-256\",\"digest_base64\":\"LPJNul+wow4m6DsqxbninhsWHlwfp0JecwQzYpOLmCQ=\"}",
  )
  let cid = "bafkreibm6jg3ux5qumhcn2b3flc3tyu6dmlb4xa7u5bf44yegnrjhc4yeq"
  let decoded = @cli.run(["cid", "decode", cid])
  assert_eq(decoded.exit_code, 0)
  assert_true(decoded.stdout.contains("codec: raw"))
  assert_eq(@cli.run(["cid", "verify", cid, "hello"]).stdout, "match")
  assert_eq(@cli.run(["cid", "verify", cid, "world"]).exit_code, 1)
  assert_eq(
    @cli.run(["cid", "verify", "--json", cid, "world"]).stdout,
    "{\"match\":false}",
  )
}
