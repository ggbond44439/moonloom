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
test "CLI command skeleton reports implementation status deterministically" {
  let result = @cli.run(["cid", "decode", "bafy"])
  assert_eq(result.exit_code, 3)
  assert_eq(result.stdout, "")
  assert_eq(result.stderr, "moonloom: command 'cid' is not implemented yet")
}
