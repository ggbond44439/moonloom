///|
test "varint encodes canonical boundaries" {
  assert_eq(@moonloom.encode_u64(0UL), b"\x00")
  assert_eq(@moonloom.encode_u64(1UL), b"\x01")
  assert_eq(@moonloom.encode_u64(127UL), b"\x7f")
  assert_eq(@moonloom.encode_u64(128UL), b"\x80\x01")
  assert_eq(@moonloom.encode_u64(300UL), b"\xac\x02")
  assert_eq(
    @moonloom.encode_u64(18446744073709551615UL),
    b"\xff\xff\xff\xff\xff\xff\xff\xff\xff\x01",
  )
}

///|
test "varint decodes values and consumed length" {
  assert_eq(@moonloom.decode_u64(b"\xac\x02\xff"), Ok((300UL, 2)))
  assert_eq(@moonloom.decode_u64(b"\x80\x01"), Ok((128UL, 2)))
  assert_eq(@moonloom.decode_u64(b"\x00"), Ok((0UL, 1)))
}

///|
test "varint rejects malformed input" {
  assert_eq(@moonloom.decode_u64(b""), Err(Truncated("varint", 0)))
  assert_eq(@moonloom.decode_u64(b"\x80"), Err(Truncated("varint", 1)))
  assert_eq(@moonloom.decode_u64(b"\x80\x00"), Err(NonCanonicalVarint(1)))
  assert_eq(
    @moonloom.decode_u64(b"\xff\xff\xff\xff\xff\xff\xff\xff\xff\x02"),
    Err(InvalidVarint("varint overflow", 9)),
  )
}
