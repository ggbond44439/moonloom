///|
test "base names round trip through the public registry" {
  let bases = @moonloom.supported_bases()
  assert_eq(bases.length(), 11)
  for base in bases {
    match @moonloom.Base::from_name(base.name()) {
      Some(decoded) => assert_eq(decoded, base)
      None => fail("missing base name " + base.name())
    }
  }
  assert_eq(@moonloom.Base::from_name("base99"), None)
}

///|
test "hash algorithm names round trip through the public registry" {
  let algorithms = @moonloom.supported_hash_algorithms()
  assert_eq(algorithms.length(), 3)
  for algorithm in algorithms {
    match @moonloom.HashAlgorithm::from_name(algorithm.name()) {
      Some(decoded) => assert_eq(decoded, algorithm)
      None => fail("missing hash name " + algorithm.name())
    }
  }
  assert_eq(@moonloom.HashAlgorithm::from_name("sha2-999"), None)
}

///|
test "codec category names round trip" {
  let categories : Array[@moonloom.CodecCategory] = [
    @moonloom.Cid,
    @moonloom.Format,
    @moonloom.Hash,
    @moonloom.Multiaddr,
  ]
  for category in categories {
    match @moonloom.CodecCategory::from_name(category.name()) {
      Some(decoded) => assert_eq(decoded, category)
      None => fail("missing codec category " + category.name())
    }
  }
}

///|
test "resource limit helpers separate digest and multiaddr bounds" {
  let limits = @moonloom.Limits::new(max_digest_bytes=8, max_multiaddr_bytes=4)
  assert_eq(limits.check_digest("digest", 8), Ok(()))
  assert_eq(
    limits.check_digest("digest", 9),
    Err(@moonloom.InputTooLong("digest", 8, 9)),
  )
  assert_eq(limits.check_multiaddr(4), Ok(()))
  assert_eq(
    limits.check_multiaddr(5),
    Err(@moonloom.InputTooLong("multiaddr", 4, 5)),
  )
}

///|
test "CID exposes stable inspection and canonical text helpers" {
  let value = match
    @moonloom.cid_from_content(
      @moonloom.RAW_CODEC,
      @moonloom.Sha2_256,
      b"hello",
      @moonloom.sha2_provider(),
      @moonloom.Limits::default(),
    ) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(value.is_v0(), false)
  assert_eq(value.codec_name(), Some("raw"))
  assert_eq(value.hash_algorithm(), Some(@moonloom.Sha2_256))
  assert_eq(
    value.to_text(),
    Ok("bafkreibm6jg3ux5qumhcn2b3flc3tyu6dmlb4xa7u5bf44yegnrjhc4yeq"),
  )
}

///|
test "multihash canonical text helper uses base58btc" {
  let value = match
    @moonloom.Multihash::identity(b"abc", @moonloom.Limits::default()) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(value.is_identity(), true)
  let text = match value.to_text_canonical() {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(text.has_prefix("z"), true)
  match @moonloom.Multihash::from_text(text, @moonloom.Limits::default()) {
    Ok(decoded) => assert_eq(decoded, value)
    Err(err) => fail(err.to_string())
  }
}
