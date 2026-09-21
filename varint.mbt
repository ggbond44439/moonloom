///|
/// Encode an unsigned 64-bit integer using the Multiformats unsigned varint
/// representation (unsigned LEB128, minimal form).
pub fn encode_u64(value : UInt64) -> Bytes {
  let buffer = @buffer.Buffer(size_hint=10)
  let mut remaining = value
  while remaining >= 0x80UL {
    buffer.write_byte((remaining & 0x7FUL).to_int().to_byte() | b'\x80')
    remaining = remaining >> 7
  }
  buffer.write_byte(remaining.to_int().to_byte())
  buffer.to_bytes()
}

///|
/// Decode an unsigned varint with the default resource limits.
pub fn decode_u64(input : BytesView) -> Result[(UInt64, Int), MoonLoomError] {
  decode_u64_with_limits(input, Limits::default())
}

///|
/// Decode one unsigned varint and return the value together with the number of
/// bytes consumed. Trailing bytes are intentionally left to the caller.
pub fn decode_u64_with_limits(
  input : BytesView,
  limits : Limits,
) -> Result[(UInt64, Int), MoonLoomError] {
  match limits.check_input("varint", input.length()) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }
  if input.length() == 0 {
    return Err(Truncated("varint", 0))
  }
  let max_bytes = limits.max_varint_bytes()
  if max_bytes <= 0 || max_bytes > 10 {
    return Err(InvalidVarint("varint limit", 0))
  }
  let mut value = 0UL
  let mut shift = 0
  let mut offset = 0
  while offset < input.length() && offset < max_bytes {
    let byte = input[offset]
    let byte_value = byte.to_int()
    let payload = (byte_value & 0x7F).to_uint64()
    if offset == 9 && payload > 1UL {
      return Err(InvalidVarint("varint overflow", offset))
    }
    value = value | (payload << shift)
    if (byte_value & 0x80) == 0 {
      if offset > 0 && payload == 0UL {
        return Err(NonCanonicalVarint(offset))
      }
      return Ok((value, offset + 1))
    }
    shift += 7
    offset += 1
  }
  if offset >= max_bytes {
    Err(InvalidVarint("varint length", offset))
  } else {
    Err(Truncated("varint", offset))
  }
}
