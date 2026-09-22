///|
/// Errors returned by MoonLoom parsing and encoding APIs.
///
/// Lengths and offsets are measured in bytes. String contexts identify the
/// format boundary that rejected the input.
pub(all) enum MoonLoomError {
  InputTooLong(String, Int, Int)
  OffsetOutOfBounds(Int)
  Truncated(String, Int)
  InvalidVarint(String, Int)
  NonCanonicalVarint(Int)
  UnknownBase(Char)
  InvalidBaseCharacter(Char, Int)
  InvalidPadding(String, Int)
  UnknownCodec(UInt64)
  UnknownCodecName(String)
  InvalidField(String, Int)
  UnsupportedHashAlgorithm(String)
  DigestLengthMismatch(String, Int, Int)
  HashMismatch
  InvalidMultihash(String, Int)
  InvalidCid(String, Int)
  CidCodecMismatch(UInt64)
  InvalidCodec(UInt64)
  InvalidProtocolValue(String)
  InvalidPort(Int)
  UnknownProtocol(String)
} derive(Eq, @debug.Debug)

///|
pub impl Show for MoonLoomError with fn output(self, logger) {
  match self {
    InputTooLong(context, limit, actual) =>
      logger.write_string(
        "moonloom: \{context} exceeds limit: \{actual} > \{limit}",
      )
    OffsetOutOfBounds(offset) =>
      logger.write_string("moonloom: byte offset \{offset} is out of bounds")
    Truncated(context, offset) =>
      logger.write_string("moonloom: \{context} is truncated at byte \{offset}")
    InvalidVarint(context, offset) =>
      logger.write_string("moonloom: invalid \{context} at byte \{offset}")
    NonCanonicalVarint(offset) =>
      logger.write_string("moonloom: non-canonical varint at byte \{offset}")
    UnknownBase(prefix) =>
      logger.write_string("moonloom: unknown multibase prefix '\{prefix}'")
    InvalidBaseCharacter(prefix, offset) =>
      logger.write_string(
        "moonloom: invalid character for multibase '\{prefix}' at byte \{offset}",
      )
    InvalidPadding(context, offset) =>
      logger.write_string(
        "moonloom: invalid \{context} padding at byte \{offset}",
      )
    UnknownCodec(code) =>
      logger.write_string("moonloom: unknown multicodec \{code}")
    UnknownCodecName(name) =>
      logger.write_string("moonloom: unknown multicodec name '\{name}'")
    InvalidField(context, offset) =>
      logger.write_string("moonloom: invalid \{context} at byte \{offset}")
    UnsupportedHashAlgorithm(name) =>
      logger.write_string("moonloom: unsupported hash algorithm '\{name}'")
    DigestLengthMismatch(name, expected, actual) =>
      logger.write_string(
        "moonloom: \{name} digest length mismatch: expected \{expected}, got \{actual}",
      )
    HashMismatch =>
      logger.write_string("moonloom: content does not match multihash")
    InvalidMultihash(context, offset) =>
      logger.write_string(
        "moonloom: invalid multihash \{context} at byte \{offset}",
      )
    InvalidCid(context, offset) =>
      logger.write_string("moonloom: invalid CID \{context} at byte \{offset}")
    CidCodecMismatch(code) =>
      logger.write_string("moonloom: CID codec \{code} cannot use CIDv0")
    InvalidCodec(code) => logger.write_string("moonloom: invalid codec \{code}")
    InvalidProtocolValue(protocol) =>
      logger.write_string("moonloom: invalid value for protocol \{protocol}")
    InvalidPort(port) => logger.write_string("moonloom: invalid port \{port}")
    UnknownProtocol(name) =>
      logger.write_string("moonloom: unknown protocol '\{name}'")
  }
}

///|
pub extend MoonLoomError with Eq::{not_equal, equal}

///|
pub extend MoonLoomError with @debug.Debug::{to_repr}

///|
pub extend MoonLoomError with Show::{to_string, output}
