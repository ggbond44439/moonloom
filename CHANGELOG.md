# Changelog

## Unreleased

- Added the shared `ProtocolInfo` registry for Multiaddr protocol metadata.
- Removed duplicated protocol code/name/value-kind mappings from Multiaddr.
- Added the typed Multiaddr domain model and protocol/value validation.
- Stabilized public naming, inspection, and resource-limit helpers.
- Added canonical name lookups for Multibase and hash algorithms.
- Added shared codec-category lookup and raw codec identifier.
- Added Multihash binary encoding and strict decoding.
- Added `identity`, `sha2-256`, and `sha2-512` hash semantics.
- Added the `HashProvider` boundary and bundled MoonCrypt SHA-2 provider.
- Added CIDv0 and CIDv1 encoding, parsing, canonical text output, and content
  verification.
- Added standard empty-content and `hello` content vectors.

## 0.1.0

Initial milestone:

- canonical unsigned varint codec
- Multibase codecs and strict validation
- curated multicodec registry
- typed errors and resource limits
- unit tests and CI
