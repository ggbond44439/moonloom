///|
fn main raise {
  let value = match
    @moonloom.Multiaddr::parse(
      "/ip6/2001:0db8:0000:0000:0000:0000:0000:0001/tcp/443",
      @moonloom.Limits::default(),
    ) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let text = match value.to_text() {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let bytes = match value.to_bytes(@moonloom.Limits::default()) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let binary = match @moonloom.multibase_encode(@moonloom.Base16, bytes) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  println("multiaddr=" + text)
  println("binary=" + binary)
}
