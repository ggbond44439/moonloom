///|
/// Multibase encodings supported by MoonLoom.
pub(all) enum Base {
  Base16
  Base16Upper
  Base32
  Base32Upper
  Base32Pad
  Base32PadUpper
  Base58Btc
  Base64
  Base64Pad
  Base64Url
  Base64UrlPad
} derive(Eq, @debug.Debug)

///|
pub(all) struct DecodedMultibase {
  base : Base
  data : Bytes
} derive(Eq, @debug.Debug)

///|
pub fn Base::prefix(self : Base) -> Char {
  match self {
    Base16 => 'f'
    Base16Upper => 'F'
    Base32 => 'b'
    Base32Upper => 'B'
    Base32Pad => 'c'
    Base32PadUpper => 'C'
    Base58Btc => 'z'
    Base64 => 'm'
    Base64Pad => 'M'
    Base64Url => 'u'
    Base64UrlPad => 'U'
  }
}

///|
pub fn Base::from_prefix(prefix : Char) -> Base? {
  match prefix {
    'f' => Some(Base16)
    'F' => Some(Base16Upper)
    'b' => Some(Base32)
    'B' => Some(Base32Upper)
    'c' => Some(Base32Pad)
    'C' => Some(Base32PadUpper)
    'z' => Some(Base58Btc)
    'm' => Some(Base64)
    'M' => Some(Base64Pad)
    'u' => Some(Base64Url)
    'U' => Some(Base64UrlPad)
    _ => None
  }
}

///|
pub fn Base::name(self : Base) -> String {
  match self {
    Base16 => "base16"
    Base16Upper => "base16upper"
    Base32 => "base32"
    Base32Upper => "base32upper"
    Base32Pad => "base32pad"
    Base32PadUpper => "base32padupper"
    Base58Btc => "base58btc"
    Base64 => "base64"
    Base64Pad => "base64pad"
    Base64Url => "base64url"
    Base64UrlPad => "base64urlpad"
  }
}

///|
pub fn Base::from_name(name : StringView) -> Base? {
  match name.to_owned() {
    "base16" => Some(Base16)
    "base16upper" => Some(Base16Upper)
    "base32" => Some(Base32)
    "base32upper" => Some(Base32Upper)
    "base32pad" => Some(Base32Pad)
    "base32padupper" => Some(Base32PadUpper)
    "base58btc" => Some(Base58Btc)
    "base64" => Some(Base64)
    "base64pad" => Some(Base64Pad)
    "base64url" => Some(Base64Url)
    "base64urlpad" => Some(Base64UrlPad)
    _ => None
  }
}

///|
pub fn supported_bases() -> Array[Base] {
  [
    Base16,
    Base16Upper,
    Base32,
    Base32Upper,
    Base32Pad,
    Base32PadUpper,
    Base58Btc,
    Base64,
    Base64Pad,
    Base64Url,
    Base64UrlPad,
  ]
}

///|
fn case_is_canonical(text : StringView, upper_required : Bool) -> Bool {
  for code_unit in text.code_units() {
    let code = code_unit.to_int()
    if code >= 65 && code <= 90 && !upper_required {
      return false
    }
    if code >= 97 && code <= 122 && upper_required {
      return false
    }
  }
  true
}

///|
fn invalid_base32_offset(text : StringView, upper : Bool) -> Int? {
  for index, code_unit in text.code_units() {
    let code = code_unit.to_int()
    let letter = if upper {
      code >= 65 && code <= 90
    } else {
      code >= 97 && code <= 122
    }
    let digit = code >= 50 && code <= 55
    if !letter && !digit && code != 61 {
      return Some(index)
    }
  }
  None
}

///|
fn has_ascii(text : StringView, expected : Int) -> Bool {
  for code_unit in text.code_units() {
    if code_unit.to_int() == expected {
      return true
    }
  }
  false
}

///|
fn trailing_padding(text : StringView) -> Int {
  let mut count = 0
  for index in text.length()>..0 {
    if text.unsafe_get(index).to_int() == 61 {
      count += 1
    } else {
      break
    }
  }
  count
}

///|
fn encode_hex(data : BytesView, upper : Bool) -> String {
  @base16.encode(
    data,
    kind=if upper { @base16.Kind::Upper } else { @base16.Kind::Lower },
  )
}

///|
fn decode_hex(text : StringView, upper : Bool) -> Result[Bytes, MoonLoomError] {
  let prefix = if upper { 'F' } else { 'f' }
  if text.length() % 2 != 0 {
    return Err(InvalidPadding("base16", text.length()))
  }
  if !case_is_canonical(text, upper) {
    return Err(InvalidBaseCharacter(prefix, 0))
  }
  let bytes = @base16.decode(text) catch {
    _ => return Err(InvalidBaseCharacter(prefix, 0))
  }
  Ok(bytes)
}

///|
fn lower_ascii(value : String) -> String {
  let out = StringBuilder(size_hint=value.length())
  for code_unit in value.code_units() {
    let code = code_unit.to_int()
    if code >= 65 && code <= 90 {
      out.write_char((code + 32).unsafe_to_char())
    } else {
      out.write_char(code.unsafe_to_char())
    }
  }
  out.to_string()
}

///|
fn encode_base32(data : BytesView, upper : Bool, padding : Bool) -> String {
  let encoded = @base32.encode(data, kind=@base32.Kind::Std, padding~)
  if upper {
    encoded
  } else {
    lower_ascii(encoded)
  }
}

///|
fn decode_base32(
  text : StringView,
  prefix : Char,
  upper : Bool,
  padding : Bool,
) -> Result[Bytes, MoonLoomError] {
  match invalid_base32_offset(text, upper) {
    Some(offset) => return Err(InvalidBaseCharacter(prefix, offset))
    None => ()
  }
  let mut data_length = text.length()
  if padding {
    if text.length() % 8 != 0 {
      return Err(InvalidPadding("base32", text.length()))
    }
    while data_length > 0 && text.unsafe_get(data_length - 1).to_int() == 61 {
      data_length -= 1
    }
    let expected = match data_length % 8 {
      0 => 0
      2 => 6
      4 => 4
      5 => 3
      7 => 1
      _ => return Err(InvalidPadding("base32", data_length))
    }
    if text.length() - data_length != expected {
      return Err(InvalidPadding("base32", data_length))
    }
  } else if has_ascii(text, 61) {
    return Err(InvalidPadding("base32", 0))
  }
  let bytes = @base32.decode(text, kind=@base32.Kind::Std) catch {
    _ => return Err(InvalidBaseCharacter(prefix, 0))
  }
  Ok(bytes)
}

///|
fn encode_base58(data : BytesView) -> String {
  @base58.encode(data)
}

///|
fn decode_base58(text : StringView) -> Result[Bytes, MoonLoomError] {
  let bytes = @base58.decode(text) catch {
    _ => return Err(InvalidBaseCharacter('z', 0))
  }
  Ok(bytes)
}

///|
fn encode_base64(data : BytesView, url : Bool, padding : Bool) -> String {
  @base64.encode(
    data,
    kind=if url { @base64.Kind::Url } else { @base64.Kind::Std },
    padding~,
  )
}

///|
fn decode_base64(
  text : StringView,
  prefix : Char,
  url : Bool,
  padding : Bool,
) -> Result[Bytes, MoonLoomError] {
  if padding {
    if text.length() % 4 != 0 {
      return Err(InvalidPadding("base64", text.length()))
    }
    let data_length = text.length() - trailing_padding(text)
    let expected = match data_length % 4 {
      0 => 0
      2 => 2
      3 => 1
      _ => return Err(InvalidPadding("base64", data_length))
    }
    if text.length() - data_length != expected {
      return Err(InvalidPadding("base64", data_length))
    }
  } else if has_ascii(text, 61) {
    return Err(InvalidPadding("base64", 0))
  } else if text.length() % 4 == 1 {
    return Err(InvalidPadding("base64", text.length()))
  }
  let bytes = @base64.decode(
    text,
    kind=if url { @base64.Kind::Url } else { @base64.Kind::Std },
  ) catch {
    _ => return Err(InvalidBaseCharacter(prefix, 0))
  }
  Ok(bytes)
}

///|
pub fn multibase_encode(
  base : Base,
  data : BytesView,
) -> Result[String, MoonLoomError] {
  let encoded = match base {
    Base16 => encode_hex(data, false)
    Base16Upper => encode_hex(data, true)
    Base32 => encode_base32(data, false, false)
    Base32Upper => encode_base32(data, true, false)
    Base32Pad => encode_base32(data, false, true)
    Base32PadUpper => encode_base32(data, true, true)
    Base58Btc => encode_base58(data)
    Base64 => encode_base64(data, false, false)
    Base64Pad => encode_base64(data, false, true)
    Base64Url => encode_base64(data, true, false)
    Base64UrlPad => encode_base64(data, true, true)
  }
  Ok(base.prefix().to_string() + encoded)
}

///|
pub fn multibase_decode(
  text : StringView,
  limits : Limits,
) -> Result[DecodedMultibase, MoonLoomError] {
  match limits.check_input("multibase", text.length()) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }
  if text.length() == 0 {
    return Err(UnknownBase('\u{0}'))
  }
  let prefix = match text.code_units()[0].to_char() {
    Some(value) => value
    None => return Err(UnknownBase('\u{0}'))
  }
  let base = match Base::from_prefix(prefix) {
    Some(value) => value
    None => return Err(UnknownBase(prefix))
  }
  let payload = text.exact_view(start=1)
  let data = match base {
    Base16 => decode_hex(payload, false)
    Base16Upper => decode_hex(payload, true)
    Base32 => decode_base32(payload, 'b', false, false)
    Base32Upper => decode_base32(payload, 'B', true, false)
    Base32Pad => decode_base32(payload, 'c', false, true)
    Base32PadUpper => decode_base32(payload, 'C', true, true)
    Base58Btc => decode_base58(payload)
    Base64 => decode_base64(payload, 'm', false, false)
    Base64Pad => decode_base64(payload, 'M', false, true)
    Base64Url => decode_base64(payload, 'u', true, false)
    Base64UrlPad => decode_base64(payload, 'U', true, true)
  }
  match data {
    Ok(bytes) => Ok({ base, data: bytes, })
    Err(err) => Err(err)
  }
}

///|
pub extend Base with Eq::{not_equal, equal}

///|
pub extend Base with @debug.Debug::{to_repr}

///|
pub extend DecodedMultibase with Eq::{not_equal, equal}

///|
pub extend DecodedMultibase with @debug.Debug::{to_repr}
