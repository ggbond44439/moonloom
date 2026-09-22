///|
/// Bounded binary reader used by protocol codecs.
pub struct WireReader {
  input : BytesView
  mut offset : Int
  limits : Limits
}

///|
pub fn WireReader::new(
  input : BytesView,
  limits : Limits,
) -> Result[WireReader, MoonLoomError] {
  match limits.check_input("wire input", input.length()) {
    Ok(_) => Ok({ input, offset: 0, limits, })
    Err(err) => Err(err)
  }
}

///|
pub fn WireReader::position(self : WireReader) -> Int {
  self.offset
}

///|
pub fn WireReader::remaining(self : WireReader) -> Int {
  self.input.length() - self.offset
}

///|
pub fn WireReader::is_done(self : WireReader) -> Bool {
  self.offset >= self.input.length()
}

///|
pub fn WireReader::remaining_view(self : WireReader) -> BytesView {
  self.input[self.offset:]
}

///|
pub fn WireReader::read_fixed(
  self : WireReader,
  context : String,
  length : Int,
) -> Result[BytesView, MoonLoomError] {
  if length < 0 {
    return Err(OffsetOutOfBounds(length))
  }
  if self.offset + length > self.input.length() {
    Err(Truncated(context, self.offset))
  } else {
    let result = self.input[self.offset:self.offset + length]
    self.offset += length
    Ok(result)
  }
}

///|
pub fn WireReader::read_varint(
  self : WireReader,
  context : String,
) -> Result[UInt64, MoonLoomError] {
  let base = self.offset
  match decode_u64_with_limits(self.input[self.offset:], self.limits) {
    Ok((value, consumed)) => {
      self.offset += consumed
      Ok(value)
    }
    Err(Truncated(_, offset)) => Err(Truncated(context, base + offset))
    Err(InvalidVarint(_, offset)) => Err(InvalidVarint(context, base + offset))
    Err(NonCanonicalVarint(offset)) => Err(NonCanonicalVarint(base + offset))
    Err(err) => Err(err)
  }
}

///|
pub fn WireReader::read_length_prefixed(
  self : WireReader,
  context : String,
) -> Result[BytesView, MoonLoomError] {
  match self.read_varint(context) {
    Ok(length) =>
      if length > self.limits.max_input_bytes().to_uint64() {
        Err(
          InputTooLong(context, self.limits.max_input_bytes(), length.to_int()),
        )
      } else {
        self.read_fixed(context, length.to_int())
      }
    Err(err) => Err(err)
  }
}

///|
pub fn WireReader::read_u16_be(
  self : WireReader,
  context : String,
) -> Result[Int, MoonLoomError] {
  match self.read_fixed(context, 2) {
    Ok(bytes) => Ok((bytes[0].to_int() << 8) | bytes[1].to_int())
    Err(err) => Err(err)
  }
}

///|
/// Append-only binary writer used by protocol codecs.
pub struct WireWriter {
  buffer : @buffer.Buffer
}

///|
pub fn WireWriter::new() -> WireWriter {
  { buffer: @buffer.Buffer(), }
}

///|
pub fn WireWriter::length(self : WireWriter) -> Int {
  self.buffer.length()
}

///|
pub fn WireWriter::write_byte(self : WireWriter, value : Byte) -> Unit {
  self.buffer.write_byte(value)
}

///|
pub fn WireWriter::write_bytes(self : WireWriter, value : BytesView) -> Unit {
  for byte in value {
    self.buffer.write_byte(byte)
  }
}

///|
pub fn WireWriter::write_varint(self : WireWriter, value : UInt64) -> Unit {
  self.write_bytes(encode_u64(value))
}

///|
pub fn WireWriter::write_u16_be(self : WireWriter, value : Int) -> Unit {
  self.buffer.write_byte((value >> 8).to_byte())
  self.buffer.write_byte((value & 0xFF).to_byte())
}

///|
pub fn WireWriter::write_length_prefixed(
  self : WireWriter,
  value : BytesView,
) -> Unit {
  self.write_varint(value.length().to_uint64())
  self.write_bytes(value)
}

///|
pub fn WireWriter::to_bytes(self : WireWriter) -> Bytes {
  self.buffer.to_bytes()
}
