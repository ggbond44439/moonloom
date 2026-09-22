# Format boundaries

This document defines what MoonLoom accepts in the current format-core
milestone. It is a contract for the code, not a list of future aspirations.

## Unsigned varint

- Encoding is unsigned LEB128 with the minimum possible number of bytes.
- The maximum value is `UInt64::MAX_VALUE`.
- The decoder rejects overlong encodings such as `80 00`.
- The decoder rejects overflow and truncation with a byte offset.
- Signed/zigzag varints are not part of this milestone.

## Multibase

The registry supports these prefixes:

| Prefix | Encoding | Padding |
| --- | --- | --- |
| `f` | base16 lower | no |
| `F` | base16 upper | no |
| `b` | base32 lower | no |
| `B` | base32 upper | no |
| `c` | base32 lower | yes |
| `C` | base32 upper | yes |
| `z` | base58btc | no |
| `m` | base64 | no |
| `M` | base64 | yes |
| `u` | base64url | no |
| `U` | base64url | yes |

Decoding is strict:

- Unknown prefixes are rejected.
- Mixed-case base16/base32 input is rejected.
- Invalid alphabet characters and malformed padding are rejected.
- Base64 length `mod 4 == 1` is rejected.
- Whitespace is not ignored.

## Multicodec registry

The registry is a curated subset. Codes are stable numeric identifiers and are
resolved by name or number. Unknown codes are preserved as unknown values; they
are not assigned a guessed name.

The current table covers:

- `identity`
- `cidv1`
- `sha2-256`, `sha2-512`, `sha3-256`, `sha3-512`, `blake3`
- `raw`, `dag-pb`, `dag-cbor`, `libp2p-key`
- `ip4`, `ip6`, `dns`, `dns4`, `dns6`, `dnsaddr`
- `tcp`, `udp`, `p2p`, `http`, `https`, `ws`, `wss`

The table will be expanded only from the upstream registry, with source and
version recorded in the repository.

Registry source: `https://github.com/multiformats/multicodec/blob/master/table.csv`,
checked on 2026-09-21.

## Multihash

Binary layout:

```text
<unsigned-varint code><unsigned-varint digest length><digest bytes>
```

Implemented algorithms:

- `identity`
- `sha2-256`
- `sha2-512`

Rules:

- Digest length is bounded by `Limits.max_digest_bytes`.
- Known algorithms require their exact digest size.
- Unknown algorithm codes can be decoded and preserved, but cannot be verified
  until a matching provider is supplied.
- Text output uses Multibase. Base58btc is the conventional choice for
  multihash fixtures.
- `verify` distinguishes unsupported algorithms from hash mismatches.

SHA-2 is provided by the external MoonCrypt implementation. MoonLoom does not
implement cryptographic primitives.

## CID

Implemented versions:

- CIDv0
- CIDv1

CIDv0 rules:

- Only `sha2-256` is accepted.
- The implicit codec is `dag-pb`.
- Text form is raw base58btc without a Multibase prefix.

CIDv1 rules:

- Binary form is `<version><codec><multihash>` with unsigned varints.
- The canonical text form uses base32 lower and therefore starts with `b`.
- Text decoding may accept another Multibase prefix, but output is canonical.
- A CIDv1 text value without a Multibase prefix is rejected.
- Codec and hash values remain numeric and can be inspected directly.

Content verification calls the supplied `HashProvider`. CID verification never
reimplements or silently substitutes a hash algorithm.

## Multiaddr domain model

The current milestone provides an in-memory, typed model only. It does not yet
parse or serialize Multiaddr text.

Implemented protocols:

- `ip4`, `ip6`
- `dns`, `dns4`, `dns6`, `dnsaddr`
- `tcp`, `udp`
- `p2p`
- `http`, `https`, `ws`, `wss`

Rules:

- A protocol declares the kind of value it accepts.
- TCP and UDP ports must be in `0..=65535`.
- DNS and peer identifiers must be non-empty and at most 255 UTF-16 code units.
- IPv4 values are exactly four bytes; IPv6 values are exactly sixteen bytes.
- Unknown protocol codes remain representable as `Protocol::Unknown(code)`.
- Text parsing and binary encoding are deliberately deferred to the next
  milestones.

## Limits

`Limits` bounds input length, varint width, digest size, and future Multiaddr
size. Limits are explicit parameters at parsing boundaries and are designed to
be lowered by applications that process untrusted input.

## Not implemented yet

- Multiaddr text and binary codecs
- CLI commands
- Mooncakes publication
- CIDv2 or other future versions
- SHA3, BLAKE3, and other extra hash providers
- CAR, IPLD, blockstores, networking, and DNS resolution

Those boundaries are deliberate. MoonLoom will not claim support for a format
before its codec, tests, and documentation exist.
