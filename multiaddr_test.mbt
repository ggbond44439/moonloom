///|
test "protocol identifiers round trip" {
  let protocols : Array[@moonloom.Protocol] = [
    @moonloom.Ip4,
    @moonloom.Ip6,
    @moonloom.Dns,
    @moonloom.Dns4,
    @moonloom.Dns6,
    @moonloom.Dnsaddr,
    @moonloom.Tcp,
    @moonloom.Udp,
    @moonloom.P2p,
    @moonloom.Http,
    @moonloom.Https,
    @moonloom.Ws,
    @moonloom.Wss,
  ]
  for protocol in protocols {
    assert_eq(@moonloom.Protocol::from_code(protocol.code()), protocol)
    match protocol.name() {
      Some(name) =>
        assert_eq(@moonloom.Protocol::from_name(name), Some(protocol))
      None => fail("known protocol has no name")
    }
  }
  assert_eq(@moonloom.Protocol::from_code(9999UL), @moonloom.Unknown(9999UL))
  assert_eq(@moonloom.Protocol::Unknown(9999UL).name(), None)
}

///|
test "protocol value compatibility is explicit" {
  let ip = match @moonloom.Ipv4Address::new(127, 0, 0, 1) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(@moonloom.Ip4.expected_value_kind(), @moonloom.Ipv4)
  assert_eq(@moonloom.Ip4.accepts_value(@moonloom.Ipv4(ip)), true)
  assert_eq(@moonloom.Tcp.accepts_value(@moonloom.Port(443)), true)
  assert_eq(@moonloom.Tcp.accepts_value(@moonloom.Empty), false)
}

///|
test "IPv4 and IPv6 address models reject wrong widths" {
  assert_eq(
    @moonloom.Ipv4Address::from_octets(b"\x7f\x00\x00"),
    Err(@moonloom.InvalidField("ipv4 length", 3)),
  )
  assert_eq(
    @moonloom.Ipv6Address::from_octets(b"\x00"),
    Err(@moonloom.InvalidField("ipv6 length", 1)),
  )
  let ip = match @moonloom.Ipv4Address::from_octets(b"\x7f\x00\x00\x01") {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(ip.octets(), b"\x7f\x00\x00\x01")
}

///|
test "PathSegment rejects mismatched protocol values" {
  assert_eq(
    @moonloom.PathSegment::new(@moonloom.Tcp, @moonloom.Empty),
    Err(@moonloom.InvalidProtocolValue("tcp")),
  )
  assert_eq(
    @moonloom.PathSegment::new(@moonloom.Http, @moonloom.Port(80)),
    Err(@moonloom.InvalidProtocolValue("http")),
  )
  assert_eq(
    @moonloom.PathSegment::new(@moonloom.Tcp, @moonloom.Port(65536)),
    Err(@moonloom.InvalidPort(65536)),
  )
}

///|
test "Multiaddr remains immutable while segments are appended" {
  let ip = match @moonloom.Ipv4Address::new(127, 0, 0, 1) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let ip_segment = match
    @moonloom.PathSegment::new(@moonloom.Ip4, @moonloom.Ipv4(ip)) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let port_segment = match
    @moonloom.PathSegment::new(@moonloom.Tcp, @moonloom.Port(8080)) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let first = @moonloom.Multiaddr::empty()
  let second = match first.push(ip_segment, @moonloom.Limits::default()) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let third = match second.push(port_segment, @moonloom.Limits::default()) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(first.length(), 0)
  assert_eq(second.length(), 1)
  assert_eq(third.length(), 2)
  assert_eq(third.get(0), Some(ip_segment))
  assert_eq(third.get(1), Some(port_segment))
}

///|
test "Multiaddr length is bounded before segment accumulation" {
  let limits = @moonloom.Limits::new(max_multiaddr_bytes=1)
  let segment = match
    @moonloom.PathSegment::new(@moonloom.Http, @moonloom.Empty) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let one = match @moonloom.Multiaddr::from_segments([segment], limits) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  assert_eq(
    one.push(segment, limits),
    Err(@moonloom.InputTooLong("multiaddr", 1, 2)),
  )
}

///|
test "protocol metadata is driven by the shared registry" {
  assert_eq(@moonloom.protocol_table().length(), 13)
  for info in @moonloom.protocol_table() {
    assert_eq(info.protocol.code(), info.code)
    assert_eq(info.protocol.name(), Some(info.name))
    assert_eq(info.protocol.expected_value_kind(), info.value_kind)
    assert_eq(@moonloom.protocol_info(info.protocol), Some(info))
  }
  assert_eq(@moonloom.protocol_info(@moonloom.Unknown(9999UL)), None)
  assert_eq(@moonloom.protocol_info_by_code(9999UL), None)
}

///|
test "protocol value kind is explicit" {
  assert_eq(
    @moonloom.ProtocolValue::Empty.kind(),
    @moonloom.ProtocolValueKind::Empty,
  )
  assert_eq(
    @moonloom.ProtocolValue::Port(80).kind(),
    @moonloom.ProtocolValueKind::Port,
  )
  assert_eq(
    @moonloom.ProtocolValue::Raw(b"x").kind(),
    @moonloom.ProtocolValueKind::Raw,
  )
  assert_eq(
    @moonloom.ProtocolValue::Text("x").kind(),
    @moonloom.ProtocolValueKind::Text,
  )
}
