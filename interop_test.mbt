///|
test "interop: RFC 4648 and Multibase hello vectors" {
  assert_eq(
    @moonloom.multibase_encode(@moonloom.Base32, b"hello"),
    Ok("bnbswy3dp"),
  )
  assert_eq(
    @moonloom.multibase_encode(@moonloom.Base64, b"hello"),
    Ok("maGVsbG8"),
  )
  assert_eq(
    @moonloom.multibase_encode(@moonloom.Base58Btc, b"hello"),
    Ok("zCn8eVZg"),
  )
}

///|
test "interop: SHA-256 and Multihash hello vector" {
  let digest = match
    @moonloom.sha2_provider().hash(@moonloom.Sha2_256, b"hello") {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let expected = match
    @moonloom.multibase_decode(
      "f2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824",
      @moonloom.Limits::default(),
    ) {
    Ok(value) => value.data
    Err(err) => fail(err.to_string())
  }
  assert_eq(digest, expected)
  let value = match
    @moonloom.Multihash::create(
      @moonloom.Sha2_256,
      digest,
      @moonloom.Limits::default(),
    ) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(
    value.to_text_canonical(),
    Ok("zQmRN6wdp1S2A5EtjW9A3M1vKSBuQQGcgvuhoMUoEz4iiT5"),
  )
}

///|
test "interop: canonical empty-content CID vectors" {
  let provider = @moonloom.sha2_provider()
  let limits = @moonloom.Limits::default()
  let raw = match
    @moonloom.cid_from_content(
      @moonloom.RAW_CODEC,
      @moonloom.Sha2_256,
      b"",
      provider,
      limits,
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
      provider,
      limits,
    ) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(
    dag_pb.to_text(),
    Ok("bafybeihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetojuzjevtenxquvyku"),
  )
  let v0 = match @moonloom.cid_v0_from_content(b"", provider, limits) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(v0.to_text(), Ok("QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n"))
}

///|
test "interop: Multiaddr binary vectors" {
  let limits = @moonloom.Limits::default()
  let ipv4 = match
    @moonloom.Multiaddr::parse("/ip4/127.0.0.1/tcp/8080", limits) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(ipv4.to_bytes(limits), Ok(b"\x04\x7f\x00\x00\x01\x06\x1f\x90"))
  let ipv6 = match @moonloom.Multiaddr::parse("/ip6/::1/udp/53", limits) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(
    ipv6.to_bytes(limits),
    Ok(
      b"\x29\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x91\x02\x00\x35",
    ),
  )
  let dns = match
    @moonloom.Multiaddr::parse("/dns/example.com/tcp/443", limits) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(dns.to_bytes(limits), Ok(b"\x35\x0bexample.com\x06\x01\xbb"))
}
