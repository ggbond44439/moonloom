///|
fn main raise {
  let provider = @moonloom.sha2_provider()
  let content = b"MoonLoom artifact example"
  let cid = match
    @moonloom.cid_from_content(
      @moonloom.RAW_CODEC,
      @moonloom.Sha2_256,
      content,
      provider,
      @moonloom.Limits::default(),
    ) {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  let text = match cid.to_text() {
    Ok(value) => value
    Err(err) => fail(err.to_string())
  }
  println("cid=" + text)
  match cid.verify(content, provider, @moonloom.Limits::default()) {
    Ok(_) => println("verified=true")
    Err(err) => fail(err.to_string())
  }
}
