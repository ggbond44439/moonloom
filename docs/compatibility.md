# Compatibility matrix

MoonLoom targets deterministic behavior across supported MoonBit backends.

| Area | wasm | wasm-gc | JS | Native |
| --- | --- | --- | --- | --- |
| Varint | yes | yes | yes | check |
| Multibase | yes | yes | yes | check |
| Multihash | yes | yes | yes | check |
| CIDv0/CIDv1 | yes | yes | yes | check |
| Multiaddr text | yes | yes | yes | check |
| Multiaddr binary | yes | yes | yes | check |
| CLI core | yes | yes | yes | check |
| SHA-2 provider | bundled | bundled | bundled | bundled |

`check` means the code is target-checked in CI. The hosted CI runner executes
the full target matrix, including Native, when the C toolchain is available.

## Standard versions

- Unsigned varint: Multiformats unsigned LEB128.
- Multibase: supported prefixes listed in `docs/format-boundaries.md`.
- Multicodec: curated snapshot from the upstream registry on 2026-09-21.
- Multihash: identity, SHA-256, and SHA-512.
- CID: CIDv0 and CIDv1.
- Multiaddr: IPv4, IPv6, DNS variants, TCP, UDP, p2p, HTTP(S), WS(S).
- IPv6 text: RFC 5952 canonical compression.

## Intentional limits

- DNS and peer strings in the current text parser are ASCII and at most 255
  code units.
- Unknown protocol codes can be represented in the model but cannot be text or
  binary encoded without a protocol-specific payload rule.
- SHA3 and BLAKE3 codes are registered but do not yet have bundled providers.
- File and stdin CLI input are not part of the current milestone.
