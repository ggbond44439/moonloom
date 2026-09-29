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

///|
test "interop: SHA-3 and BLAKE3 vectors" {
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
test "interop: extended Multiaddr binary vectors" {
  let limits = @moonloom.Limits::default()
  let transport = match
    @moonloom.Multiaddr::parse(
      "/ip4/127.0.0.1/udp/443/quic-v1/webtransport", limits,
    ) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(
    transport.to_bytes(limits),
    Ok(b"\x04\x7f\x00\x00\x01\x91\x02\x01\xbb\xcd\x03\xd1\x03"),
  )
  let unix = match
    @moonloom.Multiaddr::parse("/unix/tmp/moonloom.sock", limits) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(unix.to_bytes(limits), Ok(b"\x90\x03\x12/tmp/moonloom.sock"))
}
