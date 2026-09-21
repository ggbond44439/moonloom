# MoonLoom

MoonLoom is a pure MoonBit toolkit for self-describing content addressing. It
brings Multibase, Multicodec, Multihash, CID, and Multiaddr into one small,
strict, deterministic library.

The project is intentionally not a full IPFS implementation. MoonLoom focuses
on the format layer: creating canonical identifiers, converting between text
and bytes, validating input, and preserving interoperability with the
Multiformats ecosystem.

## Current milestone

The first milestone is implemented and tested:

- Canonical unsigned varint encoding and strict decoding.
- Multibase codecs for base16, base32, base58btc, base64, and URL-safe base64.
- A curated multicodec registry covering CID, hash, content format, and core
  Multiaddr protocol identifiers.
- Typed errors with byte offsets and configurable resource limits.
- Cross-target-friendly MoonBit code with no FFI dependency.

The next milestones add Multihash, CIDv0/CIDv1, Multiaddr, the CLI, and
Mooncakes publication.

## Quick start

```moonbit
let encoded = @moonloom.encode_u64(300UL)
assert_eq(encoded, b"\xac\x02")

let decoded = @moonloom.decode_u64(encoded)
assert_eq(decoded, Ok((300UL, 2)))

let text = @moonloom.multibase_encode(@moonloom.Base32, b"hello")
assert_eq(text, Ok("bnbswy3dp"))

match @moonloom.multibase_decode(
  "bnbswy3dp",
  @moonloom.Limits::default(),
) {
  Ok(value) => assert_eq(value.data, b"hello")
  Err(err) => fail(err.to_string())
}
```

## Why MoonLoom

MoonBit increasingly needs to exchange content-addressed data with other
ecosystems: build artifacts, offline caches, package integrity manifests,
decentralized identifiers, and peer addresses. Those formats already have
precise specifications and conformance vectors, but MoonBit lacked one shared,
bounded implementation.

MoonLoom is useful in at least three practical scenarios:

1. Create and verify a stable identifier for a build artifact or offline cache
   entry.
2. Parse and normalize a peer Multiaddr before handing it to a network layer.
3. Convert CID, hash, and address fixtures between text and binary form for
   cross-language tests.

## Design rules

- Canonical output by default.
- Strict decoding with typed errors and byte offsets.
- Every parser is bounded by `Limits`.
- No panic for malformed external input.
- Registry data is centralized and reviewed.
- Text and binary round trips are deterministic.
- Cryptographic algorithms are provided by adapters, never reimplemented here.

## Build and test

```text
moon check
moon test
moon build
```

## Status

MoonLoom is under active construction for the 2026 September MoonBit
Hackathon. Version `0.1.0` is the first internal milestone, not the final
published API.

## License

Apache-2.0.
