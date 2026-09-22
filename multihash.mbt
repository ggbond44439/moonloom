///|
/// Hash algorithms currently understood by MoonLoom.
pub(all) enum HashAlgorithm {
  Identity
  Sha2_256
  Sha2_512
} derive(Eq, @debug.Debug)

///|
pub fn HashAlgorithm::name(self : HashAlgorithm) -> String {
  match self {
    Identity => "identity"
    Sha2_256 => "sha2-256"
    Sha2_512 => "sha2-512"
  }
}

///|
pub fn HashAlgorithm::code(self : HashAlgorithm) -> UInt64 {
  match self {
    Identity => 0UL
    Sha2_256 => 18UL
    Sha2_512 => 19UL
  }
}

///|
pub fn HashAlgorithm::from_code(code : UInt64) -> HashAlgorithm? {
  match code {
    0UL => Some(Identity)
    18UL => Some(Sha2_256)
    19UL => Some(Sha2_512)
    _ => None
  }
}

///|
pub fn HashAlgorithm::from_name(name : StringView) -> HashAlgorithm? {
  match name.to_owned() {
    "identity" => Some(Identity)
    "sha2-256" => Some(Sha2_256)
    "sha2-512" => Some(Sha2_512)
    _ => None
  }
}

///|
pub fn supported_hash_algorithms() -> Array[HashAlgorithm] {
  [Identity, Sha2_256, Sha2_512]
}

///|
pub fn HashAlgorithm::expected_digest_size(self : HashAlgorithm) -> Int? {
  match self {
    Identity => None
    Sha2_256 => Some(32)
    Sha2_512 => Some(64)
  }
}

///|
/// Provider seam for cryptographic hash implementations.
pub struct HashProvider {
  digest : (HashAlgorithm, BytesView) -> Result[Bytes, MoonLoomError]
}

///|
pub fn HashProvider::new(
  digest : (HashAlgorithm, BytesView) -> Result[Bytes, MoonLoomError],
) -> HashProvider {
  { digest, }
}

///|
pub fn HashProvider::hash(
  self : HashProvider,
  algorithm : HashAlgorithm,
  data : BytesView,
) -> Result[Bytes, MoonLoomError] {
  (self.digest)(algorithm, data)
}

///|
/// Built-in provider backed by the reviewed MoonCrypt SHA-2 implementation.
pub fn sha2_provider() -> HashProvider {
  HashProvider::new(fn(algorithm, data) {
    match algorithm {
      Sha2_256 => Ok(@sha2.hash(data, kind=@sha2.Kind::Sha256))
      Sha2_512 => Ok(@sha2.hash(data, kind=@sha2.Kind::Sha512))
      Identity =>
        Err(UnsupportedHashAlgorithm("identity is not a cryptographic hash"))
    }
  })
}

///|
pub(all) struct Multihash {
  code : UInt64
  digest : Bytes
} derive(Eq, @debug.Debug)

///|
pub fn Multihash::create(
  algorithm : HashAlgorithm,
  digest : BytesView,
  limits : Limits,
) -> Result[Multihash, MoonLoomError] {
  if digest.length() > limits.max_digest_bytes() {
    return Err(
      InputTooLong(
        "multihash digest",
        limits.max_digest_bytes(),
        digest.length(),
      ),
    )
  }
  match algorithm.expected_digest_size() {
    Some(expected) =>
      if digest.length() != expected {
        return Err(
          DigestLengthMismatch(algorithm.name(), expected, digest.length()),
        )
      }
    None => ()
  }
  Ok({ code: algorithm.code(), digest: digest.to_owned(), })
}

///|
pub fn Multihash::identity(
  data : BytesView,
  limits : Limits,
) -> Result[Multihash, MoonLoomError] {
  Multihash::create(Identity, data, limits)
}

///|
pub fn Multihash::is_identity(self : Multihash) -> Bool {
  self.code == 0UL
}

///|
pub fn Multihash::algorithm(self : Multihash) -> HashAlgorithm? {
  HashAlgorithm::from_code(self.code)
}

///|
pub fn Multihash::encode(self : Multihash) -> Bytes {
  let out = @buffer.Buffer(size_hint=self.digest.length() + 10)
  for byte in encode_u64(self.code) {
    out.write_byte(byte)
  }
  for byte in encode_u64(self.digest.length().to_uint64()) {
    out.write_byte(byte)
  }
  for byte in self.digest {
    out.write_byte(byte)
  }
  out.to_bytes()
}

///|
pub fn Multihash::decode(
  input : BytesView,
  limits : Limits,
) -> Result[(Multihash, Int), MoonLoomError] {
  match limits.check_input("multihash", input.length()) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }
  match decode_u64_with_limits(input, limits) {
    Ok((code, code_length)) => {
      if code_length >= input.length() {
        return Err(Truncated("multihash digest length", code_length))
      }
      match decode_u64_with_limits(input[code_length:], limits) {
        Ok((digest_length, length_bytes)) => {
          let digest_start = code_length + length_bytes
          if digest_length > limits.max_digest_bytes().to_uint64() {
            return Err(
              InputTooLong(
                "multihash digest",
                limits.max_digest_bytes(),
                digest_length.to_int(),
              ),
            )
          }
          let digest_size = digest_length.to_int()
          if digest_start + digest_size > input.length() {
            return Err(Truncated("multihash digest", digest_start))
          }
          Ok(
            (
              {
                code,
                digest: input[digest_start:digest_start + digest_size].to_owned(),
              },
              digest_start + digest_size,
            ),
          )
        }
        Err(err) => Err(err)
      }
    }
    Err(err) => Err(err)
  }
}

///|
pub fn Multihash::to_text(
  self : Multihash,
  base : Base,
) -> Result[String, MoonLoomError] {
  multibase_encode(base, self.encode())
}

///|
pub fn Multihash::to_text_canonical(
  self : Multihash,
) -> Result[String, MoonLoomError] {
  self.to_text(Base58Btc)
}

///|
pub fn Multihash::from_text(
  text : StringView,
  limits : Limits,
) -> Result[Multihash, MoonLoomError] {
  match multibase_decode(text, limits) {
    Ok(value) =>
      match Multihash::decode(value.data, limits) {
        Ok((decoded, consumed)) =>
          if consumed == value.data.length() {
            Ok(decoded)
          } else {
            Err(InvalidMultihash("trailing bytes", consumed))
          }
        Err(err) => Err(err)
      }
    Err(err) => Err(err)
  }
}

///|
pub fn Multihash::verify(
  self : Multihash,
  content : BytesView,
  provider : HashProvider,
  limits : Limits,
) -> Result[Unit, MoonLoomError] {
  match limits.check_input("multihash content", content.length()) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }
  match self.algorithm() {
    Some(Identity) =>
      if self.digest[:] == content {
        Ok(())
      } else {
        Err(HashMismatch)
      }
    Some(algorithm) =>
      match provider.hash(algorithm, content) {
        Ok(digest) =>
          if digest == self.digest {
            Ok(())
          } else {
            Err(HashMismatch)
          }
        Err(err) => Err(err)
      }
    None => Err(UnknownCodec(self.code))
  }
}

///|
pub extend HashAlgorithm with Eq::{not_equal, equal}

///|
pub extend HashAlgorithm with @debug.Debug::{to_repr}

///|
pub extend Multihash with Eq::{not_equal, equal}

///|
pub extend Multihash with @debug.Debug::{to_repr}
