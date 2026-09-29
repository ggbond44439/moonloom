///|
test "sha2 provider matches the FIPS empty digest" {
  let digest = match @moonloom.sha2_provider().hash(@moonloom.Sha2_256, b"") {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(
    digest, b"\xe3\xb0\xc4\x42\x98\xfc\x1c\x14\x9a\xfb\xf4\xc8\x99\x6f\xb9\x24\x27\xae\x41\xe4\x64\x9b\x93\x4c\xa4\x95\x99\x1b\x78\x52\xb8\x55",
  )
}

///|
test "multihash encodes and decodes sha2-256" {
  let digest = match
    @moonloom.sha2_provider().hash(@moonloom.Sha2_256, b"hello") {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let value = match
    @moonloom.Multihash::create(
      @moonloom.Sha2_256,
      digest,
      @moonloom.Limits::default(),
    ) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let encoded = value.encode()
  assert_eq(encoded[:2], b"\x12\x20")
  match @moonloom.Multihash::decode(encoded, @moonloom.Limits::default()) {
    Ok((decoded, consumed)) => {
      assert_eq(consumed, encoded.length())
      assert_eq(decoded, value)
      assert_eq(decoded.algorithm(), Some(@moonloom.Sha2_256))
    }
    Err(err) => fail(err.to_string())
  }
}

///|
test "identity multihash preserves bytes" {
  let value = match
    @moonloom.Multihash::identity(b"\x00\x01\xff", @moonloom.Limits::default()) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(value.encode(), b"\x00\x03\x00\x01\xff")
  let text = match value.to_text(@moonloom.Base58Btc) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  match @moonloom.Multihash::from_text(text, @moonloom.Limits::default()) {
    Ok(decoded) => assert_eq(decoded, value)
    Err(err) => fail(err.to_string())
  }
}

///|
test "multihash verifies content and rejects mismatch" {
  let value = match
    @moonloom.Multihash::identity(b"hello", @moonloom.Limits::default()) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let provider = @moonloom.sha2_provider()
  assert_eq(
    value.verify(b"hello", provider, @moonloom.Limits::default()),
    Ok(()),
  )
  assert_eq(
    value.verify(b"world", provider, @moonloom.Limits::default()),
    Err(@moonloom.HashMismatch),
  )
}

///|
test "multihash rejects malformed lengths and trailing bytes" {
  assert_eq(
    @moonloom.Multihash::decode(b"\x12", @moonloom.Limits::default()),
    Err(@moonloom.Truncated("multihash digest length", 1)),
  )
  assert_eq(
    @moonloom.Multihash::decode(b"\x12\x20short", @moonloom.Limits::default()),
    Err(@moonloom.Truncated("multihash digest", 2)),
  )
  let value = match
    @moonloom.Multihash::identity(b"a", @moonloom.Limits::default()) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let text = match value.to_text(@moonloom.Base16) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  match
    @moonloom.Multihash::from_text(text + "00", @moonloom.Limits::default()) {
    Ok(_) => fail("expected trailing-byte rejection")
    Err(err) => assert_eq(err, @moonloom.InvalidMultihash("trailing bytes", 3))
  }
}

///|
test "builtin provider matches SHA-3 and BLAKE3 vectors" {
  let provider = @moonloom.builtin_hash_provider()
  let sha3_256 = match provider.hash(@moonloom.Sha3_256, b"abc") {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let sha3_512 = match provider.hash(@moonloom.Sha3_512, b"abc") {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let blake3 = match provider.hash(@moonloom.Blake3, b"abc") {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(
    @moonloom.multibase_encode(@moonloom.Base16, sha3_256),
    Ok("f3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532"),
  )
  assert_eq(
    @moonloom.multibase_encode(@moonloom.Base16, sha3_512),
    Ok(
      "fb751850b1a57168a5693cd924b6b096e08f621827444f70d884f5d0240d2712e10e116e9192af3c91a7ec57647e3934057340b4cf408d5a56592f8274eec53f0",
    ),
  )
  assert_eq(
    @moonloom.multibase_encode(@moonloom.Base16, blake3),
    Ok("f6437b3ac38465133ffb63b75273a8db548c558465d79db03fd359c6cd5bd9d85"),
  )
}

///|
test "extended algorithms carry canonical multicodec identifiers" {
  assert_eq(@moonloom.Sha3_256.code(), 22UL)
  assert_eq(@moonloom.Sha3_512.code(), 20UL)
  assert_eq(@moonloom.Blake3.code(), 30UL)
  assert_eq(
    @moonloom.HashAlgorithm::from_name("sha3-256"),
    Some(@moonloom.Sha3_256),
  )
  assert_eq(@moonloom.HashAlgorithm::from_code(30UL), Some(@moonloom.Blake3))
}
