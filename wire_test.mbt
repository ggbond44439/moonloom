///|
test "WireReader reads varints and network-order fields" {
  let reader = match
    @moonloom.WireReader::new(b"\xac\x02\x1f\x90", @moonloom.Limits::default()) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(reader.read_varint("test"), Ok(300UL))
  assert_eq(reader.read_u16_be("port"), Ok(8080))
  assert_eq(reader.is_done(), true)
  assert_eq(reader.position(), 4)
}

///|
test "WireReader length-prefixed reads are bounded" {
  let reader = match
    @moonloom.WireReader::new(b"\x03abc\xff", @moonloom.Limits::default()) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(reader.read_length_prefixed("field"), Ok(b"abc"))
  assert_eq(reader.remaining_view(), b"\xff")
  assert_eq(reader.remaining(), 1)
}

///|
test "WireWriter emits deterministic bytes" {
  let writer = @moonloom.WireWriter::new()
  writer.write_varint(300UL)
  writer.write_u16_be(8080)
  writer.write_length_prefixed(b"abc")
  assert_eq(writer.length(), 8)
  assert_eq(writer.to_bytes(), b"\xac\x02\x1f\x90\x03abc")
}
