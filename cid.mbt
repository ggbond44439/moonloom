///|
pub const CID_VERSION_0 : UInt64 = 0UL

///|
pub const CID_VERSION_1 : UInt64 = 1UL

///|
pub const DAG_PB_CODEC : UInt64 = 112UL

///|
/// CIDv0 or CIDv1 value.
pub(all) struct Cid {
  version : UInt64
  codec : UInt64
  hash : Multihash
} derive(Eq, @debug.Debug)

///|
pub fn Cid::v1(
  codec : UInt64,
  hash : Multihash,
  limits : Limits,
) -> Result[Cid, MoonLoomError] {
  if codec == 0UL {
    return Err(InvalidCodec(codec))
  }
  let encoded_hash = hash.encode()
  let version = encode_u64(CID_VERSION_1)
  let encoded_codec = encode_u64(codec)
  let total_length = version.length() +
    encoded_codec.length() +
    encoded_hash.length()
  match limits.check_input("CID", total_length) {
    Ok(_) => Ok({ version: CID_VERSION_1, codec, hash, })
    Err(err) => Err(err)
  }
}

///|
pub fn Cid::v0(hash : Multihash, limits : Limits) -> Result[Cid, MoonLoomError] {
  match hash.algorithm() {
    Some(Sha2_256) => {
      let bytes = hash.encode()
      match limits.check_input("CID", bytes.length()) {
        Ok(_) => Ok({ version: CID_VERSION_0, codec: DAG_PB_CODEC, hash, })
        Err(err) => Err(err)
      }
    }
    _ => Err(UnsupportedHashAlgorithm("CIDv0 requires sha2-256"))
  }
}

///|
pub fn Cid::to_bytes(self : Cid) -> Bytes {
  let writer = WireWriter::new()
  if self.version == 0UL {
    writer.write_bytes(self.hash.encode())
  } else {
    writer.write_varint(self.version)
    writer.write_varint(self.codec)
    writer.write_bytes(self.hash.encode())
  }
  writer.to_bytes()
}

///|
pub fn Cid::is_v0(self : Cid) -> Bool {
  self.version == CID_VERSION_0
}

///|
pub fn Cid::codec_name(self : Cid) -> String? {
  multicodec_name(self.codec)
}

///|
pub fn Cid::hash_algorithm(self : Cid) -> HashAlgorithm? {
  self.hash.algorithm()
}

///|
fn decode_v1(input : BytesView, limits : Limits) -> Result[Cid, MoonLoomError] {
  match decode_u64_with_limits(input, limits) {
    Ok((codec, codec_length)) => {
      if codec == 0UL {
        return Err(InvalidCodec(codec))
      }
      if codec_length >= input.length() {
        return Err(Truncated("CID codec", codec_length))
      }
      match Multihash::decode(input[codec_length:], limits) {
        Ok((hash, hash_length)) => {
          if codec_length + hash_length != input.length() {
            return Err(InvalidCid("trailing bytes", codec_length + hash_length))
          }
          Ok({ version: CID_VERSION_1, codec, hash, })
        }
        Err(err) => Err(err)
      }
    }
    Err(err) => Err(err)
  }
}

///|
pub fn Cid::decode_bytes(
  input : BytesView,
  limits : Limits,
) -> Result[Cid, MoonLoomError] {
  match limits.check_input("CID", input.length()) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }
  if input.length() == 0 {
    return Err(Truncated("CID", 0))
  }
  match decode_u64_with_limits(input, limits) {
    Ok((first, first_length)) =>
      if first == CID_VERSION_1 {
        decode_v1(input[first_length:], limits)
      } else {
        match Multihash::decode(input, limits) {
          Ok((hash, consumed)) => {
            if consumed != input.length() {
              return Err(InvalidCid("trailing bytes", consumed))
            }
            Cid::v0(hash, limits)
          }
          Err(err) => Err(err)
        }
      }
    Err(err) => Err(err)
  }
}

///|
pub fn Cid::to_text(self : Cid) -> Result[String, MoonLoomError] {
  if self.version == 0UL {
    Ok(encode_base58(self.to_bytes()))
  } else {
    multibase_encode(Base32, self.to_bytes())
  }
}

///|
pub fn Cid::parse(
  text : StringView,
  limits : Limits,
) -> Result[Cid, MoonLoomError] {
  match limits.check_input("CID", text.length()) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }
  if text.length() == 0 {
    return Err(Truncated("CID", 0))
  }
  let first = text.code_units()[0].to_int()
  let first_char = first.unsafe_to_char()
  match Base::from_prefix(first_char) {
    Some(_) =>
      match multibase_decode(text, limits) {
        Ok(value) =>
          match Cid::decode_bytes(value.data, limits) {
            Ok(cid) =>
              if cid.version == CID_VERSION_1 {
                Ok(cid)
              } else {
                Err(InvalidCid("multibase is only valid for CIDv1", 0))
              }
            Err(err) => Err(err)
          }
        Err(err) => Err(err)
      }
    None => {
      let _ = first
      match decode_base58(text) {
        Ok(bytes) =>
          match Cid::decode_bytes(bytes, limits) {
            Ok(cid) =>
              if cid.version == 0UL {
                Ok(cid)
              } else {
                Err(InvalidCid("CIDv1 requires a multibase prefix", 0))
              }
            Err(err) => Err(err)
          }
        Err(err) => Err(err)
      }
    }
  }
}

///|
pub fn cid_from_content(
  codec : UInt64,
  algorithm : HashAlgorithm,
  content : BytesView,
  provider : HashProvider,
  limits : Limits,
) -> Result[Cid, MoonLoomError] {
  match provider.hash(algorithm, content) {
    Ok(digest) =>
      match Multihash::create(algorithm, digest, limits) {
        Ok(hash) => Cid::v1(codec, hash, limits)
        Err(err) => Err(err)
      }
    Err(err) => Err(err)
  }
}

///|
pub fn cid_v0_from_content(
  content : BytesView,
  provider : HashProvider,
  limits : Limits,
) -> Result[Cid, MoonLoomError] {
  match provider.hash(Sha2_256, content) {
    Ok(digest) =>
      match Multihash::create(Sha2_256, digest, limits) {
        Ok(hash) => Cid::v0(hash, limits)
        Err(err) => Err(err)
      }
    Err(err) => Err(err)
  }
}

///|
pub fn Cid::verify(
  self : Cid,
  content : BytesView,
  provider : HashProvider,
  limits : Limits,
) -> Result[Unit, MoonLoomError] {
  self.hash.verify(content, provider, limits)
}

///|
pub extend Cid with Eq::{not_equal, equal}

///|
pub extend Cid with @debug.Debug::{to_repr}
