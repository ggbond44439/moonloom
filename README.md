# MoonLoom

MoonLoom is a pure MoonBit toolkit for self-describing content addressing. It
brings Multibase, Multicodec, Multihash, CID, and Multiaddr into one small,
strict, deterministic library.

The project is intentionally not a full IPFS implementation. MoonLoom focuses
on the format layer: creating canonical identifiers, converting between text
and bytes, validating input, and preserving interoperability with the
Multiformats ecosystem.

## Current milestone

The format core is implemented and tested:

- Canonical unsigned varint encoding and strict decoding.
- Multibase codecs for base16, base32, base58btc, base64, and URL-safe base64.
- A single registry covering CID, hash, content format, and Multiaddr protocol
  metadata, including value kinds and canonical names.
- Multihash binary encoding with `identity`, `sha2-256`, and `sha2-512`.
- Multihash verification through an explicit hash-provider boundary.
- CIDv0 and CIDv1 encoding, decoding, canonical text output, and content
  verification.
- A typed Multiaddr domain model with reusable protocol, protocol-value,
  path-segment, IPv4, and IPv6 types.
- Typed errors with byte offsets and configurable resource limits.
- Stable public API conventions for construction, parsing, verification, and
  extension seams, documented in `docs/api-contracts.md`.
- Cross-target-friendly MoonBit code with no FFI dependency.

The remaining milestones add Multiaddr, the CLI, interop vectors, and
Mooncakes publication.

## Quick start

```moonbit
let encoded = @moonloom.encode_u64(300UL)
assert_eq(encoded, b"\xac\x02")

let text = @moonloom.multibase_encode(@moonloom.Base32, b"hello")
assert_eq(text, Ok("bnbswy3dp"))

let provider = @moonloom.sha2_provider()
let cid = match @moonloom.cid_from_content(
  85UL,
  @moonloom.Sha2_256,
  b"hello",
  provider,
  @moonloom.Limits::default(),
) {
  Ok(value) => value
  Err(err) => fail(err.to_string())
}

assert_eq(
  cid.to_text(),
  Ok("bafkreibm6jg3ux5qumhcn2b3flc3tyu6dmlb4xa7u5bf44yegnrjhc4yeq"),
)
assert_eq(
  cid.verify(b"hello", provider, @moonloom.Limits::default()),
  Ok(()),
)
```

## Why MoonLoom

MoonBit increasingly needs to exchange content-addressed data with other
ecosystems: build artifacts, offline caches, package integrity manifests,
decentralized identifiers, and peer addresses. Those formats already have
precise specifications and conformance vectors, but MoonBit lacked one shared,
bounded implementation.

MoonLoom is useful in at least three practical scenarios:

1. Create and verify a stable CID for a build artifact or offline cache entry.
2. Convert CIDs, multihashes, and future Multiaddrs between text and binary for
   cross-language protocol fixtures.
3. Verify content obtained from a cache, mirror, or peer before accepting it.

## Design rules

- Canonical output by default.
- Strict decoding with typed errors and byte offsets.
- Every parser and content verifier is bounded by `Limits`.
- No panic for malformed external input.
- Registry data is centralized and reviewed.
- Text and binary round trips are deterministic.
- Cryptographic algorithms are provided by adapters, never reimplemented here.
- SHA-2 support is delegated to Apache-2.0 MoonCrypt.

## Build and test

```text
moon check --target all
moon test --target all
moon build
```

## Status

MoonLoom is under active construction for the 2026 September MoonBit
Hackathon. Version `0.1.0` is the internal format-core milestone, not the final
published API.

## License

Apache-2.0.
