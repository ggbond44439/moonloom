///|
test "multibase known-vector encoding" {
  let data = b"hello"
  assert_eq(
    @moonloom.multibase_encode(@moonloom.Base16, data),
    Ok("f68656c6c6f"),
  )
  assert_eq(
    @moonloom.multibase_encode(@moonloom.Base16Upper, data),
    Ok("F68656C6C6F"),
  )
  assert_eq(@moonloom.multibase_encode(@moonloom.Base32, data), Ok("bnbswy3dp"))
  assert_eq(
    @moonloom.multibase_encode(@moonloom.Base32Upper, data),
    Ok("BNBSWY3DP"),
  )
  assert_eq(
    @moonloom.multibase_encode(@moonloom.Base58Btc, data),
    Ok("zCn8eVZg"),
  )
  assert_eq(@moonloom.multibase_encode(@moonloom.Base64, data), Ok("maGVsbG8"))
  assert_eq(
    @moonloom.multibase_encode(@moonloom.Base64Pad, data),
    Ok("MaGVsbG8="),
  )
}

///|
test "multibase known-vector decoding" {
  match @moonloom.multibase_decode("bnbswy3dp", @moonloom.Limits::default()) {
    Ok(value) => {
      assert_eq(value.base, @moonloom.Base32)
      assert_eq(value.data, b"hello")
    }
    Err(err) => fail(err.to_string())
  }
  match @moonloom.multibase_decode("zCn8eVZg", @moonloom.Limits::default()) {
    Ok(value) => assert_eq(value.data, b"hello")
    Err(err) => fail(err.to_string())
  }
}

///|
test "multibase round trips every supported base" {
  let samples : Array[Bytes] = [
    b"", b"\x00", b"\x00\x00\x01", b"hello", b"\x00\x01\x02\x7f\x80\xff",
  ]
  let bases : Array[@moonloom.Base] = [
    @moonloom.Base16,
    @moonloom.Base16Upper,
    @moonloom.Base32,
    @moonloom.Base32Upper,
    @moonloom.Base32Pad,
    @moonloom.Base32PadUpper,
    @moonloom.Base58Btc,
    @moonloom.Base64,
    @moonloom.Base64Pad,
    @moonloom.Base64Url,
    @moonloom.Base64UrlPad,
  ]
  for base in bases {
    for sample in samples {
      let encoded = match @moonloom.multibase_encode(base, sample) {
        Ok(value) => value
        Err(err) => fail("encode: \{err.to_string()}")
      }
      match @moonloom.multibase_decode(encoded, @moonloom.Limits::default()) {
        Ok(decoded) => {
          assert_eq(decoded.base, base)
          assert_eq(decoded.data, sample)
        }
        Err(err) => fail("decode \{encoded}: \{err.to_string()}")
      }
    }
  }
}

///|
test "multibase rejects unknown and malformed input" {
  assert_eq(
    @moonloom.multibase_decode("xabc", @moonloom.Limits::default()),
    Err(@moonloom.UnknownBase('x')),
  )
  assert_eq(
    @moonloom.multibase_decode("f0", @moonloom.Limits::default()),
    Err(@moonloom.InvalidPadding("base16", 1)),
  )
  assert_eq(
    @moonloom.multibase_decode("babc1", @moonloom.Limits::default()),
    Err(@moonloom.InvalidBaseCharacter('b', 3)),
  )
  assert_eq(
    @moonloom.multibase_decode("mA", @moonloom.Limits::default()),
    Err(@moonloom.InvalidPadding("base64", 1)),
  )
}
