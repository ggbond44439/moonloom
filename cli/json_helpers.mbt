///|
fn json_string(value : String) -> String {
  @json.to_json(value).stringify()
}

///|
fn json_bool(value : Bool) -> String {
  @json.to_json(value).stringify()
}

///|
fn json_uint64(value : UInt64) -> String {
  value.to_string()
}

///|
fn base64_bytes(value : BytesView) -> String {
  @base64.encode(value, padding=true)
}

///|
fn hex_bytes(value : BytesView) -> String {
  match @moonloom.multibase_encode(@moonloom.Base16, value) {
    Ok(encoded) => encoded.view(start_offset=1).to_owned()
    Err(_) => ""
  }
}
