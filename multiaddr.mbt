///|
/// Protocol identifiers used by the first Multiaddr model.
pub(all) enum Protocol {
  Ip4
  Ip6
  Dns
  Dns4
  Dns6
  Dnsaddr
  Tcp
  Udp
  P2p
  Http
  Https
  Ws
  Wss
  Unknown(UInt64)
} derive(Eq, @debug.Debug)

///|
pub(all) enum ProtocolValueKind {
  Empty
  Ipv4
  Ipv6
  Domain
  Port
  PeerId
  Text
  Raw
} derive(Eq, @debug.Debug)

///|
pub fn Protocol::code(self : Protocol) -> UInt64 {
  match protocol_info(self) {
    Some(info) => info.code
    None =>
      match self {
        Unknown(code) => code
        _ => abort("known protocol missing from registry")
      }
  }
}

///|
pub fn Protocol::from_code(code : UInt64) -> Protocol {
  match protocol_info_by_code(code) {
    Some(info) => info.protocol
    None => Unknown(code)
  }
}

///|
pub fn Protocol::name(self : Protocol) -> String? {
  match protocol_info(self) {
    Some(info) => Some(info.name)
    None => None
  }
}

///|
pub fn Protocol::from_name(name : StringView) -> Protocol? {
  let wanted = name.to_owned()
  for info in protocol_table() {
    if info.name == wanted {
      return Some(info.protocol)
    }
  }
  None
}

///|
pub fn Protocol::expected_value_kind(self : Protocol) -> ProtocolValueKind {
  match protocol_info(self) {
    Some(info) => info.value_kind
    None => Raw
  }
}

///|
pub fn Protocol::accepts_value(self : Protocol, value : ProtocolValue) -> Bool {
  match self {
    Unknown(_) => value.kind() == Text || value.kind() == Raw
    _ => self.expected_value_kind() == value.kind()
  }
}

///|
pub fn Protocol::diagnostic_name(self : Protocol) -> String {
  match self.name() {
    Some(name) => name
    None => "protocol-" + self.code().to_string()
  }
}

///|
pub struct Ipv4Address {
  octets : Bytes
} derive(Eq, @debug.Debug)

///|
pub fn Ipv4Address::new(
  a : Int,
  b : Int,
  c : Int,
  d : Int,
) -> Result[Ipv4Address, MoonLoomError] {
  if a < 0 || a > 255 {
    return Err(InvalidField("ipv4 octet", a))
  }
  if b < 0 || b > 255 {
    return Err(InvalidField("ipv4 octet", b))
  }
  if c < 0 || c > 255 {
    return Err(InvalidField("ipv4 octet", c))
  }
  if d < 0 || d > 255 {
    return Err(InvalidField("ipv4 octet", d))
  }
  Ok({ octets: [a.to_byte(), b.to_byte(), c.to_byte(), d.to_byte()], })
}

///|
pub fn Ipv4Address::from_octets(
  value : BytesView,
) -> Result[Ipv4Address, MoonLoomError] {
  if value.length() != 4 {
    Err(InvalidField("ipv4 length", value.length()))
  } else {
    Ok({ octets: value.to_owned(), })
  }
}

///|
pub fn Ipv4Address::octets(self : Ipv4Address) -> BytesView {
  self.octets[:]
}

///|
pub struct Ipv6Address {
  octets : Bytes
} derive(Eq, @debug.Debug)

///|
pub fn Ipv6Address::from_octets(
  value : BytesView,
) -> Result[Ipv6Address, MoonLoomError] {
  if value.length() != 16 {
    Err(InvalidField("ipv6 length", value.length()))
  } else {
    Ok({ octets: value.to_owned(), })
  }
}

///|
pub fn Ipv6Address::octets(self : Ipv6Address) -> BytesView {
  self.octets[:]
}

///|
/// Typed values accepted by the Multiaddr domain model.
pub(all) enum ProtocolValue {
  Empty
  Ipv4(Ipv4Address)
  Ipv6(Ipv6Address)
  Domain(String)
  Port(Int)
  PeerId(String)
  Text(String)
  Raw(Bytes)
} derive(Eq, @debug.Debug)

///|
/// A typed protocol/value pair.
pub struct PathSegment {
  protocol : Protocol
  value : ProtocolValue
} derive(Eq, @debug.Debug)

///|
pub fn ProtocolValue::kind(self : ProtocolValue) -> ProtocolValueKind {
  match self {
    Empty => Empty
    Ipv4(_) => Ipv4
    Ipv6(_) => Ipv6
    Domain(_) => Domain
    Port(_) => Port
    PeerId(_) => PeerId
    Text(_) => Text
    Raw(_) => Raw
  }
}

///|
pub fn PathSegment::new(
  protocol : Protocol,
  value : ProtocolValue,
) -> Result[PathSegment, MoonLoomError] {
  if !protocol.accepts_value(value) {
    return Err(InvalidProtocolValue(protocol.diagnostic_name()))
  }
  match value {
    Port(port) =>
      if port < 0 || port > 65535 {
        Err(InvalidPort(port))
      } else {
        Ok({ protocol, value, })
      }
    Domain(domain) | PeerId(domain) =>
      if domain.is_empty() || domain.length() > 255 || domain.contains("\u{0}") {
        Err(InvalidProtocolValue(protocol.diagnostic_name()))
      } else {
        Ok({ protocol, value, })
      }
    _ => Ok({ protocol, value, })
  }
}

///|
pub fn PathSegment::protocol(self : PathSegment) -> Protocol {
  self.protocol
}

///|
pub fn PathSegment::value(self : PathSegment) -> ProtocolValue {
  self.value
}

///|
/// Type-safe Multiaddr domain model. Text and binary codecs are layered on top.
pub struct Multiaddr {
  segments : Array[PathSegment]
} derive(Eq, @debug.Debug)

///|
pub fn Multiaddr::empty() -> Multiaddr {
  { segments: [], }
}

///|
pub fn Multiaddr::from_segments(
  segments : Array[PathSegment],
  limits : Limits,
) -> Result[Multiaddr, MoonLoomError] {
  match limits.check_multiaddr(segments.length()) {
    Ok(_) => {
      let copy : Array[PathSegment] = Array(capacity=segments.length())
      for segment in segments {
        copy.push(segment)
      }
      Ok({ segments: copy, })
    }
    Err(err) => Err(err)
  }
}

///|
pub fn Multiaddr::length(self : Multiaddr) -> Int {
  self.segments.length()
}

///|
pub fn Multiaddr::is_empty(self : Multiaddr) -> Bool {
  self.segments.is_empty()
}

///|
pub fn Multiaddr::get(self : Multiaddr, index : Int) -> PathSegment? {
  if index < 0 || index >= self.segments.length() {
    None
  } else {
    Some(self.segments[index])
  }
}

///|
pub fn Multiaddr::segments(self : Multiaddr) -> ArrayView[PathSegment] {
  self.segments[:]
}

///|
pub fn Multiaddr::push(
  self : Multiaddr,
  segment : PathSegment,
  limits : Limits,
) -> Result[Multiaddr, MoonLoomError] {
  match limits.check_multiaddr(self.length() + 1) {
    Ok(_) => {
      let copy : Array[PathSegment] = Array(capacity=self.length() + 1)
      for item in self.segments {
        copy.push(item)
      }
      copy.push(segment)
      Ok({ segments: copy, })
    }
    Err(err) => Err(err)
  }
}

///|
fn parse_decimal_bounded(input : StringView, maximum : Int) -> Int? {
  if input.length() == 0 {
    return None
  }
  let mut value = 0
  for code_unit in input.code_units() {
    let code = code_unit.to_int()
    if code < 48 || code > 57 {
      return None
    }
    value = value * 10 + (code - 48)
    if value > maximum {
      return None
    }
  }
  Some(value)
}

///|
fn parse_ipv4_text(input : StringView) -> Result[Ipv4Address, MoonLoomError] {
  let parts : Array[Int] = []
  for part in input.split(".") {
    match parse_decimal_bounded(part, 255) {
      Some(value) => parts.push(value)
      None => return Err(InvalidProtocolValue("ip4"))
    }
  }
  if parts.length() != 4 {
    return Err(InvalidProtocolValue("ip4"))
  }
  Ipv4Address::new(parts[0], parts[1], parts[2], parts[3])
}

///|
fn parse_hex_group(input : StringView) -> Int? {
  if input.length() == 0 || input.length() > 4 {
    return None
  }
  let mut value = 0
  for code_unit in input.code_units() {
    let code = code_unit.to_int()
    let digit = if code >= 48 && code <= 57 {
      code - 48
    } else if code >= 97 && code <= 102 {
      code - 97 + 10
    } else if code >= 65 && code <= 70 {
      code - 65 + 10
    } else {
      return None
    }
    value = (value << 4) | digit
  }
  Some(value)
}

///|
fn parse_ipv6_side(
  input : StringView,
  groups : Array[Int],
) -> Result[Unit, MoonLoomError] {
  if input.length() == 0 {
    return Ok(())
  }
  for part in input.split(":") {
    match parse_hex_group(part) {
      Some(value) => groups.push(value)
      None => return Err(InvalidProtocolValue("ip6"))
    }
  }
  Ok(())
}

///|
fn parse_ipv6_text(input : StringView) -> Result[Ipv6Address, MoonLoomError] {
  let sides : Array[StringView] = []
  for side in input.split("::") {
    sides.push(side)
  }
  let groups : Array[Int] = []
  if sides.length() == 1 {
    match parse_ipv6_side(sides[0], groups) {
      Ok(_) => ()
      Err(err) => return Err(err)
    }
    if groups.length() != 8 {
      return Err(InvalidProtocolValue("ip6"))
    }
  } else if sides.length() == 2 {
    match parse_ipv6_side(sides[0], groups) {
      Ok(_) => ()
      Err(err) => return Err(err)
    }
    let right : Array[Int] = []
    match parse_ipv6_side(sides[1], right) {
      Ok(_) => ()
      Err(err) => return Err(err)
    }
    if groups.length() + right.length() >= 8 {
      return Err(InvalidProtocolValue("ip6"))
    }
    let missing = 8 - groups.length() - right.length()
    for _ in 0..<missing {
      groups.push(0)
    }
    for value in right {
      groups.push(value)
    }
  } else {
    return Err(InvalidProtocolValue("ip6"))
  }
  let out = @buffer.Buffer(size_hint=16)
  for group in groups {
    out.write_byte((group >> 8).to_byte())
    out.write_byte((group & 0xFF).to_byte())
  }
  Ipv6Address::from_octets(out.to_bytes())
}

///|
fn validate_ascii_value(
  input : StringView,
  context : String,
) -> Result[String, MoonLoomError] {
  if input.length() == 0 || input.length() > 255 {
    return Err(InvalidProtocolValue(context))
  }
  for code_unit in input.code_units() {
    let code = code_unit.to_int()
    let valid = (code >= 48 && code <= 57) ||
      (code >= 65 && code <= 90) ||
      (code >= 97 && code <= 122) ||
      code == 45 ||
      code == 46 ||
      code == 95
    if !valid {
      return Err(InvalidProtocolValue(context))
    }
  }
  Ok(input.to_owned())
}

///|
fn parse_protocol_value(
  protocol : Protocol,
  input : StringView,
) -> Result[ProtocolValue, MoonLoomError] {
  match protocol {
    Ip4 =>
      match parse_ipv4_text(input) {
        Ok(value) => Ok(ProtocolValue::Ipv4(value))
        Err(err) => Err(err)
      }
    Ip6 =>
      match parse_ipv6_text(input) {
        Ok(value) => Ok(ProtocolValue::Ipv6(value))
        Err(err) => Err(err)
      }
    Dns | Dns4 | Dns6 | Dnsaddr =>
      match validate_ascii_value(input, protocol.diagnostic_name()) {
        Ok(value) => Ok(ProtocolValue::Domain(value))
        Err(err) => Err(err)
      }
    Tcp | Udp =>
      match parse_decimal_bounded(input, 65535) {
        Some(value) => Ok(ProtocolValue::Port(value))
        None => Err(InvalidProtocolValue(protocol.diagnostic_name()))
      }
    P2p =>
      match validate_ascii_value(input, "p2p") {
        Ok(value) => Ok(ProtocolValue::PeerId(value))
        Err(err) => Err(err)
      }
    Unknown(_) => Ok(ProtocolValue::Text(input.to_owned()))
    Http | Https | Ws | Wss =>
      Err(InvalidProtocolValue(protocol.diagnostic_name()))
  }
}

///|
pub fn Multiaddr::parse(
  text : StringView,
  limits : Limits,
) -> Result[Multiaddr, MoonLoomError] {
  match limits.check_multiaddr(text.length()) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }
  if text.length() == 0 {
    return Ok(Multiaddr::empty())
  }
  let parts : Array[StringView] = []
  for part in text.split("/") {
    parts.push(part)
  }
  if parts.length() == 0 || parts[0].length() != 0 {
    return Err(InvalidField("multiaddr prefix", 0))
  }
  if parts.length() == 1 {
    return Ok(Multiaddr::empty())
  }
  let segments : Array[PathSegment] = []
  let mut index = 1
  while index < parts.length() {
    if parts[index].length() == 0 {
      return Err(InvalidField("multiaddr protocol", index))
    }
    let protocol = match Protocol::from_name(parts[index]) {
      Some(value) => value
      None => return Err(UnknownProtocol(parts[index].to_owned()))
    }
    index += 1
    let value = if protocol.expected_value_kind() == Empty {
      ProtocolValue::Empty
    } else {
      if index >= parts.length() || parts[index].length() == 0 {
        return Err(Truncated("multiaddr value", index))
      }
      let parsed = match parse_protocol_value(protocol, parts[index]) {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      index += 1
      parsed
    }
    let segment = match PathSegment::new(protocol, value) {
      Ok(value) => value
      Err(err) => return Err(err)
    }
    segments.push(segment)
  }
  Multiaddr::from_segments(segments, limits)
}

///|
fn write_bytes(buffer : @buffer.Buffer, bytes : BytesView) -> Unit {
  for byte in bytes {
    buffer.write_byte(byte)
  }
}

///|
fn write_length_prefixed(buffer : @buffer.Buffer, bytes : BytesView) -> Unit {
  write_bytes(buffer, encode_u64(bytes.length().to_uint64()))
  write_bytes(buffer, bytes)
}

///|
fn read_fixed(
  input : BytesView,
  offset : Int,
  length : Int,
  context : String,
) -> Result[BytesView, MoonLoomError] {
  if offset + length > input.length() {
    Err(Truncated(context, offset))
  } else {
    Ok(input[offset:offset + length])
  }
}

///|
fn read_length_prefixed(
  input : BytesView,
  offset : Int,
  limits : Limits,
  context : String,
) -> Result[(BytesView, Int), MoonLoomError] {
  if offset >= input.length() {
    return Err(Truncated(context, offset))
  }
  match decode_u64_with_limits(input[offset:], limits) {
    Ok((length, consumed)) => {
      if length > limits.max_input_bytes().to_uint64() {
        return Err(
          InputTooLong(context, limits.max_input_bytes(), length.to_int()),
        )
      }
      let size = length.to_int()
      let start = offset + consumed
      match read_fixed(input, start, size, context) {
        Ok(bytes) => Ok((bytes, start + size))
        Err(err) => Err(err)
      }
    }
    Err(err) => Err(err)
  }
}

///|
pub fn Multiaddr::to_bytes(
  self : Multiaddr,
  limits : Limits,
) -> Result[Bytes, MoonLoomError] {
  let out = @buffer.Buffer()
  for segment in self.segments {
    let protocol = segment.protocol()
    match protocol {
      Unknown(code) =>
        return Err(UnknownProtocol("protocol-" + code.to_string()))
      _ => ()
    }
    write_bytes(out, encode_u64(protocol.code()))
    match segment.value() {
      Empty => ()
      Ipv4(value) => write_bytes(out, value.octets())
      Ipv6(value) => write_bytes(out, value.octets())
      Domain(value) => write_length_prefixed(out, @utf8.encode(value[:]))
      Port(value) => {
        if value < 0 || value > 65535 {
          return Err(InvalidPort(value))
        }
        out.write_byte((value >> 8).to_byte())
        out.write_byte((value & 0xFF).to_byte())
      }
      PeerId(value) =>
        match decode_base58(value[:]) {
          Ok(bytes) => write_length_prefixed(out, bytes)
          Err(_) => return Err(InvalidProtocolValue("p2p"))
        }
      Text(_) | Raw(_) =>
        return Err(InvalidProtocolValue(protocol.diagnostic_name()))
    }
  }
  let bytes = out.to_bytes()
  match limits.check_multiaddr(bytes.length()) {
    Ok(_) => Ok(bytes)
    Err(err) => Err(err)
  }
}

///|
pub fn Multiaddr::parse_bytes(
  input : BytesView,
  limits : Limits,
) -> Result[Multiaddr, MoonLoomError] {
  match limits.check_multiaddr(input.length()) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }
  let segments : Array[PathSegment] = []
  let mut offset = 0
  while offset < input.length() {
    match decode_u64_with_limits(input[offset:], limits) {
      Ok((code, consumed)) => {
        offset += consumed
        let protocol = Protocol::from_code(code)
        match protocol {
          Unknown(_) =>
            return Err(UnknownProtocol("protocol-" + code.to_string()))
          _ => ()
        }
        let value = match protocol.expected_value_kind() {
          Empty => ProtocolValue::Empty
          Ipv4 => {
            let bytes = match read_fixed(input, offset, 4, "ip4") {
              Ok(value) => value
              Err(err) => return Err(err)
            }
            offset += 4
            match Ipv4Address::from_octets(bytes) {
              Ok(value) => ProtocolValue::Ipv4(value)
              Err(err) => return Err(err)
            }
          }
          Ipv6 => {
            let bytes = match read_fixed(input, offset, 16, "ip6") {
              Ok(value) => value
              Err(err) => return Err(err)
            }
            offset += 16
            match Ipv6Address::from_octets(bytes) {
              Ok(value) => ProtocolValue::Ipv6(value)
              Err(err) => return Err(err)
            }
          }
          Domain => {
            let bytes = match
              read_length_prefixed(input, offset, limits, "dns") {
              Ok((value, next)) => {
                offset = next
                value
              }
              Err(err) => return Err(err)
            }
            let decoded = @utf8.decode(bytes) catch {
              _ => return Err(InvalidProtocolValue(protocol.diagnostic_name()))
            }
            ProtocolValue::Domain(decoded)
          }
          Port => {
            let bytes = match
              read_fixed(input, offset, 2, protocol.diagnostic_name()) {
              Ok(value) => value
              Err(err) => return Err(err)
            }
            offset += 2
            let value = (bytes[0].to_int() << 8) | bytes[1].to_int()
            ProtocolValue::Port(value)
          }
          PeerId => {
            let bytes = match
              read_length_prefixed(input, offset, limits, "p2p") {
              Ok((value, next)) => {
                offset = next
                value
              }
              Err(err) => return Err(err)
            }
            ProtocolValue::PeerId(encode_base58(bytes))
          }
          Text | Raw =>
            return Err(InvalidProtocolValue(protocol.diagnostic_name()))
        }
        let segment = match PathSegment::new(protocol, value) {
          Ok(value) => value
          Err(err) => return Err(err)
        }
        segments.push(segment)
      }
      Err(err) => return Err(err)
    }
  }
  Multiaddr::from_segments(segments, limits)
}

///|
pub extend Protocol with Eq::{not_equal, equal}

///|
pub extend Protocol with @debug.Debug::{to_repr}

///|
pub extend ProtocolValueKind with Eq::{not_equal, equal}

///|
pub extend ProtocolValueKind with @debug.Debug::{to_repr}

///|
pub extend ProtocolValue with Eq::{not_equal, equal}

///|
pub extend ProtocolValue with @debug.Debug::{to_repr}

///|
pub extend PathSegment with Eq::{not_equal, equal}

///|
pub extend PathSegment with @debug.Debug::{to_repr}

///|
pub extend Ipv4Address with Eq::{not_equal, equal}

///|
pub extend Ipv4Address with @debug.Debug::{to_repr}

///|
pub extend Ipv6Address with Eq::{not_equal, equal}

///|
pub extend Ipv6Address with @debug.Debug::{to_repr}

///|
pub extend Multiaddr with Eq::{not_equal, equal}

///|
pub extend Multiaddr with @debug.Debug::{to_repr}
