///|
test "multicodec registry round trips curated names" {
  assert_eq(@moonloom.multicodec_code("sha2-256"), Some(18UL))
  assert_eq(@moonloom.multicodec_code("raw"), Some(85UL))
  assert_eq(@moonloom.multicodec_code("multiaddr-dns"), None)
  assert_eq(@moonloom.multicodec_name(421UL), Some("p2p"))
  assert_eq(@moonloom.multicodec_name(999UL), None)
}

///|
test "multicodec registry exposes category" {
  match @moonloom.multicodec_info(112UL) {
    Some(info) => {
      assert_eq(info.name, "dag-pb")
      assert_eq(info.category, @moonloom.Format)
    }
    None => fail("missing dag-pb")
  }
}

///|
test "Multiaddr protocol entries are generated into multicodec registry" {
  for info in @moonloom.protocol_table() {
    assert_eq(@moonloom.multicodec_name(info.code), Some(info.name))
    match @moonloom.multicodec_info(info.code) {
      Some(codec) => {
        assert_eq(codec.name, info.name)
        assert_eq(codec.category, @moonloom.Multiaddr)
      }
      None => fail("missing protocol codec")
    }
  }
  assert_eq(@moonloom.multicodec_count(), 24)
}
