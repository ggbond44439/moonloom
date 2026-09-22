///|
/// High-level namespace for a multicodec entry.
pub(all) enum CodecCategory {
  Cid
  Format
  Hash
  Multiaddr
} derive(Eq, @debug.Debug)

///|
/// Common codec identifier for raw bytes.
pub const RAW_CODEC : UInt64 = 85UL

///|
/// One curated entry from the multicodec registry.
pub(all) struct CodecInfo {
  code : UInt64
  name : String
  category : CodecCategory
} derive(Eq, @debug.Debug)

/// Curated entries from the upstream Multiformats multicodec registry.
/// Source: https://github.com/multiformats/multicodec/blob/master/table.csv
/// Snapshot date: 2026-09-21.

///|
pub(all) struct ProtocolInfo {
  protocol : Protocol
  code : UInt64
  name : String
  value_kind : ProtocolValueKind
} derive(Eq, @debug.Debug)

///|
pub fn protocol_table() -> Array[ProtocolInfo] {
  [
    { protocol: Ip4, code: 4UL, name: "ip4", value_kind: Ipv4, },
    { protocol: Tcp, code: 6UL, name: "tcp", value_kind: Port, },
    { protocol: Ip6, code: 41UL, name: "ip6", value_kind: Ipv6, },
    { protocol: Dns, code: 53UL, name: "dns", value_kind: Domain, },
    { protocol: Dns4, code: 54UL, name: "dns4", value_kind: Domain, },
    { protocol: Dns6, code: 55UL, name: "dns6", value_kind: Domain, },
    { protocol: Dnsaddr, code: 56UL, name: "dnsaddr", value_kind: Domain, },
    { protocol: Udp, code: 273UL, name: "udp", value_kind: Port, },
    { protocol: P2p, code: 421UL, name: "p2p", value_kind: PeerId, },
    { protocol: Https, code: 443UL, name: "https", value_kind: Empty, },
    { protocol: Ws, code: 477UL, name: "ws", value_kind: Empty, },
    { protocol: Wss, code: 478UL, name: "wss", value_kind: Empty, },
    { protocol: Http, code: 480UL, name: "http", value_kind: Empty, },
  ]
}

///|
pub fn protocol_info(protocol : Protocol) -> ProtocolInfo? {
  for entry in protocol_table() {
    if entry.protocol == protocol {
      return Some(entry)
    }
  }
  None
}

///|
pub fn protocol_info_by_code(code : UInt64) -> ProtocolInfo? {
  for entry in protocol_table() {
    if entry.code == code {
      return Some(entry)
    }
  }
  None
}

///|
fn named_codec_table() -> Array[CodecInfo] {
  [
    { code: 0UL, name: "identity", category: Hash, },
    { code: 1UL, name: "cidv1", category: Cid, },
    { code: 18UL, name: "sha2-256", category: Hash, },
    { code: 19UL, name: "sha2-512", category: Hash, },
    { code: 22UL, name: "sha3-256", category: Hash, },
    { code: 20UL, name: "sha3-512", category: Hash, },
    { code: 30UL, name: "blake3", category: Hash, },
    { code: 85UL, name: "raw", category: Format, },
    { code: 112UL, name: "dag-pb", category: Format, },
    { code: 113UL, name: "dag-cbor", category: Format, },
    { code: 114UL, name: "libp2p-key", category: Format, },
  ]
}

///|
pub fn codec_table() -> Array[CodecInfo] {
  let table = named_codec_table()
  for entry in protocol_table() {
    table.push({ code: entry.code, name: entry.name, category: Multiaddr, })
  }
  table
}

///|
pub fn multicodec_info(code : UInt64) -> CodecInfo? {
  for entry in codec_table() {
    if entry.code == code {
      return Some(entry)
    }
  }
  None
}

///|
pub fn multicodec_name(code : UInt64) -> String? {
  match multicodec_info(code) {
    Some(info) => Some(info.name)
    None => None
  }
}

///|
pub fn multicodec_code(name : StringView) -> UInt64? {
  let wanted = name.to_owned()
  for entry in codec_table() {
    if entry.name == wanted {
      return Some(entry.code)
    }
  }
  None
}

///|
pub fn multicodec_count() -> Int {
  codec_table().length()
}

///|
pub fn CodecCategory::name(self : CodecCategory) -> String {
  match self {
    Cid => "cid"
    Format => "format"
    Hash => "hash"
    Multiaddr => "multiaddr"
  }
}

///|
pub fn CodecCategory::from_name(name : StringView) -> CodecCategory? {
  match name.to_owned() {
    "cid" => Some(Cid)
    "format" => Some(Format)
    "hash" => Some(Hash)
    "multiaddr" => Some(Multiaddr)
    _ => None
  }
}

///|
pub extend CodecCategory with Eq::{not_equal, equal}

///|
pub extend CodecCategory with @debug.Debug::{to_repr}

///|
pub extend CodecInfo with Eq::{not_equal, equal}

///|
pub extend CodecInfo with @debug.Debug::{to_repr}

///|
pub extend ProtocolInfo with Eq::{not_equal, equal}

///|
pub extend ProtocolInfo with @debug.Debug::{to_repr}
