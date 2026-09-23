///|
fn deterministic_bytes(seed : UInt64, length : Int) -> Bytes {
  let out = FixedArray::make(length, b'\x00')
  let mut state = seed
  for index in 0..<length {
    state = state * 6364136223846793005UL + 1442695040888963407UL
    out[index] = ((state >> 33) & 0xFFUL).to_int().to_byte()
  }
  Bytes::from_array(out)
}

///|
test "hardening: binary decoders do not panic on arbitrary bytes" {
  let limits = @moonloom.Limits::default()
  for length in 0..<96 {
    let bytes = deterministic_bytes(length.to_uint64() + 17UL, length)
    ignore(@moonloom.decode_u64(bytes))
    ignore(@moonloom.Multihash::decode(bytes, limits))
    ignore(@moonloom.Cid::decode_bytes(bytes, limits))
    ignore(@moonloom.Multiaddr::parse_bytes(bytes, limits))
  }
}

///|
test "hardening: varint round trips generated values" {
  for index in 1..<128 {
    let value = (index.to_uint64() * 977UL) ^ (index.to_uint64() << 17)
    let encoded = @moonloom.encode_u64(value)
    assert_eq(@moonloom.decode_u64(encoded), Ok((value, encoded.length())))
  }
}

///|
test "hardening: parsers reject every strict truncation prefix" {
  let limits = @moonloom.Limits::default()
  let multihash = b"\x12\x20\x2c\xf2\x4d\xba"
  for end in 0..<multihash.length() {
    assert_true(@moonloom.Multihash::decode(multihash[:end], limits) is Err(_))
  }
  let multiaddr = b"\x04\x7f\x00\x00\x01\x06\x1f\x90"
  for end in [1, 2, 3, 4, 6, 7] {
    assert_true(
      @moonloom.Multiaddr::parse_bytes(multiaddr[:end], limits) is Err(_),
    )
  }
}
