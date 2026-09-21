///|
/// Resource limits shared by all formats.
pub struct Limits {
  max_input_bytes : Int
  max_varint_bytes : Int
  max_digest_bytes : Int
  max_multiaddr_bytes : Int
}

///|
pub fn Limits::default() -> Limits {
  {
    max_input_bytes: 16 * 1024 * 1024,
    max_varint_bytes: 10,
    max_digest_bytes: 64,
    max_multiaddr_bytes: 4 * 1024,
  }
}

///|
pub fn Limits::new(
  max_input_bytes? : Int = 16 * 1024 * 1024,
  max_varint_bytes? : Int = 10,
  max_digest_bytes? : Int = 64,
  max_multiaddr_bytes? : Int = 4 * 1024,
) -> Limits {
  { max_input_bytes, max_varint_bytes, max_digest_bytes, max_multiaddr_bytes, }
}

///|
pub fn Limits::max_input_bytes(self : Limits) -> Int {
  self.max_input_bytes
}

///|
pub fn Limits::max_varint_bytes(self : Limits) -> Int {
  self.max_varint_bytes
}

///|
pub fn Limits::max_digest_bytes(self : Limits) -> Int {
  self.max_digest_bytes
}

///|
pub fn Limits::max_multiaddr_bytes(self : Limits) -> Int {
  self.max_multiaddr_bytes
}

///|
pub fn Limits::check_input(
  self : Limits,
  context : String,
  length : Int,
) -> Result[Unit, MoonLoomError] {
  if length < 0 {
    Err(OffsetOutOfBounds(length))
  } else if length > self.max_input_bytes {
    Err(InputTooLong(context, self.max_input_bytes, length))
  } else {
    Ok(())
  }
}
