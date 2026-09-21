///|
/// Multibase encodings supported by MoonLoom's first milestone.
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
/// Result of decoding a Multibase string.
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
const HEX_LOWER : Bytes = b"0123456789abcdef"

///|
const HEX_UPPER : Bytes = b"0123456789ABCDEF"

///|
const BASE32_LOWER : Bytes = b"abcdefghijklmnopqrstuvwxyz234567"

///|
const BASE32_UPPER : Bytes = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

///|
const BASE58_BTC : Bytes = b"123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

///|
fn hex_value(code : Int) -> Int {
  match code {
    48..=57 => code - 48
    65..=70 => code - 65 + 10
    97..=102 => code - 97 + 10
    _ => -1
  }
}

///|
fn base32_value(code : Int, upper : Bool) -> Int {
  let a = if upper { 65 } else { 97 }
  if code >= a && code <= a + 25 {
    code - a
  } else if code >= 50 && code <= 55 {
    code - 50 + 26
  } else if !upper && code >= 65 && code <= 90 {
    -1
  } else if upper && code >= 97 && code <= 122 {
    -1
  } else {
    -1
  }
}

///|
fn encode_hex(data : BytesView, upper : Bool) -> String {
  let alphabet = if upper { HEX_UPPER } else { HEX_LOWER }
  let out = StringBuilder(size_hint=data.length() * 2)
  for byte in data {
    let value = byte.to_int()
    out.write_char(alphabet[(value >> 4) & 0x0F].to_char())
    out.write_char(alphabet[value & 0x0F].to_char())
  }
  out.to_string()
}

///|
fn decode_hex(text : StringView, upper : Bool) -> Result[Bytes, MoonLoomError] {
  if text.length() % 2 != 0 {
    return Err(InvalidPadding("base16", text.length()))
  }
  let out = @buffer.Buffer(size_hint=text.length() / 2)
  let mut index = 0
  while index < text.length() {
    let high = hex_value(text.unsafe_get(index).to_int())
    let low = hex_value(text.unsafe_get(index + 1).to_int())
    if high < 0 || low < 0 {
      let prefix = if upper { 'F' } else { 'f' }
      return Err(InvalidBaseCharacter(prefix, index))
    }
    let high_code = text.unsafe_get(index).to_int()
    let low_code = text.unsafe_get(index + 1).to_int()
    let high_is_alpha = high_code >= 65
    let low_is_alpha = low_code >= 65
    let high_case_ok = if upper {
      high_code >= 65 && high_code <= 70
    } else {
      high_code >= 97 && high_code <= 102
    }
    if high_is_alpha && !high_case_ok {
      return Err(InvalidBaseCharacter(if upper { 'F' } else { 'f' }, index))
    }
    let low_case_ok = if upper {
      low_code >= 65 && low_code <= 70
    } else {
      low_code >= 97 && low_code <= 102
    }
    if low_is_alpha && !low_case_ok {
      return Err(InvalidBaseCharacter(if upper { 'F' } else { 'f' }, index + 1))
    }
    out.write_byte(((high << 4) | low).to_byte())
    index += 2
  }
  Ok(out.to_bytes())
}

///|
fn encode_base32(data : BytesView, alphabet : Bytes, padding : Bool) -> String {
  let out = StringBuilder(size_hint=(data.length() + 4) / 5 * 8)
  let mut accumulator = 0
  let mut bits = 0
  for byte in data {
    accumulator = (accumulator << 8) | byte.to_int()
    bits += 8
    while bits >= 5 {
      bits -= 5
      out.write_char(alphabet[(accumulator >> bits) & 0x1F].to_char())
    }
    accumulator = if bits == 0 { 0 } else { accumulator & ((1 << bits) - 1) }
  }
  if bits > 0 {
    out.write_char(alphabet[(accumulator << (5 - bits)) & 0x1F].to_char())
  }
  if padding {
    let written = (data.length() * 8 + 4) / 5
    let remainder = written % 8
    if remainder != 0 {
      for _ in 0..<(8 - remainder) {
        out.write_char('=')
      }
    }
  }
  out.to_string()
}

///|
fn decode_base32(
  text : StringView,
  prefix : Char,
  upper : Bool,
  padding : Bool,
) -> Result[Bytes, MoonLoomError] {
  let mut data_length = text.length()
  if padding {
    if text.length() % 8 != 0 {
      return Err(InvalidPadding("base32", text.length()))
    }
    while data_length > 0 && text.unsafe_get(data_length - 1).to_int() == 61 {
      data_length -= 1
    }
    let padding_count = text.length() - data_length
    let remainder = data_length % 8
    let expected_padding = match remainder {
      0 => 0
      2 => 6
      4 => 4
      5 => 3
      7 => 1
      _ => return Err(InvalidPadding("base32", data_length))
    }
    if padding_count != expected_padding {
      return Err(InvalidPadding("base32", data_length))
    }
  } else {
    if text.length() > 0 && text.unsafe_get(text.length() - 1).to_int() == 61 {
      return Err(InvalidPadding("base32", text.length() - 1))
    }
    match text.length() % 8 {
      0 | 2 | 4 | 5 | 7 => ()
      _ => return Err(InvalidPadding("base32", text.length()))
    }
  }
  let out = @buffer.Buffer(size_hint=data_length * 5 / 8)
  let mut accumulator = 0
  let mut bits = 0
  for index in 0..<data_length {
    let code = text.unsafe_get(index).to_int()
    let value = base32_value(code, upper)
    if value < 0 {
      return Err(InvalidBaseCharacter(prefix, index))
    }
    accumulator = (accumulator << 5) | value
    bits += 5
    while bits >= 8 {
      bits -= 8
      out.write_byte(((accumulator >> bits) & 0xFF).to_byte())
    }
    accumulator = if bits == 0 { 0 } else { accumulator & ((1 << bits) - 1) }
  }
  if bits > 0 && accumulator != 0 {
    return Err(InvalidPadding("base32", data_length))
  }
  Ok(out.to_bytes())
}

///|

///|
fn base58_digit_value(char_code : Int) -> Int {
  for index, byte in BASE58_BTC {
    if byte.to_int() == char_code {
      return index
    }
  }
  -1
}

///|
fn encode_base58(data : BytesView) -> String {
  let out = StringBuilder()
  let mut leading_zeroes = 0
  while leading_zeroes < data.length() && data[leading_zeroes].to_int() == 0 {
    leading_zeroes += 1
    out.write_char('1')
  }
  if leading_zeroes < data.length() {
    let radix = @bigint.BigInt::from_int(58)
    let mut value = @bigint.BigInt::from_octets(data)
    let digits : Array[Int] = []
    while !value.is_zero() {
      let quotient = value / radix
      let remainder = value % radix
      digits.push(remainder.to_int())
      value = quotient
    }
    for index in digits.length()>..0 {
      out.write_char(BASE58_BTC[digits[index]].to_char())
    }
  }
  out.to_string()
}

///|
fn decode_base58(text : StringView) -> Result[Bytes, MoonLoomError] {
  if text.length() == 0 {
    return Ok(b"")
  }
  let radix = @bigint.BigInt::from_int(58)
  let mut value = @bigint.BigInt::from_int(0)
  let mut leading_zeroes = 0
  let mut saw_non_zero = false
  for index, code in text.code_units() {
    let digit = base58_digit_value(code.to_int())
    if digit < 0 {
      return Err(InvalidBaseCharacter('z', index))
    }
    if !saw_non_zero && digit == 0 {
      leading_zeroes += 1
    } else {
      saw_non_zero = true
      value = value * radix + @bigint.BigInt::from_int(digit)
    }
  }
  if !saw_non_zero {
    return Ok(Bytes::makei(leading_zeroes, _ => b'\x00'))
  }
  let octets = value.to_octets()
  let out = @buffer.Buffer(size_hint=leading_zeroes + octets.length())
  for _ in 0..<leading_zeroes {
    out.write_byte(b'\x00')
  }
  for byte in octets {
    out.write_byte(byte)
  }
  Ok(out.to_bytes())
}

///|
fn transform_base64(text : StringView, url : Bool) -> String {
  let out = StringBuilder(size_hint=text.length())
  for code in text.code_units() {
    let value = code.to_int()
    if url {
      if value == 43 {
        out.write_char('-')
      } else if value == 47 {
        out.write_char('_')
      } else {
        out.write_char(value.unsafe_to_char())
      }
    } else if value == 45 {
      out.write_char('+')
    } else if value == 95 {
      out.write_char('/')
    } else {
      out.write_char(value.unsafe_to_char())
    }
  }
  out.to_string()
}

///|
fn base64_from_url(text : StringView) -> String {
  let out = StringBuilder(size_hint=text.length())
  for code in text.code_units() {
    let value = code.to_int()
    if value == 45 {
      out.write_char('+')
    } else if value == 95 {
      out.write_char('/')
    } else {
      out.write_char(value.unsafe_to_char())
    }
  }
  out.to_string()
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
    let remainder = text.length() % 4
    if text.length() > 0 {
      let has_padding = text.unsafe_get(text.length() - 1).to_int() == 61
      if (remainder == 2 || remainder == 3) && !has_padding {
        return Err(InvalidPadding("base64", text.length()))
      }
    }
  } else {
    if text.length() % 4 == 1 {
      return Err(InvalidPadding("base64", text.length()))
    }
    if !text.is_empty() && text.unsafe_get(text.length() - 1).to_int() == 61 {
      return Err(InvalidPadding("base64", text.length() - 1))
    }
  }
  let normalized = if url { base64_from_url(text) } else { text.to_owned() }
  let bytes = @base64.decode(normalized, ignore_whitespace=false) catch {
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
    Base32 => encode_base32(data, BASE32_LOWER, false)
    Base32Upper => encode_base32(data, BASE32_UPPER, false)
    Base32Pad => encode_base32(data, BASE32_LOWER, true)
    Base32PadUpper => encode_base32(data, BASE32_UPPER, true)
    Base58Btc => encode_base58(data)
    Base64 => @base64.encode(data, padding=false)
    Base64Pad => @base64.encode(data, padding=true)
    Base64Url => transform_base64(@base64.encode(data, padding=false), true)
    Base64UrlPad => transform_base64(@base64.encode(data, padding=true), true)
  }
  let result = StringBuilder(size_hint=encoded.length() + 1)
  result.write_char(base.prefix())
  result.write_string(encoded)
  Ok(result.to_string())
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
    Some(base) => base
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
