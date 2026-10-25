///|
test "CIDv0 matches the empty SHA-256 multihash vector" {
  let cid = match
    @moonloom.cid_v0_from_content(
      b"",
      @moonloom.sha2_provider(),
      @moonloom.Limits::default(),
    ) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(cid.version, 0UL)
  assert_eq(cid.codec, @moonloom.DAG_PB_CODEC)
  assert_eq(cid.to_text(), Ok("QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"))
  match
    @moonloom.Cid::parse(
      "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n",
      @moonloom.Limits::default(),
    ) {
    Ok(decoded) => assert_eq(decoded, cid)
    Err(err) => fail(err.to_string())
  }
}

///|
test "CIDv1 raw and dag-pb match standard base32 forms" {
  let raw = match
    @moonloom.cid_from_content(
      85UL,
      @moonloom.Sha2_256,
      b"",
      @moonloom.sha2_provider(),
      @moonloom.Limits::default(),
    ) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(
    raw.to_text(),
    Ok("bafkreihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetojuzjevtenxquvyku"),
  )
  let dag_pb = match
    @moonloom.cid_from_content(
      @moonloom.DAG_PB_CODEC,
      @moonloom.Sha2_256,
      b"",
      @moonloom.sha2_provider(),
      @moonloom.Limits::default(),
    ) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(
    dag_pb.to_text(),
    Ok("bafybeihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetojuzjevtenxquvyku"),
  )
}

///|
test "CID text and binary round trip" {
  let original = match
    @moonloom.cid_from_content(
      85UL,
      @moonloom.Sha2_256,
      b"hello",
      @moonloom.sha2_provider(),
      @moonloom.Limits::default(),
    ) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let text = match original.to_text() {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(text, "bafkreibm6jg3ux5qumhcn2b3flc3tyu6dmlb4xa7u5bf44yegnrjhc4yeq")
  match @moonloom.Cid::parse(text, @moonloom.Limits::default()) {
    Ok(decoded) => assert_eq(decoded, original)
    Err(err) => fail(err.to_string())
  }
  let bytes = original.to_bytes()
  match @moonloom.Cid::decode_bytes(bytes, @moonloom.Limits::default()) {
    Ok(decoded) => assert_eq(decoded, original)
    Err(err) => fail(err.to_string())
  }
}

///|
test "CID versions convert without changing identity" {
  let limits = @moonloom.Limits::default()
  let v0 = match
    @moonloom.cid_v0_from_content(b"hello", @moonloom.sha2_provider(), limits) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let v1 = match v0.to_v1(limits) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(v1.version, 1UL)
  assert_eq(v1.codec, @moonloom.DAG_PB_CODEC)
  assert_eq(v1.hash, v0.hash)
  assert_eq(
    v1.to_text(),
    Ok("bafybeibm6jg3ux5qumhcn2b3flc3tyu6dmlb4xa7u5bf44yegnrjhc4yeq"),
  )
  let downgraded = match v1.to_v0(limits) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(downgraded, v0)
  assert_eq(v0.to_v1(limits), Ok(v1))
  assert_eq(v1.to_v0(limits), Ok(v0))
}

///|
test "CIDv1 text supports every multibase spelling" {
  let limits = @moonloom.Limits::default()
  let v0 = match
    @moonloom.cid_v0_from_content(b"hello", @moonloom.sha2_provider(), limits) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let v1 = match v0.to_v1(limits) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(
    v1.to_text_with_base(@moonloom.Base36),
    Ok("k2jmtxshftbvrdof1z3qg5p2h3ikoogqns7mwkrp24dbii8uaksgjg2s"),
  )
  let base58 = match v1.to_text_with_base(@moonloom.Base58Btc) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_true(base58.has_prefix("z"))
  match @moonloom.Cid::parse(base58, limits) {
    Ok(decoded) => assert_eq(decoded, v1)
    Err(err) => fail(err.to_string())
  }
  assert_eq(
    v0.to_text_with_base(@moonloom.Base32),
    Err(@moonloom.InvalidCid("CIDv0 text must use base58btc", 0)),
  )
}

///|
test "CIDv0 downgrade rejects incompatible codecs and hashes" {
  let limits = @moonloom.Limits::default()
  let raw = match
    @moonloom.cid_from_content(
      @moonloom.RAW_CODEC,
      @moonloom.Sha2_256,
      b"hello",
      @moonloom.sha2_provider(),
      limits,
    ) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(raw.to_v0(limits), Err(@moonloom.CidCodecMismatch(85UL)))

  let sha512 = match
    @moonloom.cid_from_content(
      @moonloom.DAG_PB_CODEC,
      @moonloom.Sha2_512,
      b"hello",
      @moonloom.sha2_provider(),
      limits,
    ) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(
    sha512.to_v0(limits),
    Err(@moonloom.UnsupportedHashAlgorithm("CIDv0 requires sha2-256")),
  )
}

///|
test "CID verifies content and rejects a mismatch" {
  let cid = match
    @moonloom.cid_from_content(
      @moonloom.DAG_PB_CODEC,
      @moonloom.Sha2_256,
      b"hello",
      @moonloom.sha2_provider(),
      @moonloom.Limits::default(),
    ) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let provider = @moonloom.sha2_provider()
  assert_eq(cid.verify(b"hello", provider, @moonloom.Limits::default()), Ok(()))
  assert_eq(
    cid.verify(b"world", provider, @moonloom.Limits::default()),
    Err(@moonloom.HashMismatch),
  )
}

///|
test "CID constructors enforce version-specific rules" {
  let hash = match
    @moonloom.Multihash::identity(b"x", @moonloom.Limits::default()) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(
    @moonloom.Cid::v1(0UL, hash, @moonloom.Limits::default()),
    Err(@moonloom.InvalidCodec(0UL)),
  )
  assert_eq(
    @moonloom.Cid::v0(hash, @moonloom.Limits::default()),
    Err(@moonloom.UnsupportedHashAlgorithm("CIDv0 requires sha2-256")),
  )
}

///|
test "CIDv0 requires the exact sha2-256 multihash shape" {
  assert_eq(
    @moonloom.Multihash::decode(b"\x12\x01\x00", @moonloom.Limits::default()),
    Err(@moonloom.DigestLengthMismatch("sha2-256", 32, 1)),
  )
  let oversized = Bytes::make(73 * 1024, b'\x00')
  assert_eq(
    @moonloom.Cid::decode_bytes(oversized, @moonloom.Limits::default()),
    Err(@moonloom.InvalidCid("CIDv0 must be 34 bytes", 73 * 1024)),
  )
}

///|
test "CID creation enforces content limits before hashing" {
  let limits = @moonloom.Limits::new(max_input_bytes=4)
  assert_eq(
    @moonloom.cid_from_content(
      85UL,
      @moonloom.Sha2_256,
      b"12345",
      @moonloom.sha2_provider(),
      limits,
    ),
    Err(@moonloom.InputTooLong("CID content", 4, 5)),
  )
  assert_eq(
    @moonloom.cid_v0_from_content(b"12345", @moonloom.sha2_provider(), limits),
    Err(@moonloom.InputTooLong("CID content", 4, 5)),
  )
}
