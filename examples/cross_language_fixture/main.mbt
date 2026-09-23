///|
fn main raise {
  let hash = match
    @moonloom.sha2_provider().hash(@moonloom.Sha2_256, b"fixture") {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let multihash = match
    @moonloom.Multihash::create(
      @moonloom.Sha2_256,
      hash,
      @moonloom.Limits::default(),
    ) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let multihash_text = match multihash.to_text_canonical() {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let cid = match
    @moonloom.Cid::v1(
      @moonloom.RAW_CODEC,
      multihash,
      @moonloom.Limits::default(),
    ) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let cid_text = match cid.to_text() {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let cid_bytes = cid.to_bytes()
  let cid_hex = match @moonloom.multibase_encode(@moonloom.Base16, cid_bytes) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  println("multihash=" + multihash_text)
  println("cid=" + cid_text)
  println("cid_binary=" + cid_hex)
}
