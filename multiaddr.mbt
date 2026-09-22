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
  match self {
    Ip4 => 4UL
    Ip6 => 41UL
    Dns => 53UL
    Dns4 => 54UL
    Dns6 => 55UL
    Dnsaddr => 56UL
    Tcp => 6UL
    Udp => 273UL
    P2p => 421UL
    Http => 480UL
    Https => 443UL
    Ws => 477UL
    Wss => 478UL
    Unknown(code) => code
  }
}

///|
pub fn Protocol::from_code(code : UInt64) -> Protocol {
  match code {
    4UL => Ip4
    41UL => Ip6
    53UL => Dns
    54UL => Dns4
    55UL => Dns6
    56UL => Dnsaddr
    6UL => Tcp
    273UL => Udp
    421UL => P2p
    480UL => Http
    443UL => Https
    477UL => Ws
    478UL => Wss
    _ => Unknown(code)
  }
}

///|
pub fn Protocol::name(self : Protocol) -> String? {
  match self {
    Ip4 => Some("ip4")
    Ip6 => Some("ip6")
    Dns => Some("dns")
    Dns4 => Some("dns4")
    Dns6 => Some("dns6")
    Dnsaddr => Some("dnsaddr")
    Tcp => Some("tcp")
    Udp => Some("udp")
    P2p => Some("p2p")
    Http => Some("http")
    Https => Some("https")
    Ws => Some("ws")
    Wss => Some("wss")
    Unknown(_) => None
  }
}

///|
pub fn Protocol::from_name(name : StringView) -> Protocol? {
  match name.to_owned() {
    "ip4" => Some(Ip4)
    "ip6" => Some(Ip6)
    "dns" => Some(Dns)
    "dns4" => Some(Dns4)
    "dns6" => Some(Dns6)
    "dnsaddr" => Some(Dnsaddr)
    "tcp" => Some(Tcp)
    "udp" => Some(Udp)
    "p2p" => Some(P2p)
    "http" => Some(Http)
    "https" => Some(Https)
    "ws" => Some(Ws)
    "wss" => Some(Wss)
    _ => None
  }
}

///|
pub fn Protocol::expected_value_kind(self : Protocol) -> ProtocolValueKind {
  match self {
    Ip4 => Ipv4
    Ip6 => Ipv6
    Dns | Dns4 | Dns6 | Dnsaddr => Domain
    Tcp | Udp => Port
    P2p => PeerId
    Http | Https | Ws | Wss => Empty
    Unknown(_) => Raw
  }
}

///|
pub fn Protocol::accepts_value(self : Protocol, value : ProtocolValue) -> Bool {
  match (self, value) {
    (Ip4, Ipv4(_)) => true
    (Ip6, Ipv6(_)) => true
    (Dns | Dns4 | Dns6 | Dnsaddr, Domain(_)) => true
    (Tcp | Udp, Port(_)) => true
    (P2p, PeerId(_)) => true
    (Http | Https | Ws | Wss, Empty) => true
    (Unknown(_), Raw(_) | Text(_)) => true
    _ => false
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
